
local logging = false

-- returns a string with suffixes "_A", "_B", "_AB" removed
local function GetBaseWeapon(weapon)
	assert(type(weapon) == 'string')
	
	if modApi:stringEndsWith(weapon, "_AB") then
		return string.sub(weapon, 1, -4)
	elseif
		modApi:stringEndsWith(weapon, "_A") or
		modApi:stringEndsWith(weapon, "_B")
	then
		return string.sub(weapon, 1, -3)
	end
	
	return weapon
end

-- returns an array of size 2 with upgrade booleans
local function GetWeaponUpgrades(weapon)
	assert(type(weapon) == 'string')
	
	if modApi:stringEndsWith(weapon, "_AB") then
		return {true, true}
	elseif modApi:stringEndsWith(weapon, "_A") then
		return {true, false}
	elseif modApi:stringEndsWith(weapon, "_B") then
		return {false, true}
	end
	
	return {false, false}
end

-- taken from Lemonymous's RF1995 and modified to add the third parameter
function Wolf_HasPoweredWeapon(pawn, weapon, upgraded)
	assert(type(weapon) == 'string')
	
	local ptable = HiveWar_modApiExt.pawn:getSavedataTable(pawn:GetId())
	local weapons = {}
	table.insert(weapons, HiveWar_modApiExt.pawn:getWeaponData(ptable, "primary"))
	table.insert(weapons, HiveWar_modApiExt.pawn:getWeaponData(ptable, "secondary"))
	
	local weaponBase = GetBaseWeapon(weapon)
	local upgrades = GetWeaponUpgrades(weapon)
	
	for _, v in ipairs(weapons) do
		if v.id == weaponBase and (#v.power == 0 or v.power[1] > 0) then
			if not upgraded then return true end
			
			for i, u in ipairs(upgrades) do
				if u and v['upgrade'.. i][1] == 0 then
					return false
				end
			end
			
			return true
		end
	end
	
	return false
end

local function EvoCheck(evo)
	if GAME.HW_Evolutions ~= nil then
		for _,v in pairs(GAME.HW_Evolutions) do
			if v == evo then
				return true
			end
		end
	end
	return false
end

------------------------------------------------------
--                  HIVE WEAPONRY                   --
------------------------------------------------------

--Reave
Wolf_Reave = {
	Name = "Talons and Biocannon",
	Description = "Press W to view the Hive Warrior's current stats.",
	GetDamage = function() return GAME.HW_ReaveDmg or 1 end,
	PathSize = 1,
	Icon = "weapons/enemy_scorpion1.png",	
	PreDamage = 0,
	Class = "Enemy",
	LaunchSound = "",
	SoundBase = "/enemy/scorpion_soldier_1",
	TipImage = {
		Unit = Point(2,2),
		Enemy = Point(2,1),
		Target = Point(2,1),
		CustomPawn = "HiveWarrior"
	}
}
Wolf_Reave = Skill:new(Wolf_Reave) 

function Wolf_Reave:GetTargetScore(p1,p2)
	local effect = SkillEffect()
	local island = GetSector()
	
	-- GOTTA GET THOSE TIME TRAVELLERS' TREASURES
	if Board:IsPod(p2) then
		return 50
	end
	
	if GAME.HW_PodHolder ~= nil and Board:GetPawn(p2) ~= nil then
		if Board:GetPawn(p2):GetId() == GAME.HW_PodHolder then
			return 100
		end
	end
	
	-- don't flame units without repair
	if EvoCheck("F") then
		local pawn = Board:GetPawn(p2)
		if pawn ~= nil then
			if not pawn:IsMech() then
				return -100
			end
		end
	end
		
	return self:ScoreList(self:GetSkillEffect(p1,p2).q_effect, true)
end

function Wolf_Reave:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local damage = SpaceDamage(p2, self.GetDamage())
	
	if EvoCheck("W") then
		local predam = SpaceDamage(p2)
		ret:AddDamage(predam)
		ret:AddDelay(0.2)
		ret:AddDamage(SoundEffect(p2,self.SoundBase.."/attack_web"))
		ret:AddGrapple(p1,p2,"hold")
		ret:AddDelay(0.2)
	end
	if EvoCheck("F") then
		local predam = SpaceDamage(p2)
		if Board:IsPod(p2) == false then
			predam.iFire = 1
		end
		predam.sAnimation = "flamethrower1_"..direction
		predam.sSound = "/weapons/flamethrower"
		ret:AddDamage(predam)
		ret:AddDelay(0.2)
	end

	GAME.HW_LastReave = direction
	damage = SpaceDamage(p2, self.GetDamage())
	damage.sAnimation = "SwipeClaw2"
	damage.sSound = "/enemy/beetle_2/attack_impact"
	ret:AddQueuedMelee(p1,damage)
	
	return ret
end	

-------------------------------------------------------
--Biocannon
Wolf_Biocannon = {
	Name = "Hidden Weapon",
	Description = "You shouldn't be seeing this weapon description, please file a bug report.",
	GetDamage = function() return GAME.HW_BioDmg or 2 end,
	PathSize = 1,
	Class = "Enemy",
	Icon = "weapons/ranged_rainingvolley.png",
	Explosion = "ExploBiocannon",
	ImpactSound = "/impact/dynamic/enemy_projectile",
	Projectile = "effects/shot_biocannon",
	Cost = "high",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Building = Point(2,0),
		Target = Point(2,2),
		CustomPawn = "HiveWarrior"
	}
}	
Wolf_Biocannon = Skill:new(Wolf_Biocannon)

function Wolf_Biocannon:GetTargetArea(point)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		local this_path = {}
		
		local target = point + DIR_VECTORS[dir]

		while not Board:IsBlocked(target, PATH_PROJECTILE) do
			this_path[#this_path+1] = target
			target = target + DIR_VECTORS[dir]
		end
		this_path[#this_path+1] = target
		
		for i,v in ipairs(this_path) do 
			ret:push_back(v)
		end
		
	end
	
	return ret
end

function Wolf_Biocannon:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2 - p1)
	local target = GetProjectileEnd(p1, p2)
	
	local pawn = Board:GetPawn(p2)
	if pawn ~= nil then
		local pilot = pawn:GetPersonality()
		
		if (pilot == "Original" or Wolf_HasPoweredWeapon(pawn, "Passive_ServoEvade", false)) and Board:IsValid(p2 + DIR_VECTORS[dir]) then
			target = GetProjectileEnd(p2, p2 + DIR_VECTORS[dir])
			HW_Intimidate("Wolf_HW_Evade", false, 0)
		end
	end
	
	local damage = SpaceDamage(target, self.GetDamage())
	
	if Board:IsBuilding(target) then
		damage = SpaceDamage(target, 0)
	end
	
	if EvoCheck("A") then
		damage.iAcid = 1
	else
		damage.iAcid = 0
	end
	
	--LOG("Shooting: "..target.x..","..target.y)
	
	ret:AddProjectile(damage, self.Projectile)
	
	return ret
end

Wolf_ReflexReave = SelfTarget:new{
	Name = "Reave",
	GetDamage = function() return GAME.HW_ReaveDmg or 1 end,
	PathSize = 1,
	Icon = "weapons/enemy_scorpion1.png",	
	PreDamage = 0,
	Class = "Enemy",
	LaunchSound = "",
	SoundBase = "/enemy/scorpion_soldier_2",
	CustomTipImage = "Wolf_ReflexReave_Tip",
	TipImage = {
		Unit = Point(3,2),
		Enemy = Point(1,1),
		Building = Point(1,2),
		Target = Point(3,2),
		Second_Origin = Point(3,2),
		Second_Target = Point(0,0), -- we just need to be able to identify the second attack.
		Length = 1.5,
		CustomPawn = "HiveWarrior"
	}
}

local isTargetScore
function Wolf_ReflexReave:GetTargetScore(p1, p2)
	isTargetScore = true
	local ret = Skill.GetTargetScore(self, p1, p2)
	isTargetScore = false
	
	return 10
end

function Wolf_ReflexReave:GetTargetArea(point)
	local ret = PointList()
	
	ret:push_back(point)
	
	return ret
end

function Wolf_ReflexReave:GetSkillEffect(p1, p2, parentSkill, isTipImage)
	local ret = SkillEffect()
	local mission = GetCurrentMission()
	local targets = {}
	local shooter = Board:GetPawn(p1)
	local damage = SpaceDamage(p1)
	local i = 0
	
	if not shooter then
		ret:AddQueuedMelee(damage)
		return ret
	end
	
	for dir = DIR_START, DIR_END do
		local target = p1 + DIR_VECTORS[dir]
		
		if Board:IsValid(target) then
			local pawn = Board:GetPawn(target)
			
			local isEnemy = false
			if pawn ~= nil then
				if pawn:GetTeam() == TEAM_PLAYER then
					if not pawn:IsDead() then
						isEnemy = true
					end
				end
			end
			
			local isBuilding = false
			if Board:IsBuilding(target) and Board:IsPowered(target) then
				isBuilding = true
			end
			
			table.insert(targets, {
				id = p2idx(target),
				loc = target,
				dir = dir,
				isEnemy = isEnemy,
				isBuilding = isBuilding,
			})
		end
	end
	
	local hasEnemy = false
	
	-- filter out directions without a target.
	for i = #targets, 1, -1 do
		if not targets[i].isEnemy then--and not targets[i].isBuilding then
			if logging then LOG("Removing target: "..tostring(targets[i].isEnemy).." / "..tostring(targets[i].isBuilding)) end
			table.remove(targets, i)
		elseif targets[i].isEnemy then
			hasEnemy = true
		end
	end
	
	if logging then LOG("Targets remaining: "..#targets) end
	
	-- if enemy in range, filter out building tiles
	if hasEnemy then
		for i = #targets, 1, -1 do
			if not targets[i].isEnemy then
				if logging then LOG("Removing target: "..tostring(targets[i].isEnemy).." / "..tostring(targets[i].isBuilding)) end
				table.remove(targets, i)
			end
		end
	end
	
	local finaltarget = nil
	if #targets > 0 then
		local result = targets[1]
		
		finaltarget = result.loc
		GAME.HW_LastReave = result.dir
	elseif GAME.HW_LastReave ~= nil then
		finaltarget = p1 + DIR_VECTORS[GAME.HW_LastReave]
	else
		damage.bHide = true
		ret:AddQueuedScript(string.format("Board:AddAlert(%s, 'NO TARGET')", p1:GetString()))
		return ret
	end
	
	damage = SpaceDamage(finaltarget, self.GetDamage())
	damage.sAnimation = "SwipeClaw2"
	damage.sSound = "/enemy/beetle_2/attack_impact"
	ret:AddQueuedMelee(p1,damage)
	
	return ret
end

Wolf_ReflexReave_Tip = Wolf_ReflexReave:new{}

function Wolf_ReflexReave_Tip:GetTargetArea(p)
	local ret = PointList()
	ret:push_back(self.TipImage.Target)
	ret:push_back(self.TipImage.Second_Target)
	return ret
end

function Wolf_ReflexReave_Tip:GetSkillEffect(p1, p2)
	-- hardcode tipimage
	local ret = SkillEffect()
	local unit = self.TipImage.Unit
	local enemy = self.TipImage.Enemy
	local dest = Point(unit.x, enemy.y)
	local building = self.TipImage.Building
	
	if p2 == unit then
		
		local damage = SpaceDamage(building, self.Damage)
		local repair = SpaceDamage(building)
		damage.sScript = "Board:ClearSpace(".. building:GetString() ..")"
		repair.sScript = "Board:SetTerrain(".. building:GetString() ..", TERRAIN_BUILDING)"
		
		-- move taunter into place.
		ret:AddDelay(0.67)
		ret:AddScript(string.format("Board:GetPawn(%s):Move(%s)", enemy:GetString(), dest:GetString()))
		ret:AddDelay(0.08)
		
		-- increase speed so fake projectile hits instantly.
		worldConstants.QueuedSetSpeed(ret, 1000)
		ret:AddQueuedMelee(damage, NO_DELAY)
		ret:AddQueuedMelee(repair, NO_DELAY)
		worldConstants.QueuedResetSpeed(ret)
		
		-- display redirected projectile arrow.
		--ret:AddScript(string.format("Board:AddAnimation(%s, 'lmn_Cactus_Damage_Close_'.. %s, ANIM_NO_DELAY)", dest:GetString(), self.Damage))
		
	else
		-- second attack on taunting enemy.
		local d = SpaceDamage(dest, self.Damage)
		d.sAnimation = self.Anim_Impact
		ret:AddDamage(d)
	end
	
	return ret
end

------------------------------------------------------
--                 PLAYER WEAPONRY                  --
------------------------------------------------------

-- Disabled for release, may be added back in at some point

--[[

Passive_Adaptation = PassiveSkill:new{
	PowerCost = 0,
	Icon = "weapons/passives/passive_adaptation.png",
	Passive = "adapt",
	Upgrades = 1,
	UpgradeCost = {2},
	UpgradeList = { "Mass Adapt" },
	Rarity = 1,
	TipImage = {
		Unit = Point(2,3)
	}
}

Passive_Adaptation_A = Passive_Adaptation:new{
	Passive = "adapt_aoe",
	TipImage = {
		Unit = Point(2,3),
		Friendly = Point(2,1),
		Friendly2 = Point(3,2),
	}
}

-------------------------------------------------------

Prime_GridOverload = Skill:new{
	GetDamage = function()
		local grid = GameData.network
		
		if grid == nil then
			return 3
		elseif grid == 10 then
			return 5
		elseif grid == 9 then
			return 4
		elseif grid == 8 then
			return 4
		elseif grid == 7 then
			return 3
		elseif grid == 6 then
			return 3
		elseif grid == 5 then
			return 2
		elseif grid == 4 then
			return 2
		elseif grid == 3 then
			return 1
		elseif grid == 2 then
			return 1
		elseif grid == 1 then
			return 1
		end
		
		return 3
	end,
	PathSize = 1,
	SelfDamage = 3,
	PowerCost = 1,
	Icon = "weapons/prime_overload.png",
	Upgrades = 1,
	UpgradeCost = {2, 3},
	UpgradeList = { "Safe Operation", "Grid Channeling" },
	Rarity = 1,
	TipDamage = 5,
	MinDamage = 1,
	Buildings = false,
	TipImage = {
		Unit = Point(3,2),
		Building = Point(2,2),
		Friendly = Point(2,1),
		Enemy = Point(4,2),
		Enemy2 = Point(2,3),
		Enemy3 = Point(1,1),
		Target = Point(3,2)
	}
}

Prime_GridOverload_A = Prime_GridOverload:new{
	SelfDamage = 2
}

Prime_GridOverload_B = Prime_GridOverload:new{
	Buildings = true,
	SelfDamage = 4
}

Prime_GridOverload_AB = Prime_GridOverload:new{
	Buildings = true,
	SelfDamage = 3
}

function Prime_GridOverload:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)
	return ret
end

function Prime_GridOverload:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local hash = function(point) return point.x + point.y*10 end
	local explored = {[hash(p1)] = true}
	
	ret:AddAnimation(p1,"Lightning_Hit")
	ret:AddDamage(SpaceDamage(p1, self.SelfDamage))
	
	for dir = DIR_START, DIR_END do
		local tile = p1 + DIR_VECTORS[dir]
		local damage = SpaceDamage(tile, self.GetDamage())
		local todo = {tile}
		local origin = { [hash(tile)] = p1 }
		
		while #todo ~= 0 do
			local current = pop_back(todo)
			
			if not explored[hash(current)] then
				explored[hash(current)] = true
				
				if self.Buildings and (Board:IsBuilding(current) or Board:IsPawnTeam(current, TEAM_PLAYER)) then
					local direction = GetDirection(current - origin[hash(current)])
					damage.sAnimation = "Lightning_Attack_"..direction
					damage.loc = current
					damage.iDamage = DAMAGE_ZERO
					
					ret:AddDamage(damage)
					ret:AddAnimation(current,"Lightning_Hit")
					
					for i = DIR_START, DIR_END do
						local neighbor = current + DIR_VECTORS[i]
						if not explored[hash(neighbor)] then
							todo[#todo + 1] = neighbor
							origin[hash(neighbor)] = current
						end
					end
				else
					local direction = GetDirection(current - origin[hash(current)])
					damage.sAnimation = "Lightning_Attack_"..direction
					damage.loc = current
					damage.iDamage = self.GetDamage()
					
					ret:AddDamage(damage)
				end
			end
		end
	end

	return ret
end

-------------------------------------------------------

Passive_ServoEvade = PassiveSkill:new{
	PowerCost = 1,
	Icon = "weapons/passives/passive_servoevade.png",
	Passive = "evade",
	Upgrades = 0,
	Rarity = 1,
	TipImage = {
		Unit = Point(2,3)
	}
}

-------------------------------------------------------

Science_ChronoBoost = Skill:new{
	PowerCost = 2,
	Icon = "weapons/science_timeskip.png",
	Upgrades = 0,
	Limited = 1,
	Rarity = 1,
	LaunchSound = "/weapons/swap",
	TipImage = {
		Unit = Point(2,2),
		Target = Point(2,2)
	}
}

function Science_ChronoBoost:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(Point(point.x+1, point.y))
	ret:push_back(Point(point.x-1, point.y))
	return ret
end

local function GetTilesInRange(origin, range)
	local results = {}
	for x = 0,7 do
		for y = 0,7 do
			if origin:Manhattan(Point(x,y)) == range then
				results[#results+1] = Point(x,y)
			end
		end
	end
	return results
end

function Science_ChronoBoost:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	
	ret:AddSound(self.LaunchSound)
	
	if p2.x < p1.x then
		ret:AddBounce(p1, 10)
		ret:AddDelay(0.2)

		for i = 1,8 do
			local points = GetTilesInRange(p1, i)
			
			for j = 1,#points do
				if Board:IsValid(points[j]) then
					ret:AddBounce(points[j], -1*(i-9))
				end
			end
			
			ret:AddDelay(0.2)
		end
	else
		ret:AddBounce(p1, -10)
		ret:AddDelay(0.2)

		for i = 1,8 do
			local points = GetTilesInRange(p1, i)
			
			for j = 1,#points do
				if Board:IsValid(points[j]) then
					ret:AddBounce(points[j], i-9)
				end
			end
			
			ret:AddDelay(0.2)
		end
	end
	
	return ret
end

-]]

-------------------------------------------------------
