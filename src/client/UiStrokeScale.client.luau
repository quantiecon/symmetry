task.wait(1)

local player = game.Players.LocalPlayer
local function scalestroke(stroke)
	local basethickness = stroke.Thickness
	local scaleFactor = workspace.CurrentCamera.ViewportSize.X / 1920
	stroke.Thickness = basethickness * scaleFactor
end

local function autoscalestroke()
	for _,gui in ipairs(player.PlayerGui:GetDescendants()) do
		if gui:IsA("UIStroke") then
			scalestroke(gui)
		end
	end
end

player.PlayerGui.DescendantAdded:Connect(function(d)
	if d:IsA("UIStroke") then
		--scalestroke(d)
	end
end)

autoscalestroke()