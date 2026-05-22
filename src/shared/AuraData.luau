-- ModuleScript: aura definitions and weighted RNG table.
-- Required by both server (to pick auras) and client (to display info).
local AuraData = {}

-- weight = how many "tickets" this aura has in the pool.
-- Higher weight → more common. Chance = weight / TotalWeight.
AuraData.Auras = {
    -- Common (~54%)
    { id = "ember",     name = "Ember",     rarity = "Common",    weight = 500, color = Color3.fromRGB(255, 120,  30) },
    { id = "frost",     name = "Frost",     rarity = "Common",    weight = 450, color = Color3.fromRGB(120, 200, 255) },

    -- Uncommon (~24%)
    { id = "nature",    name = "Nature",    rarity = "Uncommon",  weight = 180, color = Color3.fromRGB( 80, 200,  80) },
    { id = "storm",     name = "Storm",     rarity = "Uncommon",  weight = 150, color = Color3.fromRGB(150, 100, 255) },

    -- Rare (~6%)
    { id = "shadow",    name = "Shadow",    rarity = "Rare",      weight = 45,  color = Color3.fromRGB( 60,  30, 100) },
    { id = "inferno",   name = "Inferno",   rarity = "Rare",      weight = 40,  color = Color3.fromRGB(255,  40,   0) },

    -- Epic (~1%)
    { id = "void",      name = "Void",      rarity = "Epic",      weight = 8,   color = Color3.fromRGB( 20,   0,  50) },
    { id = "celestial", name = "Celestial", rarity = "Epic",      weight = 6,   color = Color3.fromRGB(255, 220, 100) },

    -- Legendary (~0.07%)
    { id = "divine",    name = "Divine",    rarity = "Legendary", weight = 1,   color = Color3.fromRGB(255, 255, 200) },
}

AuraData.TotalWeight = 0
for _, aura in AuraData.Auras do
    AuraData.TotalWeight += aura.weight
end

-- UI colors per rarity tier
AuraData.RarityColors = {
    Common    = Color3.fromRGB(200, 200, 200),
    Uncommon  = Color3.fromRGB(100, 220, 100),
    Rare      = Color3.fromRGB( 80, 120, 255),
    Epic      = Color3.fromRGB(180,  80, 255),
    Legendary = Color3.fromRGB(255, 180,   0),
}

return AuraData
