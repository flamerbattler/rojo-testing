local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)

local CombatService = nil

Knit.OnStart():andThen(function()
	CombatService = Knit.GetService("CombatService")
end):catch(warn)

local player = Players.LocalPlayer
local katana: Tool

WaitFor.Descendant(player, "Katana"):andThen(function(child: Instance)
	katana = child
end):await()

function OnActivate()
	if player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
		local Melee = {
			Character = player.Character,
			AttackPart = katana:FindFirstChild("Blade"),
			Damage = 10,
			Range = 4.2,
		}

		local loadedAnim = player.Character.Humanoid:FindFirstChildOfClass("Animator"):LoadAnimation(katana:FindFirstChildOfClass("Animation"))
		loadedAnim:Play()
		CombatService:StartAttack("Melee", Melee)
	end
end

katana.Activated:Connect(OnActivate)