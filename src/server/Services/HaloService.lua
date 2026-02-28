--[[
    HaloService.lua — Cosmetic currency (Halos) earn/spend/balance
    Knit Service

    Halos are the COSMETIC currency. They buy wing skins, cloud base items, emotes.
    Purchasable via Robux. NEVER overlap with Motes (progression currency).

    See docs/halo_economy.md and src/shared/Config/Economy.lua for rates.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local HaloService = Knit.CreateService({
    Name = "HaloService",
    Client = {
        HaloChanged = Knit.CreateSignal(),
    },
})

type HaloData = {
    balance: number,
    lifetimeEarned: number,
    lastDailyLogin: number,
    streakDay: number,
}

local DataService
local Economy

-- Daily earn tracking (anti-exploit)
local dailyEarned: { [number]: number } = {}
local MAX_DAILY_EARN = 500

function HaloService:KnitInit()
    Economy = require(ReplicatedStorage.Config.Economy)
end

function HaloService:KnitStart()
    DataService = Knit.GetService("DataService")
end

function HaloService:AddHalos(player: Player, amount: number, source: string): boolean
    assert(amount > 0, "Halo amount must be positive")

    -- Anti-exploit daily cap
    local userId = player.UserId
    dailyEarned[userId] = (dailyEarned[userId] or 0) + amount
    if dailyEarned[userId] > MAX_DAILY_EARN and source ~= "robux_purchase" then
        warn("[HaloService] Daily earn cap reached for " .. player.Name)
        return false
    end

    local data = DataService:GetData(player)
    if not data then return false end

    data.halos = (data.halos or 0) + amount
    self.Client.HaloChanged:Fire(player, {
        balance = data.halos,
        change = amount,
        source = source,
    })

    print("[HaloService] " .. player.Name .. " +" .. amount .. " Halos (" .. source .. ") → " .. data.halos)
    return true
end

function HaloService:SpendHalos(player: Player, amount: number, itemId: string): boolean
    assert(amount > 0, "Spend amount must be positive")

    local data = DataService:GetData(player)
    if not data then return false end

    if (data.halos or 0) < amount then
        return false
    end

    data.halos = data.halos - amount
    self.Client.HaloChanged:Fire(player, {
        balance = data.halos,
        change = -amount,
        source = "purchase:" .. itemId,
    })

    print("[HaloService] " .. player.Name .. " -" .. amount .. " Halos (buy:" .. itemId .. ") → " .. data.halos)
    return true
end

function HaloService:_getBalance(player: Player): number
    local data = DataService:GetData(player)
    return data and (data.halos or 0) or 0
end

function HaloService:CanAfford(player: Player, amount: number): boolean
    return self:_getBalance(player) >= amount
end

function HaloService:OnDailyLogin(player: Player)
    local loginHalos = Economy.DailyActivities[1].halos  -- daily_login = 10
    self:AddHalos(player, loginHalos, "daily_login")
end

function HaloService:OnStreakBonus(player: Player, streakDay: number)
    if streakDay == 7 then
        local bonusHalos = Economy.DailyActivities[2].halos  -- streak_bonus = 50
        self:AddHalos(player, bonusHalos, "streak_bonus_7day")
    end
end

function HaloService:OnRobuxPurchase(player: Player, bundleId: string)
    for _, bundle in ipairs(Economy.RobuxBundles) do
        if bundle.id == bundleId then
            self:AddHalos(player, bundle.halos, "robux_purchase")
            return true
        end
    end
    return false
end

function HaloService:ResetDailyTracking(player: Player)
    dailyEarned[player.UserId] = 0
end

function HaloService:RemovePlayer(player: Player)
    dailyEarned[player.UserId] = nil
end

-- Client-callable methods
function HaloService.Client:GetBalance(player: Player): number
    return self.Server:_getBalance(player)
end

return HaloService
