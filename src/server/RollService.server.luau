-- Script (runs on server): handles roll requests and fires results back to each player.
-- Server owns the RNG so clients can't manipulate their own outcome.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AuraData = require(ReplicatedStorage.Shared.AuraData)
local Remotes = ReplicatedStorage.Remotes

local ROLL_COOLDOWN = 1 -- seconds; prevents spam-clicking

-- Per-player timestamp of their last roll (cleaned up on leave)
local lastRoll: { [Player]: number } = {}

local function pickAura()
    local roll = math.random(1, AuraData.TotalWeight)
    local cumulative = 0
    for _, aura in AuraData.Auras do
        cumulative += aura.weight
        if roll <= cumulative then
            return aura
        end
    end
    return AuraData.Auras[1] -- unreachable, satisfies type checker
end

-- OnServerEvent receives the player automatically as the first arg
Remotes.RollAura.OnServerEvent:Connect(function(player: Player)
    local now = os.clock()
    if lastRoll[player] and (now - lastRoll[player]) < ROLL_COOLDOWN then
        return
    end
    lastRoll[player] = now

    local aura = pickAura()
    Remotes.AuraResult:FireClient(player, aura)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    lastRoll[player] = nil
end)
