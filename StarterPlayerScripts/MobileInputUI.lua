--[[
    MobileInputUI.lua — Touch controls for mobile players
    Creates on-screen buttons for flight, glide, action, and mail
    Only shows on touch-enabled devices
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MobileInputUI = {}

-- Callbacks set by ClientController
MobileInputUI.OnFlightToggle = nil :: (() -> ())?
MobileInputUI.OnGlideStart = nil :: (() -> ())?
MobileInputUI.OnGlideEnd = nil :: (() -> ())?
MobileInputUI.OnAction = nil :: (() -> ())?
MobileInputUI.OnDescendStart = nil :: (() -> ())?
MobileInputUI.OnDescendEnd = nil :: (() -> ())?

function MobileInputUI.Init()
    -- Only create touch UI on mobile/tablet
    if not UserInputService.TouchEnabled then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileControls"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Right side action buttons
    local buttonSize = UDim2.new(0, 65, 0, 65)
    local buttonColor = Color3.fromRGB(0, 180, 255)
    local buttonTransparency = 0.3

    -- FLIGHT TOGGLE (large button, bottom right area)
    local flightBtn = MobileInputUI.CreateButton(gui, {
        name = "FlightBtn",
        text = "FLY",
        size = UDim2.new(0, 75, 0, 75),
        position = UDim2.new(1, -95, 1, -200),
        color = Color3.fromRGB(0, 200, 255),
        transparency = buttonTransparency,
    })
    flightBtn.Activated:Connect(function()
        if MobileInputUI.OnFlightToggle then
            MobileInputUI.OnFlightToggle()
        end
    end)

    -- GLIDE (hold to glide — below flight button)
    local glideBtn = MobileInputUI.CreateButton(gui, {
        name = "GlideBtn",
        text = "GLIDE",
        size = buttonSize,
        position = UDim2.new(1, -85, 1, -110),
        color = Color3.fromRGB(100, 220, 255),
        transparency = buttonTransparency,
    })
    glideBtn.MouseButton1Down:Connect(function()
        if MobileInputUI.OnGlideStart then
            MobileInputUI.OnGlideStart()
        end
    end)
    glideBtn.MouseButton1Up:Connect(function()
        if MobileInputUI.OnGlideEnd then
            MobileInputUI.OnGlideEnd()
        end
    end)

    -- ACTION BUTTON (E key equivalent — interact with NPCs etc)
    local actionBtn = MobileInputUI.CreateButton(gui, {
        name = "ActionBtn",
        text = "E",
        size = UDim2.new(0, 55, 0, 55),
        position = UDim2.new(1, -170, 1, -160),
        color = Color3.fromRGB(255, 200, 50),
        transparency = buttonTransparency,
    })
    actionBtn.Activated:Connect(function()
        if MobileInputUI.OnAction then
            MobileInputUI.OnAction()
        end
    end)

    -- DESCEND (hold to go down while flying)
    local descendBtn = MobileInputUI.CreateButton(gui, {
        name = "DescendBtn",
        text = "DOWN",
        size = UDim2.new(0, 55, 0, 55),
        position = UDim2.new(1, -170, 1, -95),
        color = Color3.fromRGB(180, 100, 255),
        transparency = buttonTransparency,
    })
    descendBtn.MouseButton1Down:Connect(function()
        if MobileInputUI.OnDescendStart then
            MobileInputUI.OnDescendStart()
        end
    end)
    descendBtn.MouseButton1Up:Connect(function()
        if MobileInputUI.OnDescendEnd then
            MobileInputUI.OnDescendEnd()
        end
    end)

    print("[MobileInputUI] Touch controls created for mobile device")
end

function MobileInputUI.CreateButton(parent: ScreenGui, config: any): TextButton
    local btn = Instance.new("TextButton")
    btn.Name = config.name
    btn.Size = config.size
    btn.Position = config.position
    btn.AnchorPoint = Vector2.new(0, 0)
    btn.BackgroundColor3 = config.color
    btn.BackgroundTransparency = config.transparency
    btn.Text = config.text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 2
    stroke.Parent = btn

    return btn
end

return MobileInputUI
