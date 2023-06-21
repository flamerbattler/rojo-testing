--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage.Packages.profileservice)
local Promise = require(ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_knit@1.5.1").Promise)

local ProfileStore = ProfileService.GetProfileStore(
	"Player",
	{
		Character = "player",
		Stellas = 10
	}
)

local Profiles = {}

local function OnPlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync(
		"Player_"..player.UserId,
		"ForceLoad"
	)
	
	if profile then
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)
		
		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			Profiles[player]:Reconcile()
		else
			profile:Release()
		end
	else
		player:Kick("Data error, please rejoin!")
	end
end

local function OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	
	if profile then
		profile:Release()
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

local DataManager = {}

local function GetData(player: Player)
	return Promise.new(function(resolve: ((...any) -> ()), reject:(...any) -> ())
		while true do
			if Profiles[player] and Profiles[player].Data then
				resolve(Profiles[player].Data)
			end
			
			task.wait()
		end
	end)
end

function DataManager.Get(player: Player): any
	local profile = Profiles[player]
	
	if profile then
		return profile.Data
	else
		return GetData(player):Await()
	end
end

function DataManager.Set(player: Player, key: string, value: any): ()
	local profile = Profiles[player]
	
	if profile then
		profile.Data[key] = value
	end
end

return DataManager