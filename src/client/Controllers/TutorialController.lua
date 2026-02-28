--[[
    TutorialController.lua — Knit Controller for first-time user experience
    Checks if player is new (firstJoin is recent), shows tutorial overlay sequence.
    Guides: movement, flight basics, Halo collection, codex, Cloud Base intro.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local TutorialController = Knit.CreateController({ Name = "TutorialController" })

local player: Player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- How recently (in seconds) a firstJoin timestamp must be to trigger the tutorial
local NEW_PLAYER_THRESHOLD_SECONDS: number = 60

type TutorialStep = {
    title: string,
    body: string,
    duration: number,
}

local TUTORIAL_STEPS: { TutorialStep } = {
    {
        title = "Welcome to Angel Cloud",
        body = "You are an Angel. Your wings will grow as you do.",
        duration = 5,
    },
    {
        title = "Movement",
        body = "Use WASD or the joystick to move. Jump with Space or the jump button.",
        duration = 5,
    },
    {
        title = "Flight",
        body = "Double-jump to glide! Hold the flight button to soar through the clouds.",
        duration = 5,
    },
    {
        title = "Halos",
        body = "Collect glowing Halos to earn currency. Spend them on wings, cosmetics, and your Cloud Base.",
        duration = 5,
    },
    {
        title = "Lore Codex",
        body = "Press C to open the Lore Codex. Discover fragments of Angel's scattered light.",
        duration = 5,
    },
    {
        title = "Your Cloud Base",
        body = "Build and customize your personal sky island. Visitors can leave kind messages!",
        duration = 5,
    },
    {
        title = "Every Angel Strengthens the Cloud",
        body = "Play, explore, and grow. Your journey begins now.",
        duration = 4,
    },
}

-- State
local tutorialActive: boolean = false
local currentStepIndex: number = 0

--[=[
    Checks whether the player qualifies as new based on their firstJoin timestamp.
    @param firstJoinTimestamp number -- Unix timestamp of the player's first join
    @return boolean -- True if the player joined within the threshold
]=]
function TutorialController:_isNewPlayer(firstJoinTimestamp: number): boolean
    local now: number = os.time()
    return (now - firstJoinTimestamp) < NEW_PLAYER_THRESHOLD_SECONDS
end

--[=[
    Displays a single tutorial overlay step with fade-in/out animations.
    @param step TutorialStep -- The tutorial step data
    @param onComplete (() -> ())? -- Optional callback when the step finishes
]=]
function TutorialController:_showStep(step: TutorialStep, onComplete: (() -> ())?): ()
    local screenGui: ScreenGui? = playerGui:FindFirstChild("AngelCloudUI") :: ScreenGui?
    if not screenGui then
        if onComplete then onComplete() end
        return
    end

    local overlay: Frame = Instance.new("Frame")
    overlay.Name = "TutorialOverlay"
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.ZIndex = 40
    overlay.Parent = screenGui

    local card: Frame = Instance.new("Frame")
    card.Name = "TutorialCard"
    card.Size = UDim2.new(0, 460, 0, 150)
    card.Position = UDim2.new(0.5, -230, 0.5, -75)
    card.BackgroundColor3 = Color3.fromRGB(5, 5, 12)
    card.BackgroundTransparency = 0.05
    card.ZIndex = 41
    card.Parent = overlay

    local corner: UICorner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local stroke: UIStroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 212, 255)
    stroke.Thickness = 2
    stroke.Parent = card

    local titleLabel: TextLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -30, 0, 35)
    titleLabel.Position = UDim2.new(0, 15, 0, 15)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = step.title
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 42
    titleLabel.Parent = card

    local bodyLabel: TextLabel = Instance.new("TextLabel")
    bodyLabel.Size = UDim2.new(1, -30, 0, 60)
    bodyLabel.Position = UDim2.new(0, 15, 0, 55)
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Text = step.body
    bodyLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    bodyLabel.TextSize = 15
    bodyLabel.Font = Enum.Font.GothamMedium
    bodyLabel.TextWrapped = true
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.ZIndex = 42
    bodyLabel.Parent = card

    local progressLabel: TextLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, -30, 0, 20)
    progressLabel.Position = UDim2.new(0, 15, 1, -25)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = currentStepIndex .. " / " .. #TUTORIAL_STEPS
    progressLabel.TextColor3 = Color3.fromRGB(0, 212, 255)
    progressLabel.TextSize = 11
    progressLabel.Font = Enum.Font.Gotham
    progressLabel.TextXAlignment = Enum.TextXAlignment.Right
    progressLabel.ZIndex = 42
    progressLabel.Parent = card

    -- Fade in
    overlay.BackgroundTransparency = 1
    card.BackgroundTransparency = 1
    stroke.Transparency = 1
    titleLabel.TextTransparency = 1
    bodyLabel.TextTransparency = 1
    progressLabel.TextTransparency = 1

    local fadeIn: TweenInfo = TweenInfo.new(0.4)
    TweenService:Create(overlay, fadeIn, { BackgroundTransparency = 0.6 }):Play()
    TweenService:Create(card, fadeIn, { BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(stroke, fadeIn, { Transparency = 0 }):Play()
    TweenService:Create(titleLabel, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(bodyLabel, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(progressLabel, fadeIn, { TextTransparency = 0 }):Play()

    -- Auto-advance after duration
    task.delay(step.duration, function()
        if overlay and overlay.Parent then
            local fadeOut: TweenInfo = TweenInfo.new(0.4)
            TweenService:Create(overlay, fadeOut, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(card, fadeOut, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()
            TweenService:Create(titleLabel, fadeOut, { TextTransparency = 1 }):Play()
            TweenService:Create(bodyLabel, fadeOut, { TextTransparency = 1 }):Play()
            TweenService:Create(progressLabel, fadeOut, { TextTransparency = 1 }):Play()
            task.delay(0.5, function()
                overlay:Destroy()
                if onComplete then onComplete() end
            end)
        end
    end)
end

--[=[
    Runs the full tutorial sequence, stepping through each overlay in order.
]=]
function TutorialController:_runSequence(): ()
    tutorialActive = true
    currentStepIndex = 0

    local function showNext(): ()
        currentStepIndex = currentStepIndex + 1
        if currentStepIndex > #TUTORIAL_STEPS then
            tutorialActive = false
            print("[TutorialController] Tutorial sequence complete")
            return
        end

        local step: TutorialStep = TUTORIAL_STEPS[currentStepIndex]
        self:_showStep(step, showNext)
    end

    showNext()
end

--[=[
    KnitInit: Connects to the TutorialCheck RemoteEvent to receive firstJoin data.
    If the player is new, triggers the tutorial overlay sequence.
]=]
function TutorialController:KnitInit(): ()
    local TutorialCheck: RemoteEvent? = ReplicatedStorage:WaitForChild("TutorialCheck", 15) :: RemoteEvent?

    if TutorialCheck then
        (TutorialCheck :: RemoteEvent).OnClientEvent:Connect(function(data: { firstJoin: number })
            if self:_isNewPlayer(data.firstJoin) and not tutorialActive then
                task.delay(3, function()
                    self:_runSequence()
                end)
            end
        end)
    end

    print("[TutorialController] Tutorial system initialized")
end

--[=[
    KnitStart: Requests tutorial status from server after a brief loading delay.
]=]
function TutorialController:KnitStart(): ()
    -- Request tutorial check from server after player loads in
    task.delay(2, function()
        local TutorialRequest: RemoteEvent? = ReplicatedStorage:FindFirstChild("TutorialRequest") :: RemoteEvent?
        if TutorialRequest then
            (TutorialRequest :: RemoteEvent):FireServer()
        end
    end)
end

return TutorialController
