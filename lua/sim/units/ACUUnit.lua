local CommandUnit = import('/lua/sim/units/CommandUnit.lua').CommandUnit

--- Class for ACUs. Handles special stuff like "Commander under attack" VOs.
ACUUnit = Class(CommandUnit) {
    -- The "commander under attack" warnings.
    CreateShield = function(self, bpShield)
        CommandUnit.CreateShield(self, bpShield)

        local aiBrain = self:GetAIBrain()

        -- Mutate the OnDamage function for this one very special shield.
        local oldOnDamage = self.MyShield.OnDamage
        local newOnDamage = function(shield, instigator, amount, vector, dmgType)
            oldOnDamage(shield, instigator, amount, vector, dmgType)

            aiBrain:OnPlayCommanderUnderAttackVO()
        end

        self.MyShield.OnDamage = newOnDamage
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        CommandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = self:GetAIBrain()
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)

        --If there is a killer, and it's not me
        if instigator and instigator:GetArmy() ~= self:GetArmy() then
            local instigatorBrain = ArmyBrains[instigator:GetArmy()]
            if instigatorBrain and not instigatorBrain:IsDefeated() then
                instigatorBrain:AddArmyStat("FAFWin", 1)
            end
        end

        --Score change, we send the score of all players
        for index, brain in ArmyBrains do
            if brain and not brain:IsDefeated() then
                local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                table.insert(Sync.GameResult, { index, result })
            end
        end
    end,

    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
    end,

    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
    end,

    GiveInitialResources = function(self)
        WaitTicks(2)
        self:GetAIBrain():GiveResource('Energy', self:GetBlueprint().Economy.StorageEnergy)
        self:GetAIBrain():GiveResource('Mass', self:GetBlueprint().Economy.StorageMass)
    end,
}
