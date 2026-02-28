--[[
    Economy.lua — Halo Economy configuration
    Sourced from docs/halo_economy.md

    Two currencies:
    - Light Motes: progression currency, NEVER purchasable
    - Halos: cosmetic currency, purchasable via Robux

    Rule: Motes gate progression. Halos gate cosmetics. They NEVER overlap.
]]

local Economy = {}

-- =========================================================================
-- HALO FAUCETS (Earn Sources)
-- =========================================================================

Economy.DailyActivities = {
    { source = "daily_login",       halos = 10,  limit = 1,  resetType = "midnight_utc" },
    { source = "streak_bonus_7day", halos = 50,  limit = 1,  resetType = "after_claim" },
    { source = "send_3_angel_mails", halos = 15, limit = 1,  resetType = "midnight_utc" },
    { source = "host_cloud_visitor", halos = 10, limit = 5,  resetType = "midnight_utc" },
    { source = "wind_temple_run",   halos = 25,  limit = nil, resetType = "1hr_cooldown" },
    { source = "guardian_trial",    halos = 30,  limit = 1,  resetType = "per_trial_24hr" },
}

Economy.OneTimeRewards = {
    { source = "first_visitor_hosted",  halos = 50 },
    { source = "easter_egg_discovered", halos = 100 },  -- per egg, 7 eggs = 700 total
    { source = "cross_platform_link",   halos = 100 },
    { source = "first_trial_completed", halos = 50 },
    { source = "reach_angel_level",     halos = 100 },  -- per level, 6 levels = 600 total
}

Economy.EventFaucets = {
    { source = "community_event",       halos = 40,  frequency = "weekly" },
    { source = "seasonal_event",        halos = 200, frequency = "quarterly" },
    { source = "community_milestone",   halos = 25,  frequency = "collective_goal" },
}

-- =========================================================================
-- HALO SINKS (Spend Targets)
-- =========================================================================

Economy.WingSkins = {
    { id = "cloud_wisp",      name = "Cloud Wisp",       rarity = "Common",    price = 150 },
    { id = "stardust",        name = "Stardust",         rarity = "Common",    price = 150 },
    { id = "moonbeam",        name = "Moonbeam",         rarity = "Common",    price = 150 },
    { id = "solar_flare",     name = "Solar Flare",      rarity = "Rare",      price = 500 },
    { id = "nebula",          name = "Nebula",           rarity = "Rare",      price = 500 },
    { id = "aurora_borealis", name = "Aurora Borealis",  rarity = "Epic",      price = 1200 },
    { id = "crystalline",     name = "Crystalline",      rarity = "Epic",      price = 1200 },
    { id = "celestial",       name = "Celestial",        rarity = "Legendary", price = 2500 },
}

Economy.Emotes = {
    { id = "wave",            name = "Wave",             price = 0 },
    { id = "thumbs_up",       name = "Thumbs Up",        price = 0 },
    { id = "reflect",         name = "Reflect",          price = 0 },
    { id = "happy_dance",     name = "Happy Dance",      price = 100 },
    { id = "cloud_surf",      name = "Cloud Surf",       price = 150 },
    { id = "angel_pose",      name = "Angel Pose",       price = 200 },
    { id = "sparkle_spin",    name = "Sparkle Spin",     price = 250 },
    { id = "flying_backflip", name = "Flying Backflip",  price = 400 },
    { id = "halo_toss",       name = "Halo Toss",        price = 500 },
    { id = "aurora_burst",    name = "Aurora Burst",      price = 1000 },
}

Economy.HaloEffects = {
    { id = "classic_gold",    name = "Classic Gold",     price = 0 },
    { id = "silver_shimmer",  name = "Silver Shimmer",   price = 300 },
    { id = "cyan_glow",       name = "Cyan Glow",        price = 500 },
    { id = "purple_lightning", name = "Purple Lightning", price = 800 },
    { id = "rainbow_pulse",   name = "Rainbow Pulse",    price = 1200 },
    { id = "prismatic",       name = "Prismatic",        price = 1500 },
    { id = "constellation",   name = "Constellation",    price = 2000 },
}

Economy.FurniturePriceRanges = {
    Basic     = { min = 30,  max = 80 },
    Standard  = { min = 100, max = 250 },
    Premium   = { min = 300, max = 600 },
    Legendary = { min = 800, max = 1500 },
}

-- =========================================================================
-- ROBUX → HALO CONVERSION
-- =========================================================================

Economy.RobuxBundles = {
    { id = "small",  name = "Small Bundle",  robux = 49,  halos = 500 },
    { id = "medium", name = "Medium Bundle", robux = 99,  halos = 1500 },
    { id = "large",  name = "Large Bundle",  robux = 249, halos = 5000 },
}

-- =========================================================================
-- GAME PASSES
-- =========================================================================

Economy.GamePasses = {
    { id = "cloud_supporter",     name = "Cloud Supporter",      robux = 99,  haloBonus = 500, duration = nil },
    { id = "halo_boost",          name = "Halo Boost",           robux = 199, multiplier = 2,  duration = 30 },
    { id = "cloud_base_expansion", name = "Cloud Base Expansion", robux = 149, haloBonus = 0,  duration = nil },
    { id = "angel_mail_plus",     name = "Angel Mail Plus",      robux = 49,  haloBonus = 0,  duration = nil },
}

-- =========================================================================
-- ECONOMY HEALTH METRICS
-- =========================================================================

Economy.HealthMetrics = {
    MEDIAN_HALO_HEALTHY_MIN = 200,
    MEDIAN_HALO_HEALTHY_MAX = 2000,
    MEDIAN_HALO_RED_FLAG = 5000,
    ZERO_HALO_RED_FLAG_PCT = 0.15,
    DAILY_FAUCET_HEALTHY_MIN = 50,
    DAILY_FAUCET_HEALTHY_MAX = 150,
    DAILY_FAUCET_RED_FLAG = 300,
    TIME_TO_FIRST_PURCHASE_MAX_SESSIONS = 7,
}

-- =========================================================================
-- DAILY EARN ESTIMATES
-- =========================================================================

Economy.DailyEstimates = {
    FLOOR_MINIMAL = 10,     -- login only, ~5 min
    CASUAL = 60,            -- login + mail + 1 visitor, ~20 min
    ACTIVE = 130,           -- login + mail + visitors + temple, ~45 min
    DEDICATED = 200,        -- all sources, ~90 min
}

return Economy
