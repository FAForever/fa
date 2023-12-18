-- File     :  /cdimage/units/UAS0302/UAS0302_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Battleship Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local AAMWillOWisp = import("/lua/aeonweapons.lua").AAMWillOWisp
local NavalCannonOblivionWeapon = import("/lua/aeonweapons.lua").ADFCannonOblivionNaval

-- upvlaue for perfomance
local TrashBagAdd = TrashBag.Add
local CreateAnimator = CreateAnimator

---@class UAS0302 : ASeaUnit
UAS0302 = ClassUnit(ASeaUnit) {
    Weapons = {
        BackTurret = ClassWeapon(NavalCannonOblivionWeapon) {},
        FrontTurret = ClassWeapon(NavalCannonOblivionWeapon) {},
        MidTurret = ClassWeapon(NavalCannonOblivionWeapon) {},
        AntiMissile1 = ClassWeapon(AAMWillOWisp) {},
        AntiMissile2 = ClassWeapon(AAMWillOWisp) {},
    },

    OnCreate = function(self)
        ASeaUnit.OnCreate(self)
        local bp = self.Blueprint
        local trash = self.Trash

        for i = 1, 3 do
            TrashBagAdd(trash,CreateAnimator(self):PlayAnim(bp.Weapon[i].AnimationOpen))
        end
    end,
}
TypeClass = UAS0302