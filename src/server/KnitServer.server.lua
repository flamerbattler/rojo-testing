local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.knit)

-- Load all services within 'Services':
Knit.AddServices(script.Parent.Services)

Knit.Start():catch(warn)