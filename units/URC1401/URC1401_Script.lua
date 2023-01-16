--****************************************************************************
--** 
--**  File     :  /cdimage/units/URC1401/URC1401_script.lua 
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos
--** 
--**  Summary  :  Cybran Agricultural Center, Ver1
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CCivilianStructureUnit = import("/lua/cybranunits.lua").CCivilianStructureUnit

---@class URC1401 : CCivilianStructureUnit
URC1401 = ClassUnit(CCivilianStructureUnit) {
	OnCreate = function(self)
		CCivilianStructureUnit.OnCreate(self)

        self.WindowEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.WindowEntity:AttachBoneTo( -1, self, 'URC1401' )
        self.WindowEntity:SetMesh('/effects/Entities/URC1401_WINDOW/URC1401_WINDOW_mesh')
        self.WindowEntity:SetDrawScale(0.1)
        self.WindowEntity:SetVizToAllies('Intel')
        self.WindowEntity:SetVizToNeutrals('Intel')
        self.WindowEntity:SetVizToEnemies('Intel')         
        self.Trash:Add(self.WindowEntity)
	end,
}


TypeClass = URC1401

