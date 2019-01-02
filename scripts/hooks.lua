-- Where all the magic happens

local Wolf_MineTiles = {}

local function onLoad()
	if Game then
		GAME.HW_WarriorStats = {
			Sector1 = {
				Move = 3,
				Health = 5,
				ReaveDmg = 2,
				BioDmg = 1,
				BioRange = 1,
			},
			Sector2 = {
				Move = 4,
				Health = 6,
				ReaveDmg = 2,
				BioDmg = 2,
				BioRange = 2,
			},
			Sector3 = {
				Move = 4,
				Health = 7,
				ReaveDmg = 3,
				BioDmg = 2,
				BioRange = 3,
			},
			Sector4 = {
				Move = 5,
				Health = 8,
				ReaveDmg = 3,
				BioDmg = 2,
				BioRange = 3,
			},
		}
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

--999 so the icon doesn't appear on the board, but only in his summary. Use (-3,24) to make it show up
Location["combat/icons/icon_adapt_glow.png"] = Point(999,999)

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
	
    dirs = { DIR_RIGHT, DIR_UP, DIR_DOWN, DIR_LEFT }
	list = {1, 2, 3, 4, 5, 6, 7, 8}
	
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
				
				local island = GetSector()
				local damage = SpaceDamage(target, 0)
				damage.sPawn = "HiveWarrior"
				Board:DamageSpace(damage)
				GAME.HW_WarriorLoc = target
				--HW_InfoPanel()
				Game:AddTutorial("Tut_Breach", GAME.HW_WarriorLoc)
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
				Game:AddTutorial("Tut_Breach", GAME.HW_WarriorLoc)
				return
			end
		end
	end
	LOG("HIVE WARRIOR SPAWNING FAILED! NO VALID TILES!")
end

local function TrackMines()
	if GAME.HW_WarriorLoc then
		GAME.HW_Restore = Board:GetPawn(GAME.HW_WarriorLoc):GetHealth()
	end
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
	--LOG("Index = "..index)
	local ret = SkillEffect()
	ret:AddDelay(0.5)
	for i = 1, index do
		--LOG(Wolf_MineTiles[i].x..","..Wolf_MineTiles[i].y)
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
    BreachWarrior(GAME.HW_PodTile)
    --if GetSector() == 4 then
        GAME.HW_ObjStatus = OBJ_STANDARD
    --end
	
	TrackMines()
	SmiteMines()
	
	HW_Intimidate("HW_Spawn", 100)
end

local function Wolf_OnTimeBreachWarningStart()
    Wolf_HWBreach:create()

    -- pretty effects to make it more noticeable
    Game:TriggerSound("/ui/map/region_lost")
    Board:StartShake(Wolf_BreachWarnTimeInSeconds)
    
    -- Delay vek burrowing out
    local fx = SkillEffect()
    fx:AddDelay(Wolf_BreachWarnTimeInSeconds + 1)
    Board:AddEffect(fx)
end

-- Do you believe you can walk on water?
local function pawnPositionChangedHook(mission, pawn, oldPosition)
	if _G[pawn:GetType()].Name == "Hive Warrior" then
		pos = pawn:GetSpace()
		
		if Board:GetTerrain(oldPosition) == TERRAIN_WATER then
			Board:SetTerrain(oldPosition, TERRAIN_ICE)
			Game:AddTutorial("Tut_Water", pos)
		end
		
		SetAdaptive(oldPosition, false)
	end
end

local function skillStartHook(mission, pawn, weaponId, p1, p2)
	TrackMines()
end
		
local function skillEndHook(mission, pawn, weaponId, p1, p2)
	TrackMines()
end

local function queuedSkillEndHook(mission, pawn, weaponId, p1, p2)
end

local function pawnKilledHook(mission, pawn)
	if _G[pawn:GetType()].Name == "Hive Warrior" and GAME.HW_DeadWarrior == false then
		GAME.HW_WarriorLoc = pawn:GetSpace()
		
		HW_Intimidate("HW_Failure", 100)
		--if GetSector() == 4 then
			GAME.HW_ObjStatus = OBJ_COMPLETE
		--end
		Game:AddTutorial("Tut_RetreatWin", GAME.HW_WarriorLoc)
		LOG("Warrior Killed")
		SetAdaptive(GAME.HW_WarriorLoc, false)
		GAME.HW_DeadWarrior = true
		GAME.HW_MaxPower = GAME.HW_MaxPower + 1
		GAME.HW_PowerUps = GAME.HW_PowerUps + 1
	end
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
			LOG("HIVE WARRIOR INBOUND! Increasing the Turn limit by 1!")
			mission.TurnLimit = mission.TurnLimit + 1
		end
		-- Heal all status effects at the beginning of the player's turn
		if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior and GAME.HW_WarriorLoc ~= nil then
			if EvoCheck("HWAdapt") then
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
	end
end

local function missionUpdateHook(self)
	for x = 0, 7 do
		for y = 0, 7 do
			if Board:IsPawnSpace(Point(x,y)) then
				pawn = Board:GetPawn(Point(x,y))
				if _G[pawn:GetType()].Name == "Hive Warrior" then
					GAME.HW_WarriorLoc = pawn:GetSpace()
					if EvoCheck("HWAdapt") then
						SetAdaptive(GAME.HW_WarriorLoc, true)
					end
				end
			end
			if Board:IsPod(Point(x,y)) then
				GAME.HW_TimePodExists = true
				GAME.HW_PodTile = Point(x,y)
			end
		end
	end
	if GAME.Overwatch ~= nil then
		for att_id, _ in pairs(GAME.Overwatch) do
			if GAME.Overwatch[att_id].remainingShots == 0 then
				local attacker = Board:GetPawn(att_id)
				if _G[attacker:GetType()].Name == "Hive Warrior" and GAME.HW_WarriorLoc ~= nil then
					Game:AddTutorial("Tut_Reflex", GAME.HW_WarriorLoc)
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
end

local function preMissionAvailableHook(mission)
	-- reset the variables
	GAME.HW_WarriorOnBoard = false
	GAME.HW_DeadWarrior = false
	GAME.HW_TimePodExists = false
	GAME.HW_PodTile = nil
	GAME.HW_WarriorLoc = nil
	GAME.HW_PodHolder = nil
	GAME.HW_ObjStatus = nil
	-- check for warrior upgrades
	local island = GetSector()
	if island == nil or island == 0 then
		LOG("ERROR! COULD NOT GET ISLAND NUMBER!")
	elseif island == 1 then
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
		LOG("ERROR! COULD NOT GET ISLAND NUMBER! REPORT THIS TO MOD AUTHOR!")
	end
	if EvoCheck("BCAmmo") then
		GAME.HW_BioAmmo = 2
	end
	-- check for island change
	if island ~= GAME.HW_OldIsland then
		GridImprovement(GAME.HW_PowerUps)
		Location["undo_turn"] = Location["undo_turn"] + Point((15 * GAME.HW_PowerUps), 0)
		GAME.HW_PowerUps = 0
		if island > 1 then
			local TempList = GAME.HW_Evolist
			local SelectedEvo = math.random(1, #TempList)
			table.insert(GAME.HW_Evolutions, GAME.HW_Evolist[SelectedEvo])
			table.remove(GAME.HW_Evolist, SelectedEvo)
		end
	end
	GAME.HW_OldIsland = GetSector()
end

local function missionEndHook(mission)
	if GAME.HW_WarriorOnBoard == true
		HW_Intimidate("HW_Draw", 100)
	end
end

local function podDetectedHook()
	GAME.HW_TimePodExists = true
	local turn = Board:GetTurn()
	if turn == 0 then
		GAME.HW_PodTimer = turn + 2
	else
		GAME.HW_PodTimer = turn + 1
	end
end

local function podLandedHook(point)
	GAME.HW_PodTile = point
	GAME.HW_TimePodExists = true
end

local function podDestroyedHook(pawn)
	LOG("Pod Destroyed!")
	if GAME.HW_WarriorLoc ~= nil then
		local pawn = Board:GetPawn(GAME.HW_WarriorLoc)
		pawn:Retreat()
		HW_Intimidate("HW_Victory", 100)
		GAME.HW_WarriorOnBoard = false
		GAME.HW_DeadWarrior = true
		Game:AddTutorial("Tut_RetreatLoss", GAME.HW_WarriorLoc)
		SetAdaptive(GAME.HW_WarriorLoc, false)
		--if GAME.HW_ObjStatus ~= nil and GetSector() == 4 then
			GAME.HW_ObjStatus = OBJ_FAILED
		--end
	end
end

local function podTrampledHook(pawn)
	podDestroyedHook(pawn)
end

local function podCollectedHook(pawn)
	LOG("Pod Collected!")
	GAME.HW_PodHolder = pawn:GetId()
	Game:AddTutorial("Tut_Bearer", GAME.HW_PodTile)
	--if GAME.HW_WarriorOnBoard == true and GAME.HW_DeadWarrior == false then
	--	GAME.HW_ObjStatus = OBJ_STANDARD
	--end
end

local function postStartGameHook()
	GAME.HW_MaxPower = 0
	GAME.HW_PowerUps = 0
	GAME.HW_OldIsland = 5
	GAME.HW_Evolist = {
		"BCAcid",
		"BCAmmo",
		"RVFire",
		"RVWeb",
		"HWArmor",
		"HWAdapt",
	}
	GAME.HW_Evolutions = {}
	GAME.HW_BioAmmo = 1
	GAME.HW_Restore = 0
	-- Initialize the HW's stats
	GAME.HW_WarriorStats = {
		Sector1 = {
			Move = 3,
			Health = 5,
			ReaveDmg = 2,
			BioDmg = 1,
			BioRange = 1,
		},
		Sector2 = {
			Move = 4,
			Health = 6,
			ReaveDmg = 2,
			BioDmg = 2,
			BioRange = 2,
		},
		Sector3 = {
			Move = 4,
			Health = 7,
			ReaveDmg = 3,
			BioDmg = 2,
			BioRange = 3,
		},
		Sector4 = {
			Move = 5,
			Health = 8,
			ReaveDmg = 3,
			BioDmg = 2,
			BioRange = 3,
		},
	}
end

function GridImprovement(ExtraPower)
	if GetSector() == 4 and GAME.HW_MaxPower > 0 then
		sdlext.showTextDialog("Power Grid Improvement Halted","Unfortunately, strategists have determined that there is not enough time before the Final Assault to improve the Grid any further. Instead, any extra supplies of the Hive Warrior's electroblood will be converted directly into electricity for the Grid.")
	end
	if ExtraPower > 0 then
		sdlext.showTextDialog("Power Grid Improved","By studying the defeated Hive Warrior's electroblood, our allies have managed to improve the Grid's maximum capacity by "..ExtraPower.." units.")
	end
end

function HW_Intimidate(dialogue, chance)
	roll = math.random(0, 99)
	if roll < chance then
		local voice = SkillEffect()
		local pawn = Board:GetPawn(GAME.HW_WarriorLoc)
		voice:AddVoice(dialogue, pawn:GetId())
		Board:AddEffect(voice)
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
}