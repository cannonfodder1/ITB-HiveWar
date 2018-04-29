-- Overloading global.lua's ScorePositioning function so it will work with this mod

local originalScorePositioning = ScorePositioning
function ScorePositioning(point, pawn)
    local pawnClass = _G[pawn:GetType()]
    if (pawnClass.ScorePositioning) then
        return pawnClass:ScorePositioning(point, pawn)
    end
    return originalScorePositioning(point, pawn)
end

-------------------------

HiveWarrior = {
	Health = 5,
	Name = "Hive Warrior",
	Image = "HiveWarrior",
	ImageOffset = 0,
	MoveSpeed = 3,
	-- Enable Reflex Fire on this unit
	Overwatch = {
		Range = 3, -- range in tiles
		ShotsTotal = 1, -- total shots this unit can take per turn
		ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
		WeaponSlot = 2, -- the slot of the weapon that we want to fire
	},
	Massive = true,
	DefaultTeam = TEAM_ENEMY,
	SkillList = { "Reave", "Biocannon" },
	ImpactMaterial = IMPACT_INSECT,
	SoundLocation = "/enemy/scorpion_2/",
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
	
	-- Make sure mechs aren't blocking the reflex fire line of sight
	for dir = DIR_START, DIR_END do
		target = point + DIR_VECTORS[dir]
		local pawnRange = _G[pawn:GetType()].Overwatch
		while Board:IsValid(target) and not Board:IsSmoke(target) and point:Manhattan(target) <= pawnRange.Range do
			if Board:IsPawnTeam(target, TEAM_PLAYER) then
				rangedScore = rangedScore - 3
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
		
		if Board:GetTerrain(target) == TERRAIN_LAVA then rangedScore = rangedScore - 5 end
		
		-- Don't stand anywhere near the horrible shit
		target2 = target + DIR_VECTORS[dir]
		
		if Board:IsDangerous(target2) then rangedScore = rangedScore - 10 end -- Danger marker for Volcano Island environmental hazards
		
		if Board:IsEnvironmentDanger(target2) then rangedScore = rangedScore - 10 end -- Danger marker for other environmental hazards
	
		if Board:IsDangerousItem(target2) then rangedScore = rangedScore - 10 end -- Land mines and freeze mines
		--[[
		target3 = target + DIR_VECTORS[dir+1]
		
		if Board:IsDangerous(target3) then rangedScore = rangedScore - 10 end -- Danger marker for Volcano Island environmental hazards
		
		if Board:IsEnvironmentDanger(target3) then rangedScore = rangedScore - 10 end -- Danger marker for other environmental hazards
	
		if Board:IsDangerousItem(target3) then rangedScore = rangedScore - 10 end -- Land mines and freeze mines
		
		target4 = target + DIR_VECTORS[dir-1]
		
		if Board:IsDangerous(target4) then rangedScore = rangedScore - 10 end -- Danger marker for Volcano Island environmental hazards
		
		if Board:IsEnvironmentDanger(target4) then rangedScore = rangedScore - 10 end -- Danger marker for other environmental hazards
	
		if Board:IsDangerousItem(target4) then rangedScore = rangedScore - 10 end -- Land mines and freeze mines
		--]]
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