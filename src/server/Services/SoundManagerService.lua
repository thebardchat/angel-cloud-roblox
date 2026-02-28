--[[
    SoundManagerService.lua — Ambient music, environmental audio, and SFX (Knit)
    Uses Roblox SoundService and Sound instances
    Per-layer ambient tracks with crossfading
    Sound asset IDs are placeholders — replace with uploaded audio assets
    Named SoundManagerService to avoid conflict with Roblox's SoundService
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundManagerService = Knit.CreateService({
    Name = "SoundManagerService",
    Client = {
        PlaySound = Knit.CreateSignal(),
    },
})

-- NOTE: Ambient music now plays on the CLIENT (SoundPlayer.lua)
-- Server sounds in SoundService are NOT audible to players!
-- This module still handles SFX dispatch via Knit signal -> client
--
-- SFX asset IDs sent to client for playback:
local AUDIO = {
    -- Ambient is handled client-side now — these are unused but kept for reference
    ambient = {
        [1] = "rbxassetid://1848354536",   -- Relaxed Scene
        [2] = "rbxassetid://1844272089",   -- Positive Calm
        [3] = "rbxassetid://1837429944",   -- Soft Music
        [4] = "rbxassetid://7399814871",   -- No Light (Boa pack)
        [5] = "rbxassetid://7399811837",   -- Cloudy Space (Boa pack)
        [6] = "rbxassetid://7399815715",   -- Space Cruise (Boa pack)
    },

    environment = {},  -- handled client-side

    -- Sound effects (sent via Knit signal to client for playback)
    sfx = {
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
        halt_reminder = "rbxassetid://9125402735",
        shop_purchase = "rbxassetid://9125402735",
        meditation_start = "rbxassetid://9125402735",
        lightning = "rbxassetid://9125402735",
        bounce = "rbxassetid://9125402735",
        speed_boost = "rbxassetid://9125402735",
        wing_forge = "rbxassetid://9125402735",
        speed_pad = "rbxassetid://9125402735",
        stairway_step = "rbxassetid://9125402735",
        gate_approach = "rbxassetid://9125402735",
        community_board = "rbxassetid://9125402735",
        mail_sent = "rbxassetid://9125402735",
        mail_received = "rbxassetid://9125402735",
        daily_reward = "rbxassetid://9125402735",
    },
}

-- Layer ambient volume levels
local LAYER_VOLUMES = {
    [1] = 0.3,   -- Nursery: gentle
    [2] = 0.35,  -- Meadow: slightly louder, more life
    [3] = 0.25,  -- Canopy: hushed
    [4] = 0.4,   -- Stormwall: louder, dramatic
    [5] = 0.3,   -- Luminance: serene
    [6] = 0.35,  -- Empyrean: full
}

-- Ambient music is now CLIENT-SIDE only (see SoundPlayer.lua)
-- Server Sound objects in SoundService are inaudible to players
local currentAmbientLayer: number = 0

-- SFX sound pool (reusable)
local sfxPool: { [string]: Sound } = {}

function SoundManagerService:KnitInit(): ()
    -- Create SFX folder in SoundService
    local sfxFolder = Instance.new("Folder")
    sfxFolder.Name = "SFX"
    sfxFolder.Parent = SoundService

    -- NOTE: Ambient music is now handled client-side in SoundPlayer.lua
    -- Server Sound objects are inaudible to players — don't create them here

    -- Pre-create reusable SFX instances
    for sfxName, assetId in pairs(AUDIO.sfx) do
        local sound = Instance.new("Sound")
        sound.Name = "SFX_" .. sfxName
        sound.SoundId = assetId
        sound.Looped = false
        sound.Volume = 0.5
        sound.Parent = sfxFolder
        sfxPool[sfxName] = sound
    end

    print("[SoundManagerService] Sound system initialized — ambient music is CLIENT-SIDE")
end

function SoundManagerService:KnitStart(): ()
    -- No additional start-time setup needed
end

-- SetAmbientLayer is called by AtmosphereService but ambient now plays on client
-- The AtmosphereService fires AtmosphereUpdate signal which the client's
-- SoundPlayer.lua listens to for layer music crossfading
function SoundManagerService:SetAmbientLayer(layerIndex: number): ()
    currentAmbientLayer = layerIndex
    -- Client handles the actual music playback via AtmosphereUpdate event
end

function SoundManagerService:PlaySFX(sfxName: string, volumeOverride: number?): ()
    local sound = sfxPool[sfxName]
    if not sound then return end

    -- Clone to allow overlapping plays
    local clone = sound:Clone()
    clone.Volume = volumeOverride or sound.Volume
    clone.Parent = sound.Parent
    clone:Play()

    -- Auto-cleanup after playing
    clone.Ended:Connect(function()
        clone:Destroy()
    end)

    -- Safety cleanup in case Ended doesn't fire
    task.delay(10, function()
        if clone and clone.Parent then
            clone:Destroy()
        end
    end)
end

function SoundManagerService:PlaySFXForPlayer(player: Player, sfxName: string, volume: number?): ()
    self.Client.PlaySound:Fire(player, {
        sfx = sfxName,
        volume = volume or 0.5,
        assetId = AUDIO.sfx[sfxName],
    })
end

function SoundManagerService:PlaySFXForAll(sfxName: string, volume: number?): ()
    self.Client.PlaySound:FireAll({
        sfx = sfxName,
        volume = volume or 0.5,
        assetId = AUDIO.sfx[sfxName],
    })
end

-- Called by AtmosphereService when player changes layers
function SoundManagerService:OnPlayerLayerChanged(player: Player, newLayerIndex: number): ()
    self:PlaySFXForPlayer(player, "gate_open", 0.3)
end

-- Convenience methods for common game events
function SoundManagerService:OnMoteCollected(player: Player): ()
    self:PlaySFXForPlayer(player, "mote_collect", 0.4)
end

function SoundManagerService:OnLevelUp(player: Player): ()
    self:PlaySFXForPlayer(player, "level_up", 0.7)
end

function SoundManagerService:OnBlessingSent(player: Player): ()
    self:PlaySFXForPlayer(player, "blessing_send", 0.5)
end

function SoundManagerService:OnBlessingReceived(player: Player): ()
    self:PlaySFXForPlayer(player, "blessing_receive", 0.5)
end

function SoundManagerService:OnFragmentCollected(player: Player): ()
    self:PlaySFXForPlayer(player, "fragment_collect", 0.6)
end

function SoundManagerService:OnTrialStart(): ()
    self:PlaySFXForAll("trial_start", 0.5)
end

function SoundManagerService:OnTrialComplete(): ()
    self:PlaySFXForAll("trial_complete", 0.6)
end

function SoundManagerService:OnNPCTalk(player: Player): ()
    self:PlaySFXForPlayer(player, "npc_talk", 0.3)
end

function SoundManagerService:OnLightning(): ()
    self:PlaySFXForAll("lightning", 0.6)
end

return SoundManagerService
