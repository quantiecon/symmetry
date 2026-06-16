local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local oreFolder = Workspace:FindFirstChild("Ores") or Instance.new("Folder", Workspace)
oreFolder.Name = "Ores"

local spawnArea = Workspace:WaitForChild("OrePlaceArea") -- The part defining the spawn bounds

-- Ore rarity table (weights, higher = more common)
local ores = {
	{template = script:WaitForChild("Stoneite"), weight = 50},
	{template = script:WaitForChild("Copper"), weight = 30},
	{template = script:WaitForChild("Silver"), weight = 15},
	{template = script:WaitForChild("Shade Remnant"), weight = 10},
	{template = script:WaitForChild("Abyssal Remnant"), weight = 4},
}

local MAX_ORES = 30
local SPAWN_INTERVAL = 4 -- seconds

-- Loot rarity chances (percentages)
local LOOT_CHANCES = {
	voidChest = 5,      -- 3% chance for "Void Chest"
	abyssalVoid = 1     -- 1% chance for "Abyssal Void Chest"
}

-- Function to pick ore type based on rarity weights
local function pickRandomOre()
	local totalWeight = 0
	for _, ore in ipairs(ores) do
		totalWeight += ore.weight
	end

	local rand = math.random(1, totalWeight)
	local cumulative = 0
	for _, ore in ipairs(ores) do
		cumulative += ore.weight
		if rand <= cumulative then
			return ore.template
		end
	end
end

-- Function to get random position inside spawnArea
local function getRandomPositionInPart(part)
	local size = part.Size
	local minX = part.Position.X - size.X/2
	local maxX = part.Position.X + size.X/2
	local minY = part.Position.Y - size.Y/2
	local maxY = part.Position.Y + size.Y/2
	local minZ = part.Position.Z - size.Z/2
	local maxZ = part.Position.Z + size.Z/2

	local pos = Vector3.new(
		math.random() * (maxX - minX) + minX,
		math.random() * (maxY - minY) + minY,
		math.random() * (maxZ - minZ) + minZ
	)
	return pos
end

-- Function to maybe override Loot value based on rare chance
local function applyRareLoot(oreClone)
	if not oreClone:FindFirstChild("Loot") then return end
	if not oreClone.Loot:IsA("StringValue") then return end

	local roll = math.random(1, 100) -- percent chance

	if roll <= LOOT_CHANCES.abyssalVoid then
		oreClone.Loot.Value = "Abyssal Void Chest"
	elseif roll <= (LOOT_CHANCES.abyssalVoid + LOOT_CHANCES.voidChest) then
		oreClone.Loot.Value = "Void Chest"
	end
end

-- Main loop
while true do
	task.wait(SPAWN_INTERVAL)

	if #oreFolder:GetChildren() < MAX_ORES then
		local oreTemplate = pickRandomOre()
		local oreClone = oreTemplate:Clone()
		oreClone.Parent = oreFolder

		-- Rare loot chance
		applyRareLoot(oreClone)

		-- Position
		local pos = getRandomPositionInPart(spawnArea)
		if oreClone:IsA("Model") then
			oreClone:PivotTo(CFrame.new(pos))

			local Properties = {
				Type = "OreSpawn";
				Specifics1 = oreClone.PrimaryPart.Position;
			}

			game.ReplicatedStorage.Events.ClientFX:FireAllClients(Properties)
		elseif oreClone:IsA("BasePart") then
			oreClone.Position = pos
		end
	end
end