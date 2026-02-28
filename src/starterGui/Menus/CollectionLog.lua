--[[
    CollectionLog.lua — Easter egg / fragment tracker UI
    Modeled after LoreCodexUI.lua's constellation-map fragment display.
    Categories with colored indicators, collected vs uncollected states, detail cards.
]]

local TweenService = game:GetService("TweenService")

local CollectionLog = {}

local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
    uncollected = Color3.fromRGB(40, 40, 55),
    categoryColors = {
        Decision = Color3.fromRGB(255, 215, 0),
        Emotion = Color3.fromRGB(0, 212, 255),
        Relationship = Color3.fromRGB(255, 150, 200),
        Strength = Color3.fromRGB(255, 100, 50),
        Suffering = Color3.fromRGB(120, 50, 180),
        Guardian = Color3.fromRGB(100, 255, 100),
        Angel = Color3.fromRGB(255, 255, 255),
        EasterEgg = Color3.fromRGB(255, 215, 0),
    },
}

local CATEGORIES = { "Decision", "Emotion", "Relationship", "Strength", "Suffering", "Guardian", "Angel", "EasterEgg" }

local isOpen: boolean = false
local logFrame: Frame? = nil
local screenGuiRef: ScreenGui? = nil
local cachedData: any = nil
local activeCategory: string = "Decision"

local function createFragmentCard(parent: ScrollingFrame, entry: { [string]: any }, order: number): Frame
    local collected = entry.collected == true
    local catColor = COLORS.categoryColors[entry.category] or COLORS.gold

    local card = Instance.new("Frame")
    card.Name = "Entry_" .. (entry.id or tostring(order))
    card.Size = UDim2.new(1, -10, 0, collected and 100 or 44)
    card.BackgroundColor3 = collected and Color3.fromRGB(15, 15, 25) or COLORS.uncollected
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 32
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    if collected then
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = catColor
        cardStroke.Thickness = 1
        cardStroke.Transparency = 0.5
        cardStroke.Parent = card
    end

    -- Star indicator
    local star = Instance.new("TextLabel")
    star.Size = UDim2.new(0, 25, 0, 25)
    star.Position = UDim2.new(0, 8, 0, 8)
    star.BackgroundTransparency = 1
    star.Text = collected and "*" or "."
    star.TextColor3 = collected and catColor or COLORS.dimWhite
    star.TextSize = collected and 22 or 14
    star.Font = Enum.Font.GothamBold
    star.ZIndex = 33
    star.Parent = card

    -- Name
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -50, 0, 22)
    name.Position = UDim2.new(0, 36, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = collected and (entry.name or "Unknown") or "???"
    name.TextColor3 = collected and COLORS.white or COLORS.dimWhite
    name.TextSize = 14
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.ZIndex = 33
    name.Parent = card

    if collected and entry.description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -50, 0, 50)
        desc.Position = UDim2.new(0, 36, 0, 36)
        desc.BackgroundTransparency = 1
        desc.Text = entry.description
        desc.TextColor3 = catColor
        desc.TextSize = 12
        desc.Font = Enum.Font.GothamMedium
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.ZIndex = 33
        desc.Parent = card
    end

    return card
end

function CollectionLog.Create(screenGui: ScreenGui): Frame
    screenGuiRef = screenGui

    logFrame = Instance.new("Frame")
    logFrame.Name = "CollectionLogPanel"
    logFrame.Size = UDim2.new(0.85, 0, 0.85, 0)
    logFrame.Position = UDim2.new(0.075, 0, 0.075, 0)
    logFrame.BackgroundColor3 = COLORS.bg
    logFrame.BackgroundTransparency = 0.05
    logFrame.BorderSizePixel = 0
    logFrame.Visible = false
    logFrame.ZIndex = 30
    logFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = logFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.gold
    stroke.Thickness = 2
    stroke.Parent = logFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.5, 0, 0, 40)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "COLLECTION LOG"
    title.TextColor3 = COLORS.gold
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 31
    title.Parent = logFrame

    -- Progress counter
    local progress = Instance.new("TextLabel")
    progress.Name = "ProgressCount"
    progress.Size = UDim2.new(0, 200, 0, 25)
    progress.Position = UDim2.new(1, -220, 0, 15)
    progress.BackgroundTransparency = 1
    progress.Text = "0 / 0 Collected"
    progress.TextColor3 = COLORS.accent
    progress.TextSize = 16
    progress.Font = Enum.Font.GothamBold
    progress.TextXAlignment = Enum.TextXAlignment.Right
    progress.ZIndex = 31
    progress.Parent = logFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -55, 0, 10)
    closeBtn.BackgroundColor3 = COLORS.bgLight
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.white
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 32
    closeBtn.Parent = logFrame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        CollectionLog.Toggle()
    end)

    -- Category sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "CategorySidebar"
    sidebar.Size = UDim2.new(0, 155, 1, -70)
    sidebar.Position = UDim2.new(0, 15, 0, 60)
    sidebar.BackgroundTransparency = 1
    sidebar.ZIndex = 31
    sidebar.Parent = logFrame

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.Parent = sidebar

    for i, cat in ipairs(CATEGORIES) do
        local tab = Instance.new("TextButton")
        tab.Name = "Tab_" .. cat
        tab.Size = UDim2.new(1, 0, 0, 32)
        tab.BackgroundColor3 = COLORS.uncollected
        tab.BackgroundTransparency = 0.3
        tab.BorderSizePixel = 0
        tab.Text = "  " .. cat
        tab.TextColor3 = COLORS.categoryColors[cat] or COLORS.white
        tab.TextSize = 13
        tab.Font = Enum.Font.GothamMedium
        tab.TextXAlignment = Enum.TextXAlignment.Left
        tab.LayoutOrder = i
        tab.ZIndex = 32
        tab.Parent = sidebar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            activeCategory = cat
            CollectionLog._showCategory(cat)
        end)
    end

    -- Detail area
    local detailArea = Instance.new("ScrollingFrame")
    detailArea.Name = "DetailArea"
    detailArea.Size = UDim2.new(1, -195, 1, -70)
    detailArea.Position = UDim2.new(0, 185, 0, 60)
    detailArea.BackgroundTransparency = 1
    detailArea.ScrollBarThickness = 4
    detailArea.ScrollBarImageColor3 = COLORS.accent
    detailArea.ZIndex = 31
    detailArea.Parent = logFrame

    local detailLayout = Instance.new("UIListLayout")
    detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
    detailLayout.Padding = UDim.new(0, 8)
    detailLayout.Parent = detailArea

    return logFrame
end

function CollectionLog._showCategory(category: string): ()
    if not logFrame then return end
    local detailArea = logFrame:FindFirstChild("DetailArea")
    if not detailArea or not cachedData then return end

    -- Clear existing cards
    for _, child in ipairs(detailArea:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Build cards from cached data
    local entries = cachedData.entries or {}
    local order = 0
    for _, entry in ipairs(entries) do
        if entry.category == category then
            order += 1
            createFragmentCard(detailArea, entry, order)
        end
    end

    -- Update canvas size
    local layout = detailArea:FindFirstChild("UIListLayout")
    if layout then
        detailArea.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end

    -- Highlight active tab in sidebar
    local sidebar = logFrame:FindFirstChild("CategorySidebar")
    if sidebar then
        for _, child in ipairs(sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                local catName = string.sub(child.Name, 5)
                local selected = (catName == category)
                child.BackgroundColor3 = selected and (COLORS.categoryColors[catName] or COLORS.accent) or COLORS.uncollected
                child.BackgroundTransparency = selected and 0.1 or 0.3
                child.TextColor3 = selected and COLORS.bg or (COLORS.categoryColors[catName] or COLORS.white)
            end
        end
    end
end

function CollectionLog.Toggle(): ()
    isOpen = not isOpen
    if not logFrame then return end

    logFrame.Visible = isOpen
    if isOpen and cachedData then
        CollectionLog._showCategory(activeCategory)
    end
end

function CollectionLog.Refresh(data: any): ()
    cachedData = data
    if not logFrame then return end

    -- Update progress counter
    local progressLabel = logFrame:FindFirstChild("ProgressCount")
    if progressLabel and data then
        local collected = data.totalCollected or 0
        local total = data.totalEntries or 0
        progressLabel.Text = tostring(collected) .. " / " .. tostring(total) .. " Collected"
    end

    -- Update category tab counts
    local sidebar = logFrame:FindFirstChild("CategorySidebar")
    if sidebar and data and data.categoryProgress then
        for cat, prog in pairs(data.categoryProgress) do
            local tab = sidebar:FindFirstChild("Tab_" .. cat)
            if tab then
                local displayName = cat
                local count = (prog.collected or 0) .. "/" .. (prog.total or 0)
                tab.Text = "  " .. displayName .. " (" .. count .. ")"
            end
        end
    end

    if isOpen then
        CollectionLog._showCategory(activeCategory)
    end
end

return CollectionLog
