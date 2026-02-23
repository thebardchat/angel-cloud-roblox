--[[
	Net.lua — Type-safe RemoteEvent/RemoteFunction wrapper
	ModuleScript → ReplicatedStorage.Shared.Net

	Centralizes all network communication. No more scattered Instance.new("RemoteEvent").

	SERVER USAGE:
		local Net = require(ReplicatedStorage.Shared.Net)
		Net.CreateRemotes() -- call once in GameManager.Init()
		Net.OnServer("PlayerReady", function(player) ... end)
		Net.FireClient("ServerMessage", player, { type = "welcome" })
		Net.FireAllClients("ServerAnnouncement", "Hello!")

	CLIENT USAGE:
		local Net = require(ReplicatedStorage.Shared.Net)
		Net.OnClient("ServerMessage", function(data) ... end)
		Net.FireServer("PlayerReady")

	REMOTE REGISTRY:
		All remotes are defined in Net.Remotes table below.
		Add new remotes here — they'll be auto-created on server init.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- Master registry of all RemoteEvents and RemoteFunctions
-- type: "Event" for RemoteEvent, "Function" for RemoteFunction
Net.Remotes = {
	-- Player lifecycle
	PlayerReady = { type = "Event", direction = "ClientToServer" },
	PlayerProgress = { type = "Event", direction = "ServerToClient" },
	ServerMessage = { type = "Event", direction = "ServerToClient" },

	-- Stamina
	StaminaUpdate = { type = "Event", direction = "ServerToClient" },

	-- Progression
	LevelUp = { type = "Event", direction = "ServerToClient" },

	-- Motes
	MoteCollected = { type = "Event", direction = "ServerToClient" },
	CollectMote = { type = "Event", direction = "ClientToServer" },

	-- Blessings
	BlessPlayer = { type = "Event", direction = "ClientToServer" },
	BlessingReceived = { type = "Event", direction = "ServerToClient" },
	BlessingChainUpdate = { type = "Event", direction = "ServerToClient" },

	-- Lore
	FragmentCollected = { type = "Event", direction = "ServerToClient" },
	CollectFragment = { type = "Event", direction = "ClientToServer" },

	-- Trials
	StartTrial = { type = "Event", direction = "ClientToServer" },
	TrialUpdate = { type = "Event", direction = "ServerToClient" },
	TrialComplete = { type = "Event", direction = "ServerToClient" },

	-- Quests
	QuestUpdate = { type = "Event", direction = "ServerToClient" },
	QuestComplete = { type = "Event", direction = "ServerToClient" },
	AcceptQuest = { type = "Event", direction = "ClientToServer" },

	-- Shop
	PurchaseItem = { type = "Function", direction = "ClientToServer" },
	EquipItem = { type = "Event", direction = "ClientToServer" },
	ShopSync = { type = "Event", direction = "ServerToClient" },

	-- NPC
	NPCInteract = { type = "Event", direction = "ClientToServer" },
	NPCDialogue = { type = "Event", direction = "ServerToClient" },

	-- Cross-platform
	LinkAngelCloud = { type = "Function", direction = "ClientToServer" },

	-- Flight
	FlightTime = { type = "Event", direction = "ClientToServer" },

	-- Retro / Reflection
	RetroSubmit = { type = "Event", direction = "ClientToServer" },
	RetroPrompt = { type = "Event", direction = "ServerToClient" },

	-- Rotary Dial
	DialCode = { type = "Event", direction = "ClientToServer" },
	DialResult = { type = "Event", direction = "ServerToClient" },

	-- Sound
	PlaySound = { type = "Event", direction = "ServerToClient" },

	-- Atmosphere
	AtmosphereUpdate = { type = "Event", direction = "ServerToClient" },

	-- Debug (dev only)
	DebugCommand = { type = "Event", direction = "ClientToServer" },
	DebugResponse = { type = "Event", direction = "ServerToClient" },
}

local IS_SERVER = RunService:IsServer()
local remoteFolder: Folder = nil

-- Rate limiting state (server-side)
local lastFireTime: { [Player]: { [string]: number } } = {}
local RATE_LIMIT = 0.15 -- 150ms between fires per remote per player

--[[ ===== SETUP ===== ]]

function Net.CreateRemotes()
	assert(IS_SERVER, "[Net] CreateRemotes must be called from the server")

	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage

	for name, def in Net.Remotes do
		local remote
		if def.type == "Event" then
			remote = Instance.new("RemoteEvent")
		elseif def.type == "Function" then
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = remoteFolder
	end

	print("[Net] Created " .. tostring(#Net._getRemoteNames()) .. " remotes")
end

function Net._getRemoteNames(): { string }
	local names = {}
	for name in Net.Remotes do
		table.insert(names, name)
	end
	return names
end

function Net._getFolder(): Folder
	if remoteFolder then
		return remoteFolder
	end
	remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
	if not remoteFolder then
		warn("[Net] Timed out waiting for Remotes folder")
	end
	return remoteFolder
end

function Net._getRemote(name: string): Instance?
	local folder = Net._getFolder()
	if not folder then
		return nil
	end
	return folder:FindFirstChild(name) or folder:WaitForChild(name, 10)
end

function Net._checkRateLimit(player: Player, remoteName: string): boolean
	if not lastFireTime[player] then
		lastFireTime[player] = {}
	end

	local now = tick()
	local last = lastFireTime[player][remoteName] or 0

	if now - last < RATE_LIMIT then
		return false -- rate limited
	end

	lastFireTime[player][remoteName] = now
	return true
end

--[[ ===== SERVER API ===== ]]

function Net.OnServer(remoteName: string, handler: (Player, ...any) -> ())
	assert(IS_SERVER, "[Net] OnServer must be called from the server")

	local remote = Net._getRemote(remoteName)
	if not remote then
		warn("[Net] Remote not found: " .. remoteName)
		return
	end

	if remote:IsA("RemoteEvent") then
		remote.OnServerEvent:Connect(function(player: Player, ...)
			if not Net._checkRateLimit(player, remoteName) then
				return -- silently drop rate-limited requests
			end
			handler(player, ...)
		end)
	elseif remote:IsA("RemoteFunction") then
		remote.OnServerInvoke = function(player: Player, ...)
			if not Net._checkRateLimit(player, remoteName) then
				return nil -- rate limited
			end
			return handler(player, ...)
		end
	end
end

function Net.FireClient(remoteName: string, player: Player, ...: any)
	assert(IS_SERVER, "[Net] FireClient must be called from the server")

	local remote = Net._getRemote(remoteName)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[Net] Event not found: " .. remoteName)
		return
	end

	remote:FireClient(player, ...)
end

function Net.FireAllClients(remoteName: string, ...: any)
	assert(IS_SERVER, "[Net] FireAllClients must be called from the server")

	local remote = Net._getRemote(remoteName)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[Net] Event not found: " .. remoteName)
		return
	end

	remote:FireAllClients(...)
end

-- Clean up rate limit tracking when player leaves
function Net.RemovePlayer(player: Player)
	lastFireTime[player] = nil
end

--[[ ===== CLIENT API ===== ]]

function Net.OnClient(remoteName: string, handler: (...any) -> ())
	assert(not IS_SERVER, "[Net] OnClient must be called from the client")

	local remote = Net._getRemote(remoteName)
	if not remote then
		warn("[Net] Remote not found: " .. remoteName)
		return
	end

	if remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(handler)
	end
end

function Net.FireServer(remoteName: string, ...: any)
	assert(not IS_SERVER, "[Net] FireServer must be called from the client")

	local remote = Net._getRemote(remoteName)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[Net] Event not found: " .. remoteName)
		return
	end

	remote:FireServer(...)
end

function Net.InvokeServer(remoteName: string, ...: any): any
	assert(not IS_SERVER, "[Net] InvokeServer must be called from the client")

	local remote = Net._getRemote(remoteName)
	if not remote or not remote:IsA("RemoteFunction") then
		warn("[Net] Function not found: " .. remoteName)
		return nil
	end

	return remote:InvokeServer(...)
end

return Net
