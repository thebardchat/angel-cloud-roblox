--[[
    WingDisplay.lua — Wing tier name and icon display for HUD
    Shows current wing tier with level indicator
    Visual identity: #0a0a0f background, #00d4ff accent
]]

local TweenService = game:GetService("TweenService")

local WingDisplay = {}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local COLORS = {
    bg      = Color3.fromRGB(10, 10, 15),
    accent  = Color3.fromRGB(0, 212, 255),
    gold    = Color3.fromRGB(255, 215, 0),
    white   = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
}

-- Wing tier display colors (progressively more radiant)
local TIER_COLORS: { [string]: Color3 } = {
    ["Starter"]         = Color3.fromRGB(180, 180, 200),
    ["Courage"]         = Color3.fromRGB(0, 212, 255),
    ["Kindness"]        = Color3.fromRGB(100, 255, 150),
    ["Resilience"]      = Color3.fromRGB(255, 215, 0),
    ["Wisdom"]          = Color3.fromRGB(120, 50, 180),
    ["Guardian Angel"]  = Color3.fromRGB(255, 255, 255),
}

-- Wing tier icon glyphs (text stand-ins; replace with ImageLabels for final assets)
local TIER_ICONS: { [string]: string } = {
    ["Starter"]         = "~",
    ["Courage"]         = "^",
    ["Kindness"]        = "*",
    ["Resilience"]      = "#",
    ["Wisdom"]          = "&",
    ["Guardian Angel"]  = "W",
}

---------------------------------------------------------------------------
-- Create: Build the wing display frame inside the given parent
---------------------------------------------------------------------------

function WingDisplay.Create(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Name = "WingDisplay"
    frame.Size = UDim2.new(0, 170, 0, 36)
    frame.BackgroundColor3 = COLORS.bg
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "TierStroke"
    stroke.Color = COLORS.dimWhite
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- Wing icon (text glyph)
    local icon = Instance.new("TextLabel")
    icon.Name = "WingIcon"
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 6, 0.5, -14)
    icon.BackgroundTransparency = 1
    icon.Text = TIER_ICONS["Starter"]
    icon.TextColor3 = COLORS.dimWhite
    icon.TextSize = 20
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame

    -- Tier name label
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "TierName"
    tierLabel.Size = UDim2.new(1, -42, 0, 18)
    tierLabel.Position = UDim2.new(0, 36, 0, 3)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Text = "Starter"
    tierLabel.TextColor3 = COLORS.dimWhite
    tierLabel.TextSize = 14
    tierLabel.Font = Enum.Font.GothamBold
    tierLabel.TextXAlignment = Enum.TextXAlignment.Left
    tierLabel.TextTruncate = Enum.TextTruncate.AtEnd
    tierLabel.Parent = frame

    -- Level sub-label
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, -42, 0, 14)
    levelLabel.Position = UDim2.new(0, 36, 0, 20)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv. 1"
    levelLabel.TextColor3 = COLORS.dimWhite
    levelLabel.TextSize = 11
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = frame

    return frame
end

---------------------------------------------------------------------------
-- Update: Set the wing tier name, icon, and level
---------------------------------------------------------------------------

function WingDisplay.Update(frame: Frame, tierName: string, level: number): ()
    local tierLabel = frame:FindFirstChild("TierName") :: TextLabel?
    local levelLabel = frame:FindFirstChild("LevelLabel") :: TextLabel?
    local wingIcon = frame:FindFirstChild("WingIcon") :: TextLabel?
    local tierStroke = frame:FindFirstChild("TierStroke") :: UIStroke?

    local tierColor: Color3 = TIER_COLORS[tierName] or COLORS.dimWhite
    local iconGlyph: string = TIER_ICONS[tierName] or "~"

    if tierLabel then
        local previous: string = tierLabel.Text
        tierLabel.Text = tierName
        -- Animate color transition on tier change
        if previous ~= tierName then
            tierLabel.TextColor3 = COLORS.white
            TweenService:Create(tierLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextColor3 = tierColor,
            }):Play()
        else
            tierLabel.TextColor3 = tierColor
        end
    end

    if levelLabel then
        levelLabel.Text = "Lv. " .. math.floor(level)
    end

    if wingIcon then
        wingIcon.Text = iconGlyph
        wingIcon.TextColor3 = tierColor
    end

    if tierStroke then
        tierStroke.Color = tierColor
    end
end

return WingDisplay
