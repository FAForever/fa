-----------------------------------------------------------------
-- File     :  /data/units/XSB2305/XSB2305_script.lua
-- Author(s):  Jessica St. Croix, Matt Vainio
-- Summary  :  Seraphim Tactical Missile Launcher Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SIFInainoWeapon = import("/lua/seraphimweapons.lua").SIFInainoWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class XSB2305 : SStructureUnit
XSB2305 = ClassUnit(SStructureUnit) {
    Weapons = {
        InainoMissiles = ClassWeapon(SIFInainoWeapon) {
            LaunchEffects = function(self)
                local FxLaunch = EffectTemplate.SIFInainoPreLaunch01

                WaitTicks(16)
                self.unit:PlayUnitAmbientSound('NukeCharge')

                for k, v in FxLaunch do
                    CreateEmitterAtEntity(self.unit, self.unit.Army, v)
                end

                WaitTicks(96)
                self.unit:StopUnitAmbientSound('NukeCharge')
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self.Trash:Add(ForkThread(self.LaunchEffects,self))
                SIFInainoWeapon.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },
}

TypeClass = XSB2305
