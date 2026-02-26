--[[
    AngelMailSystem.lua — Player-to-player positive messaging system
    "Angel Mail" — send kind, pre-written messages to other players
    Core game pillar: community building through positive interaction

    Design:
    - Players choose from curated positive messages (no free text = COPPA safe)
    - Sending mail costs 1 Mote (prevents spam, creates investment)
    - Receiving mail gives visual FX + warm notification
    - Sending 3 mails in a session = quest objective
    - Messages are pre-approved templates (no moderation needed)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(script.Parent.DataManager)
local MoteSystem = require(script.Parent.MoteSystem)
local SoundManager = require(script.Parent.SoundManager)

local AngelMailSystem = {}

-- RemoteEvents
local MailSend       -- Client -> Server: send a mail to target player
local MailReceived   -- Server -> Client: you got mail!
local MailCatalog    -- Server -> Client: available message templates
local MailHistory    -- Server -> Client: recent received mails

-- Pre-approved message templates (COPPA-safe, no free text)
local MESSAGE_TEMPLATES = {
    -- Encouragement
    { id = "encourage_01", category = "Encouragement", text = "You're doing amazing! Keep climbing!" },
    { id = "encourage_02", category = "Encouragement", text = "I believe in you, Angel. You've got this." },
    { id = "encourage_03", category = "Encouragement", text = "Your wings are getting stronger every day!" },
    { id = "encourage_04", category = "Encouragement", text = "Don't give up. The Meadow is worth it." },
    { id = "encourage_05", category = "Encouragement", text = "You're braver than you think." },

    -- Gratitude
    { id = "thanks_01", category = "Gratitude", text = "Thank you for the blessing! It made my day." },
    { id = "thanks_02", category = "Gratitude", text = "Thanks for being an awesome Angel!" },
    { id = "thanks_03", category = "Gratitude", text = "You helped me when I needed it. Thank you." },
    { id = "thanks_04", category = "Gratitude", text = "Grateful to climb alongside you." },

    -- Kindness
    { id = "kind_01", category = "Kindness", text = "You matter. Never forget that." },
    { id = "kind_02", category = "Kindness", text = "The Cloud is brighter because you're here." },
    { id = "kind_03", category = "Kindness", text = "You're not alone. We climb together." },
    { id = "kind_04", category = "Kindness", text = "Sending you light and warmth today." },
    { id = "kind_05", category = "Kindness", text = "Your light inspires others to shine." },

    -- Celebration
    { id = "celebrate_01", category = "Celebration", text = "Congrats on leveling up! You earned it!" },
    { id = "celebrate_02", category = "Celebration", text = "Your wings look incredible!" },
    { id = "celebrate_03", category = "Celebration", text = "You found a starfish?! That's awesome!" },
    { id = "celebrate_04", category = "Celebration", text = "Look at you go! What a climb!" },

    -- Wisdom
    { id = "wisdom_01", category = "Wisdom", text = "Rest is part of the climb, not a break from it." },
    { id = "wisdom_02", category = "Wisdom", text = "Every Angel was once a Newborn." },
    { id = "wisdom_03", category = "Wisdom", text = "The strongest wings grow from helping others." },
    { id = "wisdom_04", category = "Wisdom", text = "It's okay to fall. The wind always catches you." },
}

-- Quick lookup
local TemplateById = {}
for _, template in ipairs(MESSAGE_TEMPLATES) do
    TemplateById[template.id] = template
end

-- Constants
local MAIL_MOTE_COST = 1
local MAIL_COOLDOWN = 10  -- seconds between sends to same player
local MAX_INBOX_SIZE = 20 -- keep last 20 received mails in memory

-- Per-player state (session only)
local PlayerMailState = {}

function AngelMailSystem.Init()
    MailSend = Instance.new("RemoteEvent")
    MailSend.Name = "MailSend"
    MailSend.Parent = ReplicatedStorage

    MailReceived = Instance.new("RemoteEvent")
    MailReceived.Name = "MailReceived"
    MailReceived.Parent = ReplicatedStorage

    MailCatalog = Instance.new("RemoteEvent")
    MailCatalog.Name = "MailCatalog"
    MailCatalog.Parent = ReplicatedStorage

    MailHistory = Instance.new("RemoteEvent")
    MailHistory.Name = "MailHistory"
    MailHistory.Parent = ReplicatedStorage

    -- Handle send request
    MailSend.OnServerEvent:Connect(function(player, targetPlayerName, templateId)
        AngelMailSystem.HandleSend(player, targetPlayerName, templateId)
    end)

    -- Handle catalog request
    MailCatalog.OnServerEvent:Connect(function(player)
        AngelMailSystem.SendCatalog(player)
    end)

    -- Handle history request
    MailHistory.OnServerEvent:Connect(function(player)
        AngelMailSystem.SendHistory(player)
    end)

    print("[AngelMailSystem] Angel Mail initialized — spread kindness, one message at a time")
end

function AngelMailSystem.HandleSend(sender: Player, targetName: string, templateId: string)
    -- Validate template
    if not templateId or not TemplateById[templateId] then
        return
    end

    -- Validate target name is a string
    if type(targetName) ~= "string" then
        return
    end

    -- Find target player
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == targetName and p ~= sender then
            target = p
            break
        end
    end

    if not target then
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            ServerMessage:FireClient(sender, {
                type = "info",
                message = "Couldn't find that Angel. They may have left the cloud.",
            })
        end
        return
    end

    -- Check cost
    local senderData = DataManager.GetData(sender)
    if not senderData then return end

    if (senderData.motes or 0) < MAIL_MOTE_COST then
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            ServerMessage:FireClient(sender, {
                type = "info",
                message = "You need " .. MAIL_MOTE_COST .. " Mote to send Angel Mail.",
            })
        end
        return
    end

    -- Check cooldown
    local state = PlayerMailState[sender.UserId]
    if not state then
        state = { cooldowns = {}, inbox = {}, sentCount = 0 }
        PlayerMailState[sender.UserId] = state
    end

    local now = os.time()
    local lastSendToTarget = state.cooldowns[target.UserId] or 0
    if now - lastSendToTarget < MAIL_COOLDOWN then
        local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
        if ServerMessage then
            ServerMessage:FireClient(sender, {
                type = "info",
                message = "Wait a moment before sending another mail to " .. target.Name .. ".",
            })
        end
        return
    end

    -- Deduct cost
    MoteSystem.AwardMotes(sender, -MAIL_MOTE_COST, "angel_mail_sent")

    -- Track cooldown
    state.cooldowns[target.UserId] = now
    state.sentCount = state.sentCount + 1

    -- Track in sender data for persistence
    if not senderData.mailSentCount then
        senderData.mailSentCount = 0
    end
    senderData.mailSentCount = senderData.mailSentCount + 1

    -- Store in recipient's inbox
    local targetState = PlayerMailState[target.UserId]
    if not targetState then
        targetState = { cooldowns = {}, inbox = {}, sentCount = 0 }
        PlayerMailState[target.UserId] = targetState
    end

    table.insert(targetState.inbox, {
        from = sender.Name,
        templateId = templateId,
        text = TemplateById[templateId].text,
        category = TemplateById[templateId].category,
        timestamp = now,
    })

    -- Trim inbox if too large
    while #targetState.inbox > MAX_INBOX_SIZE do
        table.remove(targetState.inbox, 1)
    end

    -- Play sounds
    pcall(SoundManager.PlaySFXForPlayer, sender, "mail_sent", 0.5)
    pcall(SoundManager.PlaySFXForPlayer, target, "blessing_received", 0.6)

    -- Notify recipient
    MailReceived:FireClient(target, {
        from = sender.Name,
        text = TemplateById[templateId].text,
        category = TemplateById[templateId].category,
    })

    -- Confirm to sender
    local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
    if ServerMessage then
        ServerMessage:FireClient(sender, {
            type = "info",
            message = "Angel Mail sent to " .. target.Name .. "! (-" .. MAIL_MOTE_COST .. " Mote)",
        })
    end

    -- Quest hook
    local QuestSystem = require(script.Parent.QuestSystem)
    pcall(QuestSystem.OnMailSent, sender)

    print("[AngelMailSystem] " .. sender.Name .. " -> " .. target.Name .. ": " .. TemplateById[templateId].text)
end

function AngelMailSystem.SendCatalog(player: Player)
    -- Build catalog grouped by category
    local catalog = {}
    local categories = {}

    for _, template in ipairs(MESSAGE_TEMPLATES) do
        if not categories[template.category] then
            categories[template.category] = {}
        end
        table.insert(categories[template.category], {
            id = template.id,
            text = template.text,
        })
    end

    -- Get list of other players for targeting
    local otherPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(otherPlayers, p.Name)
        end
    end

    MailCatalog:FireClient(player, {
        categories = categories,
        players = otherPlayers,
        cost = MAIL_MOTE_COST,
    })
end

function AngelMailSystem.SendHistory(player: Player)
    local state = PlayerMailState[player.UserId]
    if not state then
        MailHistory:FireClient(player, { inbox = {} })
        return
    end

    MailHistory:FireClient(player, {
        inbox = state.inbox,
        sentCount = state.sentCount,
    })
end

function AngelMailSystem.RemovePlayer(player: Player)
    PlayerMailState[player.UserId] = nil
end

return AngelMailSystem
