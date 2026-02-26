--[[
    LayerIndicatorUI.lua — Vertical layer map showing player position
    Displays all 6 layers as a vertical bar on the right side of screen
    Player dot moves up/down based on Y position
    Current layer name displayed next to indicator
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Layers = require(ReplicatedStorage.Config.Layers)

local LayerIndicatorUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Colors matching each layer's identity
local LAYER_COLORS = {
    Color3.fromRGB(255, 215, 100),  -- Nursery: warm gold
    Color3.fromRGB(0, 212, 255),    -- Meadow: cyan
    Color3.fromRGB(100, 255, 180),  -- Canopy: green
    Color3.fromRGB(180, 100, 255),  -- Stormwall: purple
    Color3.fromRGB(100, 200, 255),  -- Luminance: bright blue
    Color3.fromRGB(255, 255, 255),  -- Empyrean: white
}

local LAYER_NAMES = {
    "Nursery",
    "Meadow",
    "Canopy",
    "Stormwall",
    "Luminance",
    "Empyrean",
}

-- World height range (matches Layers.lua definitions)
local WORLD_MIN_Y = 50
local WORLD_MAX_Y = 750

local indicatorFrame
local playerDot
local layerNameLabel
local altitudeLabel

function LayerIndicatorUI.Init()
    local screenGui = playerGui:FindFirstChild("AngelCloudUI")
    if not screenGui then
        -- Wait for UIManager to create it
        task.delay(3, function()
            screenGui = playerGui:FindFirstChild("AngelCloudUI")
            if screenGui then
                LayerIndicatorUI.CreateUI(screenGui)
            end
        end)
        return
    end

    LayerIndicatorUI.CreateUI(screenGui)
end

function LayerIndicatorUI.CreateUI(screenGui: ScreenGui)
    -- Main container (right side of screen, vertically centered)
    indicatorFrame = Instance.new("Frame")
    indicatorFrame.Name = "LayerIndicator"
    indicatorFrame.Size = UDim2.new(0, 40, 0, 300)
    indicatorFrame.Position = UDim2.new(1, -55, 0.5, -150)
    indicatorFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    indicatorFrame.BackgroundTransparency = 0.3
    indicatorFrame.BorderSizePixel = 0
    indicatorFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = indicatorFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 212, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = indicatorFrame

    -- Layer segments (6 colored bands from bottom to top)
    for i = 1, 6 do
        local segHeight = 1 / 6
        local seg = Instance.new("Frame")
        seg.Name = "Layer" .. i
        seg.Size = UDim2.new(0.6, 0, segHeight, -2)
        seg.Position = UDim2.new(0.2, 0, 1 - segHeight * i, 1)
        seg.BackgroundColor3 = LAYER_COLORS[i]
        seg.BackgroundTransparency = 0.5
        seg.BorderSizePixel = 0
        seg.Parent = indicatorFrame

        local segCorner = Instance.new("UICorner")
        segCorner.CornerRadius = UDim.new(0, 3)
        segCorner.Parent = seg

        -- Layer number label
        local numLabel = Instance.new("TextLabel")
        numLabel.Size = UDim2.new(1, 0, 1, 0)
        numLabel.BackgroundTransparency = 1
        numLabel.Text = tostring(i)
        numLabel.TextColor3 = LAYER_COLORS[i]
        numLabel.TextSize = 10
        numLabel.Font = Enum.Font.GothamBold
        numLabel.TextTransparency = 0.3
        numLabel.Parent = seg
    end

    -- Player position dot
    playerDot = Instance.new("Frame")
    playerDot.Name = "PlayerDot"
    playerDot.Size = UDim2.new(0, 12, 0, 12)
    playerDot.Position = UDim2.new(0.5, -6, 0.9, -6)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    playerDot.BorderSizePixel = 0
    playerDot.ZIndex = 2
    playerDot.Parent = indicatorFrame

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = playerDot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(0, 212, 255)
    dotStroke.Thickness = 2
    dotStroke.Parent = playerDot

    -- Current layer name (to the left of the bar)
    layerNameLabel = Instance.new("TextLabel")
    layerNameLabel.Name = "LayerName"
    layerNameLabel.Size = UDim2.new(0, 100, 0, 20)
    layerNameLabel.Position = UDim2.new(0, -110, 0.5, -10)
    layerNameLabel.BackgroundTransparency = 1
    layerNameLabel.Text = "The Nursery"
    layerNameLabel.TextColor3 = LAYER_COLORS[1]
    layerNameLabel.TextSize = 13
    layerNameLabel.Font = Enum.Font.GothamBold
    layerNameLabel.TextXAlignment = Enum.TextXAlignment.Right
    layerNameLabel.Parent = indicatorFrame

    -- Altitude readout
    altitudeLabel = Instance.new("TextLabel")
    altitudeLabel.Name = "Altitude"
    altitudeLabel.Size = UDim2.new(0, 100, 0, 16)
    altitudeLabel.Position = UDim2.new(0, -110, 0.5, 10)
    altitudeLabel.BackgroundTransparency = 1
    altitudeLabel.Text = "Alt: 100"
    altitudeLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    altitudeLabel.TextSize = 11
    altitudeLabel.Font = Enum.Font.Gotham
    altitudeLabel.TextXAlignment = Enum.TextXAlignment.Right
    altitudeLabel.Parent = indicatorFrame

    -- Update loop
    RunService.RenderStepped:Connect(LayerIndicatorUI.Update)

    print("[LayerIndicatorUI] Layer indicator initialized")
end

function LayerIndicatorUI.Update()
    if not indicatorFrame or not playerDot then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local y = hrp.Position.Y

    -- Map Y position to indicator bar position (0 = top, 1 = bottom)
    local normalized = math.clamp((y - WORLD_MIN_Y) / (WORLD_MAX_Y - WORLD_MIN_Y), 0, 1)
    local barPosition = 1 - normalized  -- invert (top = high altitude)

    playerDot.Position = UDim2.new(0.5, -6, barPosition, -6)

    -- Determine current layer
    local currentLayer = 1
    for i = 6, 1, -1 do
        local layerDef = Layers.GetLayerByIndex(i)
        if layerDef and y >= layerDef.heightRange.min then
            currentLayer = i
            break
        end
    end

    -- Update layer name and color
    if layerNameLabel then
        layerNameLabel.Text = LAYER_NAMES[currentLayer] or "Unknown"
        layerNameLabel.TextColor3 = LAYER_COLORS[currentLayer] or Color3.fromRGB(255, 255, 255)
    end

    -- Update altitude
    if altitudeLabel then
        altitudeLabel.Text = "Alt: " .. math.floor(y)
    end

    -- Update dot color to match current layer
    if playerDot then
        playerDot.BackgroundColor3 = LAYER_COLORS[currentLayer] or Color3.fromRGB(255, 255, 255)
    end
end

return LayerIndicatorUI
