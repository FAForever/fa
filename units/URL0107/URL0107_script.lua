-- File     :  /cdimage/units/URL0107/URL0107_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Heavy Infantry Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFLaserHeavyWeapon = CybranWeaponsFile.CDFLaserHeavyWeapon
local EffectUtil = import("/lua/effectutilities.lua")

local EmptyTable = EmptyTable

---@class URL0107 : CWalkingLandUnit
---@field BuildEffectsBag TrashBag
URL0107 = ClassUnit(CWalkingLandUnit) {
    Weapons = {
        LaserArms = ClassWeapon(CDFLaserHeavyWeapon) {},
    },

    ---@param self URL0107
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
    end,

    ---@param self URL0107
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateCybranBuildBeamsOpti(self, EmptyTable, unitBeingBuilt, self.BuildEffectsBag, false)
    end,

}

TypeClass = URL0107
