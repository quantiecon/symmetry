local TweenService = game:GetService("TweenService")

task.spawn(function()
	while true do
		local Tween = TweenService:Create(script.Parent["spinning part"],TweenInfo.new(2,Enum.EasingStyle.Linear),{Orientation = script.Parent["spinning part"].Orientation + Vector3.new(0,720,0)})
		Tween:Play()
		Tween.Completed:Wait()
		script.Parent["spinning part"].Orientation -= Vector3.new(0,720,0)
	end
end)