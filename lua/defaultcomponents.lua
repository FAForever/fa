
---@class ShieldEffectsComponent : Unit
---@field Trash TrashBag
---@field ShieldEffectsBag TrashBag
---@field ShieldEffectsBone Bone
---@field ShieldEffectsScale number
ShieldEffectsComponent = ClassSimple {

    ShieldEffects = { },
    ShieldEffectsBone = 0,
    ShieldEffectsScale = 1,

    ---@param self ShieldEffectsComponent
    OnCreate = function(self)
        self.ShieldEffectsBag = TrashBag()
        self.Trash:Add(self.ShieldEffectsBag)
    end,

    ---@param self ShieldEffectsComponent
    OnShieldEnabled = function(self)
        self.ShieldEffectsBag:Destroy()
        for _, v in self.ShieldEffects do
            self.ShieldEffectsBag:Add(CreateAttachedEmitter(self, self.ShieldEffectsBone, self.Army, v):ScaleEmitter(self.ShieldEffectsScale))
        end
    end,

    ---@param self ShieldEffectsComponent
    OnShieldDisabled = function(self)
        self.ShieldEffectsBag:Destroy()
    end,
}

---@class IntelComponent
---@field IntelStatus? UnitIntelStatus
IntelComponent = ClassSimple {

    ---@param self IntelComponent | Unit
    OnStopBeingBuilt = function(self, builder, layer)
        local intelBlueprint = self.Blueprint.Intel
        if intelBlueprint and intelBlueprint.State then
            reprsl(intelBlueprint)
            self.IntelStatus = table.deepcopy(intelBlueprint.State)
            reprsl(self.IntelStatus)
            self:EnableUnitIntel('NotInitialized')
            self.Brain:AddEnergyDependingEntity(self)
        end
    end,

    ---@param self IntelComponent | Unit
    OnEnergyDepleted = function(self)
        LOG("OnEnergyDepleted")
        local status = self.IntelStatus
        if status then
            self:DisableUnitIntel('Energy')
        end
    end,

    ---@param self IntelComponent | Unit
    OnEnergyViable = function(self)
        LOG("OnEnergyDepleted")
        local status = self.IntelStatus
        if status then
            self:EnableUnitIntel('Energy')
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param disabler string
    ---@param intel? IntelType
    DisableUnitIntel = function(self, disabler, intel)
        local status = self.IntelStatus
        if status then
            LOG("DisableUnitIntel: " .. tostring(disabler) .. " for " .. tostring(intel))

            -- prevent recharging from occuring
            self:OnIntelRechargeFailed()

            -- disable all intel
            local allIntel = status.AllIntel
            local allIntelDisabledByEvent = status.AllIntelDisabledByEvent
            local allIntelMaintenanceFree = status.AllIntelMaintenanceFree
            local allIntelFromEnhancements = status.AllIntelFromEnhancements
            if not intel then
                for i, _ in allIntel do
                    if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if not allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = true
                            self:DisableIntel(i)
                            self:OnIntelDisabled(i)
                        end
                    end
                end

                if allIntelMaintenanceFree then
                    for i, _ in allIntelMaintenanceFree do
                        if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[i]) then
                            allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                            if not allIntelDisabledByEvent[i][disabler] then
                                allIntelDisabledByEvent[i][disabler] = true
                                self:DisableIntel(i)
                                self:OnIntelDisabled(i)
                            end
                        end
                    end
                end

            -- disable one intel
            elseif allIntel[intel] or (allIntelFromEnhancements and allIntelFromEnhancements[intel]) then
                -- special case that requires additional book keeping
                if disabler == 'Enhancement' then
                    allIntelFromEnhancements[intel] = true
                end

                if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[intel]) then
                    allIntelDisabledByEvent[intel] = allIntelDisabledByEvent[intel] or { }
                    if not allIntelDisabledByEvent[intel][disabler] then
                        allIntelDisabledByEvent[intel][disabler] = true
                        self:DisableIntel(intel)
                        self:OnIntelDisabled(intel)
                    end
                end
            end
            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param disabler string
    ---@param intel? IntelType
    EnableUnitIntel = function(self, disabler, intel)
        local status = self.IntelStatus
        if status then
            LOG("EnableUnitIntel: " .. tostring(disabler) .. " for " .. tostring(intel))

            local allIntel = status.AllIntel
            local allIntelDisabledByEvent = status.AllIntelDisabledByEvent
            local allIntelMaintenanceFree = status.AllIntelMaintenanceFree
            local allIntelFromEnhancements = status.AllIntelFromEnhancements

            -- special case when unit is finished building
            if disabler == 'NotInitialized' then

                -- this bit is weird, but unit logic expects to always have intel immediately enabled when 
                -- the unit is done constructing, regardless whether the unit is able to use the intel
                for i, _ in allIntel do
                    self:OnIntelEnabled(i)
                    self:EnableIntel(i)
                end

                if allIntelMaintenanceFree then
                    for i, _ in allIntelMaintenanceFree do
                        self:EnableIntel(i)
                        self:OnIntelEnabled(i)
                    end
                end

                return
            end

            -- disable all intel
            if not intel then
                for i, _ in allIntel do
                    if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = nil
                            if table.empty(allIntelDisabledByEvent[i]) then
                                self:OnIntelRecharge(i)
                            end
                        end
                    end
                end

                if allIntelFromEnhancements then
                    for i, _ in allIntelFromEnhancements do
                        if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[i]) then
                            allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                            if allIntelDisabledByEvent[i][disabler] then
                                allIntelDisabledByEvent[i][disabler] = nil
                                if table.empty(allIntelDisabledByEvent[i]) then
                                    self:OnIntelRecharge(i)
                                end
                            end
                        end
                    end
                end

            -- disable one intel
            elseif allIntel[intel] or (allIntelFromEnhancements and allIntelFromEnhancements[intel]) then
                -- special case that requires additional book keeping
                if disabler == 'Enhancement' then
                    allIntelFromEnhancements[intel] = true
                end

                if not (disabler == 'Energy' and allIntelMaintenanceFree and allIntelMaintenanceFree[intel]) then
                    allIntelDisabledByEvent[intel] = allIntelDisabledByEvent[intel] or { }
                    if allIntelDisabledByEvent[intel][disabler] then
                        allIntelDisabledByEvent[intel][disabler] = nil
                        if table.empty(allIntelDisabledByEvent[intel]) then
                            self:OnIntelRecharge(intel)
                        end
                    end
                end
            end

            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel IntelType
    OnIntelRecharge = function(self, intel)
        local status = self.IntelStatus
        if status then
            LOG("OnIntelRecharge: for " .. tostring(intel))
            if not status.RechargeThread then 
                status.RechargeThread = ForkThread(self.IntelRechargeThread, self)
            end

            status.AllIntelRecharging[intel] = true

            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    OnIntelRecharged = function(self)
        local status = self.IntelStatus
        if status and status.RechargeThread then
            LOG("OnIntelRecharged")
            status.RechargeThread = nil
            for i, _ in status.AllIntelRecharging do
                self:EnableIntel(i)
                self:OnIntelEnabled(i)
                status.AllIntelRecharging[i] = nil
            end

            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    OnIntelRechargeFailed = function(self)
        local status = self.IntelStatus
        if status and status.RechargeThread then
            LOG("OnIntelRechargeFailed")
            status.RechargeThread:Destroy()
            status.RechargeThread = nil
            self:SetWorkProgress(0)

            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    IntelRechargeThread = function(self)
        local status = self.IntelStatus
        if status then
            LOG("IntelRechargeThread")
            local ticks = 10 * (self.Blueprint.Intel.ReactivateTime or 1)

            --- display progress
            for k = 1, ticks do
                self:SetWorkProgress((k / ticks))
                WaitTicks(1)
            end

            self:SetWorkProgress(-1)
            self:OnIntelRecharged()
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelEnabled = function(self, intel)
        LOG("Enabled intel: " .. tostring(intel))

        if intel == 'Cloak' or intel == 'CloakField' then
            self:UpdateCloakEffect(true, intel)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelDisabled = function(self, intel)
        LOG("Disabled intel: " .. tostring(intel))

        if intel == 'Cloak' or intel == 'CloakField' then
            self:UpdateCloakEffect(false, intel)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param cloaked boolean
    ---@param intel IntelType
    UpdateCloakEffect = function(self, cloaked, intel)
        -- When debugging cloak FX issues, remember that once a structure unit is seen by the enemy,
        -- recloaking won't make it vanish again, and they'll see the new FX.
        if self and not self.Dead then
            if intel == 'Cloak' then
                local bpDisplay = self.Blueprint.Display

                if cloaked then
                    self:SetMesh(bpDisplay.CloakMeshBlueprint, true)
                else
                    self:SetMesh(bpDisplay.MeshBlueprint, true)
                end
            elseif intel == 'CloakField' then
                if self.CloakFieldWatcherThread then
                    KillThread(self.CloakFieldWatcherThread)
                    self.CloakFieldWatcherThread = nil
                end

                if cloaked then
                    self.CloakFieldWatcherThread = self:ForkThread(self.CloakFieldWatcher)
                end
            end
        end
    end,

    ---@param self IntelComponent | Unit
    CloakFieldWatcher = function(self)
        if self and not self.Dead then
            local bp = self.Blueprint
            local radius = bp.Intel.CloakFieldRadius - 2 -- Need to take off 2, because engine reasons
            local brain = self:GetAIBrain()

            while self and not self.Dead and self:IsIntelEnabled('CloakField') do
                local pos = self:GetPosition()
                local units = brain:GetUnitsAroundPoint(categories.ALLUNITS, pos, radius, 'Ally')

                for _, unit in units do
                    if unit and not unit.Dead and unit ~= self then
                        if unit.CloakFXWatcherThread then
                            KillThread(unit.CloakFXWatcherThread)
                            unit.CloakFXWatcherThread = nil
                        end

                        unit:UpdateCloakEffect(true, 'Cloak') -- Turn on the FX for the unit
                        unit.CloakFXWatcherThread = unit:ForkThread(unit.CloakFXWatcher)
                    end
                end

                WaitTicks(6)
            end
        end
    end,

    ---@param self IntelComponent | Unit
    CloakFXWatcher = function(self)
        WaitTicks(6)

        if self and not self.Dead then
            self:UpdateCloakEffect(false, 'Cloak')
        end
    end,


    ---@param self Unit
    ---@param hook fun(unit: Unit, army: number)
    AddDetectedByHook = function(self, hook)
        if not self.DetectedByHooks then
            self.DetectedByHooks = {}
        end
        table.insert(self.DetectedByHooks, hook)
    end,

    ---@param self Unit
    ---@param hook fun(unit: Unit, army: number)
    RemoveDetectedByHook = function(self, hook)
        if self.DetectedByHooks then
            for k, v in self.DetectedByHooks do
                if v == hook then
                    table.remove(self.DetectedByHooks, k)
                    return
                end
            end
        end
    end,

    ---@param self Unit
    ---@param index integer
    OnDetectedBy = function(self, index)
        if self.DetectedByHooks then
            for k, v in self.DetectedByHooks do
                v(self, index)
            end
        end
    end,

}