--[[
    WingService.lua — Wing Gauge (stamina) + Wing Attachment/Forge
    Migrated from StaminaSystem.lua (wing gauge portion) and GameManager.server.lua (wing visuals/forge)

    Max Capacity: 100 base + 20 per angel level index (Newborn=100, Angel=200)
    Drain: Glide 5/sec, Flight 15/sec, Cloud-Shape 10/action, Shield 8/sec
    Recovery: Ground 3/sec, Reflection Pool +50%, Blessing +30%, 3+ players nearby 2x, Meditation 30s full
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Layers = require(ReplicatedStorage.Config.Layers)

local WingService = Knit.CreateService({
    Name = "WingService",
    Client = {
        StaminaUpdate = Knit.CreateSignal(),
        WingForged = Knit.CreateSignal(),
    },
})

---------------------------------------------------------------------------
-- Constants: Stamina
---------------------------------------------------------------------------
local BASE_STAMINA = 100
local STAMINA_PER_LEVEL = 20

local DRAIN_RATES = {
    glide = 5,        -- per second
    flight = 15,      -- per second
    cloud_shape = 10, -- per action
    shield = 8,       -- per second
}

local RECOVERY_RATES = {
    ground = 3,               -- per second on ground
    reflection_pool = 4.5,    -- 3 * 1.5 (+50%)
    blessing_boost = 3.9,     -- 3 * 1.3 (+30%)
    near_players = 6,         -- 3 * 2 (3+ nearby players)
    meditation = "full",      -- full restore after 30s sit
}

---------------------------------------------------------------------------
-- Constants: Wing Forge
---------------------------------------------------------------------------
local WING_FORGE_COST = 5   -- motes per upgrade
local WING_MAX_LEVEL = 10

---------------------------------------------------------------------------
-- Constants: Wing Appearance
---------------------------------------------------------------------------
local WING_COLORS = {
    Color3.fromRGB(245, 245, 255),   -- Newborn: pure white
    Color3.fromRGB(230, 240, 255),   -- Young Angel: soft sky blue
    Color3.fromRGB(220, 245, 235),   -- Growing: soft mint
    Color3.fromRGB(235, 220, 255),   -- Helping: soft lavender
    Color3.fromRGB(255, 245, 220),   -- Guardian: warm gold-white
    Color3.fromRGB(255, 255, 255),   -- Angel: radiant white
}

local WING_TIPS = {
    Color3.fromRGB(220, 225, 240),
    Color3.fromRGB(200, 220, 245),
    Color3.fromRGB(190, 230, 215),
    Color3.fromRGB(210, 195, 240),
    Color3.fromRGB(240, 225, 190),
    Color3.fromRGB(240, 240, 250),
}

---------------------------------------------------------------------------
-- Per-player stamina state (session-only, not persisted)
---------------------------------------------------------------------------
type StaminaState = {
    current: number,
    max: number,
    isOnGround: boolean,
    isGliding: boolean,
    isFlying: boolean,
    isShielding: boolean,
    nearReflectionPool: boolean,
    blessingBoost: boolean,
    blessingBoostExpires: number,
    nearbyPlayerCount: number,
    isMeditating: boolean,
    meditationStart: number,
}

local StaminaState: { [number]: StaminaState } = {}

---------------------------------------------------------------------------
-- Stamina helpers
---------------------------------------------------------------------------

function WingService:GetMaxStamina(player: Player): number
    local DataService = Knit.GetService("DataService")
    local data = DataService:GetData(player)
    if not data then
        return BASE_STAMINA
    end
    local levelIndex = Layers.GetLevelIndex(data.angelLevel)
    return BASE_STAMINA + (levelIndex - 1) * STAMINA_PER_LEVEL
end

function WingService:InitPlayer(player: Player): ()
    local maxStamina = self:GetMaxStamina(player)
    StaminaState[player.UserId] = {
        current = maxStamina,
        max = maxStamina,
        isOnGround = true,
        isGliding = false,
        isFlying = false,
        isShielding = false,
        nearReflectionPool = false,
        blessingBoost = false,
        blessingBoostExpires = 0,
        nearbyPlayerCount = 0,
        isMeditating = false,
        meditationStart = 0,
    }
end

function WingService:RemovePlayer(player: Player): ()
    StaminaState[player.UserId] = nil
end

function WingService:GetStamina(player: Player): (number, number)
    local state = StaminaState[player.UserId]
    if not state then
        return 0, BASE_STAMINA
    end
    return state.current, state.max
end

function WingService:DrainStamina(player: Player, action: string, amount: number?): boolean
    local state = StaminaState[player.UserId]
    if not state then
        return false
    end

    local drain = amount or DRAIN_RATES[action] or 0
    if state.current < drain then
        return false -- not enough stamina
    end

    state.current = math.max(0, state.current - drain)
    self.Client.StaminaUpdate:Fire(player, {
        current = state.current,
        max = state.max,
        action = action,
    })
    return true
end

function WingService:SetPlayerState(player: Player, key: string, value: any): ()
    local state = StaminaState[player.UserId]
    if state then
        (state :: any)[key] = value
    end
end

function WingService:ApplyBlessingBoost(player: Player): ()
    local state = StaminaState[player.UserId]
    if state then
        -- Immediate 30% stamina restore
        local boost = state.max * 0.3
        state.current = math.min(state.max, state.current + boost)
        state.blessingBoost = true
        state.blessingBoostExpires = os.time() + 30 -- 30 second recovery boost

        self.Client.StaminaUpdate:Fire(player, {
            current = state.current,
            max = state.max,
            action = "blessing_received",
        })
    end
end

---------------------------------------------------------------------------
-- Main update tick (called every Heartbeat)
---------------------------------------------------------------------------

function WingService:Update(dt: number): ()
    local now = os.time()
    local HALTService = Knit.GetService("HALTService")

    for userId, state in pairs(StaminaState) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            continue
        end

        -- Calculate recovery rate
        local recoveryRate = 0

        if state.isOnGround and not state.isGliding and not state.isFlying then
            recoveryRate = RECOVERY_RATES.ground

            if state.nearReflectionPool then
                recoveryRate = RECOVERY_RATES.reflection_pool
            end

            if state.blessingBoost and now < state.blessingBoostExpires then
                recoveryRate = RECOVERY_RATES.blessing_boost
            elseif state.blessingBoost then
                state.blessingBoost = false
            end

            if state.nearbyPlayerCount >= 3 then
                recoveryRate = recoveryRate * 2
            end
        end

        -- Drain from active actions
        if state.isGliding then
            recoveryRate = -DRAIN_RATES.glide
        elseif state.isFlying then
            recoveryRate = -DRAIN_RATES.flight
        end

        if state.isShielding then
            recoveryRate = recoveryRate - DRAIN_RATES.shield
        end

        -- HALT slowdown (delegated to HALTService)
        local haltMultiplier = HALTService:GetHALTMultiplier(player)
        if haltMultiplier < 1 and recoveryRate > 0 then
            recoveryRate = recoveryRate * haltMultiplier
        end

        -- Meditation: full restore after 30s
        if state.isMeditating then
            if now - state.meditationStart >= 30 then
                state.current = state.max
                state.isMeditating = false
                self.Client.StaminaUpdate:Fire(player, {
                    current = state.current,
                    max = state.max,
                    action = "meditation_complete",
                })
            end
        end

        -- Apply recovery/drain
        if recoveryRate ~= 0 and not state.isMeditating then
            state.current = math.clamp(state.current + recoveryRate * dt, 0, state.max)
        end
    end
end

---------------------------------------------------------------------------
-- Wing Attachment: Halo
---------------------------------------------------------------------------

function WingService:AttachHalo(character: Model, data: { [string]: any }): ()
    if character:FindFirstChild("PlayerHalo") then return end

    local head = character:WaitForChild("Head", 3)
    if not head then return end

    local halo = Instance.new("Part")
    halo.Name = "PlayerHalo"
    halo.Shape = Enum.PartType.Cylinder
    halo.Size = Vector3.new(0.2, 3, 3)
    halo.Material = Enum.Material.Neon
    halo.CanCollide = false
    halo.Massless = true
    halo.Anchored = false

    -- Founder halo = gold, regular = cyan
    if data.founderHalo or (data.ownedCosmetics and data.ownedCosmetics["founders_halo"]) then
        halo.Color = Color3.fromRGB(255, 215, 0)
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 215, 0)
        light.Brightness = 1.5
        light.Range = 12
        light.Parent = halo
    else
        halo.Color = Color3.fromRGB(0, 212, 255)
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(0, 212, 255)
        light.Brightness = 1
        light.Range = 8
        light.Parent = halo
    end
    halo.Transparency = 0.2

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = halo
    weld.Parent = halo

    halo.CFrame = head.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, 0, math.rad(90))
    halo.Parent = character
end

---------------------------------------------------------------------------
-- Wing Attachment: Trail
---------------------------------------------------------------------------

function WingService:AttachWingTrail(character: Model): ()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or hrp:FindFirstChild("WingTrail") then return end

    -- Create two attachment points for the trail
    local att0 = Instance.new("Attachment")
    att0.Name = "TrailAtt0"
    att0.Position = Vector3.new(0, 1, -0.5)
    att0.Parent = hrp

    local att1 = Instance.new("Attachment")
    att1.Name = "TrailAtt1"
    att1.Position = Vector3.new(0, -1, -0.5)
    att1.Parent = hrp

    local trail = Instance.new("Trail")
    trail.Name = "WingTrail"
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Lifetime = 0.5
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 212, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 180)),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = hrp
end

---------------------------------------------------------------------------
-- Wing Attachment: Full feathered wings (primaries, secondaries, coverts)
---------------------------------------------------------------------------

function WingService:AttachWings(character: Model, data: { [string]: any }): ()
    if character:FindFirstChild("AngelWings") then return end

    -- Wait for torso to load (R15 = UpperTorso, R6 = Torso)
    local torso = character:WaitForChild("UpperTorso", 5) or character:WaitForChild("Torso", 5)
    if not torso then
        warn("[WingService] No torso found for wings on " .. character.Name)
        return
    end

    local levelIndex = 1
    local wingLevel = 1
    if data then
        local currentLevel = data.angelLevel or "Newborn"
        levelIndex = Layers.GetLevelIndex(currentLevel)
        wingLevel = data.wingLevel or 1
    end

    -- Wing size scales with level + forge
    local wingScale = 1 + (levelIndex - 1) * 0.3 + (wingLevel - 1) * 0.15

    -- Color by level
    local wingColor = WING_COLORS[levelIndex] or Color3.fromRGB(245, 245, 255)
    local tipColor = WING_TIPS[levelIndex] or Color3.fromRGB(220, 225, 240)

    -- Tint the base color slightly so wings are visible against white clouds
    local tintedColor = Color3.new(
        wingColor.R * 0.92 + 0.03,
        wingColor.G * 0.93 + 0.02,
        wingColor.B * 0.90 + 0.08
    )

    -- Build real feathered wings from multiple parts
    local wingModel = Instance.new("Model")
    wingModel.Name = "AngelWings"

    for side = -1, 1, 2 do
        local sideName = side == -1 and "L" or "R"
        local sideSign = side

        -- Wing bone (structural, hidden) — positioned well out from body
        local bone = Instance.new("Part")
        bone.Name = "WingBone_" .. sideName
        bone.Size = Vector3.new(0.3, 0.5 * wingScale, 4.0 * wingScale)
        bone.Material = Enum.Material.SmoothPlastic
        bone.Color = tintedColor
        bone.Transparency = 1
        bone.CanCollide = false
        bone.Massless = true
        -- 1.5 studs out, 0.3 up, 0.6 back. Angled outward at 35 degrees.
        bone.CFrame = torso.CFrame
            * CFrame.new(sideSign * 1.5, 0.3, 0.6)
            * CFrame.Angles(0, 0, math.rad(sideSign * -35))
        bone.Parent = wingModel

        local boneWeld = Instance.new("WeldConstraint")
        boneWeld.Part0 = torso
        boneWeld.Part1 = bone
        boneWeld.Parent = bone

        -- PRIMARY FEATHERS: 6-8 long feathers fanning 10-70 degrees
        local primaryCount = 6 + math.min(levelIndex, 2) -- 6 at level 1, up to 8
        for f = 1, primaryCount do
            local t = f / primaryCount
            local featherLength = (3.0 + t * 2.0) * wingScale  -- 3-5 studs
            local featherWidth = (0.9 - t * 0.2) * wingScale   -- 0.9 down to 0.7
            local featherThick = 0.2 * wingScale                -- 0.2 studs thick
            local spreadAngle = 10 + t * 60                     -- 10 to 70 degrees

            local isOuterTip = (f >= primaryCount - 1)          -- last 2 feathers

            local feather = Instance.new("Part")
            feather.Name = "Feather_" .. sideName .. "_" .. f
            feather.Size = Vector3.new(featherWidth, featherThick, featherLength)
            feather.Material = isOuterTip and Enum.Material.Neon or Enum.Material.SmoothPlastic
            feather.Color = isOuterTip and tipColor or tintedColor
            feather.Transparency = 0
            feather.CanCollide = false
            feather.Massless = true

            -- Fan feathers outward from the bone in a wide arc
            local featherAngle = math.rad(sideSign * spreadAngle)
            local yOffset = 0.3 - t * 0.6
            feather.CFrame = bone.CFrame
                * CFrame.new(0, yOffset * wingScale, -t * 2.5 * wingScale)
                * CFrame.Angles(
                    math.rad(-8 + t * 12),
                    featherAngle,
                    math.rad(sideSign * (-20 + t * 8))
                )
            feather.Parent = wingModel

            local featherWeld = Instance.new("WeldConstraint")
            featherWeld.Part0 = bone
            featherWeld.Part1 = feather
            featherWeld.Parent = feather
        end

        -- SECONDARY FEATHERS: 4 medium feathers overlapping with primaries
        for f = 1, 4 do
            local t = f / 4
            local secLength = (2.0 + t * 1.0) * wingScale  -- 2-3 studs
            local secWidth = 0.7 * wingScale
            local secThick = 0.2 * wingScale

            local sec = Instance.new("Part")
            sec.Name = "SecFeather_" .. sideName .. "_" .. f
            sec.Size = Vector3.new(secWidth, secThick, secLength)
            sec.Material = Enum.Material.SmoothPlastic
            sec.Color = tintedColor
            sec.Transparency = 0
            sec.CanCollide = false
            sec.Massless = true

            sec.CFrame = bone.CFrame
                * CFrame.new(0, (0.2 - t * 0.3) * wingScale, (-t * 1.2) * wingScale)
                * CFrame.Angles(
                    math.rad(-4 + t * 6),
                    math.rad(sideSign * (5 + t * 20)),
                    math.rad(sideSign * -18)
                )
            sec.Parent = wingModel

            local secWeld = Instance.new("WeldConstraint")
            secWeld.Part0 = bone
            secWeld.Part1 = sec
            secWeld.Parent = sec
        end

        -- COVERT FEATHERS: 3 short wide feathers at wing root for fullness
        for f = 1, 3 do
            local t = f / 3
            local covLength = (1.0 + t * 0.5) * wingScale  -- 1-1.5 studs
            local covWidth = 0.8 * wingScale
            local covThick = 0.2 * wingScale

            local cov = Instance.new("Part")
            cov.Name = "CovertFeather_" .. sideName .. "_" .. f
            cov.Size = Vector3.new(covWidth, covThick, covLength)
            cov.Material = Enum.Material.SmoothPlastic
            cov.Color = tintedColor
            cov.Transparency = 0
            cov.CanCollide = false
            cov.Massless = true

            cov.CFrame = bone.CFrame
                * CFrame.new(0, (0.35 - t * 0.25) * wingScale, 0.3 * wingScale)
                * CFrame.Angles(
                    math.rad(4),
                    math.rad(sideSign * t * 15),
                    math.rad(sideSign * -12)
                )
            cov.Parent = wingModel

            local covWeld = Instance.new("WeldConstraint")
            covWeld.Part0 = bone
            covWeld.Part1 = cov
            covWeld.Parent = cov
        end
    end

    -- Subtle wing glow (not blinding — just a soft aura)
    local wingLight = Instance.new("PointLight")
    wingLight.Name = "WingGlow"
    wingLight.Color = wingColor
    wingLight.Brightness = 0.3 + levelIndex * 0.1
    wingLight.Range = 6 + levelIndex * 1.5
    wingLight.Parent = wingModel:FindFirstChild("WingBone_L")

    wingModel.Parent = character
end

---------------------------------------------------------------------------
-- Wing Forge: Proximity prompt wiring
---------------------------------------------------------------------------

function WingService:WireWingForge(): ()
    local nurseryFolder = workspace:FindFirstChild("Layer1_Nursery")
    if not nurseryFolder then return end

    local anvil = nurseryFolder:FindFirstChild("WingForgeAnvil")
    if not anvil then return end

    local prompt = anvil:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return end

    prompt.Triggered:Connect(function(player: Player)
        self:HandleWingForge(player)
    end)

    print("[WingService] Wing Forge wired and ready")
end

---------------------------------------------------------------------------
-- Wing Forge: Handle forge interaction
---------------------------------------------------------------------------

function WingService:HandleWingForge(player: Player): ()
    local DataService = Knit.GetService("DataService")
    local data = DataService:GetData(player)
    if not data then return end

    local wingLevel = data.wingLevel or 1

    if wingLevel >= WING_MAX_LEVEL then
        self.Client.WingForged:Fire(player, {
            type = "info",
            message = "Your wings are at maximum power! You are a force of light.",
        })
        return
    end

    -- Check cost (scales with level)
    local cost = WING_FORGE_COST + (wingLevel - 1) * 2
    local MoteService = Knit.GetService("MoteService")
    if not MoteService:CanAfford(player, cost) then
        self.Client.WingForged:Fire(player, {
            type = "info",
            message = "You need " .. cost .. " Motes to forge your wings. Keep collecting!",
        })
        return
    end

    -- Spend motes and upgrade
    MoteService:AwardMotes(player, -cost, "wing_forge")
    data.wingLevel = wingLevel + 1

    -- Rebuild wings on the character with new level
    local character = player.Character
    if character then
        -- Remove old wings
        local oldLeft = character:FindFirstChild("AngelWings")
        if oldLeft then oldLeft:Destroy() end
        local oldRight = character:FindFirstChild("AngelWingR")
        if oldRight then oldRight:Destroy() end

        -- Attach upgraded wings
        self:AttachWings(character, data)
    end

    -- Flash the forge fire
    local nurseryFolder = workspace:FindFirstChild("Layer1_Nursery")
    if nurseryFolder then
        local fire = nurseryFolder:FindFirstChild("ForgeFire")
        if fire then
            local origColor = fire.Color
            fire.Color = Color3.fromRGB(255, 255, 255)
            fire.Size = Vector3.new(5, 7, 5)
            task.delay(0.5, function()
                if fire and fire.Parent then
                    fire.Color = origColor
                    fire.Size = Vector3.new(3, 4, 3)
                end
            end)
        end
    end

    -- Update the prompt text with new cost
    local nextCost = WING_FORGE_COST + (data.wingLevel - 1) * 2
    local anvil = nurseryFolder and nurseryFolder:FindFirstChild("WingForgeAnvil")
    if anvil then
        local prompt = anvil:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            if data.wingLevel >= WING_MAX_LEVEL then
                prompt.ActionText = "Wings Maxed!"
            else
                prompt.ActionText = "Forge Wings (" .. nextCost .. " Motes)"
            end
        end
    end

    self.Client.WingForged:Fire(player, {
        type = "info",
        message = "WINGS FORGED! Level " .. data.wingLevel .. "/" .. WING_MAX_LEVEL .. " — Your wings grow stronger! (-" .. cost .. " Motes)",
    })

    -- Quest hook
    local QuestService = Knit.GetService("QuestService")
    pcall(QuestService.OnWingForged, QuestService, player)

    print("[WingService] " .. player.Name .. " forged wings to level " .. data.wingLevel)
end

---------------------------------------------------------------------------
-- Client-exposed methods
---------------------------------------------------------------------------

function WingService.Client:GetStamina(player: Player): (number, number)
    return self.Server:GetStamina(player)
end

---------------------------------------------------------------------------
-- Knit Lifecycle
---------------------------------------------------------------------------

function WingService:KnitInit(): ()
    print("[WingService] Initializing...")
end

function WingService:KnitStart(): ()
    -- Wire the wing forge anvil prompt
    pcall(function()
        self:WireWingForge()
    end)

    -- Run stamina update loop every Heartbeat
    RunService.Heartbeat:Connect(function(dt: number)
        self:Update(dt)
    end)

    print("[WingService] Started")
end

return WingService
