-----------------------------------------------------------------
--  File     :  /cdimage/units/UAB3202/UAB3202_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  Aeon Long Range Sonar Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SSonarUnit = import('/lua/seraphimunits.lua').SSonarUnit
local SSubUnit = import('/lua/seraphimunits.lua').SSubUnit
local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit

XSB3202 = Class(SSubUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        SSubUnit.OnStopBeingBuilt(self,builder,layer)
        
        -- enable sonar economy
        self:SetMaintenanceConsumptionActive()
        
        -- Unless we're gifted, we should have an original builder.
        -- Remains to be seen if this property is actually copied during gift
        if self.originalBuilder then
            IssueDive({self})
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
        self.TimedSonarEffectsThread = self:ForkThread( self.TimedIdleSonarEffects )
    end,
    
    OnMotionVertEventChange = function(self, new, old)
        local mult = self:GetBlueprint().Physics.SubSpeedMultiplier
        SSubUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
            self:SetSpeedMult(1)
        elseif new == 'Down' then
            self:SetSpeedMult(mult)
        end
    end,
    
    
    TimedIdleSonarEffects = function( self )
        local layer = self:GetCurrentLayer()
        local army = self:GetArmy()
        local pos = self:GetPosition()
        if self.TimedSonarTTIdleEffects then
            while not self:IsDead() do
                for kTypeGroup, vTypeGroup in self.TimedSonarTTIdleEffects do
                    local effects = self.GetTerrainTypeEffects( 'FXIdle', layer, pos, vTypeGroup.Type, nil )
                    
                    for kb, vBone in vTypeGroup.Bones do
                        for ke, vEffect in effects do
                            emit = CreateAttachedEmitter(self,vBone,army,vEffect):ScaleEmitter(vTypeGroup.Scale or 1)
                            if vTypeGroup.Offset then
                                emit:OffsetEmitter(vTypeGroup.Offset[1] or 0, vTypeGroup.Offset[2] or 0,vTypeGroup.Offset[3] or 0)
                            end
                        end
                    end                    
                end
                WaitSeconds( 6.0 )                
            end
        end
    end,

    DestroyIdleEffects = function(self)
        self.TimedSonarEffectsThread:Destroy()
        SSeaUnit.DestroyIdleEffects(self)
    end,
    
}

TypeClass = XSB3202