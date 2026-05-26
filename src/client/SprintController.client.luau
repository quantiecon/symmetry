local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player       = Players.LocalPlayer
local BASE_SPEED   = 16
local SPRINT_SPEED = BASE_SPEED * 1.6  -- 21.6

local function humanoid()
	local char = player.Character
	return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function isSprinting()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode ~= Enum.KeyCode.LeftShift
		and input.KeyCode ~= Enum.KeyCode.RightShift then return end
	local hum = humanoid()
	if hum then hum.WalkSpeed = SPRINT_SPEED end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.LeftShift
		and input.KeyCode ~= Enum.KeyCode.RightShift then return end
	local hum = humanoid()
	if hum then hum.WalkSpeed = BASE_SPEED end
end)

-- Reapply sprint speed if Shift is already held when character respawns
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	if isSprinting() then
		hum.WalkSpeed = SPRINT_SPEED
	end
end)
