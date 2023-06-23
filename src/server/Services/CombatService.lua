local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.knit)
local Promise = require(ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_knit@1.5.1").Promise)

local CombatService = Knit.CreateService({Name = "CombatService", Client = {}})

type Damaged = {
	Character: Model,
	Damage: number,
	DamageOverTime: DamageOverTime?,
}

type DamageOverTime = {
	Damage: number,
	Length: number,
	Amount: number,
	Particle: ParticleEmitter?
}

type Melee = {
	Character: Model,
	AttackPart: BasePart,
	Damage: number,
	Range: number,
	Lingering: number?,
	DamageOverTime: DamageOverTime?
}

type Projectile = {
	Character: Model,
	AttackPart: BasePart,
	Damage: number,
	Distance: number,
	Speed: number,
	Target: Vector3,
	MoveProjectile: boolean?,
	AirTime: number?,
	Homing: boolean?,
	DamageOverTime: {}?
}

type AreaOfEffect = {
	Character: Model,
	AttackPart: BasePart?,
	Position: Vector3,
	Damage: number,
	Radius: number?,
	Lingering: number?,
	DamageOverTime: DamageOverTime?
}

local function Params(paramsType: string, ...): RaycastParams | OverlapParams
	if paramsType == "RaycastParams" then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {...}
		return params
	else
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {...}
		return params
	end
end

local function ProjectileMover(Projectile: BasePart, Target: Vector3, Speed: number)
	local Attachment = Instance.new("Attachment")
	Attachment.WorldCFrame = Projectile.CFrame
	local vectorForce = Instance.new("VectorForce")
	vectorForce.Force =  (Target - Projectile.Position).Unit * Speed
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Attachment0 = Attachment
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	local AlignOrientation = Instance.new("AlignOrientation")
	AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AlignOrientation.CFrame = CFrame.lookAt(Projectile.Position, Target)
	AlignOrientation.MaxTorque = math.huge
	AlignOrientation.MaxAngularVelocity = math.huge
	AlignOrientation.Responsiveness = math.huge
	AlignOrientation.Attachment0 = Attachment
	Attachment.Parent = Projectile
	AlignOrientation.Parent = Projectile
	vectorForce.Parent = Projectile
end

local function TakeDamageOverTime(damageOverTime: DamageOverTime, character: Model)
	local particle: ParticleEmitter

	if damageOverTime.Particle then
		particle = damageOverTime.Particle:Clone()
		particle.Parent = character.PrimaryPart
	end

	task.defer(function()
		for i=1, damageOverTime.Amount do
			character:FindFirstChildOfClass("Humanoid"):TakeDamage(damageOverTime.Damage)
			task.wait(damageOverTime.Length/damageOverTime.Amount)
		end
		Debris:AddItem(particle, 0)
	end)
end

local function TakeDamage(damaged: Damaged)

	damaged.Character:FindFirstChildOfClass("Humanoid"):TakeDamage(damaged.Damage)

	if damaged.DamageOverTime then
		TakeDamageOverTime(damaged.DamageOverTime, damaged.Character)
	end
end

local function isPartInRadius(Part: BasePart, Target: BasePart, Radius: number): boolean
	for _, object in ipairs(workspace:GetPartBoundsInRadius(Part.Position, Radius, Params("OverlapParams", {Part}))) do
		if object == Target then
			return true
		end
	end
	return false
end

local function GetOtherCharacters(Attacker: Model, HitCharacter: Model, AttackPosition: CFrame, AttackArea: Vector3)
	local HitCharacters = {}

	for _, Object in ipairs(workspace:GetPartBoundsInBox(AttackPosition, AttackArea, Params("OverlapParams", Attacker))) do
		if not Object:FindFirstAncestorOfClass("Model") then
			continue
		end

		local CharOther: Model = Object:FindFirstAncestorOfClass("Model")

		if CharOther and CharOther:FindFirstChildOfClass("Humanoid") then
			if CharOther == HitCharacter or table.find(HitCharacters, CharOther) then
				continue
			end

			local humanoid = CharOther:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				table.insert(HitCharacters, CharOther)
			else
				continue
			end
		end
	end

	return HitCharacters
end

function CombatService:MeleeAttack(Combatant: Melee)
	local AttackPart = Combatant.AttackPart

	local function Melee()
		return Promise.defer(function(resolve: ({Model}) -> (), reject: () -> (), onCancel: (() -> ()) -> ())
			local Direction = Combatant.Character:GetPivot().LookVector*Combatant.Range
			local result: RaycastResult? = workspace:Blockcast(AttackPart.CFrame, AttackPart.Size, Direction, Params("RaycastParams", Combatant.Character))

			if result then
				local hit: BasePart | Terrain = result.Instance

				if not hit:IsA("BasePart") then
					reject()
				end

				if not hit:FindFirstAncestorOfClass("Model") then
					reject()
				end

				local opponent = hit:FindFirstAncestorOfClass("Model")

				if opponent:IsA("Model") and opponent:FindFirstChildOfClass("Humanoid") then
					local humanoid = opponent:FindFirstChildOfClass("Humanoid")

					if humanoid and humanoid.Health > 0 then
						local hitCharacters: {Model} = GetOtherCharacters(Combatant.Character, opponent, CFrame.new(result.Position), AttackPart.Size)
						table.insert(hitCharacters, opponent)
						resolve(hitCharacters)
					else
						reject()
					end
				end
			end
		end):catch(function(errorResponse)
			print(errorResponse)
		end)
	end

	if Combatant.Lingering then
		Promise.retry(Melee, Combatant.Lingering * 60):andThen(function(opponents: {Model})
			for _, opponent in ipairs(opponents) do
				self:DealDamage(opponent, Combatant.Damage, Combatant.DamageOverTime)
			end
		end)
	else
		Melee():andThen(function(opponents: {Model})
			for _, opponent in ipairs(opponents) do
				self:DealDamage(opponent, Combatant.Damage, Combatant.DamageOverTime)
			end
		end)
	end
end

function CombatService:ProjectileAttack(Combatant: Projectile)
	local projectile = Combatant.AttackPart

	Debris:AddItem(projectile, Combatant.AirTime or 10)
	if Combatant.MoveProjectile then
		ProjectileMover(projectile, Combatant.Target, Combatant.Speed)
	end

	local function Projectile()
		return Promise.defer(function(resolve: ({Model}) -> (), reject: () -> (), onCancel: (() -> ()) -> ())
			repeat
				task.wait()
				local result: RaycastResult? = workspace:Blockcast(projectile.CFrame, projectile.Size, ((Combatant.Target - projectile.Position).Unit * (Combatant.Distance+1)), Params("RaycastParams", Combatant.Character))

				if result then
					local hit: BasePart | Terrain = result.Instance

					if not hit:IsA("BasePart") then
						continue
					end

					if not hit:FindFirstAncestorOfClass("Model") then
						continue
					end

					local opponent = hit:FindFirstAncestorOfClass("Model")

					if opponent:IsA("Model") and opponent:FindFirstChildOfClass("Humanoid") then
						local humanoid = opponent:FindFirstChildOfClass("Humanoid")

						if humanoid and humanoid.Health > 0 then
							if isPartInRadius(projectile, result.Instance, projectile.Size.Magnitude+1) then
								local hitCharacters: {Model} = GetOtherCharacters(Combatant.Character, opponent, CFrame.new(result.Position), projectile.Size)
								table.insert(hitCharacters, opponent)
								Debris:AddItem(projectile, 0)
								resolve(hitCharacters)
							end
						end
					end
				end
			until not projectile:IsDescendantOf(workspace)
		end):catch(function(errorResponse)
			print(errorResponse)
		end)
	end

	Projectile():andThen(function(opponents: {Model})
		for _, opponent in ipairs(opponents) do
			self:DealDamage(opponent, Combatant.Damage, Combatant.DamageOverTime)
		end
	end)
end

function CombatService:AreaOfEffectAttack(Combatant: AreaOfEffect)
	local function AOE()
		local HitCharacters: {Model} = {}

		return Promise.defer(function(resolve: ({Model}) -> (), reject: () -> (), onCancel: (() -> ()) -> ())
			if Combatant.AttackPart then
				for _, object in ipairs(workspace:GetPartBoundsInBox(Combatant.AttackPart.CFrame, Combatant.AttackPart.Size, Params("OverlapParams", Combatant.Character))) do
					if not object:FindFirstAncestorOfClass("Model") then
						continue
					end

					local opponent = object:FindFirstAncestorOfClass("Model")

					if opponent and opponent:FindFirstChildOfClass("Humanoid") then
						local humanoid = opponent:FindFirstChildOfClass("Humanoid")

						if not humanoid then
							continue
						end

						if humanoid.Health > 0 then
							table.insert(HitCharacters, opponent)
						end
					end
				end
			else
				for _, object in ipairs(workspace:GetPartBoundsInRadius(Combatant.Position, Combatant.Radius, Params("OverlapParams", Combatant.Character))) do
					if not object:FindFirstAncestorOfClass("Model") then
						continue
					end

					local opponent = object:FindFirstAncestorOfClass("Model")

					if opponent and opponent:FindFirstChildOfClass("Humanoid") then
						local humanoid = opponent:FindFirstChildOfClass("Humanoid")

						if not humanoid then
							continue
						end

						if humanoid.Health > 0 then
							table.insert(HitCharacters, opponent)
						end
					end
				end
			end

			if #HitCharacters > 0 then
				resolve(HitCharacters)
			else
				reject()
			end
		end):catch(function(errorResponse)
			print(errorResponse)
		end)
	end

	if Combatant.Lingering then
		Promise.retry(AOE, Combatant.Lingering * 60):andThen(function(opponents: {Model})
			for _, opponent in ipairs(opponents) do
				self:DealDamage(opponent, Combatant.Damage, Combatant.DamageOverTime)
			end
		end)
	else
		AOE():andThen(function(opponents: {Model})
			for _, opponent in ipairs(opponents) do
				self:DealDamage(opponent, Combatant.Damage, Combatant.DamageOverTime)
			end
		end)
	end
end

function CombatService:DealDamage(opponent: Model, damage: number, damageOverTime: DamageOverTime?)
	TakeDamage({
		Character = opponent,
		Damage = damage,
		DamageOverTime = damageOverTime
	})
end

function CombatService.Client:StartAttack(player: Player, attackType: string, attackDetails: any)
	if attackType == "Melee" then
		self.Server:MeleeAttack(attackDetails)
	elseif attackType == "Projectile" then
		self.Server:ProjectileAttack(attackDetails)
	elseif attackType == "AreaOfEffect" then
		self.Server:AreaOfEffectAttack(attackDetails)
	end
end

return CombatService