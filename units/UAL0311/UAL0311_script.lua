-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0301/UAL0311_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local AWeapons = import('/lua/aeonweapons.lua')
local ADFReactonCannon = AWeapons.ADFReactonCannon
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')

UAL0311 = Class(CommandUnit) {
    Weapons = {
        RightReactonCannon = Class(ADFReactonCannon) {},
        DeathWeapon = Class(SCUDeathWeapon) {},
    },

    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('RightReactonCannon', true)
        self:GetWeaponManipulatorByLabel('RightReactonCannon'):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Turbine', true)
        self:SetupBuildBones()
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,
}

TypeClass = UAL0311
