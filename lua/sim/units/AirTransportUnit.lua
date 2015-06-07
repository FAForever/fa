local AirUnit = import('/lua/sim/units/AirUnit.lua').AirUnit

--- Base class for air transports.
AirTransportUnit = Class(AirUnit) {
    OnTransportAttach = function(self, attachBone, unit)
        self:PlayUnitSound('Load')
        self:MarkWeaponsOnTransport(unit, true)
        if unit:ShieldIsOn() then
            unit:DisableShield()
            unit:DisableDefaultToggleCaps()
        end
        if not EntityCategoryContains(categories.PODSTAGINGPLATFORM, self) then
            self:RequestRefreshUI()
        end

        unit:OnAttachedToTransport(self, attachBone)
    end,

    OnTransportDetach = function(self, attachBone, unit)
        self:PlayUnitSound('Unload')
        self:MarkWeaponsOnTransport(unit, false)
        unit:EnableShield()
        unit:EnableDefaultToggleCaps()
        if not EntityCategoryContains(categories.PODSTAGINGPLATFORM, self) then
            self:RequestRefreshUI()
        end
        unit:TransportAnimation(-1)
        unit:OnDetachedToTransport(self)
    end,

    -- When one of our attached units gets killed, detach it
    OnAttachedKilled = function(self, attached)
        attached:DetachFrom()
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        AirUnit.OnKilled(self, instigator, type, overkillRatio)

        local units = self:GetCargo()
        for k, v in units do
            v:DetachFrom()
        end
    end,

    GetTransportClass = function(self)
        local bp = self:GetBlueprint().Transport
        return bp.TransportClass
    end
}
