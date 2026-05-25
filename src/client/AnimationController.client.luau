local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local animator  = humanoid:WaitForChild("Animator")

-- Load the KeyframeSequence directly (works in Studio play-test and uncopylocked places;
-- published games need an uploaded animation ID instead)
local walkSeq   = ReplicatedStorage.Shared.Animations:WaitForChild("basic walk")
local walkTrack = animator:LoadAnimation(walkSeq)
walkTrack.Priority = Enum.AnimationPriority.Action

local isPlaying = false

RunService.Heartbeat:Connect(function()
	local moving = humanoid.MoveDirection.Magnitude > 0.1

	if moving and not isPlaying then
		walkTrack:Play(0.2)   -- 0.2s fade-in
		isPlaying = true
	elseif not moving and isPlaying then
		walkTrack:Stop(0.2)   -- 0.2s fade-out
		isPlaying = false
	end
end)

-- Handle respawn
player.CharacterAdded:Connect(function(newChar)
	character  = newChar
	humanoid   = newChar:WaitForChild("Humanoid")
	animator   = humanoid:WaitForChild("Animator")
	walkTrack  = animator:LoadAnimation(walkSeq)
	walkTrack.Priority = Enum.AnimationPriority.Action
	isPlaying  = false
end)
