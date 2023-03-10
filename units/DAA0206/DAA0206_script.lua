------------------------------------------------------------------------------
-- File :  /cdimage/units/DAA0206/DAA0206_script.lua
-- Author(s): Dru Staltman, Eric Williamson, Gordon Duclos, Greg Kohne
-- Summary : Aeon Guided Missile Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------
local AAirUnits = import("/lua/aeonunits.lua")
local DefaultWeapons = import("/lua/sim/defaultweapons.lua")
local weapon = ClassWeapon(DefaultWeapons.DefaultProjectileWeapon) {}

local function f_OnRunOutOfFuel(self)
    self:Kill()
end

local function f_projectileFired(self)
    local playSound = self.PlayUnitSound
    weapon.IdleState.Main = nil
    playSound(self, 'Killed')
    playSound(self, 'Destroyed')
    self:Destroy()
end

---@class DAA0206 : AAirUnit
local DAA0206 = ClassUnit(AAirUnits.AAirUnit) {
    Weapons = {
        Suicide = weapon,
    },
    --ContrailEffects = {
    --    '/effects/emitters/contrail_ser_ohw_polytrail_01_emit.bp',
    --},
    OnRunOutOfFuel = f_OnRunOutOfFuel,
    ProjectileFired = f_projectileFired,
}
TypeClass = DAA0206

-- Kept for Mod Backwards Compatibility 
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtils = import('/lua/effectutilities.lua')
