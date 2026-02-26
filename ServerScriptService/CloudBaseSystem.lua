--[[
    CloudBaseSystem.lua — Personal cloud base for each player
    Players deposit brainrots here to level up their base
    Base grows and gets new features as you deliver more brainrots
    Devils cannot enter your base (safe zone)

    Base Levels:
    1 (0 brainrots)   — Small platform + deposit pad
    2 (10 brainrots)  — Walls + roof + trophy shelf
    3 (25 brainrots)  — Garden area + glowing tree
    4 (50 brainrots)  — Tower + beacon visible from anywhere
    5 (100 brainrots) — Full fortress + community visitors welcome
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Layers = require(ReplicatedStorage.Config.Layers)

local CloudBaseSystem = {}

-- Config
local BASE_SPACING = 100       -- studs between player bases
local BASE_HEIGHT_OFFSET = 20  -- above Layer 1 spawn
local DEPOSIT_RADIUS = 12      -- how close to deposit pad to trigger deposit
local SAFE_ZONE_RADIUS = 40    -- devils can't enter this radius

-- Active bases
local playerBases = {}  -- [userId] = { model, depositPad, level, position }

-- References
local DataManager
local BrainrotSystem

function CloudBaseSystem.Init()
    DataManager = require(script.Parent.DataManager)
    BrainrotSystem = require(script.Parent.BrainrotSystem)

    -- Deposit check loop
    RunService.Heartbeat:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            CloudBaseSystem.CheckDeposit(p)
        end
    end)

    print("[CloudBaseSystem] Cloud base system initialized")
end

function CloudBaseSystem.OnPlayerJoined(player: Player)
    -- Assign base position (spaced out along a line near Layer 1)
    local baseIndex = #Players:GetPlayers()
    local baseX = (baseIndex - 1) * BASE_SPACING - ((#Players:GetPlayers() - 1) * BASE_SPACING / 2)
    local basePos = Vector3.new(baseX, 100 + BASE_HEIGHT_OFFSET, -80)

    local data = DataManager.GetData(player)
    local baseLevel = 1
    if data then
        baseLevel = data.baseLevel or 1
    end

    CloudBaseSystem.BuildBase(player, basePos, baseLevel)
end

function CloudBaseSystem.BuildBase(player: Player, position: Vector3, level: number)
    local userId = player.UserId

    -- Clean up old base if exists
    if playerBases[userId] and playerBases[userId].model then
        playerBases[userId].model:Destroy()
    end

    local baseModel = Instance.new("Model")
    baseModel.Name = player.Name .. "_CloudBase"

    -- Base platform (always present)
    local platformSize = 20 + level * 5
    local platform = Instance.new("Part")
    platform.Name = "BasePlatform"
    platform.Shape = Enum.PartType.Cylinder
    platform.Size = Vector3.new(4, platformSize, platformSize)
    platform.Position = position
    platform.Orientation = Vector3.new(0, 0, 90)
    platform.Anchored = true
    platform.Material = Enum.Material.SmoothPlastic
    platform.Color = Color3.fromRGB(240, 235, 250)
    platform.Parent = baseModel

    -- Cloud bumps around edge (organic look)
    for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2
        local bump = Instance.new("Part")
        bump.Name = "BaseBump_" .. i
        bump.Shape = Enum.PartType.Ball
        bump.Size = Vector3.new(platformSize * 0.25, platformSize * 0.12, platformSize * 0.25)
        bump.Position = position + Vector3.new(
            math.cos(angle) * platformSize * 0.4,
            -1,
            math.sin(angle) * platformSize * 0.4
        )
        bump.Anchored = true
        bump.CanCollide = true
        bump.Material = Enum.Material.SmoothPlastic
        bump.Color = Color3.fromRGB(245, 240, 255)
        bump.Parent = baseModel
    end

    -- Deposit Pad (glowing circle where you deliver brainrots)
    local depositPad = Instance.new("Part")
    depositPad.Name = "DepositPad"
    depositPad.Shape = Enum.PartType.Cylinder
    depositPad.Size = Vector3.new(1, 10, 10)
    depositPad.Position = position + Vector3.new(0, 2.5, 0)
    depositPad.Orientation = Vector3.new(0, 0, 90)
    depositPad.Anchored = true
    depositPad.CanCollide = false
    depositPad.Material = Enum.Material.Neon
    depositPad.Color = Color3.fromRGB(100, 255, 150)
    depositPad.Transparency = 0.3
    depositPad.Parent = baseModel

    local depositLight = Instance.new("PointLight")
    depositLight.Color = Color3.fromRGB(100, 255, 150)
    depositLight.Brightness = 1.5
    depositLight.Range = 15
    depositLight.Parent = depositPad

    -- Deposit pad particles (inviting upward stream)
    local depositEmitter = Instance.new("ParticleEmitter")
    depositEmitter.Color = ColorSequence.new(Color3.fromRGB(100, 255, 150))
    depositEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0),
    })
    depositEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    depositEmitter.Lifetime = NumberRange.new(1, 2)
    depositEmitter.Rate = 6
    depositEmitter.Speed = NumberRange.new(2, 5)
    depositEmitter.SpreadAngle = Vector2.new(10, 10)
    depositEmitter.LightEmission = 0.5
    depositEmitter.Parent = depositPad

    -- Player name sign
    local sign = Instance.new("Part")
    sign.Name = "BaseSign"
    sign.Size = Vector3.new(8, 3, 0.5)
    sign.Position = position + Vector3.new(0, 6, -platformSize / 2 - 1)
    sign.Anchored = true
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color = Color3.fromRGB(30, 25, 45)
    sign.Parent = baseModel

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName .. "'s Cloud"
    nameLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = signGui

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0.35, 0)
    levelLabel.Position = UDim2.new(0, 0, 0.6, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Level " .. level
    levelLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Parent = signGui

    -- Level 2+: Walls
    if level >= 2 then
        for i = 1, 4 do
            local angle = (i / 4) * math.pi * 2
            local wall = Instance.new("Part")
            wall.Name = "BaseWall_" .. i
            wall.Size = Vector3.new(platformSize * 0.45, 8, 1.5)
            wall.Position = position + Vector3.new(
                math.cos(angle) * platformSize * 0.35,
                6,
                math.sin(angle) * platformSize * 0.35
            )
            wall.Rotation = Vector3.new(0, math.deg(angle), 0)
            wall.Anchored = true
            wall.Material = Enum.Material.SmoothPlastic
            wall.Color = Color3.fromRGB(230, 225, 245)
            wall.Transparency = 0.2
            wall.Parent = baseModel
        end
    end

    -- Level 3+: Glowing tree
    if level >= 3 then
        local treePos = position + Vector3.new(8, 2, 5)
        local trunk = Instance.new("Part")
        trunk.Name = "BaseTree"
        trunk.Size = Vector3.new(1.5, 10, 1.5)
        trunk.Position = treePos + Vector3.new(0, 5, 0)
        trunk.Anchored = true
        trunk.Material = Enum.Material.SmoothPlastic
        trunk.Color = Color3.fromRGB(200, 210, 220)
        trunk.Parent = baseModel

        for c = 1, 4 do
            local leaf = Instance.new("Part")
            leaf.Name = "TreeLeaf_" .. c
            leaf.Shape = Enum.PartType.Ball
            leaf.Size = Vector3.new(5, 4, 5)
            leaf.Position = treePos + Vector3.new(
                (math.random() - 0.5) * 4,
                10 + math.random() * 3,
                (math.random() - 0.5) * 4
            )
            leaf.Anchored = true
            leaf.CanCollide = false
            leaf.Material = Enum.Material.SmoothPlastic
            leaf.Color = Color3.fromRGB(180, 240, 200)
            leaf.Transparency = 0.1
            leaf.Parent = baseModel
        end
    end

    -- Level 4+: Beacon tower (visible from far)
    if level >= 4 then
        local beacon = Instance.new("Part")
        beacon.Name = "BaseBeacon"
        beacon.Size = Vector3.new(2, 25, 2)
        beacon.Position = position + Vector3.new(-8, 14, -5)
        beacon.Anchored = true
        beacon.Material = Enum.Material.SmoothPlastic
        beacon.Color = Color3.fromRGB(200, 215, 240)
        beacon.Parent = baseModel

        local beaconLight = Instance.new("PointLight")
        beaconLight.Color = Color3.fromRGB(255, 240, 200)
        beaconLight.Brightness = 3
        beaconLight.Range = 60
        beaconLight.Parent = beacon

        local beaconOrb = Instance.new("Part")
        beaconOrb.Name = "BeaconOrb"
        beaconOrb.Shape = Enum.PartType.Ball
        beaconOrb.Size = Vector3.new(3, 3, 3)
        beaconOrb.Position = position + Vector3.new(-8, 28, -5)
        beaconOrb.Anchored = true
        beaconOrb.CanCollide = false
        beaconOrb.Material = Enum.Material.Neon
        beaconOrb.Color = Color3.fromRGB(255, 240, 200)
        beaconOrb.Parent = baseModel
    end

    -- Level 5: Full fortress extras
    if level >= 5 then
        -- Grand entrance arch
        for side = -1, 1, 2 do
            local pillar = Instance.new("Part")
            pillar.Name = "FortressPillar"
            pillar.Size = Vector3.new(2, 14, 2)
            pillar.Position = position + Vector3.new(side * 6, 9, -platformSize / 2)
            pillar.Anchored = true
            pillar.Material = Enum.Material.SmoothPlastic
            pillar.Color = Color3.fromRGB(220, 215, 240)
            pillar.Parent = baseModel
        end

        local archTop = Instance.new("Part")
        archTop.Name = "FortressArch"
        archTop.Size = Vector3.new(14, 2, 2)
        archTop.Position = position + Vector3.new(0, 16, -platformSize / 2)
        archTop.Anchored = true
        archTop.Material = Enum.Material.SmoothPlastic
        archTop.Color = Color3.fromRGB(220, 215, 240)
        archTop.Parent = baseModel
    end

    -- Safe zone boundary (invisible, used by devil AI)
    local safeZone = Instance.new("Part")
    safeZone.Name = "SafeZone"
    safeZone.Shape = Enum.PartType.Ball
    safeZone.Size = Vector3.new(SAFE_ZONE_RADIUS * 2, SAFE_ZONE_RADIUS * 2, SAFE_ZONE_RADIUS * 2)
    safeZone.Position = position
    safeZone.Anchored = true
    safeZone.CanCollide = false
    safeZone.Transparency = 1
    safeZone.Parent = baseModel

    baseModel.Parent = workspace

    playerBases[userId] = {
        model = baseModel,
        depositPad = depositPad,
        level = level,
        position = position,
    }

    print("[CloudBaseSystem] Built base for " .. player.Name .. " (Level " .. level .. ")")
end

function CloudBaseSystem.CheckDeposit(player: Player)
    local userId = player.UserId
    local base = playerBases[userId]
    if not base or not base.depositPad then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - base.depositPad.Position).Magnitude
    if distance < DEPOSIT_RADIUS then
        -- Auto-deposit when standing on the pad
        local carrying = BrainrotSystem.GetCarrying(player)
        if carrying > 0 then
            BrainrotSystem.DepositBrainrots(player)

            -- Check if base should level up
            local data = DataManager.GetData(player)
            if data then
                local newLevel = math.floor((data.brainrotsDelivered or 0) / 10) + 1
                newLevel = math.min(newLevel, 5)
                if newLevel > base.level then
                    -- Rebuild base at new level
                    CloudBaseSystem.BuildBase(player, base.position, newLevel)
                end
            end
        end
    end
end

function CloudBaseSystem.GetBasePosition(player: Player): Vector3?
    local base = playerBases[player.UserId]
    if base then
        return base.position
    end
    return nil
end

function CloudBaseSystem.IsInSafeZone(position: Vector3): boolean
    for _, base in pairs(playerBases) do
        if (position - base.position).Magnitude < SAFE_ZONE_RADIUS then
            return true
        end
    end
    return false
end

function CloudBaseSystem.RemovePlayer(player: Player)
    local userId = player.UserId
    local base = playerBases[userId]
    if base and base.model then
        base.model:Destroy()
    end
    playerBases[userId] = nil
end

return CloudBaseSystem
