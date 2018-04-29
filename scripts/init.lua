local function init(self)
	-- Load up the Mod API Extension
	if modApiExt then
		-- modApiExt already defined. This means that the user has the complete
		-- ModUtils package installed. Use that instead of loading our own one.
		HiveWar_modApiExt = modApiExt
	else
		-- modApiExt was not found. Load our inbuilt version
		local extDir = self.scriptPath.."modApiExt/"
		HiveWar_modApiExt = require(extDir.."modApiExt")
		HiveWar_modApiExt:init(extDir)
	end

	-- Add new sprites with the Fully Unified Resource Loader
	FURL = require(self.scriptPath.."FURL")
	FURL(self, {
	{
		Type = "enemy",
        Name = "HiveWarrior",
        Filename = "hivewarrior",
		Path = "resources/units", 
		ResourcePath = "units/aliens",
		Height = 1,

        Default =           { PosX = -20, PosY = -10 },
        Animated =          { PosX = -20, PosY = -10, NumFrames = 12 },
        Emerge =            { PosX = -20, PosY = -10, NumFrames = 8 },
		Submerged =			{ PosX = -20, PosY = -6 },
        Death =             { PosX = -20, PosY = -10, NumFrames = 8 },
	},
	{
        Type = "base",
        Filename = "timebreach",
		Path = "resources/effects", 
		ResourcePath = "effects",
	},
	{
        Type = "anim",
        Filename = "explo_biocannon",
		Path = "resources/effects", 
		ResourcePath = "effects",
		
		Name = "ExploBiocannon",
		Base = "ExploFirefly2",

		--NumFrames = 7,
		--Loop = false,
		--PosX = -27,
		--PosY = 0,
		--Time = 0.3
	},
	{
        Type = "base",
        Filename = "shot_biocannon_U",
		Path = "resources/effects", 
		ResourcePath = "effects",
	},
	{
        Type = "base",
        Filename = "shot_biocannon_R",
		Path = "resources/effects", 
		ResourcePath = "effects",
	}
	});
end

local function load(self,options,version)
	-- load up the rest of the mod
	modApi:addWeapon_Texts(require(self.scriptPath.."text"))
	require(self.scriptPath.."weapons")
	require(self.scriptPath.."pawns")
	require(self.scriptPath.."missions")
	
	HiveWar_modApiExt:load(self, options, version)
	-- Create the code hooks needed for our mod
	-- We need a variety of hooks from both the Mod Loader and the Mod API Extension
	local hook = require(self.scriptPath.."hooks")
	hook.onLoad()
	modApi:addNextTurnHook(hook.newTurnHook)
	modApi:addMissionStartHook(hook.missionStartHook)
	modApi:addMissionUpdateHook(hook.missionUpdateHook)
	modApi:addPreMissionAvailableHook(hook.preMissionAvailableHook)
	modApi:addMissionEndHook(hook.missionEndHook)
	modApi:addPostStartGameHook(hook.postStartGameHook)
	HiveWar_modApiExt:addPodDetectedHook(hook.podDetectedHook)
	HiveWar_modApiExt:addPodLandedHook(hook.podLandedHook)
	HiveWar_modApiExt:addPodTrampledHook(hook.podTrampledHook)
	HiveWar_modApiExt:addPodDestroyedHook(hook.podDestroyedHook)
	HiveWar_modApiExt:addPodCollectedHook(hook.podCollectedHook)
	--HiveWar_modApiExt:addPawnTrackedHook(hook.pawnTrackedHook)
	--HiveWar_modApiExt:addPawnUntrackedHook(hook.pawnUntrackedHook)
	--HiveWar_modApiExt:addPawnMoveStartHook(hook.pawnMoveStartHook)
	--HiveWar_modApiExt:addPawnMoveEndHook(hook.pawnMoveEndHook)
	--HiveWar_modApiExt:addResetTurnHook(hook.resetTurnHook)
	--HiveWar_modApiExt:addPawnUndoMoveHook(hook.pawnUndoMoveHook)
	HiveWar_modApiExt:addPawnPositionChangedHook(hook.pawnPositionChangedHook)
	HiveWar_modApiExt:addSkillEndHook(hook.skillEndHook)
	HiveWar_modApiExt:addQueuedSkillEndHook(hook.queuedSkillEndHook)
	HiveWar_modApiExt:addPawnKilledHook(hook.pawnKilledHook)
end

return {
	id = "Wolf_HiveWar",
	name = "Hive War",
	version = "1.0.0",
	requirements = {},
	init = init,
	load = load,
}