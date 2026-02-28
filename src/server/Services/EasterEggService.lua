--[[
    EasterEggService.lua — Hidden starfish / easter egg tracking and rewards (Knit Service)
    Extracted from GameManager.server.lua (WireStarfish, OnStarfishFound)

    Scans all layer folders for BrownStarfish models, wires ProximityPrompts,
    tracks per-player discoveries, awards motes, triggers Keeper dialogue on
    first find, and grants starfish_hunter cosmetic when all are found.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local EasterEggService = Knit.CreateService({
    Name = "EasterEggService",
    Client = {
        EasterEggFound = Knit.CreateSignal(),
    },
})

--[[ ── Type Definitions ─────────────────────────────────────────────── ]]

type StarfishInfo = {
    id: string,
    model: Model,
    layerName: string,
}

-- Total starfish in the world (computed at wire time)
local totalStarfishInWorld: number = 0

-- Service references resolved at KnitStart
local DataService
local MoteService
local QuestService

--[[ ── Lifecycle ────────────────────────────────────────────────────── ]]

function EasterEggService:KnitInit(): ()
    print("[EasterEggService] Initializing easter egg service")
end

function EasterEggService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")

    -- QuestService may or may not exist; resolve safely
    local ok, svc = pcall(function()
        return Knit.GetService("QuestService")
    end)
    if ok then
        QuestService = svc
    end

    -- Wire up all brown starfish ProximityPrompts
    pcall(function()
        self:WireStarfish()
    end)

    print("[EasterEggService] Easter egg service started")
end

--[[ ── Starfish Wiring ──────────────────────────────────────────────── ]]

function EasterEggService:WireStarfish(): ()
    -- Find all BrownStarfish models across all layer folders and wire their prompts
    local starfishCount: number = 0

    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") and folder.Name:match("^Layer%d") then
            for _, child in ipairs(folder:GetDescendants()) do
                if child:IsA("Model") and child.Name == "BrownStarfish" then
                    starfishCount = starfishCount + 1
                    local starfishId: string = folder.Name .. "_" .. starfishCount
                    local body: BasePart? = child:FindFirstChild("StarfishBody")
                    if body then
                        local prompt: ProximityPrompt? = body:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt then
                            prompt.Triggered:Connect(function(player: Player)
                                self:OnStarfishFound(player, starfishId)
                            end)
                        end
                    end
                end
            end
        end
    end

    totalStarfishInWorld = starfishCount
    print("[EasterEggService] Wired " .. totalStarfishInWorld .. " brown starfish across all layers")
end

--[[ ── Starfish Discovery ───────────────────────────────────────────── ]]

function EasterEggService:OnStarfishFound(player: Player, starfishId: string): ()
    local data = DataService:GetData(player)
    if not data then return end

    -- Track discoveries
    if not data.starfishFound then
        data.starfishFound = {}
    end

    if data.starfishFound[starfishId] then
        -- Already found this one
        self:_notifyPlayer(player, "info", "You've already found this starfish. It seems to recognize you.")
        return
    end

    -- New discovery!
    data.starfishFound[starfishId] = true
    local count: number = 0
    for _ in pairs(data.starfishFound) do
        count = count + 1
    end

    -- Award 2 motes for finding one
    MoteService:AwardMotes(player, 2, "starfish_discovery")

    -- Notify player
    self:_notifyPlayer(player, "starfish", "You found a Brown Starfish! (" .. count .. " discovered) +2 Motes")

    -- Fire client signal
    self.Client.EasterEggFound:Fire(player, {
        eggType = "starfish",
        starfishId = starfishId,
        count = count,
        total = totalStarfishInWorld,
    })

    -- First starfish triggers Keeper dialogue about them
    if count == 1 then
        self:_triggerKeeperDialogue(player)
    end

    -- Quest hook
    if QuestService then
        pcall(function()
            QuestService:OnStarfishFound(player)
        end)
    end

    -- Found ALL starfish — special reward
    if count >= totalStarfishInWorld and totalStarfishInWorld > 0 then
        self:_onAllStarfishFound(player, data)
    end
end

--[[ ── Internal Helpers ─────────────────────────────────────────────── ]]

function EasterEggService:_notifyPlayer(player: Player, msgType: string, message: string): ()
    local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
    if ServerMessage then
        ServerMessage:FireClient(player, {
            type = msgType,
            message = message,
        })
    end
end

function EasterEggService:_triggerKeeperDialogue(player: Player): ()
    task.delay(2, function()
        local NPCDialogue = ReplicatedStorage:FindFirstChild("NPCDialogue")
        if NPCDialogue then
            NPCDialogue:FireClient(player, {
                npcId = "the_keeper",
                npcName = "The Keeper",
                lines = {
                    {
                        speaker = "The Keeper",
                        text = "Ah... you found one of the Starfish. They've been here since before the Cloud itself.",
                    },
                    {
                        speaker = "The Keeper",
                        text = "Legend says a great mind once dreamed of helpful beings — not angels, but something older. Something patient. Something that listens before it speaks.",
                    },
                    {
                        speaker = "The Keeper",
                        text = "The Starfish remember. Find them all, and perhaps they'll share what they know.",
                    },
                },
            })
        end
    end)
end

function EasterEggService:_onAllStarfishFound(player: Player, data: any): ()
    self:_notifyPlayer(player, "starfish_complete", "You found every Brown Starfish in The Cloud Climb! The great mind smiles upon you.")

    -- Grant special cosmetic
    if not data.ownedCosmetics then
        data.ownedCosmetics = {}
    end

    if not data.ownedCosmetics["starfish_hunter"] then
        data.ownedCosmetics["starfish_hunter"] = true
        MoteService:AwardMotes(player, 10, "starfish_complete")
    end

    -- Fire completion signal to client
    self.Client.EasterEggFound:Fire(player, {
        eggType = "starfish_complete",
        starfishId = "all",
        count = totalStarfishInWorld,
        total = totalStarfishInWorld,
    })
end

--[[ ── Public API ───────────────────────────────────────────────────── ]]

function EasterEggService:GetDiscoveryCount(player: Player): number
    local data = DataService:GetData(player)
    if not data or not data.starfishFound then
        return 0
    end

    local count: number = 0
    for _ in pairs(data.starfishFound) do
        count = count + 1
    end
    return count
end

function EasterEggService:GetTotalStarfish(): number
    return totalStarfishInWorld
end

function EasterEggService:HasFoundStarfish(player: Player, starfishId: string): boolean
    local data = DataService:GetData(player)
    if not data or not data.starfishFound then
        return false
    end
    return data.starfishFound[starfishId] == true
end

--[[ ── Client API ───────────────────────────────────────────────────── ]]

function EasterEggService.Client:GetDiscoveryCount(player: Player): number
    return self.Server:GetDiscoveryCount(player)
end

function EasterEggService.Client:GetTotalStarfish(player: Player): number
    return self.Server:GetTotalStarfish()
end

function EasterEggService.Client:HasFoundStarfish(player: Player, starfishId: string): boolean
    return self.Server:HasFoundStarfish(player, starfishId)
end

return EasterEggService
