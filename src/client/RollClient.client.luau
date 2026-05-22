-- LocalScript (runs on each player's client): sends roll requests and receives results.
-- UI wiring lives here once we build the roll button.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Remotes are defined in default.project.json so they always exist at this path
local Remotes = ReplicatedStorage.Remotes

-- Handle result coming back from the server
Remotes.AuraResult.OnClientEvent:Connect(function(aura)
    -- TODO: replace print with aura visual + UI notification
    print(string.format("[AuraRNG] Rolled: %s (%s)", aura.name, aura.rarity))
end)

-- Temporary keyboard trigger (Spacebar) until the roll button UI is built
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        Remotes.RollAura:FireServer()
    end
end)
