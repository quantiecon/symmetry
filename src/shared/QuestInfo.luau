local module = {
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
	
	--Main Quest
	["Discover Crafting"] = {
		Goal = 1;
		Reward = "Gems"; 
		Amount = 30;
	};
	["Make Money"] = {
		Goal = 10000;
		Reward = "Gems"; 
		Amount = 30;
	};
	["Mine a Legendary"] = {
		Goal = 1;
		Reward = "Gems"; 
		Amount = 30;
	};
	["Expand Your Plot"] = {
		Goal = 1;
		Reward = "Gems"; 
		Amount = 30;
	};
}

return module
