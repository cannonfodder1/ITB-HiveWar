-- Where all the magic happens

local function onLoad()
end

local function BreachWarrior(pod)
	-- scan spaces adjacent to pod for valid placement
	-- spawn the Hive Warrior pawn
	
    dirs = { DIR_RIGHT, DIR_UP, DIR_DOWN, DIR_LEFT }
	list = {1, 2, 3, 4, 5, 6, 7, 8}
	
	for i, v in ipairs(list) do
		for index, dir in ipairs(dirs) do
			if pod == nil then break end
			tick = v
			target = pod
			while tick > 0 do
				target = target + DIR_VECTORS[dir]
				tick = tick - 1
			end
			if not Board:IsBlocked(target, PATH_GROUND)
			and not Board:IsSpawning(target)
			and not Board:IsFire(target)
			and not Board:IsAcid(target)
			and not Board:IsSmoke(target)
			and not Board:IsDangerous(target)
			and not Board:IsEnvironmentDanger(target)
			and not Board:IsDangerousItem(target)
			and Board:GetTerrain(target) ~= TERRAIN_LAVA
			and Board:IsValid(target) then
            
				WarnPlayer()
			
				local damage = SpaceDamage(target, 0)
					damage.sPawn = "HiveWarrior"
				Board:DamageSpace(damage)
				GAME.HW_WarriorLoc = target
				Game:AddTutorial("Tut_Breach", GAME.HW_WarriorLoc)
				return
			end
		end
	end
	-- If we still can't find any space, try with less parameters
		for i, v in ipairs(list) do
		for index, dir in ipairs(dirs) do
			if pod == nil then break end
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
            
				WarnPlayer()
			
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

-- Do you believe you can walk on water?
local function pawnPositionChangedHook(mission, pawn, oldPosition)
	if _G[pawn:GetType()].Name == "Hive Warrior" then
		pos = pawn:GetSpace()
		if Board:GetTerrain(pos) == TERRAIN_WATER then
			Board:SetTerrain(pos, TERRAIN_ICE)
			Game:AddTutorial("Tut_Water", pos)
		end
		if Board:GetTerrain(oldPosition) == TERRAIN_WATER then
			Board:SetTerrain(oldPosition, TERRAIN_ICE)
		end
	end
end

local function skillEndHook(mission, pawn, weaponId, p1, p2)
	local IcedHW = Board:GetPawn(p2)
	if IcedHW ~= nil then
		if IcedHW:IsFrozen() and _G[IcedHW:GetType()].Name == "Hive Warrior" then
			Game:AddTutorial("Tut_Freeze", p2)
		end
	end
end

local function queuedSkillEndHook(mission, pawn, weaponId, p1, p2)
end

local function pawnKilledHook(mission, pawn)
	if _G[pawn:GetType()].Name == "Hive Warrior" then
		GAME.HW_ObjStatus = OBJ_COMPLETE
		Game:AddTutorial("Tut_RetreatWin", GAME.HW_WarriorLoc)
	end
end

local function newTurnHook(mission)
	local turn = Board:GetTurn()
	local roll = 0
	-- Setup the Hive Warrior spawning
	if Game:GetTeamTurn() == TEAM_ENEMY and not GAME.HW_WarriorOnBoard then
		turn = Board:GetTurn()
		if turn <= 1 then
			roll = 0
		elseif turn >= 2 then
			roll = 1
		end
		LOG("Turn: "..turn)
		LOG("Roll: "..roll)
		if roll > 0 and not GAME.HW_DeadWarrior then
			BreachWarrior(GAME.HW_PodTile)
			GAME.HW_WarriorOnBoard = true
			if GAME.HW_PodHolder ~= nil then
				GAME.HW_ObjStatus = OBJ_STANDARD
			end
		end
	end
	if Game:GetTeamTurn() == TEAM_PLAYER then
		-- Increase the mission timer by 1
		if GAME.HW_TimePodExists and turn == 1 then
			LOG("HIVE WARRIOR INBOUND! Increasing the Turn limit by 1!")
			mission.TurnLimit = mission.TurnLimit + 1
		end
		-- Break the warrior out of ice at the beginning of the player's turn
		if GAME.HW_WarriorOnBoard and not GAME.HW_DeadWarrior and GAME.HW_WarriorLoc ~= nil then
			local damage = SpaceDamage(GAME.HW_WarriorLoc, 1)
			damage.bHide = true
			local IcedHW = Board:GetPawn(GAME.HW_WarriorLoc)
			if IcedHW ~= nil then
				if IcedHW:IsFrozen() then
					Board:DamageSpace(damage)
				end
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
				end
			end
		end
	end
	for att_id, _ in pairs(GAME.Overwatch) do
		if GAME.Overwatch[att_id].remainingShots == 0 then
			local attacker = Board:GetPawn(att_id)
			if _G[attacker:GetType()].Name == "Hive Warrior" and GAME.HW_WarriorLoc ~= nil then
				Game:AddTutorial("Tut_Reflex", GAME.HW_WarriorLoc)
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
end

local function missionEndHook(mission)
end

function WarnPlayer()
	local screen = sdl.screen()
	local img = sdlext.surface("img/effects/timebreach.png")
	local screenshot = sdl.screenshot()
	local timer = sdl.timer()
	local eventloop = sdl.eventloop()
	local quit = 0
	
	while quit == 0 do
		while eventloop:next() do
			local type = eventloop:type();
			
			if type == sdl.events.quit then
                quit = 1
            elseif type == sdl.events.keydown and eventloop:keycode() == 27 then -- escape key
                quit = 1
            elseif timer:elapsed() > 1000 then
                quit = 1
            end
		end
	screen:begin()
	screen:blit(screenshot, nil, 0, 0)
	screen:blit(img, nil, 10, 460)
	screen:finish()
	end
end

local function podDetectedHook()
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
		GAME.HW_WarriorOnBoard = false
		GAME.HW_DeadWarrior = true
		Game:AddTutorial("Tut_RetreatLoss", GAME.HW_WarriorLoc)
		if GAME.HW_ObjStatus ~= nil then
			GAME.HW_ObjStatus = OBJ_FAILED
		end
	end
end

local function podTrampledHook(pawn)
	podDestroyedHook(pawn)
end

local function podCollectedHook(pawn)
	LOG("Pod Collected!")
	GAME.HW_PodHolder = pawn:GetId()
	Game:AddTutorial("Tut_Bearer", GAME.HW_PodTile)
	if GAME.HW_WarriorOnBoard == true then
		GAME.HW_ObjStatus = OBJ_STANDARD
	end
end

local function postStartGameHook()

end

return {
	onLoad = onLoad,
	newTurnHook = newTurnHook,
	missionStartHook = missionStartHook,
	missionUpdateHook = missionUpdateHook,
	BreachWarrior = BreachWarrior,
	WarnPlayer = WarnPlayer,
	pawnPositionChangedHook = pawnPositionChangedHook,
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