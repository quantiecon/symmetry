local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local animator  = humanoid:WaitForChild("Animator")
local hrp       = character:WaitForChild("HumanoidRootPart")

-- Speed below this plays walk; at or above plays run.
-- Base walk = 16, sprint = 25.6 — 20 sits cleanly in between.
local WALK_RUN_THRESHOLD = 20

local function makeTrack(id, priority)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	local track = animator:LoadAnimation(anim)
	track.Priority = priority
	return track
end

-- Action priority overrides whatever Animate plays for walk/run
local walkTrack  = makeTrack("122235205002711", Enum.AnimationPriority.Action)
local runTrack   = makeTrack("100044344992725", Enum.AnimationPriority.Action)
local emoteTrack = makeTrack("101861600822053", Enum.AnimationPriority.Action)

-- ── Movement loop ─────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	-- Horizontal speed only (ignore vertical so jumping doesn't affect it)
	local vel   = hrp.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local moving = speed > 1

	if emoteTrack.IsPlaying then
		-- Emote cancels on movement
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
