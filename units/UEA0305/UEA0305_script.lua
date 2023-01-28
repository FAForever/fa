-----------------------------------------------------------------
--  File     :  /cdimage/units/UEA0305/UEA0305_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  UEF Heavy Gunship Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TWeapons = import("/lua/terranweapons.lua")
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local TAirToAirLinkedRailgun = TWeapons.TAirToAirLinkedRailgun


---@class UEA0305 : TAirUnit
UEA0305 = ClassUnit(TAirUnit) {

    EngineRotateBones = {'Jet_Front', 'Jet_Back',},
    BeamExhaustCruise = '/effects/emitters/gunship_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/gunship_thruster_beam_02_emit.bp',

    Weapons = {
        Plasma01 = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
        Plasma02 = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
        AAGun = ClassWeapon(TAirToAirLinkedRailgun) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()

        -- create the engine thrust manipulators
        for _, bone in self.EngineRotateBones do
            local controller = CreateThrustController(self, 'Thruster', bone)
            controller:SetThrustingParam(-0.0, 0.0, -0.25, 0.25, -0.1, 1, 1.0, 0.25 )
            self.Trash:Add(controller)
        end
    end,

}
TypeClass = UEA0305
