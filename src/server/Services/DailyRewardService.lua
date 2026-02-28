--[[
    DailyRewardService.lua — Daily login streak rewards (Knit)
    Keeps players coming back every day with escalating rewards
    Server-authoritative: checks real time, prevents exploitation

    Day 1: 5 Motes
    Day 2: 8 Motes
    Day 3: 12 Motes
    Day 4: 15 Motes
    Day 5: 20 Motes
    Day 6: 25 Motes
    Day 7: 40 Motes + bonus cosmetic unlock
    Streak resets if player misses a day (grace period: 48 hours)
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")

local DailyRewardService = Knit.CreateService({
    Name = "DailyRewardService",
    Client = {
        DailyRewardNotify = Knit.CreateSignal(),
        DailyRewardClaim = Knit.CreateSignal(),
    },
})

-- Reward tiers (repeats weekly after day 7)
local DAILY_REWARDS = {
    { motes = 5,  label = "Day 1" },
    { motes = 8,  label = "Day 2" },
    { motes = 12, label = "Day 3" },
    { motes = 15, label = "Day 4" },
    { motes = 20, label = "Day 5" },
    { motes = 25, label = "Day 6" },
    { motes = 40, label = "Day 7 — Weekly Bonus!", bonusCosmetic = "streak_halo" },
}

-- Seconds in a day
local ONE_DAY: number = 86400
-- Grace period: 48 hours before streak resets
local GRACE_PERIOD: number = ONE_DAY * 2

-- References to other Knit services (resolved in KnitStart)
local DataService
local MoteService
local SoundManagerService

function DailyRewardService:KnitInit(): ()
    -- Listen for client claim requests via Knit signal
    self.Client.DailyRewardClaim:Connect(function(player: Player)
        self:ClaimReward(player)
    end)

    print("[DailyRewardService] Daily rewards initialized")
end

function DailyRewardService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")
    SoundManagerService = Knit.GetService("SoundManagerService")
end

function DailyRewardService:OnPlayerJoined(player: Player): ()
    local data = DataService:GetData(player)
    if not data then return end

    -- Initialize daily reward fields if missing
    if not data.dailyStreak then
        data.dailyStreak = 0
    end
    if not data.lastDailyClaimTime then
        data.lastDailyClaimTime = 0
    end

    -- Check if daily reward is available
    local now = os.time()
    local timeSinceLastClaim = now - data.lastDailyClaimTime

    -- First login ever or new day available
    if data.lastDailyClaimTime == 0 or timeSinceLastClaim >= ONE_DAY then
        -- Check if streak should reset (missed more than grace period)
        if data.lastDailyClaimTime > 0 and timeSinceLastClaim > GRACE_PERIOD then
            data.dailyStreak = 0
        end

        -- Calculate which day reward to show
        local streakDay = (data.dailyStreak % 7) + 1
        local reward = DAILY_REWARDS[streakDay]

        -- Notify client that reward is available
        task.delay(4, function()
            if player.Parent == Players then
                self.Client.DailyRewardNotify:Fire(player, {
                    available = true,
                    streakDay = streakDay,
                    totalStreak = data.dailyStreak + 1,
                    reward = reward,
                    allRewards = self:GetWeekRewards(data.dailyStreak),
                })
            end
        end)
    end
end

function DailyRewardService:ClaimReward(player: Player): ()
    local data = DataService:GetData(player)
    if not data then return end

    local now = os.time()
    local timeSinceLastClaim = now - (data.lastDailyClaimTime or 0)

    -- Must wait at least one day since last claim
    if data.lastDailyClaimTime > 0 and timeSinceLastClaim < ONE_DAY then
        self.Client.DailyRewardNotify:Fire(player, {
            available = false,
            message = "You already claimed today's reward! Come back tomorrow.",
        })
        return
    end

    -- Reset streak if grace period exceeded
    if data.lastDailyClaimTime > 0 and timeSinceLastClaim > GRACE_PERIOD then
        data.dailyStreak = 0
    end

    -- Calculate reward
    local streakDay = (data.dailyStreak % 7) + 1
    local reward = DAILY_REWARDS[streakDay]

    -- Award motes
    MoteService:AwardMotes(player, reward.motes, "daily_reward")

    -- Award bonus cosmetic on day 7
    if reward.bonusCosmetic then
        if not data.ownedCosmetics then
            data.ownedCosmetics = {}
        end
        if not data.ownedCosmetics[reward.bonusCosmetic] then
            data.ownedCosmetics[reward.bonusCosmetic] = true
        end
    end

    -- Update streak
    data.dailyStreak = data.dailyStreak + 1
    data.lastDailyClaimTime = now

    -- Play reward sound
    pcall(function()
        SoundManagerService:PlaySFXForPlayer(player, "daily_reward", 0.7)
    end)

    -- Notify client
    self.Client.DailyRewardNotify:Fire(player, {
        available = false,
        claimed = true,
        streakDay = streakDay,
        totalStreak = data.dailyStreak,
        reward = reward,
        message = reward.label .. ": +" .. reward.motes .. " Motes!",
    })

    print("[DailyRewardService] " .. player.Name .. " claimed Day " .. streakDay .. " reward (" .. reward.motes .. " Motes, streak " .. data.dailyStreak .. ")")
end

function DailyRewardService:GetWeekRewards(currentStreak: number): { any }
    local rewards = {}
    for i, reward in ipairs(DAILY_REWARDS) do
        local dayNumber = i
        local claimed = false

        -- Calculate which days in the current week are claimed
        local streakInWeek = currentStreak % 7
        if i <= streakInWeek then
            claimed = true
        end

        table.insert(rewards, {
            day = dayNumber,
            motes = reward.motes,
            label = reward.label,
            claimed = claimed,
            bonusCosmetic = reward.bonusCosmetic,
        })
    end
    return rewards
end

return DailyRewardService
