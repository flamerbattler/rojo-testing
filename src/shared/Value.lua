local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages._Index["sleitnick_signal@1.5.0"].signal)

local Value = {}
Value.__index = Value

function Value.new(value: any, typeStrict: boolean?): () -> ()
	local self = setmetatable({}, Value)
	self.__value = value
	self.__subscribeEvent = Signal.new()
	if typeStrict then
		self.__type = typeof(value)
	else
		self.__type = "dynamic"
	end
	return self
end

function Value:Get(): (any, any)
	return self.__value, self.__type
end

function Value:Set(newValue: any): () -> ()
	local oldValue = self.__value

	if self.__type ~= "dynamic" and typeof(newValue) ~= self.__type then
		warn("Not the same type; value wasn't changed")
		return
	end

	if oldValue == newValue then
		return
	end

	self.__value = newValue
	self.__subscribeEvent:Fire(newValue, oldValue)
end

function Value:Let(func: () -> ()): any
	self.__subscribeEvent:Connect(func)
	return self:Get()
end

return Value