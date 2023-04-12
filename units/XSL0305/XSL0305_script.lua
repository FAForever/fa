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
---@field TrashSniperFx TrashBag
XSL0305 = ClassUnit(SLandUnit) {
    Weapons = {
        MainGun = ClassWeapon(SDFSihEnergyRifleNormalMode) { },
        SniperGun = ClassWeapon(SDFSihEnergyRifleSniperMode) { },
    },

    ---@param self XSL0305
    OnCreate = function(self)
        SLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('SniperGun', false)
        self.TrashSniperFx = TrashBag()
    end,

    ---@param self XSL0305
    ---@param bit number
    OnScriptBitSet = function(self, bit)
        SLandUnit.OnScriptBitSet(self, bit)
        if bit == 1 then
            local bp = self.Blueprint
            self:SetSpeedMult(bp.Physics.LandSpeedMultiplier * 0.75)
            self:SetWeaponEnabledByLabel('SniperGun', true)
            self:SetWeaponEnabledByLabel('MainGun', false)
            self:GetWeaponManipulatorByLabel('SniperGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('MainGun'):GetHeadingPitch())
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self:GetWeaponByLabel('SniperGun').Blueprint.MaxRadius)
            self.TrashSniperFx:Add(CreateAttachedEmitter(self, 'XSL0305', self.Army, '/effects/emitters/seraphim_being_built_ambient_01_emit.bp'))
        end
    end,

    ---@param self XSL0305
    ---@param bit number
    OnScriptBitClear = function(self, bit)
        SLandUnit.OnScriptBitClear(self, bit)
        if bit == 1 then
            local bp = self.Blueprint
            self:SetSpeedMult(bp.Physics.LandSpeedMultiplier)
            self:SetWeaponEnabledByLabel('SniperGun', false)
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:GetWeaponManipulatorByLabel('MainGun'):SetHeadingPitch(self:GetWeaponManipulatorByLabel('SniperGun'):GetHeadingPitch())
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self:GetWeaponByLabel('MainGun').Blueprint.MaxRadius)
            self.TrashSniperFx:Destroy()
        end
    end,
}
TypeClass = XSL0305

--- Kept for mod support
local EffectUtil = import("/lua/effectutilities.lua")