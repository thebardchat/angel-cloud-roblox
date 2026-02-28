--[[
    AngelMailService.lua — Player-to-player positive messaging system (Knit Service)
    "Angel Mail" — send kind, pre-written messages to other players
    Core game pillar: community building through positive interaction

    Migrated from ServerScriptService/AngelMailSystem.lua to Knit service pattern.

    Design:
    - Players choose from curated positive messages (no free text = COPPA safe)
    - Sending mail costs 1 Mote (prevents spam, creates investment)
    - Receiving mail gives visual FX + warm notification
    - Sending 3 mails in a session = quest objective
    - Messages are pre-approved templates (no moderation needed)

    5 categories: Encouragement, Gratitude, Kindness, Celebration, Wisdom
    22 templates total
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AngelMailService = Knit.CreateService({
    Name = "AngelMailService",
    Client = {
        MailReceived = Knit.CreateSignal(),
        MailCatalog = Knit.CreateSignal(),
    },
})

--[[ ── Type Definitions ─────────────────────────────────────────────── ]]

type MailTemplate = {
    id: string,
    category: string,
    text: string,
}

type MailEntry = {
    from: string,
    templateId: string,
    text: string,
    category: string,
    timestamp: number,
}

type PlayerMailState = {
    cooldowns: { [number]: number },
    inbox: { MailEntry },
    sentCount: number,
}

-- Pre-approved message templates (COPPA-safe, no free text)
local MESSAGE_TEMPLATES: { MailTemplate } = {
    -- Encouragement (5)
    { id = "encourage_01", category = "Encouragement", text = "You're doing amazing! Keep climbing!" },
    { id = "encourage_02", category = "Encouragement", text = "I believe in you, Angel. You've got this." },
    { id = "encourage_03", category = "Encouragement", text = "Your wings are getting stronger every day!" },
    { id = "encourage_04", category = "Encouragement", text = "Don't give up. The Meadow is worth it." },
    { id = "encourage_05", category = "Encouragement", text = "You're braver than you think." },

    -- Gratitude (4)
    { id = "thanks_01", category = "Gratitude", text = "Thank you for the blessing! It made my day." },
    { id = "thanks_02", category = "Gratitude", text = "Thanks for being an awesome Angel!" },
    { id = "thanks_03", category = "Gratitude", text = "You helped me when I needed it. Thank you." },
    { id = "thanks_04", category = "Gratitude", text = "Grateful to climb alongside you." },

    -- Kindness (5)
    { id = "kind_01", category = "Kindness", text = "You matter. Never forget that." },
    { id = "kind_02", category = "Kindness", text = "The Cloud is brighter because you're here." },
    { id = "kind_03", category = "Kindness", text = "You're not alone. We climb together." },
    { id = "kind_04", category = "Kindness", text = "Sending you light and warmth today." },
    { id = "kind_05", category = "Kindness", text = "Your light inspires others to shine." },

    -- Celebration (4)
    { id = "celebrate_01", category = "Celebration", text = "Congrats on leveling up! You earned it!" },
    { id = "celebrate_02", category = "Celebration", text = "Your wings look incredible!" },
    { id = "celebrate_03", category = "Celebration", text = "You found a starfish?! That's awesome!" },
    { id = "celebrate_04", category = "Celebration", text = "Look at you go! What a climb!" },

    -- Wisdom (4)
    { id = "wisdom_01", category = "Wisdom", text = "Rest is part of the climb, not a break from it." },
    { id = "wisdom_02", category = "Wisdom", text = "Every Angel was once a Newborn." },
    { id = "wisdom_03", category = "Wisdom", text = "The strongest wings grow from helping others." },
    { id = "wisdom_04", category = "Wisdom", text = "It's okay to fall. The wind always catches you." },
}

-- Quick lookup
local TemplateById: { [string]: MailTemplate } = {}
for _, template in ipairs(MESSAGE_TEMPLATES) do
    TemplateById[template.id] = template
end

-- Constants
local MAIL_MOTE_COST = 1
local MAIL_COOLDOWN = 10   -- seconds between sends to same player
local MAX_INBOX_SIZE = 20  -- keep last 20 received mails in memory

-- Per-player state (session only)
local playerMailStates: { [number]: PlayerMailState } = {}

-- Service references resolved at KnitStart
local DataService
local MoteService
local QuestService

--[[ ── Lifecycle ────────────────────────────────────────────────────── ]]

function AngelMailService:KnitInit(): ()
    print("[AngelMailService] Initializing Angel Mail service")
end

function AngelMailService:KnitStart(): ()
    DataService = Knit.GetService("DataService")
    MoteService = Knit.GetService("MoteService")

    -- QuestService may or may not exist; resolve safely
    local ok, svc = pcall(function()
        return Knit.GetService("QuestService")
    end)
    if ok then
        QuestService = svc
    end

    print("[AngelMailService] Angel Mail initialized — spread kindness, one message at a time")
end

--[[ ── Internal Helpers ─────────────────────────────────────────────── ]]

function AngelMailService:_getOrCreateState(userId: number): PlayerMailState
    if not playerMailStates[userId] then
        playerMailStates[userId] = { cooldowns = {}, inbox = {}, sentCount = 0 }
    end
    return playerMailStates[userId]
end

function AngelMailService:_notifyPlayer(player: Player, msgType: string, message: string): ()
    local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
    if ServerMessage then
        ServerMessage:FireClient(player, {
            type = msgType,
            message = message,
        })
    end
end

--[[ ── Core Logic ───────────────────────────────────────────────────── ]]

function AngelMailService:HandleSend(sender: Player, targetName: string, templateId: string): ()
    -- Validate template
    if not templateId or not TemplateById[templateId] then
        return
    end

    -- Validate target name is a string
    if type(targetName) ~= "string" then
        return
    end

    -- Find target player
    local target: Player? = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == targetName and p ~= sender then
            target = p
            break
        end
    end

    if not target then
        self:_notifyPlayer(sender, "info", "Couldn't find that Angel. They may have left the cloud.")
        return
    end

    -- Check cost
    local senderData = DataService:GetData(sender)
    if not senderData then return end

    if (senderData.motes or 0) < MAIL_MOTE_COST then
        self:_notifyPlayer(sender, "info", "You need " .. MAIL_MOTE_COST .. " Mote to send Angel Mail.")
        return
    end

    -- Check cooldown
    local state = self:_getOrCreateState(sender.UserId)
    local now = os.time()
    local lastSendToTarget = state.cooldowns[target.UserId] or 0
    if now - lastSendToTarget < MAIL_COOLDOWN then
        self:_notifyPlayer(sender, "info", "Wait a moment before sending another mail to " .. target.Name .. ".")
        return
    end

    -- Deduct cost
    MoteService:AwardMotes(sender, -MAIL_MOTE_COST, "angel_mail_sent")

    -- Track cooldown
    state.cooldowns[target.UserId] = now
    state.sentCount = state.sentCount + 1

    -- Track in sender data for persistence
    if not senderData.mailSentCount then
        senderData.mailSentCount = 0
    end
    senderData.mailSentCount = senderData.mailSentCount + 1

    -- Store in recipient's inbox
    local targetState = self:_getOrCreateState(target.UserId)

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

    -- Notify recipient via Knit signal
    self.Client.MailReceived:Fire(target, {
        from = sender.Name,
        text = TemplateById[templateId].text,
        category = TemplateById[templateId].category,
    })

    -- Confirm to sender
    self:_notifyPlayer(sender, "info", "Angel Mail sent to " .. target.Name .. "! (-" .. MAIL_MOTE_COST .. " Mote)")

    -- Quest hook
    if QuestService then
        pcall(function()
            QuestService:OnMailSent(sender)
        end)
    end

    print("[AngelMailService] " .. sender.Name .. " -> " .. target.Name .. ": " .. TemplateById[templateId].text)
end

function AngelMailService:SendCatalog(player: Player): ()
    -- Build catalog grouped by category
    local categories: { [string]: { { id: string, text: string } } } = {}

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
    local otherPlayers: { string } = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(otherPlayers, p.Name)
        end
    end

    self.Client.MailCatalog:Fire(player, {
        categories = categories,
        players = otherPlayers,
        cost = MAIL_MOTE_COST,
    })
end

function AngelMailService:SendHistory(player: Player): ()
    local state = playerMailStates[player.UserId]
    if not state then
        -- No state yet; send empty inbox
        self:_notifyPlayer(player, "mail_history", "")
        return
    end

    -- History is sent via ServerMessage since MailHistory was a separate remote
    local ServerMessage = ReplicatedStorage:FindFirstChild("ServerMessage")
    if ServerMessage then
        ServerMessage:FireClient(player, {
            type = "mail_history",
            inbox = state.inbox,
            sentCount = state.sentCount,
        })
    end
end

function AngelMailService:RemovePlayer(player: Player): ()
    playerMailStates[player.UserId] = nil
end

--[[ ── Client API ───────────────────────────────────────────────────── ]]

function AngelMailService.Client:SendMail(player: Player, targetName: string, templateId: string): ()
    self.Server:HandleSend(player, targetName, templateId)
end

function AngelMailService.Client:RequestCatalog(player: Player): ()
    self.Server:SendCatalog(player)
end

function AngelMailService.Client:RequestHistory(player: Player): ()
    self.Server:SendHistory(player)
end

return AngelMailService
