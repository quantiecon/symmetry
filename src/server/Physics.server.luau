local PhysicsService = game:GetService("PhysicsService")

-- Create collision groups (only need to do once)
pcall(function()
	PhysicsService:CreateCollisionGroup("Players")
	PhysicsService:CreateCollisionGroup("Workers")
end)

-- Make sure Workers and Players don't collide
PhysicsService:CollisionGroupSetCollidable("Players", "Workers", false)

local function assignWorkerCollision(workerModel)
	for _, part in ipairs(workerModel:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, "Workers")
		end
	end
end


game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(part, "Players")
			end
		end
	end)
	
	local Conn
	
	Conn = workspace.ChildAdded:Connect(function(child)
		if child.Name == player.Name.."Workers" then
			for _,k in pairs(child:GetChildren()) do
				if k:FindFirstChild("Humanoid") then
					assignWorkerCollision(k)
				end
			end
			
			child.ChildAdded:Connect(function(child2)
				if child2:FindFirstChild("Humanoid") then
					assignWorkerCollision(child2)
				end
			end)
			
			Conn:Disconnect()
		end
	end)
end)