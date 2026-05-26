local module = {
	["Phase Drill"] = {
		Description = "Phases through reality to mine rare materials.";
		IngredientCount = 3;
		Ingredient1 = "Shadowite:4";
		Ingredient2 = "Cryozite:8";
		Ingredient3 = "Glimmerite:6";
	};

	["KinetiCore Drill"] = {
		Description = "Pulses with unstoppable motion energy.";
		IngredientCount = 3;
		Ingredient1 = "Gold:10";
		Ingredient2 = "Cryozite:10";
		Ingredient3 = "Silver:15";
	};
	["Stormcell Drill"] = {
		Description = "The newest modification to Charged Drill.";
		IngredientCount = 3;
		Ingredient1 = "Charged Drill:1";
		Ingredient2 = "Gold:10";
		Ingredient3 = "Glimmerite:15";
	};
	["Pulsebreaker Drill"] = {
		Description = "Direct Upgrade from Surge Drill.";
		IngredientCount = 3;
		Ingredient1 = "Surge Drill:1";
		Ingredient2 = "Cryozite:3";
		Ingredient3 = "Glimmerite:15";
	};

	["Aether Drill"] = {
		Description = "Taps into mysterious celestial energy.";
		IngredientCount = 3;
		Ingredient1 = "Obscurite:6";
		Ingredient2 = "Cryozite:10";
		Ingredient3 = "Gold:8";
	};
	
	["Impulse Driver Drill"] = {
		Description = "Direct upgrade from KinetiCore Drill.";
		IngredientCount = 4;
		Ingredient1 = "KinetiCore Drill:1";
		Ingredient2 = "Cryozite:5";
		Ingredient3 = "Pyronite:5";
		Ingredient4 = "Demonite:1";
	};

	["Nebula Drill"] = {
		Description = "Infused with nebular energy, forged from rare minerals.";
		IngredientCount = 3;
		Ingredient1 = "Cryozite:12";
		Ingredient2 = "Glimmerite:10";
		Ingredient3 = "Starstruck:10";
	};

	["Singularity Drill"] = {
		Description = "Condensed power in a singular mining unit.";
		IngredientCount = 4;
		Ingredient1 = "Obscurite:8";
		Ingredient2 = "Cryozite:12";
		Ingredient3 = "Shadowite:5";
		Ingredient4 = "Demonite:3";
	};
	
	["Void Drill"] = {
		Description = "Uses power from the Void in order to mine rare minerals.";
		IngredientCount = 3;
		Ingredient1 = "Lodestar:1";
		Ingredient2 = "Abyssite:2";
		Ingredient3 = "Dustlode:5";
	};
	
	["Arcane Drill"] = {
		Description = "Uses Arcane powers to magically bring forth rare gems and minerals.";
		IngredientCount = 2;
		Ingredient1 = "Arcana Unbound:1";
		Ingredient2 = "Arcana:3";
	};
	["HyperQuantum Drill"] = {
		Description = "Uses unimaginable quantum power to mine the rarest, most purest gems.";
		IngredientCount = 3;
		Ingredient1 = "Quantum Drill:1";
		Ingredient2 = "Starcore:3";
		Ingredient3 = "Blue Giant:3";
	};
	
	--Event Stuff from this point onwards!!
	["Summer Pack"] = {
		Description = "";
		Event = true;
		IngredientCount = 2;
		Ingredient1 = "Pearl:8";
		Ingredient2 = "Coral:8";
	};
	["Coral Drill"] = {
		Description = "";
		Event = true;
		IngredientCount = 3;
		Ingredient1 = "Pearl:10";
		Ingredient2 = "Coral:10";
		Ingredient3 = "Seaswept Coral:10";
	};
	["Tidecaller Drill"] = {
		Description = "";
		Event = true;
		IngredientCount = 4;
		Ingredient1 = "Coral Drill:5";
		Ingredient2 = "Seaswept Coral:25";
		Ingredient3 = "Pearl of the Sea:3";
		Ingredient4 = "Heart of the Sea:1";
	};
	
	["Pickaxe"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 1;
		Ingredient1 = "Stoneite:5";
	};
	["Dwarven Pickaxe"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 3;
		Ingredient1 = "Pickaxe:1";
		Ingredient2 = "Shadowite:5";
		Ingredient3 = "Shade Remnant:3";
	};
	["Reality Crusher"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 4;
		Ingredient1 = "Pickaxe:5";
		Ingredient2 = "Dwarven Pickaxe:5";
		Ingredient3 = "Solaryte:1";
		Ingredient4 = "Eclipsium:1";
	};
	["Void Chest"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 1;
		Ingredient1 = "Shade Remnant:5";
	};
	["Abyssal Void Chest"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 1;
		Ingredient1 = "Abyssal Remnant:5";
	};
	["Boundless Depths Chest"] = {
		Description = "";
		VoidEvent = true;
		IngredientCount = 3;
		Ingredient1 = "Abyssal Void Chest:1";
		Ingredient2 = "Abyssal Remnant:5";
		Ingredient3 = "Shade Remnant:5";
	};
	
	["Forest Chest"] = {
		Description = "";
		NatureEvent = true;
		IngredientCount = 2;
		Ingredient1 = "Rootcrystal:8";
		Ingredient2 = "Verdanite:1";
	};
	["NatureCore Drill"] = {
		Description = "";
		NatureEvent = true;
		IngredientCount = 2;
		Ingredient1 = "Rootcrystal:5";
		Ingredient2 = "Verdanite:1";
	};
	["NatureGate Drill"] = {
		Description = "";
		NatureEvent = true;
		IngredientCount = 3;
		Ingredient1 = "Rootcrystal:5";
		Ingredient2 = "Verdanite:5";
		Ingredient3 = "Mossrock:5";
	};
	["Gaia Drill"] = {
		Description = "";
		NatureEvent = true;
		IngredientCount = 4;
		Ingredient1 = "Rootcrystal:5";
		Ingredient2 = "Verdanite:5";
		Ingredient3 = "Mossrock:5";
		Ingredient4 = "Gaia's Heart:1";
	};
}

return module