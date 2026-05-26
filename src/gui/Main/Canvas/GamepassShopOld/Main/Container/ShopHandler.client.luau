local Events = game.ReplicatedStorage.Events
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local PolicyService = game:GetService("PolicyService")

local TweenService = game:GetService("TweenService")
local RNG = Random.new()

local function applyClickTween(button: GuiButton)
	local downTween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = button.Position + UDim2.new(0, 0, 0.02, 0)
	})

	local upTween = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = button.Position
	})

	button.MouseButton1Click:Connect(function()
		downTween:Play()
		downTween.Completed:Wait()
		upTween:Play()
	end)
end

local function applyHoverEffect(button, scaleAmount, tweenTime)
	-- Default values if none provided
	scaleAmount = scaleAmount or 1.1
	tweenTime = tweenTime or 0.2

	local originalSize = button.Size
	local hoverSize = UDim2.new(
		originalSize.X.Scale * scaleAmount,
		originalSize.X.Offset * scaleAmount,
		originalSize.Y.Scale * scaleAmount,
		originalSize.Y.Offset * scaleAmount
	)

	local enlargeTween = TweenService:Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = hoverSize
	})
	local shrinkTween = TweenService:Create(button, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = originalSize
	})

	button.MouseEnter:Connect(function()
		enlargeTween:Play()
	end)

	button.MouseLeave:Connect(function()
		shrinkTween:Play()
	end)
end

local function animateGradientRotation(gradient: UIGradient)
	local rotation = 0
	local speed = 30 -- degrees per second, adjust for faster/slower

	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not gradient or not gradient.Parent then
			connection:Disconnect()
			return
		end

		rotation = (rotation + dt * speed) % 360
		gradient.Rotation = rotation
	end)
end
for i,v in pairs(script.Parent:GetChildren()) do
	if v.Name == "StarterBundle" or v.Name == "AdvancedBundle" then
		for _,k in pairs(v:GetChildren()) do
			if k:FindFirstChildWhichIsA("ViewportFrame") and game.ReplicatedStorage.System.Parts:FindFirstChild(k.Name) then
				local viewport = k:FindFirstChild("Viewport")
				local model = game.ReplicatedStorage.System.Parts:FindFirstChild(k.Name):Clone()

				local camera = Instance.new("Camera")
				camera.FieldOfView = 70
				camera.Parent = viewport

				model.Parent = viewport
				viewport.CurrentCamera = camera

				local vpfModel = ViewportModel.new(viewport, camera)
				local cf, size = model:GetBoundingBox()

				vpfModel:SetModel(model)

				local theta = 0
				local orientation = CFrame.new()
				local distance = vpfModel:GetFitDistance(cf.Position)

				task.spawn(function()
					game:GetService("RunService").RenderStepped:Connect(function(dt)
						theta = theta + math.rad(20 * dt)
						orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
						camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
					end)
				end)
			end
			
			if k.Name == "Icon" then
				task.spawn(function()
					while wait(RNG:NextNumber(0,1)) do
						local Star = script:FindFirstChild("Star1"):Clone()
						Star.Parent = k
						Star.Position = UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
						game.Debris:AddItem(Star,3)

						local tween = TweenService:Create(Star,TweenInfo.new(1.5),{Size = UDim2.new(0.6,0,0.6,0)})
						tween:Play()
						task.delay(2,function()
							TweenService:Create(Star,TweenInfo.new(1),{Size = UDim2.new(0,0,0,0)}):Play()
						end)

					end
				end)
			end
		end
	elseif v.Name == "VIP" or v.Name == "MVP" or v.Name == "LegendaryGemPack" then
		task.spawn(function()
			while wait(RNG:NextNumber(0.2,1)) do
				local Star = script:FindFirstChild("Star1"):Clone()
				Star.Parent = v:FindFirstChild("Icon")
				Star.Position = UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
				game.Debris:AddItem(Star,3)

				local tween = TweenService:Create(Star,TweenInfo.new(1.5),{Size = UDim2.new(0.7,0,0.7,0)})
				tween:Play()
				task.delay(2,function()
					TweenService:Create(Star,TweenInfo.new(1),{Size = UDim2.new(0,0,0,0)}):Play()
				end)
				
			end
		end)
		
	elseif v.Name == "SummerEventBundles" then
		for _,k in pairs(v:GetDescendants()) do
			if k:IsA("ViewportFrame") and game.ReplicatedStorage.ToolDisplay:FindFirstChild(k.Name) then
				local viewport = k
				local model = game.ReplicatedStorage.ToolDisplay:FindFirstChild(k.Name):Clone()

				local camera = Instance.new("Camera")
				camera.FieldOfView = 70
				camera.Parent = viewport

				model.Parent = viewport
				viewport.CurrentCamera = camera

				local vpfModel = ViewportModel.new(viewport, camera)
				local cf, size = model:GetBoundingBox()

				vpfModel:SetModel(model)

				local theta = 0
				local orientation = CFrame.new()
				local distance = vpfModel:GetFitDistance(cf.Position)

				task.spawn(function()
					game:GetService("RunService").RenderStepped:Connect(function(dt)
						theta = theta + math.rad(20 * dt)
						orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
						camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
					end)
				end)
			end
		end
		
		local gradient = v:FindFirstChild("ProSummer") and v.ProSummer:FindFirstChild("Header") and v.ProSummer.Header:FindFirstChild("UIGradient")
		if gradient then
			task.spawn(function()
				animateGradientRotation(gradient)
			end)
		else
			warn("UIGradient not found in SummerEventBundles")
		end
	elseif v.Name == "SummerEventPageBIG" then
		for _,k in pairs(v:GetChildren()) do
			if k:FindFirstChildWhichIsA("ViewportFrame") and game.ReplicatedStorage.Workers:FindFirstChild(k.Name) then
				local viewport = k:FindFirstChild("Viewport")
				if viewport and viewport:IsA("ViewportFrame") then
					-- Clean any existing children in the viewport
					viewport:ClearAllChildren()

					-- Clone the model
					local model = game.ReplicatedStorage.Workers:FindFirstChild(k.Name):Clone()

					-- Create and configure WorldModel
					local worldModel = Instance.new("WorldModel")
					worldModel.Parent = viewport

					-- Parent the model to the WorldModel
					model.Parent = worldModel

					-- Create and configure the Camera
					local camera = Instance.new("Camera")
					camera.CFrame = CFrame.new(0,0,-5) * CFrame.Angles(0,math.rad(180),0) -- Adjust as needed
					viewport.CurrentCamera = camera
					camera.Parent = viewport

					-- Optional: Move model to origin or adjust position if needed
					model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

					-- Play emote animation
					local humanoid = model:WaitForChild("Humanoid")
					local emote = humanoid:LoadAnimation(game.ReplicatedStorage.Animations:FindFirstChild("Emote"..math.random(1,2)))
					emote:Play()
				end
				
			end
			
			if k.Name == "TidecallerDrill" then
				task.spawn(function()
					while wait(RNG:NextNumber(0,1)) do
						local Star = script:FindFirstChild("Star1"):Clone()
						Star.Parent = k:FindFirstChild("ImageLabel")
						Star.Position = UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
						game.Debris:AddItem(Star,3)

						local tween = TweenService:Create(Star,TweenInfo.new(1.5),{Size = UDim2.new(0.3,0,0.3,0)})
						tween:Play()
						task.delay(2,function()
							TweenService:Create(Star,TweenInfo.new(1),{Size = UDim2.new(0,0,0,0)}):Play()
						end)

					end
				end)
			end
		end
	elseif v.Name == "DominusDaneAndEmp" then
		for _,k in pairs(v:GetDescendants()) do
			if k:FindFirstChildWhichIsA("ViewportFrame") and game.ReplicatedStorage.Workers:FindFirstChild(k.Name) then
				local viewport = k:FindFirstChild("Viewport")
				if viewport and viewport:IsA("ViewportFrame") then
					-- Clean any existing children in the viewport
					viewport:ClearAllChildren()

					-- Clone the model
					local model = game.ReplicatedStorage.Workers:FindFirstChild(k.Name):Clone()

					-- Create and configure WorldModel
					local worldModel = Instance.new("WorldModel")
					worldModel.Parent = viewport

					-- Parent the model to the WorldModel
					model.Parent = worldModel

					-- Create and configure the Camera
					local camera = Instance.new("Camera")
					camera.CFrame = CFrame.new(0,0,-5) * CFrame.Angles(0,math.rad(180),0) -- Adjust as needed
					viewport.CurrentCamera = camera
					camera.Parent = viewport

					-- Optional: Move model to origin or adjust position if needed
					model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))

					-- Play emote animation
					local humanoid = model:WaitForChild("Humanoid")
					local emote = humanoid:LoadAnimation(game.ReplicatedStorage.Animations:FindFirstChild("Emote"..math.random(1,2)))
					emote:Play()
				end
				
				task.spawn(function()
					while wait(RNG:NextNumber(0,1)) do
						local Star = script:FindFirstChild("Star1"):Clone()
						Star.Parent = viewport.Parent
						Star.Position = UDim2.new(RNG:NextNumber(0,1),0,RNG:NextNumber(0,1),0)
						if viewport.Parent.Name == "Dominus Dane" then
							Star.ImageColor3 = Color3.new(1, 0.109804, 0.12549)
						else
							Star.ImageColor3 = Color3.new(1, 0.956863, 0.368627)
						end
						game.Debris:AddItem(Star,3)

						local tween = TweenService:Create(Star,TweenInfo.new(1.5),{Size = UDim2.new(0.6,0,0.6,0)})
						tween:Play()
						task.delay(2,function()
							TweenService:Create(Star,TweenInfo.new(1),{Size = UDim2.new(0,0,0,0)}):Play()
						end)

					end
				end)
			end
		end
	end
	
	if v.Name == "LegendaryGemPack" then
		applyHoverEffect(v.Buy)
		v.Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3318480558)
		end)
	elseif v.Name == "3Slot" then
		applyHoverEffect(v["Gems 1"].Buy)
		applyHoverEffect(v["Gems 2"].Buy)
		applyHoverEffect(v["Gems 3"].Buy)
		v["Gems 1"].Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3318480818)
		end)
		v["Gems 2"].Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3318481054)
		end)
		v["Gems 3"].Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3318481270)
		end)
	elseif v.Name == "StarterBundle" then
		applyHoverEffect(v.Buy)
		v.Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319216900)
		end)
	elseif v.Name == "AdvancedBundle" then
		applyHoverEffect(v.Buy)
		v.Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320033456)
		end)
	elseif v.Name == "PlotAndWorkerEquippedExpansion" then
		local plotTier = Events.Get:InvokeServer({"BoughtPlotExpansions"}).BoughtPlotExpansions
		if plotTier >=4 then
			script.Parent.PlotAndWorkerEquippedExpansion.ExpandPlot.BuyGems:Destroy()
			script.Parent.PlotAndWorkerEquippedExpansion.ExpandPlot.Buy.Main.TextLabel.Text = "Maxed!"
		else
			applyHoverEffect(v.ExpandPlot.Buy)
			applyHoverEffect(v.ExpandPlot.BuyGems)
			v.ExpandPlot.Buy.MouseButton1Click:Connect(function()
				local plotTier = Events.Get:InvokeServer({"BoughtPlotExpansions"}).BoughtPlotExpansions
				if plotTier >=4 then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319297071)
			end)
			v.ExpandPlot.BuyGems.MouseButton1Click:Connect(function()
				local plotTier = Events.Get:InvokeServer({"BoughtPlotExpansions"}).BoughtPlotExpansions
				if plotTier >=4 then return end
				Events.BuyWithDiamonds:FireServer("PlotExpansion")
			end)
		end
		
		if Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier2" then
			script.Parent.PlotAndWorkerEquippedExpansion.WorkerEquipped.BuyGems:Destroy()
			script.Parent.PlotAndWorkerEquippedExpansion.WorkerEquipped.Buy.Main.TextLabel.Text = "Maxed!"
		else
			applyHoverEffect(v.WorkerEquipped.Buy)
			applyHoverEffect(v.WorkerEquipped.BuyGems)
			v.WorkerEquipped.Buy.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier2" then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319316190)
			end)
			v.WorkerEquipped.BuyGems.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier2" then return end
				Events.BuyWithDiamonds:FireServer("WorkersEquipped")
			end)
		end
	elseif v.Name == "MaxDrillsAndWalkSpeed" then
		if Events.Get:InvokeServer({"SpeedProduct"}).SpeedProduct == true then
			script.Parent.MaxDrillsAndWalkSpeed.Walkspeed.BuyGems:Destroy()
			script.Parent.MaxDrillsAndWalkSpeed.Walkspeed.Buy.Main.TextLabel.Text = "Maxed!"
		else
			applyHoverEffect(v.Walkspeed.Buy)
			applyHoverEffect(v.Walkspeed.BuyGems)
			v.Walkspeed.Buy.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"SpeedProduct"}).SpeedProduct == true then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320601586)
			end)
			v.Walkspeed.BuyGems.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"SpeedProduct"}).SpeedProduct == true then return end
				Events.BuyWithDiamonds:FireServer("2xSpeed")
			end)
		end

		if Events.Get:InvokeServer({"MaxDrills"}).MaxDrills == "Tier2" then
			script.Parent.MaxDrillsAndWalkSpeed.MaxDrills.BuyGems:Destroy()
			script.Parent.MaxDrillsAndWalkSpeed.MaxDrills.Buy.Main.TextLabel.Text = "Maxed!"
		else
			applyHoverEffect(v.MaxDrills.Buy)
			applyHoverEffect(v.MaxDrills.BuyGems)
			v.MaxDrills.Buy.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"MaxDrills"}).MaxDrills == "Tier2" then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320593298)
			end)
			v.MaxDrills.BuyGems.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"MaxDrills"}).MaxDrills == "Tier2" then return end
				Events.BuyWithDiamonds:FireServer("DrillLimit")
			end)
		end
	elseif v.Name == "LuckAndBuy" then
		applyHoverEffect(v.FillAll.Buy)
		v.FillAll.Buy.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319325670)
		end)
		
		if Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 1 then
			v.Luck.Title.Text = "2X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 99"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 2 then
			v.Luck.Title.Text = "4X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 299"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 4 then
			v.Luck.Title.Text = "8X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 399"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 8 then
			v.Luck.Title.Text = "16X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text= "R$ 799"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 16 then
			v.Luck.Title.Text = "32X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 999"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 32 then
			v.Luck.Title.Text = "64X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 1999"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 64 then
			v.Luck.Title.Text = "128X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 128 then
			v.Luck.Title.Text = "256X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 256 then
			v.Luck.Title.Text = "512X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
		elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 512 then
			v.Luck.Title.Text = "1024X LUCK!!!"
			v.Luck.desc.Text = "5 mins."
			v.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
		else
			v.Luck.Title.Text = "MAXED OUT!!"
			v.Luck.desc.Text = ""
			v.Luck.Buy.Main.TextLabel.Text = ""
		end
		
		applyHoverEffect(v.Luck.Buy)
		v.Luck.Buy.MouseButton1Click:Connect(function()
			if Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 1 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319337976)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 2 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319344460)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 4 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319344650)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 8 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319345899)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 16 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319346079)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 32 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319346367)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 64 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3319346565)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 128 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321053944)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 256 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321054309)
			elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 512 then
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321054744)
			else
				print("max reached")
			end
		end)
	elseif v.Name == "SummerEventBundles" then
		if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"SummerBundle") then
			script.Parent.SummerEventBundles.SummerBundle.Buy.Main.TextLabel.Text = "Purchased!"
		else
			applyHoverEffect(v.SummerBundle.Buy)
			v.SummerBundle.Buy.MouseButton1Click:Connect(function()
				if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"SummerBundle") then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320613614)
			end)
		end

		if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"ProSummer") then
			script.Parent.SummerEventBundles.ProSummer.Buy.Main.TextLabel.Text = "Purchased!"
		else
			applyHoverEffect(v.ProSummer.Buy)
			v.ProSummer.Buy.MouseButton1Click:Connect(function()
				if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"ProSummer") then return end
				game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3320623603)
			end)
		end
	elseif v.Name == "DominusDaneAndEmp" then
		applyHoverEffect(v["Dominus Dane"].Buy)
		v["Dominus Dane"].Buy.MouseButton1Click:Connect(function()
			if game.Players.LocalPlayer:FindFirstChild("WorkerCapacity").Value >= 30 then return end
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3327236909)
		end)

		applyHoverEffect(v.Empyreus.Buy)
		v.Empyreus.Buy.MouseButton1Click:Connect(function()
			if game.Players.LocalPlayer:FindFirstChild("WorkerCapacity").Value >= 30 then return end
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3327237064)
		end)
	elseif v.Name == "SummerEventPageBIG" then
		applyHoverEffect(v.Buy1)
		applyHoverEffect(v.Buy3)
		applyHoverEffect(v.Buy10)
		v.Buy1.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321025820)
		end)
		v.Buy3.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321026170)
		end)
		v.Buy10.MouseButton1Click:Connect(function()
			game:GetService("MarketplaceService"):PromptProductPurchase(game.Players.LocalPlayer, 3321026395)
		end)
	elseif v.Name == "VIP" then
		if Events.Get:InvokeServer({"VIP"}).VIP == true then
			script.Parent.VIP.BuyGems:Destroy()
			script.Parent.VIP.Buy.Main.TextLabel.Text = "Purchased!"
		else
			applyHoverEffect(v.Buy)
			applyHoverEffect(v.BuyGems)
			v.Buy.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"VIP"}).VIP == true then return end
				game:GetService("MarketplaceService"):PromptGamePassPurchase(game.Players.LocalPlayer, 1283734238)
			end)
			v.BuyGems.MouseButton1Click:Connect(function()
				if Events.Get:InvokeServer({"VIP"}).VIP == true then return end
				Events.BuyWithDiamonds:FireServer("VIP")
			end)
		end
	end
end

Events.LuckBought.OnClientEvent:Connect(function()
	if Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 1 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "2X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 99"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 2 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "4X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 299"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 4 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "8X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 399"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 8 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "16X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text= "R$ 799"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 16 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "32X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 999"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 32 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "64X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 1999"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 64 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "128X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 128 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "256X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 256 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "512X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
	elseif Events.Get:InvokeServer({"LuckMultiplier"}).LuckMultiplier == 512 then
		script.Parent.LuckAndBuy.Luck.Title.Text = "1024X LUCK!!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = "5 mins."
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = "R$ 9999"
	else
		script.Parent.LuckAndBuy.Luck.Title.Text = "MAXED OUT!!"
		script.Parent.LuckAndBuy.Luck.desc.Text = ""
		script.Parent.LuckAndBuy.Luck.Buy.Main.TextLabel.Text = ""
	end
end)

Events.WorkerLimitChange.OnClientEvent:Connect(function()
	if Events.Get:InvokeServer({"WorkerSlots"}).WorkerSlots == "Tier2" then
		if script.Parent.PlotAndWorkerEquippedExpansion.WorkerEquipped then
			script.Parent.PlotAndWorkerEquippedExpansion.WorkerEquipped.Buy.Main.TextLabel.Text = "Maxed!"
		end
	end
end)



Events.PlotSizeChange.OnClientEvent:Connect(function()
	local plotTier = Events.Get:InvokeServer({"BoughtPlotExpansions"}).BoughtPlotExpansions
	if plotTier >=4 then
		if script.Parent.PlotAndWorkerEquippedExpansion.ExpandPlot then
			script.Parent.PlotAndWorkerEquippedExpansion.ExpandPlot.BuyGems:Destroy()
			script.Parent.PlotAndWorkerEquippedExpansion.ExpandPlot.Buy.Main.TextLabel.Text = "Maxed!"
		end
	end
end)

Events.DevProductBought.OnClientEvent:Connect(function(Which)
	if Which == "SpeedMultiplier" then
		script.Parent.MaxDrillsAndWalkSpeed.Walkspeed.BuyGems:Destroy()
		script.Parent.MaxDrillsAndWalkSpeed.Walkspeed.Buy.Main.TextLabel.Text = "Maxed!"
	elseif Which == "DrillLimit" then
		if Events.Get:InvokeServer({"MaxDrills"}).MaxDrills == "Tier2" then
			script.Parent.MaxDrillsAndWalkSpeed.MaxDrills.BuyGems:Destroy()
			script.Parent.MaxDrillsAndWalkSpeed.MaxDrills.Buy.Main.TextLabel.Text = "Maxed!"
		end
	elseif Which == "SummerBundle" then
		if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"SummerBundle") then
			script.Parent.SummerEventBundles.SummerBundle.Buy.Main.TextLabel.Text = "Purchased!"
		end
	elseif Which == "ProSummer" then
		if string.find(Events.Get:InvokeServer({"OneTimePurchases"}).OneTimePurchases,"ProSummer") then
			script.Parent.SummerEventBundles.ProSummer.Buy.Main.TextLabel.Text = "Purchased!"
		end
	elseif Which == "VIP" then
		if Events.Get:InvokeServer({"VIP"}).VIP == true then
			script.Parent.VIP.BuyGems:Destroy()
			script.Parent.VIP.Buy.Main.TextLabel.Text = "Purchased!"
		end
	end
end)

local success, policyInfo = pcall(function()
	return PolicyService:GetPolicyInfoForPlayerAsync(game.Players.LocalPlayer)
end)


local PaidRandomItems = {
	"AdvancedBundle",
	"StarterBundle",
	"SummerEventBundles",
	"SummerEventPageBIG",
}


if success and policyInfo and policyInfo.ArePaidRandomItemsRestricted == true then
	for _, v in pairs(script.Parent:GetChildren()) do
		if v:IsA("Frame") and table.find(PaidRandomItems, v.Name) then
			v.Visible = false
		end
	end
end

local scrollingFrame = script.Parent
local layout = scrollingFrame:FindFirstChildOfClass("UIListLayout")

local function updateCanvasSize()
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
end

-- Listen for children being added or removed
scrollingFrame.ChildAdded:Connect(updateCanvasSize)
scrollingFrame.ChildRemoved:Connect(updateCanvasSize)

-- Watch for size changes in children (e.g. if a child resizes)
for _, child in pairs(scrollingFrame:GetChildren()) do
	if child:IsA("GuiObject") then
		child:GetPropertyChangedSignal("Size"):Connect(updateCanvasSize)
	end
end

-- Optional: Connect this dynamically for new children too
scrollingFrame.ChildAdded:Connect(function(child)
	if child:IsA("GuiObject") then
		child:GetPropertyChangedSignal("Size"):Connect(updateCanvasSize)
	end
end)

-- Initial setup
updateCanvasSize()