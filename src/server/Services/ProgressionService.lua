--[[
    ProgressionService.lua — Angel level progression and layer access (Knit Service)
    Mirrors the real Angel Cloud ANGEL_LEVELS and PROGRESSION_THRESHOLDS
    Handles level-up detection, ascension sequences, and gate checks

    Migrated from ServerScriptService/ProgressionSystem.lua to Knit service pattern.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Layers = require(ReplicatedStorage.Config.Layers)

local ProgressionService = Knit.CreateService({
    Name = "ProgressionService",
    Client = {
        LevelUp = Knit.CreateSignal(),
        PlayerProgress = Knit.CreateSignal(),
    },
})

-- Service references resolved at KnitStart
local DataService
local MoteService
local SoundManager

-- VISUAL TRANSFORMATION — character gets more epic with each level
local LEVEL_VISUALS = {
    -- Level 1: Newborn — small wings, faint glow
    { wingSize = 4, wingColor = Color3.fromRGB(150, 200, 255), glowBrightness = 1, haloSize = 3, trailWidth = 1, auraSize = 0 },
    -- Level 2: Young Angel — medium wings, brighter
    { wingSize = 5.5, wingColor = Color3.fromRGB(0, 212, 255), glowBrightness = 2, haloSize = 3.5, trailWidth = 1.5, auraSize = 4 },
    -- Level 3: Growing Angel — big wings, visible aura
    { wingSize = 7, wingColor = Color3.fromRGB(0, 255, 200), glowBrightness = 3, haloSize = 4, trailWidth = 2, auraSize = 6 },
    -- Level 4: Helping Angel — large wings, strong glow
    { wingSize = 9, wingColor = Color3.fromRGB(180, 100, 255), glowBrightness = 4, haloSize = 4.5, trailWidth = 2.5, auraSize = 8 },
    -- Level 5: Guardian Angel — massive wings, intense aura
    { wingSize = 11, wingColor = Color3.fromRGB(100, 200, 255), glowBrightness = 5, haloSize = 5, trailWidth = 3, auraSize = 10 },
    -- Level 6: ARCHANGEL — ENORMOUS wings, blinding power
    { wingSize = 14, wingColor = Color3.fromRGB(255, 255, 255), glowBrightness = 8, haloSize = 6, trailWidth = 4, auraSize = 14 },
}

function ProgressionService:KnitInit(): ()
    -- Nothing to create; Knit signals replace Instance.new("RemoteEvent")
end

function ProgressionService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")

    -- SoundManager may still be a legacy module; require it safely
    local success, result = pcall(function()
        return require(game:GetService("ServerScriptService"):FindFirstChild("SoundManager"))
    end)
    if success and result then
        SoundManager = result
    end
end

function ProgressionService:CheckLevelUp(player: Player): string?
    local data = DataService:GetData(player)
    if not data then
        return nil
    end

    local currentLevel = data.angelLevel
    local currentIndex = Layers.GetLevelIndex(currentLevel)
    local motes = data.motes

    -- Check if player qualifies for a higher level
    local newLevel = nil
    for i = #Layers.ANGEL_LEVELS, currentIndex + 1, -1 do
        local levelName = Layers.ANGEL_LEVELS[i]
        if motes >= Layers.PROGRESSION_THRESHOLDS[levelName] then
            newLevel = levelName
            break
        end
    end

    if newLevel and newLevel ~= currentLevel then
        local newIndex = Layers.GetLevelIndex(newLevel)
        data.angelLevel = newLevel
        data.layerIndex = newIndex

        -- TRANSFORM the character — bigger wings, more glow!
        self:TransformCharacter(player, newIndex)

        -- Play level up sound
        if SoundManager then
            SoundManager.OnLevelUp(SoundManager, player)
        end

        -- Fire ascension cinematic for the player via Knit signal
        local layerDef = Layers.GetLayerByIndex(newIndex)
        self.Client.LevelUp:Fire(player, {
            newLevel = newLevel,
            layerIndex = newIndex,
            layerName = layerDef.name,
        })

        -- Update quest progress
        local questOk, QuestService = pcall(Knit.GetService, Knit, "QuestService")
        if questOk and QuestService then
            pcall(QuestService.OnLayerReached, QuestService, player, newIndex)
        end

        -- Notify all players in server
        local message = player.Name .. " ascends to " .. layerDef.name .. "! Every Angel strengthens the cloud."
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                self.Client.PlayerProgress:Fire(otherPlayer, {
                    playerName = player.Name,
                    newLevel = newLevel,
                    layerName = layerDef.name,
                    message = message,
                })
            end
        end

        return newLevel
    end

    return nil
end

function ProgressionService:GetPlayerLevel(player: Player): (string, number)
    local data = DataService:GetData(player)
    if not data then
        return "Newborn", 1
    end
    return data.angelLevel, data.layerIndex
end

function ProgressionService:CanAccessLayer(player: Player, layerIndex: number): boolean
    local data = DataService:GetData(player)
    if not data then
        return layerIndex == 1
    end
    return data.layerIndex >= layerIndex
end

function ProgressionService:GetProgress(player: Player): { [string]: any }
    local data = DataService:GetData(player)
    if not data then
        return {
            level = "Newborn",
            layerIndex = 1,
            motes = 0,
            nextThreshold = 10,
            progress = 0,
        }
    end

    local currentLevel = data.angelLevel
    local currentIndex = Layers.GetLevelIndex(currentLevel)
    local currentThreshold = Layers.PROGRESSION_THRESHOLDS[currentLevel]
    local nextThreshold = nil
    local progress = 100

    if currentIndex < #Layers.ANGEL_LEVELS then
        local nextLevel = Layers.ANGEL_LEVELS[currentIndex + 1]
        nextThreshold = Layers.PROGRESSION_THRESHOLDS[nextLevel]
        local range = nextThreshold - currentThreshold
        local current = data.motes - currentThreshold
        progress = math.clamp(math.floor((current / range) * 100), 0, 100)
    end

    return {
        level = currentLevel,
        layerIndex = data.layerIndex,
        motes = data.motes,
        nextThreshold = nextThreshold,
        progress = progress,
        fragmentCount = 0, -- filled by LoreSystem
    }
end

-- Called after any mote award to check for progression
function ProgressionService:OnMotesChanged(player: Player): ()
    self:CheckLevelUp(player)
end

-- Gate interaction: player touches a layer gate
function ProgressionService:HandleGateTouch(player: Player, targetLayerIndex: number): boolean
    if self:CanAccessLayer(player, targetLayerIndex) then
        -- Teleport player to next layer's spawn
        local layerDef = Layers.GetLayerByIndex(targetLayerIndex)
        if layerDef and player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = CFrame.new(layerDef.spawnPosition)
                return true
            end
        end
    end
    return false
end

-- VISUAL TRANSFORMATION — character gets more epic with each level
function ProgressionService:TransformCharacter(player: Player, levelIndex: number): ()
    local character = player.Character
    if not character then return end

    local visuals = LEVEL_VISUALS[levelIndex]
    if not visuals then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not hrp then return end

    -- Update halo size
    local halo = character:FindFirstChild("PlayerHalo")
    if halo then
        halo.Size = Vector3.new(0.3, visuals.haloSize, visuals.haloSize)
        halo.Color = visuals.wingColor
        local haloLight = halo:FindFirstChildWhichIsA("PointLight")
        if haloLight then
            haloLight.Brightness = visuals.glowBrightness
            haloLight.Range = visuals.haloSize * 4
            haloLight.Color = visuals.wingColor
        end
    end

    -- Update or create wing trail
    local trail = hrp:FindFirstChild("WingTrail")
    if trail then
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, visuals.wingColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 100)),
        })
        trail.Lifetime = 0.5 + levelIndex * 0.15
    end

    -- Add/update AURA (growing glow sphere around character)
    local aura = character:FindFirstChild("AngelAura")
    if visuals.auraSize > 0 then
        if not aura then
            aura = Instance.new("Part")
            aura.Name = "AngelAura"
            aura.Shape = Enum.PartType.Ball
            aura.Anchored = false
            aura.CanCollide = false
            aura.Massless = true
            aura.Material = Enum.Material.ForceField
            aura.Transparency = 0.8

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = hrp
            weld.Part1 = aura
            weld.Parent = aura

            aura.CFrame = hrp.CFrame
            aura.Parent = character
        end
        aura.Size = Vector3.new(visuals.auraSize, visuals.auraSize, visuals.auraSize)
        aura.Color = visuals.wingColor

        local auraLight = aura:FindFirstChildWhichIsA("PointLight")
        if not auraLight then
            auraLight = Instance.new("PointLight")
            auraLight.Parent = aura
        end
        auraLight.Color = visuals.wingColor
        auraLight.Brightness = visuals.glowBrightness * 0.5
        auraLight.Range = visuals.auraSize * 3
    end

    -- Boost movement with each level
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 28 + levelIndex * 4  -- gets faster each level
        humanoid.JumpPower = 70 + levelIndex * 8  -- jumps higher each level
    end

    -- ARCHANGEL special: permanent flight unlocked
    if levelIndex >= 6 then
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            ServerMessage:FireClient(player, {
                type = "info",
                message = "YOU ARE AN ARCHANGEL. Unlimited flight unlocked. The Cloud answers to you.",
            })
        end
    end

    print("[Progression] " .. player.Name .. " transformed to level " .. levelIndex .. " — "
        .. Layers.ANGEL_LEVELS[levelIndex])
end

return ProgressionService
