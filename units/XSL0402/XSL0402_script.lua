----****************************************************************************
----**
----**  File     :  /cdimage/units/XSL0402/XSL0402_script.lua
----**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos, Greg Kohne
----**
----**  Summary  :  Seraphim Unidentified Residual Energy Signature Script
----**
----**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local SEnergyBallUnit = import("/lua/seraphimunits.lua").SEnergyBallUnit
local SDFUnstablePhasonBeam = import("/lua/seraphimweapons.lua").SDFUnstablePhasonBeam
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class XSL0402 : SEnergyBallUnit
XSL0402 = ClassUnit(SEnergyBallUnit) {
    Weapons = {
        PhasonBeam = ClassWeapon(SDFUnstablePhasonBeam) {
            -- we intentionally do not call the base class as that would immediately
            -- remove the beam again, we remove the beam in the base class of the unit
            OnLostTarget = function(self)
            end,
        },
    },

    OnCreate = function(self)
        SEnergyBallUnit.OnCreate(self)
        for k, v in EffectTemplate.OthuyAmbientEmanation do
            -- XSL0402
            CreateAttachedEmitter(self,'Outer_Tentaclebase', self.Army, v)
        end
        self:HideBone(0,true)
    end,
}

TypeClass = XSL0402