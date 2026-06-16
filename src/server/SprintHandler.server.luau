local Events = game.ReplicatedStorage.Events

local BASE_SPEED   = 25
local SPRINT_SPEED = 50
local SPEED_MULT   = 1.6  -- matches SpeedProduct multiplier used in Main

Events.SprintToggle.OnServerEvent:Connect(function(player, isSprinting)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local PlayerData = game.ServerStorage.PlayerData:FindFirstChild(player.Name.."Data")
	local hasSpeedProduct = PlayerData
		and PlayerData:FindFirstChild("SpeedProduct")
		and PlayerData.SpeedProduct.Value == true

	if isSprinting then
		humanoid.WalkSpeed = hasSpeedProduct and (SPRINT_SPEED * SPEED_MULT) or SPRINT_SPEED
	else
		humanoid.WalkSpeed = hasSpeedProduct and (BASE_SPEED * SPEED_MULT) or BASE_SPEED
	end
end)
