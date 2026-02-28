--[[
    DevilService.lua — Knit Service migration of DevilSystem
    Enemy devils that fly around trying to steal brainrots
    Devils patrol each layer, chase players carrying brainrots,
    and can be scared off by blessings or group proximity
    Server-authoritative: all devil AI runs here
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Layers = require(ReplicatedStorage.Config.Layers)

local DevilService = Knit.CreateService({
    Name = "DevilService",
    Client = {
        DevilAlert = Knit.CreateSignal(),
        DevilStole = Knit.CreateSignal(),
    },
})

-- Forward reference (set in KnitStart after service resolution)
local CloudBaseService: any = nil

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
local devils: { any } = {}  -- { model, layerIndex, state, target, patrolAngle, cooldown, ... }

-- Devil colors per layer (getting darker/scarier in higher layers)
local DEVIL_COLORS = {
    Color3.fromRGB(180, 60, 60),    -- Nursery: mild red
    Color3.fromRGB(160, 40, 40),    -- Meadow: darker
    Color3.fromRGB(120, 30, 80),    -- Canopy: purple-red
    Color3.fromRGB(80, 20, 100),    -- Stormwall: deep purple
    Color3.fromRGB(60, 10, 60),     -- Luminance: dark violet
    Color3.fromRGB(40, 5, 40),      -- Empyrean: nearly black
}

function DevilService:KnitInit(): ()
    print("[DevilService] Initializing...")
end

function DevilService:KnitStart(): ()
    -- Load cloud base service for safe zone checks
    local ok, result = pcall(function()
        return Knit.GetService("CloudBaseService")
    end)
    if ok then
        CloudBaseService = result
    end

    -- Spawn devils for each layer
    for layerIndex = 1, 6 do
        local count = DEVILS_PER_LAYER[layerIndex] or 3
        for i = 1, count do
            self:SpawnDevil(layerIndex, i)
        end
    end

    -- AI update loop
    RunService.Heartbeat:Connect(function(dt: number)
        self:Update(dt)
    end)

    print("[DevilService] Spawned devils across all layers")
end

function DevilService:SpawnDevil(layerIndex: number, index: number): ()
    local layerDef = Layers.GetLayerByIndex(layerIndex)
    if not layerDef then return end

    local heightMin = layerDef.heightRange.min
    local heightMax = layerDef.heightRange.max
    local centerY = (heightMin + heightMax) / 2
    local color = DEVIL_COLORS[layerIndex] or Color3.fromRGB(150, 30, 30)

    -- Derived colors
    local darkerColor = Color3.fromRGB(
        math.max(0, math.floor(color.R * 255 * 0.7)),
        math.max(0, math.floor(color.G * 255 * 0.7)),
        math.max(0, math.floor(color.B * 255 * 0.7))
    )
    local armColor = Color3.fromRGB(
        math.max(0, math.floor(color.R * 255 * 0.85)),
        math.max(0, math.floor(color.G * 255 * 0.85)),
        math.max(0, math.floor(color.B * 255 * 0.85))
    )
    local hornColor = Color3.fromRGB(30, 8, 8)
    local wingColor = Color3.fromRGB(40, 12, 50)
    local clawColor = Color3.fromRGB(25, 5, 5)

    -- Helper: create a child part welded to a parent part at a relative CFrame
    local function makeChild(parentPart: BasePart, name: string, shape: Enum.PartType?, size: Vector3, mat: Enum.Material, col: Color3, relativeCF: CFrame): BasePart
        local part = Instance.new("Part")
        part.Name = name
        if shape then
            part.Shape = shape
        end
        part.Size = size
        part.Material = mat
        part.Color = col
        part.CanCollide = false
        part.Massless = true
        part.CFrame = parentPart.CFrame * relativeCF
        part.Parent = parentPart.Parent

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = part
        weld.Parent = part

        return part
    end

    -- Helper: create a WedgePart child welded to a parent part
    local function makeWedgeChild(parentPart: BasePart, name: string, size: Vector3, mat: Enum.Material, col: Color3, relativeCF: CFrame): WedgePart
        local wedge = Instance.new("WedgePart")
        wedge.Name = name
        wedge.Size = size
        wedge.Material = mat
        wedge.Color = col
        wedge.CanCollide = false
        wedge.Massless = true
        wedge.CFrame = parentPart.CFrame * relativeCF
        wedge.Parent = parentPart.Parent

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = parentPart
        weld.Part1 = wedge
        weld.Parent = wedge

        return wedge
    end

    -- Build devil model (~7 studs tall flying imp)
    local model = Instance.new("Model")
    model.Name = "Devil_L" .. layerIndex .. "_" .. index

    -- Body / Torso (root part, Anchored)
    local body = Instance.new("Part")
    body.Name = "DevilBody"
    body.Size = Vector3.new(2.5, 3, 1.5)
    body.Material = Enum.Material.SmoothPlastic
    body.Color = color
    body.Anchored = true
    body.CanCollide = false
    body.Parent = model

    -- Head (ball on top of body, welded to body)
    local head = makeChild(body, "Head", Enum.PartType.Ball,
        Vector3.new(2.2, 2.2, 2.2), Enum.Material.SmoothPlastic, darkerColor,
        CFrame.new(0, 2.6, 0))

    -- Eyes (two neon yellow balls on front of head, welded to head)
    for side = -1, 1, 2 do
        makeChild(head, "Eye", Enum.PartType.Ball,
            Vector3.new(0.5, 0.5, 0.5), Enum.Material.Neon, Color3.fromRGB(255, 200, 0),
            CFrame.new(side * 0.45, 0.15, -0.85))
    end

    -- Horns (two cylinders angled outward from head, welded to head)
    for side = -1, 1, 2 do
        makeChild(head, "Horn", Enum.PartType.Cylinder,
            Vector3.new(2, 0.4, 0.4), Enum.Material.SmoothPlastic, hornColor,
            CFrame.new(side * 0.6, 1.2, -0.1)
                * CFrame.Angles(0, 0, math.rad(side * 70))
                * CFrame.Angles(math.rad(-15), 0, 0))
    end

    -- Arms (two blocks hanging from body sides, welded to body)
    local leftArm, rightArm
    for side = -1, 1, 2 do
        local arm = makeChild(body, "Arm", nil,
            Vector3.new(0.7, 2.5, 0.7), Enum.Material.SmoothPlastic, armColor,
            CFrame.new(side * 1.6, -0.25, 0))
        if side == -1 then leftArm = arm else rightArm = arm end

        -- Claw at end of arm (wedge part, welded to arm)
        makeWedgeChild(arm, "Claw",
            Vector3.new(0.7, 0.6, 0.9), Enum.Material.SmoothPlastic, clawColor,
            CFrame.new(0, -1.55, -0.1) * CFrame.Angles(0, 0, 0))
    end

    -- Bat Wings (two large parts per side + wedge tips, welded to body)
    for side = -1, 1, 2 do
        -- Main wing membrane
        local wing = makeChild(body, "BatWing", nil,
            Vector3.new(0.15, 4, 5), Enum.Material.SmoothPlastic, wingColor,
            CFrame.new(side * 3, 0.5, 1)
                * CFrame.Angles(math.rad(-10), math.rad(side * -15), math.rad(side * -20)))

        -- Wing tip (pointed wedge at outer edge)
        makeWedgeChild(wing, "WingTip",
            Vector3.new(0.15, 1.5, 2.5), Enum.Material.SmoothPlastic, wingColor,
            CFrame.new(0, -2.75, -1.25) * CFrame.Angles(math.rad(10), 0, 0))
    end

    -- Tail (cylinder extending backward from lower body, welded to body)
    local tail = makeChild(body, "Tail", Enum.PartType.Cylinder,
        Vector3.new(3.5, 0.3, 0.3), Enum.Material.SmoothPlastic, color,
        CFrame.new(0, -1.2, 2.2)
            * CFrame.Angles(0, 0, math.rad(90))
            * CFrame.Angles(math.rad(25), 0, 0))

    -- Tail fork (two small wedges at end of tail for forked tip, welded to tail)
    for side = -1, 1, 2 do
        makeWedgeChild(tail, "TailFork",
            Vector3.new(0.5, 0.6, 0.3), Enum.Material.SmoothPlastic, clawColor,
            CFrame.new(side * 0.25, -1.75, 0)
                * CFrame.Angles(0, 0, math.rad(side * 25)))
    end

    -- PointLight: red glow on body
    local glowLight = Instance.new("PointLight")
    glowLight.Color = Color3.fromRGB(255, 50, 50)
    glowLight.Brightness = 1.5
    glowLight.Range = 20
    glowLight.Parent = body

    -- Smoke ParticleEmitter: dark purple smoke trail on body
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

    -- Fire ParticleEmitter: small orange/red fire from head (mouth area)
    local fire = Instance.new("ParticleEmitter")
    fire.Name = "DevilFire"
    fire.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 10)),
    })
    fire.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    fire.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    fire.Lifetime = NumberRange.new(0.2, 0.5)
    fire.Rate = 12
    fire.Speed = NumberRange.new(2, 4)
    fire.SpreadAngle = Vector2.new(15, 10)
    fire.EmissionDirection = Enum.NormalId.Front
    fire.Parent = head

    model.PrimaryPart = body

    -- Starting position
    local startAngle = (index / (DEVILS_PER_LAYER[layerIndex] or 3)) * math.pi * 2
    body.CFrame = CFrame.new(
        math.cos(startAngle) * DEVIL_PATROL_RADIUS * 0.5,
        centerY,
        math.sin(startAngle) * DEVIL_PATROL_RADIUS * 0.5
    )

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

function DevilService:Update(dt: number): ()
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
            self:UpdatePatrol(devil, dt)
        elseif devil.state == "chase" then
            self:UpdateChase(devil, dt)
        elseif devil.state == "steal_cooldown" then
            devil.cooldown = devil.cooldown - dt
            if devil.cooldown <= 0 then
                devil.state = "patrol"
                devil.target = nil
            end
        end

        -- Check if any player with brainrots is nearby
        if devil.state == "patrol" then
            self:CheckForTargets(devil)
        end

        -- Check if a group of players scares this devil
        self:CheckForScare(devil)
    end
end

function DevilService:UpdatePatrol(devil: any, dt: number): ()
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

function DevilService:UpdateChase(devil: any, dt: number): ()
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
    if CloudBaseService and CloudBaseService.IsInSafeZone and CloudBaseService.IsInSafeZone(targetPos) then
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
        self:StealBrainrot(devil)
    end
end

function DevilService:CheckForTargets(devil: any): ()
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

            -- Alert the player via Knit signal
            self.Client.DevilAlert:Fire(p, {
                devilPos = devilPos,
                distance = distance,
            })
            break
        end
    end
end

function DevilService:StealBrainrot(devil: any): ()
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

    -- Notify the player via Knit signal
    self.Client.DevilStole:Fire(devil.target, {
        stolen = 1,
        remaining = carrying.Value,
    })

    -- Devil flies away after stealing
    devil.state = "steal_cooldown"
    devil.cooldown = DEVIL_STEAL_COOLDOWN
    devil.target = nil
end

function DevilService:CheckForScare(devil: any): ()
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
        self:ScareDevil(devil)
    end
end

function DevilService:ScareDevil(devil: any): ()
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

-- Called by BlessingService when a blessing hits near a devil
function DevilService:OnBlessingNearby(position: Vector3, range: number): ()
    for _, devil in ipairs(devils) do
        if not devil.active then continue end
        if not devil.body or not devil.body.Parent then continue end

        local distance = (devil.body.Position - position).Magnitude
        if distance < (range or 30) then
            self:ScareDevil(devil)
        end
    end
end

function DevilService:RemovePlayer(player: Player): ()
    -- Clear any devil targeting this player
    for _, devil in ipairs(devils) do
        if devil.target == player then
            devil.target = nil
            devil.state = "patrol"
        end
    end
end

return DevilService
