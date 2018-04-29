------------------------------------------------------
--        		      WEAPONRY						--
------------------------------------------------------
--Reave
Reave = {
	PathSize = 1,
	Icon = "weapons/enemy_scorpion1.png",	
	Damage = 1,
	PreDamage = 0,
	Web = 0,
	Acid = 0,
	Push = 0,
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
	
	-- GOTTA GET THOSE DAMN TIME TRAVELLERS' TREASURES
	if Board:IsPod(p2) then
		return 100
	end
	LOG(GAME.HW_PodHolder)
	if GAME.HW_PodHolder ~= nil and Board:GetPawn(p2) ~= nil then
		if Board:GetPawn(p2):GetId() == GAME.HW_PodHolder then
			return 100
		end
	end
		
	return self:ScoreList(self:GetSkillEffect(p1,p2).q_effect, true)
end

function Reave:GetSkillEffect(p1, p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local damage = SpaceDamage(p2, self.Damage)
	
	if self.Web == 1 then
		local sound = SpaceDamage(p2)
		ret:AddDamage(SoundEffect(p2,self.SoundBase.."/attack_web"))
		ret:AddGrapple(p1,p2,"hold")
	end
		
	damage = SpaceDamage(p2, self.Damage)
	damage.sAnimation = "SwipeClaw2"
	damage.iAcid = self.Acid
	damage.sSound = "/enemy/beetle_2/attack_impact"
	ret:AddQueuedMelee(p1,damage)
	
	return ret
end	

-------------------------------------------------------
--Biocannon
Biocannon = 	{
	Damage = 2,
	PathSize = 1,
	Fire = 0,
	Freeze = 0,
	Acid = 0,
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
	local damage = SpaceDamage(target, self.Damage)
	
	damage = SpaceDamage(target, self.Damage)
	ret:AddProjectile(damage, self.Projectile)
	
	if self.Splash == 1 then
		local damage1 = SpaceDamage(target + DIR_VECTORS[(dir)% 4])
		local damage2 = SpaceDamage(target - DIR_VECTORS[(dir)% 4])
		local damage3 = SpaceDamage(target + DIR_VECTORS[(dir + 1)% 4])
		local damage4 = SpaceDamage(target + DIR_VECTORS[(dir - 1)% 4])
		ret:AddQueuedDamage(damage1)
		ret:AddQueuedDamage(damage2)
		ret:AddQueuedDamage(damage3)
		ret:AddQueuedDamage(damage4)
	end
	
	return ret
end