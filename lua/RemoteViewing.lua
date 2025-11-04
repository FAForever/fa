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

-- TODO: Fix the RemoteViewingUnit class annotation always taking definitions from the Unit class instead of the base class.

---@class RemoteViewingData
---@field RemoteViewingFunctions table
---@field DisableCounter number
---@field IntelButton boolean
---@field Satellite VizMarker
---@field PendingVisibleLocation Vector
---@field VisibleLocation Vector

---@generic T: Unit
---@param SuperClass T | Unit
---@return T | RemoteViewingUnit
function RemoteViewing(SuperClass)
    ---@class RemoteViewingUnit: Unit
    ---@field RemoteViewingData RemoteViewingData
    return Class(SuperClass) {
        ---@param self RemoteViewingUnit
        OnCreate = function(self)
            SuperClass.OnCreate(self)
            self.RemoteViewingData = {}
            self.RemoteViewingData.RemoteViewingFunctions = {}
            self.RemoteViewingData.DisableCounter = 0
            self.RemoteViewingData.IntelButton = true
        end,

        ---@param self RemoteViewingUnit
        ---@param builder Unit
        ---@param layer Layer
        OnStopBeingBuilt = function(self, builder, layer)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self:SetMaintenanceConsumptionInactive()
            SuperClass.OnStopBeingBuilt(self, builder, layer)
        end,

        ---@param self RemoteViewingUnit
        ---@param instigator Unit
        ---@param type DamageType
        ---@param overkillRatio number
        OnKilled = function(self, instigator, type, overkillRatio)
            SuperClass.OnKilled(self, instigator, type, overkillRatio)
            if self.RemoteViewingData.Satellite then
                self.RemoteViewingData.Satellite:Destroy()
            end
            self:SetMaintenanceConsumptionInactive()
        end,

        ---@param self RemoteViewingUnit
        DisableRemoteViewingButtons = function(self)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self.Sync.Abilities.TargetLocation.Active = false
            self:RemoveToggleCap('RULEUTC_IntelToggle')
        end,

        ---@param self RemoteViewingUnit
        EnableRemoteViewingButtons = function(self)
            self.Sync.Abilities = self:GetBlueprint().Abilities
            self.Sync.Abilities.TargetLocation.Active = true
            self:AddToggleCap('RULEUTC_IntelToggle')
        end,

        ---@param self RemoteViewingUnit
        TargetLocationThread = function(self)
            local Cost = CreateEconomyEvent(self, self:GetBlueprint().Economy.InitialRemoteViewingEnergyDrain * (self.EnergyMaintAdjMod or 1), 0, 1, self.SetWorkProgress)
            WaitFor(Cost)
            self:SetWorkProgress(0.0)
            RemoveEconomyEvent(self, Cost)
            self:RequestRefreshUI()
            self.RemoteViewingData.VisibleLocation = self.RemoteViewingData.PendingVisibleLocation
            self.RemoteViewingData.PendingVisibleLocation = nil
            self:CreateVisibleEntity()
        end,

        ---@param self RemoteViewingUnit
        ---@param location Vector
        OnTargetLocation = function(self, location)
            if self.RemoteViewingData.PendingVisibleLocation then
                self.RemoteViewingData.PendingVisibleLocation = location
            else
                self.RemoteViewingData.PendingVisibleLocation = location
                self:ForkThread(self.TargetLocationThread)
            end
        end,

        ---@param self RemoteViewingUnit
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
                        Warp(self.RemoteViewingData.Satellite, self.RemoteViewingData.VisibleLocation)
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

        ---@param self RemoteViewingUnit
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

        ---@param self RemoteViewingUnit
        ---@param intel IntelType
        OnIntelEnabled = function(self, intel)
            -- Make sure the button is only calculated once rather than once per possible intel type
            if not self.RemoteViewingData.IntelButton then
                self.RemoteViewingData.IntelButton = true
                self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter - 1
                self:CreateVisibleEntity()
            end
            SuperClass.OnIntelEnabled(self, intel)
        end,

        ---@param self RemoteViewingUnit
        ---@param intel IntelType
        OnIntelDisabled = function(self, intel)
            -- make sure button is only calculated once rather than once per possible intel type
            if self.RemoteViewingData.IntelButton then
                self.RemoteViewingData.IntelButton = false
                self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter + 1
                self:DisableVisibleEntity()
            end
            SuperClass.OnIntelDisabled(self, intel)
        end,

        ---@param self RemoteViewingUnit
        DisableResourceMonitor = function(self)
            WaitSeconds(0.5)
            local fraction = self:GetResourceConsumed()
            while fraction == 1 do
                WaitSeconds(0.5)
                fraction = self:GetResourceConsumed()
            end
            if self.RemoteViewingData.IntelButton then
                self:DisableVisibleEntity()
                self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter + 1
                self.RemoteViewingData.ResourceThread = self:ForkThread(self.EnableResourceMonitor)
            end
        end,

        ---@param self RemoteViewingUnit
        EnableResourceMonitor = function(self)
            local recharge = self:GetBlueprint().Intel.ReactivateTime or 10
            WaitSeconds(recharge)
            self.RemoteViewingData.DisableCounter = self.RemoteViewingData.DisableCounter - 1
            self:CreateVisibleEntity()
        end,
    }
end
