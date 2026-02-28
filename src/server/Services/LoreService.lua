--[[
    LoreService.lua — Lore Fragment collection and codex management (Knit Service)
    65 fragments across 7 categories telling the story of Angel's fall
    Server tracks collection; client renders codex constellation map
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fragments = require(ReplicatedStorage.Config.Fragments)
local Layers = require(ReplicatedStorage.Config.Layers)

local LoreService = Knit.CreateService({
    Name = "LoreService",
    Client = {
        FragmentCollected = Knit.CreateSignal(),
        CodexData = Knit.CreateSignal(),
    },
})

-- Service references (resolved in KnitStart)
local DataService

-- Category colors used for fragments
local CATEGORY_COLORS: { [string]: Color3 } = {
    Decision = Color3.fromRGB(255, 215, 0),      -- gold
    Emotion = Color3.fromRGB(0, 212, 255),        -- cyan
    Relationship = Color3.fromRGB(255, 150, 200), -- pink
    Strength = Color3.fromRGB(255, 100, 50),      -- orange
    Suffering = Color3.fromRGB(120, 50, 180),     -- purple
    Guardian = Color3.fromRGB(100, 255, 100),     -- green
    Angel = Color3.fromRGB(255, 255, 255),        -- white (special glow)
}

function LoreService:KnitInit(): ()
    -- Nothing to initialize before other services are ready
end

function LoreService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
end

function LoreService.Client:CollectFragment(player: Player, fragmentId: string): boolean
    return self.Server:TryCollectFragment(player, fragmentId)
end

function LoreService.Client:RequestCodexData(player: Player): ()
    self.Server:SendCodexData(player)
end

function LoreService:TryCollectFragment(player: Player, fragmentId: string): boolean
    local data = DataService:GetData(player)
    if not data then
        return false
    end

    -- Already collected?
    if data.collectedFragments[fragmentId] then
        return false
    end

    -- Fragment exists?
    local fragment = Fragments.GetFragment(fragmentId)
    if not fragment then
        return false
    end

    -- Player on correct layer or higher?
    local playerLayerIndex: number = data.layerIndex or 1
    if playerLayerIndex < fragment.layer then
        return false
    end

    -- Angel fragments have special requirements (checked elsewhere)
    if fragment.category == "Angel" then
        if not self:CheckAngelRequirement(player, fragment) then
            return false
        end
    end

    -- Collect!
    data.collectedFragments[fragmentId] = true

    -- Update quest progress
    local QuestService = Knit.GetService("QuestService")
    pcall(QuestService.OnFragmentCollected, QuestService, player)

    -- Notify client with full fragment data
    self.Client.FragmentCollected:Fire(player, {
        id = fragment.id,
        name = fragment.name,
        category = fragment.category,
        wisdom = fragment.wisdom,
        loreText = fragment.loreText,
        totalCollected = self:GetCollectedCount(player),
        totalFragments = Fragments.TOTAL_COUNT,
    })

    return true
end

function LoreService:CheckAngelRequirement(player: Player, fragment: { [string]: any }): boolean
    local data = DataService:GetData(player)
    if not data then
        return false
    end

    if fragment.id == "angel_01" then
        -- Angel's Wing: must have at least 1 fragment from each non-Guardian, non-Angel category
        local categories: { [string]: boolean } = {
            Decision = false,
            Emotion = false,
            Relationship = false,
            Strength = false,
            Suffering = false,
        }
        for fragId, _ in pairs(data.collectedFragments) do
            local frag = Fragments.GetFragment(fragId)
            if frag and categories[frag.category] ~= nil then
                categories[frag.category] = true
            end
        end
        for _, has in pairs(categories) do
            if not has then
                return false
            end
        end
        return true

    elseif fragment.id == "angel_02" then
        -- Angel's Voice: during a blessing chain of 5+
        -- This is checked by BlessingService and triggers collection
        return false -- must be triggered externally

    elseif fragment.id == "angel_03" then
        -- Angel's Heart: 4 Angel-rank players at Cloud Core with emote sequence
        -- This is checked by a special interaction in Layer 6
        return false -- must be triggered externally

    elseif fragment.id == "angel_04" then
        -- Angel's Light: enter Empyrean with all other 60 fragments at server dawn
        local count: number = self:GetCollectedCount(player)
        return count >= 60 -- all non-Angel fragments

    elseif fragment.id == "angel_05" then
        -- Angel's Promise: Angel rank + helped 20+ Newborns
        return data.angelLevel == "Angel" and (data.newbornsHelped or 0) >= 20
    end

    return false
end

function LoreService:GetCollectedCount(player: Player): number
    local data = DataService:GetData(player)
    if not data then
        return 0
    end

    local count: number = 0
    for _ in pairs(data.collectedFragments) do
        count = count + 1
    end
    return count
end

function LoreService:GetCollectedFragments(player: Player): { string }
    local data = DataService:GetData(player)
    if not data then
        return {}
    end

    local collected: { string } = {}
    for fragId, _ in pairs(data.collectedFragments) do
        table.insert(collected, fragId)
    end
    return collected
end

function LoreService:SendCodexData(player: Player): ()
    local data = DataService:GetData(player)
    if not data then
        return
    end

    -- Build codex: all fragments with collected status
    local codex: { { [string]: any } } = {}
    for _, fragment in ipairs(Fragments.Definitions) do
        local entry: { [string]: any } = {
            id = fragment.id,
            name = fragment.name,
            category = fragment.category,
            layer = fragment.layer,
            collected = data.collectedFragments[fragment.id] == true,
        }

        -- Only send wisdom/lore text if collected
        if entry.collected then
            entry.wisdom = fragment.wisdom
            entry.loreText = fragment.loreText
        end

        table.insert(codex, entry)
    end

    self.Client.CodexData:Fire(player, {
        codex = codex,
        totalCollected = self:GetCollectedCount(player),
        totalFragments = Fragments.TOTAL_COUNT,
        categoryProgress = self:GetCategoryProgress(player),
    })
end

function LoreService:GetCategoryProgress(player: Player): { [string]: { collected: number, total: number } }
    local data = DataService:GetData(player)
    if not data then
        return {}
    end

    local progress: { [string]: { collected: number, total: number } } = {}
    for category, frags in pairs(Fragments.ByCategory) do
        local collected: number = 0
        for _, frag in ipairs(frags) do
            if data.collectedFragments[frag.id] then
                collected = collected + 1
            end
        end
        progress[category] = {
            collected = collected,
            total = #frags,
        }
    end
    return progress
end

-- Spawn fragment interaction points in a layer — pulsing, glowing, with particles
function LoreService:SpawnFragmentPoints(layerFolder: Folder, layerIndex: number): ()
    local layerFragments = Fragments.GetByLayer(layerIndex)
    local spread: number = 180

    for i, fragment in ipairs(layerFragments) do
        local layerDef = Layers.GetLayerByIndex(layerIndex)
        local heightMin: number = layerDef.heightRange.min
        local heightMax: number = layerDef.heightRange.max

        local fragColor: Color3 = CATEGORY_COLORS[fragment.category] or Color3.fromRGB(200, 200, 200)

        local point = Instance.new("Part")
        point.Name = "FragmentPoint_" .. fragment.id
        point.Shape = Enum.PartType.Ball
        point.Size = Vector3.new(2.5, 2.5, 2.5)
        point.Position = Vector3.new(
            math.random(-spread, spread),
            math.random(heightMin + 20, heightMax - 20),
            math.random(-spread, spread)
        )
        point.Anchored = true
        point.CanCollide = false
        point.Material = Enum.Material.ForceField
        point.Transparency = 0.15
        point.Color = fragColor

        -- Inner core (brighter, smaller)
        local core = Instance.new("Part")
        core.Name = "FragmentCore"
        core.Shape = Enum.PartType.Ball
        core.Size = Vector3.new(1.2, 1.2, 1.2)
        core.Position = point.Position
        core.Anchored = true
        core.CanCollide = false
        core.Material = Enum.Material.Neon
        core.Color = fragColor
        core.Transparency = 0.1
        core.Parent = layerFolder

        -- Point light (colored, visible from distance)
        local light = Instance.new("PointLight")
        light.Color = fragColor
        light.Brightness = 2
        light.Range = 20
        light.Parent = point

        -- Orbiting sparkle particles
        local sparkle = Instance.new("ParticleEmitter")
        sparkle.Name = "FragSparkle"
        sparkle.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, fragColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        })
        sparkle.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0),
        })
        sparkle.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        sparkle.Lifetime = NumberRange.new(1, 2.5)
        sparkle.Rate = 5
        sparkle.Speed = NumberRange.new(0.5, 1.5)
        sparkle.SpreadAngle = Vector2.new(360, 360)
        sparkle.LightEmission = 1
        sparkle.Parent = point

        -- Angel fragments get extra intense glow
        if fragment.category == "Angel" then
            light.Brightness = 4
            light.Range = 35
            sparkle.Rate = 12

            -- Gold halo ring around Angel fragments
            local angelRing = Instance.new("Part")
            angelRing.Name = "AngelRing"
            angelRing.Shape = Enum.PartType.Cylinder
            angelRing.Size = Vector3.new(0.3, 5, 5)
            angelRing.Position = point.Position
            angelRing.Orientation = Vector3.new(0, 0, 90)
            angelRing.Anchored = true
            angelRing.CanCollide = false
            angelRing.Material = Enum.Material.Neon
            angelRing.Color = Color3.fromRGB(255, 215, 100)
            angelRing.Transparency = 0.4
            angelRing.Parent = layerFolder
        end

        local fragIdValue = Instance.new("StringValue")
        fragIdValue.Name = "FragmentId"
        fragIdValue.Value = fragment.id
        fragIdValue.Parent = point

        -- Rotation + pulsing animation
        task.spawn(function()
            local offset: number = math.random() * math.pi * 2
            while point and point.Parent do
                local t: number = tick()
                point.Orientation = point.Orientation + Vector3.new(0, 1.5, 0)

                -- Size pulse (breathe in/out)
                local pulse: number = 2.5 + math.sin(t * 2 + offset) * 0.5
                point.Size = Vector3.new(pulse, pulse, pulse)
                if core and core.Parent then
                    core.Position = point.Position
                    local corePulse: number = 1.2 + math.sin(t * 3 + offset) * 0.3
                    core.Size = Vector3.new(corePulse, corePulse, corePulse)
                end

                task.wait(0.03)
            end
        end)

        -- Touch detection
        point.Touched:Connect(function(hit: BasePart)
            local character = hit.Parent
            local player: Player? = Players:GetPlayerFromCharacter(character)
            if player then
                self:TryCollectFragment(player, fragment.id)
            end
        end)

        point.Parent = layerFolder
    end
end

return LoreService
