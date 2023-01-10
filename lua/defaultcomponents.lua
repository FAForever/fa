
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

local BlueprintNameToIntel = {

    Cloak = 'Cloak',
    CloakField = 'CloakField',
    CloakFieldRadius = 'CloakField',
    JammerBlips = 'Spoof',

    RadarRadius = 'Radar',
    RadarStealth = 'RadarStealth',
    RadarStealthField = 'RadarStealthField',
    RadarStealthFieldRadius = 'RadarStealthField',

    Sonar = 'Sonar',
    SonarRadius = 'Sonar',
    SonarStealth = 'SonarStealth',
    SonarStealthFieldRadius = 'SonarStealthField',
}

---@type table<UnitId, UnitIntelStatus | boolean>
local IntelStatusCache = { }

---@class UnitIntelStatus
---@field AllIntel table<IntelType, boolean>
---@field AllIntelMaintenanceFree table<IntelType, boolean>
---@field AllIntelFromEnhancements table<IntelType, boolean>
---@field AllIntelDisabledByEvent table<IntelType, table<string, boolean>>

---@class IntelComponent
---@field IntelStatus? UnitIntelStatus
IntelComponent = ClassSimple {

    ---@param self IntelComponent | Unit
    OnStopBeingBuilt = function(self, builder, layer)
        -- TODO: perhaps perform all this logic during blueprint loading instead?
        -- check if we've done this already
        local cache = IntelStatusCache[self.UnitId]
        if cache then
            self.IntelStatus = table.deepcopy(cache)
            self:EnableUnitIntel('NotInitialized')
            self.Brain:AddEnergyDependingEntity(self)
            return
        end

        -- gather data
        local intelBlueprint = self.Blueprint.Intel
        local enhancementBlueprints = self.Blueprint.Enhancements
        if intelBlueprint or enhancementBlueprints then
            -- life is good, intel is funded by the government
            if intelBlueprint.FreeIntel then
                return
            end

            ---@type UnitIntelStatus
            local status = { }

            -- special case: unit has intel that is considered free
            status.AllIntelMaintenanceFree = { } -- TODO: catch non existence with if statements
            if intelBlueprint.ActiveIntel then
                for intel, _ in intelBlueprint.ActiveIntel do
                    status.AllIntelMaintenanceFree[intel] = true
                end
            end

            -- special case: unit has enhancements and therefore can have any intel type
            status.AllIntelFromEnhancements = { } -- TODO: catch non existence with if statements
            if enhancementBlueprints then 
            end

            -- usual case: find all remaining intel
            status.AllIntel = { }
            for name, value in intelBlueprint do

                if value == true or value > 0 then
                    local intel = BlueprintNameToIntel[name]
                    if intel then
                        status.AllIntel[intel] = true
                    end
                end
            end

            -- check if we have any intel
            if table.empty(status.AllIntel) and not enhancementBlueprints then
                IntelStatusCache[self.UnitId] = false
                LOG("No intel for: " .. self.UnitId)
                return
            end

            -- cache it
            status.AllIntelDisabledByEvent = { }
            IntelStatusCache[self.UnitId] = status

            reprsl(status)

            -- prepare unit state
            self.IntelStatus = table.deepcopy(status)
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

            -- disable all intel
            local allIntelDisabledByEvent = status.AllIntelDisabledByEvent
            if not intel then
                for i, _ in status.AllIntel do
                    if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if not allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = true
                            self:DisableIntel(i)
                            self:OnIntelDisabled(i)
                        end
                    end
                end

                for i, _ in status.AllIntelFromEnhancements do
                    if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if not allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = true
                            self:DisableIntel(i)
                            self:OnIntelDisabled(i)
                        end
                    end
                end

            -- disable one intel
            elseif status.AllIntel[intel] or status.AllIntelFromEnhancements[intel] then
                -- special case that requires additional book keeping
                if disabler == 'Enhancement' then
                    status.AllIntelFromEnhancements[intel] = true
                end

                if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[intel]) then
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

            -- special case when unit is finished building
            if disabler == 'NotInitialized' then

                -- this bit is weird, but unit logic expects to always have intel immediately enabled when 
                -- the unit is done constructing, regardless whether the unit is able to use the intel
                for i, _ in status.AllIntel do
                    self:OnIntelEnabled(i)
                    self:EnableIntel(i)
                end

                for i, _ in status.AllIntelMaintenanceFree do
                    self:EnableIntel(i)
                    self:OnIntelEnabled(i)
                end

                return
            end

            -- disable all intel
            local allIntelDisabledByEvent = status.AllIntelDisabledByEvent
            if not intel then
                for i, _ in status.AllIntel do
                    if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = nil
                            if table.empty(allIntelDisabledByEvent[i]) then
                                self:EnableIntel(i)
                                self:OnIntelEnabled(i)
                            end
                        end
                    end
                end

                for i, _ in status.AllIntelFromEnhancements do
                    if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[i]) then
                        allIntelDisabledByEvent[i] = allIntelDisabledByEvent[i] or { }
                        if allIntelDisabledByEvent[i][disabler] then
                            allIntelDisabledByEvent[i][disabler] = nil
                            if table.empty(allIntelDisabledByEvent[i]) then
                                self:EnableIntel(i)
                                self:OnIntelEnabled(i)
                            end
                        end
                    end
                end

            -- disable one intel
            elseif status.AllIntel[intel] or status.AllIntelFromEnhancements[intel] then
                -- special case that requires additional book keeping
                if disabler == 'Enhancement' then
                    status.AllIntelFromEnhancements[intel] = true
                end

                if not (disabler == 'Energy' and status.AllIntelMaintenanceFree[intel]) then
                    allIntelDisabledByEvent[intel] = allIntelDisabledByEvent[intel] or { }
                    if allIntelDisabledByEvent[intel][disabler] then
                        allIntelDisabledByEvent[intel][disabler] = nil
                        if table.empty(allIntelDisabledByEvent[intel]) then
                            self:EnableIntel(intel)
                            self:OnIntelEnabled(intel)
                        end
                    end
                end
            end

            reprsl(status)
        end
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelEnabled = function(self, intel)
        LOG(debug.traceback())
        LOG("Enabled intel: " .. tostring(intel))
    end,

    ---@param self IntelComponent | Unit
    ---@param intel? IntelType
    OnIntelDisabled = function(self, intel)
        LOG("Disabled intel: " .. tostring(intel))
    end,

}