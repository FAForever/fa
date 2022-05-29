#****************************************************************************
#**
#**  File     :  /cdimage/Units/UXLTest01/UXL0021_unit.bp
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Test unit for low arc slow moving projectile with multiple 
#**              emitter types.
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local TLandUnit = import('/lua/terranunits.lua').TLandUnit
local WeaponFile = import('/lua/sim/defaultweapons.lua')
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon

UXL0021 = Class(TLandUnit) {
    Weapons = {
        MainGun = Class(DefaultProjectileWeapon) {
            TurretBone = 'Turret',
            BarrelBone = 'Turret_Barrel',
            MuzzleBone = 'Turret_Muzzle',
            FxMuzzleScale = 1,
            RecoilDistance = 0,
        }
    },
    KickupBones = {},
    DestructionPartsLowToss = {'Turret', 'Turret_Barrel', 'Turret_Muzzle'},
    DestructionPartsChassisToss = {'UEL0103',},
    DestructionTicks = 75,
}

TypeClass = UXL0021