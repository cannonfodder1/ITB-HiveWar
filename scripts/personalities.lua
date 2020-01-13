
-- Most dialogs roll a dice for target like so:
-- 40% chance for Hive Warrior to speak
-- 20% chance for Pilot 1 to speak
-- 20% chance for Pilot 2 to speak
-- 20% chance for Pilot 3 to speak
-- If the rolled mech has no pilot, the Hive Warrior will speak (because in order to get Vek to talk, I have to overwrite the AI Pilot's dialog lines)
-- There are a few exceptions:
-- The Wolf_HW_Breach dialog has a 33% chance for each pilot and the AI Pilot is allowed to speak
-- The Wolf_HW_Retreat dialog will only target the Hive Warrior itself, because the pilots have the standard "vek killed" dialog
-- The Wolf_HW_Death dialog will only target the Hive Warrior itself, because the pilots have the standard "vek killed" dialog
-- The Wolf_HW_Draw dialog will only target the Hive Warrior itself, because the pilots have the standard "mission over" dialog



-- Wolf_HW_Breach - called when time breach warning begins - 50% chance for call

Personality.Artificial.Wolf_HW_Breach = {
	"Anomaly. Anomaly. Anomaly.",
	"Temporal breach detected."
}

Personality.Archive.Wolf_HW_Breach = {
	"Commander, we're detecting a Breach!",
	"All my scopes just went crazy!",
	"Commander, my chronometer just lit up!",
	"Quantum fluctuations spiking!",
	"These readings... This can't be right!"
}

Personality.Rust.Wolf_HW_Breach = Personality.Archive.Wolf_HW_Breach
Personality.Detritus.Wolf_HW_Breach = Personality.Archive.Wolf_HW_Breach

Personality.Pinnacle.Wolf_HW_Breach = {
	"[ Att: Commander. Reporting unauthorized quantum collapse ]"
}

Personality.Original.Wolf_HW_Breach = {
	"#squad, hold position and prepare for contact!"
}

-- Wolf_HW_Spawn - called when HW ports into the battle - 50% chance for call

Personality.Artificial.Wolf_HW_Spawn = {
	"Back away from the pod if you wish to live.",
	"#squad, your doom approaches.",
	"This timeline will fall. As have the others.",
	"Surrender the pod. Your story need not end here.",
	"#corp will be cast into the cleansing fire."
}

Personality.Archive.Wolf_HW_Spawn = {
	"What the hell is that thing?!",
	"It's going for the pod!"
}

Personality.Rust.Wolf_HW_Spawn = Personality.Archive.Wolf_HW_Spawn
Personality.Detritus.Wolf_HW_Spawn = Personality.Archive.Wolf_HW_Spawn

Personality.Pinnacle.Wolf_HW_Spawn = {
	"[ Att: Commander. New contact. Threat category: Omega ]"
}

Personality.Original.Wolf_HW_Spawn = {
	"I've killed it before, and I will kill it again..."
}

-- Wolf_HW_Evade - called when Ralph dodges a reflex shot - 100% chance for call

Personality.Artificial.Wolf_HW_Evade = {
	"I wondered if you were here, Karlsson.",
	"Karlsson! It must be.",
	"Finally, we meet again."
}

Personality.Original.Wolf_HW_Evade = {
	"You can't surprise me.",
	"I know all your tricks.",
	"Missed, you ugly bug!"
}

Personality.Archive.Wolf_HW_Evade = {
	"Ralph, how did you dodge that?!",
	"You need to teach me how to do that!",
	"Hell yeah, Ralph!"
}

Personality.Rust.Wolf_HW_Evade = Personality.Archive.Wolf_HW_Evade
Personality.Detritus.Wolf_HW_Evade = Personality.Archive.Wolf_HW_Evade

Personality.Pinnacle.Wolf_HW_Evade = {
	"[ Squadmate: R. KARLSSON has evaded enemy fire ]"
}

-- Wolf_HW_Escape - called when HW escapes with the pod - 100% chance for call

Personality.Artificial.Wolf_HW_Escape = {
	"The #squad cannot match the might of the hive.",
	"A dismal performance. Step up your game.",
	"With weapons like those, your loss was inevitable.",
	"How do you expect to make it to the hive chambers?",
	"Humanity's last hope? Pathetic.",
	"You have run out of time. Ironic.",
	"The gifts of your home timeline are mine.",
	"All your defenses are ultimately meaningless."
}

-- Wolf_HW_Draw - called when mission ends with HW alive - 50% chance for call

Personality.Artificial.Wolf_HW_Draw = {
	"I did not expect such paltry resistance.",
	"I will return, stronger than ever before.",
	"You have only delayed the inevitable.",
	"The hive will prevail. In this timeline, or the next."
}

-- Wolf_HW_Retreat - called when HW retreats out of battle - 50% chance for call

Personality.Artificial.Wolf_HW_Retreat = {
	"You may have won this battle, but at what cost?",
	"Enjoy your victory. It won't last.",
	"I must adapt. We will meet again.",
	"I will never forget the lessons learned this day.",
	"The #squad will meet a painful end one day.",
	"Strike me down, and I will only become more powerful."
}

-- Wolf_HW_Death - called when HW is killed on the hive island - 100% chance for call
--[[
Personality.Artificial.Wolf_HW_Death = {
	"They... will... avenge... me...",
	"Impossible!",
	"We... are... inevitable..."
}
--]]
-- decided not to include this dialog because of the nature of the death animation
