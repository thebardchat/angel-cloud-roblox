--[[
    Enums.lua — Game-specific enumerations for Angel Cloud ROBLOX
    ModuleScript → ReplicatedStorage.Modules.Enums
]]

local Enums = {}

Enums.FlightState = {
    Grounded = "Grounded",
    Gliding = "Gliding",
    Flying = "Flying",
}

Enums.MessageType = {
    Welcome = "welcome",
    Info = "info",
    Warning = "warning",
    LevelUp = "level_up",
    QuestComplete = "quest_complete",
    Starfish = "starfish",
    StarfishComplete = "starfish_complete",
}

Enums.CosmeticCategory = {
    WingSkins = "WingSkins",
    TrailEffects = "TrailEffects",
    EmotePacks = "EmotePacks",
    CloudMaterials = "CloudMaterials",
    NameGlow = "NameGlow",
    StarterPack = "StarterPack",
    Special = "Special",
}

Enums.FragmentCategory = {
    Decision = "Decision",
    Emotion = "Emotion",
    Relationship = "Relationship",
    Strength = "Strength",
    Suffering = "Suffering",
    Guardian = "Guardian",
    Angel = "Angel",
}

Enums.QuestObjective = {
    CollectMotes = "collect_motes",
    UsePads = "use_pads",
    FlyTime = "fly_time",
    ForgeWings = "forge_wings",
    WingLevel = "wing_level",
    ReachLayer = "reach_layer",
    GiveBlessing = "give_blessing",
    ReceiveBlessing = "receive_blessing",
    CollectFragment = "collect_fragment",
    SendMail = "send_mail",
    CompleteTrial = "complete_trial",
    FindStarfish = "find_starfish",
    HelpNewborn = "help_newborn",
}

Enums.StaminaState = {
    Normal = "normal",
    Draining = "draining",
    Recovering = "recovering",
    Empty = "empty",
}

Enums.HALTState = {
    Normal = "normal",
    Warning = "warning",
    Slowdown = "slowdown",
    Rest = "rest",
}

Enums.DevilState = {
    Patrol = "patrol",
    Chase = "chase",
    Steal = "steal",
    Scare = "scare",
    Flee = "flee",
}

Enums.TrialState = {
    Queued = "queued",
    Active = "active",
    Complete = "complete",
    Failed = "failed",
}

return Enums
