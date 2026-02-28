--[[
    FlightController.lua -- Flight mechanics state machine
    Handles: glide, full flight, wing visuals, FOV, flight-time tracking
    Flight states: Grounded -> Gliding -> Flying

    Physics:
      Glide  = LinearVelocity (slow fall) + horizontal boost via AssemblyLinearVelocity
      Flight = LinearVelocity (directional) + VectorForce (anti-gravity)

    Input is read from InputController via getters each frame.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local FlightController = Knit.CreateController({
    Name = "FlightController",
})

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

-- Glide physics -- fast and fun, not floaty and boring
local GLIDE_FALL_SPEED: number = -4         -- very slow descent (hang time!)
local GLIDE_HORIZONTAL_BOOST: number = 2.5  -- zip across the sky

-- Flight speed -- FAST so it feels good
local FLIGHT_SPEED: number = 80             -- horizontal flight speed
local FLIGHT_VERTICAL_SPEED: number = 50    -- up/down speed while flying

-- Dynamic FOV (inspired by Gemini's FlightEngine -- smooth camera zoom at speed)
local BASE_FOV: number = 70
local GLIDE_FOV: number = 80
local FLIGHT_FOV: number = 95
local FOV_LERP_SPEED: number = 0.1          -- smooth interpolation factor

-- Flight time tracking for quests
local FLIGHT_REPORT_INTERVAL: number = 10   -- report every 10 seconds of flight

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local player: Player = Players.LocalPlayer
local camera: Camera = workspace.CurrentCamera

local isGliding: boolean = false
local isFlying: boolean = false
local canGlide: boolean = true   -- UNLOCKED FROM THE START
local canFly: boolean = true     -- EVERYONE CAN FLY from the start!
local stamina: number = 100
local maxStamina: number = 100
local currentLevel: string = "Newborn"
local currentLayer: number = 1

local flightTimeAccum: number = 0

-- Controller reference (populated in KnitStart)
local InputController: any = nil

---------------------------------------------------------------------------
-- State getters
---------------------------------------------------------------------------

function FlightController:IsFlying(): boolean
    return isFlying
end

function FlightController:IsGliding(): boolean
    return isGliding
end

function FlightController:GetStamina(): number
    return stamina
end

function FlightController:GetMaxStamina(): number
    return maxStamina
end

---------------------------------------------------------------------------
-- Wing visuals
---------------------------------------------------------------------------

function FlightController:ShowWings(active: boolean): ()
    local character: Model? = player.Character
    if not character then return end

    local wingModel: Model? = character:FindFirstChild("AngelWings") :: Model?
    if not wingModel or not wingModel:IsA("Model") then return end

    -- When flying/gliding: spread wings wider and add subtle glow
    for _, part in ipairs(wingModel:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "WingBone_L" and part.Name ~= "WingBone_R" then
            -- Feathers become slightly more visible when active
            if string.find(part.Name, "Feather") then
                part.Transparency = active and 0 or 0
            end
        end
    end

    -- Add/remove flight glow effect
    local boneL: BasePart? = wingModel:FindFirstChild("WingBone_L") :: BasePart?
    local boneR: BasePart? = wingModel:FindFirstChild("WingBone_R") :: BasePart?

    if active then
        -- Add soft sparkle trail from wing tips when flying
        for _, bone in ipairs({ boneL, boneR }) do
            if bone and not bone:FindFirstChild("WingSparkle") then
                local sparkle: ParticleEmitter = Instance.new("ParticleEmitter")
                sparkle.Name = "WingSparkle"
                sparkle.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255)),
                })
                sparkle.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 0),
                })
                sparkle.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.5),
                    NumberSequenceKeypoint.new(1, 1),
                })
                sparkle.Lifetime = NumberRange.new(0.3, 0.8)
                sparkle.Rate = 6
                sparkle.Speed = NumberRange.new(0.5, 2)
                sparkle.SpreadAngle = Vector2.new(60, 60)
                sparkle.LightEmission = 0.5
                sparkle.Parent = bone
            end
        end
    else
        -- Remove sparkles when landing
        for _, bone in ipairs({ boneL, boneR }) do
            if bone then
                local sparkle: ParticleEmitter? = bone:FindFirstChild("WingSparkle") :: ParticleEmitter?
                if sparkle then sparkle:Destroy() end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Glide
---------------------------------------------------------------------------

function FlightController:StartGlide(): ()
    if isGliding or stamina <= 0 then
        return
    end

    isGliding = true
    local character: Model? = player.Character
    if not character then
        isGliding = false
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        isGliding = false
        return
    end

    -- Create glide using LinearVelocity (modern physics)
    local att: Attachment? = humanoidRootPart:FindFirstChild("GlideAttachment") :: Attachment?
    if not att then
        att = Instance.new("Attachment")
        att.Name = "GlideAttachment"
        att.Parent = humanoidRootPart
    end

    local glideForce: LinearVelocity = Instance.new("LinearVelocity")
    glideForce.Name = "GlideForce"
    glideForce.Attachment0 = att
    glideForce.MaxForce = 20000
    glideForce.VectorVelocity = Vector3.new(0, GLIDE_FALL_SPEED, 0)
    glideForce.RelativeTo = Enum.ActuatorRelativeTo.World
    glideForce.Parent = humanoidRootPart

    -- Wing visual effect
    self:ShowWings(true)
end

function FlightController:StopGlide(): ()
    isGliding = false
    local character: Model? = player.Character
    if character then
        local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if humanoidRootPart then
            local glideForce = humanoidRootPart:FindFirstChild("GlideForce")
            if glideForce then glideForce:Destroy() end
            local glideAtt = humanoidRootPart:FindFirstChild("GlideAttachment")
            if glideAtt then glideAtt:Destroy() end
        end
    end
    self:ShowWings(false)
end

---------------------------------------------------------------------------
-- Flight
---------------------------------------------------------------------------

function FlightController:ToggleFlight(): ()
    if not canFly then
        return
    end

    if isFlying then
        self:StopFlight()
    else
        self:StartFlight()
    end
end

function FlightController:StartFlight(): ()
    isFlying = true
    isGliding = false

    local character: Model? = player.Character
    if not character then
        isFlying = false
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        isFlying = false
        return
    end

    -- Remove any existing glide force
    local existingForce = humanoidRootPart:FindFirstChild("GlideForce")
    if existingForce then
        existingForce:Destroy()
    end
    local existingGlideAtt = humanoidRootPart:FindFirstChild("GlideAttachment")
    if existingGlideAtt then
        existingGlideAtt:Destroy()
    end

    -- Create attachment for LinearVelocity
    local att: Attachment = Instance.new("Attachment")
    att.Name = "FlightAttachment"
    att.Parent = humanoidRootPart

    -- Use LinearVelocity (modern replacement for BodyVelocity)
    local flightForce: LinearVelocity = Instance.new("LinearVelocity")
    flightForce.Name = "FlightForce"
    flightForce.Attachment0 = att
    flightForce.MaxForce = 50000
    flightForce.VectorVelocity = Vector3.zero
    flightForce.RelativeTo = Enum.ActuatorRelativeTo.World
    flightForce.Parent = humanoidRootPart

    -- Counteract gravity with VectorForce
    local antiGrav: VectorForce = Instance.new("VectorForce")
    antiGrav.Name = "FlightAntiGrav"
    antiGrav.Attachment0 = att
    antiGrav.Force = Vector3.new(0, humanoidRootPart.AssemblyMass * workspace.Gravity, 0)
    antiGrav.RelativeTo = Enum.ActuatorRelativeTo.World
    antiGrav.ApplyAtCenterOfMass = true
    antiGrav.Parent = humanoidRootPart

    self:ShowWings(true)
    print("[Flight] Flight enabled!")
end

function FlightController:StopFlight(): ()
    isFlying = false
    local character: Model? = player.Character
    if character then
        local hrp: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            local ff = hrp:FindFirstChild("FlightForce")
            if ff then ff:Destroy() end
            local ag = hrp:FindFirstChild("FlightAntiGrav")
            if ag then ag:Destroy() end
            local fa = hrp:FindFirstChild("FlightAttachment")
            if fa then fa:Destroy() end
        end
    end
    self:ShowWings(false)
end

---------------------------------------------------------------------------
-- Per-frame update (RenderStepped)
---------------------------------------------------------------------------

function FlightController:Update(dt: number): ()
    local character: Model? = player.Character
    if not character then
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
    if not humanoidRootPart or not humanoid then
        return
    end

    -- Read input state from InputController
    local flyUpHeld: boolean = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local flyDownHeld: boolean = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    if InputController then
        flyUpHeld = flyUpHeld or InputController:IsFlyUpHeld()
        flyDownHeld = flyDownHeld or InputController:IsFlyDownHeld()
    end

    -- Update flight velocity based on camera direction
    if isFlying then
        local flightForce: LinearVelocity? = humanoidRootPart:FindFirstChild("FlightForce") :: LinearVelocity?
        if flightForce then
            local moveDirection: Vector3 = humanoid.MoveDirection
            local velocity: Vector3 = Vector3.zero

            -- WASD moves you in camera direction (true 3D flight)
            -- moveDirection is already world-space and camera-relative from Humanoid
            if moveDirection.Magnitude > 0 then
                velocity = moveDirection.Unit * FLIGHT_SPEED
            end

            -- Space/RT/A = go UP, Shift/LT = go DOWN (keyboard + gamepad)
            if flyUpHeld then
                velocity = velocity + Vector3.new(0, FLIGHT_VERTICAL_SPEED, 0)
            end
            if flyDownHeld then
                velocity = velocity + Vector3.new(0, -FLIGHT_VERTICAL_SPEED, 0)
            end

            flightForce.VectorVelocity = velocity
        end
    end

    -- Auto-stop glide when landing
    if isGliding then
        if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            self:StopGlide()
        end
    end

    -- Gamepad: auto-start glide if A is held and we enter freefall
    local glideHeld: boolean = InputController and InputController:IsGlideHeld() or false
    if glideHeld and not isGliding and not isFlying and canGlide then
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            self:StartGlide()
        end
    end

    -- Glide horizontal boost
    if isGliding and stamina > 0 then
        local moveDirection: Vector3 = humanoid.MoveDirection
        if moveDirection.Magnitude > 0 then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * 30 * GLIDE_HORIZONTAL_BOOST,
                humanoidRootPart.AssemblyLinearVelocity.Y,
                moveDirection.Z * 30 * GLIDE_HORIZONTAL_BOOST
            )
        end
    end

    -- Track flight time for quests
    if isFlying then
        flightTimeAccum = flightTimeAccum + dt
        if flightTimeAccum >= FLIGHT_REPORT_INTERVAL then
            local FlightTime: RemoteEvent? = ReplicatedStorage:FindFirstChild("FlightTime") :: RemoteEvent?
            if FlightTime then
                FlightTime:FireServer(math.floor(flightTimeAccum))
            end
            flightTimeAccum = 0
        end
    else
        flightTimeAccum = 0
    end

    -- Dynamic FOV: widens during flight/glide based on speed
    local targetFOV: number = BASE_FOV
    if isFlying then
        local velocity: number = humanoidRootPart.AssemblyLinearVelocity.Magnitude
        targetFOV = math.clamp(FLIGHT_FOV + velocity * 0.1, FLIGHT_FOV, FLIGHT_FOV + 10)
    elseif isGliding then
        local velocity: number = humanoidRootPart.AssemblyLinearVelocity.Magnitude
        targetFOV = math.clamp(GLIDE_FOV + velocity * 0.08, GLIDE_FOV, FLIGHT_FOV)
    end
    camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * FOV_LERP_SPEED
end

---------------------------------------------------------------------------
-- Server event handlers
---------------------------------------------------------------------------

function FlightController:OnStaminaUpdate(data: { [string]: any }): ()
    stamina = data.current
    maxStamina = data.max

    -- Update stamina UI
    local staminaModule = player:WaitForChild("PlayerScripts"):FindFirstChild("StaminaUI")
    if staminaModule then
        local StaminaUI = require(staminaModule)
        StaminaUI.UpdateBar(stamina, maxStamina, data.action)
    end
end

function FlightController:OnLevelUp(data: { [string]: any }): ()
    currentLevel = data.newLevel
    currentLayer = data.layerIndex

    -- Update capabilities
    canGlide = true
    canFly = true -- everyone flies!

    -- Trigger cinematic
    local cinematicModule = player:WaitForChild("PlayerScripts"):FindFirstChild("LevelUpCinematic")
    if cinematicModule then
        local LevelUpCinematic = require(cinematicModule)
        LevelUpCinematic.Play(data)
    end
end

function FlightController:OnServerMessage(data: { [string]: any }): ()
    if data.type == "welcome" then
        currentLevel = data.angelLevel
        local Layers = require(ReplicatedStorage.Config.Layers)
        local levelIndex: number = Layers.GetLevelIndex(currentLevel)
        currentLayer = levelIndex
        canGlide = true
        canFly = true
    end

    local uiModule = player:WaitForChild("PlayerScripts"):FindFirstChild("UIManager")
    if uiModule then
        local UIManager = require(uiModule)
        UIManager.ShowMessage(data)
    end
end

---------------------------------------------------------------------------
-- Knit lifecycle
---------------------------------------------------------------------------

function FlightController:KnitInit(): ()
    -- Nothing needed at init; services/controllers not yet available
end

function FlightController:KnitStart(): ()
    InputController = Knit.GetController("InputController")

    -- Wait for RemoteEvents (with timeout to avoid infinite hang)
    local StaminaUpdate: RemoteEvent? = ReplicatedStorage:WaitForChild("StaminaUpdate", 30) :: RemoteEvent?
    local PlayerReady: RemoteEvent? = ReplicatedStorage:WaitForChild("PlayerReady", 30) :: RemoteEvent?
    local LevelUp: RemoteEvent? = ReplicatedStorage:WaitForChild("LevelUp", 30) :: RemoteEvent?
    local ServerMessage: RemoteEvent? = ReplicatedStorage:WaitForChild("ServerMessage", 30) :: RemoteEvent?

    if not StaminaUpdate or not PlayerReady or not LevelUp or not ServerMessage then
        warn("[FlightController] Timed out waiting for RemoteEvents -- server may still be loading")
        return
    end

    -- Listen for server events
    StaminaUpdate.OnClientEvent:Connect(function(data: { [string]: any })
        self:OnStaminaUpdate(data)
    end)
    LevelUp.OnClientEvent:Connect(function(data: { [string]: any })
        self:OnLevelUp(data)
    end)
    ServerMessage.OnClientEvent:Connect(function(data: { [string]: any })
        self:OnServerMessage(data)
    end)

    -- Update loop
    RunService.RenderStepped:Connect(function(dt: number)
        self:Update(dt)
    end)

    -- Notify server we're ready
    task.wait(2) -- let everything load
    PlayerReady:FireServer()

    print("[FlightController] Flight system ready")
end

return FlightController
