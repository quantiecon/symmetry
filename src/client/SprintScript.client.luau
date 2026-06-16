-- Shift toggles sprint on/off.  Server (SprintHandler) applies the speed.
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events      = ReplicatedStorage:WaitForChild("Events")
local SprintToggle = Events:WaitForChild("SprintToggle")

local isSprinting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= Enum.KeyCode.LeftShift and input.KeyCode ~= Enum.KeyCode.RightShift then return end

	isSprinting = not isSprinting
	SprintToggle:FireServer(isSprinting)
end)

-- Safety: always stop sprinting when the character is removed (respawn / death)
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
	if isSprinting then
		isSprinting = false
	end
end)
