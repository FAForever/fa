#****************************************************************************
#**
#**  File     :  /cdimage/units/XRB3301/XRB3301_script.lua
#**  Author(s):  Dru Staltman, Ted Snook
#**
#**  Summary  :  Cybran Vision unit thing
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local CRadarUnit = import('/lua/cybranunits.lua').CRadarUnit
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local CSoothSayerAmbient = import('/lua/EffectTemplates.lua').CSoothSayerAmbient

XRB3301 = Class(CRadarUnit) {   
    IntelEffects = {
        {
            Bones = { 'Emitter', },
            Offset = { 0, 0, 4, },
            Type = 'Jammer01',
        },
    },
    
    OnStopBeingBuilt = function(self)
        CRadarUnit.OnStopBeingBuilt(self)
        ChangeState( self, self.ExpandingVision )
        self.ExpandingVisionDisableCount = 0
        
        
        if self.OmniEffectsBag then
            for k, v in self.OmniEffectsBag do
                v:Destroy()
            end
        end
		self.OmniEffectsBag = {}
		
        for k, v in CSoothSayerAmbient do
            table.insert( self.OmniEffectsBag, CreateAttachedEmitter(self, 'XRB3301', self:GetArmy(), v) )
        end        
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        local curRadius = self:GetIntelRadius('vision')
        local position = self:GetPosition()
        local army = self:GetAIBrain():GetArmyIndex()
        CRadarUnit.OnKilled(self, instigator, type, overkillRatio)
        local spec = {
            X = position[1],
            Z = position[3],
            Radius = curRadius,
            LifeTime = -1,
            Army = army,
        }
        local vizEnt = VizMarker(spec)
        vizEnt.DeathThread = ForkThread(self.VisibleEntityDeathThread, vizEnt, curRadius)
    end,
    
    VisibleEntityDeathThread = function(entity, curRadius)
        local lifetime = 0
        while lifetime < 30 do
            if curRadius > 1 then
                curRadius = curRadius - 1
                if curRadius < 1 then
                    curRadius = 1
                end
                entity:SetIntelRadius('vision', curRadius)
            end
            lifetime = lifetime + 2
            WaitSeconds(0.1)
        end
        entity:Destroy()
    end,

    OnIntelEnabled = function(self)
        self.ExpandingVisionDisableCount = self.ExpandingVisionDisableCount - 1
        if self.ExpandingVisionDisableCount == 0 then
            if self.OmniEffectsBag then
                for k, v in self.OmniEffectsBag do
                    v:Destroy()
                end
		        self.OmniEffectsBag = {}
		    end
            for k, v in CSoothSayerAmbient do
                table.insert( self.OmniEffectsBag, CreateAttachedEmitter(self, 'XRB3301', self:GetArmy(), v) )
            end   		            
            ChangeState( self, self.ExpandingVision )
        end
    end,

    OnIntelDisabled = function(self)
        self.ExpandingVisionDisableCount = self.ExpandingVisionDisableCount + 1
        if self.ExpandingVisionDisableCount == 1 then
            if self.OmniEffectsBag then
                for k, v in self.OmniEffectsBag do
                    v:Destroy()
                end
		        self.OmniEffectsBag = {}
		    end
            ChangeState( self, self.ContractingVision )
        end
    end,
    
    ExpandingVision = State {
        Main = function(self)
            WaitSeconds(0.1)
            while true do
                if self:GetResourceConsumed() ~= 1 then
                    self.ExpandingVisionEnergyCheck = true
                    self:OnIntelDisabled()
                end
                local curRadius = self:GetIntelRadius('vision')
                local targetRadius = self:GetBlueprint().Intel.MaxVisionRadius
                if curRadius < targetRadius then
                    curRadius = curRadius + 1
                    if curRadius >= targetRadius then
                        self:SetIntelRadius('vision', targetRadius)
                    else
                        self:SetIntelRadius('vision', curRadius)
                    end
                end
                WaitSeconds(0.2)
            end
        end,
    },
    
    ContractingVision = State {
        Main = function(self)
            while true do
                if self:GetResourceConsumed() == 1 then
                    if self.ExpandingVisionEnergyCheck then
                        self:OnIntelEnabled()
                    else
                        self:OnIntelDisabled()
                        self.ExpandingVisionEnergyCheck = true
                    end
                end
                local curRadius = self:GetIntelRadius('vision')
                local targetRadius = self:GetBlueprint().Intel.MinVisionRadius
                if curRadius > targetRadius then
                    curRadius = curRadius - 1
                    if curRadius <= targetRadius then
                        self:SetIntelRadius('vision', targetRadius)
                    else
                        self:SetIntelRadius('vision', curRadius)
                    end
                end
                WaitSeconds(0.2)
            end
        end,
    },
}

TypeClass = XRB3301