--[[
    Wings.lua — Wing Progression System configuration
    Sourced from docs/wing_progression.md

    Wings are the primary visible progression indicator.
    Wings are NOT purchasable — they are EARNED.
]]

local Wings = {}

-- =========================================================================
-- BASE WING TIERS (earned via Angel Level)
-- =========================================================================

Wings.Tiers = {
    {
        level = 1,
        levelName = "Newborn",
        wingName = "Spark Wings",
        motesRequired = 0,
        visual = "Tiny translucent nubs, faint white glow",
        particle = "Soft sparkle on jump",
        abilities = { glide = false, flight = false, shield = false, windChannel = false, mentorGlow = false },
        color = Color3.fromRGB(245, 245, 255),
        tipColor = Color3.fromRGB(220, 225, 240),
        idleAnimation = "Slight glow pulse (1.5s cycle)",
    },
    {
        level = 2,
        levelName = "Young Angel",
        wingName = "Fledgling Wings",
        motesRequired = 10,
        visual = "Small feathered wings, soft white, gentle movement",
        particle = "Light trail when gliding",
        abilities = { glide = true, flight = false, shield = false, windChannel = false, mentorGlow = false },
        color = Color3.fromRGB(230, 240, 255),
        tipColor = Color3.fromRGB(200, 220, 245),
        idleAnimation = "Gentle fold/unfold (3s cycle)",
    },
    {
        level = 3,
        levelName = "Growing Angel",
        wingName = "Courage Wings",
        motesRequired = 25,
        visual = "Medium wings, gold trim, visible feather detail",
        particle = "Gold dust on flap",
        abilities = { glide = true, flight = false, shield = false, windChannel = false, mentorGlow = false },
        color = Color3.fromRGB(220, 245, 235),
        tipColor = Color3.fromRGB(190, 230, 215),
        idleAnimation = "Slow flap (4s cycle) + gold dust",
    },
    {
        level = 4,
        levelName = "Helping Angel",
        wingName = "Kindness Wings",
        motesRequired = 50,
        visual = "Large wings, cyan energy veins, flowing motion",
        particle = "Cyan energy trails",
        abilities = { glide = true, flight = false, shield = true, windChannel = false, mentorGlow = false },
        color = Color3.fromRGB(235, 220, 255),
        tipColor = Color3.fromRGB(210, 195, 240),
        idleAnimation = "Flowing motion like underwater (5s cycle)",
    },
    {
        level = 5,
        levelName = "Guardian Angel",
        wingName = "Resilience Wings",
        motesRequired = 100,
        visual = "Full wingspan, purple lightning crackling along edges",
        particle = "Lightning spark on takeoff",
        abilities = { glide = true, flight = true, shield = true, windChannel = true, mentorGlow = false },
        color = Color3.fromRGB(255, 245, 220),
        tipColor = Color3.fromRGB(240, 225, 190),
        idleAnimation = "Crackling energy + occasional lightning arc",
    },
    {
        level = 6,
        levelName = "Angel",
        wingName = "Radiant Wings",
        motesRequired = 250,
        visual = "Massive prismatic wings, shifting colors, aurora trails",
        particle = "Full aurora particle stream",
        abilities = { glide = true, flight = true, shield = true, windChannel = true, mentorGlow = true },
        color = Color3.fromRGB(255, 255, 255),
        tipColor = Color3.fromRGB(240, 240, 250),
        idleAnimation = "Continuous aurora flow + color shift",
    },
}

-- =========================================================================
-- COSMETIC WING SKINS (change appearance only, purchased with Halos)
-- =========================================================================

Wings.EarnableSkins = {
    { id = "cloud_wisp",  name = "Cloud Wisp",  unlockCondition = "Collect 10 Lore Fragments",              visual = "Wispy, cloud-like translucent wings" },
    { id = "stardust",    name = "Stardust",     unlockCondition = "Complete 3 different Guardian Trials",   visual = "Glittering star-speckled wings" },
    { id = "moonbeam",    name = "Moonbeam",     unlockCondition = "Send 50 Angel Mails (lifetime total)",  visual = "Soft silver-blue luminescent wings" },
}

Wings.PurchasableSkins = {
    { id = "solar_flare",     name = "Solar Flare",     rarity = "Rare",      price = 500,  visual = "Warm orange-red with ember particles" },
    { id = "nebula",          name = "Nebula",           rarity = "Rare",      price = 500,  visual = "Deep purple with swirling gas cloud effect" },
    { id = "aurora_borealis", name = "Aurora Borealis",  rarity = "Epic",      price = 1200, visual = "Shifting green-blue northern lights effect" },
    { id = "crystalline",     name = "Crystalline",      rarity = "Epic",      price = 1200, visual = "Ice-crystal structured wings, refractive sparkle" },
    { id = "celestial",       name = "Celestial",        rarity = "Legendary", price = 2500, visual = "Deep space black with constellation patterns" },
}

Wings.ExclusiveSkins = {
    { id = "dreamer",    name = "Dreamer",    unlockMethod = "Easter Egg: The Founder's Loft",  visual = "Soft pastel watercolor wings" },
    { id = "windwalker", name = "Windwalker", unlockMethod = "Easter Egg: The First Breath",    visual = "Transparent with visible wind currents" },
    { id = "stargazer",  name = "Stargazer",  unlockMethod = "Collect all 65 Lore Fragments",   visual = "Prismatic constellation map wings" },
    { id = "supporter",  name = "Supporter",  unlockMethod = "Cloud Supporter Game Pass",       visual = "Gold-trimmed with Supporter badge glow" },
}

-- =========================================================================
-- WING GAUGE (Stamina System)
-- =========================================================================

Wings.Gauge = {
    MAX_GAUGE = 100,
    GLIDE_DRAIN_RATE = 5,       -- units/sec
    FLIGHT_DRAIN_RATE = 10,     -- units/sec
    SHIELD_ACTIVATION_COST = 15, -- instant
    WIND_CHANNEL_COST = 8,      -- per cycle
    PASSIVE_REGEN = 3,          -- units/sec grounded
    REFLECTION_POOL_REGEN = 10, -- units/sec
}

Wings.GaugeColors = {
    { threshold = 0.60, color = Color3.fromRGB(0, 200, 100),  feedback = "Normal" },
    { threshold = 0.30, color = Color3.fromRGB(255, 215, 0),  feedback = "Subtle pulse animation" },
    { threshold = 0.10, color = Color3.fromRGB(255, 100, 100), feedback = "Fast pulse + warning sound" },
    { threshold = 0.00, color = Color3.fromRGB(255, 50, 50),  feedback = "Flashing Red — forced landing" },
}

-- =========================================================================
-- HALT INTEGRATION (session time modifiers)
-- =========================================================================

Wings.HALTModifiers = {
    { sessionMinutes = 0,   drainMultiplier = 1.0 },
    { sessionMinutes = 45,  drainMultiplier = 1.2 },
    { sessionMinutes = 90,  drainMultiplier = 1.4 },
    { sessionMinutes = 120, drainMultiplier = 1.4 },  -- + UI banner
}

-- =========================================================================
-- WING FORGE
-- =========================================================================

Wings.Forge = {
    BASE_COST = 5,           -- motes per first upgrade
    COST_INCREMENT = 2,      -- additional motes per level
    MAX_LEVEL = 10,
    SCALE_PER_LEVEL = 0.15,  -- wing size increase per forge level
}

-- =========================================================================
-- ASCENSION CINEMATIC (10 seconds)
-- =========================================================================

Wings.AscensionSequence = {
    { time = 0.0, event = "Screen flash white. Player frozen." },
    { time = 0.5, event = "Beam of light descends." },
    { time = 1.5, event = "Old wings dissolve into particles." },
    { time = 2.5, event = "New wings materialize feather by feather." },
    { time = 4.0, event = "Player lifts off ground. Camera pulls back." },
    { time = 5.5, event = "Cloud staircase materializes toward next layer." },
    { time = 7.0, event = "UI celebration with level title." },
    { time = 8.5, event = "Nearby players see beacon of light." },
    { time = 10.0, event = "Player regains control. Staircase remains 30s." },
}

-- =========================================================================
-- HELPERS
-- =========================================================================

function Wings.GetTierForLevel(level: number)
    return Wings.Tiers[math.clamp(level, 1, #Wings.Tiers)]
end

function Wings.GetAbilities(level: number): { [string]: boolean }
    local tier = Wings.GetTierForLevel(level)
    return tier and tier.abilities or { glide = false, flight = false, shield = false, windChannel = false, mentorGlow = false }
end

function Wings.GetForgeUpgradeCost(currentForgeLevel: number): number
    return Wings.Forge.BASE_COST + (currentForgeLevel - 1) * Wings.Forge.COST_INCREMENT
end

return Wings
