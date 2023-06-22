local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.knit)
local Roact = require(ReplicatedStorage.Packages.roact)

local StellaService = nil

Knit.OnStart():andThen(function()
	StellaService = Knit.GetService("StellaService")
end):catch(warn)

local PlayerGui = Players.LocalPlayer.PlayerGui
local Stellas = Roact.Component:extend("Stellas")

function Stellas:init()
	self:setState({
		stellas = 0
	})
end

function Stellas:render()
	return Roact.createElement("ScreenGui", {}, {
		Stellas = Roact.createElement("TextLabel", {
			Size = UDim2.new(0.1, 0, 0.1, 0),
			Position = UDim2.new(0.4525, 0, 0.85, 0),
			BackgroundColor = BrickColor.new("Tr. Blue"),
			Text = self.state.stellas,
			TextScaled = true
		})
	})
end

function Stellas:didMount()
	StellaService.Stellas:Observe(function(currentStellas: number)
		self:setState(function(state)
			return {stellas = currentStellas}
		end)
	end)
end

Roact.mount(Roact.createElement(Stellas), PlayerGui)