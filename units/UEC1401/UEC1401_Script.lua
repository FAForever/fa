--****************************************************************************
--** 
--**  File     :  /cdimage/units/UEC1401/UEC1401_script.lua 
--**  Author(s):  John Comes, David Tomandl 
--** 
--**  Summary  :  Earth Agricultural Center, Ver1
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TCivilianStructureUnit = import("/lua/terranunits.lua").TCivilianStructureUnit

---@class UEC1401 : TCivilianStructureUnit
UEC1401 = ClassUnit(TCivilianStructureUnit) {

	OnCreate = function(self)
		TCivilianStructureUnit.OnCreate(self)
        self.WindowEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.WindowEntity:AttachBoneTo( -1, self, 'UEC1401' )
        self.WindowEntity:SetMesh('/effects/Entities/UEC1401_WINDOW/UEC1401_WINDOW_mesh')
        self.WindowEntity:SetDrawScale(0.1)
        self.WindowEntity:SetVizToAllies('Intel')
        self.WindowEntity:SetVizToNeutrals('Intel')
        self.WindowEntity:SetVizToEnemies('Intel')        
        self.Trash:Add(self.WindowEntity)
	end,
	
}


TypeClass = UEC1401

