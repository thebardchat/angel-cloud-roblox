--[[
    WingShowcase.lua — Wing collection display
    Shows all wing skins owned/available with equip functionality.
    Wing tiers: Starter -> Courage -> Kindness -> Resilience -> Wisdom -> Guardian Angel
]]

local TweenService = game:GetService("TweenService")

local WingShowcase = {}

local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
    green = Color3.fromRGB(100, 255, 150),
    locked = Color3.fromRGB(50, 50, 60),
}

local isOpen: boolean = false
local showcaseFrame: Frame? = nil
local screenGuiRef: ScreenGui? = nil
local currentOwned: { string } = {}
local currentEquipped: string = ""

local function createWingCard(parent: ScrollingFrame, skinName: string, owned: boolean, equipped: boolean, order: number): Frame
    local card = Instance.new("Frame")
    card.Name = "Wing_" .. skinName
    card.Size = UDim2.new(0, 130, 0, 160)
    card.BackgroundColor3 = owned and COLORS.bgLight or COLORS.locked
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 42
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = equipped and COLORS.gold or (owned and COLORS.accent or COLORS.locked)
    cardStroke.Thickness = equipped and 2 or 1
    cardStroke.Transparency = owned and 0 or 0.5
    cardStroke.Parent = card

    -- Wing icon placeholder
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(1, -16, 0, 80)
    iconBg.Position = UDim2.new(0, 8, 0, 8)
    iconBg.BackgroundColor3 = COLORS.bg
    iconBg.BackgroundTransparency = 0.3
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 43
    iconBg.Parent = card

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 6)
    iconCorner.Parent = iconBg

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = owned and "W" or "?"
    iconLabel.TextColor3 = owned and COLORS.accent or COLORS.dimWhite
    iconLabel.TextSize = 32
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.ZIndex = 44
    iconLabel.Parent = iconBg

    -- Wing name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 18)
    nameLabel.Position = UDim2.new(0, 5, 0, 92)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = owned and skinName or "???"
    nameLabel.TextColor3 = owned and COLORS.white or COLORS.dimWhite
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 43
    nameLabel.Parent = card

    -- Status / equip button
    if owned then
        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, -16, 0, 28)
        actionBtn.Position = UDim2.new(0, 8, 0, 118)
        actionBtn.BackgroundColor3 = equipped and COLORS.gold or COLORS.accent
        actionBtn.BorderSizePixel = 0
        actionBtn.Text = equipped and "EQUIPPED" or "EQUIP"
        actionBtn.TextColor3 = COLORS.bg
        actionBtn.TextSize = 12
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.ZIndex = 44
        actionBtn.Parent = card

        local actionCorner = Instance.new("UICorner")
        actionCorner.CornerRadius = UDim.new(0, 6)
        actionCorner.Parent = actionBtn

        if not equipped then
            actionBtn.MouseButton1Click:Connect(function()
                -- TODO: Wire to Knit WingService:EquipSkin(skinName)
                currentEquipped = skinName
                WingShowcase.Refresh(currentOwned, currentEquipped)
            end)
        end
    else
        local lockedLabel = Instance.new("TextLabel")
        lockedLabel.Size = UDim2.new(1, -16, 0, 28)
        lockedLabel.Position = UDim2.new(0, 8, 0, 118)
        lockedLabel.BackgroundTransparency = 1
        lockedLabel.Text = "LOCKED"
        lockedLabel.TextColor3 = COLORS.dimWhite
        lockedLabel.TextSize = 11
        lockedLabel.Font = Enum.Font.GothamMedium
        lockedLabel.ZIndex = 43
        lockedLabel.Parent = card
    end

    return card
end

function WingShowcase.Create(screenGui: ScreenGui): Frame
    screenGuiRef = screenGui

    showcaseFrame = Instance.new("Frame")
    showcaseFrame.Name = "WingShowcasePanel"
    showcaseFrame.Size = UDim2.new(0, 580, 0, 440)
    showcaseFrame.Position = UDim2.new(0.5, -290, 0.5, -220)
    showcaseFrame.BackgroundColor3 = COLORS.bg
    showcaseFrame.BackgroundTransparency = 0.05
    showcaseFrame.BorderSizePixel = 0
    showcaseFrame.Visible = false
    showcaseFrame.ZIndex = 40
    showcaseFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = showcaseFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 2
    stroke.Parent = showcaseFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 0, 35)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "WING SHOWCASE"
    title.TextColor3 = COLORS.accent
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 41
    title.Parent = showcaseFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.5, 0, 0, 18)
    subtitle.Position = UDim2.new(0, 20, 0, 42)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Your wings reflect your journey"
    subtitle.TextColor3 = COLORS.dimWhite
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 41
    subtitle.Parent = showcaseFrame

    -- Collection count
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CollectionCount"
    countLabel.Size = UDim2.new(0, 200, 0, 25)
    countLabel.Position = UDim2.new(1, -220, 0, 15)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0 / 0 Unlocked"
    countLabel.TextColor3 = COLORS.gold
    countLabel.TextSize = 15
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Right
    countLabel.ZIndex = 41
    countLabel.Parent = showcaseFrame

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
    closeBtn.ZIndex = 42
    closeBtn.Parent = showcaseFrame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        WingShowcase.Toggle()
    end)

    -- Wing grid
    local gridScroll = Instance.new("ScrollingFrame")
    gridScroll.Name = "WingGrid"
    gridScroll.Size = UDim2.new(1, -30, 1, -80)
    gridScroll.Position = UDim2.new(0, 15, 0, 68)
    gridScroll.BackgroundTransparency = 1
    gridScroll.ScrollBarThickness = 4
    gridScroll.ScrollBarImageColor3 = COLORS.accent
    gridScroll.ZIndex = 41
    gridScroll.Parent = showcaseFrame

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 130, 0, 160)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridScroll

    return showcaseFrame
end

function WingShowcase.Toggle(): ()
    isOpen = not isOpen
    if not showcaseFrame then return end

    if isOpen then
        showcaseFrame.Visible = true
        showcaseFrame.Position = UDim2.new(0.5, -290, 1.2, 0)
        TweenService:Create(showcaseFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -290, 0.5, -220),
        }):Play()
    else
        TweenService:Create(showcaseFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -290, 1.2, 0),
        }):Play()
        task.delay(0.3, function()
            if showcaseFrame then
                showcaseFrame.Visible = false
            end
        end)
    end
end

function WingShowcase.Refresh(ownedSkins: { string }, equippedSkin: string): ()
    currentOwned = ownedSkins
    currentEquipped = equippedSkin

    if not showcaseFrame then return end

    local grid = showcaseFrame:FindFirstChild("WingGrid")
    if not grid then return end

    -- Clear existing cards
    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- All possible wing skins (tier order)
    local ALL_SKINS = {
        "Starter Wings",
        "Courage Wings",
        "Kindness Wings",
        "Resilience Wings",
        "Wisdom Wings",
        "Guardian Angel Wings",
        "Starlight Wings",
        "Storm Wings",
        "Crystal Wings",
        "Ember Wings",
        "Frost Wings",
        "Shadow Wings",
    }

    -- Build owned lookup
    local ownedSet: { [string]: boolean } = {}
    for _, skin in ipairs(ownedSkins) do
        ownedSet[skin] = true
    end

    -- Create cards
    for i, skin in ipairs(ALL_SKINS) do
        local owned = ownedSet[skin] == true
        local equipped = (skin == equippedSkin)
        createWingCard(grid, skin, owned, equipped, i)
    end

    -- Update collection count
    local countLabel = showcaseFrame:FindFirstChild("CollectionCount")
    if countLabel then
        countLabel.Text = tostring(#ownedSkins) .. " / " .. tostring(#ALL_SKINS) .. " Unlocked"
    end

    -- Update canvas size
    local layout = grid:FindFirstChild("UIGridLayout")
    if layout then
        grid.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
end

return WingShowcase
