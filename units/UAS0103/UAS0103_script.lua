--****************************************************************************
--**
--**  File     :  /cdimage/units/UAS0103/UAS0103_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Frigate Script: UAS0103
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local AeonWeapons = import('/lua/aeonweapons.lua')
local ADFCannonQuantumWeapon = AeonWeapons.ADFCannonQuantumWeapon
local AIFQuasarAntiTorpedoWeapon = AeonWeapons.AIFQuasarAntiTorpedoWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')


UAS0103 = Class(ASeaUnit) {

    Weapons = {
        MainGun = Class(ADFCannonQuantumWeapon) {
            FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle02
        },
        MainGun2 = Class(ADFCannonQuantumWeapon) {
            FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle02
        },
        AntiTorpedo01 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = Class(AIFQuasarAntiTorpedoWeapon) {},
    },
}

TypeClass = UAS0103
