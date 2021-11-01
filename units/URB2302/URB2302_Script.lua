-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsCreateAttachedEmitter = GlobalMethods.CreateAttachedEmitter
-- End of automatically upvalued moho functions

--#****************************************************************************
--#**
--#**  File     :  /cdimage/units/URB2302/URB2302_script.lua
--#**  Author(s):  John Comes, David Tomandl
--#**
--#**  Summary  :  Cybran Long Range Artillery Script
--#**
--#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')
local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CIFArtilleryWeapon = import('/lua/cybranweapons.lua').CIFArtilleryWeapon
local DefaultProjectileWeapon = import('/lua/sim/DefaultWeapons.lua').DefaultProjectileWeapon

URB2302 = Class(CStructureUnit)({
    Weapons = {
        MainGun = Class(CIFArtilleryWeapon)({
            FxMuzzleFlashScale = 0.6,
            FxGroundEffect = EffectTemplate.CDisruptorGroundEffect,
            FxVentEffect = EffectTemplate.CDisruptorVentEffect,
            FxMuzzleEffect = EffectTemplate.CElectronBolterMuzzleFlash01,
            FxCoolDownEffect = EffectTemplate.CDisruptorCoolDownEffect,

            PlayFxMuzzleSequence = function(self, muzzle)
                local army = self.unit.Army
                DefaultProjectileWeapon.PlayFxMuzzleSequence(self, muzzle)
                for k, v in self.FxGroundEffect do
                    GlobalMethodsCreateAttachedEmitter(self.unit, 'URB2302', army, v)
                end
                for k, v in self.FxVentEffect do
                    GlobalMethodsCreateAttachedEmitter(self.unit, 'Exhaust_Left', army, v)
                    GlobalMethodsCreateAttachedEmitter(self.unit, 'Exhaust_Right', army, v)
                end
                for k, v in self.FxMuzzleEffect do
                    GlobalMethodsCreateAttachedEmitter(self.unit, 'Turret_Muzzle', army, v)
                end
                for k, v in self.FxCoolDownEffect do
                    GlobalMethodsCreateAttachedEmitter(self.unit, 'Barrel_B01', army, v)
                end
            end,
        }),
    },
})

TypeClass = URB2302
