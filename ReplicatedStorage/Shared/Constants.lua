--[[
	Constants.lua — Game-wide constants for Angel Cloud ROBLOX
	ModuleScript → ReplicatedStorage.Shared.Constants

	Single source of truth for all magic numbers. If a value is used
	in more than one file, it belongs here.
]]

local Constants = {}

-- Player Movement
Constants.WALK_SPEED = 28
Constants.JUMP_POWER = 70
Constants.JUMP_HEIGHT = 12

-- Flight
Constants.FLIGHT_SPEED = 80
Constants.FLIGHT_VERTICAL_SPEED = 50
Constants.GLIDE_FALL_SPEED = -4
Constants.GLIDE_HORIZONTAL_BOOST = 2.5

-- Camera / FOV
Constants.BASE_FOV = 70
Constants.GLIDE_FOV = 80
Constants.FLIGHT_FOV = 95
Constants.FOV_LERP_SPEED = 0.1

-- Stamina
Constants.MAX_STAMINA = 100
Constants.STAMINA_DRAIN_RATE = 5 -- per second while flying
Constants.STAMINA_REGEN_RATE = 8 -- per second while grounded
Constants.STAMINA_REGEN_DELAY = 2 -- seconds before regen starts after landing
Constants.GLIDE_STAMINA_DRAIN = 2 -- per second while gliding

-- Motes (currency)
Constants.MOTE_RESPAWN_TIME = 30 -- seconds
Constants.MOTE_COLLECTION_RADIUS = 6
Constants.MOTE_BASE_VALUE = 1
Constants.MOTE_BONUS_MULTIPLIER = 1.5 -- for hard-to-reach motes

-- Blessings
Constants.BLESSING_COOLDOWN = 30 -- seconds between blessings to same player
Constants.BLESSING_RANGE = 50 -- studs
Constants.BLESSING_MOTE_REWARD = 2
Constants.BLESSING_CHAIN_BONUS = 1 -- extra motes per chain link
Constants.BLESSING_CHAIN_CLEANUP_INTERVAL = 30 -- seconds

-- Quests
Constants.QUEST_NOTIFICATION_DURATION = 5 -- seconds
Constants.QUEST_COMPLETION_CELEBRATION_TIME = 3

-- Economy
Constants.DAILY_LOGIN_REWARD = 10 -- halos
Constants.MAX_DAILY_EARN = 500 -- halos per day cap (anti-exploit)

-- Progression
Constants.LEVEL_NAMES = {
	"Newborn",
	"Young Angel",
	"Growing Angel",
	"Helping Angel",
	"Guardian Angel",
	"Angel",
}

Constants.LEVEL_THRESHOLDS = {
	Newborn = 0,
	["Young Angel"] = 10,
	["Growing Angel"] = 25,
	["Helping Angel"] = 50,
	["Guardian Angel"] = 100,
	Angel = 250,
}

-- Data
Constants.DATA_STORE_NAME = "PlayerData_v2"
Constants.AUTO_SAVE_INTERVAL = 300 -- 5 minutes
Constants.DATA_RETRY_ATTEMPTS = 3
Constants.DATA_RETRY_DELAY = 2 -- seconds

-- World Generation
Constants.WORLD_SEED = 42
Constants.CLOUD_PLATFORM_MIN_SIZE = Vector3.new(10, 2, 10)
Constants.CLOUD_PLATFORM_MAX_SIZE = Vector3.new(40, 4, 40)

-- Network
Constants.REMOTE_RATE_LIMIT = 0.2 -- minimum seconds between client→server fires
Constants.REMOTE_TIMEOUT = 30 -- seconds to wait for remote to exist

-- UI
Constants.UI_TWEEN_DURATION = 0.3 -- seconds for UI transitions
Constants.NOTIFICATION_DISPLAY_TIME = 4
Constants.HUD_UPDATE_RATE = 0.1 -- seconds between HUD refreshes

-- Audio
Constants.MUSIC_FADE_TIME = 2 -- seconds
Constants.SFX_DEFAULT_VOLUME = 0.5
Constants.MUSIC_DEFAULT_VOLUME = 0.3

-- Performance
Constants.MAX_ACTIVE_PARTICLES = 50
Constants.STREAMING_TARGET_RADIUS = 256
Constants.LOD_DISTANCE_NEAR = 100
Constants.LOD_DISTANCE_FAR = 400

-- Safety
Constants.MAX_CHAT_MESSAGE_LENGTH = 200
Constants.MODERATION_QUEUE_SIZE = 50
Constants.REPORT_COOLDOWN = 60 -- seconds between player reports

-- Easter Eggs
Constants.STARFISH_TOTAL_COUNT = 10 -- total brown starfish hidden in game
Constants.EASTER_EGG_HINT_CHANCE = 0.15 -- 15% chance NPC drops a hint

return Constants
