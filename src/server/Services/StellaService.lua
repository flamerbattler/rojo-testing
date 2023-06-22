local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.knit)
local DataManager = require(ServerScriptService.Server.datamanager)

local StellaService = Knit.CreateService({Name = "StellaService", Client = {Stellas = Knit.CreateProperty(0)}})

function StellaService:GetStellas(player: Player): number
	if self.Client.Stellas:GetFor(player) == DataManager.Get(player).Stellas then
		return self.Client.Stellas:GetFor(player)
	else
		return error("Stellas on client differ from the profileservice.")
	end
end

function StellaService:SetStellas(player: Player, stellas: number): () -> ()
	DataManager.Set(player, "Stellas", stellas)
	self.Client.Stellas:SetFor(player, stellas)
end

function StellaService:AddStellas(player: Player, stellasToAdd: number): () -> ()
	self:SetStellas(player, self:GetStellas(player) + stellasToAdd)
end

function StellaService:RemoveStellas(player: Player, stellasToRemove: number): () -> ()
	self:SetStellas(player, math.floor(self:GetStellas(player) - stellasToRemove))
end

function StellaService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
        self.Client.Stellas:SetFor(player, DataManager.Get(player).Stellas)
    end)
end

return StellaService