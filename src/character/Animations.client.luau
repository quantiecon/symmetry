local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local character = script.Parent
local humanoid  = character:WaitForChild("Humanoid")
local animator  = humanoid:WaitForChild("Animator")
local hrp       = character:WaitForChild("HumanoidRootPart")

local anims = ReplicatedStorage:WaitForChild("CharacterAnims")

-- ── Walk / Run: swap IDs inside the Animate script ────────────────────────
-- Animate already handles when to play walk vs run — we just redirect it to
-- our assets. No manual LoadAnimation needed, so no HTTP fetch on the client.
local animate = character:WaitForChild("Animate")
animate:WaitForChild("walk"):WaitForChild("WalkAnim").Value = anims:WaitForChild("Walk").AnimationId
animate:WaitForChild("run"):WaitForChild("RunAnim").Value   = anims:WaitForChild("Run").AnimationId

-- ── Emote: loaded from a pre-existing ReplicatedStorage instance ──────────
-- LoadAnimation on an already-replicated Animation avoids a client HTTP fetch.
local emoteTrack = animator:LoadAnimation(anims:WaitForChild("SixSeven"))
emoteTrack.Priority = Enum.AnimationPriority.Action

RunService.Heartbeat:Connect(function()
	if not emoteTrack.IsPlaying then return end
	local vel = hrp.AssemblyLinearVelocity
	if Vector3.new(vel.X, 0, vel.Z).Magnitude > 1 then
		emoteTrack:Stop(0.2)
	end
end)

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
