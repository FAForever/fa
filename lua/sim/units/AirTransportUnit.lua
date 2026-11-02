local AirUnit = import("/lua/sim/units/airunit.lua").AirUnit
local AirUnitOnCreate = AirUnit.OnCreate
local AirUnitOnMotionHorzEventChange = AirUnit.OnMotionHorzEventChange
local AirUnitOnTransportAttach = AirUnit.OnTransportAttach
local AirUnitOnTransportDetach = AirUnit.OnTransportDetach
local AirUnitOnAttachedKilled = AirUnit.OnAttachedKilled
local AirUnitOnStartTransportLoading = AirUnit.OnStartTransportLoading
local AirUnitOnStopTransportLoading = AirUnit.OnStopTransportLoading
local AirUnitKill = AirUnit.Kill
local AirUnitOnImpact = AirUnit.OnImpact
local AirUnitOnStorageChange = AirUnit.OnStorageChange

local BaseTransport = import("/lua/sim/units/components/transportunitcomponent.lua").BaseTransport
local BaseTransportOnTransportAttach = BaseTransport.OnTransportAttach
local BaseTransportOnTransportDetach = BaseTransport.OnTransportDetach
local BaseTransportOnAttachedKilled = BaseTransport.OnAttachedKilled
local BaseTransportOnStartTransportLoading = BaseTransport.OnStartTransportLoading
local BaseTransportOnStopTransportLoading = BaseTransport.OnStopTransportLoading
local BaseTransportDestroyedOnTransport = BaseTransport.DestroyedOnTransport

local UnloadCommands = {
    [24] = true, -- TransportUnloadUnits
    [25] = true, -- TransportUnloadSpecificUnits
    [37] = true, -- AssistMove
}

-- Horizontal distance in ogrids within which we can still unload cargo
local HorzUnloadMargin = 2.5

-- Factor by which to multiply TransportHoverHeight when determining if we can unload cargo
local VertUnloadFactor = 1.5

---@class AirTransport: AirUnit, BaseTransport
---@field slots table<Bone, Unit>
---@field GroundImpacted boolean
AirTransport = ClassUnit(AirUnit, BaseTransport) {
    ---@param self AirTransport
    OnCreate = function(self)
        AirUnitOnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    ---@param self AirTransport
    ---@param new HorizontalMovementState
    ---@param old HorizontalMovementState
    OnMotionHorzEventChange = function(self, new, old)
        AirUnitOnMotionHorzEventChange(self, new, old)

        -- Unloading the units of a transport has always been a bit sketchy. The Transport would take forever to get
        -- the signal to actually drop the units. We discovered that aborting the navigation while we're trying to
        -- unload is the signal that the engine uses to drop the units. We help the engine here a little bit by
        -- increasing the threshold at which the transport can start dropping the units

        if new == 'Stopped' and (not self.Dead or IsDestroyed(self)) then
            local command = self:GetCommandQueue()[1]
            if UnloadCommands[command.commandType] then
                local navigator = self:GetNavigator()
                local targetPos = navigator:GetCurrentTargetPos()
                local pos = self:GetPosition()

                -- Don't drop if we're too far away from the target
                if not targetPos
                    or VDist2(pos[1], pos[3], command.x, command.z) > 20
                    or VDist2(pos[1], pos[3], targetPos[1], targetPos[3]) > HorzUnloadMargin
                    or pos[2] - targetPos[2] > (self.Blueprint.Air.TransportHoverHeight or 6) * VertUnloadFactor
                then
                    return
                end

                -- Tell our navigator to abort the move
                -- this has the effect of causing the next unload command to be executed immediately
                navigator:AbortMove()
            end
        end
    end,

    ---@param self AirTransport
    ReduceTransportSpeed = function(self)
        local transportspeed = self.Blueprint.Air.MaxAirspeed
        -- add a minimum speed of 30% base to prevent breaking the transport with a zero or negative speed multiplier
        local maxWeight = transportspeed - transportspeed * 0.3
        local totalweight = 0
        for _, unit in self:GetCargo() do
            local reduction = unit.Blueprint.Physics.TransportSpeedReduction
            if not reduction then continue end
            totalweight = totalweight + reduction

            if totalweight > maxWeight then
                totalweight = maxWeight
                break
            end
        end
        self:SetSpeedMult(1 - (totalweight / transportspeed))
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        AirUnitOnTransportAttach(self, attachBone, unit)
        BaseTransportOnTransportAttach(self, attachBone, unit)
        self:ReduceTransportSpeed()
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        AirUnitOnTransportDetach(self, attachBone, unit)
        BaseTransportOnTransportDetach(self, attachBone, unit)
        self:ReduceTransportSpeed()
    end,

    OnAttachedKilled = function(self, attached)
        AirUnitOnAttachedKilled(self, attached)
        BaseTransportOnAttachedKilled(self, attached)
    end,

    ---@param self AirTransport
    OnStartTransportLoading = function(self)
        AirUnitOnStartTransportLoading(self)
        BaseTransportOnStartTransportLoading(self)
    end,

    ---@param self AirTransport
    OnStopTransportLoading = function(self)
        AirUnitOnStopTransportLoading(self)
        BaseTransportOnStopTransportLoading(self)
    end,

    ---@param self AirTransport
    DestroyedOnTransport = function(self)
        -- AirUnit.DestroyedOnTransport(self)
        BaseTransportDestroyedOnTransport(self)
    end,

    ---@param self AirTransport
    ---@param instigator Unit
    ---@param damageType? DamageType
    ---@param excessDamageRatio? number
    Kill = function(self, instigator, damageType, excessDamageRatio)
        -- handle the cargo killing
        -- skip for transports inside other transports, as our KillCargo will have
        -- already been recursively called from the parent transports KillCargo call
        if damageType ~= "TransportDamage" then
            self:KillCargo(instigator)
        end
        -- these need to be defined for certain behaviors (like ctrl-k) to function
        damageType = damageType or "Normal"
        excessDamageRatio = excessDamageRatio or 0
        AirUnitKill(self, instigator, damageType, excessDamageRatio)
    end,

    -- Override OnImpact to dispense with our cargo
    ---@param self AirTransport
    ---@param with ImpactType
    OnImpact = function(self, with)
        if self.GroundImpacted then return end
        self:ImpactCargo()
        AirUnitOnImpact(self, with)
    end,

    ---@param self AirTransport
    ---@param loading boolean
    OnStorageChange = function(self, loading)
        AirUnitOnStorageChange(self, loading)
        for k, v in self:GetCargo() do
            v:OnStorageChange(loading)
        end
    end,
}
