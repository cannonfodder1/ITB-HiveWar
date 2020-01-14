-- Where all the magic happens

local Wolf_MineTiles = {}

-- Enable this for log messages
local logging = false

-- master table from which HW statistics are copied, make any balance changes you want here
local MasterStatsHW = {
	Sector1 = {
		Move = 3,
		Health = 5,
		ReaveDmg = 2,
		BioDmg = 1,
		BioRange = 1,
	},
	Sector2 = {
		Move = 3,
		Health = 6,
		ReaveDmg = 2,
		BioDmg = 1,
		BioRange = 2,
	},
	Sector3 = {
		Move = 4,
		Health = 6,
		ReaveDmg = 3,
		BioDmg = 2,
		BioRange = 2,
	},
	Sector4 = {
		Move = 4,
		Health = 7,
		ReaveDmg = 3,
		BioDmg = 2,
		BioRange = 3,
	},
}
		
local function onLoad()
	if Game then
		GAME.HW_WarriorStats = copy_table(MasterStatsHW)
	end
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

local function UpdateWarriorSprite()
	local result = "HiveWarrior"
	local evo1 = GAME.HW_Evolutions[1]
	local evo2 = GAME.HW_Evolutions[2]
	local evo3 = GAME.HW_Evolutions[3]
	
	if evo1 == "A" or evo1 == "D" then
		result = result..evo1
	elseif evo2 == "A" or evo2 == "D" then
		result = result..evo2
	elseif evo3 == "A" or evo3 == "D" then
		result = result..evo3
	end
	
	if evo1 == "C" or evo1 == "M" then
		result = result..evo1
	elseif evo2 == "C" or evo2 == "M" then
		result = result..evo2
	elseif evo3 == "C" or evo3 == "M" then
		result = result..evo3
	end
	
	if evo1 == "F" or evo1 == "W" then
		result = result..evo1
	elseif evo2 == "F" or evo2 == "W" then
		result = result..evo2
	elseif evo3 == "F" or evo3 == "W" then
		result = result..evo3
	end
	
	if evo1 == "V" or evo1 == "R" then
		result = result..evo1
	elseif evo2 == "V" or evo2 == "R" then
		result = result..evo2
	elseif evo3 == "V" or evo3 == "R" then
		result = result..evo3
	end
	
	for _, pawn in pairs(_G) do
		if type(pawn) == "table" and pawn == HiveWarrior then
			pawn.Image = result
			if logging then LOG("Setting normal sprites to: "..result) end
		end
		if type(pawn) == "table" and pawn == HiveWarriorFinal then
			pawn.Image = result.."Final"
			if logging then LOG("Setting final sprites to: "..result) end
		end
	end
end
--[[
local function UpdateWarriorWeapons()
	if EvoCheck("R") then
		for _, pawn in pairs(_G) do
			if type(pawn) == "table" and pawn == HiveWarrior then
				pawn.SkillList = { "Wolf_ReflexReave", "Wolf_Biocannon" }
				if logging then LOG(save_table(pawn.SkillList)) end
			end
			if type(pawn) == "table" and pawn == HiveWarriorFinal then
				pawn.SkillList = { "Wolf_ReflexReave", "Wolf_Biocannon" }
			end
		end
	else
		for _, pawn in pairs(_G) do
			if type(pawn) == "table" and pawn == HiveWarrior then
				pawn.SkillList = { "Wolf_Reave", "Wolf_Biocannon" }
				if logging then LOG(save_table(pawn.SkillList)) end
			end
			if type(pawn) == "table" and pawn == HiveWarriorFinal then
				pawn.SkillList = { "Wolf_Reave", "Wolf_Biocannon" }
			end
		end
	end
end
--]]
--999 so the icon doesn't appear on the board, but only in his summary. Use (-3,24) to make it show up
Location["combat/icons/icon_adapt_glow.png"] = Point(-3,24)

local oldGetStatusTooltip = GetStatusTooltip
function GetStatusTooltip(id)
    if id == "adapt" then
        return {"Adaptive", "This unit sheds all negative status effects at the beginning of each player turn."}
    end
    return oldGetStatusTooltip(id)
end

local function SetAdaptive(point, flag)
    Board:SetTerrainIcon(point, flag and "adapt" or "")
end

local function BreachWarrior(pod)
	-- scan spaces adjacent to pod for valid placement
	-- spawn the Hive Warrior pawn
	
	if pod == nil then return end
	
	local island = GetSector()
    local dirs = { DIR_RIGHT, DIR_UP, DIR_DOWN, DIR_LEFT }
	local list = {1, 2, 3, 4, 5, 6, 7, 8}
	
	for i, v in ipairs(list) do
		for dir = DIR_START, DIR_END do
			tick = v
			target = pod
			while tick > 0 do
				target = target + DIR_VECTORS[dir]
				tick = tick - 1
			end
			if not Board:IsBlocked(target, PATH_GROUND)
			and not Board:IsFire(target)
			and not Board:IsAcid(target)
			and not Board:IsSmoke(target)
			and not Board:IsDangerous(target)
			and not Board:IsEnvironmentDanger(target)
			and not Board:IsDangerousItem(target)
			and Board:GetTerrain(target) ~= TERRAIN_LAVA
			and Board:IsValid(target) then
				
				local damage = SpaceDamage(target, 0)
				damage.sPawn = "HiveWarrior"
				Board:DamageSpace(damage)
				GAME.HW_WarriorLoc = target
				
				if island == 1 then
					Game:AddTutorial("Tut_Breach", GAME.HW_WarriorLoc)
				else
					Game:AddTutorial("Tut_Evolve", GAME.HW_WarriorLoc)
				end
				
				return
			end
		end
	end
	-- If we still can't find any space, try with less parameters
	for i, v in ipairs(list) do
		for dir = DIR_START, DIR_END do
			tick = v
			target = pod
			while tick > 0 do
				target = target + DIR_VECTORS[dir]
				tick = tick - 1
			end
			if not Board:IsBlocked(target, PATH_GROUND)
			and not Board:IsDangerous(target)
			and not Board:IsEnvironmentDanger(target)
			and not Board:IsDangerousItem(target)
			and Board:IsValid(target) then
			
				local damage = SpaceDamage(target, 0)
				damage.sPawn = "HiveWarrior"
				Board:DamageSpace(damage)
				GAME.HW_WarriorLoc = target
				
				if island == 1 then
					Game:AddTutorial("Tut_Breach", GAME.HW_WarriorLoc)
				else
					Game:AddTutorial("Tut_Evolve", GAME.HW_WarriorLoc)
				end
				
				return
			end
		end
	end
	if logging then LOG("HIVE WARRIOR SPAWNING FAILED! NO VALID TILES!") end
end

local function TrackMines()
	Wolf_MineTiles = {}
	for x = 0, 7 do
		for y = 0, 7 do
			if Board:IsDangerousItem(Point(x,y)) then
				table.insert(Wolf_MineTiles, Point(x,y))
			end
		end
	end
end

local function SmiteMines()
	local index = table.getn(Wolf_MineTiles)
	local ret = SkillEffect()
	ret:AddDelay(0.5)
	for i = 1, index do
		if logging then LOG(Wolf_MineTiles[i].x..","..Wolf_MineTiles[i].y) end
		local damage = SpaceDamage(Wolf_MineTiles[i], 1)
		damage.sAnimation = "Explo_Fire1"
		damage.bHide = true
		ret:AddDamage(damage)
		ret:AddDelay(0.2)
	end
	Board:AddEffect(ret)
end

function Wolf_OnTimeBreachWarningDone()
    GAME.HW_WarriorOnBoard = true
	GAME.HW_Encounter = true
	
    BreachWarrior(GAME.HW_PodTile)
    --if GetSector() == 4 then
        GAME.HW_ObjStatus = OBJ_STANDARD
    --end
	
	TrackMines()
	SmiteMines()
	
	HW_Intimidate("Wolf_HW_Spawn", false, 0)
end

local function Wolf_OnTimeBreachWarningStart()
	-- Pilot reaction and delay
	HW_Intimidate("Wolf_HW_Breach", false, 1)
    local fx = SkillEffect()
    fx:AddDelay(Wolf_BreachWarnTimeInSeconds - 1)
    Board:AddEffect(fx)
	
	-- ui element init
    Wolf_HWBreach:create()

    -- pretty effects to make it more noticeable
    Game:TriggerSound("/ui/map/region_lost")
    Board:StartShake(Wolf_BreachWarnTimeInSeconds)
    
    -- Delay vek burrowing out
    fx = SkillEffect()
    fx:AddDelay(Wolf_BreachWarnTimeInSeconds + 1)
    Board:AddEffect(fx)
end

local function pawnPositionChangedHook(mission, pawn, oldPosition)
	SetAdaptive(oldPosition, false)
end

local function skillStartHook(mission, pawn, weaponId, p1, p2)
	TrackMines()
	
	if Game then
		if pawn:GetPersonality() == "Original" then
			GAME.HW_WasRalph = true
		else
			GAME.HW_WasRalph = false
		end
		
		if weaponId == "Biocannon" then
			GAME.HW_Dodged = true
		else
			GAME.HW_Dodged = false
		end
	end
end
	
local function skillEndHook(mission, pawn, weaponId, p1, p2)
	TrackMines()

	local timer = mission
	
	if timer == nil then
		timer = GetCurrentMission()
	end
	
	if timer ~= nil then
		if weaponId == "Science_ChronoBoost" then
			if p2.x < p1.x then
				timer.TurnLimit = timer.TurnLimit + 1
			else
				timer.TurnLimit = timer.TurnLimit - 1
			end
		end
	end
end

local function queuedSkillEndHook(mission, pawn, weaponId, p1, p2)
end

local function pawnKilledHook(mission, pawn)
	if _G[pawn:GetType()].Name == "Hive Warrior" and GAME.HW_DeadWarrior == false then
		GAME.HW_WarriorLoc = pawn:GetSpace()
		
		if _G[pawn:GetType()] == HiveWarrior then
			GAME.HW_ObjStatus = OBJ_COMPLETE
			HW_Intimidate("Wolf_HW_Retreat", true, 2)
		end
		
		--Game:AddTutorial("Tut_RetreatWin", GAME.HW_WarriorLoc)
		if logging then LOG("Warrior Killed") end
		SetAdaptive(GAME.HW_WarriorLoc, false)
		GAME.HW_DeadWarrior = true
		GAME.HW_MaxPower = GAME.HW_MaxPower + 1
		GAME.HW_PowerUps = GAME.HW_PowerUps + 1
		GAME.HW_Encounters[#GAME.HW_Encounters+1] = "win"
		
		if GAME.HW_Overwatched == false then
			HiveWar_achvApi:TriggerChievo("HW_SilentKill", true)
		end
		
		if _G[pawn:GetType()] == HiveWarriorFinal then
			--HW_Intimidate("Wolf_HW_Death", true, 2)
			
			HiveWar_achvApi:TriggerChievo("HW_FinalKill", true)
			
			local idx = 0
			while idx < #GAME.HW_Encounters do
				if GAME.HW_Encounters[idx+1] ~= "win" and GAME.HW_Encounters[idx+1] ~= nil then
					idx = 999
				end
				idx = idx + 1
			end
			if idx == 5 then
				HiveWar_achvApi:TriggerChievo("HW_PentaKill", true)
			end
			
			if GAME.HW_WasRalph == true then
				HiveWar_achvApi:TriggerChievo("HW_RalphKill", true)
			end
		end
	end
	
	if pawn:GetTeam() == TEAM_ENEMY and GAME.HW_Dodged == true then
		HiveWar_achvApi:TriggerChievo("HW_FriendlyFire", true)
	end
	
	SetAdaptive(pawn:GetSpace(), false)
end

local function newTurnHook(mission)
    local turn = Board:GetTurn()
    -- Setup the Hive Warrior spawning
    if Game:GetTeamTurn() == TEAM_ENEMY and not GAME.HW_WarriorOnBoard then
        turn = Board:GetTurn()
        if turn == GAME.HW_PodTimer and not GAME.HW_DeadWarrior and GAME.HW_TimePodExists then
			Wolf_OnTimeBreachWarningStart()
        end
    end
	if Game:GetTeamTurn() == TEAM_PLAYER then
		-- Increase the mission timer by 1
		if GAME.HW_TimePodExists and turn == 1 then
			if logging then LOG("HIVE WARRIOR INBOUND! Increasing the Turn limit by 1!") end
			mission.TurnLimit = mission.TurnLimit + 1
		end
		-- Heal all status effects at the beginning of the player's turn
		if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior and GAME.HW_WarriorLoc ~= nil then
			if EvoCheck("D") then
				local damage = SpaceDamage(GAME.HW_WarriorLoc, 0)
				damage.bHide = true
				damage.iFire = EFFECT_REMOVE
				if Board:IsPawnSpace(GAME.HW_WarriorLoc) then
					damage.iAcid = EFFECT_REMOVE
				end
				damage.iFrozen = EFFECT_REMOVE
				Board:DamageSpace(damage)
				Board:AddAlert(GAME.HW_WarriorLoc, "Adaptation!")
			end
		end
		
		for i = 0,2 do
			local mech = Board:GetPawn(i)
			if Wolf_HasPoweredWeapon(mech, "Passive_Adaptation", true) then
				for i = 0,2 do
					local mech2 = Board:GetPawn(i)
					local damage = SpaceDamage(mech2:GetSpace(), 0)
					damage.bHide = true
					damage.iFire = EFFECT_REMOVE
					damage.iAcid = EFFECT_REMOVE
					damage.iFrozen = EFFECT_REMOVE
					damage.iSmoke = EFFECT_REMOVE
					Board:DamageSpace(damage)
					Board:AddAlert(mech2:GetSpace(), "Adaptation!")
				end
			elseif Wolf_HasPoweredWeapon(mech, "Passive_Adaptation", false) then
				local damage = SpaceDamage(mech:GetSpace(), 0)
				damage.bHide = true
				damage.iFire = EFFECT_REMOVE
				damage.iAcid = EFFECT_REMOVE
				damage.iFrozen = EFFECT_REMOVE
				damage.iSmoke = EFFECT_REMOVE
				Board:DamageSpace(damage)
				Board:AddAlert(mech:GetSpace(), "Adaptation!")
			end
		end
	end
	--[[
	if logging then LOG("Checking for snap validity!") end
	if Game:GetTeamTurn() == TEAM_ENEMY and EvoCheck("BCSnap") then
		if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior and GAME.HW_WarriorLoc ~= nil and EvoCheck("BCSnap") then
			local hw = Board:GetPawn(GAME.HW_WarriorLoc)
			local id = hw:GetId()
			local range = GAME.HW_BioRange
			if logging then LOG("Beginning snap targeting!") end
			for dir = DIR_START, DIR_END do
				local target = GAME.HW_WarriorLoc
				for i = 1, range do
					target = target + DIR_VECTORS[dir]
					local pawn = Board:GetPawn(target)
					if pawn ~= nil and GAME.Overwatch[id] ~= nil then
						if pawn:IsMech() and GAME.Overwatch[id].remainingShots > 0 then
							hw:FireWeapon(target, GAME.Overwatch[id].weaponSlot)
							GAME.Overwatch[id].remainingShots = GAME.Overwatch[id].remainingShots - 1
						end
					end
				end
			end
			for dir = DIR_START, DIR_END do
				local target = GAME.HW_WarriorLoc
				for i = 1, range do
					target = target + DIR_VECTORS[dir]
					if GAME.Overwatch[id] ~= nil then
						if Board:IsBuilding(target) and GAME.Overwatch[id].remainingShots > 0 then
							if logging then LOG("Targeting: "..target.x..","..target.y) end
							hw:FireWeapon(target, GAME.Overwatch[id].weaponSlot)
							GAME.Overwatch[id].remainingShots = GAME.Overwatch[id].remainingShots - 1
						end
					end
				end
			end
		end
	end
	--]]
end

local function missionUpdateHook(self)
	for x = 0, 7 do
		for y = 0, 7 do
			if Board:IsPawnSpace(Point(x,y)) then
				local pawn = Board:GetPawn(Point(x,y))
				if pawn ~= nil then
					if _G[pawn:GetType()].Name == "Hive Warrior" then
						GAME.HW_WarriorLoc = pawn:GetSpace()
						if EvoCheck("D") then
							SetAdaptive(GAME.HW_WarriorLoc, true)
						end
					end
					if Wolf_HasPoweredWeapon(pawn, "Passive_Adaptation", false) then
						SetAdaptive(Point(x,y), true)
					end
					if Wolf_HasPoweredWeapon(pawn, "Passive_Adaptation", true) then
						for i = 0,2 do
							local mech = Board:GetPawn(i)
							SetAdaptive(mech:GetSpace(), true)
						end
					end
				end
			end
		end
	end
end

local function missionStartHook(mission)
	-- reset the variables
	GAME.HW_WarriorOnBoard = false
	GAME.HW_DeadWarrior = false
	GAME.HW_TimePodExists = false
	GAME.HW_PodTile = nil
	GAME.HW_WarriorLoc = nil
	GAME.HW_PodHolder = nil
	GAME.HW_ObjStatus = nil
	GAME.HW_Overwatched = false
	GAME.HW_Dodged = false
	
	if logging then LOG("ALL HW VARS RESET") end
	
	UpdateWarriorSprite()
end

local function islandChangeHook(island)
	if GAME.HW_PowerUps ~= nil then
		if GAME.HW_PowerUps > 0 then
			GridImprovement(GAME.HW_PowerUps)
		end
		-- ResetTurn button has to be shifted to the right a bit so it doesn't overlap with the increased grid power bar
		Location["undo_turn"] = Location["undo_turn"] + Point((15 * GAME.HW_PowerUps), 0)
	end
	GAME.HW_PowerUps = 0
	if island > 1 then
		local SelectedEvo = math.random(1, #GAME.HW_Evolist/2)
		if math.random(1, 2) == 1 then
			if logging then LOG("Adding evolution: "..GAME.HW_Evolist[SelectedEvo*2]) end
			table.insert(GAME.HW_Evolutions, GAME.HW_Evolist[SelectedEvo*2])
			table.remove(GAME.HW_Evolist, SelectedEvo*2)
			table.remove(GAME.HW_Evolist, (SelectedEvo*2)-1)
		else
			if logging then LOG("Adding evolution: "..GAME.HW_Evolist[(SelectedEvo*2)-1]) end
			table.insert(GAME.HW_Evolutions, GAME.HW_Evolist[(SelectedEvo*2)-1])
			table.remove(GAME.HW_Evolist, SelectedEvo*2)
			table.remove(GAME.HW_Evolist, (SelectedEvo*2)-1)
		end
		
		UpdateWarriorSprite()
	end
	GAME.HW_Encounter = nil
end

local function preMissionAvailableHook(mission)
	for index, boss in ipairs(Mission_Final_Cave.BossList) do
		table.remove(Mission_Final_Cave.BossList, index)
	end
	table.insert(Mission_Final_Cave.BossList, "HiveWarriorFinal")
	
	-- reset the variables
	GAME.HW_WarriorOnBoard = false
	GAME.HW_DeadWarrior = false
	GAME.HW_TimePodExists = false
	GAME.HW_PodTile = nil
	GAME.HW_WarriorLoc = nil
	GAME.HW_PodHolder = nil
	GAME.HW_ObjStatus = nil
	if logging then LOG("ALL HW VARS RESET") end
	
	-- check for warrior upgrades
	local island = GetSector()
	
	if island == 1 then
		GAME.HW_Move = GAME.HW_WarriorStats.Sector1.Move
		GAME.HW_Health = GAME.HW_WarriorStats.Sector1.Health
		GAME.HW_ReaveDmg = GAME.HW_WarriorStats.Sector1.ReaveDmg
		GAME.HW_BioDmg = GAME.HW_WarriorStats.Sector1.BioDmg
		GAME.HW_BioRange = GAME.HW_WarriorStats.Sector1.BioRange
	elseif island == 2 then
		GAME.HW_Move = GAME.HW_WarriorStats.Sector2.Move
		GAME.HW_Health = GAME.HW_WarriorStats.Sector2.Health
		GAME.HW_ReaveDmg = GAME.HW_WarriorStats.Sector2.ReaveDmg
		GAME.HW_BioDmg = GAME.HW_WarriorStats.Sector2.BioDmg
		GAME.HW_BioRange = GAME.HW_WarriorStats.Sector2.BioRange
	elseif island == 3 then
		GAME.HW_Move = GAME.HW_WarriorStats.Sector3.Move
		GAME.HW_Health = GAME.HW_WarriorStats.Sector3.Health
		GAME.HW_ReaveDmg = GAME.HW_WarriorStats.Sector3.ReaveDmg
		GAME.HW_BioDmg = GAME.HW_WarriorStats.Sector3.BioDmg
		GAME.HW_BioRange = GAME.HW_WarriorStats.Sector3.BioRange
	elseif island == 4 then
		GAME.HW_Move = GAME.HW_WarriorStats.Sector4.Move
		GAME.HW_Health = GAME.HW_WarriorStats.Sector4.Health
		GAME.HW_ReaveDmg = GAME.HW_WarriorStats.Sector4.ReaveDmg
		GAME.HW_BioDmg = GAME.HW_WarriorStats.Sector4.BioDmg
		GAME.HW_BioRange = GAME.HW_WarriorStats.Sector4.BioRange
	else
		if logging then LOG("COULD NOT GET ISLAND NUMBER!") end
	end
	if EvoCheck("M") then
		GAME.HW_BioAmmo = 2
	end
	
	-- check for island change
	if island ~= GAME.HW_OldIsland then
		islandChangeHook(island)
	end
	GAME.HW_OldIsland = GetSector()
end

local function missionEndHook(mission)
	if GAME.HW_WarriorOnBoard == true and GAME.HW_DeadWarrior == false then
		HW_Intimidate("Wolf_HW_Draw", true, 2)
		GAME.HW_Encounters[#GAME.HW_Encounters+1] = "draw"
	end
end

local function podDetectedHook()
	-- If island 3 or 4
	if GetSector() == 3 or GetSector() == 4 then
		-- If you haven't rolled this island, roll for encounter
		if GAME.HW_Encounter == nil then--[[
			local roll = math.random(1, 2)
			if logging then LOG("Encounter Roll: "..roll) end
			if roll == 1 then
				GAME.HW_Encounter = true--]]
				GAME.HW_TimePodExists = true--[[
			end
			if roll == 2 then
				GAME.HW_Encounter = false
				GAME.HW_TimePodExists = false
			end--]]
		-- If you have already rolled, do the opposite of last time
		else
			if GAME.HW_Encounter then
				GAME.HW_TimePodExists = false
			else
				GAME.HW_TimePodExists = true
			end
		end
	else
		GAME.HW_TimePodExists = true
	end
	
	if GAME.HW_TimePodExists then
		local turn = Board:GetTurn()
		if turn == 0 then
			GAME.HW_PodTimer = turn + 2
		else
			GAME.HW_PodTimer = turn + 1
		end
		if logging then LOG("Time till breach: "..GAME.HW_PodTimer) end
	end
end

local function podLandedHook(point)
	if logging then LOG("Pod Landed!") end
	GAME.HW_PodTile = point
end

local function podDestroyedHook(pawn)
	if logging then LOG("Pod Destroyed!") end
	GAME.HW_TimePodExists = false
	if GAME.HW_WarriorLoc ~= nil then
		HW_Intimidate("Wolf_HW_Escape", false, 0)
		local pawn = Board:GetPawn(GAME.HW_WarriorLoc)
		pawn:Retreat()
		GAME.HW_WarriorOnBoard = false
		GAME.HW_DeadWarrior = true
		--Game:AddTutorial("Tut_RetreatLoss", GAME.HW_WarriorLoc)
		SetAdaptive(GAME.HW_WarriorLoc, false)
		--if GAME.HW_ObjStatus ~= nil and GetSector() == 4 then
			GAME.HW_ObjStatus = OBJ_FAILED
		--end
		GAME.HW_Encounters[#GAME.HW_Encounters+1] = "loss"
	else
		if GetSector() == 3 or GetSector() == 4 then
			-- guarantee a breach on the next pod this island
			if GAME.HW_Encounter == nil then
				GAME.HW_Encounter = false
				return
			end
			
			-- there will not be another encounter this island so mark it as a loss
			if GAME.HW_Encounter == false then
				GAME.HW_Encounters[#GAME.HW_Encounters+1] = "loss"
			end
		else
			GAME.HW_Encounters[#GAME.HW_Encounters+1] = "loss"
		end
	end
end

local function podTrampledHook(pawn)
	podDestroyedHook(pawn)
end

local function podCollectedHook(pawn)
	if logging then LOG("Pod Collected!") end
	GAME.HW_PodHolder = pawn:GetId()
	--Game:AddTutorial("Tut_Bearer", GAME.HW_PodTile)
	--if GAME.HW_WarriorOnBoard == true and GAME.HW_DeadWarrior == false then
	--	GAME.HW_ObjStatus = OBJ_STANDARD
	--end
end

local function postStartGameHook()
	GAME.HW_MaxPower = 0
	GAME.HW_PowerUps = 0
	GAME.HW_OldIsland = 5
	GAME.HW_Evolist = {
		--[[
		"BCAcid",
		"BCAmmo",
		"RVFire",
		"RVWeb",
		"HWArmor",
		"HWAdapt",
		"HWVines",
		"HWAggro"
		--]]
		"A",
		"D",
		"C",
		"M",
		"F",
		"W"
		--"V",
		--"R"
	}
	GAME.HW_Evolutions = {}
	GAME.HW_BioAmmo = 1
	-- Initialize the HW's stats
	GAME.HW_WarriorStats = copy_table(MasterStatsHW)
	GAME.HW_Encounters = {}
end

local function missionNextPhaseCreatedHook(prevMission, nextMission)
	if GameData.network >= 10 then
		HiveWar_achvApi:TriggerChievo("HW_TenPower", true)
	end
end

function GridImprovement(ExtraPower)
	if GetSector() == 4 and GAME.HW_MaxPower > 0 then
		sdlext.showTextDialog("Power Grid Improvement Halted","Unfortunately, strategists have determined that there is not enough time before the Final Assault to improve the Grid any further. Instead, any extra biological components will be salvaged directly into electricity for the Grid.")
	end
	if ExtraPower ~= nil then
		if ExtraPower > 0 then
			sdlext.showTextDialog("Power Grid Improved","By studying the defeated Hive Warrior's organic technology, our allies have managed to improve the Grid's maximum capacity by "..ExtraPower.." units.")
		end
	end
end

function HW_Intimidate(dialogue, proxy, target)
	if logging then LOG("INTIMIDATE CALLED!") end
	
	local roll = nil
	if target == 0 then roll = math.random(0,4) end -- anyone
	if target == 1 then roll = math.random(0,2) end -- squad
	if target == 2 then roll = 5 end -- hive warrior
	
	if logging then LOG("CAST ROLL: "..roll) end
	
	if roll < 3 then
		if Board:GetPawn(roll):GetPersonality() == "Artificial" then
			if logging then LOG("Pilot is AI! Not happening!") end
			if target ~= 1 then roll = 5 end
		end
	end
	
	if roll > 2 then
		if proxy then
			if logging then LOG("PROXYING INTIMIDATE!") end
			local damage = SpaceDamage(GAME.HW_WarriorLoc, 0)
			damage.sPawn = "HiveWarriorProxy"
			damage.bHide = true
			Board:DamageSpace(damage)
		end
		
		local pawn = Board:GetPawn(GAME.HW_WarriorLoc)
		local cast = { }
		cast.main = pawn:GetId()
		HiveWar_modApiExt.dialog:triggerRuledDialog(dialogue, cast)
		
		if proxy then
			local damage = SpaceDamage(GAME.HW_WarriorLoc, DAMAGE_DEATH)
			damage.bHide = true
			Board:DamageSpace(damage)
		end
	else
		local cast = { }
		cast.main = roll
		HiveWar_modApiExt.dialog:triggerRuledDialog(dialogue, cast)
	end
end

return {
	onLoad = onLoad,
	newTurnHook = newTurnHook,
	missionStartHook = missionStartHook,
	missionUpdateHook = missionUpdateHook,
	BreachWarrior = BreachWarrior,
	pawnPositionChangedHook = pawnPositionChangedHook,
	skillStartHook = skillStartHook,
	skillEndHook = skillEndHook,
	queuedSkillEndHook = queuedSkillEndHook,
	preMissionAvailableHook = preMissionAvailableHook,
	missionEndHook = missionEndHook,
	pawnKilledHook = pawnKilledHook,
	podDetectedHook = podDetectedHook,
	podLandedHook = podLandedHook,
	podTrampledHook = podTrampledHook,
	podDestroyedHook = podDestroyedHook,
	podCollectedHook = podCollectedHook,
	postStartGameHook = postStartGameHook,
	missionNextPhaseCreatedHook = missionNextPhaseCreatedHook,
}