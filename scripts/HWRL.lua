-- HWRL is the Hive Warrior Resource Loader, based off the Fully Unified Resource Loader or FURL
-- HWRL allows easy adding of the various Hive Warrior animation variants

local spawn = "breach/warriorteleportin"
local retreat = "breach/warriorteleportout"
local death = "breach/DEATH"

-- Enable this to see log messages
local logging = false

local function setUpVariant(mod,object,final)

	-- LOCALISE

	local name = object.Name
	local filename = object.Filename
	local path = object.Path or "units"
	local innerPath = object.ResourcePath or "units/aliens"
	local height = object.Height or 3
	
	-- SET UP RESOURCE LOADING
	
	local function replaceSprite(external, internal)
		if logging then LOG(internal) end
		modApi:appendAsset("img/"..innerPath.."/"..internal..".png", mod.resourcePath.."/"..path.."/"..external..".png")
	end
	
	-- LOAD
	if final then
		if object.Default then replaceSprite("icon/"..filename.."", filename.."-final") end
		if object.Animated then replaceSprite("anim/"..filename.."_a", filename.."-final_a") end
		if object.Submerged then replaceSprite("water/"..filename.."", filename.."-final_Bw") end
		if object.Emerge then replaceSprite(spawn, filename.."-final_emerge") end
		if object.Death then replaceSprite(death, filename.."-final_death") end
	else
		if object.Default then replaceSprite("icon/"..filename.."", filename.."") end
		if object.Animated then replaceSprite("anim/"..filename.."_a", filename.."_a") end
		if object.Submerged then replaceSprite("water/"..filename.."", filename.."_Bw") end
		if object.Emerge then replaceSprite(spawn, filename.."_emerge") end
		if object.Retreat then replaceSprite(retreat, filename.."_death") end
	end
	
	-- MODIFY THE OBJECTS PASSED
	
	local function addImage(obj, addition)
		if logging then LOG(addition) end
		if obj == nil then obj = {} end
		obj.Image = innerPath.."/"..addition..".png"
		obj.Height = height
		obj.IsVek = true
		return obj
	end
	
	local function addDeath(obj, addition)
		obj.NumFrames = obj.NumFrames or 8
		obj.Time = obj.Time or 0.14
		obj.Loop = obj.Loop or false
		obj = addImage(obj, addition)
		return obj
	end
	
	-- LOAD ANIMATIONS
	
	if final then
		if object.Default         then ANIMS[name.."Final"] =         ANIMS.EnemyUnit:new(addImage(object.Default, filename.."-final")) end
		if object.Animated        then ANIMS[name.."Finala"] =        ANIMS.EnemyUnit:new(addImage(object.Animated, filename.."-final_a")) end
		if object.Submerged       then ANIMS[name.."Finalw"] =        ANIMS.EnemyUnit:new(addImage(object.Submerged, filename.."-final_Bw")) end
		if object.Emerge          then ANIMS[name.."Finale"] =        ANIMS.BaseEmerge:new(addImage(object.Emerge, filename.."-final_emerge")) end
		if object.Death       	  then ANIMS[name.."Finald"] =        ANIMS.EnemyUnit:new(addDeath(object.Death, filename.."-final_death")) end
	else
		if object.Default         then ANIMS[name..""] =         ANIMS.EnemyUnit:new(addImage(object.Default, filename.."")) end
		if object.Animated        then ANIMS[name.."a"] =        ANIMS.EnemyUnit:new(addImage(object.Animated, filename.."_a")) end
		if object.Submerged       then ANIMS[name.."w"] =        ANIMS.EnemyUnit:new(addImage(object.Submerged, filename.."_Bw")) end
		if object.Emerge          then ANIMS[name.."e"] =        ANIMS.BaseEmerge:new(addImage(object.Emerge, filename.."_emerge")) end
		if object.Retreat     	  then ANIMS[name.."d"] =        ANIMS.EnemyUnit:new(addDeath(object.Retreat, filename.."_death")) end
	end
	
end

return function(mod)
	variants = {
		{Name = "HiveWarrior", File = "warrior-none"},
		{Name = "HiveWarriorW", File = "warrior-web"}, -- W
		{Name = "HiveWarriorWV", File = "warrior-web-vines"}, -- WV
		{Name = "HiveWarriorWR", File = "warrior-web-reflex"}, -- WR
		{Name = "HiveWarriorF", File = "warrior-fire"}, -- F
		{Name = "HiveWarriorFV", File = "warrior-fire-vines"}, -- FV
		{Name = "HiveWarriorFR", File = "warrior-fire-reflex"}, -- FR
		{Name = "HiveWarriorC", File = "warrior-acid"}, -- C
		{Name = "HiveWarriorCW", File = "warrior-acid-web"}, -- CW
		--{Name = "HiveWarriorCWV", File = "warrior-acid-web-vines"}, -- CWV
		--{Name = "HiveWarriorCWR", File = "warrior-acid-web-reflex"}, -- CWR
		{Name = "HiveWarriorCF", File = "warrior-acid-fire"}, -- CF
		--{Name = "HiveWarriorCFV", File = "warrior-acid-fire-vines"}, -- CFV
		--{Name = "HiveWarriorCFR", File = "warrior-acid-fire-reflex"}, -- CFR
		{Name = "HiveWarriorCV", File = "warrior-acid-vines"}, -- CV
		{Name = "HiveWarriorCR", File = "warrior-acid-reflex"}, -- CR
		{Name = "HiveWarriorM", File = "warrior-ammo"}, -- M
		{Name = "HiveWarriorMW", File = "warrior-ammo-web"}, -- MW
		--{Name = "HiveWarriorMWV", File = "warrior-ammo-web-vines"}, -- MWV
		--{Name = "HiveWarriorMWR", File = "warrior-ammo-web-reflex"}, -- MWR
		{Name = "HiveWarriorMF", File = "warrior-ammo-fire"}, -- MF
		--{Name = "HiveWarriorMFV", File = "warrior-ammo-fire-vines"}, -- MFV
		--{Name = "HiveWarriorMFR", File = "warrior-ammo-fire-reflex"}, -- MFR
		{Name = "HiveWarriorMV", File = "warrior-ammo-vines"}, -- MV
		{Name = "HiveWarriorMR", File = "warrior-ammo-reflex"}, -- MR
		{Name = "HiveWarriorV", File = "warrior-vines"}, -- V
		{Name = "HiveWarriorR", File = "warrior-reflex"}, -- R
		
		{Name = "HiveWarriorA", File = "warrior-armor-none"}, -- A
		{Name = "HiveWarriorAF", File = "warrior-armor-fire"}, -- AF
		{Name = "HiveWarriorAFR", File = "warrior-armor-fire-reflex"}, -- AFR
		{Name = "HiveWarriorAFV", File = "warrior-armor-fire-vines"}, -- AFV
		{Name = "HiveWarriorAW", File = "warrior-armor-web"}, -- AW
		{Name = "HiveWarriorAWR", File = "warrior-armor-web-reflex"}, -- AWR
		{Name = "HiveWarriorAWV", File = "warrior-armor-web-vines"}, -- AWV
		{Name = "HiveWarriorAC", File = "warrior-armor-acid"}, -- AC
		{Name = "HiveWarriorACF", File = "warrior-armor-acid-fire"}, -- ACF
		{Name = "HiveWarriorACW", File = "warrior-armor-acid-web"}, -- ACW
		{Name = "HiveWarriorACR", File = "warrior-armor-acid-reflex"}, -- ACR
		{Name = "HiveWarriorACV", File = "warrior-armor-acid-vines"}, -- ACV
		{Name = "HiveWarriorAM", File = "warrior-armor-ammo"}, -- AM
		{Name = "HiveWarriorAMF", File = "warrior-armor-ammo-fire"}, -- AMF
		{Name = "HiveWarriorAMW", File = "warrior-armor-ammo-web"}, -- AMW
		{Name = "HiveWarriorAMR", File = "warrior-armor-ammo-reflex"}, -- AMR
		{Name = "HiveWarriorAMV", File = "warrior-armor-ammo-vines"}, -- AMV
		{Name = "HiveWarriorAV", File = "warrior-armor-vines"}, -- AV
		{Name = "HiveWarriorAR", File = "warrior-armor-reflex"}, -- AR
		
		{Name = "HiveWarriorD", File = "warrior-adaptation-none"}, -- D
		{Name = "HiveWarriorDF", File = "warrior-adaptation-fire"}, -- DF
		{Name = "HiveWarriorDFV", File = "warrior-adaptation-fire-vines"}, -- DFV
		{Name = "HiveWarriorDFR", File = "warrior-adaptation-fire-reflex"}, -- DFR
		{Name = "HiveWarriorDW", File = "warrior-adaptation-web"}, -- DW
		{Name = "HiveWarriorDWV", File = "warrior-adaptation-web-vines"}, -- DWV
		{Name = "HiveWarriorDWR", File = "warrior-adaptation-web-reflex"}, -- DWR
		{Name = "HiveWarriorDC", File = "warrior-adaptation-acid"}, -- DC
		{Name = "HiveWarriorDCR", File = "warrior-adaptation-acid-reflex"}, -- DCR
		{Name = "HiveWarriorDCV", File = "warrior-adaptation-acid-vines"}, -- DCV
		{Name = "HiveWarriorDCW", File = "warrior-adaptation-acid-web"}, -- DCW
		{Name = "HiveWarriorDCF", File = "warrior-adaptation-acid-fire"}, -- DCF
		{Name = "HiveWarriorDM", File = "warrior-adaptation-ammo"}, -- DM
		{Name = "HiveWarriorDMR", File = "warrior-adaptation-ammo-reflex"}, -- DMR
		{Name = "HiveWarriorDMV", File = "warrior-adaptation-ammo-vines"}, -- DMV
		{Name = "HiveWarriorDMW", File = "warrior-adaptation-ammo-web"}, -- DMW
		{Name = "HiveWarriorDMF", File = "warrior-adaptation-ammo-fire"}, -- DMF
		{Name = "HiveWarriorDV", File = "warrior-adaptation-vines"}, -- DV
		{Name = "HiveWarriorDR", File = "warrior-adaptation-reflex"}, -- DR
	}
	
	for i=1,#variants do
		local object = {
			Name = variants[i].Name,
			Filename = variants[i].File,
			Path = "resources/units",
			ResourcePath = "units/aliens",
			Height = 1,
			
			Default =           { PosX = -50, PosY = -10 },
			Animated =          { PosX = -50, PosY = -10, NumFrames = 8 },
			Submerged =			{ PosX = -50, PosY = -6 },
			Emerge =            { PosX = -32, PosY = -136, NumFrames = 20 },
			Retreat =           { PosX = -32, PosY = -136, NumFrames = 20 },
			Death =             { PosX = -40, PosY = -20, NumFrames = 16 }
		}
		
		setUpVariant(mod, object, false)
		setUpVariant(mod, object, true)
	end
end