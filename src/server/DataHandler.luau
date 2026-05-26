local PlayerService = game:GetService("Players")
local ProfileService = require(game.ReplicatedStorage.Modules.ProfileService)

local ProfileStore = ProfileService.GetProfileStore( 
	"Player",
	{
		HandDrill = "Basic Drill";
		PlacedDrills = "";
		_PlacedDrillsBackup = "";
		Collection = "Standard Drill:1,";
		CollectedWorkers = "";
		EquippedWorkers = "";
		_lastCollection = "";
		PlotExpansion = "None";
		BoughtPlotExpansions = 0;
		WorkerSlots = "None";
		Coins = 0;
		Diamonds = 0;
		SecondsSpentIngame = 0;
		EventCurrency = "";
		EventStock = "";
		EventRefresh = 0;
		
		FavouriteOre = "";
		LockedOres = "";
		
		ContractStock = "";
		ContractRefresh = 0;
		
		MerchantStock = "";
		MerchantRefresh = 0;
		
		PityPer10 = 0;
		PityPer50 = 0;
		
		RisingEventRequirement = "";
		
		DailySpinTickets = 0;
		LastClaimedTimestamp = 0;
		RewardStreak = 0;
		CanClaimDaily = false;
		FirstTimePlaying = true;
		AlreadyGotVIPExpansion = false;

		OneTimeQuests = "";
		DailyQuests = "";
		
		LuckMultiplier = 1;
		TimeUntilLuckEnds = 1;
		
		ClaimedRewards = "";
		
		OneTimePurchases = "";
		SpeedProduct = false;
		VIP = false;
		MaxDrills = "None";
		
		Music = "On";
		Tips = "On";
		OreAnnouncments = "On";
		DisableOrbs = "Off";
		LowGraphicsMode = "Off";
		AutoSellCommons = "Off";
		AutoSellRares = "Off";
	}
)

local Profiles = {}

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync(
		"Player_" .. player.UserId,
		"ForceLoad"
	)
	if profile then
		profile:Reconcile()
		
		profile:ListenToRelease(function()
			Profiles[profile] = nil
			player:Kick()
		end)
		
		if player:IsDescendantOf(PlayerService) then
			Profiles[player] = profile
		else
			profile:Release()
		end
		
		local PlayerData = Instance.new("Folder") 
		PlayerData.Name = player.Name.."Data"
		PlayerData.Parent = game.ServerStorage.PlayerData
		
		for key,value in pairs(profile.Data) do
			local Value
			if type(value) == "string" then
				Value = Instance.new("StringValue")
				Value.Parent = PlayerData
				Value.Name = key
				Value.Value = value
			elseif type(value) == "number" then
				Value = Instance.new("NumberValue")
				Value.Parent = PlayerData
				Value.Name = key
				Value.Value = value
			elseif type(value) == "boolean" then
				Value = Instance.new("BoolValue")
				Value.Parent = PlayerData
				Value.Name = key
				Value.Value = value
			elseif type(value) == "table" then
				Value = Instance.new("StringValue")
				Value.Parent = PlayerData
				Value.Name = key
				Value.Value = table.concat(value, ",")
			else
				warn("ERROR: DATA NOT LOADING ONTO FOLDER")
				print(key)
				print(value)
			end
			
			Value.Changed:Connect(function()
				if Value then
					profile.Data[Value.Name] = Value.Value
				end
			end)
		end
	else
		player:Kick()
	end
end

local function onPlayerRemoved(Player)
	local Profile = Profiles[Player]
	if Profile then
		Profile:Release()
		
		for i,v in pairs(game.ServerStorage.PlayerData:GetChildren()) do
			if v.Name == Player.Name.."Data" then
				v:Destroy()
				
				print("Deleted data of "..Player.Name)
			end
		end
	end
end

game.Players.PlayerAdded:Connect(PlayerAdded)
PlayerService.PlayerRemoving:Connect(onPlayerRemoved)	
	
	
local DataManager = {}

function DataManager:Get(Player)
	local Profile = Profiles[Player]
	
	
	if Profile then
		return Profile.Data
	end
end

return DataManager