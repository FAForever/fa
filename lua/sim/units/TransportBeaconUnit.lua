
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit

---@class TransportBeaconUnit : StructureUnit
TransportBeaconUnit = ClassUnit(StructureUnit) {

    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    --- Invincibility!  (the only way to kill a transport beacon is
    --- to kill the transport unit generating it)
    ---@param self TransportBeaconUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    ---@param self TransportBeaconUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
    end,
}
