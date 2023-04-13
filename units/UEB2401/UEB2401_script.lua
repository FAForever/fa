-- File     :  /cdimage/units/UEB2401/UEB2401_script.lua
-- Author(s):  John Comes
-- Summary  :  UEF Experimental Artillery Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFArtilleryWeapon = import("/lua/terranweapons.lua").TIFArtilleryWeapon

---@class UEB2401 : TStructureUnit
UEB2401 = ClassUnit(TStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFArtilleryWeapon) {
            FxMuzzleFlashScale = 3,
        },
    },

    OnGotTarget = function(self, weapon)
        local unpackAnimation = self.UnpackAnimation
        if not unpackAnimation then
            unpackAnimation = CreateAnimator(self)
            unpackAnimation:PlayAnim(self.Blueprint.Display.AnimationOpen)
            self.UnpackAnimation = unpackAnimation
            self.Trash:Add(unpackAnimation)
        end
    end,
}

TypeClass = UEB2401
