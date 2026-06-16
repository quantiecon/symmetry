-- Delays the intro shop popup for new players.
-- Listens for the DelayedIntroShop RemoteEvent fired by the server
-- and then opens the Shop UI (same as pressing the Shop button).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Events           = ReplicatedStorage:WaitForChild("Events")
local DelayedIntroShop = Events:WaitForChild("DelayedIntroShop")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

DelayedIntroShop.OnClientEvent:Connect(function()
	-- Find and open the Shop frame — adjust the path to match your actual UI tree
	local shopGui = playerGui:FindFirstChild("ShopGui") or playerGui:FindFirstChild("Shop")
	if shopGui then
		local frame = shopGui:FindFirstChildWhichIsA("Frame", true)
		if frame then
			frame.Visible = true
		end
	end
end)
