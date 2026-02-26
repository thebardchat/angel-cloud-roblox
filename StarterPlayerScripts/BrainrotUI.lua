--[[
    BrainrotUI.lua — HUD for brainrot carry count, deposit indicator, devil warnings
    Shows how many brainrots you're carrying, direction to your base, and devil alerts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BrainrotUI = {}

local carryLabel
local devilWarning
local baseArrow

function BrainrotUI.Init()
    -- Wait for RemoteEvents
    local BrainrotCollected = ReplicatedStorage:WaitForChild("BrainrotCollected", 15)
    local BrainrotDeposited = ReplicatedStorage:WaitForChild("BrainrotDeposited", 15)
    local DevilAlert = ReplicatedStorage:WaitForChild("DevilAlert", 15)
    local DevilStole = ReplicatedStorage:WaitForChild("DevilStole", 15)

    -- Create HUD
    local gui = Instance.new("ScreenGui")
    gui.Name = "BrainrotHUD"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Carry counter (top center)
    local carryFrame = Instance.new("Frame")
    carryFrame.Name = "CarryFrame"
    carryFrame.Size = UDim2.new(0, 180, 0, 50)
    carryFrame.Position = UDim2.new(0.5, -90, 0, 10)
    carryFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    carryFrame.BackgroundTransparency = 0.3
    carryFrame.BorderSizePixel = 0
    carryFrame.Parent = gui

    local carryCorner = Instance.new("UICorner")
    carryCorner.CornerRadius = UDim.new(0, 10)
    carryCorner.Parent = carryFrame

    local carryStroke = Instance.new("UIStroke")
    carryStroke.Color = Color3.fromRGB(255, 150, 200)
    carryStroke.Transparency = 0.5
    carryStroke.Parent = carryFrame

    carryLabel = Instance.new("TextLabel")
    carryLabel.Name = "CarryLabel"
    carryLabel.Size = UDim2.new(1, 0, 1, 0)
    carryLabel.BackgroundTransparency = 1
    carryLabel.Text = "Brainrots: 0 / 10"
    carryLabel.TextColor3 = Color3.fromRGB(255, 200, 230)
    carryLabel.TextScaled = true
    carryLabel.Font = Enum.Font.GothamBold
    carryLabel.Parent = carryFrame

    -- Devil warning (center screen, hidden by default)
    devilWarning = Instance.new("TextLabel")
    devilWarning.Name = "DevilWarning"
    devilWarning.Size = UDim2.new(0, 300, 0, 60)
    devilWarning.Position = UDim2.new(0.5, -150, 0.3, 0)
    devilWarning.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
    devilWarning.BackgroundTransparency = 0.2
    devilWarning.BorderSizePixel = 0
    devilWarning.Text = "DEVIL NEARBY! Protect your brainrots!"
    devilWarning.TextColor3 = Color3.fromRGB(255, 100, 100)
    devilWarning.TextScaled = true
    devilWarning.Font = Enum.Font.GothamBold
    devilWarning.Visible = false
    devilWarning.Parent = gui

    local warnCorner = Instance.new("UICorner")
    warnCorner.CornerRadius = UDim.new(0, 8)
    warnCorner.Parent = devilWarning

    -- Connect events
    if BrainrotCollected then
        BrainrotCollected.OnClientEvent:Connect(function(data)
            BrainrotUI.OnCollected(data)
        end)
    end

    if BrainrotDeposited then
        BrainrotDeposited.OnClientEvent:Connect(function(data)
            BrainrotUI.OnDeposited(data)
        end)
    end

    if DevilAlert then
        DevilAlert.OnClientEvent:Connect(function(data)
            BrainrotUI.ShowDevilWarning(data)
        end)
    end

    if DevilStole then
        DevilStole.OnClientEvent:Connect(function(data)
            BrainrotUI.OnStolen(data)
        end)
    end

    print("[BrainrotUI] Brainrot HUD initialized")
end

function BrainrotUI.OnCollected(data: any)
    if carryLabel then
        carryLabel.Text = "Brainrots: " .. data.carrying .. " / " .. data.maxCarry
    end

    -- Flash green
    if carryLabel then
        carryLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        task.delay(0.5, function()
            if carryLabel then
                carryLabel.TextColor3 = Color3.fromRGB(255, 200, 230)
            end
        end)
    end
end

function BrainrotUI.OnDeposited(data: any)
    if carryLabel then
        carryLabel.Text = "Brainrots: 0 / 10"
    end

    -- Show deposit notification
    if devilWarning then
        devilWarning.Text = "Deposited " .. data.deposited .. "! +" .. data.bonusMotes .. " Motes!"
        devilWarning.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
        devilWarning.TextColor3 = Color3.fromRGB(100, 255, 150)
        devilWarning.Visible = true

        task.delay(3, function()
            if devilWarning then
                devilWarning.Visible = false
                devilWarning.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
                devilWarning.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end)
    end
end

function BrainrotUI.ShowDevilWarning(data: any)
    if devilWarning then
        devilWarning.Text = "DEVIL NEARBY! Protect your brainrots!"
        devilWarning.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
        devilWarning.TextColor3 = Color3.fromRGB(255, 100, 100)
        devilWarning.Visible = true

        task.delay(3, function()
            if devilWarning then
                devilWarning.Visible = false
            end
        end)
    end
end

function BrainrotUI.OnStolen(data: any)
    if carryLabel then
        carryLabel.Text = "Brainrots: " .. data.remaining .. " / 10"
    end

    -- Flash red warning
    if devilWarning then
        devilWarning.Text = "A devil stole a brainrot! (" .. data.remaining .. " left)"
        devilWarning.BackgroundColor3 = Color3.fromRGB(120, 10, 10)
        devilWarning.TextColor3 = Color3.fromRGB(255, 50, 50)
        devilWarning.Visible = true

        task.delay(3, function()
            if devilWarning then
                devilWarning.Visible = false
            end
        end)
    end
end

return BrainrotUI
