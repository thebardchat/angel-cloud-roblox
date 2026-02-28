--[[
    MainMenu.lua — Pause/Settings menu for Angel Cloud
    ESC or button toggle. Music volume, SFX volume, controls help, credits, links.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MainMenu = {}

local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
}

local isOpen: boolean = false
local mainFrame: Frame? = nil
local screenGuiRef: ScreenGui? = nil

-- Internal: slider for volume controls
local function createSlider(parent: Frame, label: string, yPos: number, default: number, zBase: number, onChange: (number) -> ()): Frame
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -40, 0, 50)
    row.Position = UDim2.new(0, 20, 0, yPos)
    row.BackgroundTransparency = 1
    row.ZIndex = zBase
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 140, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = COLORS.white
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = zBase + 1
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -160, 0, 6)
    track.Position = UDim2.new(0, 150, 0, 7)
    track.BackgroundColor3 = COLORS.bgLight
    track.BorderSizePixel = 0
    track.ZIndex = zBase + 1
    track.Parent = row

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 3)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(default, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.accent
    fill.BorderSizePixel = 0
    fill.ZIndex = zBase + 2
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Position = UDim2.new(1, 5, 0, -7)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(math.floor(default * 100)) .. "%"
    valueLabel.TextColor3 = COLORS.accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.ZIndex = zBase + 2
    valueLabel.Parent = track

    -- Click-to-set on track
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.Position = UDim2.new(0, 0, 0, -7)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = zBase + 3
    btn.Parent = track

    btn.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        local absPos = track.AbsolutePosition.X
        local absSize = track.AbsoluteSize.X
        local pct = math.clamp((mouse.X - absPos) / absSize, 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valueLabel.Text = tostring(math.floor(pct * 100)) .. "%"
        onChange(pct)
    end)

    return row
end

function MainMenu.Create(screenGui: ScreenGui): Frame
    screenGuiRef = screenGui

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainMenuPanel"
    mainFrame.Size = UDim2.new(0, 440, 0, 460)
    mainFrame.Position = UDim2.new(0.5, -220, 0.5, -230)
    mainFrame.BackgroundColor3 = COLORS.bg
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.ZIndex = 50
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 2
    stroke.Parent = mainFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 35)
    title.Position = UDim2.new(0, 20, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "SETTINGS"
    title.TextColor3 = COLORS.accent
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 51
    title.Parent = mainFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -48, 0, 10)
    closeBtn.BackgroundColor3 = COLORS.bgLight
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.dimWhite
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 52
    closeBtn.Parent = mainFrame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        MainMenu.Toggle()
    end)

    -- Section: Audio
    local audioHeader = Instance.new("TextLabel")
    audioHeader.Size = UDim2.new(1, -40, 0, 22)
    audioHeader.Position = UDim2.new(0, 20, 0, 58)
    audioHeader.BackgroundTransparency = 1
    audioHeader.Text = "AUDIO"
    audioHeader.TextColor3 = COLORS.gold
    audioHeader.TextSize = 13
    audioHeader.Font = Enum.Font.GothamBold
    audioHeader.TextXAlignment = Enum.TextXAlignment.Left
    audioHeader.ZIndex = 51
    audioHeader.Parent = mainFrame

    createSlider(mainFrame, "Music Volume", 82, 0.7, 51, function(val: number)
        -- TODO: Wire to SoundController music volume
    end)

    createSlider(mainFrame, "SFX Volume", 135, 1.0, 51, function(val: number)
        -- TODO: Wire to SoundController SFX volume
    end)

    -- Section: Controls
    local controlsHeader = Instance.new("TextLabel")
    controlsHeader.Size = UDim2.new(1, -40, 0, 22)
    controlsHeader.Position = UDim2.new(0, 20, 0, 200)
    controlsHeader.BackgroundTransparency = 1
    controlsHeader.Text = "CONTROLS"
    controlsHeader.TextColor3 = COLORS.gold
    controlsHeader.TextSize = 13
    controlsHeader.Font = Enum.Font.GothamBold
    controlsHeader.TextXAlignment = Enum.TextXAlignment.Left
    controlsHeader.ZIndex = 51
    controlsHeader.Parent = mainFrame

    local controlsList = {
        "F / Double-Tap Space — Fly",
        "WASD — Move",
        "Space (flying) — Ascend  |  Shift — Descend",
        "M — Angel Mail  |  C — Lore Codex",
        "ESC — This Menu",
    }

    for i, line in ipairs(controlsList) do
        local ctrlLabel = Instance.new("TextLabel")
        ctrlLabel.Size = UDim2.new(1, -40, 0, 18)
        ctrlLabel.Position = UDim2.new(0, 30, 0, 222 + (i - 1) * 20)
        ctrlLabel.BackgroundTransparency = 1
        ctrlLabel.Text = line
        ctrlLabel.TextColor3 = COLORS.dimWhite
        ctrlLabel.TextSize = 12
        ctrlLabel.Font = Enum.Font.Gotham
        ctrlLabel.TextXAlignment = Enum.TextXAlignment.Left
        ctrlLabel.ZIndex = 51
        ctrlLabel.Parent = mainFrame
    end

    -- Section: Credits
    local creditsHeader = Instance.new("TextLabel")
    creditsHeader.Size = UDim2.new(1, -40, 0, 22)
    creditsHeader.Position = UDim2.new(0, 20, 0, 345)
    creditsHeader.BackgroundTransparency = 1
    creditsHeader.Text = "CREDITS"
    creditsHeader.TextColor3 = COLORS.gold
    creditsHeader.TextSize = 13
    creditsHeader.Font = Enum.Font.GothamBold
    creditsHeader.TextXAlignment = Enum.TextXAlignment.Left
    creditsHeader.ZIndex = 51
    creditsHeader.Parent = mainFrame

    local creditsText = Instance.new("TextLabel")
    creditsText.Size = UDim2.new(1, -40, 0, 36)
    creditsText.Position = UDim2.new(0, 30, 0, 368)
    creditsText.BackgroundTransparency = 1
    creditsText.Text = "Angel Cloud ROBLOX — by thebardchat\nPart of the Angel Cloud mental wellness ecosystem"
    creditsText.TextColor3 = COLORS.dimWhite
    creditsText.TextSize = 12
    creditsText.Font = Enum.Font.Gotham
    creditsText.TextXAlignment = Enum.TextXAlignment.Left
    creditsText.TextWrapped = true
    creditsText.ZIndex = 51
    creditsText.Parent = mainFrame

    -- Bottom motto
    local motto = Instance.new("TextLabel")
    motto.Size = UDim2.new(1, -40, 0, 20)
    motto.Position = UDim2.new(0, 20, 1, -30)
    motto.BackgroundTransparency = 1
    motto.Text = "Every Angel strengthens the cloud."
    motto.TextColor3 = COLORS.gold
    motto.TextSize = 12
    motto.Font = Enum.Font.GothamMedium
    motto.ZIndex = 51
    motto.Parent = mainFrame

    return mainFrame
end

function MainMenu.Toggle(): ()
    isOpen = not isOpen
    if not mainFrame then return end

    if isOpen then
        mainFrame.Visible = true
        mainFrame.BackgroundTransparency = 1
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.05,
        }):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.25, function()
            if mainFrame then
                mainFrame.Visible = false
            end
        end)
    end
end

function MainMenu.IsOpen(): boolean
    return isOpen
end

return MainMenu
