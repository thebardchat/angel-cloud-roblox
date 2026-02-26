--[[
    DevilSystem.lua — Enemy devils that fly around trying to steal brainrots
    Devils patrol each layer, chase players carrying brainrots,
    and can be scared off by blessings or group proximity
    Server-authoritative: all devil AI runs here
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layers = require(ReplicatedStorage.Config.Layers)

local DevilSystem = {}

-- Forward reference (set in Init after require)
local CloudBaseSystem

-- Devil configuration
local DEVIL_SPEED = 35               -- base movement speed
local DEVIL_CHASE_SPEED = 50         -- speed when chasing a player
local DEVIL_CHASE_RANGE = 80         -- distance to start chasing
local DEVIL_STEAL_RANGE = 8          -- distance to steal a brainrot
local DEVIL_STEAL_COOLDOWN = 5       -- seconds after stealing before chasing again
local DEVIL_SCARE_RANGE = 15         -- blessing/group scare radius
local DEVIL_PATROL_RADIUS = 120      -- how far devils patrol from center
local DEVILS_PER_LAYER = { 2, 3, 4, 5, 4, 3 }  -- more in middle layers
local DEVIL_RESPAWN_TIME = 15        -- seconds to respawn after being scared off

-- Active devils
local devils = {}  -- { model, layerIndex, state, target, patrolAngle, cooldown, ... }

-- RemoteEvents
local DevilAlert    -- server→client: warn player a devil is nearby
local DevilStole    -- server→client: devil stole your brainrot

-- Devil colors per layer (getting darker/scarier in higher layers)
local DEVIL_COLORS = {
    Color3.fromRGB(180, 60, 60),    -- Nursery: mild red
    Color3.fromRGB(160, 40, 40),    -- Meadow: darker
    Color3.fromRGB(120, 30, 80),    -- Canopy: purple-red
    Color3.fromRGB(80, 20, 100),    -- Stormwall: deep purple
    Color3.fromRGB(60, 10, 60),     -- Luminance: dark violet
    Color3.fromRGB(40, 5, 40),      -- Empyrean: nearly black
}

function DevilSystem.Init()
    -- Load cloud base system for safe zone checks
    CloudBaseSystem = require(script.Parent.CloudBaseSystem)

    -- Create RemoteEvents
    DevilAlert = Instance.new("RemoteEvent")
    DevilAlert.Name = "DevilAlert"
    DevilAlert.Parent = ReplicatedStorage

    DevilStole = Instance.new("RemoteEvent")
    DevilStole.Name = "DevilStole"
    DevilStole.Parent = ReplicatedStorage

    -- Spawn devils for each layer
    for layerIndex = 1, 6 do
        local count = DEVILS_PER_LAYER[layerIndex] or 3
        for i = 1, count do
            DevilSystem.SpawnDevil(layerIndex, i)
        end
    end

    -- AI update loop
    RunService.Heartbeat:Connect(function(dt)
        DevilSystem.Update(dt)
    end)

    print("[DevilSystem] Spawned devils across all layers")
end

function DevilSystem.SpawnDevil(layerIndex: number, index: number)
    local layerDef = Layers.GetLayerByIndex(layerIndex)
    if not layerDef then return end

    local heightMin = layerDef.heightRange.min
    local heightMax = layerDef.heightRange.max
    local centerY = (heightMin + heightMax) / 2
    local color = DEVIL_COLORS[layerIndex] or Color3.fromRGB(150, 30, 30)

    -- Build devil model from parts (menacing but kid-friendly — more mischievous imp than horror)
    local model = Instance.new("Model")
    model.Name = "Devil_L" .. layerIndex .. "_" .. index

    -- Body (round, imp-like)
    local body = Instance.new("Part")
    body.Name = "DevilBody"
    body.Shape = Enum.PartType.Ball
    body.Size = Vector3.new(4, 4, 4)
    body.Material = Enum.Material.SmoothPlastic
    body.Color = color
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model

    -- Eyes (two glowing yellow orbs)
    for side = -1, 1, 2 do
        local eye = Instance.new("Part")
        eye.Name = "Eye"
        eye.Shape = Enum.PartType.Ball
        eye.Size = Vector3.new(0.8, 0.8, 0.8)
        eye.Material = Enum.Material.Neon
        eye.Color = Color3.fromRGB(255, 200, 0)
        eye.Anchored = true
        eye.CanCollide = false
        eye.Parent = model

        local eyeWeld = Instance.new("WeldConstraint")
        eyeWeld.Part0 = body
        eyeWeld.Part1 = eye
        eyeWeld.Parent = eye

        eye.CFrame = body.CFrame * CFrame.new(side * 0.8, 0.5, -1.5)
    end

    -- Horns (two small angled parts)
    for side = -1, 1, 2 do
        local horn = Instance.new("Part")
        horn.Name = "Horn"
        horn.Size = Vector3.new(0.5, 1.5, 0.5)
        horn.Material = Enum.Material.SmoothPlastic
        horn.Color = Color3.fromRGB(40, 10, 10)
        horn.Anchored = true
        horn.CanCollide = false
        horn.Parent = model

        local hornWeld = Instance.new("WeldConstraint")
        hornWeld.Part0 = body
        hornWeld.Part1 = horn
        hornWeld.Parent = horn

        horn.CFrame = body.CFrame * CFrame.new(side * 1, 2, 0) * CFrame.Angles(0, 0, math.rad(side * 20))
    end

    -- Bat wings (dark, angular)
    for side = -1, 1, 2 do
        local wing = Instance.new("Part")
        wing.Name = "BatWing"
        wing.Size = Vector3.new(0.2, 2.5, 3)
        wing.Material = Enum.Material.SmoothPlastic
        wing.Color = Color3.fromRGB(30, 10, 30)
        wing.Anchored = true
        wing.CanCollide = false
        wing.Parent = model

        local wingWeld = Instance.new("WeldConstraint")
        wingWeld.Part0 = body
        wingWeld.Part1 = wing
        wingWeld.Parent = wing

        wing.CFrame = body.CFrame * CFrame.new(side * 2.5, 0.5, 0.5) * CFrame.Angles(0, 0, math.rad(side * -30))
    end

    -- Tail (thin wavy part)
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.3, 0.3, 2.5)
    tail.Material = Enum.Material.SmoothPlastic
    tail.Color = color
    tail.Anchored = true
    tail.CanCollide = false
    tail.Parent = model

    local tailWeld = Instance.new("WeldConstraint")
    tailWeld.Part0 = body
    tailWeld.Part1 = tail
    tailWeld.Parent = tail

    tail.CFrame = body.CFrame * CFrame.new(0, -0.5, 2.5)

    -- Evil glow (subtle red light)
    local glow = Instance.new("PointLight")
    glow.Color = Color3.fromRGB(255, 50, 50)
    glow.Brightness = 0.8
    glow.Range = 15
    glow.Parent = body

    -- Smoke trail
    local smoke = Instance.new("ParticleEmitter")
    smoke.Name = "DevilSmoke"
    smoke.Color = ColorSequence.new(Color3.fromRGB(60, 20, 60))
    smoke.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 2),
    })
    smoke.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    smoke.Lifetime = NumberRange.new(0.5, 1.5)
    smoke.Rate = 5
    smoke.Speed = NumberRange.new(1, 3)
    smoke.SpreadAngle = Vector2.new(30, 30)
    smoke.Parent = body

    model.PrimaryPart = body

    -- Starting position
    local startAngle = (index / (DEVILS_PER_LAYER[layerIndex] or 3)) * math.pi * 2
    body.CFrame = CFrame.new(
        math.cos(startAngle) * DEVIL_PATROL_RADIUS * 0.5,
        centerY,
        math.sin(startAngle) * DEVIL_PATROL_RADIUS * 0.5
    )

    -- Update weld positions
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("WeldConstraint") then
            -- Welds auto-resolve from initial CFrame
        end
    end

    local layerFolderName = "Layer" .. layerIndex .. "_" .. layerDef.name:gsub("The ", ""):gsub("%s+", "")
    local layerFolder = workspace:FindFirstChild(layerFolderName)
    if layerFolder then
        model.Parent = layerFolder
    else
        model.Parent = workspace
    end

    -- Register devil data
    table.insert(devils, {
        model = model,
        body = body,
        layerIndex = layerIndex,
        state = "patrol",  -- patrol, chase, steal_cooldown, scared, respawning
        target = nil,
        patrolAngle = startAngle,
        cooldown = 0,
        heightMin = heightMin,
        heightMax = heightMax,
        centerY = centerY,
        active = true,
    })
end

function DevilSystem.Update(dt: number)
    for _, devil in ipairs(devils) do
        if not devil.active then
            -- Respawn timer
            devil.cooldown = devil.cooldown - dt
            if devil.cooldown <= 0 then
                devil.active = true
                devil.state = "patrol"
                if devil.model and devil.model.Parent then
                    for _, part in ipairs(devil.model:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = part.Name == "DevilBody" and 0 or (part.Material == Enum.Material.Neon and 0 or 0)
                        end
                    end
                end
            end
            continue
        end

        if not devil.body or not devil.body.Parent then continue end

        if devil.state == "patrol" then
            DevilSystem.UpdatePatrol(devil, dt)
        elseif devil.state == "chase" then
            DevilSystem.UpdateChase(devil, dt)
        elseif devil.state == "steal_cooldown" then
            devil.cooldown = devil.cooldown - dt
            if devil.cooldown <= 0 then
                devil.state = "patrol"
                devil.target = nil
            end
        end

        -- Check if any player with brainrots is nearby
        if devil.state == "patrol" then
            DevilSystem.CheckForTargets(devil)
        end

        -- Check if a group of players scares this devil
        DevilSystem.CheckForScare(devil)
    end
end

function DevilSystem.UpdatePatrol(devil: any, dt: number)
    -- Circle around the layer center
    devil.patrolAngle = devil.patrolAngle + dt * 0.3
    local bobY = math.sin(tick() * 2) * 3
    local targetPos = Vector3.new(
        math.cos(devil.patrolAngle) * DEVIL_PATROL_RADIUS * 0.6,
        devil.centerY + bobY,
        math.sin(devil.patrolAngle) * DEVIL_PATROL_RADIUS * 0.6
    )

    local currentPos = devil.body.Position
    local direction = (targetPos - currentPos)
    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    devil.body.CFrame = CFrame.new(
        currentPos + direction * DEVIL_SPEED * dt,
        currentPos + direction * DEVIL_SPEED * dt + direction
    )
end

function DevilSystem.UpdateChase(devil: any, dt: number)
    if not devil.target then
        devil.state = "patrol"
        return
    end

    local targetChar = devil.target.Character
    if not targetChar then
        devil.state = "patrol"
        devil.target = nil
        return
    end

    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        devil.state = "patrol"
        devil.target = nil
        return
    end

    local currentPos = devil.body.Position
    local targetPos = targetHRP.Position
    local distance = (targetPos - currentPos).Magnitude

    -- If target is too far, give up
    if distance > DEVIL_CHASE_RANGE * 1.5 then
        devil.state = "patrol"
        devil.target = nil
        return
    end

    -- If target is in a cloud base safe zone, back off
    if CloudBaseSystem and CloudBaseSystem.IsInSafeZone(targetPos) then
        devil.state = "patrol"
        devil.target = nil
        return
    end

    -- Move toward target
    local direction = (targetPos - currentPos).Unit
    devil.body.CFrame = CFrame.new(
        currentPos + direction * DEVIL_CHASE_SPEED * dt,
        targetPos
    )

    -- Close enough to steal?
    if distance < DEVIL_STEAL_RANGE then
        DevilSystem.StealBrainrot(devil)
    end
end

function DevilSystem.CheckForTargets(devil: any)
    local devilPos = devil.body.Position

    for _, p in ipairs(Players:GetPlayers()) do
        local character = p.Character
        if not character then continue end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local distance = (hrp.Position - devilPos).Magnitude
        if distance > DEVIL_CHASE_RANGE then continue end

        -- Check if player is carrying brainrots (stored as IntValue on character)
        local carrying = character:FindFirstChild("CarryingBrainrots")
        if carrying and carrying.Value > 0 then
            devil.state = "chase"
            devil.target = p

            -- Alert the player
            DevilAlert:FireClient(p, {
                devilPos = devilPos,
                distance = distance,
            })
            break
        end
    end
end

function DevilSystem.StealBrainrot(devil: any)
    if not devil.target then return end

    local character = devil.target.Character
    if not character then return end

    local carrying = character:FindFirstChild("CarryingBrainrots")
    if not carrying or carrying.Value <= 0 then
        devil.state = "patrol"
        devil.target = nil
        return
    end

    -- Steal one brainrot
    carrying.Value = carrying.Value - 1

    -- Notify the player
    DevilStole:FireClient(devil.target, {
        stolen = 1,
        remaining = carrying.Value,
    })

    -- Devil flies away after stealing
    devil.state = "steal_cooldown"
    devil.cooldown = DEVIL_STEAL_COOLDOWN
    devil.target = nil
end

function DevilSystem.CheckForScare(devil: any)
    local devilPos = devil.body.Position
    local nearbyPlayers = 0

    for _, p in ipairs(Players:GetPlayers()) do
        local character = p.Character
        if not character then continue end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local distance = (hrp.Position - devilPos).Magnitude
        if distance < DEVIL_SCARE_RANGE then
            nearbyPlayers = nearbyPlayers + 1
        end
    end

    -- 3+ nearby players scare the devil away
    if nearbyPlayers >= 3 then
        DevilSystem.ScareDevil(devil)
    end
end

function DevilSystem.ScareDevil(devil: any)
    devil.state = "scared"
    devil.active = false
    devil.cooldown = DEVIL_RESPAWN_TIME
    devil.target = nil

    -- Make devil disappear (fade out)
    if devil.model then
        for _, part in ipairs(devil.model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
    end
end

-- Called by BlessingSystem when a blessing hits near a devil
function DevilSystem.OnBlessingNearby(position: Vector3, range: number)
    for _, devil in ipairs(devils) do
        if not devil.active then continue end
        if not devil.body or not devil.body.Parent then continue end

        local distance = (devil.body.Position - position).Magnitude
        if distance < (range or 30) then
            DevilSystem.ScareDevil(devil)
        end
    end
end

function DevilSystem.RemovePlayer(player: Player)
    -- Clear any devil targeting this player
    for _, devil in ipairs(devils) do
        if devil.target == player then
            devil.target = nil
            devil.state = "patrol"
        end
    end
end

return DevilSystem
