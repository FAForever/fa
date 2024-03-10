------------------------------------------------------------------------------
-- File :  /cdimage/units/DAA0206/DAA0206_script.lua
-- Author(s): Dru Staltman, Eric Williamson, Gordon Duclos, Greg Kohne
-- Summary : Aeon Guided Missile Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local DefaultProjectileWeapon = import("/lua/sim/defaultweapons.lua").DefaultProjectileWeapon

---@class DAA0206 : AAirUnit
DAA0206 = ClassUnit(AAirUnit) {
    Weapons = {
        Suicide = ClassWeapon(DefaultProjectileWeapon) {}
    },

    ---@param self DAA0206
    OnRunOutOfFuel = function(self)
        self:Kill()
    end,

    ---@param self DAA0206
    ProjectileFired = function(self)
        self:GetWeapon(1).IdleState.Main = function(self) end
        self:PlayUnitSound('Killed')
        self:PlayUnitSound('Destroyed')
        self:Destroy()
    end,
}
TypeClass = DAA0206

-- Kept for Mod Backwards Compatablity
local EffectTemplate = import('/lua/effecttemplates.lua')
local EffectUtils = import('/lua/effectutilities.lua')
local VisionMarker = import("/lua/sim/vizmarker.lua").VisionMarkerOpti