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
UEA0305 = Class(TAirUnit) {
    
    EngineRotateBones = {'Jet_Front', 'Jet_Back',},
    BeamExhaustCruise = '/effects/emitters/gunship_thruster_beam_01_emit.bp',
    BeamExhaustIdle = '/effects/emitters/gunship_thruster_beam_02_emit.bp',
    
    Weapons = {
        Plasma01 = Class(TDFHeavyPlasmaCannonWeapon) {},
        Plasma02 = Class(TDFHeavyPlasmaCannonWeapon) {},
        AAGun = Class(TAirToAirLinkedRailgun) {},
    },
    
    OnStopBeingBuilt = function(self,builder,layer)
        TAirUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetMaintenanceConsumptionActive()
        self.EngineManipulators = {}

        -- create the engine thrust manipulators
        for key, value in self.EngineRotateBones do
            table.insert(self.EngineManipulators, CreateThrustController(self, 'Thruster', value))
        end

        -- set up the thursting arcs for the engines
        for key,value in self.EngineManipulators do
            --                          XMAX, XMIN, YMAX,YMIN, ZMAX,ZMIN, TURNMULT, TURNSPEED
            value:SetThrustingParam( -0.0, 0.0, -0.25, 0.25, -0.1, 1, 1.0,      0.25 )
        end

        for k, v in self.EngineManipulators do
            self.Trash:Add(v)
        end

    end,

}
TypeClass = UEA0305
