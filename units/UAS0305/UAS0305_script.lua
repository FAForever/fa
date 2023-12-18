--****************************************************************************
--**
--**  File     :  /cdimage/units/UAS0305/UAS0305_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Aeon T3 Sonar
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local AIFQuasarAntiTorpedoWeapon = import("/lua/aeonweapons.lua").AIFQuasarAntiTorpedoWeapon

-- upvalue for performance
local CreateAttachedEmitter = CreateAttachedEmitter
local WaitSeconds = WaitSeconds
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add


---@class UAS0305 : ASeaUnit
UAS0305 = ClassUnit(ASeaUnit) {
    Weapons = {
        AntiTorpedo01 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
    },

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Probe',
            },
            Type = 'SonarBuoy01',
        },
    },

    CreateIdleEffects = function(self)
        ASeaUnit.CreateIdleEffects(self)
        local trash = self.Trash
        self.TimedSonarEffectsThread = TrashBagAdd(trash,ForkThread(self.TimedIdleSonarEffects,self))
    end,

    TimedIdleSonarEffects = function(self)
        local layer = self.Layer
        local pos = self:GetPosition()
        local army = self.Army

        if self.TimedSonarTTIdleEffects then
            while not self.Dead do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects('FXIdle', layer, pos, vTypeGroup.Type, nil)

                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            emit = CreateAttachedEmitter(self, vBone, army, vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
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
        ASeaUnit.DestroyIdleEffects(self)
    end,
}

TypeClass = UAS0305
