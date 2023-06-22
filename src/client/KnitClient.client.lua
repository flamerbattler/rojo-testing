local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.knit)

-- Load all services within 'Services':
Knit.AddControllers(ReplicatedStorage.Shared.Controllers)

Knit.Start():catch(warn)