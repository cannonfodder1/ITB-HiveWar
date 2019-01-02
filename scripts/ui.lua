local Wolf_HWInfo = {}
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
	
	local upgrade1 = nil
	local upgrade2 = nil
	local upgrade3 = nil
	
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
		
	local HasDrawn1 = 0
	local HasDrawn2 = 0
	local HasDrawn3 = 0
	
	local function setUpgrade(num, pic)
		if HasDrawn1 == 0 then
			upgrade1 = iconImage(pic, 5, 20)
			HasDrawn1 = num
			LOG("num1")
			else if HasDrawn2 == 0 then
				upgrade2 = iconImage(pic, 5, 60)
				HasDrawn2 = num
				LOG("num2")
				else if HasDrawn3 == 0 then
					upgrade3 = iconImage(pic, 5, 100)
					HasDrawn3 = num
					LOG("num3")
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
		}
		
		if not Game or island < 2 then
			text = "\nNo evolutions... yet"
			else if Game then
				for i=1, 3 do
					if EvoCheck("BCAcid", i) then
						text = text .. HW_EvoText.BCAcid .."\n"
						setUpgrade(1, acidpic)
					end
					if EvoCheck("BCAmmo", i) then
						text = text .. HW_EvoText.BCAmmo .."\n"
						setUpgrade(2, ammopic)
					end
					if EvoCheck("RVFire", i) then
						text = text .. HW_EvoText.RVFire .."\n"
						setUpgrade(3, firepic)
					end
					if EvoCheck("RVWeb", i) then
						text = text .. HW_EvoText.RVWeb .."\n"
						setUpgrade(4, webpic)
					end
					if EvoCheck("HWArmor", i) then
						text = text .. HW_EvoText.HWArmor .."\n"
						setUpgrade(5, armorpic)
					end
					if EvoCheck("HWAdapt", i) then
						text = text .. HW_EvoText.HWAdapt .."\n"
						setUpgrade(6, adaptpic)
					end
				end
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
		-- After sizing is done, position it at the right edge of the screen, centered vertically
		:pospx(uiRoot.w - pane.w, (uiRoot.h - pane.h) / 2)
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

return {
    Wolf_HWInfo = Wolf_HWInfo,
    Wolf_HWBreach = Wolf_HWBreach
}