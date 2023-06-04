--****************************************************************************
--**
--**  File     :  /cdimage/units/UAL0205/UAL0205_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Aeon Mobile Flak Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

--Below, changed from ALandUnit to AHoverLandUnit
local AHoverLandUnit = import("/lua/aeonunits.lua").AHoverLandUnit
local AAATemporalFizzWeapon = import("/lua/aeonweapons.lua").AAATemporalFizzWeapon
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit


--Below, changed from ALandUnit to AHoverLandUnit
UAL0205 = ClassUnit(AHoverLandUnit, SlowHover) {
    KickupBones = {},

    Weapons = {
        AAGun = ClassWeapon(AAATemporalFizzWeapon) {
            ChargeEffectMuzzles = {'Muzzle_R01', 'Muzzle_L01'},

            PlayFxRackSalvoChargeSequence = function(self)
                AAATemporalFizzWeapon.PlayFxRackSalvoChargeSequence(self)
                CreateAttachedEmitter(self.unit, 'Muzzle_R01', self.unit.Army, '/effects/emitters/temporal_fizz_muzzle_charge_02_emit.bp')
                CreateAttachedEmitter(self.unit, 'Muzzle_L01', self.unit.Army, '/effects/emitters/temporal_fizz_muzzle_charge_03_emit.bp')
            end,
        },
    },

    OnCreate = function(self)
        AHoverLandUnit.OnCreate(self)
        self.Trash:Add(CreateSlaver(self, 'Barrel_L', 'Barrel_R'))
    end,
}

TypeClass = UAL0205
