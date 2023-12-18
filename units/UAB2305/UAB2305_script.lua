-----------------------------------------------------------------
-- File     :  /cdimage/units/UAB2305/UAB2305_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AIFQuantumWarhead = import("/lua/aeonweapons.lua").AIFQuantumWarhead

-- upvalue for perfomance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local CreateAnimator = CreateAnimator
local CreateAttachedEmitter = CreateAttachedEmitter
local TrashBagAdd = TrashBag.Add


---@class UAB2305 : AStructureUnit
UAB2305 = ClassUnit(AStructureUnit) {
    Weapons = {
        QuantumMissiles = ClassWeapon(AIFQuantumWarhead) {
            UnpackEffects01 = { '/effects/emitters/aeon_nuke_unpack_01_emit.bp', },

            PlayFxWeaponUnpackSequence = function(self)
                local unit = self.unit
                local army = unit.Army

                for k, v in self.UnpackEffects01 do
                    CreateAttachedEmitter(unit, 'B04', army, v)
                end
                AIFQuantumWarhead.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self.Blueprint
        local trash = self.Trash

        TrashBagAdd(trash, CreateAnimator(self):PlayAnim(bp.Display.AnimationOpen))
        TrashBagAdd(trash, ForkThread(self.PlayArmSounds,self))
    end,

    PlayArmSounds = function(self)
        local bp = self.Blueprint
        if bp.Audio.Open and bp.Audio.Activate then
            WaitTicks(48)
            self:PlaySound(bp.Audio.Activate)
            WaitTicks(38)
            self:PlaySound(bp.Audio.Activate)
            WaitTicks(39)
            self:PlaySound(bp.Audio.Activate)
        end
    end,
}
TypeClass = UAB2305

-- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")