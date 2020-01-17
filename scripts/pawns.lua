-- Overloading global.lua's ScorePositioning function so it will work with this mod

local originalScorePositioning = ScorePositioning
function ScorePositioning(point, pawn)
    local pawnClass = _G[pawn:GetType()]
    if (pawnClass.ScorePositioning) then
        return pawnClass:ScorePositioning(point, pawn)
    end
    return originalScorePositioning(point, pawn)
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
	
-------------------------

HiveWarrior = {
	Name = "Hive Warrior",
	Image = "HiveWarrior",
	ImageOffset = 0,
	GetHealth = function() return GAME.HW_Health or 5 end,
	GetMoveSpeed = function() return GAME.HW_Move or 3 end,
	-- Enable Reflex Fire on this unit
	ReflexConfig = {
		Range = 3, -- range in tiles
		ShotsTotal = 1, -- total shots this unit can take per turn
		ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
		WeaponSlot = 2, -- the slot of the weapon that we want to fire
	},
	Massive = true,
	GetArmor = function() return EvoCheck("A") or false end,
	DefaultTeam = TEAM_ENEMY,
	SkillList = { "Wolf_Reave", "Wolf_Biocannon" },
	ImpactMaterial = IMPACT_INSECT,
	SoundLocation = "/enemy/scorpion_2/",
	GetPortrait = function()
		if Wolf_HiveWarriorPortrait ~= nil then return "enemy/"..Wolf_HiveWarriorPortrait else return "enemy/hwportrait_normal" end
	end
}
AddPawn("HiveWarrior")

-------------------------

function HiveWarrior:ScorePositioning(point, pawn)

	-- Don't step on bad shit
	if Board:IsDangerous(point) then return -100 end
	
	if Board:IsDangerousItem(point) then return -100 end
	
	if Board:IsEnvironmentDanger(point) then return -100 end
	
	if Board:IsPod(point) then return -100 end
	
	local rangedScore = 0
	
	if Board:IsTargeted(point) then rangedScore = rangedScore - 10 end
	
	if Board:IsSmoke(point) then rangedScore = rangedScore - 10 end
	
	if Board:IsAcid(point) and not pawn:IsAcid() then rangedScore = rangedScore - 10 end
	
	if Board:IsFire(point) and not pawn:IsFire() then rangedScore = rangedScore - 10 end
	
	if Board:IsSpawning(point) then rangedScore = rangedScore - 10 end
	
	if Board:GetTerrain(point) == TERRAIN_WATER then rangedScore = rangedScore - 15 end
	
	if Board:GetTerrain(point) == TERRAIN_LAVA then rangedScore = rangedScore - 15 end
	
	-- Make sure mechs aren't blocking the reflex fire line of sight
	for dir = DIR_START, DIR_END do
		target = point + DIR_VECTORS[dir]
		local pawnRange = _G[pawn:GetType()].ReflexConfig
		while Board:IsValid(target) and not Board:IsSmoke(target) and point:Manhattan(target) <= pawnRange.Range do
			if Board:IsPawnTeam(target, TEAM_PLAYER) then
				rangedScore = rangedScore - 2
			end
			rangedScore = rangedScore + 1
			target = target + DIR_VECTORS[dir]
		end
	end
	
	-- Don't stand next to bad shit
	for dir = DIR_START, DIR_END do
		target = point + DIR_VECTORS[dir]
		if Board:IsPod(target) then rangedScore = rangedScore + 10 end
		
		if Board:IsBuilding(target) then rangedScore = rangedScore + 5 end
	
		if Board:IsTargeted(target) then rangedScore = rangedScore - 1 end
	
		if Board:IsSmoke(target) then rangedScore = rangedScore - 5 end
	
		if Board:IsAcid(target) and not pawn:IsAcid() then rangedScore = rangedScore - 5 end
	
		if Board:IsFire(target) and not pawn:IsFire() then rangedScore = rangedScore - 5 end
	
		if Board:IsSpawning(target) then rangedScore = rangedScore - 10 end
	
		if Board:IsDangerous(target) then rangedScore = rangedScore - 20 end -- Danger marker for Volcano Island environmental hazards
		
		if Board:IsEnvironmentDanger(target) then rangedScore = rangedScore - 20 end -- Danger marker for other environmental hazards
	
		if Board:IsDangerousItem(target) then rangedScore = rangedScore - 20 end -- Land mines and freeze mines
		
		if Board:GetTerrain(target) == TERRAIN_WATER then rangedScore = rangedScore - 5 end
		
		if Board:GetTerrain(target) == TERRAIN_LAVA then rangedScore = rangedScore - 5 end
		
		-- Don't stand anywhere near the horrible shit
		--[[
		for dir = DIR_START, DIR_END do
			targetadjacent = target + DIR_VECTORS[dir]
			if targetadjacent ~= target then
				if Board:IsDangerous(targetadjacent) then rangedScore = rangedScore - 10 end -- Danger marker for Volcano Island environmental hazards
			
				if Board:IsEnvironmentDanger(targetadjacent) then rangedScore = rangedScore - 10 end -- Danger marker for other environmental hazards
		
				--if Board:IsDangerousItem(targetadjacent) then rangedScore = rangedScore - 10 end -- Land mines and freeze mines
			end
		end
		--]]
		-- Disabled because it too often led to situations where the Hive Warrior would be a coward and refuse to attack
	end
	
	local edge1 = point.x == 0 or point.x == 7
	local edge2 = point.y == 0 or point.y == 7
	
	if edge1 and edge2 then
		rangedScore = rangedScore - 5 --really avoid corners
	elseif edge1 or edge2 then
		rangedScore = rangedScore - 2 --edges are discouraged
	end
	
	return rangedScore
end

HiveWarriorFinal = {
	Name = "Hive Warrior",
	Image = "HiveWarriorFinal",
	ImageOffset = 0,
	GetHealth = function() return GAME.HW_Health or 5 end,
	GetMoveSpeed = function() return GAME.HW_Move or 3 end,
	-- Enable Reflex Fire on this unit
	ReflexConfig = {
		Range = 3, -- range in tiles
		ShotsTotal = 1, -- total shots this unit can take per turn
		ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
		WeaponSlot = 2, -- the slot of the weapon that we want to fire
	},
	Massive = true,
	GetArmor = function() return EvoCheck("A") or false end,
	DefaultTeam = TEAM_ENEMY,
	SkillList = { "Wolf_Reave", "Wolf_Biocannon" },
	ImpactMaterial = IMPACT_INSECT,
	SoundLocation = "/enemy/scorpion_2/",
	GetPortrait = function()
		if Wolf_HiveWarriorPortrait ~= nil then return "enemy/"..Wolf_HiveWarriorPortrait else return "enemy/hwportrait_normal" end
	end
}
AddPawn("HiveWarriorFinal")

-------------------------

function HiveWarriorFinal:ScorePositioning(point, pawn)

	-- Don't step on bad shit
	if Board:IsDangerous(point) then return -100 end
	
	if Board:IsDangerousItem(point) then return -100 end
	
	if Board:IsEnvironmentDanger(point) then return -100 end
	
	if Board:IsPod(point) then return -100 end
	
	local rangedScore = 0
	
	if Board:IsTargeted(point) then rangedScore = rangedScore - 10 end
	
	if Board:IsSmoke(point) then rangedScore = rangedScore - 10 end
	
	if Board:IsAcid(point) and not pawn:IsAcid() then rangedScore = rangedScore - 10 end
	
	if Board:IsFire(point) and not pawn:IsFire() then rangedScore = rangedScore - 10 end
	
	if Board:IsSpawning(point) then rangedScore = rangedScore - 10 end
	
	if Board:GetTerrain(point) == TERRAIN_WATER then rangedScore = rangedScore - 15 end
	
	if Board:GetTerrain(point) == TERRAIN_LAVA then rangedScore = rangedScore - 15 end
	
	-- Make sure mechs aren't blocking the reflex fire line of sight
	for dir = DIR_START, DIR_END do
		target = point + DIR_VECTORS[dir]
		local pawnRange = _G[pawn:GetType()].ReflexConfig
		while Board:IsValid(target) and not Board:IsSmoke(target) and point:Manhattan(target) <= pawnRange.Range do
			if Board:IsPawnTeam(target, TEAM_PLAYER) then
				rangedScore = rangedScore - 2
			end
			rangedScore = rangedScore + 1
			target = target + DIR_VECTORS[dir]
		end
	end
	
	-- Don't stand next to bad shit
	for dir = DIR_START, DIR_END do
		target = point + DIR_VECTORS[dir]
		if Board:IsPod(target) then rangedScore = rangedScore + 10 end
		
		if Board:IsBuilding(target) then rangedScore = rangedScore + 5 end
	
		if Board:IsTargeted(target) then rangedScore = rangedScore - 1 end
	
		if Board:IsSmoke(target) then rangedScore = rangedScore - 5 end
	
		if Board:IsAcid(target) and not pawn:IsAcid() then rangedScore = rangedScore - 5 end
	
		if Board:IsFire(target) and not pawn:IsFire() then rangedScore = rangedScore - 5 end
	
		if Board:IsSpawning(target) then rangedScore = rangedScore - 10 end
	
		if Board:IsDangerous(target) then rangedScore = rangedScore - 20 end -- Danger marker for Volcano Island environmental hazards
		
		if Board:IsEnvironmentDanger(target) then rangedScore = rangedScore - 20 end -- Danger marker for other environmental hazards
	
		if Board:IsDangerousItem(target) then rangedScore = rangedScore - 20 end -- Land mines and freeze mines
		
		if Board:GetTerrain(target) == TERRAIN_WATER then rangedScore = rangedScore - 5 end
		
		if Board:GetTerrain(target) == TERRAIN_LAVA then rangedScore = rangedScore - 5 end
		
		-- Don't stand anywhere near the horrible shit
		--[[
		for dir = DIR_START, DIR_END do
			targetadjacent = target + DIR_VECTORS[dir]
			if targetadjacent ~= target then
				if Board:IsDangerous(targetadjacent) then rangedScore = rangedScore - 10 end -- Danger marker for Volcano Island environmental hazards
			
				if Board:IsEnvironmentDanger(targetadjacent) then rangedScore = rangedScore - 10 end -- Danger marker for other environmental hazards
		
				--if Board:IsDangerousItem(targetadjacent) then rangedScore = rangedScore - 10 end -- Land mines and freeze mines
			end
		end
		--]]
		-- Disabled because it too often led to situations where the Hive Warrior would be a coward and refuse to attack
	end
	
	local edge1 = point.x == 0 or point.x == 7
	local edge2 = point.y == 0 or point.y == 7
	
	if edge1 and edge2 then
		rangedScore = rangedScore - 5 --really avoid corners
	elseif edge1 or edge2 then
		rangedScore = rangedScore - 2 --edges are discouraged
	end
	
	return rangedScore
end

-------------------------

HiveWarriorProxy = {
	Name = "Hive Warrior",
	Image = nil,
	ImageOffset = 0,
	Health = 1,
	MoveSpeed = 0,
	DefaultTeam = TEAM_NEUTRAL,
	SkillList = { },
	ImpactMaterial = IMPACT_INSECT,
	SoundLocation = "/enemy/scorpion_2/",
	GetPortrait = function()
		if Wolf_HiveWarriorPortrait ~= nil then return "enemy/"..Wolf_HiveWarriorPortrait else return "enemy/hwportrait_normal" end
	end
}
AddPawn("HiveWarriorProxy")

-------------------------

HiveGuard = 
	{
		Name = "Firefly",
		Health = 5,
		MoveSpeed = 2,
		Image = "HiveGuard",	
		ImageOffset = 0,
		ReflexConfig = {
			Range = 3, -- range in tiles
			ShotsTotal = 1, -- total shots this unit can take per turn
			ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
			WeaponSlot = 1, -- the slot of the weapon that we want to fire
		},
		SkillList = { "Wolf_Biocannon" },
		Ranged = 1,
		SoundLocation = "/enemy/firefly_soldier_2/",
		DefaultTeam = TEAM_ENEMY,
		ImpactMaterial = IMPACT_INSECT
	}
AddPawn("HiveGuard") 
