--[[
    HALTService.lua — HALT (Hungry/Angry/Lonely/Tired) Anti-Burnout System
    Migrated from StaminaSystem.lua (HALT portion)

    After 45 minutes of continuous play, recovery rates are halved for 5 minutes.
    Players who go AFK for 2 minutes during HALT receive 5 bonus motes and their
    session timer resets.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HALTService = Knit.CreateService({
    Name = "HALTService",
    Client = {
        HALTWarning = Knit.CreateSignal(),
        HALTRest = Knit.CreateSignal(),
    },
})

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local HALT_THRESHOLD = 45 * 60            -- 45 minutes in seconds
local HALT_SLOWDOWN_DURATION = 5 * 60     -- 5 minutes slowdown
local HALT_AFK_REST_DURATION = 2 * 60     -- 2 minutes AFK for rest bonus
local HALT_AFK_REST_MOTES = 5             -- motes awarded for resting

---------------------------------------------------------------------------
-- Per-player session tracking
---------------------------------------------------------------------------
type HALTState = {
    sessionPlayStart: number,
    haltTriggered: boolean,
    haltSlowdownActive: boolean,
    haltSlowdownExpires: number,
    lastAFKCheck: number,
    isAFK: boolean,
    afkStart: number,
}

local HALTStates: { [number]: HALTState } = {}

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------

function HALTService:InitPlayer(player: Player): ()
    HALTStates[player.UserId] = {
        sessionPlayStart = os.time(),
        haltTriggered = false,
        haltSlowdownActive = false,
        haltSlowdownExpires = 0,
        lastAFKCheck = os.time(),
        isAFK = false,
        afkStart = 0,
    }
end

function HALTService:RemovePlayer(player: Player): ()
    HALTStates[player.UserId] = nil
end

---------------------------------------------------------------------------
-- HALT multiplier — used by WingService to reduce recovery rates
-- Returns 1.0 normally, 0.5 during HALT slowdown
---------------------------------------------------------------------------

function HALTService:GetHALTMultiplier(player: Player): number
    local state = HALTStates[player.UserId]
    if not state then
        return 1
    end

    if state.haltSlowdownActive then
        local now = os.time()
        if now < state.haltSlowdownExpires then
            return 0.5
        else
            state.haltSlowdownActive = false
        end
    end

    return 1
end

---------------------------------------------------------------------------
-- AFK state setter (called by input detection systems)
---------------------------------------------------------------------------

function HALTService:SetAFK(player: Player, isAFK: boolean): ()
    local state = HALTStates[player.UserId]
    if not state then return end

    if isAFK and not state.isAFK then
        state.isAFK = true
        state.afkStart = os.time()
    elseif not isAFK and state.isAFK then
        state.isAFK = false
        state.afkStart = 0
    end
end

---------------------------------------------------------------------------
-- Main update tick (called every Heartbeat)
---------------------------------------------------------------------------

function HALTService:Update(dt: number): ()
    local now = os.time()

    for userId, state in pairs(HALTStates) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            continue
        end

        -- HALT check: 45 minutes continuous play
        if not state.haltTriggered then
            local playTime = now - state.sessionPlayStart
            if playTime >= HALT_THRESHOLD then
                state.haltTriggered = true
                state.haltSlowdownActive = true
                state.haltSlowdownExpires = now + HALT_SLOWDOWN_DURATION

                self.Client.HALTWarning:Fire(player, {
                    message = "You've been flying for a while. Even angels need to rest. Take a breather — a Rest Bonus awaits.",
                    haltRestBonus = HALT_AFK_REST_MOTES,
                    afkRequired = HALT_AFK_REST_DURATION,
                })
            end
        end

        -- HALT rest bonus: 2 min AFK = 5 motes
        if state.haltTriggered and state.isAFK then
            if now - state.afkStart >= HALT_AFK_REST_DURATION then
                -- Award rest bonus
                local MoteService = Knit.GetService("MoteService")
                MoteService:AwardMotes(player, HALT_AFK_REST_MOTES, "halt_rest_bonus")

                -- Reset HALT state
                state.haltTriggered = false
                state.sessionPlayStart = now -- reset timer
                state.isAFK = false
                state.afkStart = 0

                self.Client.HALTRest:Fire(player, {
                    message = "Rest complete! You earned " .. HALT_AFK_REST_MOTES .. " Motes for taking a break.",
                    motesAwarded = HALT_AFK_REST_MOTES,
                })
            end
        end
    end
end

---------------------------------------------------------------------------
-- Client-exposed methods
---------------------------------------------------------------------------

function HALTService.Client:GetSessionTime(player: Player): number
    local state = HALTStates[player.UserId]
    if not state then
        return 0
    end
    return os.time() - state.sessionPlayStart
end

function HALTService.Client:IsHALTActive(player: Player): boolean
    local state = HALTStates[player.UserId]
    if not state then
        return false
    end
    return state.haltTriggered
end

---------------------------------------------------------------------------
-- Knit Lifecycle
---------------------------------------------------------------------------

function HALTService:KnitInit(): ()
    print("[HALTService] Initializing...")
end

function HALTService:KnitStart(): ()
    local RunService = game:GetService("RunService")

    -- Run HALT update loop every Heartbeat
    RunService.Heartbeat:Connect(function(dt: number)
        self:Update(dt)
    end)

    print("[HALTService] Started")
end

return HALTService
