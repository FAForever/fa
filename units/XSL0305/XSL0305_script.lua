----------------------------------------------------------------------------
--  File     :  /data/units/XSL0305/XSL0305_script.lua
--  Summary  :  Seraphim Sniper Bot Script
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SDFSihEnergyRifleNormalMode = SeraphimWeapons.SDFSniperShotNormalMode
local SDFSihEnergyRifleSniperMode = SeraphimWeapons.SDFSniperShotSniperMode

---@class XSL0305 : SLandUnit
XSL0305 = ClassUnit(SLandUnit) {

    Weapons = {
        MainGun = ClassWeapon(SDFSihEnergyRifleNormalMode) {},
        SniperGun = ClassWeapon(SDFSihEnergyRifleSniperMode) {
            SetOnTransport = function(self, transportstate)
                SDFSihEnergyRifleSniperMode.SetOnTransport(self, transportstate)
                self.unit:SetScriptBit('RULEUTC_WeaponToggle', false)
            end,
        },
    },

    OnCreate = function(self)
        SLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('SniperGun', false)

        local wepBp = self.Blueprint.Weapon
        self.sniperRange = 75
        self.normalRange = 65
        for k, v in wepBp do
            if v.Label == 'SniperGun' then
                self.sniperRange = v.MaxRadius
            elseif v.Label == 'MainGun' then
                self.normalRange = v.MaxRadius
            end
        end
    end,

    OnScriptBitSet = function(self, bit)
        SLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            local bp = self.Blueprint
            self:SetSpeedMult(bp.Physics.LandSpeedMultiplier * 0.75)

            self:SetWeaponEnabledByLabel('SniperGun', true)
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:GetWeaponManipulatorByLabel('SniperGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('MainGun'):GetHeadingPitch())
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.sniperRange)
        end

        if not self.ShieldEffectsBag then
            self.ShieldEffectsBag = {}
        end
        self.ShieldEffectsBag = {}
        table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'XSL0305', self.Army, '/effects/emitters/seraphim_being_built_ambient_01_emit.bp'))
    end,

    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            local bp = self.Blueprint
            self:SetSpeedMult(bp.Physics.LandSpeedMultiplier)
            self:SetWeaponEnabledByLabel('SniperGun', false)
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:GetWeaponManipulatorByLabel('MainGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('SniperGun'):GetHeadingPitch())
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
            if self.ShieldEffectsBag then
                for k, v in self.ShieldEffectsBag do
                    v:Destroy()
                end
                self.ShieldEffectsBag = {}
            end
            self.ShieldEffectsBag = nil
        end
    end,
}
TypeClass = XSL0305

--- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")