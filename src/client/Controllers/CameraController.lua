--[[
    CameraController.lua — Knit Controller for custom camera behaviors
    Manages: FOV transitions (flight/glide/default), cinematic cameras, zone-specific angles
    FOV management partially extracted from ClientController's flight system
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local CameraController = Knit.CreateController({ Name = "CameraController" })

local player: Player = Players.LocalPlayer

-- =====================================================================
-- FOV CONSTANTS — extracted from ClientController flight system
-- =====================================================================
local BASE_FOV: number = 70
local GLIDE_FOV: number = 80
local FLIGHT_FOV: number = 95
local FOV_LERP_SPEED: number = 0.1

-- Camera state
local targetFOV: number = BASE_FOV
local cinematicActive: boolean = false
local zoneOverrideFOV: number? = nil

type CameraMode = "Default" | "Flight" | "Glide" | "Cinematic" | "ZoneOverride"
local currentMode: CameraMode = "Default"

--[=[
    Sets the camera FOV target for smooth lerp transitions.
    @param fov number -- The target field of view value
]=]
function CameraController:SetTargetFOV(fov: number): ()
    targetFOV = fov
end

--[=[
    Gets the current target FOV.
    @return number -- The current target FOV
]=]
function CameraController:GetTargetFOV(): number
    return targetFOV
end

--[=[
    Sets the camera mode and adjusts FOV accordingly.
    @param mode CameraMode -- The camera mode to switch to
    @param velocity number? -- Optional velocity for dynamic FOV scaling in flight/glide
]=]
function CameraController:SetMode(mode: CameraMode, velocity: number?): ()
    currentMode = mode
    local vel: number = velocity or 0

    if mode == "Default" then
        targetFOV = BASE_FOV
    elseif mode == "Flight" then
        targetFOV = math.clamp(FLIGHT_FOV + vel * 0.1, FLIGHT_FOV, FLIGHT_FOV + 10)
    elseif mode == "Glide" then
        targetFOV = math.clamp(GLIDE_FOV + vel * 0.08, GLIDE_FOV, FLIGHT_FOV)
    elseif mode == "Cinematic" then
        cinematicActive = true
    elseif mode == "ZoneOverride" then
        if zoneOverrideFOV then
            targetFOV = zoneOverrideFOV
        end
    end
end

--[=[
    Gets the current camera mode.
    @return CameraMode -- The active camera mode
]=]
function CameraController:GetMode(): CameraMode
    return currentMode
end

--[=[
    Sets a zone-specific FOV override. Call with nil to clear.
    @param fov number? -- The FOV override for the current zone, or nil to clear
]=]
function CameraController:SetZoneOverrideFOV(fov: number?): ()
    zoneOverrideFOV = fov
    if fov and currentMode == "ZoneOverride" then
        targetFOV = fov
    end
end

--[=[
    Enables or disables cinematic camera mode.
    When active, external systems (CinematicController) drive the camera.
    @param active boolean -- Whether cinematic mode is active
]=]
function CameraController:SetCinematicActive(active: boolean): ()
    cinematicActive = active
    if not active then
        currentMode = "Default"
        targetFOV = BASE_FOV
    end
end

--[=[
    Returns whether cinematic mode is currently active.
    @return boolean -- True if cinematic camera is active
]=]
function CameraController:IsCinematicActive(): boolean
    return cinematicActive
end

--[=[
    Per-frame FOV interpolation update. Smoothly lerps the camera FOV
    toward the target value. Skipped during cinematic mode.
    @param _dt number -- Delta time (unused, uses fixed lerp factor)
]=]
function CameraController:_updateFOV(_dt: number): ()
    if cinematicActive then return end

    local camera: Camera = workspace.CurrentCamera
    if not camera then return end

    camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * FOV_LERP_SPEED
end

--[=[
    KnitInit: Initializes camera state. Future: connect to zone change events.
]=]
function CameraController:KnitInit(): ()
    print("[CameraController] Camera system initialized — FOV management active")
end

--[=[
    KnitStart: Binds the per-frame FOV update to RenderStepped.
    Future: cinematic camera sequences, zone-specific angle overrides.
]=]
function CameraController:KnitStart(): ()
    RunService.RenderStepped:Connect(function(dt: number)
        self:_updateFOV(dt)
    end)
end

return CameraController
