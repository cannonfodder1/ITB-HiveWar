
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

------------------------------------------------------
--        		      WEAPONRY						--
------------------------------------------------------
--Reave
Reave = {
	GetDamage = function() return GAME.HW_ReaveDmg or 1 end,
	PathSize = 1,
	Icon = "weapons/enemy_scorpion1.png",	
	PreDamage = 0,
	Class = "Enemy",
	LaunchSound = "",
	SoundBase = "/enemy/scorpion_soldier_1",
	TipImage = {
		Unit = Point(2,2),
		Enemy = Point(2,1),
		Target = Point(2,1),
		CustomPawn = "HiveWarrior"
	}
}
Reave = Skill:new(Reave) 

function Reave:GetTargetScore(p1,p2)
	local effect = SkillEffect()
	local island = GetSector()
	
	-- GOTTA GET THOSE TIME TRAVELLERS' TREASURES
	if Board:IsPod(p2) then
		return 100
	end
	
	if GAME.HW_PodHolder ~= nil and Board:GetPawn(p2) ~= nil then
		if Board:GetPawn(p2):GetId() == GAME.HW_PodHolder then
			return 100
		end
	end
	
	-- don't flame units without repair
	if EvoCheck("RVFire") then
		local pawn = Board:GetPawn(p2)
		if pawn ~= nil then
			if not pawn:IsMech() then
				return -100
			end
		end
	end
		
	return self:ScoreList(self:GetSkillEffect(p1,p2).q_effect, true)
end

function Reave:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local damage = SpaceDamage(p2, self.GetDamage())
	local island = GetSector()
	
	if EvoCheck("RVWeb") then
		local predam = SpaceDamage(p2)
		ret:AddDamage(predam)
		ret:AddDelay(0.2)
		ret:AddDamage(SoundEffect(p2,self.SoundBase.."/attack_web"))
		ret:AddGrapple(p1,p2,"hold")
		ret:AddDelay(0.2)
	end
	if EvoCheck("RVFire") then
		local predam = SpaceDamage(p2)
		if Board:IsPod(p2) == false then
			predam.iFire = 1
		end
		predam.sAnimation = "flamethrower1_"..direction
		predam.sSound = "/weapons/flamethrower"
		ret:AddDamage(predam)
		ret:AddDelay(0.2)
	end

	damage = SpaceDamage(p2, self.GetDamage())
	damage.sAnimation = "SwipeClaw2"
	damage.sSound = "/enemy/beetle_2/attack_impact"
	ret:AddQueuedMelee(p1,damage)
	
	return ret
end	

-------------------------------------------------------
--Biocannon
Biocannon = 	{
	GetDamage = function() return GAME.HW_BioDmg or 2 end,
	PathSize = 1,
	Splash = 0,
	Class = "Enemy",
	Icon = "weapons/ranged_rainingvolley.png",
	Explosion = "ExploBiocannon",
	ImpactSound = "/impact/dynamic/enemy_projectile",
	Projectile = "effects/shot_biocannon",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Building = Point(2,0),
		Target = Point(2,2),
		CustomPawn = "HiveWarrior"
	}
}	
Biocannon = Skill:new(Biocannon)

function Biocannon:GetTargetArea(point)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		local this_path = {}
		
		local target = point + DIR_VECTORS[dir]

		while not Board:IsBlocked(target, PATH_PROJECTILE) do
			this_path[#this_path+1] = target
			target = target + DIR_VECTORS[dir]
		end
		this_path[#this_path+1] = target
		
		for i,v in ipairs(this_path) do 
			ret:push_back(v)
		end
		
	end
	
	return ret
end

function Biocannon:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local dir = GetDirection(p2 - p1)
	local target = GetProjectileEnd(p1,p2)
	local damage = SpaceDamage(target, self.GetDamage())
	
	if EvoCheck("BCAcid") then
		damage.iAcid = 1
	else
		damage.iAcid = 0
	end
	
	ret:AddProjectile(damage, self.Projectile)
	
	return ret
end
