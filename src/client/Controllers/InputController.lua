--[[
    InputController.lua -- Cross-platform input detection and delegation
    Handles: keyboard, gamepad (Xbox), and mobile touch input
    Delegates flight actions to FlightController via Knit

    KEYBOARD:
    F key = TOGGLE FLIGHT (one press fly, one press land)
    HOLD Space while airborne = glide
    While flying: WASD move, Space = up, Shift = down
    E = action / interact
    C = Lore Codex

    GAMEPAD (Xbox Controller):
    Y button = TOGGLE FLIGHT (one press fly, one press land)
    Left Bumper (LB) = TOGGLE FLIGHT (alternate)
    While flying: Left Stick = move, RT = up, LT = down
    Hold A while airborne = glide
    X button = action / interact
    B button = open Lore Codex
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InputController = Knit.CreateController({
    Name = "InputController",
})

-- References (populated in KnitStart)
local FlightController
local player: Player = Players.LocalPlayer

-- Gamepad / mobile state flags (shared with FlightController via getters)
local gamepadFlyUp: boolean = false
local gamepadFlyDown: boolean = false
local gamepadGlideHeld: boolean = false

---------------------------------------------------------------------------
-- Public getters so FlightController can read input state each frame
---------------------------------------------------------------------------

function InputController:IsFlyUpHeld(): boolean
    return gamepadFlyUp
end

function InputController:IsFlyDownHeld(): boolean
    return gamepadFlyDown
end

function InputController:IsGlideHeld(): boolean
    return gamepadGlideHeld
end

---------------------------------------------------------------------------
-- Input handlers
---------------------------------------------------------------------------

function InputController:OnInputBegan(input: InputObject, gameProcessed: boolean): ()
    -- IMPORTANT: Roblox marks gamepad buttons as "gameProcessed" (ButtonA = jump, etc.)
    -- We MUST let gamepad buttons through, otherwise controller flight never works.
    -- Only block keyboard inputs that were consumed by chat/GUI.
    local isGamepad: boolean = input.UserInputType == Enum.UserInputType.Gamepad1
    if gameProcessed and not isGamepad then
        return
    end

    -- === FLIGHT TOGGLE (the #1 most important input) ===
    -- Y button (gamepad) or F key (keyboard) = instant flight toggle
    if input.KeyCode == Enum.KeyCode.ButtonY
        or input.KeyCode == Enum.KeyCode.ButtonL1
        or input.KeyCode == Enum.KeyCode.F then
        if FlightController then
            FlightController:ToggleFlight()
        end
        return
    end

    -- === A button (gamepad) / Space (keyboard) = glide or fly up ===
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
        -- If already flying, A/Space = go up (handled in FlightController Update loop via flag)
        if FlightController and FlightController:IsFlying() then
            if input.KeyCode == Enum.KeyCode.ButtonA then
                gamepadFlyUp = true
            end
            return
        end

        -- Hold while falling = glide
        if input.KeyCode == Enum.KeyCode.ButtonA then
            gamepadGlideHeld = true
        end
        local character: Model? = player.Character
        if character then
            local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                if FlightController and not FlightController:IsFlying() then
                    FlightController:StartGlide()
                end
            end
        end
        return
    end

    -- === Right Trigger = fly up ===
    if input.KeyCode == Enum.KeyCode.ButtonR2 then
        gamepadFlyUp = true
        return
    end

    -- === Left Trigger = fly down ===
    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        gamepadFlyDown = true
        return
    end

    -- === X button (gamepad) / E key = action ===
    if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
        self:HandleAction()
        return
    end

    -- === B button (gamepad) / C key = Lore Codex ===
    if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonB then
        -- LoreCodexUI is loaded externally; fire through a signal or direct require
        -- Keeping the legacy behaviour: require from the old script tree if present
        local loreModule = player:WaitForChild("PlayerScripts"):FindFirstChild("LoreCodexUI")
        if loreModule then
            local LoreCodexUI = require(loreModule)
            LoreCodexUI.Toggle()
        end
        return
    end
end

function InputController:OnInputEnded(input: InputObject, _gameProcessed: boolean): ()
    -- Let gamepad releases through (same logic as OnInputBegan)
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
        if FlightController and FlightController:IsGliding() then
            FlightController:StopGlide()
        end
        gamepadGlideHeld = false
        if input.KeyCode == Enum.KeyCode.ButtonA then
            gamepadFlyUp = false
        end
    end

    if input.KeyCode == Enum.KeyCode.ButtonR2 then
        gamepadFlyUp = false
    end
    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        gamepadFlyDown = false
    end
end

---------------------------------------------------------------------------
-- Action key (E / X) -- proximity-prompt-like interactions
---------------------------------------------------------------------------

function InputController:HandleAction(): ()
    local character: Model? = player.Character
    if not character then
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        return
    end

    -- Look for nearby meditation spots or reflection pools
    local position: Vector3 = humanoidRootPart.Position
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "MeditationSpot" and obj:IsA("BasePart") then
            if (obj.Position - position).Magnitude < 15 then
                -- Meditation is handled server-side via stamina system
                break
            end
        end
    end
end

---------------------------------------------------------------------------
-- Mobile touch controls
---------------------------------------------------------------------------

function InputController:_setupMobileInput(): ()
    if not UserInputService.TouchEnabled then
        return
    end

    local mobileModule = player:WaitForChild("PlayerScripts"):FindFirstChild("MobileInputUI")
    if not mobileModule then
        return
    end

    local MobileInputUI = require(mobileModule)

    MobileInputUI.OnFlightToggle = function()
        if FlightController then
            FlightController:ToggleFlight()
        end
    end

    MobileInputUI.OnGlideStart = function()
        local character: Model? = player.Character
        if character then
            local humanoid: Humanoid? = character:FindFirstChild("Humanoid") :: Humanoid?
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                if FlightController and not FlightController:IsFlying() then
                    FlightController:StartGlide()
                end
            end
        end
    end

    MobileInputUI.OnGlideEnd = function()
        if FlightController and FlightController:IsGliding() then
            FlightController:StopGlide()
        end
    end

    MobileInputUI.OnDescendStart = function()
        gamepadFlyDown = true -- reuse gamepad flag for mobile descend
    end

    MobileInputUI.OnDescendEnd = function()
        gamepadFlyDown = false
    end

    MobileInputUI.Init()
end

---------------------------------------------------------------------------
-- Knit lifecycle
---------------------------------------------------------------------------

function InputController:KnitInit(): ()
    -- Nothing needed at init time; services/controllers not yet available
end

function InputController:KnitStart(): ()
    FlightController = Knit.GetController("FlightController")

    -- Wire up UserInputService
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        self:OnInputBegan(input, gameProcessed)
    end)
    UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
        self:OnInputEnded(input, gameProcessed)
    end)

    -- Mobile controls
    self:_setupMobileInput()

    print("[InputController] Input system ready")
end

return InputController
