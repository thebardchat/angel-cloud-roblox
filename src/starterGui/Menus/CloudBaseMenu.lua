--[[
    CloudBaseMenu.lua — Building interface for Cloud Base
    Personal sky island customization: room placement, furniture, decorations.
]]

local TweenService = game:GetService("TweenService")

local CloudBaseMenu = {}

local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
}

local CATEGORIES = { "Rooms", "Furniture", "Decorations", "Lighting", "Visitors" }

local isOpen: boolean = false
local menuFrame: Frame? = nil
local screenGuiRef: ScreenGui? = nil
local activeCategory: string = "Rooms"

local function createCategoryTab(parent: Frame, name: string, index: number, zBase: number): TextButton
    local tab = Instance.new("TextButton")
    tab.Name = "Tab_" .. name
    tab.Size = UDim2.new(1, 0, 0, 32)
    tab.BackgroundColor3 = (name == activeCategory) and COLORS.accent or COLORS.bgLight
    tab.BackgroundTransparency = (name == activeCategory) and 0 or 0.3
    tab.BorderSizePixel = 0
    tab.Text = "  " .. name
    tab.TextColor3 = (name == activeCategory) and COLORS.bg or COLORS.white
    tab.TextSize = 13
    tab.Font = Enum.Font.GothamMedium
    tab.TextXAlignment = Enum.TextXAlignment.Left
    tab.LayoutOrder = index
    tab.ZIndex = zBase + 1
    tab.Parent = parent

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tab

    return tab
end

function CloudBaseMenu.Create(screenGui: ScreenGui): Frame
    screenGuiRef = screenGui

    menuFrame = Instance.new("Frame")
    menuFrame.Name = "CloudBasePanel"
    menuFrame.Size = UDim2.new(0, 520, 0, 400)
    menuFrame.Position = UDim2.new(0.5, -260, 0.5, -200)
    menuFrame.BackgroundColor3 = COLORS.bg
    menuFrame.BackgroundTransparency = 0.05
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.ZIndex = 40
    menuFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = menuFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 2
    stroke.Parent = menuFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 35)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "CLOUD BASE"
    title.TextColor3 = COLORS.accent
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 41
    title.Parent = menuFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -60, 0, 18)
    subtitle.Position = UDim2.new(0, 20, 0, 42)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Your personal sky island"
    subtitle.TextColor3 = COLORS.dimWhite
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 41
    subtitle.Parent = menuFrame

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
    closeBtn.Parent = menuFrame

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        CloudBaseMenu.Toggle()
    end)

    -- Category sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 140, 1, -80)
    sidebar.Position = UDim2.new(0, 15, 0, 68)
    sidebar.BackgroundTransparency = 1
    sidebar.ZIndex = 41
    sidebar.Parent = menuFrame

    local sidebarLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 4)
    sidebarLayout.Parent = sidebar

    for i, cat in ipairs(CATEGORIES) do
        local tab = createCategoryTab(sidebar, cat, i, 41)
        tab.MouseButton1Click:Connect(function()
            activeCategory = cat
            CloudBaseMenu._refreshTabs(sidebar)
            CloudBaseMenu._refreshContent()
        end)
    end

    -- Content area
    local contentArea = Instance.new("ScrollingFrame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -185, 1, -80)
    contentArea.Position = UDim2.new(0, 170, 0, 68)
    contentArea.BackgroundColor3 = COLORS.bgLight
    contentArea.BackgroundTransparency = 0.5
    contentArea.BorderSizePixel = 0
    contentArea.ScrollBarThickness = 4
    contentArea.ScrollBarImageColor3 = COLORS.accent
    contentArea.ZIndex = 41
    contentArea.Parent = menuFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentArea

    local contentLayout = Instance.new("UIGridLayout")
    contentLayout.CellSize = UDim2.new(0, 90, 0, 90)
    contentLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentArea

    -- Placeholder message
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "Placeholder"
    placeholder.Size = UDim2.new(1, 0, 0, 60)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = "Items will appear here\nwhen CloudBaseService is connected"
    placeholder.TextColor3 = COLORS.dimWhite
    placeholder.TextSize = 13
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextWrapped = true
    placeholder.ZIndex = 42
    placeholder.Parent = contentArea

    -- Halo balance at bottom
    local balanceLabel = Instance.new("TextLabel")
    balanceLabel.Name = "BalanceLabel"
    balanceLabel.Size = UDim2.new(1, -30, 0, 20)
    balanceLabel.Position = UDim2.new(0, 15, 1, -26)
    balanceLabel.BackgroundTransparency = 1
    balanceLabel.Text = "0 Halos available"
    balanceLabel.TextColor3 = COLORS.gold
    balanceLabel.TextSize = 12
    balanceLabel.Font = Enum.Font.GothamMedium
    balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    balanceLabel.ZIndex = 41
    balanceLabel.Parent = menuFrame

    return menuFrame
end

function CloudBaseMenu._refreshTabs(sidebar: Frame): ()
    for _, child in ipairs(sidebar:GetChildren()) do
        if child:IsA("TextButton") then
            local catName = string.sub(child.Name, 5) -- strip "Tab_"
            local selected = (catName == activeCategory)
            child.BackgroundColor3 = selected and COLORS.accent or COLORS.bgLight
            child.BackgroundTransparency = selected and 0 or 0.3
            child.TextColor3 = selected and COLORS.bg or COLORS.white
        end
    end
end

function CloudBaseMenu._refreshContent(): ()
    -- TODO: Populate content grid from CloudBaseService inventory
    -- Items filtered by activeCategory
end

function CloudBaseMenu.Toggle(): ()
    isOpen = not isOpen
    if not menuFrame then return end

    if isOpen then
        menuFrame.Visible = true
        menuFrame.Position = UDim2.new(0.5, -260, 1.2, 0)
        TweenService:Create(menuFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -260, 0.5, -200),
        }):Play()
    else
        TweenService:Create(menuFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -260, 1.2, 0),
        }):Play()
        task.delay(0.3, function()
            if menuFrame then
                menuFrame.Visible = false
            end
        end)
    end
end

return CloudBaseMenu
