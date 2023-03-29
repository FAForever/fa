-----------------------------------------------------------------
-- File     :  /cdimage/units/UAB2305/UAB2305_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Aeon Tactical Missile Launcher Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AIFQuantumWarhead = import("/lua/aeonweapons.lua").AIFQuantumWarhead

---@class UAB2305 : AStructureUnit
UAB2305 = ClassUnit(AStructureUnit) {
    Weapons = {
        QuantumMissiles = ClassWeapon(AIFQuantumWarhead) {
            UnpackEffects01 = { '/effects/emitters/aeon_nuke_unpack_01_emit.bp', },
            PlayFxWeaponUnpackSequence = function(self)
                for k, v in self.UnpackEffects01 do
                    CreateAttachedEmitter(self.unit, 'B04', self.unit.Army, v)
                end
                AIFQuantumWarhead.PlayFxWeaponUnpackSequence(self)
            end,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self.Blueprint
        self.Trash:Add(CreateAnimator(self):PlayAnim(bp.Display.AnimationOpen))
        self.Trash:Add(ForkThread(self.PlayArmSounds,self))
    end,

    PlayArmSounds = function(self)
        local myBlueprint = self.Blueprint
        if myBlueprint.Audio.Open and myBlueprint.Audio.Activate then
            WaitTicks(48)
            self:PlaySound(myBlueprint.Audio.Activate)
            WaitTicks(38)
            self:PlaySound(myBlueprint.Audio.Activate)
            WaitTicks(39)
            self:PlaySound(myBlueprint.Audio.Activate)
        end
    end,
}
TypeClass = UAB2305

-- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")