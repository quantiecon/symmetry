-- Replaces the default run animation ID in Roblox's built-in Animate script.
-- StarterCharacterScripts re-runs this automatically on every respawn.
local animate = script.Parent:WaitForChild("Animate")
animate:WaitForChild("run"):WaitForChild("RunAnim").Value = "rbxassetid://100044344992725"
