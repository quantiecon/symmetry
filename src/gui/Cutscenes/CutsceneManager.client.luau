local Events = game.ReplicatedStorage.Events
local TweenService = game:GetService("TweenService")

Events.Cutscene.OnClientEvent:Connect(function(Rarity)
	if script.Parent:FindFirstChild("CutsceneInProgress") then
		return
	end
	
	if Rarity == "Secret" then
		local InProgress = Instance.new("Folder")
		InProgress.Name = "CutsceneInProgress"
		InProgress.Parent = script.Parent
		game.Debris:AddItem(InProgress,5)
		
		local Cutscene = script.Parent.SecretCutscene
		Cutscene.BackgroundTransparency = 0
		Cutscene.BackgroundColor3 = Color3.new(0, 0, 0)
		Cutscene.MainStar.Rotation = 0
		Cutscene.MainStar.ImageTransparency = 0
		Cutscene.MainStar.ImageColor3 = Color3.new(1, 1, 1)
		Cutscene.MainStar.Size = UDim2.new(0.364, 0,0.783, 0)
		
		script.Parent.SecretCutscene.Visible = true
		TweenService:Create(Cutscene.MainStar,TweenInfo.new(4),{Rotation = Cutscene.MainStar.Rotation + 360}):Play()
		TweenService:Create(Cutscene.MainStar,TweenInfo.new(4),{Size = UDim2.new(0.212, 0,0.429, 0)}):Play()
		task.delay(2,function()
			TweenService:Create(Cutscene.MainStar,TweenInfo.new(2),{ImageColor3 = Color3.new(0, 0, 0)}):Play()
		end)
		
		Cutscene.Crescendo:Play()
		
		task.delay(4.5,function()
			Cutscene.Pop:Play()
			Cutscene.MainStar.ImageColor3 = Color3.new(1, 1, 1)
			Cutscene.BackgroundColor3 = Color3.new(1, 1, 1)
			TweenService:Create(Cutscene.MainStar,TweenInfo.new(0.7),{Size = UDim2.new(0.5, 0,0.491, 0)}):Play()
			TweenService:Create(Cutscene.MainStar,TweenInfo.new(1),{Size = UDim2.new(20, 0,20, 0)}):Play()
			
			task.wait(0.3)
			
			TweenService:Create(Cutscene,TweenInfo.new(0.7),{BackgroundTransparency = 1}):Play()
			TweenService:Create(Cutscene.MainStar,TweenInfo.new(0.7),{ImageTransparency = 1}):Play()
		end)
		
	end
end)