----****************************************************************************
----**
----**  File     :  /cdimage/units/UES0305/UES0305_script.lua
----**  Author(s):  John Comes
----**
----**  Summary  :  UEF T3 Mobile Sonar
----**
----**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler
local CreateBuildCubeThread = import("/lua/effectutilities.lua").CreateBuildCubeThread

---@class UES0305 : TSeaUnit
UES0305 = ClassUnit(TSeaUnit) {
    Weapons = {
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
    },

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'B14',
            },
            Offset = {
                0,
                -0.6,
                0,
            },
            Type = 'SonarBuoy01',
        },
    }, 

    CreateIdleEffects = function(self)
        TSeaUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread(self.TimedIdleSonarEffects)
    end,

    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end                    
                end
                WaitSeconds(6)                
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        TSeaUnit.DestroyIdleEffects(self)
    end,     

    StartBeingBuiltEffects = function(self, builder, layer)
        self:HideBone(0, true)
        self.BeingBuiltShowBoneTriggered = false
        if self:GetBlueprint().General.UpgradesFrom ~= builder.UnitId then
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
        end
    end,
}

TypeClass = UES0305
