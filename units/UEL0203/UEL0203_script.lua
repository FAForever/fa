#****************************************************************************
#**
#**  File     :  /cdimage/units/UEL0203/UEL0203_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  UEF Amphibious Tank Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local EffectTemplate = import('/lua/EffectTemplates.lua')
local THoverLandUnit = import('/lua/terranunits.lua').THoverLandUnit
local TDFRiotWeapon = import('/lua/terranweapons.lua').TDFRiotWeapon
local SlowHover = import('/lua/defaultunits.lua').SlowHoverLandUnit

UEL0203 = Class(THoverLandUnit, SlowHover) {
    Weapons = {
        Riotgun01 = Class(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
        #Riotgun02 = Class(TDFRiotWeapon)
        #{
        #    #FxMuzzleFlash = {'/effects/emitters/riotgun_muzzle_fire_01_emit.bp',
        #    #                 '/effects/emitters/riot_gun_shells_02_emit.bp',},
        #    FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        #},
    },
}

TypeClass = UEL0203