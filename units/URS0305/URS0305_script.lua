#****************************************************************************
#**
#**  File     :  /cdimage/units/URB3202/URB3202_script.lua
#**  Author(s):  John Comes
#**
#**  Summary  :  Cybran Long Range Sonar Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CSeaUnit = import('/lua/cybranunits.lua').CSeaUnit

URB3302 = Class(CSeaUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        CSeaUnit.OnStopBeingBuilt(self,builder,layer)
        #enable sonar economy
        self:SetMaintenanceConsumptionActive()
    end,

    TimedSonarTTIdleEffects = {
        {
            Bones = {
                'Plunger',
            },
            Type = 'SonarBuoy01',
        },
    }, 
      
    CreateIdleEffects = function(self)
        CSeaUnit.CreateIdleEffects(self)
        self.TimedSonarEffectsThread = self:ForkThread( self.TimedIdleSonarEffects )
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
        CSeaUnit.DestroyIdleEffects(self)
    end,               
}

TypeClass = URB3302