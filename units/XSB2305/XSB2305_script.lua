-----------------------------------------------------------------
-- File     :  /data/units/XSB2305/XSB2305_script.lua
-- Author(s):  Jessica St. Croix, Matt Vainio
-- Summary  :  Seraphim Tactical Missile Launcher Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SStructureUnit = import('/lua/seraphimunits.lua').SStructureUnit
local SIFInainoWeapon = import('/lua/seraphimweapons.lua').SIFInainoWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')

XSB2305 = Class(SStructureUnit)({
    Weapons = {
        InainoMissiles = Class(SIFInainoWeapon)({
            LaunchEffects = function(self)
                local FxLaunch = EffectTemplate.SIFInainoPreLaunch01

                WaitSeconds(1.5)
                self.unit:PlayUnitAmbientSound('NukeCharge')

                for k, v in FxLaunch do
                    CreateEmitterAtEntity(self.unit, self.unit.Army, v)
                end

                WaitSeconds(9.5)
                self.unit:StopUnitAmbientSound('NukeCharge')
            end,

            PlayFxWeaponUnpackSequence = function(self)
                self:ForkThread(self.LaunchEffects)
                SIFInainoWeapon.PlayFxWeaponUnpackSequence(self)
            end,
        }),
    },
})

TypeClass = XSB2305
