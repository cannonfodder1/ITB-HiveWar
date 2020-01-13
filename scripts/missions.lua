
local this = {
	bonusGrid = 0,
}

-- Enable this for log messages
local logging = false

oldMissionGetSpawnCount = Mission.GetSpawnCount
function Mission:GetSpawnCount()
    local count = oldMissionGetSpawnCount(self)
	local newCount = count
	local diff = GetDifficulty()
    if logging then LOG("Mission:GetSpawnCount = ".. count) end
	if count == 0 then return 0 end
	if GAME.HW_DeadWarrior then
        if logging then LOG("Mission:GetSpawnCount - Dead warrior! Spawning "..count) end
        return count
	elseif GAME.HW_WarriorOnBoard and self ~= Mission_Final_Cave then
		if count <= 1 then
			newCount = count
		elseif count == 2 then
			newCount = count - 1
		else
			newCount = count - 2
		end
		if diff == 2 then
			newCount = newCount - 1
		end
		if logging then LOG("Mission:GetSpawnCount - Hive Warrior! Spawning "..newCount) end
		return newCount
    elseif GAME.HW_TimePodExists then
		if count <= 2 then
			newCount = count
		elseif diff ~= 2 then
			newCount = count - 1
		end
        if logging then LOG("Mission:GetSpawnCount - Timepod! Spawning "..newCount) end
        return newCount
    else
        if logging then LOG("Mission:GetSpawnCount - Nothing new! Spawning "..count) end
        return count
    end
end

local oldSpawnerNextPawn = Spawner.NextPawn
function Spawner:NextPawn(pawn_tables)
	pawn_tables = pawn_tables or GAME:GetSpawnList(self.spawn_island)
    local sPawn = oldSpawnerNextPawn(self, pawn_tables)
	
    if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior and self.spawn_island ~= 5 then
        if logging then LOG("Spawner:NextPawn - Spawning only weakpawns") end
		local newPawn = self:SelectPawn(pawn_tables, true)
		local alpha = 1
		local island = GetSector()
		local diff = GetDifficulty()
		local roll = math.random(5)
		local cap = 0
		
		if diff == 0 then
			if logging then LOG("Difficulty is EASY") end
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
			if logging then LOG("Difficulty is NORMAL") end
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
			if logging then LOG("Difficulty is HARD") end
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
		
		if logging then LOG("Roll: "..roll.." against Cap: "..cap) end
		if roll <= cap then alpha = 2 end
		
		self:ModifyCount(newPawn,1)
        return newPawn..alpha
    else
        if logging then LOG("Spawner:NextPawn - Spawning whatever") end
        return sPawn
    end
end

local oldBaseObjectives = Mission.BaseObjectives
function Mission:BaseObjectives()
	if GAME.HW_ObjStatus ~= nil then
		if self == Mission_Final_Cave then
			if logging then LOG("FINAL MISSION!") end
		elseif GetSector() ~= 4 then
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
			ret = add_arrays(ret, {obj})
		else
			if GetSector() == 4 then
				obj = Objective("Defeat the Hive Warrior (Escaped!)", 0, 1)
				obj.category = REWARD_POWER
			else
				obj = Objective("Defeat the Hive Warrior (Escaped!)", 0, 1)
				obj.category = -3
			end
			-- If objective is failed, don't show it so that the player can still get the perfect island bonus
			--ret = add_tables(ret, {obj})
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
		if logging then LOG("Grid Power: "..power) end
		return power
    end
	if logging then LOG("Returning normal power values") end
	return oldGetCityPower(sector)
end

local oldAddVoicePopup = AddVoicePopup
function AddVoicePopup(event, id, cast)
	-- If it isn't the specific event this override requires, just do the normal function
    if event ~= "Wolf_HW_Death" and event ~= "Wolf_HW_Retreat" then
		oldAddVoicePopup(event, id, cast)
		return
	end
	-- The Hive Warrior's death dialog needs to bypass the normal check for pawn:IsDead()
	
	cast = cast or { main = id, target = -1, other = -1 }
	cast.self = id
		
	local pop = VoicePopup()
	local personality = ""
	local corp = Game:GetCorp()
	
	pop.timetravel = event == "TimeTravel_Win" or event == "TimeTravel_Loss"
	
	local names = { main = "", target = "", other = "", self = ""}
	
	if id == PAWN_ID_CEO then
		personality = corp.ceo_personality
	else
		if Game:GetPawn(id) ~= nil then
			personality = Game:GetPawn(id):GetPersonality()
		else
			return --primary speaker doesn't exist
		end
	end
	
	if Personality[personality] == nil then
		if logging then LOG("FAILED TO FIND PERSONALITY") end
	    return
	end
	
	repeat
		pop.text = Personality[personality]:GetPilotDialog(event)
	until (string.find(pop.text,"#saved_corp") == nil or names.saved_corp ~= "")
	
	pop.pawn = id
	
	if string.find(pop.text,"#") ~= nil then
	
		local final_names = {}--copy_table(names)
	    for id, value in pairs(names) do
	        if Game:GetPawn(cast[id]) ~= nil then
				final_names[id.."_mech"] = Game:GetPawn(cast[id]):GetMechName()
				final_names[id.."_reverse"] = Game:GetPawn(cast[id]):GetPilotName(NAME_REVERSE)
			    final_names[id.."_first"] = Game:GetPawn(cast[id]):GetPilotName(NAME_FIRST)
				final_names[id.."_second"] = Game:GetPawn(cast[id]):GetPilotName(NAME_SECOND)
				final_names[id.."_last"] = final_names[id.."_second"]
				final_names[id.."_full"] = Game:GetPawn(cast[id]):GetPilotName(NAME_NORMAL)
	    	end
	    end

		local ceo_names = {}
		for i in corp.ceo_name:gmatch("%w+") do table.insert(ceo_names,i) end
		final_names.ceo_full = corp.ceo_name
		final_names.ceo_first = ceo_names[1]
		final_names.ceo_last = ceo_names[#ceo_names]
		final_names.ceo_second = ceo_names[#ceo_names]
		
		final_names.corporation = corp.bark_name
		final_names.corp = corp.bark_name
		
		if final_names.corp == "" and string.find(pop.text,"#corp") ~= nil then
			return--just skip #corp lines if there's no valid replacement for them
		end
		
		final_names.squad = Game:GetSquad()
	    final_names.saved_corp = Game:GetSavedCorp()
		
		for tag, name in pairs(final_names) do
			pop.text = string.gsub(pop.text,"#"..tag,name)
		end
	end
	
	if string.find(pop.text,"#") ~= nil then
		if logging then LOG("FAILED TO FIND TEXT") end
		--for whatever reason, it couldn't replace the token. don't do the popup.
		--(could be caused by typos or bugs. not ideal)
		return
	end

	Game:AddVoicePopup(pop)
end

local oldGetSkillInfo = GetSkillInfo
function GetSkillInfo(skill)
	if skill == "Extra_XP" then
		return PilotSkill("Experienced","Gain +2 bonus XP per kill. Can dodge incoming reflex shots from his rival.")
	end
	return oldGetSkillInfo(skill)
end

local oldMissionEnd = Mission_Final_Cave.MissionEnd
function Mission_Final_Cave:MissionEnd()
	local idx = 0
	local won = 0
	while idx < #GAME.HW_Encounters do
		if logging then LOG(GAME.HW_Encounters[idx+1]) end
		if GAME.HW_Encounters[idx+1] ~= "loss" then
			if won == 0 then won = idx+1 end
		end
		idx = idx + 1
		if logging then LOG(idx) end
	end
	
	if won == #GAME.HW_Encounters and idx > 4 then
		HiveWar_achvApi:TriggerChievo("HW_NoPodVictory", true)
	end
	
	Nostophobic = true
	origWeps = {}
	--
	for mech = 0, 2 do
		if _G[Board:GetPawn(mech):GetType()].SkillList ~= nil then
			for i, wep in ipairs(_G[Board:GetPawn(mech):GetType()].SkillList) do
				if logging then LOG(wep) end
				table.insert(origWeps, wep)
			end
		end
	end
	
	for mech = 0, 2 do
		for i, wep in ipairs(origWeps) do
			if Wolf_HasPoweredWeapon(Board:GetPawn(mech), wep, false) then
				Nostophobic = false
			end
		end
	end
	--
	if Nostophobic then
		HiveWar_achvApi:TriggerChievo("HW_Nostophobia", true)
	end
	
	oldMissionEnd()
end

