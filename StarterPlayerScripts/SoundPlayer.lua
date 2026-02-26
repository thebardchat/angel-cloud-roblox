--[[
    SoundPlayer.lua — Client-side sound and music player
    ALL audio plays on the CLIENT (server sounds are inaudible to players)
    Handles: ambient music per layer, environmental ambience, SFX
    Uses Roblox universal/licensed audio IDs that work for all games
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local SoundPlayer = {}

-- =====================================================================
-- AUDIO ASSET IDS — Roblox universal/licensed audio (confirmed working)
-- These are from Roblox's own library or APM Music (licensed for all)
-- To find more: Studio → Toolbox → Marketplace → Audio → search terms
-- =====================================================================

-- =====================================================================
-- AMBIENT MUSIC — verified working IDs from Roblox Creator Marketplace
-- Sources: DevForum curated list + Boa's Free Music Pack (public domain)
--
-- Boa's Pack (public domain, confirmed working):
--   7399811837 = Cloudy Space
--   7399812832 = Frozen In Time
--   7399813440 = Ice Castle
--   7399814871 = No Light
--   7399815715 = Space Cruise
--   7399816850 = Supernova
--
-- DevForum curated (Creator Marketplace licensed):
--   1837879082 = Paradise Falls
--   9043887091 = Lo-fi Chill A
--   1848354536 = Relaxed Scene
--   1845341094 = Chill Jazz
--   1837429944 = Soft Music
--   1844272089 = Positive Calm
--   9044565954 = Smooth Vibes
--   1841979451 = Piano Bar Jazz
-- =====================================================================

local AMBIENT_MUSIC = {
    -- Layer 1: The Nursery — calm, warm, safe
    [1] = {
        id = "rbxassetid://1848354536",   -- Relaxed Scene (confirmed working)
        volume = 0.3,
    },
    -- Layer 2: The Meadow — bright, airy
    [2] = {
        id = "rbxassetid://1844272089",   -- Positive Calm
        volume = 0.3,
    },
    -- Layer 3: The Canopy — mysterious, enchanted
    [3] = {
        id = "rbxassetid://1837429944",   -- Soft Music
        volume = 0.25,
    },
    -- Layer 4: The Stormwall — tense, dramatic
    [4] = {
        id = "rbxassetid://7399814871",   -- No Light (Boa pack — darker mood)
        volume = 0.35,
    },
    -- Layer 5: The Luminance — ethereal, cosmic
    [5] = {
        id = "rbxassetid://7399811837",   -- Cloudy Space (Boa pack — perfect for sky realm)
        volume = 0.3,
    },
    -- Layer 6: The Empyrean — transcendent, heavenly
    [6] = {
        id = "rbxassetid://7399815715",   -- Space Cruise (Boa pack — cosmic finale)
        volume = 0.3,
    },
}

-- SFX — use server-provided asset IDs when available, these are fallbacks
local SFX_IDS = {
    mote_collect = "rbxassetid://9125402735",
    level_up = "rbxassetid://9125402735",
    blessing_send = "rbxassetid://9125402735",
    blessing_receive = "rbxassetid://9125402735",
    fragment_collect = "rbxassetid://9125402735",
    gate_open = "rbxassetid://9125402735",
    trial_start = "rbxassetid://9125402735",
    trial_complete = "rbxassetid://9125402735",
    npc_talk = "rbxassetid://9125402735",
    wing_glide = "rbxassetid://9125402735",
    wing_flight = "rbxassetid://9125402735",
    stamina_low = "rbxassetid://9125402735",
    layer_transition = "rbxassetid://9125402735",
    speed_boost = "rbxassetid://9125402735",
    daily_reward = "rbxassetid://9125402735",
}

local CROSSFADE_TIME = 2.5

-- Active sound instances
local currentAmbient = nil      -- Sound instance for current layer music
local currentAmbientLayer = 0
local sfxCache = {}

-- RemoteEvents
local PlaySound
local AtmosphereUpdate

function SoundPlayer.Init()
    PlaySound = ReplicatedStorage:WaitForChild("PlaySound", 15)
    AtmosphereUpdate = ReplicatedStorage:WaitForChild("AtmosphereUpdate", 15)

    -- Listen for server SFX events
    if PlaySound then
        PlaySound.OnClientEvent:Connect(function(data)
            SoundPlayer.PlaySFX(data.sfx, data.assetId, data.volume)
        end)
    end

    -- Listen for layer change (atmosphere system tells us when player moves layers)
    if AtmosphereUpdate then
        AtmosphereUpdate.OnClientEvent:Connect(function(data)
            SoundPlayer.SetAmbientLayer(data.layerIndex)
        end)
    end

    -- Start Layer 1 music immediately
    task.delay(2, function()
        SoundPlayer.SetAmbientLayer(1)
    end)

    print("[SoundPlayer] Client sound system initialized — music plays on CLIENT")
end

function SoundPlayer.SetAmbientLayer(layerIndex: number)
    if layerIndex == currentAmbientLayer then return end

    local musicData = AMBIENT_MUSIC[layerIndex]
    if not musicData then return end

    -- Fade out current
    if currentAmbient then
        local oldSound = currentAmbient
        local fadeOut = TweenService:Create(oldSound, TweenInfo.new(CROSSFADE_TIME), {
            Volume = 0,
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            oldSound.Playing = false
            oldSound:Destroy()
        end)
    end

    -- Create and fade in new ambient
    local newSound = Instance.new("Sound")
    newSound.Name = "AmbientMusic_Layer" .. layerIndex
    newSound.SoundId = musicData.id
    newSound.Looped = true
    newSound.Volume = 0
    newSound.Playing = true
    newSound.Parent = SoundService

    local fadeIn = TweenService:Create(newSound, TweenInfo.new(CROSSFADE_TIME), {
        Volume = musicData.volume,
    })
    fadeIn:Play()

    currentAmbient = newSound
    currentAmbientLayer = layerIndex

    -- Play layer transition SFX
    if currentAmbientLayer > 0 then
        SoundPlayer.PlaySFX("layer_transition", nil, 0.3)
    end
end

function SoundPlayer.PlaySFX(sfxName: string, assetId: string?, volume: number?)
    -- Use provided asset ID, or fall back to our local SFX table
    local finalId = assetId
    if not finalId or finalId == "" then
        finalId = SFX_IDS[sfxName]
    end
    if not finalId or finalId == "" then return end

    -- Create a one-shot sound
    local sound = Instance.new("Sound")
    sound.Name = "SFX_" .. (sfxName or "unknown")
    sound.SoundId = finalId
    sound.Volume = volume or 0.5
    sound.Looped = false
    sound.Parent = SoundService
    sound:Play()

    -- Auto-cleanup
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    task.delay(10, function()
        if sound and sound.Parent then
            sound:Destroy()
        end
    end)
end

-- Public method for other client scripts to play sounds
function SoundPlayer.Play(sfxName: string, volume: number?)
    SoundPlayer.PlaySFX(sfxName, nil, volume)
end

return SoundPlayer
