--[[
    MiniMap.lua — Zone navigation minimap (Phase 2 shell)
    Placeholder module for the minimap HUD element
    Will display current zone layer and player position indicator
    Visual identity: #0a0a0f background, #00d4ff accent
]]

local MiniMap = {}

---------------------------------------------------------------------------
-- Types
---------------------------------------------------------------------------

type MapConfig = {
    layerCount: number?,
    layerNames: { string }?,
}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local COLORS = {
    bg      = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent  = Color3.fromRGB(0, 212, 255),
    gold    = Color3.fromRGB(255, 215, 0),
    white   = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
    playerDot = Color3.fromRGB(0, 212, 255),
}

local MAP_SIZE: number = 140

---------------------------------------------------------------------------
-- Create: Build the minimap frame inside the given parent (shell)
---------------------------------------------------------------------------

function MiniMap.Create(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Name = "MiniMap"
    frame.Size = UDim2.new(0, MAP_SIZE, 0, MAP_SIZE + 20)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Map background (circular-ish container)
    local mapBg = Instance.new("Frame")
    mapBg.Name = "MapBackground"
    mapBg.Size = UDim2.new(0, MAP_SIZE, 0, MAP_SIZE)
    mapBg.Position = UDim2.new(0, 0, 0, 0)
    mapBg.BackgroundColor3 = COLORS.bg
    mapBg.BackgroundTransparency = 0.3
    mapBg.BorderSizePixel = 0
    mapBg.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mapBg

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = mapBg

    -- Player position dot (center initially)
    local playerDot = Instance.new("Frame")
    playerDot.Name = "PlayerDot"
    playerDot.Size = UDim2.new(0, 8, 0, 8)
    playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
    playerDot.BackgroundColor3 = COLORS.playerDot
    playerDot.BorderSizePixel = 0
    playerDot.Parent = mapBg

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = playerDot

    -- Layer name label
    local layerLabel = Instance.new("TextLabel")
    layerLabel.Name = "LayerLabel"
    layerLabel.Size = UDim2.new(1, 0, 0, 16)
    layerLabel.Position = UDim2.new(0, 0, 0, MAP_SIZE + 2)
    layerLabel.BackgroundTransparency = 1
    layerLabel.Text = "Cloud Landing"
    layerLabel.TextColor3 = COLORS.dimWhite
    layerLabel.TextSize = 11
    layerLabel.Font = Enum.Font.Gotham
    layerLabel.TextXAlignment = Enum.TextXAlignment.Center
    layerLabel.Parent = frame

    -- "Phase 2" watermark (remove when implementing)
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "Placeholder"
    placeholder.Size = UDim2.new(1, -10, 0, 20)
    placeholder.Position = UDim2.new(0, 5, 0.5, -10)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = "MINIMAP"
    placeholder.TextColor3 = COLORS.dimWhite
    placeholder.TextSize = 14
    placeholder.TextTransparency = 0.6
    placeholder.Font = Enum.Font.GothamBold
    placeholder.Parent = mapBg

    return frame
end

---------------------------------------------------------------------------
-- Update: Refresh the minimap with current layer and player position
-- Phase 2: This will render zone geometry and moving player dot
---------------------------------------------------------------------------

function MiniMap.Update(frame: Frame, layerIndex: number, position: Vector3): ()
    -- Layer names (will come from ZoneConfig in full implementation)
    local LAYER_NAMES: { string } = {
        "Cloud Landing",
        "The Meadow",
        "Wind Temple",
        "Storm Peaks",
        "Kindness Cove",
        "Wisdom Library",
        "Guardian Sanctum",
        "Forgotten Falls",
    }

    local layerLabel = frame:FindFirstChild("LayerLabel") :: TextLabel?
    if layerLabel then
        local layerName: string = LAYER_NAMES[layerIndex] or ("Layer " .. layerIndex)
        layerLabel.Text = layerName
    end

    -- Phase 2: Map the world-space position to the minimap dot
    -- For now, the dot stays centered as a placeholder
    local mapBg = frame:FindFirstChild("MapBackground") :: Frame?
    if mapBg then
        local playerDot = mapBg:FindFirstChild("PlayerDot") :: Frame?
        if playerDot then
            -- Placeholder: keep dot centered
            -- Full implementation will normalize position against zone bounds
            playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
        end
    end
end

return MiniMap
