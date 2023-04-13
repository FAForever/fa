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

            IdleState = State(TIFArtilleryWeapon.IdleState) {
                OnGotTarget = function(self)
                    TIFArtilleryWeapon.IdleState.OnGotTarget(self)
                    local artyAnim = self.ArtyAnim
                    local unit = self.unit

                    if not artyAnim then
                        artyAnim = CreateAnimator(unit)
                        artyAnim:PlayAnim(unit.Blueprint.Display.AnimationOpen)
                        unit.Trash:Add(artyAnim)
                    end
                end,
            },
        },
    },
}

TypeClass = UEB2401
