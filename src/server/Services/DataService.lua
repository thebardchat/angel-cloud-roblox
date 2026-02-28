--[[
    DataService.lua — Server-side data persistence using ProfileStore
    Knit Service wrapping DataManager logic.
    Saves/loads all player data: motes, halos, level, fragments, cosmetics, blessings
    All progression is server-authoritative (anti-cheat)
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService = Knit.CreateService({
    Name = "DataService",
    Client = {
        DataLoaded = Knit.CreateSignal(),
    },
})

-- ProfileStore (graceful fallback for unpublished places)
local ProfileStore
local ProfileStoreAvailable = false

local PlayerStore
local Profiles: { [number]: any } = {}
local FallbackCache: { [number]: { [string]: any } } = {}

-- Community stats (separate OrderedDataStore)
local CommunityStore
local CommunityStoreAvailable = false

local DEFAULT_DATA = {
    motes = 0,
    halos = 0,
    angelLevel = "Newborn",
    layerIndex = 1,
    collectedFragments = {},
    ownedCosmetics = {},
    equippedCosmetics = {},
    equippedWingSkin = "",
    equippedTrail = "",
    equippedNameGlow = "",
    blessingsGiven = 0,
    blessingsReceived = 0,
    longestBlessingChain = 0,
    trialsCompleted = {},
    newbornsHelped = 0,
    totalPlaytime = 0,
    sessionStart = 0,
    linkedAngelCloud = false,
    angelCloudUserId = "",
    robloxLinkCode = "",
    founderHalo = false,
    starfishFound = {},
    redeemedDialCodes = {},
    wingLevel = 1,
    activeQuest = "first_motes",
    questProgress = 0,
    completedQuests = {},
    firstJoin = 0,
    lastSeen = 0,
    dailyStreak = 0,
    lastDailyClaimTime = 0,
    mailSentCount = 0,
    brainrotsDelivered = 0,
    baseLevel = 1,
}

function DataService:KnitInit()
    -- Load ProfileStore
    local ok, result = pcall(function()
        return require(ReplicatedStorage.Packages.ProfileService)
    end)
    if ok and result then
        ProfileStore = result
        ProfileStoreAvailable = true
        print("[DataService] ProfileStore loaded successfully")
    else
        warn("[DataService] ProfileStore failed to load: " .. tostring(result))
    end

    -- Create player store
    if ProfileStoreAvailable then
        local storeOk, storeResult = pcall(function()
            return ProfileStore.New("PlayerData_v2", DEFAULT_DATA)
        end)
        if storeOk then
            PlayerStore = storeResult
        else
            warn("[DataService] Failed to create ProfileStore: " .. tostring(storeResult))
            ProfileStoreAvailable = false
        end
    end

    -- Community stats
    local csOk, csResult = pcall(function()
        return DataStoreService:GetOrderedDataStore("CommunityStats_v1")
    end)
    if csOk and csResult then
        CommunityStore = csResult
        CommunityStoreAvailable = true
    end
end

function DataService:KnitStart()
    self:_startAutoSave()
end

function DataService:_getDefaultData(): { [string]: any }
    local data = {}
    for k, v in pairs(DEFAULT_DATA) do
        if type(v) == "table" then
            data[k] = {}
        else
            data[k] = v
        end
    end
    data.firstJoin = os.time()
    data.lastSeen = os.time()
    data.sessionStart = os.time()
    return data
end

function DataService:LoadPlayer(player: Player): { [string]: any }
    if not ProfileStoreAvailable or not PlayerStore then
        local data = self:_getDefaultData()
        FallbackCache[player.UserId] = data
        print("[DataService] In-memory profile for " .. player.Name)
        return data
    end

    local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
        Cancel = function()
            return player.Parent ~= Players
        end,
    })

    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            Profiles[player.UserId] = nil
            if player.Parent == Players then
                player:Kick("Your data session ended. Please rejoin.")
            end
        end)

        if player.Parent == Players then
            Profiles[player.UserId] = profile

            if profile.Data.firstJoin == 0 then
                profile.Data.firstJoin = os.time()
            end
            profile.Data.sessionStart = os.time()
            profile.Data.lastSeen = os.time()

            print("[DataService] ProfileStore session started for " .. player.Name)
            self.Client.DataLoaded:Fire(player)
            return profile.Data
        else
            profile:EndSession()
            return self:_getDefaultData()
        end
    else
        warn("[DataService] ProfileStore load failed for " .. player.Name .. " — using in-memory")
        local data = self:_getDefaultData()
        FallbackCache[player.UserId] = data
        return data
    end
end

function DataService:SavePlayer(player: Player): boolean
    local profile = Profiles[player.UserId]
    if profile then
        profile.Data.totalPlaytime = profile.Data.totalPlaytime + (os.time() - profile.Data.sessionStart)
        profile.Data.sessionStart = os.time()
        profile.Data.lastSeen = os.time()
        return true
    end

    local data = FallbackCache[player.UserId]
    if data then
        data.totalPlaytime = data.totalPlaytime + (os.time() - data.sessionStart)
        data.sessionStart = os.time()
        data.lastSeen = os.time()
    end
    return true
end

function DataService:GetData(player: Player): { [string]: any }?
    local profile = Profiles[player.UserId]
    if profile then
        return profile.Data
    end
    return FallbackCache[player.UserId]
end

function DataService:SetData(player: Player, key: string, value: any)
    local data = self:GetData(player)
    if data then
        data[key] = value
    end
end

function DataService:RemovePlayer(player: Player)
    self:SavePlayer(player)

    local profile = Profiles[player.UserId]
    if profile then
        profile:EndSession()
    end

    FallbackCache[player.UserId] = nil
end

function DataService:_startAutoSave()
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    self:SavePlayer(player)
                end)
            end
        end
    end)
end

function DataService:IncrementCommunityStat(statName: string, amount: number)
    if not CommunityStoreAvailable then return end
    local success, err = pcall(function()
        CommunityStore:IncrementAsync(statName, amount)
    end)
    if not success then
        warn("[DataService] Failed to increment community stat: " .. tostring(err))
    end
end

function DataService:GetCommunityStats(): { [string]: number }
    local stats = {}
    local keys = { "total_blessings", "total_trials", "total_motes_earned", "longest_chain" }
    if not CommunityStoreAvailable then
        for _, key in ipairs(keys) do
            stats[key] = 0
        end
        return stats
    end
    for _, key in ipairs(keys) do
        local success, value = pcall(function()
            return CommunityStore:GetAsync(key)
        end)
        stats[key] = (success and value) or 0
    end
    return stats
end

-- Client-callable methods
function DataService.Client:GetData(player: Player): { [string]: any }?
    return self.Server:GetData(player)
end

return DataService
