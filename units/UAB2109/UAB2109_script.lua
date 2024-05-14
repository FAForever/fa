--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2109/UAB2109_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Entity = import("/lua/sim/entity.lua").Entity

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add

---@class UAB2109 : AStructureUnit
UAB2109 = ClassUnit(AStructureUnit) {
    Weapons = {
        Turret01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },

	OnCreate = function(self)
		AStructureUnit.OnCreate(self)
        
        local trash = self.Trash

        local domeEntity = Entity { Owner = self }
        self.DomeEntity = domeEntity
        domeEntity:AttachBoneTo( -1, self, 'UAB2109' )
        domeEntity:SetMesh('/effects/Entities/UAB2109_Dome/UAB2109_Dome_mesh')
        domeEntity:SetDrawScale(0.3)
        domeEntity:SetVizToAllies('Intel')
        domeEntity:SetVizToNeutrals('Intel')
        domeEntity:SetVizToEnemies('Intel')
        TrashBagAdd(trash, domeEntity)
	end,
}

TypeClass = UAB2109
