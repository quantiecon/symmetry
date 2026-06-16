local module = {
	-- ── Daily quests ──────────────────────────────────────────────────────────
	["Collect Ores"] = {
		Daily = true;
		Goal = 10000;
		Reward = "Chest";
	};
	["Buy From Wandering Merchant"] = {
		Daily = true;
		Goal = 2;
		Reward = "Chest";
	};
	["Craft an Item"] = {
		Daily = true;
		Goal = 1;
		Reward = "Chest";
	};

	-- ── Main quest chain (sequential) ─────────────────────────────────────────
	-- 1. Craft anything once
	["Discover Crafting"] = {
		Goal = 1;
		Reward = "Gems";
		Amount = 30;
	};
	-- 2. Sell ore for 10,000 coins total
	["Make Money"] = {
		Goal = 10000;
		Reward = "Coins";
		Amount = 50000;
	};
	-- 3. Mine any legendary-rarity ore
	["Mine a Legendary"] = {
		Goal = 1;
		Reward = "Gems";
		Amount = 50;
	};
	-- 4. Buy a plot expansion
	["Expand Your Plot"] = {
		Goal = 1;
		Reward = "Gems";
		Amount = 50;
	};
	-- 5. Craft 10 items total
	["Grand Craftsman"] = {
		Goal = 10;
		Reward = "Gems";
		Amount = 75;
	};
	-- 6. Earn 1,000,000 coins total from selling
	["The Rich"] = {
		Goal = 1000000;
		Reward = "Coins";
		Amount = 500000;
	};
	-- 7. Mine 10 legendary-rarity ores
	["Legend Hunter"] = {
		Goal = 10;
		Reward = "Gems";
		Amount = 100;
	};
	-- 8. Collect 50,000 ores from drills
	["Dedicated Miner"] = {
		Goal = 50000;
		Reward = "Gems";
		Amount = 200;
	};
}

return module
