local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Decal = import('/lua/user/userdecal.lua').UserDecal
local Prefs = import('/lua/user/prefs.lua')

local showRangeTable = false

--toggle show range of all selected units
function ToggleShowRanges()
	if showRangeTable then
		import('/lua/ui/game/gamemain.lua').RemoveBeatFunction(ShowRanges)
		for i, ring in showRangeTable do
			if ring then
				ring:Destroy()
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
	local selection = EntityCategoryFilterDown(categories.ENGINEER, GetSelectedUnits())
	local selected = {}

	if selection then
		local worldview = import('/lua/ui/game/worldview.lua').viewLeft

		for _, unit in selection do
			local id = unit:GetEntityId()
			if not showRangeTable[id] then
				local bp = unit:GetBlueprint()
				local ring =  Decal(GetFrame(0))
				ring:SetTexture('/textures/ring_orange.dds')
				if bp.Economy.MaxBuildDistance then
					ring:SetScale({math.floor(2.03*(bp.Economy.MaxBuildDistance+2))+2, 0, math.floor(2.03*(bp.Economy.MaxBuildDistance+2))+2})
				else
					ring:SetScale({22, 0, 22})
				end
				showRangeTable[id] = ring
			end

			local pos = worldview:Project(unit:GetPosition())
			showRangeTable[id]:SetPositionByScreen({pos[1]+worldview.Left(), pos[2]+worldview.Top()})
			selected[id] = true
		end
	end

	for id, ring in showRangeTable do
		if not selected[id] then
			ring:Destroy()
			showRangeTable[id] = nil
		end
    end
end

function Init()
	local ringKeyMap = {
	['Ctrl-Alt-Num0'] = {action =  'UI_Lua import("/modules/displayrings.lua").ToggleShowRanges()'}}
	IN_AddKeyMapTable(ringKeyMap)
	ToggleShowRanges()
end
