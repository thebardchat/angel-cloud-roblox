--[[
    DailyRewardUI.lua — Client-side daily reward popup
    Shows streak progress, current reward, claim button
    Visual identity matches Angel Cloud branding (#0a0a0f bg, #00d4ff accent)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DailyRewardUI = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Colors
local COLORS = {
    bg = Color3.fromRGB(10, 10, 15),
    bgLight = Color3.fromRGB(20, 20, 30),
    accent = Color3.fromRGB(0, 212, 255),
    gold = Color3.fromRGB(255, 215, 0),
    white = Color3.fromRGB(255, 255, 255),
    dimWhite = Color3.fromRGB(180, 180, 200),
    green = Color3.fromRGB(100, 255, 150),
    claimed = Color3.fromRGB(60, 60, 80),
}

local screenGui
local rewardFrame

function DailyRewardUI.Init()
    local DailyRewardNotify = ReplicatedStorage:WaitForChild("DailyRewardNotify", 30)
    if not DailyRewardNotify then
        warn("[DailyRewardUI] DailyRewardNotify not found")
        return
    end

    local DailyRewardClaim = ReplicatedStorage:WaitForChild("DailyRewardClaim", 30)

    DailyRewardNotify.OnClientEvent:Connect(function(data)
        if data.available then
            DailyRewardUI.ShowRewardPopup(data, DailyRewardClaim)
        elseif data.claimed then
            DailyRewardUI.ShowClaimedAnimation(data)
        end
    end)

    print("[DailyRewardUI] Daily reward UI initialized")
end

function DailyRewardUI.ShowRewardPopup(data, claimRemote)
    -- Get or create ScreenGui
    screenGui = playerGui:FindFirstChild("AngelCloudUI")
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DailyRewardGui"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui
    end

    -- Dim overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "DailyRewardOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.ZIndex = 50
    overlay.Parent = screenGui

    -- Main card
    rewardFrame = Instance.new("Frame")
    rewardFrame.Name = "DailyRewardCard"
    rewardFrame.Size = UDim2.new(0, 440, 0, 380)
    rewardFrame.Position = UDim2.new(0.5, -220, 0.5, -190)
    rewardFrame.BackgroundColor3 = COLORS.bg
    rewardFrame.BackgroundTransparency = 0.05
    rewardFrame.BorderSizePixel = 0
    rewardFrame.ZIndex = 51
    rewardFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = rewardFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.gold
    stroke.Thickness = 2
    stroke.Parent = rewardFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 35)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "DAILY REWARD"
    title.TextColor3 = COLORS.gold
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 52
    title.Parent = rewardFrame

    -- Streak info
    local streakLabel = Instance.new("TextLabel")
    streakLabel.Size = UDim2.new(1, -30, 0, 20)
    streakLabel.Position = UDim2.new(0, 15, 0, 48)
    streakLabel.BackgroundTransparency = 1
    streakLabel.Text = "Login Streak: " .. (data.totalStreak or 1) .. " days"
    streakLabel.TextColor3 = COLORS.dimWhite
    streakLabel.TextSize = 14
    streakLabel.Font = Enum.Font.Gotham
    streakLabel.TextXAlignment = Enum.TextXAlignment.Left
    streakLabel.ZIndex = 52
    streakLabel.Parent = rewardFrame

    -- Week reward display (7 day boxes)
    local weekContainer = Instance.new("Frame")
    weekContainer.Size = UDim2.new(1, -30, 0, 160)
    weekContainer.Position = UDim2.new(0, 15, 0, 78)
    weekContainer.BackgroundTransparency = 1
    weekContainer.ZIndex = 52
    weekContainer.Parent = rewardFrame

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 54, 0, 70)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = weekContainer

    local rewards = data.allRewards or {}
    for i, reward in ipairs(rewards) do
        local dayBox = Instance.new("Frame")
        dayBox.Name = "Day" .. i
        dayBox.LayoutOrder = i
        dayBox.BackgroundColor3 = reward.claimed and COLORS.claimed or COLORS.bgLight
        dayBox.BorderSizePixel = 0
        dayBox.ZIndex = 53

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 8)
        boxCorner.Parent = dayBox

        -- Highlight today's reward
        local isToday = (i == data.streakDay)
        if isToday then
            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = COLORS.gold
            boxStroke.Thickness = 2
            boxStroke.Parent = dayBox
        elseif reward.claimed then
            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = COLORS.green
            boxStroke.Thickness = 1
            boxStroke.Transparency = 0.5
            boxStroke.Parent = dayBox
        end

        local dayLabel = Instance.new("TextLabel")
        dayLabel.Size = UDim2.new(1, 0, 0, 18)
        dayLabel.Position = UDim2.new(0, 0, 0, 4)
        dayLabel.BackgroundTransparency = 1
        dayLabel.Text = "Day " .. i
        dayLabel.TextColor3 = isToday and COLORS.gold or COLORS.dimWhite
        dayLabel.TextSize = 11
        dayLabel.Font = Enum.Font.GothamBold
        dayLabel.ZIndex = 54
        dayLabel.Parent = dayBox

        local moteLabel = Instance.new("TextLabel")
        moteLabel.Size = UDim2.new(1, 0, 0, 22)
        moteLabel.Position = UDim2.new(0, 0, 0, 24)
        moteLabel.BackgroundTransparency = 1
        moteLabel.Text = "+" .. reward.motes
        moteLabel.TextColor3 = isToday and COLORS.accent or (reward.claimed and COLORS.green or COLORS.white)
        moteLabel.TextSize = 18
        moteLabel.Font = Enum.Font.GothamBold
        moteLabel.ZIndex = 54
        moteLabel.Parent = dayBox

        if reward.claimed then
            local checkLabel = Instance.new("TextLabel")
            checkLabel.Size = UDim2.new(1, 0, 0, 16)
            checkLabel.Position = UDim2.new(0, 0, 0, 48)
            checkLabel.BackgroundTransparency = 1
            checkLabel.Text = "Claimed"
            checkLabel.TextColor3 = COLORS.green
            checkLabel.TextSize = 10
            checkLabel.Font = Enum.Font.Gotham
            checkLabel.ZIndex = 54
            checkLabel.Parent = dayBox
        end

        if reward.bonusCosmetic and not reward.claimed then
            local bonusLabel = Instance.new("TextLabel")
            bonusLabel.Size = UDim2.new(1, 0, 0, 14)
            bonusLabel.Position = UDim2.new(0, 0, 0, 48)
            bonusLabel.BackgroundTransparency = 1
            bonusLabel.Text = "+Bonus!"
            bonusLabel.TextColor3 = COLORS.gold
            bonusLabel.TextSize = 10
            bonusLabel.Font = Enum.Font.GothamBold
            bonusLabel.ZIndex = 54
            bonusLabel.Parent = dayBox
        end

        dayBox.Parent = weekContainer
    end

    -- Today's reward highlight
    local todayReward = data.reward or { motes = 5, label = "Day 1" }
    local todayLabel = Instance.new("TextLabel")
    todayLabel.Size = UDim2.new(1, -30, 0, 25)
    todayLabel.Position = UDim2.new(0, 15, 0, 260)
    todayLabel.BackgroundTransparency = 1
    todayLabel.Text = "Today: +" .. todayReward.motes .. " Light Motes"
    todayLabel.TextColor3 = COLORS.accent
    todayLabel.TextSize = 18
    todayLabel.Font = Enum.Font.GothamBold
    todayLabel.ZIndex = 52
    todayLabel.Parent = rewardFrame

    -- Claim button
    local claimBtn = Instance.new("TextButton")
    claimBtn.Size = UDim2.new(0, 200, 0, 44)
    claimBtn.Position = UDim2.new(0.5, -100, 0, 300)
    claimBtn.BackgroundColor3 = COLORS.gold
    claimBtn.BorderSizePixel = 0
    claimBtn.Text = "CLAIM REWARD"
    claimBtn.TextColor3 = COLORS.bg
    claimBtn.TextSize = 18
    claimBtn.Font = Enum.Font.GothamBold
    claimBtn.ZIndex = 52
    claimBtn.Parent = rewardFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = claimBtn

    -- Hover effect
    claimBtn.MouseEnter:Connect(function()
        TweenService:Create(claimBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(255, 230, 50),
        }):Play()
    end)
    claimBtn.MouseLeave:Connect(function()
        TweenService:Create(claimBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.gold,
        }):Play()
    end)

    -- Claim action
    claimBtn.MouseButton1Click:Connect(function()
        claimBtn.Text = "CLAIMING..."
        claimBtn.Active = false

        if claimRemote then
            claimRemote:FireServer()
        end

        -- Close after brief delay
        task.delay(1.5, function()
            DailyRewardUI.ClosePopup(overlay)
        end)
    end)

    -- Scale in animation
    rewardFrame.Size = UDim2.new(0, 0, 0, 0)
    rewardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(rewardFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 380),
        Position = UDim2.new(0.5, -220, 0.5, -190),
    }):Play()
end

function DailyRewardUI.ShowClaimedAnimation(data)
    -- Flash effect on existing UI (the reward popup handles most of this)
end

function DailyRewardUI.ClosePopup(overlay)
    if rewardFrame and rewardFrame.Parent then
        TweenService:Create(rewardFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):Play()
    end

    if overlay and overlay.Parent then
        TweenService:Create(overlay, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
        }):Play()
    end

    task.delay(0.4, function()
        if rewardFrame and rewardFrame.Parent then rewardFrame:Destroy() end
        if overlay and overlay.Parent then overlay:Destroy() end
    end)
end

return DailyRewardUI
