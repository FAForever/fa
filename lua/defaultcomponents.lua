local Buff = import("/lua/sim/buff.lua")
local Entity = import("/lua/sim/Entity.lua").Entity

---@class ShieldEffectsComponent : Unit
---@field Trash TrashBag
---@field ShieldEffectsBag TrashBag
---@field ShieldEffectsBone Bone
---@field ShieldEffectsScale number
ShieldEffectsComponent = ClassSimple {

    ShieldEffects = {},
    ShieldEffectsBone = 0,
    ShieldEffectsScale = 1,

    ---@param self ShieldEffectsComponent
    OnCreate = function(self)
        local bag = TrashBag()
        self.ShieldEffectsBag = bag
        self.Trash:Add(bag)
    end,

    ---@param self ShieldEffectsComponent
    OnShieldEnabled = function(self)
        local bag = self.ShieldEffectsBag
        local bone = self.ShieldEffectsBone
        local scale = self.ShieldEffectsScale
        local army = self.Army

        bag:Destroy()
        for _, effect in self.ShieldEffects do
            bag:Add(CreateAttachedEmitter(self, bone, army, effect):ScaleEmitter(scale))
        end
    end,

    ---@param self ShieldEffectsComponent
    OnShieldDisabled = function(self)
        self.ShieldEffectsBag:Destroy()
    end,
}

---@class IntelComponent
---@field IntelStatus? UnitIntelStatus
---@field DetectedByHooks? fun(unit: Unit, army: number)[]
IntelComponent = ClassSimple {

    ---@param self IntelComponent | Unit
    OnStopBeingBuilt = function(self, builder, layer)
        local intelBlueprint = self.Blueprint.Intel
        if intelBlueprint and intelBlueprint.State then
            self.IntelStatus = table.deepcopy(intelBlueprint.State)
            self:EnableUnitIntel('NotInitialized')
            self.Brain:AddEnergyDependingEntity(self)
        end
    end,

    ---@param self IntelComponent | Unit
    OnEnergyDepleted = function(self)
        local status = self.IntelStatus
        if status then
            self:DisableUnitIntel('Energy')
        end
    end,

    ---@param self IntelComponent | Unit
    OnEnergyViable = function(self)
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
            -- LOG("DisableUnitIntel: " .. tostring(disabler) .. " for " .. tostring(intel))

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
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or {}
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
                            allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or {}
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
                    allIntelDisabledByEvent[intel] = allIntelDisabledByEvent[intel] or {}
                    if not allIntelDisabledByEvent[intel][disabler] then
                        allIntelDisabledByEvent[intel][disabler] = true
                        self:DisableIntel(intel)
                        self:OnIntelDisabled(intel)
                    end
                end
            end
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param disabler string
    ---@param intel? IntelType
    EnableUnitIntel = function(self, disabler, intel)
        local status = self.IntelStatus
        if status then
            -- LOG("EnableUnitIntel: " .. tostring(disabler) .. " for " .. tostring(intel))

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
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or {}
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
                            allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or {}
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
                    allIntelDisabledByEvent[intel] = allIntelDisabledByEvent[intel] or {}
                    if allIntelDisabledByEvent[intel][disabler] then
                        allIntelDisabledByEvent[intel][disabler] = nil
                        if table.empty(allIntelDisabledByEvent[intel]) then
                            self:OnIntelRecharge(intel)
                        end
                    end
                end
            end
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel IntelType
    OnIntelRecharge = function(self, intel)
        local status = self.IntelStatus
        if status then
            -- LOG("OnIntelRecharge: for " .. tostring(intel))
            if not status.RechargeThread then
                status.RechargeThread = ForkThread(self.IntelRechargeThread, self)
            end

            status.AllIntelRecharging[intel] = true
        end
    end,

    ---@param self IntelComponent | Unit
    OnIntelRecharged = function(self)
        local status = self.IntelStatus
        if status and status.RechargeThread then
            status.RechargeThread = nil
            for i, _ in status.AllIntelRecharging do
                self:EnableIntel(i)
                self:OnIntelEnabled(i)
                status.AllIntelRecharging[i] = nil
            end
        end
    end,

    ---@param self IntelComponent | Unit
    OnIntelRechargeFailed = function(self)
        local status = self.IntelStatus
        if status and status.RechargeThread then
            status.RechargeThread:Destroy()
            status.RechargeThread = nil
            self:SetWorkProgress(0)
        end
    end,

    ---@param self IntelComponent | Unit
    IntelRechargeThread = function(self)
        local status = self.IntelStatus
        if status then
            local ticks = 10 * (self.Blueprint.Intel.ReactivateTime or 1)

            --- display progress
            for k = 1, ticks do

                -- prevent changing work progress when we are doing work (such as an enhancement)
                if not self.WorkItem then
                    self:SetWorkProgress((k / ticks))
                end

                WaitTicks(1)
            end

            -- prevent changing work progress when we are doing work (such as an enhancement)
            if not self.WorkItem then
                self:SetWorkProgress(-1)
            end

            self:OnIntelRecharged()
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelEnabled = function(self, intel)
        -- LOG("Enabled intel: " .. tostring(intel))

        if intel == 'Cloak' or intel == 'CloakField' then
            self:UpdateCloakEffect(true, intel)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelDisabled = function(self, intel)
        -- LOG("Disabled intel: " .. tostring(intel))

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

local TechToDuration = {
    TECH1 = 1,
    TECH2 = 2,
    TECH3 = 3,
    EXPERIMENTAL = 6,
}

local TechToLOD = {
    TECH1 = 120,
    TECH2 = 140,
    TECH3 = 160,
    EXPERIMENTAL = 200,
}

---@class TreadComponent
---@field CrushingSuspend? boolean
---@field CrushingThread? thread
---@field TreadBlueprint UnitBlueprintTreads
---@field TreadSuspend? boolean
---@field TreadThreads? thread[]
TreadComponent = ClassSimple {

    ---@param self Unit | TreadComponent
    OnCreate = function(self)
        self.TreadBlueprint = self.Blueprint.Display.MovementEffects.Land.Treads
    end,

    ---@param self Unit | TreadComponent
    CreateMovementEffects = function(self)
        local treads = self.TreadBlueprint
        if not treads then
            return
        end

        if treads.ScrollTreads then
            self:AddThreadScroller(1.0, treads.ScrollMultiplier or 0.2)
        end
        local treadMarks = treads.TreadMarks
        local treadType = self.TerrainType.Treads
        if treadMarks and treadType and treadType ~= 'None' then
            self:CreateTreads(treadMarks)
        end
        if treads.Damage then
            self:StartCrushing(treads.Damage)
        end
    end,

    ---@param self Unit | TreadComponent
    DestroyMovementEffects = function(self)
        local treads = self.TreadBlueprint
        if not treads then
            return
        end

        if treads.ScrollTreads then
            self:RemoveScroller()
        end
        if self.TreadThreads then
            self.TreadSuspend = true
        end
        if self.CrushingThread then
            self.CrushingSuspend = true
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param treadMarks UnitBlueprintTreadMarks
    CreateTreads = function(self, treadMarks)
        local treadThreads = self.TreadThreads
        if not treadThreads then
            treadThreads = {}
            self.TreadThreads = treadThreads

            for k, treadBlueprint in treadMarks do
                local thread = ForkThread(self.CreateTreadsThread, self, treadBlueprint)
                treadThreads[k] = thread
                self.Trash:Add(thread)
            end
        else
            self.TreadSuspend = nil
            for _, thread in treadThreads do
                ResumeThread(thread)
            end
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param treads UnitBlueprintTreadMarks
    CreateTreadsThread = function(self, treads)
        -- trade memory for performance
        local WaitTicks = WaitTicks
        local CreateSplatOnBone = CreateSplatOnBone
        local SuspendCurrentThread = SuspendCurrentThread

        local treadOffset = treads.TreadOffset
        local treadBone = treads.BoneName or 0
        local treadTexture = treads.TreadMarks
        local sizeX = treads.TreadMarksSizeX
        local sizeZ = treads.TreadMarksSizeZ
        local lod = TechToLOD[self.Blueprint.TechCategory] or 120
        local duration = treads.TreadLifeTime or TechToDuration[self.Blueprint.TechCategory] or 1
        local army = self.Army

        local interval = 10 * (treads.TreadMarksInterval or 0.1)
        -- prevent infinite loops
        if interval < 1 then
            interval = 1
        end

        while true do
            while not (self.TreadSuspend or IsDestroyed(self)) do
                CreateSplatOnBone(self, treadOffset, treadBone, treadTexture, sizeX, sizeZ, lod, duration, army)
                WaitTicks(interval)
            end

            SuspendCurrentThread()
            WaitTicks(1)
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param dmg table
    StartCrushing = function(self, dmg)
        if not self.CrushingThread then
            local thread = ForkThread(self.CreateCrushingThread, self, dmg)
            self.CrushingThread = thread
            self.Trash:Add(thread)
        else
            self.CrushingSuspend = nil
            ResumeThread(self.CrushingThread)
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param dmg table
    CreateCrushingThread = function(self, dmg)
        -- trade memory for performance
        local WaitTicks = WaitTicks
        local DamageArea = DamageArea
        local SuspendCurrentThread = SuspendCurrentThread

        local bones = dmg.Bones
        local radius = dmg.Radius
        local amount = dmg.Amount
        local type = dmg.Type
        local damageFriendly = dmg.DamageFriendly

        local interval = 10 * (dmg.PulseInterval or 3)
        -- prevent infinite loops
        if interval < 1 then
            interval = 1
        end

        while true do
            while not self.CrushingSuspend do
                if bones then
                    for _, bone in bones do
                        DamageArea(self, self:GetPosition(bone), radius, amount, type, damageFriendly)
                    end
                else
                    DamageArea(self, self:GetPosition(), radius, amount, type, damageFriendly)
                end
                WaitTicks(interval)
            end

            SuspendCurrentThread()
            WaitTicks(1)
        end
    end,
}

local MathMin = math.min

local VeterancyToTech = {
    TECH1 = 1,
    TECH2 = 2,
    TECH3 = 3,
    COMMAND = 3,
    SUBCOMMANDER = 4,
    EXPERIMENTAL = 5,
}

---Regen values by tech level and veterancy level
local VeterancyRegenBuffs = {
    { 1, 2, 3, 4, 5 }, -- T1
    { 3, 6, 9, 12, 15 }, -- T2
    { 6, 12, 18, 24, 30 }, -- T3 / ACU
    { 9, 18, 27, 36, 45 }, -- SACU
    { 25, 50, 75, 100, 125 }, -- Experimental
}

---@class VeterancyComponent
---@field VetDamage table<EntityId, number>
---@field VetDamageTaken number
---@field VetInstigators table<EntityId, Unit>
---@field VetExperience? number
---@field VetLevel? number
VeterancyComponent = ClassSimple {

    ---@param self VeterancyComponent | Unit
    OnCreate = function(self)
        local blueprint = self.Blueprint

        -- these fields are always required
        self.VetDamageTaken = 0
        self.VetDamage = {}
        self.VetInstigators = setmetatable({}, { __mode = 'v' })

        -- optionally, these fields are defined too to inform UI of our veterancy status
        if blueprint.VetEnabled then
            self:UpdateStat('VetLevel', 0)
            self:UpdateStat('VetExperience', 0)
            self.VetExperience = 0
            self.VetLevel = 0
        end
    end,

    ---@param self VeterancyComponent | Unit
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        amount = MathMin(amount, self:GetMaxHealth())
        self.VetDamageTaken = self.VetDamageTaken + amount
        if instigator and instigator.IsUnit and not IsDestroyed(instigator) then
            local entityId = instigator.EntityId
            local vetInstigators = self.VetInstigators
            local vetDamage = self.VetDamage

            vetInstigators[entityId] = instigator
            vetDamage[entityId] = (vetDamage[entityId] or 0) + amount
        end
    end,

    --- Disperses the veterancy, expects to be only called once
    ---@param self VeterancyComponent | Unit
    VeterancyDispersal = function(self)
        local vetWorth = self:GetFractionComplete() * self:GetTotalMassCost()
        local vetDamage = self.VetDamage
        local vetInstigators = self.VetInstigators
        local vetDamageTaken = self.VetDamageTaken
        for id, unit in vetInstigators do
            if unit.Blueprint.VetEnabled and (not IsDestroyed(unit)) then
                local proportion = vetWorth * (vetDamage[id] / vetDamageTaken)
                unit:AddVetExperience(proportion)
            end
        end
    end,

    -- Adds experience to a unit
    ---@param self Unit | VeterancyComponent
    ---@param experience number
    ---@param noLimit boolean
    AddVetExperience = function(self, experience, noLimit)
        local blueprint = self.Blueprint
        if not blueprint.VetEnabled then
            return
        end

        local currExperience = self.VetExperience
        local currLevel = self.VetLevel

        -- case where we're at max vet: just add the experience and be done

        if currLevel > 4 then
            currExperience = currExperience + experience
            self.VetExperience = currExperience
            self:UpdateStat('VetExperience', currExperience)
            return
        end

        ---@type UnitBlueprint
        local vetThresholds = blueprint.VetThresholds
        local lowerThreshold = vetThresholds[currLevel] or 0
        local upperThreshold = vetThresholds[currLevel + 1]
        local diffThreshold = upperThreshold - lowerThreshold

        -- case where we have no limit (after gifting / spawning)
        if noLimit then

            currExperience = currExperience + experience
            self.VetExperience = currExperience
            self:UpdateStat('VetExperience', currExperience)

            while currLevel < 5 and upperThreshold and upperThreshold <= experience do
                self:AddVetLevel()
                currLevel = currLevel + 1
                upperThreshold = vetThresholds[currLevel + 1]
            end

        -- case where we do have a limit (usual gameplay approach)
        else
            if experience > diffThreshold then
                experience = diffThreshold
            end

            currExperience = currExperience + experience
            self.VetExperience = currExperience
            self:UpdateStat('VetExperience', currExperience)

            if upperThreshold <= currExperience then
                self:AddVetLevel()
            end
        end
    end,

    --- Adds a single level of veterancy
    ---@param self Unit | VeterancyComponent
    AddVetLevel = function(self)
        local blueprint = self.Blueprint
        if not blueprint.VetEnabled then
            return
        end

        local nextLevel = self.VetLevel + 1
        self.VetLevel = nextLevel
        self:UpdateStat('VetLevel', nextLevel)

        -- shared across all units
        Buff.ApplyBuff(self, 'VeterancyMaxHealth' .. nextLevel)

        -- unique to all units... but not quite
        local regenBuffName = self.UnitId .. 'VeterancyRegen' .. nextLevel
        if not Buffs[regenBuffName] then
            local techLevel = VeterancyToTech[blueprint.TechCategory] or 1
            if techLevel < 4 and EntityCategoryContains(categories.NAVAL, self) then
                techLevel = techLevel + 1
            end

            BuffBlueprint {
                Name = regenBuffName,
                DisplayName = regenBuffName,
                BuffType = 'VeterancyRegen',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    Regen = {
                        Add = VeterancyRegenBuffs[techLevel][nextLevel],
                    },
                },
            }
        end

        Buff.ApplyBuff(self, regenBuffName)

        -- one time health injection

        local maxHealth = blueprint.Defense.MaxHealth
        local mult = blueprint.VeteranHealingMult[nextLevel] or 0.1
        self:AdjustHealth(self, maxHealth * mult)

        -- callbacks

        self:DoUnitCallbacks('OnVeteran')
        self.Brain:OnBrainUnitVeterancyLevel(self, nextLevel)
    end,

    ---@param self Unit | VeterancyComponent
    ---@param level number
    SetVeterancy = function(self, level)
        self.VetExperience = 0
        self.VetLevel = 0
        self:AddVetExperience(self.Blueprint.VetThresholds[MathMin(level or 0, 5)] or 0, true)
    end,

    ---@param self Unit | VeterancyComponent
    ---@param massKilled number
    ---@param noLimit boolean
    CalculateVeterancyLevelAfterTransfer = function(self, massKilled, noLimit)
        self.VetExperience = 0
        self.VetLevel = 0
        self:AddVetExperience(massKilled, noLimit)
    end,

    ---@param self Unit | VeterancyComponent
    ---@param unitThatIsDying Unit
    ---@param experience? number
    OnKilledUnit = function (self, unitThatIsDying, experience)
        if not experience then
            return
        end

        if not IsDestroyed(unitThatIsDying) then
            local vetWorth = unitThatIsDying:GetFractionComplete() * unitThatIsDying:GetTotalMassCost()
            self:AddVetExperience(vetWorth, false)
        end
    end,

    -- kept for backwards compatibility with mods, but should really not be used anymore

    ---@deprecated
    ---@param self Unit | VeterancyComponent
    ---@param massKilled number
    ---@param noLimit boolean
    CalculateVeterancyLevel = function(self, massKilled, noLimit)
        self.VetExperience = 0
        self.VetLevel = 0
        self:AddVetExperience(massKilled, noLimit)
    end,

    ---@see AddVetLevel
    ---@deprecated
    ---@param self Unit | VeterancyComponent
    ---@param level number
    SetVeteranLevel = function(self, level)
        self.VetExperience = 0
        self.VetLevel = 0
        self:AddVetExperience(self.Blueprint.VetThresholds[MathMin(level, 5)] or 0, true)
    end,

    ---@deprecated
    ---@param self Unit | VeterancyComponent
    GetVeterancyValue = function(self)
        local fractionComplete = self:GetFractionComplete()
        local unitMass = self:GetTotalMassCost()
        local vetMult = self.Blueprint.VeteranImportanceMult or 1
        local cargoMass = self.cargoMass or 0
        -- Allow units to count for more or less than their real mass if needed
        return fractionComplete * unitMass * vetMult + cargoMass
    end,
}

---@class ExternalFactoryComponent
---@field ExternalFactory ExternalFactoryUnit
ExternalFactoryComponent = ClassSimple {

    FactoryAttachBone = false,
    BuildAttachBone = false,

    ---@param self Unit | ExternalFactoryComponent
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        local blueprint = self.Blueprint
        if not self.FactoryAttachBone then
            error(string.format("%s is not setup for an external factory: the unit does not have a field 'FactoryAttachBone'", blueprint.BlueprintId))
        end

        if not self.BuildAttachBone then
            error(string.format("%s is not setup for an external factory: the unit does not have a field 'BuildAttachBone'", blueprint.BlueprintId))
        end

        if self.BuildAttachBone == self.FactoryAttachBone then
            error(string.format("%s is not setup for an external factory: the 'FactoryAttachBone' can not be the same as the 'BuildAttachBone'", blueprint.BlueprintId))
        end

        if not blueprint.CategoriesHash['EXTERNALFACTORY'] then
            error(string.format("%s is not setup for an external factory: the unit does not have a 'EXTERNALFACTORY' category", blueprint.BlueprintId))
        end

        local blueprintIdExternalFactory = blueprint.BlueprintId .. 'ef'
        if not __blueprints[blueprintIdExternalFactory] then
            error(string.format("%s is not setup for an external factory: the external factory blueprint is not setup", blueprint.BlueprintId))
        end

        -- create the factory somewhere completely unrelated
        local px, py, pz = self:GetPositionXYZ(self.FactoryAttachBone)

        self.ExternalFactory = CreateUnitHPR(blueprintIdExternalFactory, self.Army, px, py, pz, 0, 0, 0) --[[@as ExternalFactoryUnit]]
        self.ExternalFactory:AttachTo(self, self.FactoryAttachBone)
        self.ExternalFactory:SetCreator(self)
        self:SetCreator(self.ExternalFactory)
        self.ExternalFactory:SetParent(self)
        self.Trash:Add(self.ExternalFactory)
    end,

    ---@param self Unit | ExternalFactoryComponent
    OnIdle = function(self)
        if self.ExternalFactory and (not IsDestroyed(self.ExternalFactory)) then
            self.ExternalFactory:SetBusy(false)
            self.ExternalFactory:SetBlockCommandQueue(false)
        end
    end,

    ---@param self Unit | ExternalFactoryComponent
    ---@param new Layer
    ---@param old Layer
    OnLayerChange = function(self, new, old)
        if self.ExternalFactory then
            if new == 'Land' then
                self.ExternalFactory:RestoreBuildRestrictions()
                self.ExternalFactory:RequestRefreshUI()
            elseif new == 'Seabed' then
                self.ExternalFactory:AddBuildRestriction(categories.ALLUNITS)
                self.ExternalFactory:RequestRefreshUI()

                IssueToUnitClearCommands(self.ExternalFactory)
            end
        end
    end,

    ---@param self Unit | ExternalFactoryComponent
    OnKilled = function(self, instigator, type, overkillRatio)
        if not IsDestroyed(self.ExternalFactory) then
            self.ExternalFactory:SetBusy(true)
            self.ExternalFactory:SetBlockCommandQueue(true)
            self.ExternalFactory:Kill()
        end
    end,

    -- We need to wait one tick for our unit to "exist" before we can clear its orders
    -- This prevents order graphs from being drawn from units inside the carrier
    ---@param self Unit | ExternalFactoryComponent
    ---@param unitBeingBuilt Unit
    ClearOrdersThread = function(self, unitBeingBuilt)
        WaitTicks(1)
        IssueToUnitClearCommands(unitBeingBuilt)
    end,

    ---@param self Unit | ExternalFactoryComponent
    ---@param unitBeingBuilt Unit
    OnStopBuildWithStorage = function(self, unitBeingBuilt)
        --local unitBeingBuilt = self.UnitBeingBuilt
        unitBeingBuilt:DetachFrom(true)
        self:DetachAll(self.BuildAttachBone)

        if not self:TransportHasAvailableStorage() or self:GetStat('AutoDeploy', 0).Value == 1 then
            unitBeingBuilt:ShowBone(0, true)
        else
            self:AddUnitToStorage(unitBeingBuilt)
            ForkThread(self.ClearOrdersThread, self, unitBeingBuilt)
        end

        self:RequestRefreshUI()
        ChangeState(self, self.IdleState)
    end,

}