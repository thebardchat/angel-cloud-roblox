--[[
    UIController.lua — Unified UI controller for Angel Cloud ROBLOX
    Migrated from UIManager.lua, StaminaUI.lua, and BlessingEffects.lua
    Manages ScreenGui, HUD, notifications, stamina bar, blessing VFX
    Visual identity: #0a0a0f background, #00d4ff accent (Angel Cloud branding)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local UIController = Knit.CreateController({
    Name = "UIController",
})

---------------------------------------------------------------------------
-- Types
---------------------------------------------------------------------------

type NotificationData = {
    text: string,
    color: Color3?,
    duration: number?,
}

type ProgressData = {
    level: string?,
    motes: number?,
    progress: number?,
    nextThreshold: number?,
    fragmentCount: number?,
}

type StaminaData = {
    current: number,
    max: number,
    action: string?,
}

type BlessingData = {
    message: string?,
    chainLength: number?,
}

type MoteData = {
    amount: number?,
    position: Vector3?,
}

type HALTData = {
    message: string,
}

type ServerMessageData = {
    type: string?,
    message: string?,
}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local COLORS = {
    bg          = Color3.fromRGB(10, 10, 15),       -- #0a0a0f
    bgLight     = Color3.fromRGB(20, 20, 30),
    accent      = Color3.fromRGB(0, 212, 255),      -- #00d4ff
    gold        = Color3.fromRGB(255, 215, 0),
    white       = Color3.fromRGB(255, 255, 255),
    dimWhite    = Color3.fromRGB(180, 180, 200),
    green       = Color3.fromRGB(100, 255, 150),
    red         = Color3.fromRGB(255, 100, 100),
    purple      = Color3.fromRGB(120, 50, 180),
}

local STAMINA_COLORS = {
    full = Color3.fromRGB(0, 212, 255),     -- cyan
    mid  = Color3.fromRGB(255, 215, 0),     -- gold
    low  = Color3.fromRGB(255, 100, 100),   -- red
}

local BLESSING_COLORS = {
    beam      = Color3.fromRGB(0, 212, 255),
    gold      = Color3.fromRGB(255, 215, 0),
    chainGreen = Color3.fromRGB(100, 255, 150),
}

local MAX_NOTIFICATIONS = 5

---------------------------------------------------------------------------
-- Private State
---------------------------------------------------------------------------

local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui")

local screenGui: ScreenGui
local notificationFrame: Frame
local progressFrame: Frame

-- Stamina bar references
local staminaBarFrame: Frame
local staminaBarFill: Frame
local staminaLabel: TextLabel
local currentPulseTween: Tween? = nil

---------------------------------------------------------------------------
-- Private: Color Palette Accessor
---------------------------------------------------------------------------

function UIController:GetColors(): { [string]: Color3 }
    return COLORS
end

function UIController:GetScreenGui(): ScreenGui
    return screenGui
end

---------------------------------------------------------------------------
-- Private: HUD Creation
---------------------------------------------------------------------------

function UIController:_createHUD(): ()
    progressFrame = Instance.new("Frame")
    progressFrame.Name = "HUD"
    progressFrame.Size = UDim2.new(0, 280, 0, 100)
    progressFrame.Position = UDim2.new(0, 15, 0, 15)
    progressFrame.BackgroundColor3 = COLORS.bg
    progressFrame.BackgroundTransparency = 0.3
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = progressFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = progressFrame

    -- Angel Level label
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelLabel"
    levelLabel.Size = UDim2.new(1, -20, 0, 25)
    levelLabel.Position = UDim2.new(0, 10, 0, 8)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Newborn"
    levelLabel.TextColor3 = COLORS.accent
    levelLabel.TextSize = 18
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.TextXAlignment = Enum.TextXAlignment.Left
    levelLabel.Parent = progressFrame

    -- Mote count
    local moteLabel = Instance.new("TextLabel")
    moteLabel.Name = "MoteLabel"
    moteLabel.Size = UDim2.new(1, -20, 0, 20)
    moteLabel.Position = UDim2.new(0, 10, 0, 35)
    moteLabel.BackgroundTransparency = 1
    moteLabel.Text = "0 Light Motes"
    moteLabel.TextColor3 = COLORS.dimWhite
    moteLabel.TextSize = 14
    moteLabel.Font = Enum.Font.Gotham
    moteLabel.TextXAlignment = Enum.TextXAlignment.Left
    moteLabel.Parent = progressFrame

    -- Progress bar background
    local barBg = Instance.new("Frame")
    barBg.Name = "ProgressBarBg"
    barBg.Size = UDim2.new(1, -20, 0, 8)
    barBg.Position = UDim2.new(0, 10, 0, 60)
    barBg.BackgroundColor3 = COLORS.bgLight
    barBg.BorderSizePixel = 0
    barBg.Parent = progressFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = barBg

    local barFill = Instance.new("Frame")
    barFill.Name = "ProgressBarFill"
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = COLORS.accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = barFill

    -- Next threshold label
    local thresholdLabel = Instance.new("TextLabel")
    thresholdLabel.Name = "ThresholdLabel"
    thresholdLabel.Size = UDim2.new(1, -20, 0, 16)
    thresholdLabel.Position = UDim2.new(0, 10, 0, 74)
    thresholdLabel.BackgroundTransparency = 1
    thresholdLabel.Text = "Next: 10 Motes"
    thresholdLabel.TextColor3 = COLORS.dimWhite
    thresholdLabel.TextSize = 11
    thresholdLabel.Font = Enum.Font.Gotham
    thresholdLabel.TextXAlignment = Enum.TextXAlignment.Left
    thresholdLabel.Parent = progressFrame

    -- Fragment count (right side)
    local fragLabel = Instance.new("TextLabel")
    fragLabel.Name = "FragmentLabel"
    fragLabel.Size = UDim2.new(0, 80, 0, 16)
    fragLabel.Position = UDim2.new(1, -90, 0, 74)
    fragLabel.BackgroundTransparency = 1
    fragLabel.Text = "0/65 Lore"
    fragLabel.TextColor3 = COLORS.gold
    fragLabel.TextSize = 11
    fragLabel.Font = Enum.Font.Gotham
    fragLabel.TextXAlignment = Enum.TextXAlignment.Right
    fragLabel.Parent = progressFrame
end

---------------------------------------------------------------------------
-- Private: Notification Area
---------------------------------------------------------------------------

function UIController:_createNotificationArea(): ()
    notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notifications"
    notificationFrame.Size = UDim2.new(0, 350, 1, -30)
    notificationFrame.Position = UDim2.new(1, -365, 0, 15)
    notificationFrame.BackgroundTransparency = 1
    notificationFrame.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Parent = notificationFrame
end

---------------------------------------------------------------------------
-- Private: Stamina Bar (from StaminaUI)
---------------------------------------------------------------------------

function UIController:_createStaminaBar(): ()
    -- Stamina bar container (below HUD)
    staminaBarFrame = Instance.new("Frame")
    staminaBarFrame.Name = "StaminaBar"
    staminaBarFrame.Size = UDim2.new(0, 200, 0, 12)
    staminaBarFrame.Position = UDim2.new(0, 15, 0, 125)
    staminaBarFrame.BackgroundColor3 = COLORS.bgLight
    staminaBarFrame.BackgroundTransparency = 0.3
    staminaBarFrame.BorderSizePixel = 0
    staminaBarFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = staminaBarFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = STAMINA_COLORS.full
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Name = "StaminaStroke"
    stroke.Parent = staminaBarFrame

    -- Fill bar
    staminaBarFill = Instance.new("Frame")
    staminaBarFill.Name = "Fill"
    staminaBarFill.Size = UDim2.new(1, 0, 1, 0)
    staminaBarFill.BackgroundColor3 = STAMINA_COLORS.full
    staminaBarFill.BackgroundTransparency = 0.2
    staminaBarFill.BorderSizePixel = 0
    staminaBarFill.Parent = staminaBarFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = staminaBarFill

    -- Label
    staminaLabel = Instance.new("TextLabel")
    staminaLabel.Name = "StaminaLabel"
    staminaLabel.Size = UDim2.new(0, 200, 0, 14)
    staminaLabel.Position = UDim2.new(0, 15, 0, 140)
    staminaLabel.BackgroundTransparency = 1
    staminaLabel.Text = "Wing Gauge: 100/100"
    staminaLabel.TextColor3 = COLORS.dimWhite
    staminaLabel.TextSize = 11
    staminaLabel.Font = Enum.Font.Gotham
    staminaLabel.TextXAlignment = Enum.TextXAlignment.Left
    staminaLabel.Parent = screenGui
end

---------------------------------------------------------------------------
-- Public: Show Notification (slide-in, max 5 stacked)
---------------------------------------------------------------------------

function UIController:ShowNotification(text: string, color: Color3?, duration: number?): ()
    color = color or COLORS.white
    duration = duration or 3

    -- Enforce max notification stack — remove oldest if at limit
    if notificationFrame then
        local children: { Frame } = {}
        for _, child in ipairs(notificationFrame:GetChildren()) do
            if child:IsA("Frame") then
                table.insert(children, child)
            end
        end
        while #children >= MAX_NOTIFICATIONS do
            children[1]:Destroy()
            table.remove(children, 1)
        end
    end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 35)
    notif.BackgroundColor3 = COLORS.bg
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = notif

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = notif

    notif.Parent = notificationFrame

    -- Slide in from right
    notif.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    -- Fade out and remove after duration
    task.delay(duration, function()
        local fadeOut = TweenService:Create(notif, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        })
        TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            notif:Destroy()
        end)
    end)
end

---------------------------------------------------------------------------
-- Public: Show Server Message (welcome / info / starfish)
---------------------------------------------------------------------------

function UIController:ShowMessage(data: ServerMessageData): ()
    if data.type == "welcome" then
        self:ShowNotification(data.message or "", COLORS.accent, 6)
        self:ShowTutorial()
    elseif data.type == "info" then
        self:ShowNotification(data.message or "", COLORS.accent, 4)
    elseif data.type == "starfish" then
        self:ShowNotification(data.message or "", COLORS.gold, 4)
    else
        self:ShowNotification(data.message or "", COLORS.white, 3)
    end
end

---------------------------------------------------------------------------
-- Public: Tutorial Overlay
---------------------------------------------------------------------------

function UIController:ShowTutorial(): ()
    local tutorialFrame = Instance.new("Frame")
    tutorialFrame.Name = "TutorialOverlay"
    tutorialFrame.Size = UDim2.new(1, 0, 1, 0)
    tutorialFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tutorialFrame.BackgroundTransparency = 0.5
    tutorialFrame.BorderSizePixel = 0
    tutorialFrame.ZIndex = 10
    tutorialFrame.Parent = screenGui

    -- Center card
    local card = Instance.new("Frame")
    card.Name = "TutorialCard"
    card.Size = UDim2.new(0, 500, 0, 320)
    card.Position = UDim2.new(0.5, -250, 0.5, -160)
    card.BackgroundColor3 = COLORS.bg
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.ZIndex = 11
    card.Parent = tutorialFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 14)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = COLORS.accent
    cardStroke.Thickness = 2
    cardStroke.Parent = card

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 40)
    title.Position = UDim2.new(0, 15, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "THE CLOUD CLIMB"
    title.TextColor3 = COLORS.accent
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 12
    title.Parent = card

    -- Instructions
    local instructions: { { icon: string, text: string } } = {
        { icon = "F",   text = "Press F to FLY! (or double-tap Space)" },
        { icon = "^^",  text = "While flying: WASD move, SPACE = up, SHIFT = down" },
        { icon = ">>",  text = "COLLECT glowing Light Motes to level up" },
        { icon = "!!",  text = "Visit the WING FORGE to upgrade your wings" },
        { icon = "ZZ",  text = "Hit GREEN PADS for speed, CYAN for updrafts" },
        { icon = "10",  text = "Get 10 Motes to unlock THE MEADOW (Layer 2)" },
    }

    for i, instr in ipairs(instructions) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -40, 0, 30)
        row.Position = UDim2.new(0, 20, 0, 55 + (i - 1) * 35)
        row.BackgroundTransparency = 1
        row.ZIndex = 12
        row.Parent = card

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = instr.icon
        icon.TextColor3 = COLORS.accent
        icon.TextSize = 16
        icon.Font = Enum.Font.Code
        icon.ZIndex = 12
        icon.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Position = UDim2.new(0, 35, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = instr.text
        label.TextColor3 = COLORS.white
        label.TextSize = 16
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 12
        label.Parent = row
    end

    -- Motto at bottom
    local motto = Instance.new("TextLabel")
    motto.Size = UDim2.new(1, -30, 0, 20)
    motto.Position = UDim2.new(0, 15, 1, -55)
    motto.BackgroundTransparency = 1
    motto.Text = "Every Angel strengthens the cloud."
    motto.TextColor3 = COLORS.gold
    motto.TextSize = 14
    motto.Font = Enum.Font.GothamMedium
    motto.ZIndex = 12
    motto.Parent = card

    -- Dismiss button
    local dismissBtn = Instance.new("TextButton")
    dismissBtn.Size = UDim2.new(0, 160, 0, 36)
    dismissBtn.Position = UDim2.new(0.5, -80, 1, -45)
    dismissBtn.BackgroundColor3 = COLORS.accent
    dismissBtn.BorderSizePixel = 0
    dismissBtn.Text = "BEGIN CLIMBING"
    dismissBtn.TextColor3 = COLORS.bg
    dismissBtn.TextSize = 16
    dismissBtn.Font = Enum.Font.GothamBold
    dismissBtn.ZIndex = 12
    dismissBtn.Parent = card

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = dismissBtn

    -- Dismiss handler
    local function dismiss(): ()
        if tutorialFrame and tutorialFrame.Parent then
            TweenService:Create(tutorialFrame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(card, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
            }):Play()
            for _, desc in ipairs(card:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    TweenService:Create(desc, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
                end
                if desc:IsA("UIStroke") then
                    TweenService:Create(desc, TweenInfo.new(0.5), { Transparency = 1 }):Play()
                end
            end
            task.delay(0.6, function()
                if tutorialFrame and tutorialFrame.Parent then
                    tutorialFrame:Destroy()
                end
            end)
        end
    end

    dismissBtn.MouseButton1Click:Connect(dismiss)
    -- Auto-dismiss after 15 seconds
    task.delay(15, dismiss)
end

---------------------------------------------------------------------------
-- Public: HALT Notification (persistent, auto-dismiss 15s)
---------------------------------------------------------------------------

function UIController:ShowHALTNotification(data: HALTData): ()
    local haltFrame = Instance.new("Frame")
    haltFrame.Name = "HALTNotification"
    haltFrame.Size = UDim2.new(0, 400, 0, 80)
    haltFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
    haltFrame.BackgroundColor3 = COLORS.bg
    haltFrame.BackgroundTransparency = 0.1
    haltFrame.BorderSizePixel = 0
    haltFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = haltFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.gold
    stroke.Thickness = 2
    stroke.Parent = haltFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -10)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = data.message
    label.TextColor3 = COLORS.gold
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextWrapped = true
    label.Parent = haltFrame

    -- Auto-dismiss after 15 seconds
    task.delay(15, function()
        if haltFrame and haltFrame.Parent then
            haltFrame:Destroy()
        end
    end)
end

---------------------------------------------------------------------------
-- Public: Progress Update Handler
---------------------------------------------------------------------------

function UIController:OnProgressUpdate(data: ProgressData): ()
    if not progressFrame then
        return
    end

    local levelLabel = progressFrame:FindFirstChild("LevelLabel") :: TextLabel?
    if levelLabel then
        levelLabel.Text = data.level or "Newborn"
    end

    local moteLabel = progressFrame:FindFirstChild("MoteLabel") :: TextLabel?
    if moteLabel then
        moteLabel.Text = (data.motes or 0) .. " Light Motes"
    end

    local barBg = progressFrame:FindFirstChild("ProgressBarBg") :: Frame?
    if barBg then
        local barFill = barBg:FindFirstChild("ProgressBarFill") :: Frame?
        if barFill then
            local progress: number = (data.progress or 0) / 100
            TweenService:Create(barFill, TweenInfo.new(0.5), {
                Size = UDim2.new(progress, 0, 1, 0),
            }):Play()
        end
    end

    local thresholdLabel = progressFrame:FindFirstChild("ThresholdLabel") :: TextLabel?
    if thresholdLabel then
        if data.nextThreshold then
            thresholdLabel.Text = "Next: " .. data.nextThreshold .. " Motes"
        else
            thresholdLabel.Text = "Maximum Angel Level"
        end
    end

    local fragLabel = progressFrame:FindFirstChild("FragmentLabel") :: TextLabel?
    if fragLabel and data.fragmentCount then
        fragLabel.Text = data.fragmentCount .. "/65 Lore"
    end
end

---------------------------------------------------------------------------
-- Public: Floating Mote Text Animation
---------------------------------------------------------------------------

function UIController:ShowFloatingMoteText(text: string): ()
    if not screenGui then
        return
    end

    local moteLabel = progressFrame and progressFrame:FindFirstChild("MoteLabel") :: TextLabel?
    local startPos: Vector2 = if moteLabel then moteLabel.AbsolutePosition else Vector2.new(80, 50)

    local floater = Instance.new("TextLabel")
    floater.Name = "MoteFloat"
    floater.Size = UDim2.new(0, 100, 0, 30)
    floater.Position = UDim2.new(0, startPos.X + 10, 0, startPos.Y)
    floater.BackgroundTransparency = 1
    floater.Text = text
    floater.TextColor3 = COLORS.accent
    floater.TextSize = 22
    floater.Font = Enum.Font.GothamBold
    floater.TextStrokeTransparency = 0.5
    floater.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    floater.ZIndex = 20
    floater.Parent = screenGui

    -- Float upward and fade
    TweenService:Create(floater, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, startPos.X + 10, 0, startPos.Y - 60),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    }):Play()

    task.delay(1.3, function()
        if floater and floater.Parent then
            floater:Destroy()
        end
    end)
end

---------------------------------------------------------------------------
-- Public: Stamina Bar Update (from StaminaUI)
---------------------------------------------------------------------------

function UIController:UpdateStaminaBar(current: number, max: number, action: string?): ()
    if not staminaBarFill or not staminaBarFrame then
        return
    end

    local ratio: number = math.clamp(current / math.max(max, 1), 0, 1)

    -- Color based on ratio: cyan > 60%, gold > 25%, red <= 25%
    local color: Color3
    if ratio > 0.6 then
        color = STAMINA_COLORS.full
    elseif ratio > 0.25 then
        color = STAMINA_COLORS.mid
    else
        color = STAMINA_COLORS.low
    end

    -- Animate fill size and color
    TweenService:Create(staminaBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = color,
    }):Play()

    -- Update stroke color
    local stroke = staminaBarFrame:FindFirstChild("StaminaStroke") :: UIStroke?
    if stroke then
        stroke.Color = color
    end

    -- Update label with action text
    if staminaLabel then
        local actionText: string = ""
        if action == "glide" then
            actionText = " (Gliding)"
        elseif action == "flight" then
            actionText = " (Flying)"
        elseif action == "shield" then
            actionText = " (Shielding)"
        elseif action == "meditation_complete" then
            actionText = " (Restored!)"
        elseif action == "blessing_received" then
            actionText = " (Blessed!)"
        end
        staminaLabel.Text = "Wing Gauge: " .. math.floor(current) .. "/" .. math.floor(max) .. actionText
    end

    -- Pulse effect when critically low (<=15%), stop when recovered
    if ratio <= 0.15 and ratio > 0 then
        if not currentPulseTween then
            currentPulseTween = TweenService:Create(
                staminaBarFill,
                TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = 0.6 }
            )
            currentPulseTween:Play()
        end
    else
        if currentPulseTween then
            currentPulseTween:Cancel()
            currentPulseTween = nil
            staminaBarFill.BackgroundTransparency = 0.2
        end
    end
end

---------------------------------------------------------------------------
-- Public: Blessing Receive Effect (beam + ring + particles)
---------------------------------------------------------------------------

function UIController:PlayBlessingReceiveEffect(): ()
    local character: Model? = player.Character
    if not character then
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        return
    end

    -- Cyan light beam from above
    local beam = Instance.new("Part")
    beam.Name = "BlessingBeam"
    beam.Size = Vector3.new(3, 200, 3)
    beam.Position = humanoidRootPart.Position + Vector3.new(0, 100, 0)
    beam.Anchored = true
    beam.CanCollide = false
    beam.Material = Enum.Material.Neon
    beam.Color = BLESSING_COLORS.beam
    beam.Transparency = 0.3
    beam.Shape = Enum.PartType.Cylinder
    beam.Orientation = Vector3.new(0, 0, 90)
    beam.Parent = workspace

    -- Expanding ring at player's feet
    local ring = Instance.new("Part")
    ring.Name = "BlessingRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.5, 4, 4)
    ring.Position = humanoidRootPart.Position - Vector3.new(0, 3, 0)
    ring.Anchored = true
    ring.CanCollide = false
    ring.Material = Enum.Material.Neon
    ring.Color = BLESSING_COLORS.gold
    ring.Transparency = 0.3
    ring.Orientation = Vector3.new(0, 0, 90)
    ring.Parent = workspace

    -- Animate: beam fades, ring expands
    TweenService:Create(beam, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(1, 200, 1),
    }):Play()

    TweenService:Create(ring, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.5, 30, 30),
        Transparency = 1,
    }):Play()

    -- Particle burst
    self:_createParticleBurst(humanoidRootPart.Position, BLESSING_COLORS.beam, 20)

    -- Cleanup
    task.delay(2.5, function()
        beam:Destroy()
        ring:Destroy()
    end)
end

---------------------------------------------------------------------------
-- Public: Chain Effect (staggered rings)
---------------------------------------------------------------------------

function UIController:PlayChainEffect(chainLength: number): ()
    local character: Model? = player.Character
    if not character then
        return
    end

    local humanoidRootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoidRootPart then
        return
    end

    -- Multiple expanding rings (one per chain length, up to 5)
    local ringCount: number = math.min(chainLength, 5)
    for i = 1, ringCount do
        task.delay(i * 0.2, function()
            local ring = Instance.new("Part")
            ring.Name = "ChainRing_" .. i
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.3, 2, 2)
            ring.Position = humanoidRootPart.Position + Vector3.new(0, i * 2, 0)
            ring.Anchored = true
            ring.CanCollide = false
            ring.Material = Enum.Material.Neon
            ring.Color = BLESSING_COLORS.chainGreen
            ring.Transparency = 0.2
            ring.Orientation = Vector3.new(0, 0, 90)
            ring.Parent = workspace

            TweenService:Create(ring, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.3, 20 + i * 5, 20 + i * 5),
                Transparency = 1,
                Position = ring.Position + Vector3.new(0, 5, 0),
            }):Play()

            task.delay(1.5, function()
                ring:Destroy()
            end)
        end)
    end

    self:_createParticleBurst(humanoidRootPart.Position, BLESSING_COLORS.chainGreen, 15)
end

---------------------------------------------------------------------------
-- Public: Mote Pickup Flash Effect
---------------------------------------------------------------------------

function UIController:PlayMotePickupEffect(position: Vector3): ()
    -- Emitter part at pickup location
    local emitterPart = Instance.new("Part")
    emitterPart.Name = "MotePickupBurst"
    emitterPart.Size = Vector3.new(1, 1, 1)
    emitterPart.Position = position
    emitterPart.Anchored = true
    emitterPart.CanCollide = false
    emitterPart.Transparency = 1
    emitterPart.Parent = workspace

    -- Flash sphere
    local flash = Instance.new("Part")
    flash.Shape = Enum.PartType.Ball
    flash.Size = Vector3.new(3, 3, 3)
    flash.Position = position
    flash.Anchored = true
    flash.CanCollide = false
    flash.Material = Enum.Material.Neon
    flash.Color = BLESSING_COLORS.beam
    flash.Transparency = 0
    flash.Parent = workspace

    -- Flash expands and fades
    TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(8, 8, 8),
        Transparency = 1,
    }):Play()

    -- Particle burst upward
    local burst = Instance.new("ParticleEmitter")
    burst.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, BLESSING_COLORS.beam),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    burst.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    burst.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    burst.Lifetime = NumberRange.new(0.3, 0.8)
    burst.Speed = NumberRange.new(8, 15)
    burst.SpreadAngle = Vector2.new(360, 360)
    burst.LightEmission = 1
    burst.Parent = emitterPart

    -- Emit a burst then disable
    burst:Emit(20)
    burst.Enabled = false

    task.delay(1.2, function()
        emitterPart:Destroy()
        flash:Destroy()
    end)
end

---------------------------------------------------------------------------
-- Private: Particle Burst Helper (from BlessingEffects)
---------------------------------------------------------------------------

function UIController:_createParticleBurst(position: Vector3, color: Color3, count: number): ()
    for _ = 1, count do
        local particle = Instance.new("Part")
        particle.Shape = Enum.PartType.Ball
        particle.Size = Vector3.new(0.3, 0.3, 0.3)
        particle.Position = position
        particle.Anchored = true
        particle.CanCollide = false
        particle.Material = Enum.Material.Neon
        particle.Color = color
        particle.Transparency = 0
        particle.Parent = workspace

        local direction: Vector3 = Vector3.new(
            math.random() * 2 - 1,
            math.random() * 2,
            math.random() * 2 - 1
        ).Unit * (5 + math.random() * 10)

        TweenService:Create(particle, TweenInfo.new(0.6 + math.random() * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = position + direction,
            Size = Vector3.new(0.05, 0.05, 0.05),
            Transparency = 1,
        }):Play()

        task.delay(1.2, function()
            particle:Destroy()
        end)
    end
end

---------------------------------------------------------------------------
-- Knit Lifecycle: KnitInit
---------------------------------------------------------------------------

function UIController:KnitInit(): ()
    -- Create main ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AngelCloudUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- Build all UI components
    self:_createHUD()
    self:_createNotificationArea()
    self:_createStaminaBar()
end

---------------------------------------------------------------------------
-- Knit Lifecycle: KnitStart (wire up RemoteEvents)
---------------------------------------------------------------------------

function UIController:KnitStart(): ()
    -- PlayerProgress updates (level, motes, bar, fragments)
    local PlayerProgress = ReplicatedStorage:WaitForChild("PlayerProgress")
    PlayerProgress.OnClientEvent:Connect(function(data: ProgressData)
        self:OnProgressUpdate(data)
    end)

    -- Server messages (welcome, info, starfish)
    local ServerMessage = ReplicatedStorage:WaitForChild("ServerMessage", 10)
    if ServerMessage then
        ServerMessage.OnClientEvent:Connect(function(data: ServerMessageData)
            self:ShowMessage(data)
        end)
    end

    -- Mote collection — floating text
    local MoteAwarded = ReplicatedStorage:WaitForChild("MoteAwarded")
    MoteAwarded.OnClientEvent:Connect(function(data: MoteData)
        if data.amount and data.amount > 0 then
            self:ShowFloatingMoteText("+" .. data.amount)
        end
    end)

    -- Mote pickup — flash effect at position
    local MoteCollected = ReplicatedStorage:WaitForChild("MoteCollected")
    MoteCollected.OnClientEvent:Connect(function(data: MoteData)
        if data.position then
            self:PlayMotePickupEffect(data.position)
        end
    end)

    -- Blessing received — notification + beam VFX
    local BlessingReceived = ReplicatedStorage:WaitForChild("BlessingReceived")
    BlessingReceived.OnClientEvent:Connect(function(data: BlessingData)
        if data.message then
            self:ShowNotification(data.message, COLORS.gold, 4)
        end
        self:PlayBlessingReceiveEffect()
    end)

    -- Blessing chain — notification + chain ring VFX
    local BlessingChain = ReplicatedStorage:WaitForChild("BlessingChain")
    BlessingChain.OnClientEvent:Connect(function(data: BlessingData)
        local msg: string = (data.message or "Chain Bonus") .. " (Chain: " .. (data.chainLength or 0) .. ")"
        self:ShowNotification(msg, COLORS.green, 3)
        self:PlayChainEffect(data.chainLength or 1)
    end)

    -- Layer unlock notifications
    local LayerUnlocked = ReplicatedStorage:WaitForChild("LayerUnlocked")
    LayerUnlocked.OnClientEvent:Connect(function(data: { message: string })
        self:ShowNotification(data.message, COLORS.accent, 5)
    end)

    -- HALT notification
    local HALTNotify = ReplicatedStorage:WaitForChild("HALTNotify")
    HALTNotify.OnClientEvent:Connect(function(data: HALTData)
        self:ShowHALTNotification(data)
    end)

    -- Stamina updates
    local StaminaUpdate = ReplicatedStorage:WaitForChild("StaminaUpdate", 10)
    if StaminaUpdate then
        StaminaUpdate.OnClientEvent:Connect(function(data: StaminaData)
            self:UpdateStaminaBar(data.current, data.max, data.action)
        end)
    end
end

return UIController
