--[[
    BlessingService.lua — Blessing Bluffs pay-it-forward mechanic (Knit Service)
    Cost: 2 Motes + 20 Stamina
    Recipient: 30% stamina + 1 Mote + notification
    Chain Blessings: if recipient blesses within 5 min, both senders get bonus Mote
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Layers = require(ReplicatedStorage.Config.Layers)

local BlessingService = Knit.CreateService({
    Name = "BlessingService",
    Client = {
        BlessingReceived = Knit.CreateSignal(),
        BlessingChainUpdate = Knit.CreateSignal(),
    },
})

-- Active blessing chain tracking
local ActiveChains: { [number]: { senderUserId: number, timestamp: number, chainLength: number } } = {}

-- Community board stats (per server session)
local ServerStats = {
    longestChainThisWeek = 0,
    mostBlessingsThisWeek = {} :: { [number]: number },
    currentChainLength = 0,
}

-- Constants
local BLESSING_MOTE_COST = 2
local BLESSING_STAMINA_COST = 20
local BLESSING_MOTE_REWARD = 1
local CHAIN_WINDOW = 5 * 60 -- 5 minutes
local CHAIN_BONUS_MOTES = 1

-- Service references (resolved in KnitStart)
local DataService
local MoteService
local WingService

function BlessingService:KnitInit(): ()
    -- Nothing to initialize before other services are ready
end

function BlessingService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")
    WingService = Knit.GetService("WingService")
end

function BlessingService.Client:SendBlessing(player: Player): boolean
    return self.Server:SendBlessing(player)
end

function BlessingService:SendBlessing(sender: Player): boolean
    local senderData = DataService:GetData(sender)
    if not senderData then
        return false
    end

    -- Check costs
    if senderData.motes < BLESSING_MOTE_COST then
        return false
    end

    local currentStamina = WingService:GetStamina(sender)
    if currentStamina < BLESSING_STAMINA_COST then
        return false
    end

    -- Deduct costs
    MoteService:AwardMotes(sender, -BLESSING_MOTE_COST, "blessing_sent")
    WingService:DrainStamina(sender, "blessing", BLESSING_STAMINA_COST)

    -- Find a random recipient on a lower layer
    local senderLevel: number = Layers.GetLevelIndex(senderData.angelLevel)
    local candidates: { Player } = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= sender then
            local playerData = DataService:GetData(player)
            if playerData then
                local playerLevel: number = Layers.GetLevelIndex(playerData.angelLevel)
                if playerLevel <= senderLevel then
                    table.insert(candidates, player)
                end
            end
        end
    end

    -- If no lower-layer players, pick any other player
    if #candidates == 0 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= sender then
                table.insert(candidates, player)
            end
        end
    end

    if #candidates == 0 then
        -- No other players; refund
        MoteService:AwardMotes(sender, BLESSING_MOTE_COST, "blessing_refund")
        return false
    end

    -- Select random recipient
    local recipient: Player = candidates[math.random(#candidates)]

    -- Apply blessing to recipient
    WingService:ApplyBlessingBoost(recipient)
    MoteService:AwardMotes(recipient, BLESSING_MOTE_REWARD, "blessing_received")

    -- Update stats
    senderData.blessingsGiven = (senderData.blessingsGiven or 0) + 1
    local recipientData = DataService:GetData(recipient)
    if recipientData then
        recipientData.blessingsReceived = (recipientData.blessingsReceived or 0) + 1
    end

    -- Notify recipient
    self.Client.BlessingReceived:Fire(recipient, {
        senderName = sender.Name,
        message = sender.Name .. " sent you a Blessing! You are not alone.",
        moteReward = BLESSING_MOTE_REWARD,
    })

    -- Check for chain blessing
    local now: number = os.time()
    local chainInfo = ActiveChains[sender.UserId]
    if chainInfo and (now - chainInfo.timestamp) <= CHAIN_WINDOW then
        -- This sender was recently blessed and is now passing it on — chain!
        local chainLength: number = (chainInfo.chainLength or 1) + 1

        -- Bonus mote to both the original sender and current sender
        local originalSender: Player? = Players:GetPlayerByUserId(chainInfo.senderUserId)
        if originalSender then
            MoteService:AwardMotes(originalSender, CHAIN_BONUS_MOTES, "blessing_chain_bonus")
            self.Client.BlessingChainUpdate:Fire(originalSender, {
                message = "Your blessing started a chain! Bonus Mote earned.",
                chainLength = chainLength,
            })
        end
        MoteService:AwardMotes(sender, CHAIN_BONUS_MOTES, "blessing_chain_bonus")
        self.Client.BlessingChainUpdate:Fire(sender, {
            message = "You extended a blessing chain! Bonus Mote earned.",
            chainLength = chainLength,
        })

        -- Track chain for recipient (they might continue it)
        ActiveChains[recipient.UserId] = {
            senderUserId = sender.UserId,
            timestamp = now,
            chainLength = chainLength,
        }

        -- Update longest chain
        if chainLength > ServerStats.longestChainThisWeek then
            ServerStats.longestChainThisWeek = chainLength
        end

        -- Update player's longest chain record
        if chainLength > (senderData.longestBlessingChain or 0) then
            senderData.longestBlessingChain = chainLength
        end
    else
        -- New chain starts
        ActiveChains[recipient.UserId] = {
            senderUserId = sender.UserId,
            timestamp = now,
            chainLength = 1,
        }
    end

    -- Track community stats
    ServerStats.mostBlessingsThisWeek[sender.UserId] = (ServerStats.mostBlessingsThisWeek[sender.UserId] or 0) + 1
    DataService:IncrementCommunityStat("total_blessings", 1)

    -- Update quest progress
    local QuestService = Knit.GetService("QuestService")
    pcall(QuestService.OnBlessingGiven, QuestService, sender)

    -- Check progression after mote changes
    local ProgressionService = Knit.GetService("ProgressionService")
    pcall(ProgressionService.OnMotesChanged, ProgressionService, sender)
    pcall(ProgressionService.OnMotesChanged, ProgressionService, recipient)

    return true
end

function BlessingService:GetCommunityBoard(): { [string]: any }
    -- Build community board (communal, not competitive)
    local blessingsLeader: { name: string, count: number } = { name = "No one yet", count = 0 }
    for userId, count in pairs(ServerStats.mostBlessingsThisWeek) do
        if count > blessingsLeader.count then
            local player: Player? = Players:GetPlayerByUserId(userId)
            blessingsLeader = {
                name = if player then player.Name else "Unknown",
                count = count,
            }
        end
    end

    return {
        longestChain = ServerStats.longestChainThisWeek,
        mostBlessings = blessingsLeader,
        -- No individual Mote leaderboard — intentionally communal
    }
end

function BlessingService.Client:GetCommunityBoard(player: Player): { [string]: any }
    return self.Server:GetCommunityBoard()
end

-- Cleanup expired chains periodically
function BlessingService:CleanupChains(): ()
    local now: number = os.time()
    for userId, info in pairs(ActiveChains) do
        if now - info.timestamp > CHAIN_WINDOW * 2 then
            ActiveChains[userId] = nil
        end
    end
end

return BlessingService
