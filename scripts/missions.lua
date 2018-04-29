
oldMissionGetSpawnCount = Mission.GetSpawnCount
function Mission:GetSpawnCount()
    local count = oldMissionGetSpawnCount(self)
	local newCount = count
    LOG("Mission:GetSpawnCount = ".. count)
	if GAME.HW_DeadWarrior then
        LOG("Mission:GetSpawnCount - Jack shit! Spawning "..count)
        return count
	elseif GAME.HW_WarriorOnBoard then
		newCount = count - 2
		if newCount < 1 then newCount = 1 end
		LOG("Mission:GetSpawnCount - Hive Warrior! Spawning "..newCount)
		return newCount
    elseif GAME.HW_TimePodExists then
		newCount = count - 1
		if newCount < 2 then newCount = 2 end
        LOG("Mission:GetSpawnCount - Timepod! Spawning "..newCount)
        return newCount
    else
        LOG("Mission:GetSpawnCount - Jack shit! Spawning "..count)
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
		
        return newPawn..alpha
    else
        LOG("Spawner:NextPawn - Spawning whatever")
        return sPawn
    end
end

local oldBaseObjectives = Mission.BaseObjectives
function Mission:BaseObjectives()
	if GAME.HW_ObjStatus ~= nil then
		Game:AddObjective("Defeat the Hive Warrior", GAME.HW_ObjStatus, REWARD_REP, 1)
	end
	local obj = oldBaseObjectives(self)
	return obj
end

-- Full fucking override until I figure out how to do a partial override
local oldBaseCompletedObjectives = Mission.BaseCompletedObjectives
function Mission:BaseCompletedObjectives()
	local primary = nil
	if GAME.HW_ObjStatus ~= nil then
		if GAME.HW_ObjStatus == OBJ_COMPLETE then
			primary = Objective("Defeat the Hive Warrior", 1, 1)
		else
			primary = Objective("The Hive Warrior escaped", 0, 1)
		end
	end
	
	local ret = {}
	
	if primary ~= nil then
		if type(primary) ~= "table" then
			primary = { primary }
		end
		ret = add_tables(ret,primary)
	end
	
	local secondary = self:GetCompletedObjectives()
	
	if type(secondary) ~= "table" then
		secondary = { secondary }
	end
	
	ret = add_tables(ret,secondary)
	ret = add_tables(ret,self:GetBonusCompleted())
	
	GAME.HW_ObjStatus = nil
	return ret
end
