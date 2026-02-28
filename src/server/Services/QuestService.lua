--[[
    QuestService.lua — Gives players actual missions and objectives (Knit Service)
    Quests drive the gameplay loop: collect, explore, forge, ascend
    Server-authoritative: tracks progress, awards rewards on completion

    Migrated from ServerScriptService/QuestSystem.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local QuestService = Knit.CreateService({
    Name = "QuestService",
    Client = {
        QuestUpdate = Knit.CreateSignal(),
        QuestComplete = Knit.CreateSignal(),
    },
})

-- Service references (resolved in KnitStart)
local DataService
local MoteService
local SoundService

-- Quest definitions: id, title, description, objective type, target, reward
local QUESTS: { any } = {
    -- STARTER QUESTS (Layer 1 -- teach the basics)
    {
        id = "first_motes",
        title = "First Light",
        description = "Collect 5 Light Motes floating in the Nursery",
        layer = 1,
        objective = "collect_motes",
        target = 5,
        reward = { motes = 3 },
        nextQuest = "explore_nursery",
    },
    {
        id = "explore_nursery",
        title = "Cloud Walker",
        description = "Use a Speed Pad and a Bounce Pad",
        layer = 1,
        objective = "use_pads",
        target = 2, -- 1 speed + 1 bounce
        reward = { motes = 5 },
        nextQuest = "learn_to_fly",
    },
    {
        id = "learn_to_fly",
        title = "Spread Your Wings",
        description = "Take flight! Press F to fly, then fly for 10 seconds",
        layer = 1,
        objective = "fly_time",
        target = 10,
        reward = { motes = 5 },
        nextQuest = "visit_forge",
    },
    {
        id = "visit_forge",
        title = "The Forge Calls",
        description = "Visit the Wing Forge and upgrade your wings",
        layer = 1,
        objective = "forge_wings",
        target = 1,
        reward = { motes = 5 },
        nextQuest = "collect_ten",
    },
    {
        id = "collect_ten",
        title = "Rising Light",
        description = "Collect 10 total Motes to unlock the Meadow",
        layer = 1,
        objective = "total_motes",
        target = 10,
        reward = { motes = 5 },
        nextQuest = "reach_meadow",
    },

    -- LAYER 2 QUESTS
    {
        id = "reach_meadow",
        title = "The Meadow Awaits",
        description = "Pass through the Layer Gate to reach The Meadow",
        layer = 1,
        objective = "reach_layer",
        target = 2,
        reward = { motes = 10 },
        nextQuest = "meadow_motes",
    },
    {
        id = "meadow_motes",
        title = "Meadow Harvest",
        description = "Collect 15 more Motes in The Meadow",
        layer = 2,
        objective = "collect_motes_in_session",
        target = 15,
        reward = { motes = 8 },
        nextQuest = "first_blessing",
    },
    {
        id = "first_blessing",
        title = "Pay It Forward",
        description = "Send a Blessing to another Angel from the Blessing Bluff",
        layer = 2,
        objective = "send_blessing",
        target = 1,
        reward = { motes = 10 },
        nextQuest = "forge_level_3",
    },
    {
        id = "forge_level_3",
        title = "Wings of Power",
        description = "Upgrade your wings to Level 3 at the Wing Forge",
        layer = 1,
        objective = "wing_level",
        target = 3,
        reward = { motes = 10 },
        nextQuest = "find_starfish",
    },
    {
        id = "find_starfish",
        title = "Hidden Friends",
        description = "Find 3 hidden Brown Starfish in the clouds",
        layer = 1,
        objective = "starfish_count",
        target = 3,
        reward = { motes = 15 },
        nextQuest = "collect_fragment",
    },
    {
        id = "collect_fragment",
        title = "Ancient Wisdom",
        description = "Collect a Lore Fragment -- press C to view your Codex",
        layer = 1,
        objective = "fragments",
        target = 1,
        reward = { motes = 10 },
        nextQuest = "forge_level_5",
    },
    {
        id = "forge_level_5",
        title = "Radiant Wings",
        description = "Upgrade your wings to Level 5 at the Wing Forge",
        layer = 1,
        objective = "wing_level",
        target = 5,
        reward = { motes = 15 },
        nextQuest = "growing_angel",
    },
    {
        id = "growing_angel",
        title = "Growing Angel",
        description = "Reach 25 total Motes to become a Growing Angel",
        layer = 1,
        objective = "total_motes",
        target = 25,
        reward = { motes = 10 },
        nextQuest = "master_forge",
    },
    {
        id = "master_forge",
        title = "Master Forger",
        description = "Max out your wings at the Wing Forge (Level 10)",
        layer = 1,
        objective = "wing_level",
        target = 10,
        reward = { motes = 25 },
        nextQuest = "send_mail",
    },

    -- ANGEL MAIL QUESTS
    {
        id = "send_mail",
        title = "Spread the Word",
        description = "Send 3 Angel Mail messages to other players (press M)",
        layer = 1,
        objective = "mail_sent",
        target = 3,
        reward = { motes = 10 },
        nextQuest = "reach_canopy",
    },

    -- LAYER 3 QUESTS (The Canopy)
    {
        id = "reach_canopy",
        title = "Into the Canopy",
        description = "Reach 25 total Motes and enter The Canopy",
        layer = 2,
        objective = "reach_layer",
        target = 3,
        reward = { motes = 15 },
        nextQuest = "canopy_explorer",
    },
    {
        id = "canopy_explorer",
        title = "Canopy Explorer",
        description = "Collect 20 Motes in The Canopy",
        layer = 3,
        objective = "collect_motes_in_session",
        target = 20,
        reward = { motes = 10 },
        nextQuest = "five_blessings",
    },
    {
        id = "five_blessings",
        title = "Chain of Light",
        description = "Send 5 total Blessings to other Angels",
        layer = 2,
        objective = "total_blessings",
        target = 5,
        reward = { motes = 15 },
        nextQuest = "ten_fragments",
    },
    {
        id = "ten_fragments",
        title = "Lore Keeper",
        description = "Collect 10 Lore Fragments -- explore every layer!",
        layer = 1,
        objective = "fragments",
        target = 10,
        reward = { motes = 20 },
        nextQuest = "reach_stormwall",
    },

    -- LAYER 4 QUESTS (The Stormwall)
    {
        id = "reach_stormwall",
        title = "Storm Breaker",
        description = "Reach 50 total Motes and brave The Stormwall",
        layer = 3,
        objective = "reach_layer",
        target = 4,
        reward = { motes = 20 },
        nextQuest = "stormwall_flight",
    },
    {
        id = "stormwall_flight",
        title = "Wind Rider",
        description = "Fly for 60 seconds through The Stormwall's winds",
        layer = 4,
        objective = "fly_time",
        target = 60,
        reward = { motes = 15 },
        nextQuest = "all_starfish",
    },
    {
        id = "all_starfish",
        title = "Starfish Whisperer",
        description = "Find 7 hidden Brown Starfish across all layers",
        layer = 1,
        objective = "starfish_count",
        target = 7,
        reward = { motes = 25 },
        nextQuest = "helping_angel",
    },
    {
        id = "helping_angel",
        title = "Helping Angel",
        description = "Send 10 Angel Mails and 10 Blessings -- be the light",
        layer = 1,
        objective = "helper_score",
        target = 20,
        reward = { motes = 30 },
        nextQuest = "reach_luminance",
    },

    -- LAYER 5 QUESTS (The Luminance)
    {
        id = "reach_luminance",
        title = "The Luminance Awaits",
        description = "Reach 100 total Motes to enter The Luminance",
        layer = 4,
        objective = "reach_layer",
        target = 5,
        reward = { motes = 25 },
        nextQuest = "luminance_fragments",
    },
    {
        id = "luminance_fragments",
        title = "Truth Seeker",
        description = "Collect 30 Lore Fragments -- the story grows clearer",
        layer = 1,
        objective = "fragments",
        target = 30,
        reward = { motes = 30 },
        nextQuest = "guardian_trial",
    },
    {
        id = "guardian_trial",
        title = "Guardian's Test",
        description = "Complete a Guardian Trial with another Angel",
        layer = 2,
        objective = "trials_completed",
        target = 1,
        reward = { motes = 25 },
        nextQuest = "reach_empyrean",
    },

    -- LAYER 6 QUESTS (The Empyrean)
    {
        id = "reach_empyrean",
        title = "The Empyrean",
        description = "Reach 250 total Motes -- ascend to the highest cloud",
        layer = 5,
        objective = "reach_layer",
        target = 6,
        reward = { motes = 50 },
        nextQuest = "final_collection",
    },
    {
        id = "final_collection",
        title = "The Full Story",
        description = "Collect 50 Lore Fragments -- Angel's story nears completion",
        layer = 1,
        objective = "fragments",
        target = 50,
        reward = { motes = 50 },
        nextQuest = "true_angel",
    },
    {
        id = "true_angel",
        title = "True Angel",
        description = "Max wings, 20+ blessings, 50+ fragments, all starfish -- become the light",
        layer = 1,
        objective = "true_angel_score",
        target = 1,
        reward = { motes = 100 },
        nextQuest = nil, -- THE END (for now)
    },
}

-- Quick lookup
local QuestById: { [string]: any } = {}
for _, quest in ipairs(QUESTS) do
    QuestById[quest.id] = quest
end

-- =========================================================================
-- LIFECYCLE
-- =========================================================================

function QuestService:KnitInit(): ()
    print("[QuestService] Quest system initialized with " .. #QUESTS .. " quests")
end

function QuestService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")

    local ok, result = pcall(function() return Knit.GetService("SoundService") end)
    SoundService = ok and result or nil

    -- Listen for players joining to initialize quest data
    Players.PlayerAdded:Connect(function(player: Player)
        self:OnPlayerJoined(player)
    end)

    -- Handle players already in game (if KnitStart fires after some players joined)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:OnPlayerJoined(player)
        end)
    end

    print("[QuestService] Started")
end

-- =========================================================================
-- CLIENT-FACING METHODS
-- =========================================================================

function QuestService.Client:AcceptQuest(player: Player, questId: string): ()
    self.Server:AcceptQuest(player, questId)
end

function QuestService.Client:GetActiveQuest(player: Player): any?
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then
        return nil
    end
    local quest = QuestById[data.activeQuest]
    if not quest then
        return nil
    end
    return {
        questId = quest.id,
        title = quest.title,
        description = quest.description,
        progress = self.Server:CalculateProgress(player, quest),
        target = quest.target,
        reward = quest.reward,
    }
end

-- =========================================================================
-- PLAYER SETUP
-- =========================================================================

function QuestService:OnPlayerJoined(player: Player): ()
    local data = DataService:GetData(player)
    if not data then return end

    -- Initialize quest data if missing
    if not data.activeQuest then
        data.activeQuest = "first_motes"
        data.questProgress = 0
        data.completedQuests = {}
    end

    -- Send current quest state to client
    task.delay(3, function()
        self:SyncQuest(player)
    end)
end

-- =========================================================================
-- QUEST ACCEPTANCE & SYNCING
-- =========================================================================

function QuestService:AcceptQuest(player: Player, questId: string): ()
    local data = DataService:GetData(player)
    if not data then return end

    local quest = QuestById[questId]
    if not quest then return end

    -- Don't accept if already completed
    if data.completedQuests and data.completedQuests[questId] then
        return
    end

    data.activeQuest = questId
    data.questProgress = 0
    self:SyncQuest(player)
end

function QuestService:SyncQuest(player: Player): ()
    local data = DataService:GetData(player)
    if not data then return end

    local questId: string? = data.activeQuest
    local quest = questId and QuestById[questId] or nil

    if not quest then
        -- All quests done
        self.Client.QuestUpdate:Fire(player, {
            status = "all_complete",
            completedCount = data.completedQuests and self:_countTable(data.completedQuests) or 0,
        })
        return
    end

    -- Calculate current progress based on objective type
    local progress: number = self:CalculateProgress(player, quest)
    data.questProgress = progress

    self.Client.QuestUpdate:Fire(player, {
        status = "active",
        questId = quest.id,
        title = quest.title,
        description = quest.description,
        progress = progress,
        target = quest.target,
        reward = quest.reward,
    })

    -- Auto-complete if already met
    if progress >= quest.target then
        self:CompleteQuest(player, quest)
    end
end

-- =========================================================================
-- PROGRESS CALCULATION (13 objective types)
-- =========================================================================

function QuestService:CalculateProgress(player: Player, quest: any): number
    local data = DataService:GetData(player)
    if not data then return 0 end

    local objective: string = quest.objective

    if objective == "collect_motes" or objective == "total_motes" then
        return data.motes or 0

    elseif objective == "collect_motes_in_session" then
        return data.questProgress or 0 -- tracked incrementally

    elseif objective == "use_pads" then
        return data.questProgress or 0 -- tracked via events

    elseif objective == "fly_time" then
        return data.questProgress or 0 -- tracked via events

    elseif objective == "forge_wings" then
        return data.questProgress or 0 -- tracked when forge used

    elseif objective == "wing_level" then
        return data.wingLevel or 1

    elseif objective == "reach_layer" then
        return data.layerIndex or 1

    elseif objective == "send_blessing" then
        return data.blessingsGiven or 0

    elseif objective == "starfish_count" then
        local count: number = 0
        if data.starfishFound then
            for _ in pairs(data.starfishFound) do
                count = count + 1
            end
        end
        return count

    elseif objective == "fragments" then
        local count: number = 0
        if data.collectedFragments then
            for _ in pairs(data.collectedFragments) do
                count = count + 1
            end
        end
        return count

    elseif objective == "mail_sent" then
        return data.mailSentCount or 0

    elseif objective == "total_blessings" then
        return data.blessingsGiven or 0

    elseif objective == "trials_completed" then
        local count: number = 0
        if data.trialsCompleted then
            for _ in pairs(data.trialsCompleted) do
                count = count + 1
            end
        end
        return count

    elseif objective == "helper_score" then
        -- Combined: mail sent + blessings given
        return (data.mailSentCount or 0) + (data.blessingsGiven or 0)

    elseif objective == "true_angel_score" then
        -- Check all conditions: max wings, 20+ blessings, 50+ fragments, all starfish
        local wingOk: boolean = (data.wingLevel or 1) >= 10
        local blessOk: boolean = (data.blessingsGiven or 0) >= 20
        local fragCount: number = 0
        if data.collectedFragments then
            for _ in pairs(data.collectedFragments) do
                fragCount = fragCount + 1
            end
        end
        local fragOk: boolean = fragCount >= 50
        local starCount: number = 0
        if data.starfishFound then
            for _ in pairs(data.starfishFound) do
                starCount = starCount + 1
            end
        end
        local starOk: boolean = starCount >= 10

        if wingOk and blessOk and fragOk and starOk then
            return 1
        end
        return 0
    end

    return 0
end

-- =========================================================================
-- QUEST COMPLETION
-- =========================================================================

function QuestService:CompleteQuest(player: Player, quest: any): ()
    local data = DataService:GetData(player)
    if not data then return end

    -- Mark completed
    if not data.completedQuests then
        data.completedQuests = {}
    end
    data.completedQuests[quest.id] = true

    -- Award rewards
    if quest.reward.motes then
        MoteService:AwardMotes(player, quest.reward.motes, "quest_complete")
    end

    -- Play completion sound
    if SoundService then
        SoundService:PlaySFXForPlayer(player, "level_up", 0.6)
    end

    -- Notify client via QuestComplete signal
    self.Client.QuestComplete:Fire(player, {
        questId = quest.id,
        title = quest.title,
        reward = quest.reward,
    })

    -- Also send QuestUpdate for UI consistency
    self.Client.QuestUpdate:Fire(player, {
        status = "completed",
        questId = quest.id,
        title = quest.title,
        reward = quest.reward,
    })

    -- Auto-advance to next quest
    if quest.nextQuest then
        data.activeQuest = quest.nextQuest
        data.questProgress = 0

        -- Sync the new quest after a short delay (let completion UI show)
        task.delay(3, function()
            self:SyncQuest(player)
        end)
    else
        data.activeQuest = nil
        data.questProgress = 0
    end

    print("[QuestService] " .. player.Name .. " completed quest: " .. quest.title)
end

-- =========================================================================
-- EVENT HOOKS -- called by other services to update quest progress
-- =========================================================================

function QuestService:OnMoteCollected(player: Player, amount: number): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    local quest = QuestById[data.activeQuest]
    if not quest then return end

    if quest.objective == "collect_motes_in_session" then
        data.questProgress = (data.questProgress or 0) + amount
    end

    -- Check all mote-related quests
    if quest.objective == "collect_motes" or quest.objective == "total_motes" or quest.objective == "collect_motes_in_session" then
        self:SyncQuest(player)
    end
end

function QuestService:OnPadUsed(player: Player, padType: string): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    local quest = QuestById[data.activeQuest]
    if not quest or quest.objective ~= "use_pads" then return end

    data.questProgress = (data.questProgress or 0) + 1
    self:SyncQuest(player)
end

function QuestService:OnFlightTime(player: Player, seconds: number): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    local quest = QuestById[data.activeQuest]
    if not quest or quest.objective ~= "fly_time" then return end

    data.questProgress = (data.questProgress or 0) + seconds
    self:SyncQuest(player)
end

function QuestService:OnWingForged(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    local quest = QuestById[data.activeQuest]
    if not quest then return end

    if quest.objective == "forge_wings" then
        data.questProgress = (data.questProgress or 0) + 1
    end

    -- Wing level quests auto-calculate from data
    self:SyncQuest(player)
end

function QuestService:OnBlessingGiven(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

function QuestService:OnLayerReached(player: Player, layerIndex: number): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

function QuestService:OnStarfishFound(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

function QuestService:OnFragmentCollected(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

function QuestService:OnMailSent(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

function QuestService:OnTrialCompleted(player: Player): ()
    local data = DataService:GetData(player)
    if not data or not data.activeQuest then return end

    self:SyncQuest(player)
end

-- =========================================================================
-- UTILITIES
-- =========================================================================

function QuestService:_countTable(tbl: { [any]: any }): number
    local count: number = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

return QuestService
