-----------------------------------------------------------------
--  File     :  /cdimage/units/UAB3202/UAB3202_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  Aeon Long Range Sonar Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SSubUnit = import("/lua/seraphimunits.lua").SSubUnit
local SSeaUnit = import("/lua/seraphimunits.lua").SSeaUnit

---@class XSB3202 : SSubUnit
XSB3202 = ClassUnit(SSubUnit) {

    OnStopBeingBuilt = function(self, builder, layer)
        SSubUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
        if self.originalBuilder then
            IssueDive({ self })
        end
    end,

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                0,
            },
            Type = 'SonarBuoy01',
        },
    },

    CreateIdleEffects = function(self)
        SSeaUnit.CreateIdleEffects(self)
        local idleEffectsThread = ForkThread(self.TimedIdleSonarEffects, self)
        self.IdleEffectsBag:Add(idleEffectsThread)
    end,

    OnMotionVertEventChange = function(self, new, old)
        local mult = self.Blueprint.Physics.SubSpeedMultiplier
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetSpeedMult(1)
        elseif new == 'Down' then
            self:SetSpeedMult(mult)
        end
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
                            emit = CreateAttachedEmitter(self, vBone, self.Army, vEffect):ScaleEmitter(vTypeGroup.Scale
                                or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,
                                    vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end
                end
                WaitTicks(61)
            end
        end
    end,
}
TypeClass = XSB3202