
local this = {
	bonusGrid = 0,
}

oldMissionGetSpawnCount = Mission.GetSpawnCount
function Mission:GetSpawnCount()
    local count = oldMissionGetSpawnCount(self)
	local newCount = count
    LOG("Mission:GetSpawnCount = ".. count)
	if count == 0 then return 0 end
	if GAME.HW_DeadWarrior then
        LOG("Mission:GetSpawnCount - Dead warrior! Spawning "..count)
        return count
	elseif GAME.HW_WarriorOnBoard then
		if count <= 1 then
			newCount = count
		elseif count == 2 then
			newCount = count - 1
		else
			newCount = count - 2
		end
		LOG("Mission:GetSpawnCount - Hive Warrior! Spawning "..newCount)
		return newCount
    elseif GAME.HW_TimePodExists then
		if count <= 2 then
			newCount = count
		else
			newCount = count - 1
		end
        LOG("Mission:GetSpawnCount - Timepod! Spawning "..newCount)
        return newCount
    else
        LOG("Mission:GetSpawnCount - Nothing new! Spawning "..count)
        return count
    end
end

local oldSpawnerNextPawn = Spawner.NextPawn
function Spawner:NextPawn(pawn_tables)
	pawn_tables = pawn_tables or GAME:GetSpawnList(self.spawn_island)
    local sPawn = oldSpawnerNextPawn(self, pawn_tables)
	
    if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior then
        LOG("Spawner:NextPawn - Spawning only weakpawns")
		local newPawn = self:SelectPawn(pawn_tables, true)
		local alpha = 1
		local island = GetSector()
		local diff = GetDifficulty()
		local roll = math.random(5)
		local cap = 0
		
		if diff == 0 then
			LOG("Difficulty is EASY")
			if island == 1 then
				cap = 0
			elseif island == 2 then
				cap = 0
			elseif island == 3 then
				cap = 1
			elseif island == 4 then
				cap = 2
			end
		end
		if diff == 1 then
			LOG("Difficulty is NORMAL")
			if island == 1 then
				cap = 0
			elseif island == 2 then
				cap = 1
			elseif island == 3 then
				cap = 2
			elseif island == 4 then
				cap = 4
			end
		end
		if diff == 2 then
			LOG("Difficulty is HARD")
			if island == 1 then
				cap = 1
			elseif island == 2 then
				cap = 2
			elseif island == 3 then
				cap = 3
			elseif island == 4 then
				cap = 5
			end
		end
		
		LOG("Roll: "..roll.." against Cap: "..cap)
		if roll <= cap then alpha = 2 end
		
		self:ModifyCount(newPawn,1)
        return newPawn..alpha
    else
        LOG("Spawner:NextPawn - Spawning whatever")
        return sPawn
    end
end

local oldBaseObjectives = Mission.BaseObjectives
function Mission:BaseObjectives()
	if GAME.HW_ObjStatus ~= nil then
		if GetSector() == 4 then
			Game:AddObjective("Defeat the Hive Warrior (Improved Grid next Island)", GAME.HW_ObjStatus, 5, 1)
		else
			Game:AddObjective("Defeat the Hive Warrior (Extra Power)", GAME.HW_ObjStatus, REWARD_POWER, 1)
		end
	end
	local obj = oldBaseObjectives(self)
	return obj
end

local oldBaseCompletedObjectives = Mission.BaseCompletedObjectives
function Mission:BaseCompletedObjectives()
	local ret = oldBaseCompletedObjectives(self)
	local obj = nil
	if GAME.HW_ObjStatus ~= nil then
		if GAME.HW_ObjStatus == OBJ_COMPLETE then
			if GetSector() == 4 then
				obj = Objective("Defeat the Hive Warrior (Extra Power!)", 1, 1)
				obj.category = REWARD_POWER
			else
				obj = Objective("Defeat the Hive Warrior (Improved Grid next Island!)", 1, 1)
				obj.category = -3
			end
			ret = add_tables(ret, {obj})
		else
			if GetSector() == 4 then
				obj = Objective("Defeat the Hive Warrior (Escaped!)", 0, 1)
				obj.category = REWARD_POWER
			else
				obj = Objective("Defeat the Hive Warrior (Escaped!)", 0, 1)
				obj.category = -3
			end
			ret = add_tables(ret, {obj})
		end
	end

	-- reset the variables
	GAME.HW_WarriorOnBoard = false
	GAME.HW_DeadWarrior = false
	GAME.HW_TimePodExists = false
	GAME.HW_PodTile = nil
	GAME.HW_WarriorLoc = nil
	GAME.HW_PodHolder = nil
	GAME.HW_ObjStatus = nil
	
	return ret
end

local oldGetCityPower = getCityPower
function getCityPower(sector)
    if GAME.HW_MaxPower ~= 0 and GAME.HW_MaxPower ~= nil then
		local power = GAME.HW_MaxPower + 7
		LOG("Grid Power: "..power)
		return power
    end
	LOG("Returning normal power values")
	return oldGetCityPower(sector)
end
