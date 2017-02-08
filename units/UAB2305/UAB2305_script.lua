#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2305/UAB2305_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Tactical Missile Launcher Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AIFQuantumWarhead = import('/lua/aeonweapons.lua').AIFQuantumWarhead
local EffectUtil = import('/lua/EffectUtilities.lua')

UAB2305 = Class(AStructureUnit) {


    Weapons = {
        QuantumMissiles = Class(AIFQuantumWarhead) 
        {
            UnpackEffects01 = {'/effects/emitters/aeon_nuke_unpack_01_emit.bp',},

            PlayFxWeaponUnpackSequence = function(self)
                for k, v in self.UnpackEffects01 do
                    CreateAttachedEmitter( self.unit, 'B04', self.unit:GetArmy(), v )
                end

                AIFQuantumWarhead.PlayFxWeaponUnpackSequence(self)
            end,
    
        },
    },

    OnStopBeingBuilt = function(self,builder,layer)
        AStructureUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint()
        self.Trash:Add(CreateAnimator(self):PlayAnim(bp.Display.AnimationOpen))
        self:ForkThread(self.PlayArmSounds)
    end,

    PlayArmSounds = function(self)
        local myBlueprint = self:GetBlueprint()
        if myBlueprint.Audio.Open and myBlueprint.Audio.Activate then
            WaitSeconds(4.75)
            self:PlaySound(myBlueprint.Audio.Activate)
            WaitSeconds(3.75)
            self:PlaySound(myBlueprint.Audio.Activate)
            WaitSeconds(3.85)
            self:PlaySound(myBlueprint.Audio.Activate)
        end
    end,
    

}

TypeClass = UAB2305
