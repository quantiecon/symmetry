local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local animator  = humanoid:WaitForChild("Animator")

-- ── Swap default walk / run IDs in Roblox's built-in Animate script ───────
local animate = character:WaitForChild("Animate")
animate:WaitForChild("walk"):WaitForChild("WalkAnim").Value = "rbxassetid://122235205002711"
animate:WaitForChild("run"):WaitForChild("RunAnim").Value   = "rbxassetid://100044344992725"

-- ── Six seven emote (R key) ───────────────────────────────────────────────
local emoteAnim = Instance.new("Animation")
emoteAnim.AnimationId = "rbxassetid://101861600822053"
local emoteTrack = animator:LoadAnimation(emoteAnim)
emoteTrack.Priority = Enum.AnimationPriority.Action

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.R then
		if emoteTrack.IsPlaying then
			emoteTrack:Stop(0.2)
		else
			emoteTrack:Play(0.2)
		end
	end
end)

-- Stop emote the moment the player starts moving
RunService.Heartbeat:Connect(function()
	if emoteTrack.IsPlaying and humanoid.MoveDirection.Magnitude > 0.1 then
		emoteTrack:Stop(0.2)
	end
end)
