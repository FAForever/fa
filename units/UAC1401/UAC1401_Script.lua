--****************************************************************************
--** 
--**  File     :  /cdimage/units/UAC1401/UAC1401_script.lua 
--**  Author(s):  John Comes, David Tomandl, Gordon Duclos 
--** 
--**  Summary  :  Aeon Agricultural Building, Ver1
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ACivilianStructureUnit = import("/lua/aeonunits.lua").ACivilianStructureUnit

---@class UAC1401 : ACivilianStructureUnit
UAC1401 = ClassUnit(ACivilianStructureUnit) {
	
	OnCreate = function(self)
		ACivilianStructureUnit.OnCreate(self)

        self.DomeEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.DomeEntity:AttachBoneTo( -1, self, 'UAC1401' )
        self.DomeEntity:SetMesh('/effects/Entities/UAC1401-DOME_M001/UAC1401-DOME_mesh')
        self.DomeEntity:SetDrawScale(0.1)
        self.DomeEntity:SetVizToAllies('Intel')
        self.DomeEntity:SetVizToNeutrals('Intel')
        self.DomeEntity:SetVizToEnemies('Intel')         
        self.Trash:Add(self.DomeEntity)
	end,

}


TypeClass = UAC1401

