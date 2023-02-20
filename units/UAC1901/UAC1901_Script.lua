--****************************************************************************
--** 
--**  File     :  /cdimage/units/UAC1901/UAC1901_script.lua 
--**  Author(s):  John Comes, David Tomandl 
--** 
--**  Summary  :  Seraphim Sacred Site, Ver1
--** 
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ACivilianStructureUnit = import("/lua/aeonunits.lua").ACivilianStructureUnit

---@class UAC1901 : ACivilianStructureUnit
UAC1901 = ClassUnit(ACivilianStructureUnit) {
	OnCreate = function(self)
		ACivilianStructureUnit.OnCreate(self)

        self.DomeEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.DomeEntity:AttachBoneTo( -1, self, 'UAC1901' )
        self.DomeEntity:SetMesh('/effects/Entities/UAC1901-DOME/UAC1901-DOME_mesh')
        self.DomeEntity:SetDrawScale(0.1)
        self.DomeEntity:SetVizToAllies('Intel')
        self.DomeEntity:SetVizToNeutrals('Intel')
        self.DomeEntity:SetVizToEnemies('Intel')          
        self.Trash:Add(self.DomeEntity)
	end,
}


TypeClass = UAC1901

