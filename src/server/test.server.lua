local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.knit)
local Print = require(ReplicatedStorage.Shared.Print)

Knit:Start():andThen(function()
	Print("Knit has started on the", "Server!")
end):catch(warn)