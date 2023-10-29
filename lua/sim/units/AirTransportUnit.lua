
local AirUnit = import("/lua/sim/units/airunit.lua").AirUnit
local BaseTransport = import("/lua/sim/units/components/transportunitcomponent.lua").BaseTransport

---@class AirTransport: AirUnit, BaseTransport
---@field slots table<Bone, Unit>
AirTransport = ClassUnit(AirUnit, BaseTransport) {
    ---@param self AirTransport
    OnCreate = function(self)
        AirUnit.OnCreate(self)
        self.slots = {}
        self.transData = {}
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        AirUnit.OnTransportAttach(self, attachBone, unit)
        BaseTransport.OnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AirTransport
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        AirUnit.OnTransportDetach(self, attachBone, unit)
        BaseTransport.OnTransportDetach(self, attachBone, unit)
    end,

    OnAttachedKilled = function(self, attached)
        AirUnit.OnAttachedKilled(self, attached)
        BaseTransport.OnAttachedKilled(self, attached)
    end,

    ---@param self AirTransport
    OnStartTransportLoading = function(self)
        AirUnit.OnStartTransportLoading(self)
        BaseTransport.OnStartTransportLoading(self)
    end,

    ---@param self AirTransport
    OnStopTransportLoading = function(self)
        AirUnit.OnStopTransportLoading(self)
        BaseTransport.OnStopTransportLoading(self)
    end,

    ---@param self AirTransport
    DestroyedOnTransport = function(self)
        -- AirUnit.DestroyedOnTransport(self)
        BaseTransport.DestroyedOnTransport(self)
    end,

    ---@param self AirTransport
    ---@param ... any
    Kill = function(self, ...) -- Hook the engine 'Kill' command to flag cargo properly
         -- The arguments are (self, instigator, type, overkillRatio) but we can't just use normal arguments or AirUnit.Kill will complain if type is nil (which does happen)
        local instigator = arg[1]
        self:FlagCargo(not instigator or not IsUnit(instigator))
        AirUnit.Kill(self, unpack(arg))
    end,

    -- Override OnImpact to kill all cargo
    ---@param self AirTransport
    ---@param with AirTransport
    OnImpact = function(self, with)
        if self.GroundImpacted then return end

        self:KillCrashedCargo()
        AirUnit.OnImpact(self, with)
    end,

    ---@param self AirTransport
    ---@param loading boolean
    OnStorageChange = function(self, loading)
        AirUnit.OnStorageChange(self, loading)
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