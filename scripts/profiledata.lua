
-- Enable this for log messages
local logging = false

function Wolf_DebugArray(array)
	local num = 0
	for id, data in pairs(array) do
		num = num + 1
	end
	return num
end

function Wolf_UnlockAll()
	HiveWar_achvApi:TriggerChievo("HW_FinalKill", true)
	HiveWar_achvApi:TriggerChievo("HW_PentaKill", true)
	HiveWar_achvApi:TriggerChievo("HW_TenPower", true)
	HiveWar_achvApi:TriggerChievo("HW_Nostophobia", true)
	HiveWar_achvApi:TriggerChievo("HW_RalphKill", true)
	HiveWar_achvApi:TriggerChievo("HW_SilentKill", true)
	HiveWar_achvApi:TriggerChievo("HW_FriendlyFire", true)
	HiveWar_achvApi:TriggerChievo("HW_NoPodVictory", true)
end

function Wolf_RelockAll()
	HiveWar_achvApi:TriggerChievo("HW_FinalKill", false)
	HiveWar_achvApi:TriggerChievo("HW_PentaKill", false)
	HiveWar_achvApi:TriggerChievo("HW_TenPower", false)
	HiveWar_achvApi:TriggerChievo("HW_Nostophobia", false)
	HiveWar_achvApi:TriggerChievo("HW_RalphKill", false)
	HiveWar_achvApi:TriggerChievo("HW_SilentKill", false)
	HiveWar_achvApi:TriggerChievo("HW_FriendlyFire", false)
	HiveWar_achvApi:TriggerChievo("HW_NoPodVictory", false)
end

-- NOTE TO OTHER MOD AUTHORS: Do not touch Wolf_ProfileWeapons! Use this function inside init() to add to Wolf_PrepWeaponry instead!
function Wolf_RegisterModdedWeapon(id, achievement)
	if id == nil then
		return false
	end
	-- achievement can be nil
	
	if logging then LOG("Evaluating: "..id) end

	for i = 1, #Wolf_PrepWeaponry do
		-- if this weapon is already there, don't do anything
		if Wolf_PrepWeaponry[i][1] == id and Wolf_PrepWeaponry[i][2] == achievement then
			if logging then LOG("Duplicate: "..id) end
			return false
		end
		-- if the mod wants to overwrite an existing weapon's achievement
		if Wolf_PrepWeaponry[i][1] == id and Wolf_PrepWeaponry[i][2] ~= achievement then
			if logging then LOG("Old Entry: "..id) end
			Wolf_PrepWeaponry[i][2] = achievement
			return true
		end
	end
	
	if logging then LOG("New Entry: "..id) end
	-- if it's a new id, then place it at the end of the array
	Wolf_PrepWeaponry[#Wolf_PrepWeaponry+1] = {id, achievement}
	
	return true
end

-- used to append a weapon to the array
function Wolf_AddProfileWeapon(id, name, status, req)
	Wolf_ProfileWeapons[id] = {name = name, status = status, req = req}
	
	modApi:writeProfileData("Wolf_Weaponry", Wolf_ProfileWeapons)
	
	return entry
end

-- used to update the status of a weapon
function Wolf_UpdateProfileWeapon(id, newStatus)
	Wolf_ProfileWeapons[id].status = newStatus
	
	modApi:writeProfileData("Wolf_Weaponry", Wolf_ProfileWeapons)
	
	return Wolf_ProfileWeapons[id]
end

-- used as a console command to regenerate the data
function Wolf_RefreshProfileWeapons()
	Wolf_ProfileWeapons = {}

	for i = 1, #Wolf_PrepWeaponry do
		local name = GetText(Wolf_PrepWeaponry[i][1].."_Name")
		Wolf_AddProfileWeapon(Wolf_PrepWeaponry[i][1], name, Wolf_PrepWeaponry[i][2] == nil, Wolf_PrepWeaponry[i][2])
	end
end

-- used to check for any new entries that need to be added
function Wolf_FindProfileWeapons()
	Wolf_ProfileWeapons = Wolf_GetProfileWeapons()
	
	for i = 1, #Wolf_PrepWeaponry do
		if Wolf_ProfileWeapons[Wolf_PrepWeaponry[i][1]] == nil then
			if _G[Wolf_PrepWeaponry[i][1]] ~= nil then
				local name = GetText(Wolf_PrepWeaponry[i][1].."_Name")
				Wolf_AddProfileWeapon(Wolf_PrepWeaponry[i][1], name, Wolf_PrepWeaponry[i][2] == nil, Wolf_PrepWeaponry[i][2])
				if logging then LOG("Found new weapon: "..Wolf_PrepWeaponry[i][1]) end
			else
				if logging then LOG("Invalid weapon entry: "..Wolf_PrepWeaponry[i][1]) end
			end
		else
			if Wolf_ProfileWeapons[Wolf_PrepWeaponry[i][1]].req ~= Wolf_PrepWeaponry[i][2] then
				Wolf_ProfileWeapons[Wolf_PrepWeaponry[i][1]].req = Wolf_PrepWeaponry[i][2]
			end
		end
	end
end

-- used to remove any invalid entries
function Wolf_CheckProfileWeapons()
	for id, data in pairs(Wolf_GetProfileWeapons()) do
		if _G[id] == nil then
			Wolf_ProfileWeapons[id] = nil
			if logging then LOG("Removing invalid weapon "..id) end
		end
	end
	modApi:writeProfileData("Wolf_Weaponry", Wolf_ProfileWeapons)
end

-- used to save the entire array
function Wolf_SaveProfileWeapons(array)
	Wolf_ProfileWeapons = copy_table(array)
	modApi:writeProfileData("Wolf_Weaponry", Wolf_ProfileWeapons)
	
	return Wolf_ProfileWeapons
end

-- used to retrieve the array
function Wolf_GetProfileWeapons()
	Wolf_ProfileWeapons = modApi:readProfileData("Wolf_Weaponry")
	return Wolf_ProfileWeapons
end

-- used to retrieve the total number of enabled weapons
function Wolf_GetNumEnabled(array)
	local num = 0
	
	for id, data in pairs(array) do
		if data.status then
			num = num + 1
		end
	end
	
	return num
end

function Wolf_GetAchievementStatus(chievo)
	if chievo ~= nil then
		if HiveWar_achvApi:GetChievo(chievo) ~= nil then
			--LOG(chievo..": "..tostring(HiveWar_achvApi:GetChievoStatus(chievo)))
			if HiveWar_achvApi:GetChievoStatus(chievo) then
				return true
			else
				return false
			end
		else
			local Profile = modApi:loadProfile()
			if Profile["achievements"][chievo] ~= nil then
				return true
			else
				return false
			end
		end
	else
		return true
	end
end

function Wolf_GetAchievementText(chievo)
	if chievo ~= nil then
		if HiveWar_achvApi:GetChievo(chievo) ~= nil then
			return HiveWar_achvApi:GetChievo(chievo).name
		else
			return Achievement_Texts["Ach_"..chievo.."_Title"]
		end
	end
	
	return "ACHIEVEMENT NOT FOUND!"
end

function Wolf_InitializeWeaponry()
	Wolf_PrepWeaponry = {}
	-- all the weapons in the game, used to initialize the array to new profiles and update it with newly added weapons, copied to PrepWeaponry in init()
	-- {"weaponID", "achievementToUnlock"}
	local InitialWeaponry = {
	------ Rift Walkers
		{ "Prime_Punchmech", nil },
		{ "Brute_Tankmech", nil },
		{ "Ranged_Artillerymech", nil },
	------ Rusting Hulks
		{ "Brute_Jetmech", nil },
		{ "Science_Repulse", nil },
		{ "Ranged_Rocket", nil },
		{ "Passive_Electric", nil },
	------ Zenith Guard
		{ "Prime_Lasermech", nil },
		{ "Brute_Beetle", nil },
		{ "Science_Pullmech", nil },
		{ "Science_Shield", nil },
	------ Blitzkrieg
		{ "Prime_Lightning", nil },
		{ "Brute_Grapple", nil },
		{ "Ranged_Rockthrow", nil },
	------ Flame Behemoths
		{ "Prime_Flamethrower", nil },
		{ "Science_Swap", nil },
		{ "Ranged_Ignite", nil },
		{ "Passive_FlameImmune", nil },
	------ Frozen Titans
		{ "Prime_ShieldBash", nil },
		{ "Brute_Mirrorshot", nil },
		{ "Ranged_Ice", nil },
	------ Steel Judoka
		{ "Prime_Shift", nil },
		{ "Science_Gravwell", nil },
		{ "Ranged_Defensestrike", nil },
		{ "Passive_FriendlyFire", nil },
	------ Hazardous Mechs
		{ "Prime_Leap", nil },
		{ "Brute_Unstable", nil },
		{ "Science_AcidShot", nil },
		{ "Passive_Leech", nil },
	------ Random Squad
		{ "Support_Wind", nil },
		{ "Support_Blizzard", nil },
		{ "Passive_ForceAmp", nil },
	------ Custom Squad
		{ "Prime_Spear", nil },
		{ "Ranged_RainingVolley", nil },
		{ "Support_Missiles", nil },
	------	
	------ Misc Weapons
	------
		{ "Prime_Rockmech", nil },
		{ "Prime_RightHook", nil },
		{ "Prime_RocketPunch", nil },
		{ "Prime_Areablast", nil },
		{ "Prime_SpinFist", nil },
		{ "Prime_Sword", nil }, 
		{ "Prime_Smash", nil },
		
		{ "Brute_PhaseShot", nil },
		{ "Brute_Shrapnel", nil },
		{ "Brute_Shockblast", nil },
		{ "Brute_Sniper", nil },
		{ "Brute_Heavyrocket", nil },
		{ "Brute_Splitshot", nil },
		{ "Brute_Bombrun", nil },
		{ "Brute_Sonic", nil },
		
		{ "Ranged_ScatterShot", nil },
		{ "Ranged_BackShot", nil },
		{ "Ranged_SmokeBlast", nil },
		{ "Ranged_Fireball", nil },
		{ "Ranged_Wide", nil },
		{ "Ranged_Dual", nil },
		
		{ "Science_Confuse", nil },
		{ "Science_SmokeDefense", nil },
		{ "Science_FireBeam", nil },
		{ "Science_FreezeBeam", nil },
		{ "Science_LocalShield", nil },
		{ "Science_PushBeam", nil },
		
		{ "Support_Boosters", nil },
		{ "Support_Smoke", nil },
		{ "Support_Force", nil },
		{ "Support_SmokeDrop", nil },
		{ "Support_Repair", nil },
		{ "Support_Refrigerate", nil },
		
		{ "Support_Destruct", nil },
		{ "DeploySkill_ShieldTank", nil },
		{ "DeploySkill_Tank", nil },
		{ "DeploySkill_AcidTank", nil },
		{ "DeploySkill_PullTank", nil },
		
		{ "Passive_MassRepair", nil },
		{ "Passive_Defenses", nil },
		{ "Passive_Burrows", nil },
		{ "Passive_AutoShields", nil },
		{ "Passive_Psions", nil },
		{ "Passive_Boosters", nil },
		{ "Passive_Medical", nil },
		{ "Passive_CritDefense", nil }
	}

	for x = 1, #InitialWeaponry do
		Wolf_RegisterModdedWeapon(InitialWeaponry[x][1], InitialWeaponry[x][2])
	end
end

local oldInitializeDecks = initializeDecks
function initializeDecks(...)
	oldInitializeDecks(...)
	
	if logging then LOG("=== START ===") end
	if logging then LOG(#GAME.WeaponDeck) end
	
	if HiveWar_achvApi:GetChievoStatus("HW_FinalKill") and Wolf_DebugArray(Wolf_GetProfileWeapons()) > 0 then
		GAME.WeaponDeck = {}
		for id, data in pairs(Wolf_GetProfileWeapons()) do
			if data.status then
				table.insert(GAME.WeaponDeck, id)
				if logging then LOG(id) end
			end
		end
	end
	
	if logging then LOG(#GAME.WeaponDeck) end
	if logging then LOG("==== END ====") end
end
