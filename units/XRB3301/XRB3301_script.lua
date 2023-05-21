-- File     :  /cdimage/units/XRB3301/XRB3301_script.lua
-- Author(s):  Dru Staltman, Ted Snook
-- Summary  :  Cybran Vision unit thing
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CRadarUnit = import("/lua/cybranunits.lua").CRadarUnit
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker
local CSoothSayerAmbient = import("/lua/effecttemplates.lua").CSoothSayerAmbient

---@class XRB3301 : CRadarUnit
XRB3301 = ClassUnit(CRadarUnit) {
    IntelEffects = {
        {
            Bones = { 'Emitter', },
            Offset = { 0, 0, 4, },
            Type = 'Jammer01',
        },
    },
    ExpandingVisionDisableCount = 0,

    OnCreate = function(self)
        CRadarUnit.OnCreate(self)
        self.OmniEffectsBag = TrashBag()
    end,

    DestroyAllTrashBags = function(self)
        CRadarUnit.DestroyAllTrashBags(self)
        self.OmniEffectsBag:Destroy()
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CRadarUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.ExpandingVision)

        for k, v in CSoothSayerAmbient do
            self.OmniEffectsBag:Add(CreateAttachedEmitter(self, 'XRB3301', self.Army, v))
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CRadarUnit.OnKilled(self, instigator, type, overkillRatio)

        local curRadius = self:GetIntelRadius('vision')
        local position = self:GetPosition()
        local army = self:GetAIBrain():GetArmyIndex()

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
            LOG("Tick!")
            if curRadius > 1 then
                curRadius = curRadius - 1
                if curRadius < 1 then
                    break
                end
                entity:SetIntelRadius('vision', curRadius)
            end
            lifetime = lifetime + 1
            WaitTicks(1)
        end
        entity:Destroy()
    end,

    OnIntelEnabled = function(self, intel)
        self.ExpandingVisionDisableCount = self.ExpandingVisionDisableCount - 1
        if self.ExpandingVisionDisableCount == 0 then
            self.OmniEffectsBag:Destroy()
            for k, v in CSoothSayerAmbient do
                self.OmniEffectsBag:Add(CreateAttachedEmitter(self, 'XRB3301', self.Army, v))
            end
            ChangeState(self, self.ExpandingVision)
        end
    end,

    OnIntelDisabled = function(self, intel)
        self.ExpandingVisionDisableCount = self.ExpandingVisionDisableCount + 1
        if self.ExpandingVisionDisableCount == 1 then
            self.OmniEffectsBag:Destroy()
            ChangeState(self, self.ContractingVision)
        end
    end,

    ExpandingVision = State {
        Main = function(self)
            WaitTicks(1)
            while true do
                if self:GetResourceConsumed() ~= 1 then
                    self.ExpandingVisionEnergyCheck = true
                    self:OnIntelDisabled()
                end
                local curRadius = self:GetIntelRadius('vision')
                local targetRadius = self.Blueprint.Intel.MaxVisionRadius
                if curRadius < targetRadius then
                    curRadius = curRadius + 1
                    if curRadius >= targetRadius then
                        self:SetIntelRadius('vision', targetRadius)
                    else
                        self:SetIntelRadius('vision', curRadius)
                    end
                end
                WaitTicks(1)
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
                local targetRadius = self.Blueprint.Intel.MinVisionRadius
                if curRadius > targetRadius then
                    curRadius = curRadius - 1
                    if curRadius <= targetRadius then
                        self:SetIntelRadius('vision', targetRadius)
                    else
                        self:SetIntelRadius('vision', curRadius)
                    end
                end
                WaitTicks(1)
            end
        end,
    },
}

TypeClass = XRB3301
