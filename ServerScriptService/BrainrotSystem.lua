--[[
    BrainrotSystem.lua — Collectible brainrots scattered across layers
    Players collect brainrots and carry them back to their Cloud Base
    Devils try to steal brainrots while you carry them
    Delivered brainrots = permanent currency, level up your base

    This is the CORE GAMEPLAY LOOP:
    1. Find brainrots scattered across the layer
    2. Pick them up (adds to your carry count)
    3. Fly/run back to your Cloud Base before devils steal them
    4. Deposit them at your base to earn permanent points
    5. Use points to upgrade your base and unlock new layers
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layers = require(ReplicatedStorage.Config.Layers)

local BrainrotSystem = {}

-- Config
local BRAINROTS_PER_LAYER = { 15, 20, 25, 30, 25, 20 }
local BRAINROT_RESPAWN_TIME = 20      -- seconds to respawn after collection
local BRAINROT_COLLECTION_RADIUS = 8
local MAX_CARRY = 10                   -- max brainrots you can carry at once
local BRAINROT_BASE_VALUE = 1          -- points per brainrot deposited
local BRAINROT_BONUS_LAYER = { 1, 1, 2, 2, 3, 5 }  -- bonus per brainrot by layer

-- Active brainrots in world
local brainrots = {}  -- { part, layerIndex, active, respawnTimer }

-- Player carry state (also stored as IntValue on character for devil system)
local playerCarrying = {}  -- [userId] = count

-- RemoteEvents
local BrainrotCollected  -- server→client: you picked one up
local BrainrotDeposited  -- server→client: you deposited at base
local BrainrotUpdate     -- server→client: carry count update
local BrainrotSpawned    -- server→client: new brainrot appeared (for effects)

-- Reference to DataManager (set during init)
local DataManager

function BrainrotSystem.Init()
    DataManager = require(script.Parent.DataManager)

    BrainrotCollected = Instance.new("RemoteEvent")
    BrainrotCollected.Name = "BrainrotCollected"
    BrainrotCollected.Parent = ReplicatedStorage

    BrainrotDeposited = Instance.new("RemoteEvent")
    BrainrotDeposited.Name = "BrainrotDeposited"
    BrainrotDeposited.Parent = ReplicatedStorage

    BrainrotUpdate = Instance.new("RemoteEvent")
    BrainrotUpdate.Name = "BrainrotUpdate"
    BrainrotUpdate.Parent = ReplicatedStorage

    BrainrotSpawned = Instance.new("RemoteEvent")
    BrainrotSpawned.Name = "BrainrotSpawned"
    BrainrotSpawned.Parent = ReplicatedStorage

    -- Spawn brainrots across all layers
    for layerIndex = 1, 6 do
        local count = BRAINROTS_PER_LAYER[layerIndex] or 15
        for i = 1, count do
            BrainrotSystem.SpawnBrainrot(layerIndex, i)
        end
    end

    -- Collection check loop
    RunService.Heartbeat:Connect(function(dt)
        BrainrotSystem.Update(dt)
    end)

    print("[BrainrotSystem] Spawned brainrots across all layers")
end

function BrainrotSystem.SpawnBrainrot(layerIndex: number, index: number)
    local layerDef = Layers.GetLayerByIndex(layerIndex)
    if not layerDef then return end

    local heightMin = layerDef.heightRange.min
    local heightMax = layerDef.heightRange.max
    local spread = 140 + layerIndex * 15

    -- The brainrot collectible — a glowing Neon orb, highly visible
    local brainrot = Instance.new("Part")
    brainrot.Name = "Brainrot_L" .. layerIndex .. "_" .. index
    brainrot.Shape = Enum.PartType.Ball
    brainrot.Size = Vector3.new(4, 4, 4)
    brainrot.Material = Enum.Material.Neon
    brainrot.Transparency = 0.1
    brainrot.Anchored = true
    brainrot.CanCollide = false

    -- Layer-specific colors (each layer has distinct brainrot look)
    local BRAINROT_COLORS = {
        Color3.fromRGB(255, 150, 200),   -- Nursery: pink
        Color3.fromRGB(150, 255, 200),   -- Meadow: mint green
        Color3.fromRGB(200, 150, 255),   -- Canopy: lavender
        Color3.fromRGB(255, 200, 100),   -- Stormwall: gold
        Color3.fromRGB(100, 200, 255),   -- Luminance: ice blue
        Color3.fromRGB(255, 255, 200),   -- Empyrean: cream white
    }
    brainrot.Color = BRAINROT_COLORS[layerIndex] or Color3.fromRGB(255, 150, 200)

    local pos = Vector3.new(
        math.random(-spread, spread),
        math.random(heightMin + 15, heightMax - 25),
        math.random(-spread, spread)
    )
    brainrot.Position = pos

    -- Bright PointLight for glow visibility
    local glow = Instance.new("PointLight")
    glow.Color = brainrot.Color
    glow.Brightness = 2
    glow.Range = 20
    glow.Parent = brainrot

    -- Beam column — vertical light pillar so players can spot brainrots from far away
    local attach0 = Instance.new("Attachment")
    attach0.Name = "BeamBase"
    attach0.Position = Vector3.new(0, 0, 0)
    attach0.Parent = brainrot

    local attach1 = Instance.new("Attachment")
    attach1.Name = "BeamTop"
    attach1.Position = Vector3.new(0, 35, 0)
    attach1.Parent = brainrot

    local beam = Instance.new("Beam")
    beam.Name = "BeamColumn"
    beam.Attachment0 = attach0
    beam.Attachment1 = attach1
    beam.Color = ColorSequence.new(brainrot.Color)
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0.8),
    })
    beam.Width0 = 1.5
    beam.Width1 = 0.3
    beam.LightEmission = 1
    beam.FaceCamera = true
    beam.Parent = brainrot

    -- BillboardGui — floating "BRAINROT" label visible from 80 studs
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BrainrotLabel"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.MaxDistance = 80
    billboard.AlwaysOnTop = false
    billboard.Parent = brainrot

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "BRAINROT"
    label.TextColor3 = brainrot.Color
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = billboard

    -- Floating particles — bigger and glowier
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(brainrot.Color)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Lifetime = NumberRange.new(1, 2)
    emitter.Rate = 8
    emitter.Speed = NumberRange.new(0.5, 2)
    emitter.SpreadAngle = Vector2.new(360, 360)
    emitter.LightEmission = 1
    emitter.Parent = brainrot

    -- Place in layer folder
    local layerFolderName = "Layer" .. layerIndex .. "_" .. layerDef.name:gsub("The ", ""):gsub("%s+", "")
    local layerFolder = workspace:FindFirstChild(layerFolderName)
    if layerFolder then
        brainrot.Parent = layerFolder
    else
        brainrot.Parent = workspace
    end

    -- Register
    table.insert(brainrots, {
        part = brainrot,
        layerIndex = layerIndex,
        index = index,
        active = true,
        respawnTimer = 0,
        originalPos = pos,
    })

    -- Bob animation
    task.spawn(function()
        local originalY = pos.Y
        local offset = math.random() * math.pi * 2
        local speed = 1.5 + math.random() * 0.5
        while brainrot and brainrot.Parent do
            if brainrot:GetAttribute("Active") ~= false then
                brainrot.Position = Vector3.new(
                    pos.X,
                    originalY + math.sin(tick() * speed + offset) * 1.5,
                    pos.Z
                )
                -- Slow spin
                brainrot.Orientation = Vector3.new(0, (tick() * 30 + offset * 57) % 360, 0)
            end
            task.wait(0.05)
        end
    end)
end

function BrainrotSystem.Update(dt: number)
    -- Check for collection proximity
    for _, br in ipairs(brainrots) do
        if not br.active then
            -- Respawn timer
            br.respawnTimer = br.respawnTimer - dt
            if br.respawnTimer <= 0 then
                br.active = true
                if br.part then
                    br.part.Transparency = 0.1
                    br.part:SetAttribute("Active", true)
                    local glow = br.part:FindFirstChildWhichIsA("PointLight")
                    if glow then glow.Enabled = true end
                    local emitter = br.part:FindFirstChildWhichIsA("ParticleEmitter")
                    if emitter then emitter.Enabled = true end
                    local beamObj = br.part:FindFirstChild("BeamColumn")
                    if beamObj then beamObj.Enabled = true end
                    local billboardObj = br.part:FindFirstChild("BrainrotLabel")
                    if billboardObj then billboardObj.Enabled = true end
                end
            end
            continue
        end

        if not br.part or not br.part.Parent then continue end

        local brPos = br.part.Position

        for _, p in ipairs(Players:GetPlayers()) do
            local character = p.Character
            if not character then continue end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local distance = (hrp.Position - brPos).Magnitude
            if distance < BRAINROT_COLLECTION_RADIUS then
                BrainrotSystem.CollectBrainrot(p, br)
                break
            end
        end
    end
end

function BrainrotSystem.CollectBrainrot(player: Player, brainrotData: any)
    local userId = player.UserId
    local currentCarry = playerCarrying[userId] or 0

    if currentCarry >= MAX_CARRY then
        -- Can't carry more — need to deposit at base first
        return
    end

    -- Mark brainrot as collected
    brainrotData.active = false
    brainrotData.respawnTimer = BRAINROT_RESPAWN_TIME

    -- Hide it
    if brainrotData.part then
        brainrotData.part.Transparency = 1
        brainrotData.part:SetAttribute("Active", false)
        local glow = brainrotData.part:FindFirstChildWhichIsA("PointLight")
        if glow then glow.Enabled = false end
        local emitter = brainrotData.part:FindFirstChildWhichIsA("ParticleEmitter")
        if emitter then emitter.Enabled = false end
        local beamObj = brainrotData.part:FindFirstChild("BeamColumn")
        if beamObj then beamObj.Enabled = false end
        local billboardObj = brainrotData.part:FindFirstChild("BrainrotLabel")
        if billboardObj then billboardObj.Enabled = false end
    end

    -- Update carry count
    playerCarrying[userId] = currentCarry + 1

    -- Update IntValue on character (for devil system to read)
    local character = player.Character
    if character then
        local carryVal = character:FindFirstChild("CarryingBrainrots")
        if not carryVal then
            carryVal = Instance.new("IntValue")
            carryVal.Name = "CarryingBrainrots"
            carryVal.Parent = character
        end
        carryVal.Value = playerCarrying[userId]
    end

    -- Notify client
    BrainrotCollected:FireClient(player, {
        carrying = playerCarrying[userId],
        maxCarry = MAX_CARRY,
        layerIndex = brainrotData.layerIndex,
    })

    -- Also award 1 mote per collection as immediate gratification
    local data = DataManager.GetData(player)
    if data then
        data.motes = (data.motes or 0) + 1
    end
end

-- Called when player reaches their cloud base deposit zone
function BrainrotSystem.DepositBrainrots(player: Player)
    local userId = player.UserId
    local carrying = playerCarrying[userId] or 0

    if carrying <= 0 then return end

    -- Calculate value (base + layer bonus)
    local totalValue = 0
    totalValue = carrying * BRAINROT_BASE_VALUE

    -- Bonus motes for the delivery
    local bonusMotes = carrying * 2

    -- Update player data
    local data = DataManager.GetData(player)
    if data then
        data.brainrotsDelivered = (data.brainrotsDelivered or 0) + carrying
        data.motes = (data.motes or 0) + bonusMotes
        data.baseLevel = math.floor((data.brainrotsDelivered or 0) / 10) + 1
    end

    -- Clear carry count
    playerCarrying[userId] = 0

    local character = player.Character
    if character then
        local carryVal = character:FindFirstChild("CarryingBrainrots")
        if carryVal then carryVal.Value = 0 end
    end

    -- Notify client
    BrainrotDeposited:FireClient(player, {
        deposited = carrying,
        bonusMotes = bonusMotes,
        totalDelivered = data and data.brainrotsDelivered or 0,
        baseLevel = data and data.baseLevel or 1,
    })
end

function BrainrotSystem.GetCarrying(player: Player): number
    return playerCarrying[player.UserId] or 0
end

function BrainrotSystem.OnPlayerJoined(player: Player)
    playerCarrying[player.UserId] = 0
end

function BrainrotSystem.RemovePlayer(player: Player)
    playerCarrying[player.UserId] = nil
end

return BrainrotSystem
