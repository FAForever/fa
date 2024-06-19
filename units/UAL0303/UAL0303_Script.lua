------------------------------------------------------------------
-- File     :  /cdimage/units/UAL0303/UAL0303_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local ADFLaserHighIntensityWeapon = import("/lua/aeonweapons.lua").ADFLaserHighIntensityWeapon
local EffectUtil = import("/lua/effectutilities.lua")

---@class UAL0303 : AWalkingLandUnit
UAL0303 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        FrontTurret01 = ClassWeapon(ADFLaserHighIntensityWeapon) {}
    },

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.Blueprint.General.BuildBones.BuildEffectBones, self.BuildEffectsBag)
    end,
}
TypeClass = UAL0303