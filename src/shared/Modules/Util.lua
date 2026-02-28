--[[
    Util.lua — Game-wide constants and utility for Angel Cloud ROBLOX
    ModuleScript → ReplicatedStorage.Modules.Util

    Single source of truth for all magic numbers. If a value is used
    in more than one file, it belongs here.
]]

local Util = {}

-- Player Movement
Util.WALK_SPEED = 28
Util.JUMP_POWER = 70
Util.JUMP_HEIGHT = 12

-- Flight
Util.FLIGHT_SPEED = 80
Util.FLIGHT_VERTICAL_SPEED = 50
Util.GLIDE_FALL_SPEED = -4
Util.GLIDE_HORIZONTAL_BOOST = 2.5

-- Camera / FOV
Util.BASE_FOV = 70
Util.GLIDE_FOV = 80
Util.FLIGHT_FOV = 95
Util.FOV_LERP_SPEED = 0.1

-- Stamina
Util.MAX_STAMINA = 100
Util.STAMINA_DRAIN_RATE = 5
Util.STAMINA_REGEN_RATE = 8
Util.STAMINA_REGEN_DELAY = 2
Util.GLIDE_STAMINA_DRAIN = 2

-- Motes (currency)
Util.MOTE_RESPAWN_TIME = 30
Util.MOTE_COLLECTION_RADIUS = 6
Util.MOTE_BASE_VALUE = 1
Util.MOTE_BONUS_MULTIPLIER = 1.5

-- Blessings
Util.BLESSING_COOLDOWN = 30
Util.BLESSING_RANGE = 50
Util.BLESSING_MOTE_REWARD = 2
Util.BLESSING_CHAIN_BONUS = 1
Util.BLESSING_CHAIN_CLEANUP_INTERVAL = 30

-- Quests
Util.QUEST_NOTIFICATION_DURATION = 5
Util.QUEST_COMPLETION_CELEBRATION_TIME = 3

-- Economy
Util.DAILY_LOGIN_REWARD = 10
Util.MAX_DAILY_EARN = 500

-- Progression
Util.LEVEL_NAMES = {
    "Newborn",
    "Young Angel",
    "Growing Angel",
    "Helping Angel",
    "Guardian Angel",
    "Angel",
}

Util.LEVEL_THRESHOLDS = {
    Newborn = 0,
    ["Young Angel"] = 10,
    ["Growing Angel"] = 25,
    ["Helping Angel"] = 50,
    ["Guardian Angel"] = 100,
    Angel = 250,
}

-- Data
Util.DATA_STORE_NAME = "PlayerData_v2"
Util.AUTO_SAVE_INTERVAL = 300
Util.DATA_RETRY_ATTEMPTS = 3
Util.DATA_RETRY_DELAY = 2

-- World Generation
Util.WORLD_SEED = 42
Util.CLOUD_PLATFORM_MIN_SIZE = Vector3.new(10, 2, 10)
Util.CLOUD_PLATFORM_MAX_SIZE = Vector3.new(40, 4, 40)

-- Network
Util.REMOTE_RATE_LIMIT = 0.2
Util.REMOTE_TIMEOUT = 30

-- UI
Util.UI_TWEEN_DURATION = 0.3
Util.NOTIFICATION_DISPLAY_TIME = 4
Util.HUD_UPDATE_RATE = 0.1

-- Audio
Util.MUSIC_FADE_TIME = 2
Util.SFX_DEFAULT_VOLUME = 0.5
Util.MUSIC_DEFAULT_VOLUME = 0.3

-- Performance
Util.MAX_ACTIVE_PARTICLES = 50
Util.STREAMING_TARGET_RADIUS = 256
Util.LOD_DISTANCE_NEAR = 100
Util.LOD_DISTANCE_FAR = 400

-- Safety
Util.MAX_CHAT_MESSAGE_LENGTH = 200
Util.MODERATION_QUEUE_SIZE = 50
Util.REPORT_COOLDOWN = 60

-- Easter Eggs
Util.STARFISH_TOTAL_COUNT = 10
Util.EASTER_EGG_HINT_CHANCE = 0.15

-- Math helpers (inline for convenience)
function Util.Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

function Util.InverseLerp(a: number, b: number, value: number): number
    if a == b then return 0 end
    return (value - a) / (b - a)
end

function Util.Clamp01(value: number): number
    return math.clamp(value, 0, 1)
end

return Util
