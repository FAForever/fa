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
---@field RemoteViewingFunctions table unused
---@field DisableCounter integer
---@field IntelButton boolean
---@field Satellite? VizMarker
---@field PendingVisibleLocation? Vector
---@field VisibleLocation Vector

---@generic T: Unit
---@param SuperClass T | Unit
---@return T | RemoteViewingUnit
function RemoteViewing(SuperClass)
    ---@class RemoteViewingUnit : Unit
    ---@field RemoteViewingData RemoteViewingData
    return Class(SuperClass) {
        ---@param self RemoteViewingUnit
        OnCreate = function(self)
            SuperClass.OnCreate(self)

            self.RemoteViewingData = {
                RemoteViewingFunctions = {},
                DisableCounter = 0,
                IntelButton = true,
            }
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

            local data = self.RemoteViewingData
            if data.Satellite then
                data.Satellite:Destroy()
                data.Satellite = nil
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
            local drain = self:GetBlueprint().Economy.InitialRemoteViewingEnergyDrain
            local event = CreateEconomyEvent(self, drain * (self.EnergyMaintAdjMod or 1), 0, 1, self.SetWorkProgress)
            WaitFor(event)

            self:SetWorkProgress(0.0)
            RemoveEconomyEvent(self, event)
            self:RequestRefreshUI()
            self.RemoteViewingData.VisibleLocation = self.RemoteViewingData.PendingVisibleLocation
            self.RemoteViewingData.PendingVisibleLocation = nil
            self:CreateVisibleEntity()
        end,

        ---@param self RemoteViewingUnit
        ---@param location Vector
        OnTargetLocation = function(self, location)
            local data = self.RemoteViewingData
            if data.PendingVisibleLocation then
                data.PendingVisibleLocation = location
            else
                data.PendingVisibleLocation = location
                self:ForkThread(self.TargetLocationThread)
            end
        end,

        ---@param self RemoteViewingUnit
        CreateVisibleEntity = function(self)
            local data = self.RemoteViewingData
            -- Only give a visible area if we have a location and intel button enabled
            if not data.VisibleLocation then
                self:SetMaintenanceConsumptionInactive()
                return
            end
            if data.DisableCounter ~= 0 or not data.IntelButton then
                return
            end

            self:SetMaintenanceConsumptionActive()
            local satellite = data.Satellite
            -- Create new visible area
            if not satellite then
                satellite = VizMarker{
                    X = data.VisibleLocation[1],
                    Z = data.VisibleLocation[3],
                    Radius = self:GetBlueprint().Intel.RemoteViewingRadius,
                    LifeTime = -1,
                    Omni = false,  -- unfortunately, these are here to stay because `VizMarker`
                    Radar = false, -- checks against `false` instead of something sensical
                    Vision = true,
                    WaterVision = true,
                    Army = self.Army,
                }
                data.Satellite = satellite
                self.Trash:Add(satellite)
            else
                -- Move and reactivate old visible area
                if not satellite:BeenDestroyed() then
                    Warp(satellite, data.VisibleLocation)
                    satellite:EnableIntel('Omni')
                    satellite:EnableIntel('Radar')
                    satellite:EnableIntel('Vision')
                    satellite:EnableIntel('WaterVision')
                end
            end

            -- monitor resources
            if data.ResourceThread then
                data.ResourceThread:Destroy()
            end
            data.ResourceThread = self:ForkThread(self.DisableResourceMonitor)
        end,

        ---@param self RemoteViewingUnit
        DisableVisibleEntity = function(self)
            local data = self.RemoteViewingData
            -- visible entity already off
            if data.DisableCounter > 1 or self.Dead then
                return
            end
            -- disable vis entity and monitor resources
            local satellite = data.Satellite
            if satellite then
                satellite:DisableIntel('Omni')
                satellite:DisableIntel('Radar')
                satellite:DisableIntel('Vision')
                satellite:DisableIntel('WaterVision')
            end
        end,

        ---@param self RemoteViewingUnit
        ---@param intel IntelType
        OnIntelEnabled = function(self, intel)
            local data = self.RemoteViewingData
            -- Make sure the button is only calculated once rather than once per possible intel type
            if not data.IntelButton then
                data.IntelButton = true
                data.DisableCounter = data.DisableCounter - 1
                self:CreateVisibleEntity()
            end
            SuperClass.OnIntelEnabled(self, intel)
        end,

        ---@param self RemoteViewingUnit
        ---@param intel IntelType
        OnIntelDisabled = function(self, intel)
            local data = self.RemoteViewingData
            -- make sure button is only calculated once rather than once per possible intel type
            if data.IntelButton then
                data.IntelButton = false
                data.DisableCounter = data.DisableCounter + 1
                self:DisableVisibleEntity()
            end
            SuperClass.OnIntelDisabled(self, intel)
        end,

        ---@param self RemoteViewingUnit
        DisableResourceMonitor = function(self)
            repeat
                WaitSeconds(0.5)
            until self:GetResourceConsumed() ~= 1.0

            local data = self.RemoteViewingData
            if data.IntelButton then
                self:DisableVisibleEntity()
                data.DisableCounter = data.DisableCounter + 1
                data.ResourceThread = self:ForkThread(self.EnableResourceMonitor)
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
