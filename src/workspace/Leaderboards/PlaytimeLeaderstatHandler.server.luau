-- [ SETTINGS ] --

local StatsName = "SecondsSpentIngame" -- Your stats name
local MaxItems = 100 -- Max number of items to be displayed on the leaderboard
local MinValueDisplay = 1 -- Any numbers lower than this will be excluded
local MaxValueDisplay = 10e15 -- (10 ^ 15) Any numbers higher than this will be excluded
local UpdateEvery = 15 -- (in seconds) How often the leaderboard has to update

-- [ END SETTINGS ] --

local function formatSecondsToDHMS(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)

	return string.format("%02d:%02d:%02d", days, hours, minutes)
end

-- Don't edit if you don't know what you're doing --Hypx

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetOrderedDataStore("GlobalLeaderboard_" .. StatsName)
local SurfaceGui = script.Parent
local Sample = script.Sample
local List = SurfaceGui.Frame.List
local ItemsFrame = List.ListContent.Items

local function GetItems()
	local Data = DataStore:GetSortedAsync(false, MaxItems, MinValueDisplay, MaxValueDisplay)
	local TopPage = Data:GetCurrentPage()
	
	ItemsFrame.Nothing.Visible = #TopPage == 0 and true or false
	
	for i, v in ipairs(TopPage) do
		local UserId = v.key
		local Value = v.value
		local Username = "[Not Available]"
		local Color = Color3.fromRGB(38, 50, 56)
		
		local Success, Error = pcall(function()
		 	Username = game.Players:GetNameFromUserIdAsync(UserId)
		end)
		
		if i == 1 then
			Color = Color3.fromRGB(255, 215, 0)
		elseif i == 2 then
			Color = Color3.fromRGB(192, 192, 192)
		elseif i == 3 then
			Color = Color3.fromRGB(205, 127, 50)
		end
		
		local Item = Sample:Clone()
		Item.Name = Username
		Item.LayoutOrder = i
		Item.Values.Number.TextColor3 = Color
		Item.Values.Number.Text = i
		Item.Values.Username.Text = Username
		Item.Values.Value.Text = formatSecondsToDHMS(Value)
		Item.Parent = ItemsFrame
	end
end

while true do
	for i, v in pairs(game.Players:GetPlayers()) do
		local Stats = game.ServerStorage.PlayerData:FindFirstChild(v.Name.."Data"):WaitForChild(StatsName).Value
		if Stats then
			pcall(function()
				DataStore:UpdateAsync(v.UserId, function(Value)
					return tonumber(Stats)
				end)
			end)
		end
	end
	
	for i, v in pairs(ItemsFrame:GetChildren()) do
		if v:IsA("ImageLabel") then
			v:Destroy()
		end
	end
	
	GetItems()
	
	wait()
	SurfaceGui.Heading.Heading.Text =  "Time Spent"
	List.ListContent.GuideTopBar.Value.Text = "D:H:M"
	List.CanvasSize = UDim2.new(0, 0, 0, ItemsFrame.UIListLayout.AbsoluteContentSize.Y + 35)
	wait(UpdateEvery)
end