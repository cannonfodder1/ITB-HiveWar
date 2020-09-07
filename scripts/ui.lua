local Wolf_HWInfo = {}
local largefont = sdlext.font("fonts/NunitoSans_Bold.ttf",44)

local warriorpic = nil
local reavepic = sdlext.surface("img/combat/arrow_hit.png")
local biopic = nil
local rangepic = nil
local healthpic = nil
local movepic = sdlext.surface("img/combat/icons/icon_move.png")

local acidpic = sdlext.surface("img/combat/icons/icon_acid_glow.png")
local ammopic = sdlext.surface("img/combat/icons/icon_doubleshot_glow.png")
local firepic = sdlext.surface("img/combat/icons/icon_fire_glow.png")
local webpic = sdlext.surface("img/combat/icons/icon_grapple_glow.png")
local armorpic = sdlext.surface("img/combat/icons/icon_armor_glow.png")
local adaptpic = nil
local vinespic = sdlext.surface("img/combat/icons/icon_tentacle_glow.png")
local aggropic = nil

local textsetMove = deco.textset(deco.colors.white, deco.colors.black, 2)

local function EvoCheck(evo, index)
	if GAME.HW_Evolutions ~= nil then
		for i,v in pairs(GAME.HW_Evolutions) do
			if v == evo and i == index then
				return true
			end
		end
	end
	return false
end

function Wolf_HWInfo:init(self)
	-- Because these images are part of the mod files and not the game files, we have to assign them here
	warrior = sdlext.surface(self.resourcePath.."resources/icons/panel_icon.png")
	biopic = sdlext.surface(self.resourcePath.."resources/icons/biocannon_hit.png")
	rangepic = sdlext.surface(self.resourcePath.."resources/icons/icon_range_glow.png")
	healthpic = sdlext.surface(self.resourcePath.."resources/icons/icon_health_glow.png")
	adaptpic = sdlext.surface(self.resourcePath.."resources/effects/icon_adapt_glow.png")
	aggropic = sdlext.surface(self.resourcePath.."resources/effects/icon_snapshot_glow.png")
end

function Wolf_HWInfo:create(screen, uiRoot)
	local minSize = 50

	local pane = Ui()
		:widthpx(400)
		:decorate({ DecoFrame() })
		:addTo(uiRoot)
	
	-- Register dragging operations: moving and resizing
	pane:registerDragMove()

	local scroll = nil
	local icon = nil
	local uitext = nil
	local forceRelayout = false
	pane.dragMove = function(self, mx, my)
		UiDraggable.dragMove(self, mx, my)

		-- Resizing the parent container doesn't update its children
		-- by default, we have to do it ourselves.
		uitext:width(1):height(1)
		forceRelayout = uitext.pixelWrap
		self:relayout()
	end

	-- Hook into the element's draw function to make its
	-- visibility flag dynamically controllable by the global
	-- Wolf_HWInfo.visible variable.
	pane.draw = function(self, screen)
		self.visible = Wolf_HWInfo.visible or false
		--if sdlext.isMainMenu then self.visible = false end
		Ui.draw(self, screen)
	end

	local function iconImage(pic, xoffset, yoffset)
		local element = Ui()
			:decorate({
				DecoSurfaceOutlined(
					pic,
					nil, nil, deco.colors.buttonbordercolor, 1
				),
				DecoText("", deco.uifont.default.font, textsetMove)
			})
			:pospx(pane.x + xoffset, pane.y + yoffset)
			:addTo(pane)
		return element
	end

	local moveicon = iconImage(movepic, 10, 17)
	local healthicon = iconImage(healthpic, 60, 17)
	local reaveicon = iconImage(reavepic, 110, 17)
	local bioicon = iconImage(biopic, 170, 17)
	local rangeicon = iconImage(rangepic, 230, 17)
	
	local offset = { 50, 73, 96 }
	
	local upgrade1icon = { 
		iconImage(acidpic, 5, offset[1]), 
		iconImage(ammopic, 5, offset[1]), 
		iconImage(firepic, 5, offset[1]), 
		iconImage(webpic, 5, offset[1]), 
		iconImage(armorpic, 5, offset[1]), 
		iconImage(adaptpic, 5, offset[1]),
		iconImage(vinespic, 5, offset[1]),
		iconImage(aggropic, 5, offset[1])
	}
	local upgrade2icon = { 
		iconImage(acidpic, 5, offset[2]), 
		iconImage(ammopic, 5, offset[2]), 
		iconImage(firepic, 5, offset[2]), 
		iconImage(webpic, 5, offset[2]), 
		iconImage(armorpic, 5, offset[2]), 
		iconImage(adaptpic, 5, offset[2]),
		iconImage(vinespic, 5, offset[2]),
		iconImage(aggropic, 5, offset[2])
	}
	local upgrade3icon = { 
		iconImage(acidpic, 5, offset[3]), 
		iconImage(ammopic, 5, offset[3]), 
		iconImage(firepic, 5, offset[3]), 
		iconImage(webpic, 5, offset[3]), 
		iconImage(armorpic, 5, offset[3]), 
		iconImage(adaptpic, 5, offset[3]),
		iconImage(vinespic, 5, offset[3]),
		iconImage(aggropic, 5, offset[3])
	}
	
	for _, pic in ipairs(upgrade1icon) do
		pic.visible = false
	end
	for _, pic in ipairs(upgrade2icon) do
		pic.visible = false
	end
	for _, pic in ipairs(upgrade3icon) do
		pic.visible = false
	end
	
	-- Create a scrolling area
	scroll = Ui()
		:width(1):height(1)
		-- Padding is an invisible inner "border" so that child elements
		-- contained within perceive the space available to them as
		-- parent's size minus this value.
		:padding(5)
		:addTo(pane)
	-- Setting a UI element as translucent means it will never consume
	-- mouse events, but can still handle them as usual
	scroll.translucent = true

	-- "Smart" text UI element that handles wrapping of long text lines if they don't
	-- fit inside of it. Scales its height dynamically to accomodate its content.
	-- You only need to set its width.
	local font = deco.uifont.tooltipText.font
	local textset = deco.uifont.tooltipText.set
	uitext = UiWrappedText(nil, font, textset)
		:width(1)
		:pospx(pane.x + 25, pane.y + 35)
		:addTo(scroll)
	uitext.translucent = true
		
	local HasDrawn = { 0, 0, 0 }
	
	local function HasAlreadyDrawn(index)
		if HasDrawn[1] == index then
			return true
		end
		
		if HasDrawn[2] == index then
			return true
		end
		
		if HasDrawn[3] == index then
			return true
		end
		
		return false
	end
	
	local function setUpgrade(num)
		if HasDrawn[1] == 0 then
			upgrade1icon[num].visible = true
			HasDrawn[1] = num
			--LOG("num1")
		else
			if HasDrawn[2] == 0 then
				upgrade2icon[num].visible = true
				HasDrawn[2] = num
				--LOG("num2")
			else
				if HasDrawn[3] == 0 then
					upgrade3icon[num].visible = true
					HasDrawn[3] = num
					--LOG("num3")
				end
			end
		end
	end

	-- Use a function that makes the text UI element's rendered text controllable
	-- by the Wolf_HWInfo.text global variable.
	local function updateText(self)
		if forceRelayout then
			forceRelayout = false
			self:setText("")
		end
		
		local text = ""
		local island = GetSector() or 1
		
		local health = 0
		local move = 0
		local reave = 0
		local biodamage = 0
		local biorange = 0
		
		if Game and island > 0 then
			health = tostring(GAME.HW_Health)
			move = tostring(GAME.HW_Move)
			reave = tostring(GAME.HW_ReaveDmg)
			biodamage = tostring(GAME.HW_BioDmg)
			biorange = tostring(GAME.HW_BioRange)
		end
		
		healthicon.decorations[2]:setsurface(health)
		moveicon.decorations[2]:setsurface(move)
		reaveicon.decorations[2]:setsurface(reave)
		bioicon.decorations[2]:setsurface(biodamage)
		rangeicon.decorations[2]:setsurface(biorange)
		
		HW_EvoText = {
			BCAcid = "Biocannon attacks will inflict ACID",
			BCAmmo = "Biocannon can attack twice per turn",
			RVFire = "Reave attacks instantly inflict fire",
			RVWeb = "Reave attacks instantly web the target",
			HWArmor = "Incoming weapon damage is reduced by 1",
			HWAdapt = "Status effects are removed every turn",
			HWVines = "Places vines at the end of every turn",
			HWAggro = "Adjusts attack direction when pushed"
		}
		
		HasDrawn = { 0, 0, 0 }
		
		if not Game or island < 2 then
			text = "The stats displayed above, from left to right, \nare Movement, Health, Reave Damage, \nBiocannon Damage, and Reflex Range."
			else if Game then
				for i=1,3 do
					if EvoCheck("C", i) then
						text = text .. HW_EvoText.BCAcid .."\n"
						if not HasAlreadyDrawn(1) then setUpgrade(1) end
					end
					if EvoCheck("M", i) then
						text = text .. HW_EvoText.BCAmmo .."\n"
						if not HasAlreadyDrawn(2) then setUpgrade(2) end
					end
					if EvoCheck("F", i) then
						text = text .. HW_EvoText.RVFire .."\n"
						if not HasAlreadyDrawn(3) then setUpgrade(3) end
					end
					if EvoCheck("W", i) then
						text = text .. HW_EvoText.RVWeb .."\n"
						if not HasAlreadyDrawn(4) then setUpgrade(4) end
					end
					if EvoCheck("A", i) then
						text = text .. HW_EvoText.HWArmor .."\n"
						if not HasAlreadyDrawn(5) then setUpgrade(5) end
					end
					if EvoCheck("D", i) then
						text = text .. HW_EvoText.HWAdapt .."\n"
						if not HasAlreadyDrawn(6) then setUpgrade(6) end
					end
					if EvoCheck("V", i) then
						text = text .. HW_EvoText.HWVines .."\n"
						if not HasAlreadyDrawn(7) then setUpgrade(7) end
					end
					if EvoCheck("R", i) then
						text = text .. HW_EvoText.HWAggro .."\n"
						if not HasAlreadyDrawn(8) then setUpgrade(8) end
					end
				end
			end
		end
				
		if not Game then
			HasDrawn[1] = 0
			HasDrawn[2] = 0
			HasDrawn[3] = 0
			
			for _, pic in ipairs(upgrade1icon) do
				pic.visible = false
			end
			for _, pic in ipairs(upgrade2icon) do
				pic.visible = false
			end
			for _, pic in ipairs(upgrade3icon) do
				pic.visible = false
			end
		end

		self:setText(text)
	end

	-- Hook into the text UI element's draw function to update its text every frame
	uitext.draw = function(self, screen)
		updateText(self)
		return UiWrappedText.draw(self, screen)
	end

	-- Set the UI text element's text, follow up by relayout call to make sure
	-- its inner state is updated to account for it, then set the parent
	-- container's starting size
	updateText(uitext)
	uitext:relayout()
	pane
		-- Size values computed specifically so that the default text will
		-- be perfectly contained.
		--:widthpx(uitext:maxChildSize("width") + scroll.padl + scroll.padr + pane.padl + pane.padr)
		--:heightpx(uitext.h + scroll.padt + scroll.padb + pane.padt + pane.padb)
		:widthpx(400)
		:heightpx(180)
		-- After sizing is done, position it at the bottom right of the screen
		:pospx(uiRoot.w - pane.w - 5, uiRoot.h - pane.h - 5)
		:decorate({ DecoFrameHeader(), DecoFrame() })
		:caption("Hive Warrior")

	-- Tells the text UI element to use pixel-perfect size computation for text wrapping
	-- It works well, but is pretty resource intensive (due to hacky implementation),
	-- so it's off by default.
	uitext.pixelWrap = false

	return pane
end

-- Breach warning

local Wolf_HWBreach = {}
local srfTimeBreach = nil
Wolf_BreachWarnTimeInSeconds = 2

function Wolf_HWBreach:init(self)
    srfTimeBreach = sdlext.surface(self.resourcePath.."resources/effects/timebreach.png")
end

function Wolf_HWBreach:create()
    sdlext.showDialog(function(ui, quit)
        -- background pane has a dark tint and fade animation by default, unset them
        ui.decorations = {}
        ui.hide = nil
        ui.show = nil
        ui.animations.fadeIn = UiAnim(ui, 1, function() end)

        local x = (ScreenSizeX() - srfTimeBreach:w()) / 2
        local y = (ScreenSizeY() - srfTimeBreach:h()) / 3
        
        local timeBreachUi = Ui()
            :pospx(x, y)
            :widthpx(srfTimeBreach:w()):heightpx(srfTimeBreach:h())
            :decorate({ DecoSurface(srfTimeBreach) })
            :addTo(ui)
        
        ui:relayout()
        
        ui.onDialogExit = function(self)
            Wolf_OnTimeBreachWarningDone()
        end

        modApi:scheduleHook(Wolf_BreachWarnTimeInSeconds * 1000, function()
            if ui.parent then
                quit()
            end
        end)
    end)
end

----------------------------------
--      PREPARE TIMELINE        --
----------------------------------

--[[
function quitPT(response)
	--LOG(response)
end

function createPrepTimeline(ui, quit)
	ui.onDialogExit = function(self)
		return true
	end
	
	Wolf_CheckProfileWeapons()
	Wolf_FindProfileWeapons()
	
	local tempWeapons = copy_table(Wolf_GetProfileWeapons())
	local minselected = 24
	local wepCount = 0
	
	local wepButtons = {}
		
	local portraitW = 120 + 8
	local portraitH = 120 + 8
	local gap = 10
	local cellW = portraitW + gap
	local cellH = portraitH + gap
	
	local frametop = Ui()
		:width(0.6):height(0.8)
		:pos(0.1, 0.1)
		:caption("Available Weaponry")
		:decorate({ DecoFrameHeader(), DecoFrame() })
		:addTo(ui)

	local scrollarea = UiScrollArea()
		:width(1):height(1)
		:padding(24)
		:addTo(frametop)
	
	local placeholder = Ui()
		:pospx(-cellW, -cellH)
		:widthpx(portraitW):heightpx(portraitH)
		:decorate({ })
		:addTo(scrollarea)

	local wepCounter = Ui()
		:width(0.3):height(0.075)
		:pos(0.75,0.8)
		:caption("")
		:decorate({ DecoCaption(largefont, deco.uifont.default.set, deco.colors.white, sdl.rgb(255, 100, 100)) })
		:addTo(ui)

	local saveButton -- defined below
	local resetButton -- defined below
		
	local updateWepCount = function()
		wepCount = Wolf_GetNumEnabled(tempWeapons)
		
		wepCounter:caption(wepCount.."\\"..minselected)
		
		if wepCount < minselected then
			wepCounter.disabled = true
			saveButton.disabled = true
		else
			wepCounter.disabled = false
			saveButton.disabled = false
		end
		
		return wepCount
	end
	
	local portraitsPerRow = math.floor(ui.w * frametop.wPercent / cellW)
	frametop
		:width((portraitsPerRow * cellW + scrollarea.padl + scrollarea.padr) / ui.w)
		--:posCentered()
	
	local function resetCheckboxes()
		wepButtons = {}
		for i = 1, #Wolf_PrepWeaponry do
			local id = Wolf_PrepWeaponry[i][1]
			local data = tempWeapons[id]
			
			if _G[id] ~= nil then
				local col = (i - 1) % portraitsPerRow
				local row = math.floor((i - 1) / portraitsPerRow)
				local surface = sdl.scaled(2, sdlext.surface("img/weapons/skill_default.png"))
				
				if _G[id].Icon ~= nil then
					surface = sdl.scaled(2, sdlext.surface("img/".._G[id].Icon))
				else
					LOG(id.." is missing an image!")
				end
				
				local button = Ui()
					:widthpx(portraitW):heightpx(portraitH)
					:pospx(cellW * col, cellH * row)
					:settooltip(data.name)
					:decorate({
						DecoButton(),
						DecoAlign(-4, -20),
						DecoSurface(surface),
						DecoAlign(-73, 60),
						DecoHWCheckbox()
					})
					:addTo(scrollarea)
				
				button.checked = data.status
				
				if data.req ~= nil then
					if Wolf_GetAchievementStatus(data.req) then
						button:settooltip(data.name.."\n\n".."Completed the achievement "..Wolf_GetAchievementText(data.req).."! This weapon is now available.")
					else
						button.checked = false
						button.disabled = true
						tempWeapons[id].status = false
						button:settooltip(data.name.."\n\n".."Complete the achievement "..Wolf_GetAchievementText(data.req).." to unlock!")
					end
				end
						
				button.onclicked = function(self, btn)
					if btn == 1 then
						if button.checked then
							tempWeapons[id].status = false
							button.checked = false
						else
							tempWeapons[id].status = true
							button.checked = true
						end
						updateWepCount()

						return true
					end

					return false
				end
				
				button.wepId = id
				
				wepButtons[i] = button
			end
		end
	end

	saveButton = Ui()
		:pos(0.75, 0.4)
		:width(0.15)
		:height(0.1)
		:caption("Save")
		:decorate({ DecoButton(), DecoAlign(2, 2), DecoCaption(largefont) })
		:addTo(ui)
		
	saveButton.onclicked = function(self, button)
		if button == 1 and minselected < wepCount+1 then
			Wolf_SaveProfileWeapons(tempWeapons)
			updateWepCount()
			quit()
			return true
		end
		return false
	end
	
	resetButton = Ui()
		:pos(0.75, 0.6)
		:width(0.15)
		:height(0.1)
		:caption("Reset")
		:decorate({ DecoButton(), DecoAlign(2, 2), DecoCaption(largefont) })
		:addTo(ui)
		
	resetButton.onclicked = function(self, button)
		if button == 1 then
			tempWeapons = copy_table(Wolf_GetProfileWeapons())
			
			for i = 1, #wepButtons do
				local button = wepButtons[i]
				
				button.checked = tempWeapons[wepButtons[i].wepId].status
			end
			
			updateWepCount()
			return true
		end
		return false
	end
	
	helpButton = Ui()
		:pos(0.75, 0.2)
		:width(0.15)
		:height(0.1)
		:caption("Help")
		:decorate({ DecoButton(), DecoAlign(2, 2), DecoCaption(largefont) })
		:addTo(ui)
		
	helpButton.onclicked = function(self, button)
		if button == 1 then
			sdlext.showTextDialog("Pre-Breach Seeding", "The readings gained from the defeat of the time-hopping Vek known as the Hive Warrior have given us valuable insight on how to direct our breaches more accurately. This interface will allow us to send equipment to the same timeline that the squad will arrive in. We can't breach timepods with 100% accuracy, so the squad will have to search for them among the islands once they arrive. The timepods (and the items within them) could drop too early and find their way into an island corporation's hands, or they may arrive too late for the squad to make use of them at all, or they might land on target, right after the squad hits dirt. We should always breach back at least two dozen items. We wouldn't want the pilots to run short of weapons down there.")
			return true
		end
		return false
	end
		
	updateWepCount()
	resetCheckboxes()
end

local Wolf_PrepTimeline = {}

function Wolf_PrepTimeline:init(self)
end

function Wolf_PrepTimeline:create(screen, uiRoot)
	Wolf_PrepTimeline = Ui()
		:pospx(screen:w()/5, 25)
		:width(0.130)
		:height(0.05)
		:caption("Timepod Launchbay")
		:settooltip("Requires the 'Unbreached' achievement (check the modded achievements menu for details)")
		:decorate({ DecoButton(), DecoAlign(2, 2), DecoCaption() })
		:addTo(uiRoot)
		
	Wolf_PrepTimeline.visible = sdlext.isHangar()

	sdlext.addGameWindowResizedHook(function(screen, oldSize)
		Wolf_PrepTimeline:pospx(screen:w()/5, 25)
	end)
	
	sdlext.addHangarEnteredHook(function(screen)
		Wolf_PrepTimeline.disabled = not HiveWar_achvApi:GetChievoStatus("HW_FinalKill")
		Wolf_PrepTimeline.visible = true
	end)

	sdlext.addHangarExitedHook(function(screen)
		Wolf_PrepTimeline.visible = false
	end)
	
	Wolf_PrepTimeline.onclicked = function(screen, uiRoot)
		sdlext.showDialog(function(ui, quit) createPrepTimeline(ui, quit) end)
		return true
	end
end
--]]
return {
    Wolf_HWInfo = Wolf_HWInfo,
    Wolf_HWBreach = Wolf_HWBreach,
    --Wolf_PrepTimeline = Wolf_PrepTimeline
}