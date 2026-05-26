local Events = game.ReplicatedStorage.Events
local ItemInfo = require(game.ReplicatedStorage.Modules.ItemInfo)
local ViewportModel = require(game.ReplicatedStorage.Modules.ViewportModel)

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local GUI = script.Parent
local ListFrame = GUI:WaitForChild("List")

local LocalPlayer = game.Players.LocalPlayer

function formatnumber(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
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

for i,v in ItemInfo do
	if ItemInfo[i].Drill then
		if not ItemInfo[i].Event or not ItemInfo[i].NatureEvent then 
			if not ItemInfo[i].NotForSale and ItemInfo[i].Robux then
				local SystemDrill = game.ReplicatedStorage.System.Parts:FindFirstChild(i)
				local SystemData = game.ReplicatedStorage.System.Parts:FindFirstChild(i):FindFirstChild("Data")
				
				local Placeholder = script.Placeholder:Clone()
				Placeholder.Parent = script.Parent.List
				Placeholder.Name = i
				Placeholder.DrillName.Text = i
				Placeholder.Luck.Text = "Luck: "..SystemData.OreYield.Value.."x"
				Placeholder.Capacity.Text = "Storage: "..SystemData.Max.Value
				Placeholder.Speed.Text = "Ores Per Second: "..SystemData.Speed.Value
				print(i)
				Placeholder.BuyRobux.Main.Home.Text = "R$ "..ItemInfo[i].Robux
				Placeholder.BuyCoins.Main.Home.Text = formatnumber(ItemInfo[i].Coins).."$"
				Placeholder.LayoutOrder = ItemInfo[i].Coins
				
				if ItemInfo[i].Rarity == "Common" then
					Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.607843, 1, 0.764706),Color3.new(0.603922, 1, 0.388235))
				elseif ItemInfo[i].Rarity == "Rare" then
					Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.576471, 0.921569, 1),Color3.new(0.333333, 0.635294, 1))
				elseif ItemInfo[i].Rarity == "Epic" then
					Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(0.878431, 0.596078, 1),Color3.new(0.678431, 0.309804, 1))
				elseif ItemInfo[i].Rarity == "Legendary" then
					Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.862745, 0.513725),Color3.new(1, 0.576471, 0.27451))
				elseif ItemInfo[i].Rarity == "Mythical" then
					Placeholder.UIGradient.Color = ColorSequence.new(Color3.new(1, 0.494118, 0.501961),Color3.new(1, 0.203922, 0.215686))
				end
				
				applyHoverEffect(Placeholder.BuyCoins)
				applyHoverEffect(Placeholder.BuyRobux)
				
				Placeholder.BuyCoins.MouseButton1Click:Connect(function()
					Placeholder.BuyCoins.Click:Play()
					Events.BuyDrillCoin:FireServer(i)
				end)
				
				Placeholder.BuyRobux.MouseButton1Click:Connect(function()
					Placeholder.BuyRobux.Click:Play()
					Events.BuyDrillRobux:FireServer(i)
				end)
				
				if game.ReplicatedStorage.System.Parts:FindFirstChild(i) then
					local model = game.ReplicatedStorage.System.Parts:FindFirstChild(i):Clone()

					local camera = Instance.new("Camera")
					camera.FieldOfView = 70
					camera.Parent = Placeholder.DrillView

					model.Parent = Placeholder.DrillView
					Placeholder.DrillView.CurrentCamera = camera

					local vpfModel = ViewportModel.new(Placeholder.DrillView, camera)
					local cf, size = model:GetBoundingBox()

					vpfModel:SetModel(model)

					local theta = 0
					local orientation = CFrame.new()
					local distance = vpfModel:GetFitDistance(cf.Position)
					local theta = 0
					local orientation = CFrame.new()
					local distance = vpfModel:GetFitDistance(cf.Position)

					task.spawn(function()
						local connection
						connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
							if not camera or not camera.Parent then
								if connection then connection:Disconnect() end
								return
							end
							
							theta = theta + math.rad(20 * dt)
							orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
							camera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)
						end)
					end)
				end
			end
		end
	end
end

ProximityPromptService.PromptShown:Connect(function(promptInstance)
	if promptInstance.Name == "DrillShop" then
		local NPC = promptInstance.Parent
		local Camera = game.Workspace.CurrentCamera

		local BlurEffect = Instance.new("BlurEffect")
		BlurEffect.Size = 0
		BlurEffect.Parent = game.Lighting

		TweenService:Create(BlurEffect,TweenInfo.new(0.8),{Size = 24}):Play()
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 50}):Play()

		script.Parent.Visible = true
		
		local drillStock = Events.GlobalDrillStockRequest:InvokeServer()
		for _, drillFrame in pairs(script.Parent.List:GetChildren()) do
			if drillFrame:IsA("Frame") and drillFrame:FindFirstChild("StockAmount") then
				local amount = drillStock[drillFrame.Name]
				if amount then
					drillFrame.StockAmount.Text = "Stock: " .. amount .. "x"
				else
					drillFrame.StockAmount.Text = "Out of Stock"
				end
			end
		end
	end
end)

ProximityPromptService.PromptHidden:Connect(function(promptInstance)
	if promptInstance.Name == "DrillShop" then
		local Camera = game.Workspace.CurrentCamera
		TweenService:Create(Camera,TweenInfo.new(0.8),{FieldOfView = 70}):Play()

		script.Parent.Visible =false

		for i,v in pairs(game.Lighting:GetChildren()) do
			if v:IsA("BlurEffect") then
				TweenService:Create(v,TweenInfo.new(0.8),{Size = 0}):Play()
				game:GetService("Debris"):AddItem(v,0.8)
			end
		end
	end
end)

-- Update stock display when a purchase completes
Events.BuyDrillCoin.OnClientEvent:Connect(function()
	local drillStock = Events.GlobalDrillStockRequest:InvokeServer()
	for _, drillFrame in pairs(script.Parent.List:GetChildren()) do
		if drillFrame:IsA("Frame") and drillFrame:FindFirstChild("StockAmount") then
			local amount = drillStock[drillFrame.Name]
			if amount then
				drillFrame.StockAmount.Text = "Stock: " .. amount .. "x"
			else
				drillFrame.StockAmount.Text = "Out of Stock"
			end
		end
	end
	
	local ProfitSound = game.ReplicatedStorage.SFX.Profit:Clone()
	ProfitSound.Parent = LocalPlayer.Character
	ProfitSound:Play()
	game.Debris:AddItem(ProfitSound,2)
end)

-- Countdown & refresh loop
local function syncTimer()
	local timeLeft = Events.RequestRefreshTimer:InvokeServer()

	while timeLeft > 0 do
		local minutes = math.floor(timeLeft / 60)
		local seconds = timeLeft % 60
		script.Parent.StockRefresh.Text = string.format("Refreshes in: %d:%02d", minutes, seconds)
		wait(1)
		timeLeft -= 1
	end

	local drillStock = Events.GlobalDrillStockRequest:InvokeServer()
	for _, drillFrame in pairs(script.Parent.List:GetChildren()) do
		if drillFrame:IsA("Frame") and drillFrame:FindFirstChild("StockAmount") then
			local amount = drillStock[drillFrame.Name]
			if amount then
				drillFrame.StockAmount.Text = "Stock: " .. amount .. "x"
			else
				drillFrame.StockAmount.Text = "Out of Stock"
			end
		end
	end

	syncTimer()
end

syncTimer()