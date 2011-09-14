local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Decal = import('/lua/user/userdecal.lua').UserDecal
local Prefs = import('/lua/user/prefs.lua')

local showRangeTable = false

--category tester function, returns true if the bp includes the given category
function HasCategory(blueprint, category)
	if blueprint then
		if blueprint.Categories then
			for i, cat in blueprint.Categories do
				if cat == category then
					return true
				end
			end
		end
		return false
	end
end

--toggle show range of all selected units
function ToggleShowRanges()
	if showRangeTable then
		import('/lua/ui/game/gamemain.lua').RemoveBeatFunction(ShowRanges)
		for i, v in showRangeTable do
			if v.BuildRangeRing then
				v.BuildRangeRing:Destroy()
			end
		end
		showRangeTable = false
	else
		showRangeTable = {}
		import('/lua/ui/game/gamemain.lua').AddBeatFunction(ShowRanges)
	end
end

--beat function, show all selected unit ranges
function ShowRanges()
	local worldview = import('/lua/ui/game/worldview.lua').viewLeft
	if showRangeTable then
		local selection = GetSelectedUnits()
		local selectedUnitInfo = {}
		if selection then
			for i, unit in selection do
				local id = unit:GetEntityId()
				selectedUnitInfo[id] = unit
			end
		end
		for id, unit in selectedUnitInfo do
			if not showRangeTable[id] then
				showRangeTable[id] = {}
				local bp = unit:GetBlueprint()
				if HasCategory(bp, 'ENGINEER') then
					showRangeTable[id].BuildRangeRing = Decal(GetFrame(0))
					showRangeTable[id].BuildRangeRing:SetTexture('/textures/ring_orange.dds')
					if bp.Economy.MaxBuildDistance then
						showRangeTable[id].BuildRangeRing:SetScale({math.floor(2.03*(bp.Economy.MaxBuildDistance+2))+2, 0, math.floor(2.03*(bp.Economy.MaxBuildDistance+2))+2})
					else
						showRangeTable[id].BuildRangeRing:SetScale({22, 0, 22})
					end
				end
			end
			if showRangeTable[id] then
				local unitpos = unit:GetPosition()
				local temppos = worldview:Project(unitpos)
				local screenpos = {temppos[1] + worldview.Left(), temppos[2] + worldview.Top()}
				if showRangeTable[id].BuildRangeRing then
					showRangeTable[id].BuildRangeRing:SetPositionByScreen(screenpos)
				end
			end
		end
		for id, overlay in showRangeTable do
			if not selectedUnitInfo[id] then
				if overlay.BuildRangeRing then
					overlay.BuildRangeRing:Destroy()
				end
				showRangeTable[id] = nil
			end
		end
	end
end

function Init()
	local ringKeyMap = {
	['Ctrl-Alt-Num0'] = {action =  'UI_Lua import("/modules/displayrings.lua").ToggleShowRanges()'}}
	IN_AddKeyMapTable(ringKeyMap)
	ToggleShowRanges()
end
