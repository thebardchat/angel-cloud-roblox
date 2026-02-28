--[[
    AnalyticsService.lua — Playtime/engagement tracking
    Knit Service — tracks player behavior for economy health monitoring

    Tracks: session duration, motes earned/spent, items purchased,
    layers visited, quests completed, blessings given/received.
    Used for monthly economy health reviews per halo_economy.md.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local AnalyticsService = Knit.CreateService({
    Name = "AnalyticsService",
    Client = {},
})

local sessionData: { [number]: { [string]: any } } = {}

function AnalyticsService:KnitInit()
    print("[AnalyticsService] Initialized")
end

function AnalyticsService:KnitStart()
end

function AnalyticsService:TrackEvent(player: Player, eventName: string, data: { [string]: any }?)
    if not sessionData[player.UserId] then
        sessionData[player.UserId] = { events = {} }
    end
    table.insert(sessionData[player.UserId].events, {
        event = eventName,
        time = os.time(),
        data = data,
    })
end

function AnalyticsService:GetSessionEvents(player: Player): { any }
    local session = sessionData[player.UserId]
    return session and session.events or {}
end

function AnalyticsService:RemovePlayer(player: Player)
    sessionData[player.UserId] = nil
end

return AnalyticsService
