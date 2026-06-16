local Player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local Events = game.ReplicatedStorage.Events

Events.PlaceDrill.OnClientEvent:Connect(function(Drill,Action)
	for i,v in pairs(Drill:GetChildren()) do
		if v.Name == "MOVE" then
			task.spawn(function()
				while true do
					local Tween = TweenService:Create(v,TweenInfo.new(1,Enum.EasingStyle.Linear),{Orientation = v.Orientation + Vector3.new(0,720,0)})
					Tween:Play()
					Tween.Completed:Wait()
					v.Orientation -= Vector3.new(0,720,0)
				end
			end)
		end
	end
	
	if Action then
		local DrillData = Drill:FindFirstChild("Data")
		local Smoke = game.ReplicatedStorage.Visuals.placementvfx:Clone()
		Smoke.Parent = Drill
		Smoke.Transparency = 1
		Smoke.CFrame = Drill:FindFirstChild("Hitbox").CFrame
		game.Debris:AddItem(Smoke,4)
		
		local PlaceSFX = game.ReplicatedStorage.SFX.Place:Clone()
		PlaceSFX.Parent = Drill
		PlaceSFX:Play()
		game.Debris:AddItem(PlaceSFX,2)
		
		if DrillData.Max.Value > 400 then
			for i,v in pairs(Smoke.large:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end
		elseif DrillData.Max.Value > 99 then
			for i,v in pairs(Smoke.medium:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end
		else
			for i,v in pairs(Smoke.small:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end
		end
	end
end)
