-----------------------------------------------------------------------------
-- File     :  /cdimage/units/UAB2204/UAB2204_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- Summary  :  Aeon Flak Cannon
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAATemporalFizzWeapon = import("/lua/aeonweapons.lua").AAATemporalFizzWeapon

-- upvalue for perfomance
local CreateAttachedEmitter = CreateAttachedEmitter

---@class UAB2204 : AStructureUnit
UAB2204 = ClassUnit(AStructureUnit) {
    Weapons = {
        AAFizz = ClassWeapon(AAATemporalFizzWeapon) {
            ChargeEffectMuzzles = {'Turret_Right_Muzzle', 'Turret_Left_Muzzle'},

            PlayFxRackSalvoChargeSequence = function(self)
                local unit = self.unit
                local army = unit.Army

                AAATemporalFizzWeapon.PlayFxRackSalvoChargeSequence(self)
                CreateAttachedEmitter(unit, 'Turret_Right_Muzzle',army, '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp')
                CreateAttachedEmitter(unit, 'Turret_Left_Muzzle', army, '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp')
            end,
        },
    },
}

TypeClass = UAB2204