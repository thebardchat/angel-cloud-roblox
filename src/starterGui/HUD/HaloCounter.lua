--[[
    HaloCounter.lua — Halo currency display module for HUD
    Creates and updates a compact Halo count frame
    Visual identity: #0a0a0f background, #ffd700 gold accent
]]

local TweenService = game:GetService("TweenService")

local HaloCounter = {}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local COLORS = {
    bg      = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    gold    = Color3.fromRGB(255, 215, 0),
    white   = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
}

---------------------------------------------------------------------------
-- Create: Build the Halo counter frame inside the given parent
---------------------------------------------------------------------------

function HaloCounter.Create(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Name = "HaloCounter"
    frame.Size = UDim2.new(0, 140, 0, 36)
    frame.BackgroundColor3 = COLORS.bg
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.gold
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- Halo icon (text stand-in; replace with ImageLabel when asset is ready)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 6, 0.5, -14)
    icon.BackgroundTransparency = 1
    icon.Text = "O"
    icon.TextColor3 = COLORS.gold
    icon.TextSize = 20
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame

    -- Amount label
    local amountLabel = Instance.new("TextLabel")
    amountLabel.Name = "Amount"
    amountLabel.Size = UDim2.new(1, -42, 1, 0)
    amountLabel.Position = UDim2.new(0, 36, 0, 0)
    amountLabel.BackgroundTransparency = 1
    amountLabel.Text = "0"
    amountLabel.TextColor3 = COLORS.gold
    amountLabel.TextSize = 18
    amountLabel.Font = Enum.Font.GothamBold
    amountLabel.TextXAlignment = Enum.TextXAlignment.Left
    amountLabel.Parent = frame

    return frame
end

---------------------------------------------------------------------------
-- Update: Set the displayed Halo amount with a brief flash
---------------------------------------------------------------------------

function HaloCounter.Update(frame: Frame, amount: number): ()
    local amountLabel = frame:FindFirstChild("Amount") :: TextLabel?
    if not amountLabel then
        return
    end

    local previous: string = amountLabel.Text
    amountLabel.Text = tostring(math.floor(amount))

    -- Flash white briefly when value changes to draw attention
    if amountLabel.Text ~= previous then
        amountLabel.TextColor3 = COLORS.white
        TweenService:Create(amountLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextColor3 = COLORS.gold,
        }):Play()
    end
end

return HaloCounter
