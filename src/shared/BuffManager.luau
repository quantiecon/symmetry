local module = {}

-- Returns a random drill from a folder
function GetRandomDrill(Drills)
	local validDrills = {}
	for _, v in pairs(Drills:GetChildren()) do
		if v:FindFirstChild("Data") then
			table.insert(validDrills, v)
		end
	end
	if #validDrills == 0 then return end
	return validDrills[math.random(1, #validDrills)]
end

function module:Passive(Player, Worker)
	local destroyed = false
	local luckBonus = nil
	local oreYieldBonus = nil
	local applied = false
	local characterAddedConn

	local luckBonuses = {
		-- Common
		["Dusty Dana"] = 0.05,
		["Miner Mike"] = 0.05,
		["Pickaxe Pete"] = 0.05,
		["Sandy Sarah"] = 0.05,
		["Shovel Shane"] = 0.05,
		["Miner Dave"] = 0.05,

		-- Rare
		["Reef Roberta"] = 0.1,
		["Tunnel Tina"] = 0.1,
		["Rusty Ray"] = 0.1,
		["lil xxtension"] = 0.15,
		["yukki"] = 0.15,
		["Disgraced Baron"] = 0.3,
		["Federation Baron"] = 0.4,

		-- Epic
		["Captain Brine"] = 0.35,
		["Cave Carla"] = 0.4,
		["albert"] = 0.45,
		["akuma"] = 0.45,
		["cog"] = 0.45,
		["Disgraced Duke"] = 0.7,
		["Federation Duke"] = 0.8,
		["Dwarven Miner"] = 0.6,

		-- Legendary
		["Aetherborn"] = 1,
		["Frostborn Guard"] = 1,
		["Disgraced King"] = 1.5,
		["Federation King"] = 1.6,

		-- Mythical
		["Mysterious Investor"] = 1.3,
		["bean"] = 1.4,
		["sunny"] = 1.41,
		["Empyreus"] = 1.25,
		["Dominus Dane"] = 2.5,
		["Poseidon"] = 2,
		["Noli"] = 3,
		["Dryad"] = 3,


		-- Celestial
		["Noli Unbound"] = 4,
		["Noli Depthless"] = 4,
	}

	local OreYieldBonuses = {
		-- Common
		["Miner Dave"] = 0.05,

		-- Epic
		["Dwarven Miner"] = 0.1,
		
		--Mythical
		["Dryad"] = 0.15,

		-- Celestial
		["Noli Depthless"] = 0.25,
	}

	local function applyBonus(Character)
		if destroyed or applied then return end

		local Luck = Character:FindFirstChild("Luck") or Character:WaitForChild("Luck", 5)
		local OreYield = Character:FindFirstChild("OreYield") or Character:WaitForChild("OreYield", 5)

		if not Luck or not OreYield then return end

		-- Luck bonus
		luckBonus = luckBonuses[Worker.Name]
		if luckBonus then
			Luck.Value += luckBonus
		end

		-- OreYield bonus
		oreYieldBonus = OreYieldBonuses[Worker.Name]
		if oreYieldBonus then
			OreYield.Value += oreYieldBonus
		end

		applied = true
	end

	local function cleanup(Character)
		if destroyed then return end
		destroyed = true

		if characterAddedConn then
			characterAddedConn:Disconnect()
		end

		local Luck = Character:FindFirstChild("Luck")
		local OreYield = Character:FindFirstChild("OreYield")

		if Luck and luckBonus then
			Luck.Value -= luckBonus
		end

		if OreYield and oreYieldBonus then
			OreYield.Value -= oreYieldBonus
		end
	end

	-- Set up respawn connection ONCE
	characterAddedConn = Player.CharacterAdded:Connect(function(char)
		if destroyed then return end
		applied = false
		applyBonus(char)
	end)

	-- Initial application
	if Player.Character then
		applyBonus(Player.Character)
	end

	-- Cleanup when worker is removed
	Worker.Destroying:Connect(function()
		if Player.Character then
			cleanup(Player.Character)
		end
	end)
end

return module