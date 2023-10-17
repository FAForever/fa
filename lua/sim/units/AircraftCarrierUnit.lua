
local SeaUnit = import("/lua/sim/units/seaunit.lua").SeaUnit
local BaseTransport = import("/lua/sim/units/components/transportunitcomponent.lua").BaseTransport

---@class AircraftCarrier : SeaUnit, BaseTransport
AircraftCarrier = ClassUnit(SeaUnit, BaseTransport) {

    DisableIntelOfCargo = true,

    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportAttach = function(self, attachBone, unit)
        SeaUnit.OnTransportAttach(self, attachBone, unit)
        BaseTransport.OnTransportAttach(self, attachBone, unit)
    end,

    ---@param self AircraftCarrier
    ---@param attachBone Bone
    ---@param unit Unit
    OnTransportDetach = function(self, attachBone, unit)
        SeaUnit.OnTransportDetach(self, attachBone, unit)
        BaseTransport.OnTransportDetach(self, attachBone, unit)
    end,

    OnAttachedKilled = function(self, attached)
        SeaUnit.OnAttachedKilled(self, attached)
        BaseTransport.OnAttachedKilled(self, attached)
    end,

    ---@param self AircraftCarrier
    OnStartTransportLoading = function(self)
        SeaUnit.OnStartTransportLoading(self)
        BaseTransport.OnStartTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    OnStopTransportLoading = function(self)
        SeaUnit.OnStopTransportLoading(self)
        BaseTransport.OnStopTransportLoading(self)
    end,

    ---@param self AircraftCarrier
    DestroyedOnTransport = function(self)
        -- SeaUnit.DestroyedOnTransport(self)
        BaseTransport.DestroyedOnTransport(self)
    end,

    ---@param self AircraftCarrier
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        self:SaveCargoMass()
        SeaUnit.OnKilled(self, instigator, type, overkillRatio)
        self:DetachCargo()
    end,
}
