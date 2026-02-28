--[[
    ShopService.lua — Server-side cosmetic shop with Developer Product integration (Knit)
    Handles purchase validation, cosmetic granting, and equipping
    All purchases are cosmetic only — NEVER sells Motes, stamina, fragments, or progression
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cosmetics = require(ReplicatedStorage.Config.Cosmetics)
local Layers = require(ReplicatedStorage.Config.Layers)

local ShopService = Knit.CreateService({
    Name = "ShopService",
    Client = {
        ShopData = Knit.CreateSignal(),
        ShopRequest = Knit.CreateSignal(),
        ShopResult = Knit.CreateSignal(),
    },
})

-- Developer Product IDs — create these in the Roblox Creator Dashboard
-- Map cosmetic item IDs to their Developer Product IDs
-- Set these to 0 until products are created in the dashboard
local PRODUCT_IDS: { [string]: number } = {
    wings_crystal = 0,
    wings_nebula = 0,
    wings_flame = 0,
    wings_nature = 0,
    wings_aurora = 0,
    trail_stardust = 0,
    trail_cyan_ribbon = 0,
    trail_rainbow = 0,
    emote_meditation = 0,
    emote_celebration = 0,
    cloud_crystal = 0,
    cloud_golden = 0,
    glow_cyan = 0,
    glow_gold = 0,
    starter_pack = 0,
}

-- Reverse lookup: product ID -> item ID
local productToItem: { [number]: string } = {}

-- Reference to DataService (resolved in KnitStart)
local DataService

function ShopService:KnitInit(): ()
    -- Build reverse lookup
    for itemId, productId in pairs(PRODUCT_IDS) do
        if productId > 0 then
            productToItem[productId] = itemId
        end
    end

    -- Handle shop requests from client via Knit signal
    self.Client.ShopRequest:Connect(function(player: Player, action: string, data: any)
        if action == "catalog" then
            self:SendCatalog(player)
        elseif action == "buy" then
            self:HandlePurchase(player, data)
        elseif action == "equip" then
            self:HandleEquip(player, data)
        elseif action == "unequip" then
            self:HandleUnequip(player, data)
        end
    end)

    -- MarketplaceService callback for Developer Product receipts
    MarketplaceService.ProcessReceipt = function(receiptInfo)
        return self:ProcessReceipt(receiptInfo)
    end

    print("[ShopService] Shop system initialized")
end

function ShopService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
end

function ShopService:SendCatalog(player: Player): ()
    local data = DataService:GetData(player)
    if not data then return end

    local catalog = {}
    for _, item in ipairs(Cosmetics.Items) do
        table.insert(catalog, {
            id = item.id,
            name = item.name,
            category = item.category,
            price = item.price,
            description = item.description,
            owned = data.ownedCosmetics[item.id] == true,
            earned = item.earned or false,
            requiredLayer = item.requiredLayer,
            color = item.color and { item.color.R * 255, item.color.G * 255, item.color.B * 255 },
        })
    end

    self.Client.ShopData:Fire(player, {
        catalog = catalog,
        equipped = data.equippedCosmetics or {},
        robux = true,  -- flag that shop uses Robux (Developer Products)
    })
end

function ShopService:HandlePurchase(player: Player, itemId: string): ()
    if not itemId then return end

    local item = Cosmetics.GetItem(itemId)
    if not item then
        self.Client.ShopResult:Fire(player, {
            success = false,
            message = "Item not found.",
        })
        return
    end

    local data = DataService:GetData(player)
    if not data then return end

    -- Already owned?
    if data.ownedCosmetics[itemId] then
        self.Client.ShopResult:Fire(player, {
            success = false,
            message = "You already own " .. item.name .. "!",
        })
        return
    end

    -- Earned items can't be purchased
    if item.earned then
        self.Client.ShopResult:Fire(player, {
            success = false,
            message = item.name .. " can only be earned, not purchased.",
        })
        return
    end

    -- Layer requirement check
    if item.requiredLayer then
        local layerIndex = data.layerIndex or 1
        if layerIndex < item.requiredLayer then
            local requiredLayer = Layers.GetLayerByIndex(item.requiredLayer)
            local layerName = requiredLayer and requiredLayer.name or ("Layer " .. item.requiredLayer)
            self.Client.ShopResult:Fire(player, {
                success = false,
                message = "Requires access to " .. layerName .. ".",
            })
            return
        end
    end

    -- Prompt Robux purchase via Developer Product
    local productId = PRODUCT_IDS[itemId]
    if productId and productId > 0 then
        MarketplaceService:PromptProductPurchase(player, productId)
    else
        -- Products not configured yet — grant for free during development
        self:GrantItem(player, itemId)
        self.Client.ShopResult:Fire(player, {
            success = true,
            message = item.name .. " unlocked! (Dev mode — free)",
            itemId = itemId,
        })
    end
end

function ShopService:ProcessReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local itemId = productToItem[receiptInfo.ProductId]
    if not itemId then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local item = Cosmetics.GetItem(itemId)
    local success = self:GrantItem(player, itemId)

    if success then
        -- Handle starter pack (grants multiple items)
        if item and item.includes then
            for _, includedId in ipairs(item.includes) do
                self:GrantItem(player, includedId)
            end
        end

        self.Client.ShopResult:Fire(player, {
            success = true,
            message = (item and item.name or itemId) .. " purchased!",
            itemId = itemId,
        })
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

function ShopService:GrantItem(player: Player, itemId: string): boolean
    local data = DataService:GetData(player)
    if not data then return false end

    data.ownedCosmetics[itemId] = true
    print("[ShopService] Granted " .. itemId .. " to " .. player.Name)
    return true
end

function ShopService:HandleEquip(player: Player, itemId: string): ()
    local data = DataService:GetData(player)
    if not data then return end

    if not data.ownedCosmetics[itemId] then
        self.Client.ShopResult:Fire(player, {
            success = false,
            message = "You don't own this item.",
        })
        return
    end

    local item = Cosmetics.GetItem(itemId)
    if not item then return end

    -- Initialize equipped table if needed
    if not data.equippedCosmetics then
        data.equippedCosmetics = {}
    end

    -- Equip in the correct slot (one per category)
    data.equippedCosmetics[item.category] = itemId

    self.Client.ShopResult:Fire(player, {
        success = true,
        message = item.name .. " equipped!",
        equipped = data.equippedCosmetics,
    })

    -- Apply visual change
    self:ApplyCosmetic(player, item)
end

function ShopService:HandleUnequip(player: Player, itemId: string): ()
    local data = DataService:GetData(player)
    if not data or not data.equippedCosmetics then return end

    local item = Cosmetics.GetItem(itemId)
    if not item then return end

    if data.equippedCosmetics[item.category] == itemId then
        data.equippedCosmetics[item.category] = nil

        self.Client.ShopResult:Fire(player, {
            success = true,
            message = item.name .. " unequipped.",
            equipped = data.equippedCosmetics,
        })

        self:RemoveCosmetic(player, item)
    end
end

function ShopService:ApplyCosmetic(player: Player, item: any): ()
    local character = player.Character
    if not character then return end

    if item.category == "WingSkins" then
        -- Update wing color/material
        local wing = character:FindFirstChild("AngelWing")
        if wing and item.color then
            wing.Color = item.color
        end

    elseif item.category == "TrailEffects" then
        -- Create trail attachment
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Remove existing trail
            local existing = hrp:FindFirstChild("CosmeticTrail")
            if existing then existing:Destroy() end

            local attachment0 = Instance.new("Attachment")
            attachment0.Name = "TrailStart"
            attachment0.Position = Vector3.new(0, 0, 1)
            attachment0.Parent = hrp

            local attachment1 = Instance.new("Attachment")
            attachment1.Name = "TrailEnd"
            attachment1.Position = Vector3.new(0, 0, -1)
            attachment1.Parent = hrp

            local trail = Instance.new("Trail")
            trail.Name = "CosmeticTrail"
            trail.Attachment0 = attachment0
            trail.Attachment1 = attachment1
            trail.Lifetime = 1.5
            trail.MinLength = 0.1
            trail.FaceCamera = true
            trail.Color = ColorSequence.new(item.color or Color3.fromRGB(255, 255, 255))
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.3),
                NumberSequenceKeypoint.new(1, 1),
            })
            trail.Parent = hrp
        end

    elseif item.category == "NameGlow" then
        -- Billboard glow effect on name
        local head = character:FindFirstChild("Head")
        if head and item.color then
            local existing = head:FindFirstChild("NameGlow")
            if existing then existing:Destroy() end

            local glow = Instance.new("BillboardGui")
            glow.Name = "NameGlow"
            glow.Size = UDim2.new(5, 0, 1, 0)
            glow.StudsOffset = Vector3.new(0, 2.5, 0)
            glow.Adornee = head
            glow.AlwaysOnTop = false
            glow.Parent = head

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = player.Name
            label.TextColor3 = item.color
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = glow
        end
    end
end

function ShopService:RemoveCosmetic(player: Player, item: any): ()
    local character = player.Character
    if not character then return end

    if item.category == "TrailEffects" then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local trail = hrp:FindFirstChild("CosmeticTrail")
            if trail then trail:Destroy() end
            local ts = hrp:FindFirstChild("TrailStart")
            if ts then ts:Destroy() end
            local te = hrp:FindFirstChild("TrailEnd")
            if te then te:Destroy() end
        end

    elseif item.category == "NameGlow" then
        local head = character:FindFirstChild("Head")
        if head then
            local glow = head:FindFirstChild("NameGlow")
            if glow then glow:Destroy() end
        end
    end
end

-- Re-apply equipped cosmetics when character respawns
function ShopService:OnCharacterAdded(player: Player, character: Model): ()
    local data = DataService:GetData(player)
    if not data or not data.equippedCosmetics then return end

    task.wait(1)  -- let character fully load

    for _, itemId in pairs(data.equippedCosmetics) do
        local item = Cosmetics.GetItem(itemId)
        if item then
            self:ApplyCosmetic(player, item)
        end
    end
end

return ShopService
