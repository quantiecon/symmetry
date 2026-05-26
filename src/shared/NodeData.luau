local NodeData = {}

NodeData.Rarities = {
	{
		name  = "Common",
		color = Color3.fromRGB(139, 115, 85),
		hp    = 6,
		yield = 10,
		bonus = 1.5,
		aura  = false,
	},
	{
		name  = "Uncommon",
		color = Color3.fromRGB(80, 200, 80),
		hp    = 9,
		yield = 30,
		bonus = 1.75,
		aura  = false,
	},
	{
		name  = "Rare",
		color = Color3.fromRGB(60, 120, 255),
		hp    = 12,
		yield = 80,
		bonus = 2.0,
		aura  = false,
	},
	{
		name  = "Legendary",
		color = Color3.fromRGB(255, 220, 0),
		hp    = 18,
		yield = 200,
		bonus = 2.5,
		aura  = false,
	},
	{
		name  = "Mythic",
		color = Color3.fromRGB(180, 0, 255),
		hp    = 28,
		yield = 500,
		bonus = 3.0,
		aura  = true,
	},
}

NodeData.RarityMap = {}
for _, r in NodeData.Rarities do
	NodeData.RarityMap[r.name] = r
end

local SPAWN_CHANCES = {
	{ name = "Mythic",    chance = 1 / 100 },
	{ name = "Legendary", chance = 1 / 50  },
	{ name = "Rare",      chance = 1 / 25  },
	{ name = "Uncommon",  chance = 1 / 5   },
}

function NodeData.RollRarity()
	for _, entry in SPAWN_CHANCES do
		if math.random() <= entry.chance then
			return NodeData.RarityMap[entry.name]
		end
	end
	return NodeData.RarityMap["Common"]
end

-- Returns HP values at which crack windows fire (75%, 50%, 25% remaining HP)
function NodeData.CrackThresholds(maxHP)
	return {
		math.max(1, math.floor(maxHP * 0.75)),
		math.max(1, math.floor(maxHP * 0.50)),
		math.max(1, math.floor(maxHP * 0.25)),
	}
end

return NodeData
