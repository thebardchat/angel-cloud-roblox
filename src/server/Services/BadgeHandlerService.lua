--[[
    BadgeHandlerService.lua — Founder badge and special cosmetic awards (Knit)
    Awards "Founder's Halo" cosmetic to players who join during launch week.
    Also handles Ko-fi code redemption for the Founder's Halo.
    Inspired by Gemini's BadgeHandler pattern with time-window checks.
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BadgeHandlerService = Knit.CreateService({
    Name = "BadgeHandlerService",
    Client = {
        KofiRedeem = Knit.CreateSignal(),
    },
})

-- Configure these after uploading badges in Roblox Creator Dashboard
local FOUNDER_BADGE_ID: number = 0  -- Replace with real Badge ID after upload
local CLOUD_CONNECTED_BADGE_ID: number = 0  -- Replace with real Badge ID

-- Launch week window — players joining before this date get Founder's Halo
local LAUNCH_WEEK_END: number = os.time({ year = 2026, month = 3, day = 31 })

-- Valid Ko-fi donor codes (in production, validate against a database or API)
-- For now, codes are generated manually and added here
local validKofiCodes: { [string]: boolean } = {}

-- Reference to DataService (resolved in KnitStart)
local DataService

function BadgeHandlerService:KnitInit(): ()
    -- Listen for client Ko-fi code redemption via Knit signal
    self.Client.KofiRedeem:Connect(function(player: Player, code: string)
        self:RedeemKofiCode(player, code)
    end)
end

function BadgeHandlerService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
end

function BadgeHandlerService:OnPlayerAdded(player: Player): ()
    task.wait(3)  -- let DataService load first

    -- Launch week Founder's Halo
    if os.time() <= LAUNCH_WEEK_END then
        self:AwardFounderHalo(player)
    end
end

function BadgeHandlerService:AwardFounderHalo(player: Player): ()
    local data = DataService:GetData(player)
    if not data then
        return
    end

    -- Grant cosmetic
    if not data.ownedCosmetics["founders_halo"] then
        data.ownedCosmetics["founders_halo"] = true
        data.founderHalo = true
        print("[BadgeHandlerService] Awarded Founder's Halo to " .. player.Name)
    end

    -- Award Roblox badge (if configured)
    if FOUNDER_BADGE_ID > 0 then
        local success, hasBadge = pcall(function()
            return BadgeService:UserHasBadgeAsync(player.UserId, FOUNDER_BADGE_ID)
        end)

        if success and not hasBadge then
            pcall(function()
                BadgeService:AwardBadge(player.UserId, FOUNDER_BADGE_ID)
            end)
        end
    end
end

function BadgeHandlerService:AwardCloudConnectedBadge(player: Player): ()
    if CLOUD_CONNECTED_BADGE_ID > 0 then
        local success, hasBadge = pcall(function()
            return BadgeService:UserHasBadgeAsync(player.UserId, CLOUD_CONNECTED_BADGE_ID)
        end)

        if success and not hasBadge then
            pcall(function()
                BadgeService:AwardBadge(player.UserId, CLOUD_CONNECTED_BADGE_ID)
            end)
        end
    end
end

function BadgeHandlerService:RedeemKofiCode(player: Player, code: string): ()
    if not code or code == "" then
        return
    end

    local data = DataService:GetData(player)
    if not data then
        return
    end

    -- Already has Founder's Halo
    if data.ownedCosmetics["founders_halo"] then
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            (ServerMessage :: RemoteEvent):FireClient(player, {
                type = "info",
                message = "You already have the Founder's Halo!",
            })
        end
        return
    end

    -- Validate code
    if validKofiCodes[code] then
        validKofiCodes[code] = nil  -- single use
        data.ownedCosmetics["founders_halo"] = true
        data.founderHalo = true

        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            (ServerMessage :: RemoteEvent):FireClient(player, {
                type = "info",
                message = "Ko-fi code accepted! Founder's Halo + Supporter tag unlocked.",
            })
        end

        print("[BadgeHandlerService] Ko-fi Founder's Halo redeemed by " .. player.Name)

        if FOUNDER_BADGE_ID > 0 then
            pcall(function()
                BadgeService:AwardBadge(player.UserId, FOUNDER_BADGE_ID)
            end)
        end
    else
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            (ServerMessage :: RemoteEvent):FireClient(player, {
                type = "info",
                message = "Invalid or already-used Ko-fi code.",
            })
        end
    end
end

-- Add Ko-fi codes at runtime (called by admin or from a secure source)
function BadgeHandlerService:AddKofiCode(code: string): ()
    validKofiCodes[code] = true
end

return BadgeHandlerService
