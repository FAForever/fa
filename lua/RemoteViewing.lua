--****************************************************************************
--**
--**  File     :  /lua/RemoteViewing.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  File that creates in units ability to create Remote Entities
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

-- TODO: make sure each new instance is using a previous metatable
function RemoteViewing(SuperClass)
    return Class(SuperClass) {
        OnCreate = function(self)
            SuperClass.OnCreate(self)
            self.RemoteViewingData = {}
            self.RemoteViewingData.RemoteViewingFunctions = {}
            self.RemoteViewingData.DisableCounter = 0
            self.RemoteViewingData.IntelButton = true
        end,

        OnStopBeingBuilt = function(self,builder,layer)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self:SetMaintenanceConsumptionInactive()
            SuperClass.OnStopBeingBuilt(self,builder,layer)
        end,

        OnKilled = function(self, instigator, type, overkillRatio)
            SuperClass.OnKilled(self, instigator, type, overkillRatio)
            if self.RemoteViewingData.Satellite then
                self.RemoteViewingData.Satellite:Destroy()
            end
            self:SetMaintenanceConsumptionInactive()
        end,

        DisableRemoteViewingButtons = function(self)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self.Sync.Abilities.TargetLocation.Active = false
            self:RemoveToggleCap('RULEUTC_IntelToggle')
        end,

        EnableRemoteViewingButtons = function(self)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self.Sync.Abilities.TargetLocation.Active = true
            self:AddToggleCap('RULEUTC_IntelToggle')
        end,

        OnTargetLocation = function(self, location)
            -- Initial energy drain here - we drain resources instantly when an eye is relocated (including initial move)
            local aiBrain = self:GetAIBrain()
            local bp = self:GetBlueprint()
            local have = aiBrain:GetEconomyStored('ENERGY')
            local need = bp.Economy.InitialRemoteViewingEnergyDrain
            if not ( have > need ) then
                return
            end

            -- Drain economy here
            aiBrain:TakeResource( 'ENERGY', bp.Economy.InitialRemoteViewingEnergyDrain )

            self.RemoteViewingData.VisibleLocation = location
            self:CreateVisibleEntity()
        end,

        CreateVisibleEntity = function(self)
            -- Only give a visible area if we have a location and intel button enabled
            if not self.RemoteViewingData.VisibleLocation then
                self:SetMaintenanceConsumptionInactive()
                return
            end

            if self.RemoteViewingData.VisibleLocation and self.RemoteViewingData.DisableCounter == 0 and self.RemoteViewingData.IntelButton then
                local bp = self:GetBlueprint()
                self:SetMaintenanceConsumptionActive()
                -- Create new visible area
                if not self.RemoteViewingData.Satellite then
                    local spec = {
                        X = self.RemoteViewingData.VisibleLocation[1],
                        Z = self.RemoteViewingData.VisibleLocation[3],
                        Radius = bp.Intel.RemoteViewingRadius,
                        LifeTime = -1,
                        Omni = false,
                        Radar = false,
                        Vision = true,
                        WaterVision = true,
                        Army = self.Army,
                    }
                    self.RemoteViewingData.Satellite = VizMarker(spec)
                    self.Trash:Add(self.RemoteViewingData.Satellite)
                else
                    -- Move and reactivate old visible area
                    if not self.RemoteViewingData.Satellite:BeenDestroyed() then
                        Warp( self.RemoteViewingData.Satellite, self.RemoteViewingData.VisibleLocation )
                        self.RemoteViewingData.Satellite:EnableIntel('Omni')
                        self.RemoteViewingData.Satellite:EnableIntel('Radar')
                        self.RemoteViewingData.Satellite:EnableIntel('Vision')
                        self.RemoteViewingData.Satellite:EnableIntel('WaterVision')
                    end
                end
                -- monitor resources
                if self.RemoteViewingData.ResourceThread then
                    self.RemoteViewingData.ResourceThread:Destroy()
                end
                self.RemoteViewingData.ResourceThread = self:ForkThread(self.DisableResourceMonitor)
            end
        end,

        DisableVisibleEntity = function(self)
            -- visible entity already off
            if self.RemoteViewingData.DisableCounter > 1 then return end
            -- disable vis entity and monitor resources
            if not self.Dead and self.RemoteViewingData.Satellite then
                self.RemoteViewingData.Satellite:DisableIntel('Omni')
                self.RemoteViewingData.Satellite:DisableIntel('Radar')
                self.RemoteViewingData.Satellite:DisableIntel('Vision')
                self.RemoteViewingData.Satellite:DisableIntel('WaterVision')
            end
        end,

        OnIntelEnabled = function(self, intel)
            -- Make sure the button is only calculated once rather than once per possible intel type
            if not self.RemoteViewingData.IntelButton then
                self.RemoteViewingData.IntelButton = true
                self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter - 1
                self:CreateVisibleEntity()
            end
            SuperClass.OnIntelEnabled(self, intel)
        end,

        OnIntelDisabled = function(self, intel)
            -- make sure button is only calculated once rather than once per possible intel type
            if self.RemoteViewingData.IntelButton then
                self.RemoteViewingData.IntelButton = false
                self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter + 1
                self:DisableVisibleEntity()
            end
            SuperClass.OnIntelDisabled(self, intel)
        end,

        DisableResourceMonitor = function(self)
            WaitSeconds(0.5)
            local fraction = self:GetResourceConsumed()
            while fraction == 1 do
                WaitSeconds(0.5)
                fraction = self:GetResourceConsumed()
            end
            if self.RemoteViewingData.IntelButton then
                self:DisableVisibleEntity()
                if fraction > 0 then
                    self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter + 1
                    self.RemoteViewingData.ResourceThread = self:ForkThread(self.EnableResourceMonitor)
                end
            end
        end,

        EnableResourceMonitor = function(self)
            local recharge = self:GetBlueprint().Intel.ReactivateTime or 10
            WaitSeconds(recharge)
            self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter - 1
            self:CreateVisibleEntity()
        end,
    }
end
