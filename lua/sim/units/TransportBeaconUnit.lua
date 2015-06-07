local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

TransportBeaconUnit = Class(StructureUnit) {
    LandBuiltHiddenBones = {'Floatation'},
    FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
    --{'/effects/emitters/red_smoke_beacon_01_emit.bp'},
    FxTransportBeaconScale = 0.5,

    -- invincibility!  (the only way to kill a transport beacon is
    -- to kill the transport unit generating it)
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        StructureUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
    end,
}
