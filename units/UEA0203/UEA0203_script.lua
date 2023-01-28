--------------------------------------------------------------------------
-- File     :  /cdimage/units/UEA0203/UEA0203_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Gunship Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------
local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local AirTransport = import("/lua/defaultunits.lua").AirTransport
local TDFRiotWeapon = import("/lua/terranweapons.lua").TDFRiotWeapon

---@class UEA0203 : AirTransport
UEA0203 = ClassUnit(AirTransport) {
    EngineRotateBones = {'Jet_Front', 'Jet_Back',},
    Weapons = {
        Turret01 = ClassWeapon(TDFRiotWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TAirUnit.OnStopBeingBuilt(self,builder,layer)
        self.EngineManipulators = {}

        for key, value in self.EngineRotateBones do
            table.insert(self.EngineManipulators, CreateThrustController(self, "thruster", value))
        end

        for key,value in self.EngineManipulators do
            value:SetThrustingParam(-0.0, 0.0, -0.25, 0.25, -0.1, 0.1, 1.0, 0.25)
        end

        for k, v in self.EngineManipulators do
            self.Trash:Add(v)
        end
    end,

    MarkWeaponsOnTransport = function(self, bool)
        TAirUnit.MarkWeaponsOnTransport(self, bool)
        local units = self:GetCargo()
        for _, unit in units do
            for i = 1, unit:GetWeaponCount() do
                local wep = unit:GetWeapon(i)
                wep:SetEnabled(not bool)
            end
        end
    end,
}
TypeClass = UEA0203