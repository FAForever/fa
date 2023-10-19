
local CommandUnit = import("/lua/sim/units/commandunit.lua").CommandUnit

---@class ACUUnit : CommandUnit
ACUUnit = ClassUnit(CommandUnit) {
    -- The "commander under attack" warnings.
    ---@param self ACUUnit
    ---@param bpShield any
    CreateShield = function(self, bpShield)
        CommandUnit.CreateShield(self, bpShield)

        local aiBrain = self:GetAIBrain()

        -- Mutate the OnDamage function for this one very special shield.
        local oldApplyDamage = self.MyShield.ApplyDamage
        self.MyShield.ApplyDamage = function(...)
            oldApplyDamage(unpack(arg))
            aiBrain:OnPlayCommanderUnderAttackVO()
        end
    end,

    ---@param self ACUUnit
    ---@param enh string
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)

        self:SendNotifyMessage('completed', enh)
        self:SetImmobile(false)
    end,

    ---@param self ACUUnit
    ---@param work string
    ---@return boolean
    OnWorkBegin = function(self, work)
        local legalWork = CommandUnit.OnWorkBegin(self, work)
        if not legalWork then return end

        self:SendNotifyMessage('started', work)

        -- No need to do it for AI
        self:SetImmobile(true)
        return true
    end,

    ---@param self ACUUnit
    ---@param work string
    OnWorkFail = function(self, work)
        self:SendNotifyMessage('cancelled', work)
        self:SetImmobile(false)

        CommandUnit.OnWorkFail(self, work)
    end,

    ---@param self ACUUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        self.WeaponEnabled = {}
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Handle incoming OC damage
        if damageType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            amount = wep.Blueprint.Overcharge.commandDamage
        end

        CommandUnit.DoTakeDamage(self, instigator, amount, vector, damageType)
        local aiBrain = self:GetAIBrain()
        if aiBrain then
            aiBrain:OnPlayCommanderUnderAttackVO()
        end

        if self:GetHealth() < ArmyBrains[self.Army]:GetUnitStat(self.UnitId, "lowest_health") then
            ArmyBrains[self.Army]:SetUnitStat(self.UnitId, "lowest_health", self:GetHealth())
        end
    end,

    ---@param self ACUUnit
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        CommandUnit.OnKilled(self, instigator, type, overkillRatio)

        -- If there is a killer, and it's not me
        if instigator and instigator.Army ~= self.Army then
            local instigatorBrain = ArmyBrains[instigator.Army]

            Sync.EnforceRating = true
            WARN('ACU kill detected. Rating for ranked games is now enforced.')

            -- If we are teamkilled, filter out death explostions of allied units that were not coused by player's self destruct order
            -- Damage types:
            --     'DeathExplosion' - when normal unit is killed
            --     'Nuke' - when Paragon is killed
            --     'Deathnuke' - when ACU is killed
            if IsAlly(self.Army, instigator.Army) and not ((type == 'DeathExplosion' or type == 'Nuke' or type == 'Deathnuke') and not instigator.SelfDestructed) then
                WARN('Teamkill detected')
                Sync.Teamkill = {killTime = GetGameTimeSeconds(), instigator = instigator.Army, victim = self.Army}
            end

            -- prepare sync
            local sync = Sync
            local events = sync.Events or { }
            sync.Events = events
            local acuDestroyed = events.ACUDestroyed or { }
            events.ACUDestroyed = acuDestroyed

            -- sync the event
            table.insert(acuDestroyed, {
                Timestamp = GetGameTimeSeconds(),
                InstigatorArmy = instigator.Army,
                KilledArmy = self.Army
            })

        end
        ArmyBrains[self.Army].CommanderKilledBy = (instigator or self).Army
    end,

    ---@param self ACUUnit
    ResetRightArm = function(self)
        CommandUnit.ResetRightArm(self)

        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)

        -- Ugly hack to re-initialise auto-OC once a task finishes
        local wep = self:GetWeaponByLabel('AutoOverCharge')
        wep:SetAutoOvercharge(wep.AutoMode)
    end,

    ---@param self ACUUnit
    OnPrepareArmToBuild = function(self)
        CommandUnit.OnPrepareArmToBuild(self)
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
    end,

    ---@param self ACUUnit
    GiveInitialResources = function(self)
        WaitTicks(1)
        local bp = self.Blueprint
        local aiBrain = self:GetAIBrain()
        aiBrain:GiveResource('Energy', bp.Economy.StorageEnergy)
        aiBrain:GiveResource('Mass', bp.Economy.StorageMass)
    end,

    ---@param self ACUUnit
    BuildDisable = function(self)
        while self:IsUnitState('Building') or self:IsUnitState('Enhancing') or self:IsUnitState('Upgrading') or
                self:IsUnitState('Repairing') or self:IsUnitState('Reclaiming') do
            WaitSeconds(0.5)
        end

        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, true, true)
            end
        end
    end,

    -- Store weapon status on upgrade. Ignore default and OC, which are dealt with elsewhere
    ---@param self ACUUnit
    ---@param label string
    ---@param enable boolean
    ---@param lockOut boolean
    SetWeaponEnabledByLabel = function(self, label, enable, lockOut)
        CommandUnit.SetWeaponEnabledByLabel(self, label, enable)

        -- Unless lockOut specified, updates the 'Permanent record' of whether a weapon is enabled. With it specified,
        -- the changing of the weapon on/off state is more... temporary. For example, when building something.
        if label ~= self.rightGunLabel and label ~= 'OverCharge' and label ~= 'AutoOverCharge' and not lockOut then
            self.WeaponEnabled[label] = enable
        end
    end,

    ---@param self ACUUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        CommandUnit.OnStartBuild(self, unitBeingBuilt, order)

        -- Disable any active upgrade weapons
        local fork = false
        for label, enabled in self.WeaponEnabled do
            if enabled then
                self:SetWeaponEnabledByLabel(label, false, true)
                fork = true
            end
        end

        if fork then
            self:ForkThread(self.BuildDisable)
        end
    end,
}
