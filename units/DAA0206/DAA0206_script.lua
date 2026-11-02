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
    OnCreate = function(self)
        AAirUnit.OnCreate(self)
        self:StartDisableWeaponThread()
    end,
    
    --- Starts a thread to make us only attack targets when on patrol/attack-move
    --- or attack orders
    --- @param self DAA0206
    StartDisableWeaponThread = function(self)
        local weapon = self:GetWeaponByLabel('Suicide')
        if weapon then
            self.Trash:Add(ForkThread(self.DisableWeaponThread, self, weapon))
        end
    end,

    ---@param self DAA0206
    ---@param weapon DefaultProjectileWeapon
    DisableWeaponThread = function(self, weapon)
        local interval = weapon.Blueprint.TargetCheckInterval / 10 + 1
        while not self.Dead do
            -- only let weapon fire when it makes sense
            if -- we're trying to attack
                self:IsUnitState('Attacking')
                or self:IsUnitState('Patrolling')
                or self:IsUnitState('Guarding')
                -- engineer trying to take us
                or self:IsUnitState('BeingCaptured')
                or self:IsUnitState('BeingReclaimed')
            then
                weapon:SetEnabled(true)
            else
                weapon:SetEnabled(false)
            end

            WaitTicks(interval)
        end
    end,

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
