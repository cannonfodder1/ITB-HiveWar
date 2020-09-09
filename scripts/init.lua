--[[
TODO LIST
- better AI
- more dialog lines
- reflexmark is broke
BUGS LIST
(confirmed)
+ ./mods/reflexivefire/scripts/overwatch.lua:34: attempt to index local 'pawnDefaults' (a nil value)
+ ./mods/HiveWar/scripts/missions.lua:136: attempt to call global 'add_arrays' (a nil value).
+ ./mods/HiveWar/scripts/profiledata.lua:7: bad argument #1 to 'pairs' (table expected, got nil)
+ Something went wrong in HiveWarriorFinal::GetPortrait
+ Hive Warrior AI is being stupid and not attacking
+ Reloading the game wipes the sprite variations
(reported)
- Acid evo always active?
- Reflex fire against mechs not being undone?
- Reflex lethal friendly fire not being undone?
- Reflex friendly fire vs burrowers probably not being undone?
--]]

local Wolf_HWInfo = nil
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
	
	-- Load up the Achievement API
	HiveWar_achvApi = require(self.scriptPath .."achievements/api")
	local chievo = {}
	
	local path = mod_loader.mods[modApi.currentMod].resourcePath
	local imgs = {
		"finalkill",
		"pentakill",
		"tenpower",
		"ralphkill",
		"friendlyfire",
		"silentkill",
		"nopodvictory",
		"swapmaster"
	}

	for _, img in ipairs(imgs) do
		modApi:appendAsset("img/achievements/".. img ..".png", path .."resources/achievements/".. img ..".png")
		modApi:appendAsset("img/achievements/".. img .."_gray.png", path .."resources/achievements/".. img .."_gray.png")
	end

	chievo = { id = "HW_FinalKill", name = "Unbreached", tip = "Kill the Hive Warrior by defeating it inside the Hive caverns", img = "img/achievements/finalkill.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_PentaKill", name = "Hive Collapse", tip = "Defeat the Hive Warrior four times then kill it, all in a single timeline", img = "img/achievements/pentakill.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_TenPower", name = "Light the Darkness", tip = "Enter the Hive caverns with 10 full bars of Grid Power", img = "img/achievements/tenpower.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_Nostophobia", name = "Off the Beaten Path", tip = "Win a victory without possessing any of the squad's original weapons", img = "img/achievements/swapmaster.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_RalphKill", name = "Cosmic Rivalry", tip = "Land the killing blow on the Hive Warrior with Ralph Karlsson", img = "img/achievements/ralphkill.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_SilentKill", name = "Can't Touch This", tip = "Defeat the Hive Warrior without any reflex shots being fired", img = "img/achievements/silentkill.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_FriendlyFire", name = "My Finger Slipped", tip = "Kill a Vek with a shot from the Hive Warrior's Biocannon", img = "img/achievements/friendlyfire.png" }
	HiveWar_achvApi:AddChievo(chievo)
	chievo = { id = "HW_NoPodVictory", name = "Comeback Kings", tip = "Win a victory after letting the Hive Warrior destroy four timepods", img = "img/achievements/nopodvictory.png" }
	HiveWar_achvApi:AddChievo(chievo)
	
	menu_images = {
		"Loading_bar",
		"Loading_bar_mask",
		"Loading_main",
		"title_large",
	}
	
	for i, name in ipairs(menu_images) do
		modApi:appendAsset("img/main_menus/"..name..".png", self.resourcePath.."resources/main_menus/"..name..".png")
	end
	
	-- Add new sprites with the Fully Unified Resource Loader
	FURL = require(self.scriptPath.."FURL")
	FURL(self, {
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
	},
	{
        Type = "base",
        Filename = "icon_adapt",
		Path = "resources/effects",
		ResourcePath = "combat/icons",
	},
	{
        Type = "base",
        Filename = "icon_adapt_glow",
		Path = "resources/effects",
		ResourcePath = "combat/icons",
	},
	{
        Type = "base",
        Filename = "reflexmark",
		Path = "resources/icons", 
		ResourcePath = "combat/tile_icon",
	},
	{
        Type = "base",
        Filename = "hwportrait_classic",
		Path = "resources/units",
		ResourcePath = "portraits/enemy",
	},
	{
        Type = "base",
        Filename = "hwportrait_normal",
		Path = "resources/units",
		ResourcePath = "portraits/enemy",
	},
	{
        Type = "base",
        Filename = "hwportrait_firelit",
		Path = "resources/units",
		ResourcePath = "portraits/enemy",
	},
	{
        Type = "base",
        Filename = "passive_adaptation",
		Path = "resources/weapons", 
		ResourcePath = "weapons/passives",
	},
	{
        Type = "base",
        Filename = "prime_overload",
		Path = "resources/weapons", 
		ResourcePath = "weapons",
	},
	{
        Type = "base",
        Filename = "passive_servoevade",
		Path = "resources/weapons", 
		ResourcePath = "weapons/passives",
	},
	{
        Type = "base",
        Filename = "science_timeskip",
		Path = "resources/weapons", 
		ResourcePath = "weapons",
	}
	});
	
	-- Add new sprites with the Hive Warrior Resource Loader
	HWRL = require(self.scriptPath.."HWRL")
	HWRL(self);
	
	-- Add the config option for the info panel hotkey
	modApi:addGenerationOption(
		"hotkey", "Info Panel Hotkey",
		"The hotkey used to toggle the Hive Warrior's information panel",
		{
			strings = { "W", "H", "F1", "F2", "F3" },
			values = { 0x77, 0x68, 0x4000003A, 0x4000003B, 0x4000003C },
			value = 0x77
		}
	)
	
	-- Add the config option for the HW portrait
	modApi:addGenerationOption(
		"portrait", "Hive Warrior Portrait",
		"The portrait image used by the Hive Warrior - REQUIRES NEW TIMELINE TO TAKE EFFECT",
		{
			strings = { "Classic Firelit", "Redux Sunlit", "Redux Firelit" },
			values = { "hwportrait_classic", "hwportrait_normal", "hwportrait_firelit" },
			value = "hwportrait_normal"
		}
	)
	
	--[[
	if modApi:readProfileData("Wolf_Weaponry") == nil then
		--LOG("HIVE WAR PROFILE DATA NOT FOUND!")
		Wolf_ProfileWeapons = {}
		modApi:writeProfileData("Wolf_Weaponry", Wolf_ProfileWeapons)
	else
		--LOG("HIVE WAR LOADING FROM PROFILE!")
		Wolf_ProfileWeapons = modApi:readProfileData("Wolf_Weaponry")
	end
	
	require(self.scriptPath.."profiledata")
	Wolf_InitializeWeaponry()
	--]]
	
	require(self.scriptPath.."deco_HWcheckbox")
	local uiModule = require(self.scriptPath.."ui")

	Wolf_HWInfo = uiModule.Wolf_HWInfo
	Wolf_HWInfo:init(self)
	Wolf_HWInfo.visible = false
	
	--Wolf_PrepTimeline = uiModule.Wolf_PrepTimeline
	--Wolf_PrepTimeline:init(self)
	--Wolf_PrepTimeline.visible = false

	sdlext.addUiRootCreatedHook(function(screen, uiRoot)
		Wolf_HWInfo:create(screen, uiRoot)
			:bringToTop()
		--Wolf_PrepTimeline:create(screen, uiRoot)
			--:bringToTop()
	end)
	
	Wolf_HWBreach = uiModule.Wolf_HWBreach
	Wolf_HWBreach:init(self)

	sdlext.addPostKeyUpHook(function(keycode)
		if sdlext.isGame and keycode == Wolf_HWInfo.hotkey then
			Wolf_HWInfo.visible = not Wolf_HWInfo.visible
			return true
		end
		if not sdlext.isGame and keycode == Wolf_HWInfo.hotkey then
			Wolf_HWInfo.visible = false
			return true
		end
		return false
	end)
	
	sdlext.addFrameDrawnHook(function(screen)
		if Game then
			if ORIGINAL_UNDOTURN_LOCATION == nil then
				ORIGINAL_UNDOTURN_LOCATION = Location.undo_turn
			end
			if GAME.HW_MaxPower ~= nil then
				Location.undo_turn = ORIGINAL_UNDOTURN_LOCATION + Point(GAME.HW_MaxPower * 20, 0)
			end
		end
	end)
	
	-- load up the rest of the mod
	modApi:addWeapon_Texts(require(self.scriptPath.."text"))
	require(self.scriptPath.."weapons")
	require(self.scriptPath.."pawns")
	require(self.scriptPath.."missions")
	require(self.scriptPath.."dialogs")
	require(self.scriptPath.."personalities")
end

local function load(self,options,version)
	Wolf_HWInfo.hotkey = options["hotkey"].value
	Wolf_HiveWarriorPortrait = options["portrait"].value
	
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
	modApi:addMissionNextPhaseCreatedHook(hook.missionNextPhaseCreatedHook)
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
	HiveWar_modApiExt:addSkillStartHook(hook.skillStartHook)
	HiveWar_modApiExt:addSkillEndHook(hook.skillEndHook)
	HiveWar_modApiExt:addQueuedSkillEndHook(hook.queuedSkillEndHook)
	HiveWar_modApiExt:addPawnKilledHook(hook.pawnKilledHook)
	
	-- Create the code hooks needed for the reflex shot
	-- We need a variety of hooks from both the Mod Loader and the Mod API Extension
	local tileState = require(self.scriptPath .."tileState")("Wolf_HW")
	local pawnState = require(self.scriptPath .."pawnState")("Wolf_HW")
	local overwatch = require(self.scriptPath.."overwatch")
	overwatch.onLoad(tileState, pawnState)
	modApi:addNextTurnHook(overwatch.newTurnHook)
	modApi:addMissionStartHook(overwatch.missionStartHook)
	modApi:addMissionUpdateHook(overwatch.missionUpdateHook)
	modApi:addTestMechEnteredHook(overwatch.missionStartHook)
	HiveWar_modApiExt:addPawnTrackedHook(overwatch.pawnTrackedHook)
	HiveWar_modApiExt:addPawnUntrackedHook(overwatch.pawnUntrackedHook)
	HiveWar_modApiExt:addPawnMoveStartHook(overwatch.pawnMoveStartHook)
	HiveWar_modApiExt:addPawnMoveEndHook(overwatch.pawnMoveEndHook)
	HiveWar_modApiExt:addPawnUndoMoveHook(overwatch.pawnUndoMoveHook)
	HiveWar_modApiExt:addPawnPositionChangedHook(overwatch.pawnPositionChangedHook)
	HiveWar_modApiExt:addSkillEndHook(overwatch.skillEndHook)
end

return {
	id = "Wolf_HiveWar",
	name = "Hive War",
	version = "1.1.0",
	requirements = { "kf_ModUtils" },
	icon = "resources/mod_icon.png",
	init = init,
	load = load,
}
