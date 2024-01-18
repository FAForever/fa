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
AirTransport = ClassUnit(AirUnit, BaseTransport) {
    ---@param self AirTransport
    OnCreate = function(self)
        AirUnitOnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    ---@param self AirTransport
    ---@param new string
    ---@param old string
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
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        AirUnitOnTransportAttach(self, attachBone, unit)
        BaseTransportOnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        AirUnitOnTransportDetach(self, attachBone, unit)
        BaseTransportOnTransportDetach(self, attachBone, unit)
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
    ---@param instigator? Unit
    ---@param damageType? DamageType
    ---@param excessDamageRatio? number
    Kill = function(self, instigator, damageType, excessDamageRatio)
        -- needs to be defined
        damageType = damageType or "Normal"
        excessDamageRatio = excessDamageRatio or 0

        self:FlagCargo(not instigator or not IsUnit(instigator))
        AirUnitKill(self, instigator, damageType, excessDamageRatio)
    end,

    -- Override OnImpact to kill all cargo
    ---@param self AirTransport
    ---@param with AirTransport
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        self:KillCrashedCargo()
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

    -- Flags cargo that it's been killed while in a transport
    ---@param self AirTransport
    ---@param suicide boolean
    FlagCargo = function(self, suicide)
        if self.Dead then return end -- Bail out early from overkill damage when already dead to avoid crashing

        if not suicide then -- If the transport is self destructed, let its contents be self destructed separately
            self:SaveCargoMass()
        end
        self.cargo = {}
        local cargo = self:GetCargo()
        for _, unit in cargo or {} do
            if EntityCategoryContains(categories.TRANSPORTATION, unit) then -- Kill the contents of a transport in a transport, however that happened
                local unitCargo = unit:GetCargo()
                for k, subUnit in unitCargo do
                    subUnit:Kill()
                end
            end
            if not EntityCategoryContains(categories.COMMAND, unit) then
                unit.willBeKilledByTransport = true
                unit.killedInTransport = true
                table.insert(self.cargo, unit)
            end
        end
    end,

    ---@param self BaseTransport
    KillCrashedCargo = function(self)
        if self:BeenDestroyed() then return end

        for _, unit in self.cargo or {} do
            if not unit:BeenDestroyed() then
                unit.DeathWeaponEnabled = false -- Units at this point have no weapons for some reason. Trying to fire one crashes the game.
                unit:OnKilled(nil, '', 0)
            end
        end
    end,
}
