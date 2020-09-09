--======================================================
--		DON'T YOU DARE MESS ANYTHING UP IN HERE
--	   LEARN LUA SCRIPTING BEFORE SCREWING AROUND
--======================================================

Location["combat/tile_icon/reflexmark.png"] = Point(-27,2)
TILE_TOOLTIPS["reflex_mark"] = { "Reflexive Fire", "Mechs that get pushed or move into this tile will be attacked!" }

local logging = false

local update = true --If this is true, we will update overwatch tiles next frame, and set it to false again.
local moveDone = true
local undoMove = false
local reflexReady = false
local targetMech = nil
local tileState = nil
local pawnState = nil

local function onLoad(tile, pawn)
	update = true
	moveDone = true
	undoMove = false
	reflexReady = false
	targetMech = nil
	tileState = tile
	pawnState = pawn
end

--The system stores variables in GAME.HW_Overwatch and GAME.HW_OverwatchUndo. No other script should overwrite those variables.
local function missionStartHook()
	GAME.HW_Overwatch = {}
	GAME.HW_OverwatchUndo = {}
end

--Refresh a pawn's remaining shots
local function pawnRefreshOverwatch(pawn)
	update = true
	local id = pawn:GetId()
	local pawnDefaults = _G[pawn:GetType()].ReflexConfig
	GAME.HW_Overwatch[id].markedTiles = {}
	GAME.HW_Overwatch[id].remainingShots = pawnDefaults.ShotsTotal or INT_MAX
	if _G[pawn:GetType()].Name == "Hive Warrior" then
		GAME.HW_Overwatch[id].remainingShots = GAME.HW_BioAmmo or 1
	end
	GAME.HW_Overwatch[id].shotPawnIds = {}
end

local function newTurnHook(self)
	GAME.HW_OverwatchUndo = {}
	GAME.HW_Overwatch = GAME.HW_Overwatch or {}
	for id, _ in pairs(GAME.HW_Overwatch) do
		pawnRefreshOverwatch(Board:GetPawn(id))
	end
end

--Set overwatch values for a pawn to it's default values defined in Pawn.
local function pawnTrackedHook(mission, pawn)
	update = true
	if logging then LOG("(".. pawn:GetId() ..") ".. _G[pawn:GetType()].Name .." just appeared on tile (".. pawn:GetSpace().x ..", ".. pawn:GetSpace().y ..")") end
	
	if _G[pawn:GetType()].ReflexConfig ~= nil then
		local id = pawn:GetId()
		local pawnDefaults = _G[pawn:GetType()].ReflexConfig
		GAME.HW_Overwatch[id] = {}
		GAME.HW_Overwatch[id].range = pawnDefaults.Range or INT_MAX
		if _G[pawn:GetType()].Name == "Hive Warrior" then
			GAME.HW_Overwatch[id].range = GAME.HW_BioRange or 3
		end
		GAME.HW_Overwatch[id].shotsPerPawn = pawnDefaults.ShotsPerPawn or INT_MAX
		GAME.HW_Overwatch[id].weaponSlot = pawnDefaults.WeaponSlot or 1
		pawnRefreshOverwatch(pawn)
	end
end

local function pawnUntrackedHook(mission, pawn)
	update = true
	if logging then LOG("(".. pawn:GetId() ..") ".. _G[pawn:GetType()].Name .." just disappeared from tile (".. pawn:GetSpace().x ..", ".. pawn:GetSpace().y ..")") end
	GAME.HW_Overwatch[pawn:GetId()] = nil
end

local function pawnMoveStartHook(mission, defender)
	moveDone = false
end

local function pawnMoveEndHook(mission, defender)
	moveDone = true
	if logging then LOG("(".. defender:GetId() ..") ".. _G[defender:GetType()].Name .." ended it's move in (".. defender:GetSpace().x ..", ".. defender:GetSpace().y ..")") end
	update = true
end

local function pawnUndoMoveHook(mission, defender, oldPosition)
	local def_id = defender:GetId()
	local att_id = GAME.HW_OverwatchUndo[def_id]
	undoMove = true
	--Give back ammunition if this pawn was shot by an overwatch shot during it's movement.
	if att_id ~= nil then
		local attacker = Board:GetPawn(att_id)
		if attacker ~= nil then
			local defaults = _G[attacker:GetType()].ReflexConfig
			GAME.HW_Overwatch[att_id].remainingShots = math.min(GAME.HW_Overwatch[att_id].remainingShots + 1, defaults.ShotsTotal)
			GAME.HW_Overwatch[att_id].shotPawnIds[def_id] = GAME.HW_Overwatch[att_id].shotPawnIds[def_id] - 1
			if logging then LOG("(".. def_id ..") ".. _G[Board:GetPawn(def_id):GetType()].Name .." undid movement, and gave back ammo to ".. _G[Board:GetPawn(att_id):GetType()].Name) end
		end
		
		if oldPosition ~= GAME.HW_PodTile then tileState:Restore(oldPosition) end
		if logging then LOG("Pilot: "..defender:GetPersonality()) end
		if defender:GetPersonality() == "Original" or Wolf_HasPoweredWeapon(defender, "Passive_ServoEvade", false) then
			local dir = GetDirection(oldPosition - attacker:GetSpace())
			local tile = GetProjectileEnd(oldPosition, oldPosition + DIR_VECTORS[dir])
			if tile ~= GAME.HW_PodTile then tileState:Restore(tile) end
			if Board:IsPawnSpace(tile) then pawnState:Restore(Board:GetPawn(tile)) end
			if logging then LOG("Loading "..tile.x..","..tile.y) end
		end
	end
end

-- Call for an update if a pawn changes position.
-- If a mech moves three tiles, this triggers three times. So we need the moveDone flag to check if the move is over.
local function pawnPositionChangedHook(mission, defender, oldPosition)
	if logging then LOG("(".. defender:GetId() ..") ".. _G[defender:GetType()].Name .." changed position from (".. oldPosition.x ..", ".. oldPosition.y ..") to (".. defender:GetSpace().x ..", ".. defender:GetSpace().y ..")") end
	if defender:GetTeam() == TEAM_PLAYER and Game:GetTeamTurn() == TEAM_PLAYER and moveDone and not undoMove then
		targetMech = defender
		reflexReady = true
		update = true
	end
	if moveDone then update = true end
end

-- We need a skillEndHook to update the marked tiles when weapons fire
-- For example, smoke drop or rock accelerator can block sightlines
local function skillEndHook(mission, pawn, weaponId, p1, p2)
	update = true
end

local function missionUpdateHook()
	--Continuously mark reflex tiles.
	for id, _ in pairs(GAME.HW_Overwatch) do
		GAME.HW_Overwatch = GAME.HW_Overwatch or {}
		GAME.HW_OverwatchUndo = GAME.HW_OverwatchUndo or {}
		for _, mark in ipairs(GAME.HW_Overwatch[id].markedTiles) do
			if not Board:IsItem(mark) and not Board:IsEnvironmentDanger(mark) then
				Board:MarkSpaceImage(mark, "combat/tile_icon/tile_airstrike.png", GL_Color(60,110,220,0.75))
				Board:MarkSpaceDesc(mark, "reflex_mark")
				--if logging then LOG("Marking tile "..mark.x.."/"..mark.y) end
			end
		end
	end
	
	if reflexReady then
		reflexReady = false
		local def_id = targetMech:GetId()
		local curr = targetMech:GetSpace()
		for att_id, _ in pairs(GAME.HW_Overwatch) do
			if GAME.HW_Overwatch[att_id].remainingShots > 0 then
				local attacker = Board:GetPawn(att_id)
				local shotfrom = attacker:GetSpace()
				local shotPawnIds = GAME.HW_Overwatch[att_id].shotPawnIds
				local WeaponSlot = GAME.HW_Overwatch[att_id].weaponSlot
				shotPawnIds[def_id] = shotPawnIds[def_id] or 0
				if logging then LOG("Preparing reflex shot using weapon in slot "..WeaponSlot.."!") end
				for _, mark in ipairs(GAME.HW_Overwatch[att_id].markedTiles) do
					if curr == mark and shotPawnIds[def_id] < GAME.HW_Overwatch[att_id].shotsPerPawn then
						if not Board:IsSmoke(shotfrom) and Board:GetTerrain(shotfrom) ~= TERRAIN_WATER then
							attacker:FireWeapon(curr, WeaponSlot)
							shotPawnIds[def_id] = shotPawnIds[def_id] + 1
							GAME.HW_Overwatch[att_id].remainingShots = GAME.HW_Overwatch[att_id].remainingShots - 1
							
							if not curr.IsPod then tileState:Save(curr) end
							if logging then LOG("Pilot: "..targetMech:GetPersonality()) end
							if targetMech:GetPersonality() == "Original" or Wolf_HasPoweredWeapon(targetMech, "Passive_ServoEvade", false) then
								local dir = GetDirection(curr - shotfrom)
								local tile = GetProjectileEnd(curr, curr + DIR_VECTORS[dir])
								if not tile.IsPod then tileState:Save(tile) end
								if Board:IsPawnSpace(tile) then pawnState:Save(Board:GetPawn(tile)) end
								if logging then LOG("Saving "..tile.x..","..tile.y) end
							end
							
							Board:AddAlert(shotfrom, "Reflex Firing!")
							
							if logging then LOG("Attacker: ".._G[attacker:GetType()].Name) end
							if _G[attacker:GetType()].Name == "Hive Warrior" then
								if logging then LOG("Biocannon Fired!") end
								GAME.HW_Overwatched = true
								if GAME.HW_WarriorLoc ~= nil then
									Game:AddTutorial("Tut_Reflex", GAME.HW_WarriorLoc)
									if targetMech:GetPersonality() == "Original" then
										Game:AddTutorial("Tut_Dodge", GAME.HW_WarriorLoc)
									end
								end
							end
						end
						--LOGGING---------------------------------------------------------------------
						if logging then LOG("(".. att_id ..") ".. _G[attacker:GetType()].Name .." shoots at (".. def_id ..") ".. _G[targetMech:GetType()].Name) end
						for id, _ in pairs(GAME.HW_Overwatch[att_id].shotPawnIds) do
							if logging then LOG("(".. id ..") ".. _G[Board:GetPawn(id):GetType()].Name .." has been shot ".. GAME.HW_Overwatch[att_id].shotPawnIds[id] .." times.") end
						end
						------------------------------------------------------------------------------
					
						--Store information about the shot in case movement is undone.
						--This would have to be done better if the system should be expanded
						--in a way that allows more than one overwatch shot to be taken in a single move action.
						if targetMech:IsUndoPossible() then
							GAME.HW_OverwatchUndo[def_id] = att_id
						end
						--If undo is not done, we won't bother to clear this until next turn.
					end
				end
			end
		end
	end
	
	if update == false then return end
	update = false
	undoMove = false
	
	for id, _ in pairs(GAME.HW_Overwatch) do --Unusable until we can detect ResetTurn/undoturn
		--Clear markedTiles and rebuild the tables.
		GAME.HW_Overwatch[id].markedTiles = {}
		local pawn = Board:GetPawn(id)
		local pawnPos = pawn:GetSpace()
		GAME.HW_Overwatch[id].pos = pawnPos
		if not pawn:IsFrozen() and not Board:IsSmoke(pawnPos) and Board:GetTerrain(pawnPos) ~= TERRAIN_WATER and GAME.HW_Overwatch[id].remainingShots > 0 then
			for dir = DIR_START, DIR_END do
				for k = 1, GAME.HW_Overwatch[id].range do
					local curr = DIR_VECTORS[dir]*k + pawnPos
				
					if not Board:IsValid(curr) then
						break
					end
					if Board:IsSmoke(curr) then
						break
					end
					if Board:IsBlocked(curr, PATH_PROJECTILE) then
						if Board:IsPawnSpace(curr) and moveDone then
							table.insert(GAME.HW_Overwatch[id].markedTiles, curr)
						end
						break
					end
					table.insert(GAME.HW_Overwatch[id].markedTiles, curr)
				end
			end
		end
	end
end

return {
	onLoad = onLoad,
	newTurnHook = newTurnHook,
	missionStartHook = missionStartHook,
	missionUpdateHook = missionUpdateHook,
	pawnTrackedHook = pawnTrackedHook,
	pawnUntrackedHook = pawnUntrackedHook,
	pawnMoveStartHook = pawnMoveStartHook,
	pawnMoveEndHook = pawnMoveEndHook,
	pawnUndoMoveHook = pawnUndoMoveHook,
	pawnPositionChangedHook = pawnPositionChangedHook,
	skillEndHook = skillEndHook,
}