-- File     :  /lua/RemoteViewing.lua
-- Author(s):  Dru Staltman
-- Summary  :  File that creates in units ability to create Remote Entities
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------
local VizMarker = import("/lua/sim/VizMarker.lua").VizMarker

-- TODO: make sure each new instance is using a previous metatable
function RemoteViewing(SuperClass)
    return Class(SuperClass) {

        OnCreate = function(self)
            SuperClass.OnCreate(self)
            local remoteViewData = self.RemoteViewingData

            remoteViewData = {}
            remoteViewData.RemoteViewingFunctions = {}
            remoteViewData.DisableCounter = 0
            remoteViewData.IntelButton = true
        end,

        OnStopBeingBuilt = function(self, builder, layer)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self:SetMaintenanceConsumptionInactive()
            SuperClass.OnStopBeingBuilt(self, builder, layer)
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
            local bp = self.Blueprint
            local have = aiBrain:GetEconomyStored('ENERGY')
            local need = bp.Economy.InitialRemoteViewingEnergyDrain
            if not (have > need) then
                return
            end

            -- Drain economy here
            aiBrain:TakeResource('ENERGY', bp.Economy.InitialRemoteViewingEnergyDrain)

            self.RemoteViewingData.VisibleLocation = location
            self:CreateVisibleEntity()
        end,

        CreateVisibleEntity = function(self)
            local remoteViewData = self.RemoteViewingData

            -- Only give a visible area if we have a location and intel button enabled
            if not remoteViewData.VisibleLocation then
                self:SetMaintenanceConsumptionInactive()
                return
            end

            if remoteViewData.VisibleLocation and remoteViewData.DisableCounter == 0 and
                remoteViewData.IntelButton then
                local bp = self.Blueprint
                self:SetMaintenanceConsumptionActive()
                -- Create new visible area
                if not remoteViewData.Satellite then
                    local spec = {
                        X = remoteViewData.VisibleLocation[1],
                        Z = remoteViewData.VisibleLocation[3],
                        Radius = bp.Intel.RemoteViewingRadius,
                        LifeTime = -1,
                        Omni = false,
                        Radar = false,
                        Vision = true,
                        WaterVision = true,
                        Army = self.Army,
                    }
                    remoteViewData.Satellite = VizMarker(spec)
                    self.Trash:Add(remoteViewData.Satellite)
                else
                    -- Move and reactivate old visible area
                    if not remoteViewData.Satellite:BeenDestroyed() then
                        Warp(remoteViewData.Satellite, remoteViewData.VisibleLocation)
                        remoteViewData.Satellite:EnableIntel('Omni')
                        remoteViewData.Satellite:EnableIntel('Radar')
                        remoteViewData.Satellite:EnableIntel('Vision')
                        remoteViewData.Satellite:EnableIntel('WaterVision')
                    end
                end
                -- monitor resources
                if remoteViewData.ResourceThread then
                    remoteViewData.ResourceThread:Destroy()
                end
                remoteViewData.ResourceThread = self:ForkThread(self.DisableResourceMonitor)
            end
        end,

        DisableVisibleEntity = function(self)
            local remoteViewData = self.RemoteViewingData
            -- visible entity already off
            if remoteViewData.DisableCounter > 1 then return end
            -- disable vis entity and monitor resources
            if not self.Dead and remoteViewData.Satellite then
                remoteViewData.Satellite:DisableIntel('Omni')
                remoteViewData.Satellite:DisableIntel('Radar')
                remoteViewData.Satellite:DisableIntel('Vision')
                remoteViewData.Satellite:DisableIntel('WaterVision')
            end
        end,

        OnIntelEnabled = function(self, intel)
            local remoteViewData = self.RemoteViewingData
            -- Make sure the button is only calculated once rather than once per possible intel type
            if not remoteViewData.IntelButton then
                remoteViewData.IntelButton = true
                remoteViewData.DisableCounter = remoteViewData.DisableCounter - 1
                self:CreateVisibleEntity()
            end
            SuperClass.OnIntelEnabled(self, intel)
        end,

        OnIntelDisabled = function(self, intel)
            local remoteViewData = self.RemoteViewingData
            -- make sure button is only calculated once rather than once per possible intel type
            if remoteViewData.IntelButton then
                remoteViewData.IntelButton = false
                remoteViewData.DisableCounter = remoteViewData.DisableCounter + 1
                self:DisableVisibleEntity()
            end
            SuperClass.OnIntelDisabled(self, intel)
        end,

        DisableResourceMonitor = function(self)
            local remoteViewData = self.RemoteViewingData
            WaitSeconds(0.5)
            local fraction = self:GetResourceConsumed()
            while fraction == 1 do
                WaitSeconds(0.5)
                fraction = self:GetResourceConsumed()
            end
            if remoteViewData.IntelButton then
                remoteViewData.DisableCounter = remoteViewData.DisableCounter + 1
                remoteViewData.ResourceThread = self:ForkThread(self.EnableResourceMonitor)
                self:DisableVisibleEntity()
            end
        end,

        EnableResourceMonitor = function(self)
            local recharge = self.Blueprint.Intel.ReactivateTime or 10
            WaitSeconds(recharge)
            self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter - 1
            self:CreateVisibleEntity()
        end,
    }
end
