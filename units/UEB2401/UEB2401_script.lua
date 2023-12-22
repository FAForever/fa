--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2401/UEB2401_script.lua
--**  Author(s):  John Comes
--**
--**  Summary  :  UEF Experimental Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TIFArtilleryWeapon = import("/lua/terranweapons.lua").TIFArtilleryWeapon

-- upvalue for perfomance
local CreateAnimator = CreateAnimator
local TrashBagAdd = TrashBag.Add

---@class UEB2401 : TStructureUnit
UEB2401 = ClassUnit(TStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(TIFArtilleryWeapon) {
            FxMuzzleFlashScale = 3,

            IdleState = State(TIFArtilleryWeapon.IdleState) {
                OnGotTarget = function(self)
                    TIFArtilleryWeapon.IdleState.OnGotTarget(self)
                    local bp = self.unit.Blueprint

                    if not self.ArtyAnim then
                        self.ArtyAnim = CreateAnimator(self.unit)
                        self.ArtyAnim:PlayAnim(bp.Display.AnimationOpen)
                        self.unit.Trash:Add(self.ArtyAnim)
                    end
                end,
            },
        },
    },
}

TypeClass = UEB2401