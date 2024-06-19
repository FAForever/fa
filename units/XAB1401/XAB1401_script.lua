--------------------------------------------------------------------------------
-- File     :  /data/units/XAB1401/XAB1401_script.lua
-- Author(s):  Jessica St. Croix, Dru Staltman
-- Summary  :  Aeon Quantum Resource Generator
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local FxAmbient = import("/lua/effecttemplates.lua").AResourceGenAmbient
local DeathNukeWeapon = import("/lua/sim/defaultweapons.lua").DeathNukeWeapon
local CreateAeonParagonBuildingEffects = import("/lua/effectutilities.lua").CreateAeonParagonBuildingEffects

---@class XAB1401 : AStructureUnit
XAB1401 = ClassUnit(AStructureUnit) {

    Weapons = {
        DeathWeapon = ClassWeapon(DeathNukeWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        AStructureUnit.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonParagonBuildingEffects(self)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        AStructureUnit.OnStopBeingBuilt(self, builder, layer)

        local num = self:GetRandomDir()
        self.BallManip = CreateRotator(self, 'Orb', 'y', nil, 0, 15, 80 + Random(0, 20) * num)
        self.Trash:Add(self.BallManip)

        for k, v in FxAmbient do
            CreateAttachedEmitter(self, 'Orb', self.Army, v)
        end

        ChangeState(self, self.ResourceOn)
    end,

    ResourceOn = State {
        Main = function(self)
            local aiBrain = self:GetAIBrain()
            local massAdd = 0
            local energyAdd = 0
            local maxMass = self.Blueprint.Economy.MaxMass
            local maxEnergy = self.Blueprint.Economy.MaxEnergy

            while true do
                local massNeed = aiBrain:GetEconomyRequested('MASS') * 10
                local energyNeed = aiBrain:GetEconomyRequested('ENERGY') * 10

                local massIncome = (aiBrain:GetEconomyIncome('MASS') * 10) - massAdd
                local energyIncome = (aiBrain:GetEconomyIncome('ENERGY') * 10) - energyAdd

                massAdd = 20
                if massNeed - massIncome > 0 then
                    massAdd = massAdd + massNeed - massIncome
                end

                if maxMass and massAdd > maxMass then
                    massAdd = maxMass
                end
                self:SetProductionPerSecondMass(massAdd)

                energyAdd = 1000
                if energyNeed - energyIncome > 0 then
                    energyAdd = energyAdd + energyNeed - energyIncome
                end
                if maxEnergy and energyAdd > maxEnergy then
                    energyAdd = maxEnergy
                end
                self:SetProductionPerSecondEnergy(energyAdd)

                WaitTicks(6)
            end
        end,
    },

    GetRandomDir = function(self)
        local num = Random(0, 2)
        if num > 1 then
            return 1
        end
        return -1
    end,
}

TypeClass = XAB1401
