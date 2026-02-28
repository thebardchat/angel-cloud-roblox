--[[
    LoreCodexController.lua — Knit Controller for the constellation map Lore Codex
    Migrated from StarterPlayerScripts/LoreCodexUI.lua
    Press C to toggle. Each fragment is a star; connected stars form Angel's silhouette.
    Collected fragments show narrative passage + wisdom principle.
    Features: constellation map, C key toggle, category tabs, fragment cards, popup notifications
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LoreCodexController = Knit.CreateController({ Name = "LoreCodexController" })

local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local codexFrame: Frame = nil :: any
local isOpen: boolean = false

type CodexCategoryProgress = {
    collected: number,
    total: number,
}

type CodexFragment = {
    id: string,
    name: string,
    category: string,
    collected: boolean,
    wisdom: string?,
    loreText: string?,
}

type CodexData = {
    totalCollected: number,
    totalFragments: number,
    categoryProgress: { [string]: CodexCategoryProgress }?,
    codex: { CodexFragment },
}

type FragmentPopupData = {
    name: string,
    category: string,
    wisdom: string?,
    loreText: string?,
    totalCollected: number,
    totalFragments: number,
}

local cachedCodex: CodexData? = nil

local COLORS = {
    bg = Color3.fromRGB(5, 5, 12),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(80, 80, 100),
    uncollected = Color3.fromRGB(40, 40, 55),
    categoryColors = {
        Decision = Color3.fromRGB(255, 215, 0),
        Emotion = Color3.fromRGB(0, 212, 255),
        Relationship = Color3.fromRGB(255, 150, 200),
        Strength = Color3.fromRGB(255, 100, 50),
        Suffering = Color3.fromRGB(120, 50, 180),
        Guardian = Color3.fromRGB(100, 255, 100),
        Angel = Color3.fromRGB(255, 255, 255),
    },
}

local CATEGORIES: { string } = { "Decision", "Emotion", "Relationship", "Strength", "Suffering", "Guardian", "Angel" }

--[=[
    Creates a fragment card UI element inside the detail scrolling frame.
    Shows collected or uncollected state, star indicator, name, wisdom, and lore text.
    @param parent ScrollingFrame -- The parent scrolling frame
    @param frag CodexFragment -- Fragment data
    @param order number -- Layout order
]=]
function LoreCodexController:_createFragmentCard(parent: ScrollingFrame, frag: CodexFragment, order: number): ()
    local card: Frame = Instance.new("Frame")
    card.Name = "Fragment_" .. frag.id
    card.Size = UDim2.new(1, -20, 0, if frag.collected then 120 else 50)
    card.BackgroundColor3 = if frag.collected then Color3.fromRGB(15, 15, 25) else COLORS.uncollected
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 12
    card.Parent = parent

    local corner: UICorner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local catColor: Color3 = COLORS.categoryColors[frag.category] or COLORS.white

    if frag.collected then
        local stroke: UIStroke = Instance.new("UIStroke")
        stroke.Color = catColor
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        stroke.Parent = card
    end

    -- Star indicator
    local star: TextLabel = Instance.new("TextLabel")
    star.Size = UDim2.new(0, 25, 0, 25)
    star.Position = UDim2.new(0, 10, 0, 10)
    star.BackgroundTransparency = 1
    star.Text = if frag.collected then "*" else "."
    star.TextColor3 = if frag.collected then catColor else COLORS.dim
    star.TextSize = if frag.collected then 24 else 16
    star.Font = Enum.Font.GothamBold
    star.ZIndex = 13
    star.Parent = card

    -- Name
    local name: TextLabel = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -50, 0, 25)
    name.Position = UDim2.new(0, 40, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = if frag.collected then frag.name else "???"
    name.TextColor3 = if frag.collected then COLORS.white else COLORS.dim
    name.TextSize = 15
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.ZIndex = 13
    name.Parent = card

    if frag.collected and frag.wisdom then
        -- Wisdom text
        local wisdom: TextLabel = Instance.new("TextLabel")
        wisdom.Size = UDim2.new(1, -50, 0, 35)
        wisdom.Position = UDim2.new(0, 40, 0, 38)
        wisdom.BackgroundTransparency = 1
        wisdom.Text = frag.wisdom
        wisdom.TextColor3 = catColor
        wisdom.TextSize = 12
        wisdom.Font = Enum.Font.GothamMedium
        wisdom.TextWrapped = true
        wisdom.TextXAlignment = Enum.TextXAlignment.Left
        wisdom.ZIndex = 13
        wisdom.Parent = card

        -- Lore text
        if frag.loreText then
            local lore: TextLabel = Instance.new("TextLabel")
            lore.Size = UDim2.new(1, -50, 0, 35)
            lore.Position = UDim2.new(0, 40, 0, 78)
            lore.BackgroundTransparency = 1
            lore.Text = '"' .. frag.loreText .. '"'
            lore.TextColor3 = COLORS.dim
            lore.TextSize = 11
            lore.Font = Enum.Font.GothamMedium
            lore.TextWrapped = true
            lore.TextXAlignment = Enum.TextXAlignment.Left
            lore.ZIndex = 13
            lore.Parent = card
        end
    end
end

--[=[
    Displays fragments filtered by the given category in the detail area.
    Clears existing fragment cards and repopulates from cachedCodex.
    @param category string -- The category name to filter by
]=]
function LoreCodexController:ShowCategory(category: string): ()
    local detailArea: ScrollingFrame? = codexFrame:FindFirstChild("DetailArea") :: ScrollingFrame?
    if not detailArea or not cachedCodex then
        return
    end

    -- Clear existing
    for _, child in ipairs((detailArea :: ScrollingFrame):GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Filter fragments by category
    local order: number = 0
    for _, frag in ipairs((cachedCodex :: CodexData).codex) do
        if frag.category == category then
            order = order + 1
            self:_createFragmentCard(detailArea :: ScrollingFrame, frag, order)
        end
    end

    -- Update canvas size
    local layout: UIListLayout? = (detailArea :: ScrollingFrame):FindFirstChild("UIListLayout") :: UIListLayout?
    if layout then
        (detailArea :: ScrollingFrame).CanvasSize = UDim2.new(0, 0, 0, (layout :: UIListLayout).AbsoluteContentSize.Y + 20)
    end
end

--[=[
    Refreshes the entire codex UI from cachedCodex data.
    Updates progress counter, category tab counts, and shows the first category.
]=]
function LoreCodexController:Refresh(): ()
    if not cachedCodex then
        return
    end

    local data: CodexData = cachedCodex :: CodexData

    -- Update progress counter
    local progressLabel: TextLabel? = codexFrame:FindFirstChild("ProgressCount") :: TextLabel?
    if progressLabel then
        (progressLabel :: TextLabel).Text = data.totalCollected .. " / " .. data.totalFragments .. " Fragments"
    end

    -- Update category tab counts
    local sidebar: Frame? = codexFrame:FindFirstChild("CategorySidebar") :: Frame?
    if sidebar and data.categoryProgress then
        for cat: string, progress: CodexCategoryProgress in pairs(data.categoryProgress :: { [string]: CodexCategoryProgress }) do
            local tab: TextButton? = (sidebar :: Frame):FindFirstChild("Tab_" .. cat) :: TextButton?
            if tab then
                (tab :: TextButton).Text = "  " .. cat .. " (" .. progress.collected .. "/" .. progress.total .. ")"
            end
        end
    end

    -- Show first category by default
    self:ShowCategory("Decision")
end

--[=[
    Toggles the Lore Codex overlay open/closed.
    When opening, fires a server request to get fresh codex data.
]=]
function LoreCodexController:Toggle(): ()
    isOpen = not isOpen
    codexFrame.Visible = isOpen

    if isOpen then
        -- Request fresh data from server
        local CodexRequest: RemoteEvent? = ReplicatedStorage:FindFirstChild("CodexRequest") :: RemoteEvent?
        if CodexRequest then
            (CodexRequest :: RemoteEvent):FireServer()
        end
    end
end

--[=[
    Shows a popup notification when a fragment is collected.
    Includes category label, fragment name, wisdom, lore, and progress counter.
    Auto-dismisses after 8 seconds with fade animation.
    @param data FragmentPopupData -- The fragment collection data from the server
]=]
function LoreCodexController:ShowFragmentPopup(data: FragmentPopupData): ()
    local screenGui: ScreenGui? = playerGui:FindFirstChild("AngelCloudUI") :: ScreenGui?
    if not screenGui then
        return
    end

    local catColor: Color3 = COLORS.categoryColors[data.category] or COLORS.gold

    local popup: Frame = Instance.new("Frame")
    popup.Name = "FragmentPopup"
    popup.Size = UDim2.new(0, 450, 0, 200)
    popup.Position = UDim2.new(0.5, -225, 0.5, -100)
    popup.BackgroundColor3 = COLORS.bg
    popup.BackgroundTransparency = 0.05
    popup.ZIndex = 20
    popup.Parent = screenGui

    local corner: UICorner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = popup

    local stroke: UIStroke = Instance.new("UIStroke")
    stroke.Color = catColor
    stroke.Thickness = 2
    stroke.Parent = popup

    -- Category label
    local catLabel: TextLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(1, 0, 0, 20)
    catLabel.Position = UDim2.new(0, 0, 0, 12)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = data.category .. " Fragment"
    catLabel.TextColor3 = catColor
    catLabel.TextSize = 12
    catLabel.Font = Enum.Font.GothamMedium
    catLabel.ZIndex = 21
    catLabel.Parent = popup

    -- Fragment name
    local nameLabel: TextLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -30, 0, 30)
    nameLabel.Position = UDim2.new(0, 15, 0, 35)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.name
    nameLabel.TextColor3 = COLORS.white
    nameLabel.TextSize = 22
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 21
    nameLabel.Parent = popup

    -- Wisdom
    local wisdomLabel: TextLabel = Instance.new("TextLabel")
    wisdomLabel.Size = UDim2.new(1, -30, 0, 50)
    wisdomLabel.Position = UDim2.new(0, 15, 0, 70)
    wisdomLabel.BackgroundTransparency = 1
    wisdomLabel.Text = data.wisdom or ""
    wisdomLabel.TextColor3 = catColor
    wisdomLabel.TextSize = 13
    wisdomLabel.Font = Enum.Font.GothamMedium
    wisdomLabel.TextWrapped = true
    wisdomLabel.TextXAlignment = Enum.TextXAlignment.Left
    wisdomLabel.ZIndex = 21
    wisdomLabel.Parent = popup

    -- Lore
    local loreLabel: TextLabel = Instance.new("TextLabel")
    loreLabel.Size = UDim2.new(1, -30, 0, 40)
    loreLabel.Position = UDim2.new(0, 15, 0, 125)
    loreLabel.BackgroundTransparency = 1
    loreLabel.Text = '"' .. (data.loreText or "") .. '"'
    loreLabel.TextColor3 = COLORS.dim
    loreLabel.TextSize = 12
    loreLabel.Font = Enum.Font.GothamMedium
    loreLabel.TextWrapped = true
    loreLabel.TextXAlignment = Enum.TextXAlignment.Left
    loreLabel.ZIndex = 21
    loreLabel.Parent = popup

    -- Progress
    local progLabel: TextLabel = Instance.new("TextLabel")
    progLabel.Size = UDim2.new(1, -30, 0, 20)
    progLabel.Position = UDim2.new(0, 15, 1, -25)
    progLabel.BackgroundTransparency = 1
    progLabel.Text = data.totalCollected .. " / " .. data.totalFragments .. " Fragments Collected"
    progLabel.TextColor3 = COLORS.accent
    progLabel.TextSize = 11
    progLabel.Font = Enum.Font.Gotham
    progLabel.TextXAlignment = Enum.TextXAlignment.Left
    progLabel.ZIndex = 21
    progLabel.Parent = popup

    -- Fade-in animation
    popup.BackgroundTransparency = 1
    stroke.Transparency = 1
    for _, child in ipairs(popup:GetChildren()) do
        if child:IsA("TextLabel") then
            (child :: TextLabel).TextTransparency = 1
        end
    end
    local fadeInInfo: TweenInfo = TweenInfo.new(0.5)
    TweenService:Create(popup, fadeInInfo, { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(stroke, fadeInInfo, { Transparency = 0 }):Play()
    task.delay(0.2, function()
        for _, child in ipairs(popup:GetChildren()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
            end
        end
    end)

    -- Auto-dismiss (fade all elements)
    task.delay(8, function()
        if popup and popup.Parent then
            local fadeInfo: TweenInfo = TweenInfo.new(1)
            TweenService:Create(popup, fadeInfo, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
            for _, child in ipairs(popup:GetChildren()) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, fadeInfo, { TextTransparency = 1 }):Play()
                end
            end
            task.delay(1.2, function()
                popup:Destroy()
            end)
        end
    end)
end

--[=[
    KnitInit: Builds the full codex UI hierarchy (overlay frame, title, subtitle,
    progress counter, close button, category sidebar tabs, detail scrolling area).
    Connects RemoteEvent listeners for codex data and fragment collection.
]=]
function LoreCodexController:KnitInit(): ()
    local screenGui: ScreenGui = playerGui:WaitForChild("AngelCloudUI") :: ScreenGui

    -- Main codex frame (full screen overlay)
    codexFrame = Instance.new("Frame")
    codexFrame.Name = "LoreCodex"
    codexFrame.Size = UDim2.new(1, 0, 1, 0)
    codexFrame.Position = UDim2.new(0, 0, 0, 0)
    codexFrame.BackgroundColor3 = COLORS.bg
    codexFrame.BackgroundTransparency = 0.05
    codexFrame.Visible = false
    codexFrame.ZIndex = 10
    codexFrame.Parent = screenGui

    -- Title
    local title: TextLabel = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "THE LORE OF ANGEL"
    title.TextColor3 = COLORS.gold
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 11
    title.Parent = codexFrame

    -- Subtitle
    local subtitle: TextLabel = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 55)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Each star is a fragment of Angel's scattered light"
    subtitle.TextColor3 = COLORS.dim
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.ZIndex = 11
    subtitle.Parent = codexFrame

    -- Progress counter
    local progress: TextLabel = Instance.new("TextLabel")
    progress.Name = "ProgressCount"
    progress.Size = UDim2.new(0, 200, 0, 25)
    progress.Position = UDim2.new(1, -215, 0, 15)
    progress.BackgroundTransparency = 1
    progress.Text = "0 / 65 Fragments"
    progress.TextColor3 = COLORS.accent
    progress.TextSize = 16
    progress.Font = Enum.Font.GothamBold
    progress.TextXAlignment = Enum.TextXAlignment.Right
    progress.ZIndex = 11
    progress.Parent = codexFrame

    -- Close button
    local closeBtn: TextButton = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -55, 0, 10)
    closeBtn.BackgroundColor3 = COLORS.bg
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.white
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 12
    closeBtn.Parent = codexFrame

    local closeCorner: UICorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Category tabs (left sidebar)
    local sidebar: Frame = Instance.new("Frame")
    sidebar.Name = "CategorySidebar"
    sidebar.Size = UDim2.new(0, 160, 1, -100)
    sidebar.Position = UDim2.new(0, 15, 0, 90)
    sidebar.BackgroundTransparency = 1
    sidebar.ZIndex = 11
    sidebar.Parent = codexFrame

    local sidebarLayout: UIListLayout = Instance.new("UIListLayout")
    sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarLayout.Padding = UDim.new(0, 5)
    sidebarLayout.Parent = sidebar

    for i: number, cat: string in ipairs(CATEGORIES) do
        local tab: TextButton = Instance.new("TextButton")
        tab.Name = "Tab_" .. cat
        tab.Size = UDim2.new(1, 0, 0, 35)
        tab.BackgroundColor3 = COLORS.uncollected
        tab.BackgroundTransparency = 0.3
        tab.Text = "  " .. cat
        tab.TextColor3 = COLORS.categoryColors[cat] or COLORS.white
        tab.TextSize = 14
        tab.Font = Enum.Font.GothamMedium
        tab.TextXAlignment = Enum.TextXAlignment.Left
        tab.LayoutOrder = i
        tab.ZIndex = 12
        tab.Parent = sidebar

        local tabCorner: UICorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
        tabCorner.Parent = tab

        tab.MouseButton1Click:Connect(function()
            self:ShowCategory(cat)
        end)
    end

    -- Fragment detail area (right side)
    local detailArea: ScrollingFrame = Instance.new("ScrollingFrame")
    detailArea.Name = "DetailArea"
    detailArea.Size = UDim2.new(1, -200, 1, -100)
    detailArea.Position = UDim2.new(0, 190, 0, 90)
    detailArea.BackgroundTransparency = 1
    detailArea.ScrollBarThickness = 4
    detailArea.ScrollBarImageColor3 = COLORS.accent
    detailArea.ZIndex = 11
    detailArea.Parent = codexFrame

    local detailLayout: UIListLayout = Instance.new("UIListLayout")
    detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
    detailLayout.Padding = UDim.new(0, 10)
    detailLayout.Parent = detailArea

    -- Listen for codex data
    local CodexData: RemoteEvent = ReplicatedStorage:WaitForChild("CodexData") :: RemoteEvent
    CodexData.OnClientEvent:Connect(function(data: CodexData)
        cachedCodex = data
        if isOpen then
            self:Refresh()
        end
    end)

    -- Fragment collection notification
    local FragmentCollected: RemoteEvent = ReplicatedStorage:WaitForChild("FragmentCollected") :: RemoteEvent
    FragmentCollected.OnClientEvent:Connect(function(data: FragmentPopupData)
        self:ShowFragmentPopup(data)
    end)

    print("[LoreCodexController] Codex UI initialized")
end

--[=[
    KnitStart: Binds the C key to toggle the Lore Codex overlay.
]=]
function LoreCodexController:KnitStart(): ()
    -- Bind C key to toggle codex
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.C then
            self:Toggle()
        end
    end)
end

return LoreCodexController
