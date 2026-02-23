--[[
	DebugConsole.lua — In-studio debug commands and state inspection
	ModuleScript → ServerScriptService (or tools/)

	Provides admin/debug commands for development and testing.
	MUST be disabled before public release.

	USAGE (from server command bar in Studio):
		local Debug = require(game.ServerScriptService.DebugConsole) -- or wherever you place it
		Debug.SetMotes(player, 100)
		Debug.SetLevel(player, "Guardian Angel")
		Debug.TeleportToLayer(player, 5)
		Debug.ListPlayers()
		Debug.InspectPlayer(player)
		Debug.GiveCosmetic(player, "wings_crystal")
		Debug.ResetPlayer(player)
		Debug.StressTest(100) -- spawn 100 motes
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugConsole = {}

-- Safety: only works in Studio
local IS_STUDIO = RunService:IsStudio()

local function checkStudio()
	if not IS_STUDIO then
		warn("[DebugConsole] Debug commands are disabled outside of Studio")
		return false
	end
	return true
end

local function getDataManager()
	local ok, dm = pcall(function()
		return require(game.ServerScriptService.DataManager)
	end)
	return ok and dm or nil
end

local function getPlayer(nameOrPlayer: any): Player?
	if typeof(nameOrPlayer) == "Instance" and nameOrPlayer:IsA("Player") then
		return nameOrPlayer
	end
	if type(nameOrPlayer) == "string" then
		for _, player in Players:GetPlayers() do
			if player.Name:lower():find(nameOrPlayer:lower()) then
				return player
			end
		end
	end
	-- If only one player, default to them
	local all = Players:GetPlayers()
	if #all == 1 then
		return all[1]
	end
	warn("[DebugConsole] Player not found: " .. tostring(nameOrPlayer))
	return nil
end

-- List all players and their basic stats
function DebugConsole.ListPlayers()
	if not checkStudio() then return end

	local dm = getDataManager()
	print("\n=== PLAYERS ===")
	for _, player in Players:GetPlayers() do
		local data = dm and dm.GetData(player)
		if data then
			print(string.format(
				"  %s | Level: %s | Motes: %d | Layer: %d | Wing: %d",
				player.Name,
				data.angelLevel or "?",
				data.motes or 0,
				data.layerIndex or 1,
				data.wingLevel or 1
			))
		else
			print("  " .. player.Name .. " | (no data loaded)")
		end
	end
	print("===============\n")
end

-- Deep inspect a player's full data
function DebugConsole.InspectPlayer(nameOrPlayer: any)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then
		warn("[DebugConsole] DataManager not available")
		return
	end

	local data = dm.GetData(player)
	if not data then
		warn("[DebugConsole] No data for " .. player.Name)
		return
	end

	print("\n=== PLAYER DATA: " .. player.Name .. " ===")
	for key, value in data do
		if type(value) == "table" then
			local count = 0
			for _ in value do count += 1 end
			print(string.format("  %s: {%d entries}", key, count))
		else
			print(string.format("  %s: %s", key, tostring(value)))
		end
	end
	print("===========================\n")
end

-- Set player's mote count
function DebugConsole.SetMotes(nameOrPlayer: any, amount: number)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	local data = dm.GetData(player)
	if data then
		data.motes = amount
		print("[DebugConsole] Set " .. player.Name .. " motes to " .. amount)
	end
end

-- Set player's angel level
function DebugConsole.SetLevel(nameOrPlayer: any, level: string)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	local data = dm.GetData(player)
	if data then
		data.angelLevel = level
		print("[DebugConsole] Set " .. player.Name .. " level to " .. level)
	end
end

-- Set player's layer
function DebugConsole.SetLayer(nameOrPlayer: any, layerIndex: number)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	local data = dm.GetData(player)
	if data then
		data.layerIndex = layerIndex
		print("[DebugConsole] Set " .. player.Name .. " layer to " .. layerIndex)
	end
end

-- Teleport player to a specific layer spawn point
function DebugConsole.TeleportToLayer(nameOrPlayer: any, layerIndex: number)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local ok, Layers = pcall(function()
		return require(game.ReplicatedStorage.Config.Layers)
	end)
	if not ok then
		warn("[DebugConsole] Could not load Layers config")
		return
	end

	local layerDef = Layers.GetLayerByIndex(layerIndex)
	if not layerDef then
		warn("[DebugConsole] Invalid layer index: " .. layerIndex)
		return
	end

	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(layerDef.spawnPosition + Vector3.new(0, 5, 0))
			print("[DebugConsole] Teleported " .. player.Name .. " to " .. layerDef.name)
		end
	end
end

-- Give a cosmetic item
function DebugConsole.GiveCosmetic(nameOrPlayer: any, cosmeticId: string)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	local data = dm.GetData(player)
	if data then
		if not data.ownedCosmetics then
			data.ownedCosmetics = {}
		end
		data.ownedCosmetics[cosmeticId] = true
		print("[DebugConsole] Gave " .. player.Name .. " cosmetic: " .. cosmeticId)
	end
end

-- Complete a quest
function DebugConsole.CompleteQuest(nameOrPlayer: any, questId: string)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	local data = dm.GetData(player)
	if data then
		if not data.completedQuests then
			data.completedQuests = {}
		end
		data.completedQuests[questId] = true
		print("[DebugConsole] Completed quest " .. questId .. " for " .. player.Name)
	end
end

-- Reset player data to defaults
function DebugConsole.ResetPlayer(nameOrPlayer: any)
	if not checkStudio() then return end

	local player = getPlayer(nameOrPlayer)
	if not player then return end

	local dm = getDataManager()
	if not dm then return end

	-- Kick and let them rejoin with fresh data would be safest
	-- For now, reset the in-memory data
	local data = dm.GetData(player)
	if data then
		data.motes = 0
		data.angelLevel = "Newborn"
		data.layerIndex = 1
		data.wingLevel = 1
		data.activeQuest = "first_motes"
		data.questProgress = 0
		print("[DebugConsole] Reset " .. player.Name .. " to defaults")
	end
end

-- Spawn N test motes at the first player's position
function DebugConsole.StressTest(count: number?)
	if not checkStudio() then return end

	count = count or 50
	local player = Players:GetPlayers()[1]
	if not player or not player.Character then
		warn("[DebugConsole] No player with character for stress test")
		return
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	print("[DebugConsole] Spawning " .. count .. " test parts...")

	local startTime = tick()
	for i = 1, count do
		local part = Instance.new("Part")
		part.Name = "StressTestPart_" .. i
		part.Size = Vector3.new(2, 2, 2)
		part.Position = hrp.Position + Vector3.new(
			math.random(-50, 50),
			math.random(5, 30),
			math.random(-50, 50)
		)
		part.Anchored = true
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromHSV(i / count, 1, 1)
		part.Parent = workspace
	end

	local elapsed = tick() - startTime
	print(string.format(
		"[DebugConsole] Spawned %d parts in %.3f seconds (%.1f parts/sec)",
		count, elapsed, count / elapsed
	))
end

-- Clean up stress test parts
function DebugConsole.CleanStressTest()
	if not checkStudio() then return end

	local removed = 0
	for _, child in workspace:GetChildren() do
		if child.Name:find("StressTestPart_") then
			child:Destroy()
			removed += 1
		end
	end
	print("[DebugConsole] Removed " .. removed .. " stress test parts")
end

-- Print all RemoteEvents and RemoteFunctions
function DebugConsole.ListRemotes()
	if not checkStudio() then return end

	print("\n=== REMOTE EVENTS/FUNCTIONS ===")

	local function scan(parent, indent)
		indent = indent or ""
		for _, child in parent:GetChildren() do
			if child:IsA("RemoteEvent") then
				print(indent .. "[Event] " .. child:GetFullName())
			elseif child:IsA("RemoteFunction") then
				print(indent .. "[Function] " .. child:GetFullName())
			end
			if #child:GetChildren() > 0 then
				scan(child, indent .. "  ")
			end
		end
	end

	scan(game.ReplicatedStorage)
	print("===============================\n")
end

-- Print memory usage
function DebugConsole.MemoryStats()
	if not checkStudio() then return end

	print("\n=== MEMORY STATS ===")
	local stats = game:GetService("Stats")

	-- Get some useful metrics
	local memCategories = {
		"CoreMemory",
		"PlaceMemory",
		"InstanceCount",
		"PhysicsParts",
	}

	for _, cat in memCategories do
		local ok, result = pcall(function()
			return stats:FindFirstChild(cat)
		end)
		if ok and result then
			print(string.format("  %s: %s", cat, tostring(result.Value)))
		end
	end

	-- Instance count
	local instanceCount = 0
	local function countInstances(parent)
		instanceCount += 1
		for _, child in parent:GetChildren() do
			countInstances(child)
		end
	end
	pcall(countInstances, workspace)
	print(string.format("  Workspace Instances: %d", instanceCount))
	print("====================\n")
end

-- Quick help
function DebugConsole.Help()
	print([[

=== DEBUG CONSOLE — Available Commands ===
  .ListPlayers()                    — List all players with stats
  .InspectPlayer(player)            — Full data dump for a player
  .SetMotes(player, amount)         — Set mote count
  .SetLevel(player, "Level Name")   — Set angel level
  .SetLayer(player, index)          — Set layer index
  .TeleportToLayer(player, index)   — Teleport to layer spawn
  .GiveCosmetic(player, "id")       — Grant a cosmetic item
  .CompleteQuest(player, "id")      — Mark quest as complete
  .ResetPlayer(player)              — Reset player to defaults
  .StressTest(count)                — Spawn N test parts
  .CleanStressTest()                — Remove stress test parts
  .ListRemotes()                    — List all RemoteEvents/Functions
  .MemoryStats()                    — Print memory usage info
  .Help()                           — Show this help

  Player arg can be: Player instance, partial name string, or nil (auto-selects if only 1 player)
==========================================
]])
end

return DebugConsole
