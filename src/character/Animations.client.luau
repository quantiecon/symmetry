local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local animator  = humanoid:WaitForChild("Animator")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- Animation objects live in ReplicatedStorage so they are created by the
-- server at startup and replicated — no client-side HTTP fetch required.
local anims      = ReplicatedStorage:WaitForChild("CharacterAnims")
local walkTrack  = animator:LoadAnimation(anims:WaitForChild("Walk"))
local runTrack   = animator:LoadAnimation(anims:WaitForChild("Run"))
local emoteTrack = animator:LoadAnimation(anims:WaitForChild("SixSeven"))

walkTrack.Priority  = Enum.AnimationPriority.Action
runTrack.Priority   = Enum.AnimationPriority.Action
emoteTrack.Priority = Enum.AnimationPriority.Action

-- Speed below this plays walk; at or above plays run.
-- Base walk = 16, sprint = 25.6 — 20 sits cleanly in between.
local WALK_RUN_THRESHOLD = 20

-- ── Movement loop ─────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	local vel   = hrp.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local moving = speed > 1

	if emoteTrack.IsPlaying then
		if moving then emoteTrack:Stop(0.2) end
		return
	end

	if moving and speed < WALK_RUN_THRESHOLD then
		if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
		if runTrack.IsPlaying      then runTrack:Stop(0.2)  end
	elseif moving then
		if not runTrack.IsPlaying  then runTrack:Play(0.2)  end
		if walkTrack.IsPlaying     then walkTrack:Stop(0.2) end
	else
		if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
		if runTrack.IsPlaying  then runTrack:Stop(0.2)  end
	end
end)

-- ── Emote (R key) ─────────────────────────────────────────────────────────
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
