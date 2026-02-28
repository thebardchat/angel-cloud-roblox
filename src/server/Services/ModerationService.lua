--[[
    ModerationService.lua — Chat filter + safety systems
    Knit Service — COPPA/CARU compliant moderation

    Safety-first: anonymous usernames in sensitive zones,
    moderated chat / pre-set phrases for younger players,
    age-appropriate crisis resources (non-alarming).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local ModerationService = Knit.CreateService({
    Name = "ModerationService",
    Client = {
        ModerationWarning = Knit.CreateSignal(),
    },
})

local MAX_CHAT_MESSAGE_LENGTH = 200
local REPORT_COOLDOWN = 60
local lastReportTime: { [number]: number } = {}

function ModerationService:KnitInit()
    print("[ModerationService] Initialized")
end

function ModerationService:KnitStart()
end

function ModerationService:FilterText(player: Player, text: string): string
    if #text > MAX_CHAT_MESSAGE_LENGTH then
        text = string.sub(text, 1, MAX_CHAT_MESSAGE_LENGTH)
    end

    local success, result = pcall(function()
        return TextService:FilterStringAsync(text, player.UserId)
    end)

    if success and result then
        local filteredOk, filtered = pcall(function()
            return result:GetNonChatStringForBroadcastAsync()
        end)
        if filteredOk then
            return filtered
        end
    end

    return string.rep("#", #text)
end

function ModerationService:CanReport(player: Player): boolean
    local now = os.time()
    local last = lastReportTime[player.UserId] or 0
    return (now - last) >= REPORT_COOLDOWN
end

function ModerationService:SubmitReport(player: Player, targetUserId: number, reason: string): boolean
    if not self:CanReport(player) then
        return false
    end
    lastReportTime[player.UserId] = os.time()
    warn("[ModerationService] Report from " .. player.Name .. " about UserId " .. targetUserId .. ": " .. reason)
    return true
end

function ModerationService:RemovePlayer(player: Player)
    lastReportTime[player.UserId] = nil
end

return ModerationService
