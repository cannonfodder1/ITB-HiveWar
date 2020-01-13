deco.surfaces.checkboxChecked = sdl.surface("resources/mods/ui/checkbox-checked.png")
deco.surfaces.checkboxUnchecked = sdl.surface("resources/mods/ui/checkbox-unchecked.png")
deco.surfaces.checkboxHoveredChecked = sdl.surface("resources/mods/ui/checkbox-hovered-checked.png")
deco.surfaces.checkboxHoveredUnchecked = sdl.surface("resources/mods/ui/checkbox-hovered-unchecked.png")

DecoHWCheckbox = Class.inherit(DecoSurface)
function DecoHWCheckbox:new(checked, unchecked, hovChecked, hovUnchecked)
	self.srfChecked = checked or sdl.surface("mods/HiveWar/resources/icons/icon_selected.png")
	self.srfUnchecked = unchecked or deco.surfaces.checkboxUnchecked
	self.srfHoveredChecked = hovChecked or sdl.surface("mods/HiveWar/resources/icons/icon_hovered.png")
	self.srfHoveredUnchecked = hovUnchecked or deco.surfaces.checkboxHoveredUnchecked
	self.srfDisabled = sdl.surface("mods/HiveWar/resources/icons/icon_locked.png")

	DecoSurface.new(self, self.srfUnchecked)
end

function DecoHWCheckbox:draw(screen, widget)
	if widget.disabled then
		self.surface = self.srfDisabled
	else
		if widget.checked ~= nil and widget.checked then
			if widget.hovered then
				self.surface = self.srfHoveredChecked
			else
				self.surface = self.srfChecked
			end
		else
			if widget.hovered then
				self.surface = self.srfHoveredUnchecked
			else
				self.surface = self.srfUnchecked
			end
		end
	end
	
	DecoSurface.draw(self, screen, widget)
end
