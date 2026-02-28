--[[
    AngelMailUI.lua — Client-side Angel Mail interface (Knit migration)
    Send pre-written positive messages to other players.
    Press M to open mail panel, pick a player, pick a message, send!
    Notification toasts for incoming mail slide in from top.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local AngelMailUI = {}

local player = Players.LocalPlayer

local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
    green = Color3.fromRGB(100, 255, 150),
    pink = Color3.fromRGB(255, 150, 200),
}

local isOpen: boolean = false
local mailPanel: Frame? = nil
local screenGuiRef: ScreenGui? = nil

-- Cached catalog from server
local cachedCategories: { [string]: { { id: string, text: string } } } = {}
local cachedPlayers: { string } = {}
local selectedPlayer: string? = nil
local selectedTemplate: string? = nil

function AngelMailUI.Init(screenGui: ScreenGui): ()
    screenGuiRef = screenGui

    -- Listen for incoming mail via Knit AngelMailService
    -- TODO: Wire to Knit controller: AngelMailController -> AngelMailService:GetMailSignal()
    -- For now, support legacy remotes as fallback
    local MailReceived = game:GetService("ReplicatedStorage"):FindFirstChild("MailReceived")
    if MailReceived and MailReceived:IsA("RemoteEvent") then
        MailReceived.OnClientEvent:Connect(function(data: any)
            AngelMailUI.ShowMailNotification(data)
        end)
    end

    -- Listen for catalog response
    local MailCatalog = game:GetService("ReplicatedStorage"):FindFirstChild("MailCatalog")
    if MailCatalog and MailCatalog:IsA("RemoteEvent") then
        MailCatalog.OnClientEvent:Connect(function(data: any)
            cachedCategories = data.categories or {}
            cachedPlayers = data.players or {}
            AngelMailUI._populatePanel()
        end)
    end

    -- M key to toggle
    UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.M then
            AngelMailUI.Toggle()
        end
    end)
end

function AngelMailUI.Toggle(): ()
    if isOpen then
        AngelMailUI._close()
    else
        AngelMailUI._open()
    end
end

function AngelMailUI._open(): ()
    if not screenGuiRef then return end
    isOpen = true
    selectedPlayer = nil
    selectedTemplate = nil

    -- Main panel
    mailPanel = Instance.new("Frame")
    mailPanel.Name = "AngelMailPanel"
    mailPanel.Size = UDim2.new(0, 500, 0, 420)
    mailPanel.Position = UDim2.new(0.5, -250, 1.2, 0) -- start offscreen
    mailPanel.BackgroundColor3 = COLORS.bg
    mailPanel.BackgroundTransparency = 0.05
    mailPanel.BorderSizePixel = 0
    mailPanel.ZIndex = 40
    mailPanel.Parent = screenGuiRef

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = mailPanel

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.pink
    stroke.Thickness = 2
    stroke.Parent = mailPanel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 35)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "ANGEL MAIL"
    title.TextColor3 = COLORS.pink
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 41
    title.Parent = mailPanel

    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -80, 0, 18)
    subtitle.Position = UDim2.new(0, 15, 0, 42)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Send kindness to other Angels (1 Mote per message)"
    subtitle.TextColor3 = COLORS.dimWhite
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 41
    subtitle.Parent = mailPanel

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -46, 0, 8)
    closeBtn.BackgroundColor3 = COLORS.bgLight
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"
    closeBtn.TextColor3 = COLORS.dimWhite
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 41
    closeBtn.Parent = mailPanel

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        AngelMailUI._close()
    end)

    -- Loading text
    local loadingLabel = Instance.new("TextLabel")
    loadingLabel.Name = "LoadingLabel"
    loadingLabel.Size = UDim2.new(1, 0, 0, 30)
    loadingLabel.Position = UDim2.new(0, 0, 0.5, -15)
    loadingLabel.BackgroundTransparency = 1
    loadingLabel.Text = "Loading mail catalog..."
    loadingLabel.TextColor3 = COLORS.dimWhite
    loadingLabel.TextSize = 14
    loadingLabel.Font = Enum.Font.Gotham
    loadingLabel.ZIndex = 41
    loadingLabel.Parent = mailPanel

    -- Request catalog from server
    -- TODO: Replace with Knit call: Knit.GetService("AngelMailService"):RequestCatalog()
    local MailCatalogRemote = game:GetService("ReplicatedStorage"):FindFirstChild("MailCatalog")
    if MailCatalogRemote then
        MailCatalogRemote:FireServer()
    end

    -- Slide in from bottom
    TweenService:Create(mailPanel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -250, 0.5, -210),
    }):Play()
end

function AngelMailUI._populatePanel(): ()
    if not mailPanel then return end

    -- Remove loading label
    local loading = mailPanel:FindFirstChild("LoadingLabel")
    if loading then loading:Destroy() end

    ---------------------------------------------------------------
    -- Player selector (left column)
    ---------------------------------------------------------------
    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(0, 160, 0, 20)
    playerLabel.Position = UDim2.new(0, 15, 0, 70)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "Send to:"
    playerLabel.TextColor3 = COLORS.accent
    playerLabel.TextSize = 13
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.ZIndex = 41
    playerLabel.Parent = mailPanel

    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Name = "PlayerList"
    playerScroll.Size = UDim2.new(0, 160, 0, 220)
    playerScroll.Position = UDim2.new(0, 15, 0, 92)
    playerScroll.BackgroundColor3 = COLORS.bgLight
    playerScroll.BackgroundTransparency = 0.5
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ZIndex = 41
    playerScroll.Parent = mailPanel

    local playerScrollCorner = Instance.new("UICorner")
    playerScrollCorner.CornerRadius = UDim.new(0, 8)
    playerScrollCorner.Parent = playerScroll

    local playerLayout = Instance.new("UIListLayout")
    playerLayout.Padding = UDim.new(0, 3)
    playerLayout.Parent = playerScroll

    for _, pName in ipairs(cachedPlayers) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 30)
        btn.BackgroundColor3 = COLORS.bgLight
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = pName
        btn.TextColor3 = COLORS.white
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.ZIndex = 42
        btn.Parent = playerScroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectedPlayer = pName
            -- Highlight selected
            for _, child in ipairs(playerScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.BackgroundColor3 = COLORS.bgLight
                    child.TextColor3 = COLORS.white
                end
            end
            btn.BackgroundColor3 = COLORS.accent
            btn.TextColor3 = COLORS.bg
        end)
    end

    if #cachedPlayers == 0 then
        local noneLabel = Instance.new("TextLabel")
        noneLabel.Size = UDim2.new(1, 0, 0, 30)
        noneLabel.BackgroundTransparency = 1
        noneLabel.Text = "No other Angels online"
        noneLabel.TextColor3 = COLORS.dimWhite
        noneLabel.TextSize = 12
        noneLabel.Font = Enum.Font.Gotham
        noneLabel.ZIndex = 42
        noneLabel.Parent = playerScroll
    end

    ---------------------------------------------------------------
    -- Message selector (right column)
    ---------------------------------------------------------------
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(0, 290, 0, 20)
    msgLabel.Position = UDim2.new(0, 190, 0, 70)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = "Choose a message:"
    msgLabel.TextColor3 = COLORS.pink
    msgLabel.TextSize = 13
    msgLabel.Font = Enum.Font.GothamBold
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.ZIndex = 41
    msgLabel.Parent = mailPanel

    local msgScroll = Instance.new("ScrollingFrame")
    msgScroll.Name = "MessageList"
    msgScroll.Size = UDim2.new(0, 290, 0, 220)
    msgScroll.Position = UDim2.new(0, 190, 0, 92)
    msgScroll.BackgroundColor3 = COLORS.bgLight
    msgScroll.BackgroundTransparency = 0.5
    msgScroll.BorderSizePixel = 0
    msgScroll.ScrollBarThickness = 4
    msgScroll.ZIndex = 41
    msgScroll.Parent = mailPanel

    local msgScrollCorner = Instance.new("UICorner")
    msgScrollCorner.CornerRadius = UDim.new(0, 8)
    msgScrollCorner.Parent = msgScroll

    local msgLayout = Instance.new("UIListLayout")
    msgLayout.Padding = UDim.new(0, 3)
    msgLayout.Parent = msgScroll

    for category, messages in pairs(cachedCategories) do
        -- Category header
        local catHeader = Instance.new("TextLabel")
        catHeader.Size = UDim2.new(1, -8, 0, 22)
        catHeader.BackgroundTransparency = 1
        catHeader.Text = category
        catHeader.TextColor3 = COLORS.gold
        catHeader.TextSize = 12
        catHeader.Font = Enum.Font.GothamBold
        catHeader.TextXAlignment = Enum.TextXAlignment.Left
        catHeader.ZIndex = 42
        catHeader.Parent = msgScroll

        for _, msg in ipairs(messages) do
            local msgBtn = Instance.new("TextButton")
            msgBtn.Size = UDim2.new(1, -8, 0, 35)
            msgBtn.BackgroundColor3 = COLORS.bgLight
            msgBtn.BackgroundTransparency = 0.3
            msgBtn.BorderSizePixel = 0
            msgBtn.Text = msg.text
            msgBtn.TextColor3 = COLORS.white
            msgBtn.TextSize = 12
            msgBtn.Font = Enum.Font.Gotham
            msgBtn.TextWrapped = true
            msgBtn.TextXAlignment = Enum.TextXAlignment.Left
            msgBtn.ZIndex = 42
            msgBtn.Parent = msgScroll

            local msgBtnCorner = Instance.new("UICorner")
            msgBtnCorner.CornerRadius = UDim.new(0, 6)
            msgBtnCorner.Parent = msgBtn

            msgBtn.MouseButton1Click:Connect(function()
                selectedTemplate = msg.id
                -- Highlight selected
                for _, child in ipairs(msgScroll:GetChildren()) do
                    if child:IsA("TextButton") then
                        child.BackgroundColor3 = COLORS.bgLight
                        child.TextColor3 = COLORS.white
                    end
                end
                msgBtn.BackgroundColor3 = COLORS.pink
                msgBtn.TextColor3 = COLORS.bg
            end)
        end
    end

    ---------------------------------------------------------------
    -- Send button
    ---------------------------------------------------------------
    local sendBtn = Instance.new("TextButton")
    sendBtn.Name = "SendBtn"
    sendBtn.Size = UDim2.new(0, 200, 0, 40)
    sendBtn.Position = UDim2.new(0.5, -100, 0, 330)
    sendBtn.BackgroundColor3 = COLORS.pink
    sendBtn.BorderSizePixel = 0
    sendBtn.Text = "SEND ANGEL MAIL"
    sendBtn.TextColor3 = COLORS.bg
    sendBtn.TextSize = 16
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.ZIndex = 41
    sendBtn.Parent = mailPanel

    local sendBtnCorner = Instance.new("UICorner")
    sendBtnCorner.CornerRadius = UDim.new(0, 10)
    sendBtnCorner.Parent = sendBtn

    sendBtn.MouseButton1Click:Connect(function()
        if not selectedPlayer then
            sendBtn.Text = "Pick an Angel first!"
            task.delay(1.5, function()
                if sendBtn.Parent then sendBtn.Text = "SEND ANGEL MAIL" end
            end)
            return
        end
        if not selectedTemplate then
            sendBtn.Text = "Pick a message first!"
            task.delay(1.5, function()
                if sendBtn.Parent then sendBtn.Text = "SEND ANGEL MAIL" end
            end)
            return
        end

        -- Send via remote (TODO: replace with Knit call)
        local MailSendRemote = game:GetService("ReplicatedStorage"):FindFirstChild("MailSend")
        if MailSendRemote then
            MailSendRemote:FireServer(selectedPlayer, selectedTemplate)
        end

        sendBtn.Text = "SENT!"
        sendBtn.BackgroundColor3 = COLORS.green
        task.delay(2, function()
            if sendBtn.Parent then
                sendBtn.Text = "SEND ANGEL MAIL"
                sendBtn.BackgroundColor3 = COLORS.pink
            end
        end)

        selectedTemplate = nil
    end)

    ---------------------------------------------------------------
    -- Hint at bottom
    ---------------------------------------------------------------
    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, -30, 0, 16)
    hintLabel.Position = UDim2.new(0, 15, 1, -24)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "Press M to close | Every message strengthens the cloud"
    hintLabel.TextColor3 = COLORS.dimWhite
    hintLabel.TextSize = 11
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.ZIndex = 41
    hintLabel.Parent = mailPanel
end

function AngelMailUI._close(): ()
    isOpen = false
    selectedPlayer = nil
    selectedTemplate = nil

    if mailPanel and mailPanel.Parent then
        TweenService:Create(mailPanel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -250, 1.2, 0),
        }):Play()
        task.delay(0.3, function()
            if mailPanel and mailPanel.Parent then
                mailPanel:Destroy()
                mailPanel = nil
            end
        end)
    end
end

function AngelMailUI.ShowMailNotification(data: any): ()
    if not screenGuiRef then return end

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 360, 0, 70)
    notif.Position = UDim2.new(0.5, -180, 0, -80) -- start offscreen top
    notif.BackgroundColor3 = COLORS.bg
    notif.BackgroundTransparency = 0.1
    notif.BorderSizePixel = 0
    notif.ZIndex = 60
    notif.Parent = screenGuiRef

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notif

    local notifStroke = Instance.new("UIStroke")
    notifStroke.Color = COLORS.pink
    notifStroke.Thickness = 2
    notifStroke.Parent = notif

    local fromLabel = Instance.new("TextLabel")
    fromLabel.Size = UDim2.new(1, -20, 0, 20)
    fromLabel.Position = UDim2.new(0, 10, 0, 6)
    fromLabel.BackgroundTransparency = 1
    fromLabel.Text = "Angel Mail from " .. (data.from or "Unknown")
    fromLabel.TextColor3 = COLORS.pink
    fromLabel.TextSize = 14
    fromLabel.Font = Enum.Font.GothamBold
    fromLabel.TextXAlignment = Enum.TextXAlignment.Left
    fromLabel.ZIndex = 61
    fromLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0, 36)
    textLabel.Position = UDim2.new(0, 10, 0, 28)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = '"' .. (data.text or "") .. '"'
    textLabel.TextColor3 = COLORS.white
    textLabel.TextSize = 13
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.ZIndex = 61
    textLabel.Parent = notif

    -- Slide in from top
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -180, 0, 20),
    }):Play()

    -- Auto-dismiss after 6 seconds
    task.delay(6, function()
        if notif and notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.4), {
                Position = UDim2.new(0.5, -180, 0, -80),
            }):Play()
            task.delay(0.5, function()
                if notif and notif.Parent then notif:Destroy() end
            end)
        end
    end)
end

return AngelMailUI
