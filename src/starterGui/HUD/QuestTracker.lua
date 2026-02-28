--[[
    QuestTracker.lua — Persistent quest tracker overlay (top-right)
    Migrated from QuestUI.lua into a reusable ModuleScript
    Shows active quest title, description, progress bar, and completion popup
    Visual identity: #0a0a0f background, #00d4ff accent, #ffd700 gold
]]

local TweenService = game:GetService("TweenService")

local QuestTracker = {}

---------------------------------------------------------------------------
-- Types
---------------------------------------------------------------------------

type QuestData = {
    status: string?,
    title: string?,
    description: string?,
    progress: number?,
    target: number?,
    reward: { motes: number? }?,
}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local COLORS = {
    bg      = Color3.fromRGB(10, 10, 20),
    accent  = Color3.fromRGB(0, 212, 255),
    gold    = Color3.fromRGB(255, 215, 0),
    white   = Color3.fromRGB(255, 255, 255),
    green   = Color3.fromRGB(100, 255, 150),
    dimWhite = Color3.fromRGB(150, 150, 170),
}

---------------------------------------------------------------------------
-- Create: Build the quest tracker frame inside the given parent
---------------------------------------------------------------------------

function QuestTracker.Create(parent: Frame): Frame
    local frame = Instance.new("Frame")
    frame.Name = "QuestTracker"
    frame.Size = UDim2.new(0, 280, 0, 90)
    frame.BackgroundColor3 = COLORS.bg
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- Quest icon
    local icon = Instance.new("TextLabel")
    icon.Name = "QuestIcon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 10, 0, 8)
    icon.BackgroundTransparency = 1
    icon.Text = ">"
    icon.TextColor3 = COLORS.gold
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame

    -- Quest title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -45, 0, 22)
    titleLabel.Position = UDim2.new(0, 35, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Loading quest..."
    titleLabel.TextColor3 = COLORS.gold
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = frame

    -- Quest description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, -20, 0, 20)
    descLabel.Position = UDim2.new(0, 10, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = ""
    descLabel.TextColor3 = COLORS.dimWhite
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    descLabel.Parent = frame

    -- Progress text
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressText"
    progressLabel.Size = UDim2.new(1, -20, 0, 16)
    progressLabel.Position = UDim2.new(0, 10, 0, 52)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "0 / 5"
    progressLabel.TextColor3 = COLORS.accent
    progressLabel.TextSize = 13
    progressLabel.Font = Enum.Font.GothamBold
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = frame

    -- Progress bar background
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, -20, 0, 6)
    progressBar.Position = UDim2.new(0, 10, 0, 72)
    progressBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = progressBar

    -- Progress bar fill
    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = COLORS.accent
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = progressFill

    -- Completion popup (hidden by default, parented to the tracker frame)
    QuestTracker._createCompletionPopup(frame)

    return frame
end

---------------------------------------------------------------------------
-- Private: Build the completion popup (hidden, inside tracker frame)
---------------------------------------------------------------------------

function QuestTracker._createCompletionPopup(parent: Frame): ()
    local completionFrame = Instance.new("Frame")
    completionFrame.Name = "QuestComplete"
    completionFrame.Size = UDim2.new(0, 320, 0, 120)
    completionFrame.Position = UDim2.new(0.5, -160, -1.5, 0)
    completionFrame.BackgroundColor3 = COLORS.bg
    completionFrame.BackgroundTransparency = 0.15
    completionFrame.BorderSizePixel = 0
    completionFrame.Visible = false
    completionFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = completionFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.gold
    stroke.Thickness = 2
    stroke.Parent = completionFrame

    local completeTitle = Instance.new("TextLabel")
    completeTitle.Name = "CompleteTitle"
    completeTitle.Size = UDim2.new(1, 0, 0, 30)
    completeTitle.Position = UDim2.new(0, 0, 0, 15)
    completeTitle.BackgroundTransparency = 1
    completeTitle.Text = "QUEST COMPLETE!"
    completeTitle.TextColor3 = COLORS.gold
    completeTitle.TextSize = 22
    completeTitle.Font = Enum.Font.GothamBold
    completeTitle.Parent = completionFrame

    local questName = Instance.new("TextLabel")
    questName.Name = "QuestName"
    questName.Size = UDim2.new(1, 0, 0, 22)
    questName.Position = UDim2.new(0, 0, 0, 48)
    questName.BackgroundTransparency = 1
    questName.Text = ""
    questName.TextColor3 = COLORS.white
    questName.TextSize = 16
    questName.Font = Enum.Font.GothamMedium
    questName.Parent = completionFrame

    local rewardText = Instance.new("TextLabel")
    rewardText.Name = "Reward"
    rewardText.Size = UDim2.new(1, 0, 0, 22)
    rewardText.Position = UDim2.new(0, 0, 0, 75)
    rewardText.BackgroundTransparency = 1
    rewardText.Text = ""
    rewardText.TextColor3 = COLORS.green
    rewardText.TextSize = 16
    rewardText.Font = Enum.Font.GothamBold
    rewardText.Parent = completionFrame
end

---------------------------------------------------------------------------
-- Update: Refresh the tracker with new quest data
---------------------------------------------------------------------------

function QuestTracker.Update(frame: Frame, data: QuestData): ()
    local titleLabel = frame:FindFirstChild("Title") :: TextLabel?
    local descLabel = frame:FindFirstChild("Description") :: TextLabel?
    local progressLabel = frame:FindFirstChild("ProgressText") :: TextLabel?
    local progressBar = frame:FindFirstChild("ProgressBar") :: Frame?

    local status: string = data.status or "active"

    if status == "active" then
        frame.Visible = true

        if titleLabel then
            titleLabel.Text = data.title or "Unknown Quest"
        end

        if descLabel then
            descLabel.Text = data.description or ""
        end

        local progress: number = math.min(data.progress or 0, data.target or 1)
        local target: number = data.target or 1

        if progressLabel then
            progressLabel.Text = progress .. " / " .. target
        end

        if progressBar then
            local progressFill = progressBar:FindFirstChild("Fill") :: Frame?
            if progressFill then
                local fillPercent: number = math.clamp(progress / target, 0, 1)
                TweenService:Create(progressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(fillPercent, 0, 1, 0),
                }):Play()

                -- Color shifts near completion
                if fillPercent >= 0.8 then
                    if progressLabel then
                        progressLabel.TextColor3 = COLORS.green
                    end
                    progressFill.BackgroundColor3 = COLORS.green
                else
                    if progressLabel then
                        progressLabel.TextColor3 = COLORS.accent
                    end
                    progressFill.BackgroundColor3 = COLORS.accent
                end
            end
        end

    elseif status == "all_complete" then
        frame.Visible = true

        if titleLabel then
            titleLabel.Text = "All Quests Complete!"
        end
        if descLabel then
            descLabel.Text = "You've mastered The Cloud Climb."
        end
        if progressLabel then
            progressLabel.Text = ""
        end
        if progressBar then
            local progressFill = progressBar:FindFirstChild("Fill") :: Frame?
            if progressFill then
                progressFill.Size = UDim2.new(1, 0, 1, 0)
                progressFill.BackgroundColor3 = COLORS.gold
            end
        end
    end
end

---------------------------------------------------------------------------
-- ShowCompletion: Animate the completion popup with quest name and reward
---------------------------------------------------------------------------

function QuestTracker.ShowCompletion(frame: Frame, data: QuestData): ()
    local completionFrame = frame:FindFirstChild("QuestComplete") :: Frame?
    if not completionFrame then
        return
    end

    completionFrame.Visible = true

    local questName = completionFrame:FindFirstChild("QuestName") :: TextLabel?
    if questName then
        questName.Text = data.title or "Quest"
    end

    local rewardText = completionFrame:FindFirstChild("Reward") :: TextLabel?
    if rewardText and data.reward then
        local parts: { string } = {}
        if data.reward.motes then
            table.insert(parts, "+" .. data.reward.motes .. " Motes")
        end
        rewardText.Text = table.concat(parts, "  ")
    end

    -- Animate in (slide down from above)
    completionFrame.Position = UDim2.new(0.5, -160, -1.8, 0)
    completionFrame.BackgroundTransparency = 1
    TweenService:Create(completionFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -160, -1.5, 0),
        BackgroundTransparency = 0.15,
    }):Play()

    -- Fade children in
    for _, desc in ipairs(completionFrame:GetDescendants()) do
        if desc:IsA("TextLabel") then
            desc.TextTransparency = 1
            TweenService:Create(desc, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
        end
    end

    -- Auto-hide after 3 seconds
    task.delay(3, function()
        TweenService:Create(completionFrame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -160, -1.8, 0),
        }):Play()

        for _, desc in ipairs(completionFrame:GetDescendants()) do
            if desc:IsA("TextLabel") then
                TweenService:Create(desc, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
            end
        end

        task.delay(0.5, function()
            completionFrame.Visible = false
        end)
    end)
end

return QuestTracker
