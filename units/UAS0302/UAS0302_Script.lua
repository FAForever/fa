--****************************************************************************
--**
--**  File     :  /cdimage/units/UAS0302/UAS0302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Battleship Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local AAMWillOWisp = import('/lua/aeonweapons.lua').AAMWillOWisp

--Custom files
local NavalCannonOblivionWeapon = import('/lua/aeon_naval_weapons.lua').ADFCannonOblivionNaval

UAS0302 = Class(ASeaUnit) {
    FxDamageScale = 2,
    DestructionTicks = 400,

    Weapons = {
        BackTurret = Class(NavalCannonOblivionWeapon) {},
        FrontTurret = Class(NavalCannonOblivionWeapon) {},
        MidTurret = Class(NavalCannonOblivionWeapon) {},
        AntiMissile1 = Class(AAMWillOWisp) {},
        AntiMissile2 = Class(AAMWillOWisp) {},
    },

    OnCreate = function(self)
        ASeaUnit.OnCreate(self)
        for i = 1, 3 do
            self.Trash:Add(CreateAnimator(self):PlayAnim(self:GetBlueprint().Weapon[i].AnimationOpen))
        end
    end,
}

TypeClass = UAS0302
