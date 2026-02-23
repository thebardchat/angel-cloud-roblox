--[[
	Types.lua — Centralized Luau type definitions for Angel Cloud ROBLOX
	ModuleScript → ReplicatedStorage.Shared.Types

	Usage:
		local Types = require(ReplicatedStorage.Shared.Types)
		local data: Types.PlayerData = DataManager.GetData(player)
]]

export type PlayerData = {
	motes: number,
	angelLevel: string,
	layerIndex: number,
	collectedFragments: { [string]: boolean },
	ownedCosmetics: { [string]: boolean },
	equippedCosmetics: { [string]: boolean },
	equippedWingSkin: string,
	equippedTrail: string,
	equippedNameGlow: string,
	blessingsGiven: number,
	blessingsReceived: number,
	longestBlessingChain: number,
	trialsCompleted: { [string]: boolean },
	newbornsHelped: number,
	totalPlaytime: number,
	sessionStart: number,
	linkedAngelCloud: boolean,
	angelCloudUserId: string,
	robloxLinkCode: string,
	founderHalo: boolean,
	starfishFound: { [string]: boolean },
	redeemedDialCodes: { [string]: boolean },
	wingLevel: number,
	activeQuest: string,
	questProgress: number,
	completedQuests: { [string]: boolean },
	firstJoin: number,
	lastSeen: number,
}

export type LayerDefinition = {
	name: string,
	layerIndex: number,
	angelLevel: string,
	requiredMotes: number,
	gateThreshold: number?,
	loreFragmentCount: number,
	description: string,
	color: Color3,
	features: { string },
	spawnPosition: Vector3,
	heightRange: { min: number, max: number },
}

export type CosmeticItem = {
	id: string,
	name: string,
	category: string,
	price: number,
	description: string,
	color: Color3?,
	requiredLayer: number?,
	earned: boolean?,
	earnMethod: string?,
	includes: { string }?,
}

export type FragmentDefinition = {
	id: string,
	name: string,
	layer: number,
	text: string,
	hint: string?,
	rarity: string?,
}

export type TrialDefinition = {
	id: string,
	name: string,
	description: string,
	layer: number,
	type: string,
	timeLimit: number?,
	requiredPlayers: number?,
	rewards: TrialRewards,
}

export type TrialRewards = {
	motes: number,
	fragment: string?,
	cosmetic: string?,
	badge: string?,
}

export type QuestDefinition = {
	id: string,
	name: string,
	description: string,
	objective: string,
	target: number,
	rewards: QuestRewards,
	nextQuest: string?,
	requiredLevel: string?,
}

export type QuestRewards = {
	motes: number,
	cosmetic: string?,
	badge: string?,
}

export type ServerMessage = {
	type: string,
	message: string,
	angelLevel: string?,
	motes: number?,
	duration: number?,
}

export type BlessingData = {
	fromPlayer: Player,
	toPlayer: Player,
	chainLength: number,
	timestamp: number,
}

export type NPCDefinition = {
	id: string,
	name: string,
	role: string,
	layer: number,
	position: Vector3,
	dialogue: { string },
}

export type ShopTransaction = {
	itemId: string,
	playerId: number,
	price: number,
	currency: string,
	timestamp: number,
	success: boolean,
}

return {}
