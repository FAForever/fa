--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2205/UAB2205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Aeon Heavy Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon

---@class UAB2205 : AStructureUnit
UAB2205 = ClassUnit(AStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },
    
	OnCreate = function(self)
		AStructureUnit.OnCreate(self)

        self.DomeEntity = import("/lua/sim/entity.lua").Entity({Owner = self,})
        self.DomeEntity:AttachBoneTo( -1, self, 'UAB2205' )
        self.DomeEntity:SetMesh('/effects/Entities/UAB2205_Dome/UAB2205_Dome_mesh')
        self.DomeEntity:SetDrawScale(0.45)
        self.DomeEntity:SetVizToAllies('Intel')
        self.DomeEntity:SetVizToNeutrals('Intel')
        self.DomeEntity:SetVizToEnemies('Intel')         
        self.Trash:Add(self.DomeEntity)
	end,    
}

TypeClass = UAB2205