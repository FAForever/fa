local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty


---@class AIPlatoonFatboyFactoryModule : AIPlatoon
---@field Fatboy UEL0401
---@field FatboyFactoryModule ExternalFactoryUnit
---@field StateInfo { BlueprintToBuilt: UnitId }
AIPlatoonFatboyFactoryModule = Class(AIPlatoon) {

    PlatoonName = 'AIPlatoonFatboyFactoryModule',

    ShouldBuildAntiAir = false,
    ShouldBuildShield = false,

    UnitsAntiAir = { 'uel0104', 'uel0205', 'uel0205', 'uel0205', 'uel0205', 'delk002', 'delk002' },
    UnitsShield = { 'uel0307' },
    UnitsDirectFire = { 'uel0303', 'uel0303', 'xel0305', 'xel0305', 'uel0202' },

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonFatboyFactoryModule
        Main = function(self)
            -- requires expansion markers
            if not import("/lua/sim/markerutilities/expansions.lua").IsGenerated() then
                self:LogWarning('requires generated expansion markers')
                self:ChangeState(self.Error)
                return
            end

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                self:LogWarning('requires generated navigational mesh')
                self:ChangeState(self.Error)
                return
            end

            -- requires exactly one factory module
            local units = self:GetPlatoonUnits()
            local modules = EntityCategoryFilterDown(categories.EXTERNALFACTORYUNIT, units)

            if TableGetn(modules) == 0 then
                self:LogWarning('requires one factory module to run')
                self:ChangeState(self.Error)
                return
            end

            if TableGetn(modules) > 1 then
                self:LogWarning('can not manage multiple factory modules')
                self:ChangeState(self.Error)
                return
            end

            self.FatboyFactoryModule = modules[1] --[[@as ExternalFactoryUnit]]
            self.Fatboy = self.FatboyFactoryModule:GetParent() --[[@as UEL0401]]
            self:ChangeState(self.Idling)
            return
        end,
    },

    Idling = State {

        StateName = 'Idling',

        ---@param self AIPlatoonFatboyFactoryModule
        Main = function(self)
            -- we can't build underwater
            local position = self.Fatboy:GetPosition()
            local surface = GetSurfaceHeight(position[1], position[3])
            local isUnderwater = position[2] < surface

            if isUnderwater then
                WaitTicks(40)
                self:ChangeState(self.Idling)
                return
            end

            -- determine category to built
            local blueprintsToBuilt = self.UnitsDirectFire
            if self.ShouldBuildShield then
                blueprintsToBuilt = self.UnitsShield
            end

            if self.ShouldBuildAntiAir then
                blueprintsToBuilt = self.UnitsAntiAir
            end

            -- try and built it
            local unitToBuilt = table.random(blueprintsToBuilt)
            if self.FatboyFactoryModule:CanBuild(unitToBuilt) then
                self:ChangeState(self.Building, { BlueprintToBuilt = unitToBuilt})
                return
            end

            WaitTicks(10)
            self:ChangeState(self.Idling)
            return
        end,

    },

    Building = State {

        StateName = 'Building',

        ---@param self AIPlatoonFatboyFactoryModule
        Main = function(self)

            -- retrieve state
            local stateInfo = self.StateInfo
            local blueprintToBuilt = stateInfo.BlueprintToBuilt

            if self.FatboyFactoryModule:CanBuild(blueprintToBuilt) then
                IssueBuildFactory({self.FatboyFactoryModule}, blueprintToBuilt, 1)
            else
                WaitTicks(10)
                self:ChangeState(self.Idling)
                return
            end
        end,

        --- Called as a unit of this platoon stops building
        ---@param self AIPlatoonFatboyFactoryModule
        ---@param unit Unit
        ---@param target Unit
        OnStopBuild = function(self, unit, target)
            -- we stopped building, but there is no unit
            if (not unit) or IsDestroyed(unit) then
                -- go back to building a unit
                self:ChangeStateAlt(self.Idling)
                return
            end

            -- check if the fatboy still exists
            local units = {unit}
            local brain = self.FatboyFactoryModule.Brain
            local platoonReference = self.Fatboy.AIPlatoonReference
            if IsDestroyed(platoonReference) then
                -- TODO: give unit to nearest base?
                self:LogDebug("platoon reference is destroyed")
                return
            end

            -- try and assign unit to a platoon
            if EntityCategoryContains(categories.DIRECTFIRE, unit) then
                brain:AssignUnitsToPlatoon(platoonReference, units, 'Attack', 'None')
            elseif EntityCategoryContains(categories.ANTIAIR + categories.SHIELD, unit) then
                brain:AssignUnitsToPlatoon(platoonReference, units, 'Support', 'None')
            elseif EntityCategoryContains(categories.SCOUT, unit) then 
                brain:AssignUnitsToPlatoon(platoonReference, units, 'Scout', 'None')
            elseif EntityCategoryContains(categories.ARTILLERY, unit) then
                brain:AssignUnitsToPlatoon(platoonReference, units, 'Artillery', 'None')
            end

            -- go back to building a unit
            self:ChangeStateAlt(self.Idling)
            return
        end,
    },

    -----------------------------------------------------------------
    -- brain events
}

---@class AIPlatoonFatboy : AIPlatoon
---@field Fatboy UEL0401
---@field FatboyFactoryModule ExternalFactoryUnit
---@field AirScanningThreadInstance thread
---@field GroundScanningThreadInstance thread
AIPlatoonFatboy = Class(AIPlatoon) {

    PlatoonName = 'AIPlatoonFatboy',

    ScanDelay = 10,

    AirScanRadius = 120,
    GroundScanRadius = 100,

    ---@param self AIPlatoonFatboy
    AirScanningThread = function(self)
        while not IsDestroyed(self.Fatboy) do
            local position = self.Fatboy:GetPosition()
            local surface = GetSurfaceHeight(position[1], position[3])
            local isUnderwater = position[2] < surface

            -- determine threats based on whether we're underwater or not
            local threats
            if isUnderwater then
                DrawCircle(position, self.AirScanRadius, '99EBFF')
                threats = self.Fatboy.Brain:GetUnitsAroundPoint(categories.AIR * (categories.BOMBER + categories.GROUNDATTACK), position, self.AirScanRadius, 'Enemy')
            else
                DrawCircle(position, self.AirScanRadius, '9999ff')
                threats = self.Fatboy.Brain:GetUnitsAroundPoint(categories.AIR * (categories.BOMBER * categories.TORPEDO), position, self.AirScanRadius, 'Enemy')
            end

            -- determine tech levels of found threats
            local threatsTech1 = TableGetn(EntityCategoryFilterDown(categories.TECH1, threats))
            local threatsTech2 = TableGetn(EntityCategoryFilterDown(categories.TECH2, threats))
            local threatsTech3 = TableGetn(EntityCategoryFilterDown(categories.TECH3, threats))
            local threatsTech4 = TableGetn(EntityCategoryFilterDown(categories.EXPERIMENTAL, threats))

            if TableGetn(threats) > 0 then

            end


            WaitTicks(self.ScanDelay)
        end
    end,

    ---@param self AIPlatoonFatboy
    GroundScanningThread = function(self)
        while not IsDestroyed(self.Fatboy) do
            WaitTicks(self.ScanDelay)
        end
    end,

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonFatboy
        Main = function(self)
            -- requires expansion markers
            if not import("/lua/sim/markerutilities/expansions.lua").IsGenerated() then
                self:LogWarning('requires generated expansion markers')
                self:ChangeState(self.Error)
                return
            end

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                self:LogWarning('requires generated navigational mesh')
                self:ChangeState(self.Error)
                return
            end

            -- requires exactly one fatboy
            local units = self:GetPlatoonUnits()
            local fatboys = EntityCategoryFilterDown(categories.uel0401, units)

            if TableGetn(fatboys) == 0 then
                self:LogWarning('requires one fatboy to run')
                self:ChangeState(self.Error)
                return
            end

            if TableGetn(fatboys) > 1 then
                self:LogWarning('can not manage multiple fatboys')
                self:ChangeState(self.Error)
                return
            end

            self.Fatboy = fatboys[1] --[[@as UEL0401]]
            self.FatboyFactoryModule = self.Fatboy.ExternalFactory

            -- start state machine for factory module
            local brain = self.Fatboy.Brain
            local platoon = brain:MakePlatoon(tostring(self) .. ' - external factory unit', '') --[[@as AIPlatoonSimpleRaidBehavior]]
            setmetatable(platoon, AIPlatoonFatboyFactoryModule)
            brain:AssignUnitsToPlatoon(platoon, { self.FatboyFactoryModule }, 'Unassigned', 'None')
            ChangeState(platoon, platoon.Start)

            -- start scanning behavior
            self.AirScanningThreadInstance = self.Trash:Add(ForkThread(
                self.AirScanningThread, self
            ))

            self.GroundScanningThreadInstance = self.Trash:Add(ForkThread(
                self.AirScanningThread, self
            ))

            self:ChangeState(self.Idling)
            return
        end,
    },

    Idling = State {

        StateName = 'Idling',

        ---@param self AIPlatoonFatboy
        Main = function(self)

            while true do
                WaitTicks(10)
            end
        end,
    },

    Retreating = State {

        StateName = "Retreating",

        ---@param self AIPlatoonFatboy
        Main = function(self)
        end,
    },

    Sieging = State {

        StateName = "Sieging",

        ---@param self AIPlatoonFatboy
        Main = function(self)
        end,
    },

    -----------------------------------------------------------------
    -- brain events

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToAttackSquad = function(self, units)
        self:LogWarning('no support for units in attack squad')
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToScoutSquad = function(self, units)
        self:LogWarning('no support for units in scout squad')
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToArtillerySquad = function(self, units)
        self:LogWarning('no support for units in artillery squad')
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToSupportSquad = function(self, units)
        self:LogWarning('no support for units in support squad')
    end,

    ---@param self AIPlatoon
    ---@param units Unit[]
    OnUnitsAddedToGuardSquad = function(self, units)
        self:LogWarning('no support for units in guard squad')
    end,
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()

        -- create the platoon
        local brain = units[1].Brain
        local platoon = brain:MakePlatoon('', '') --[[@as AIPlatoonSimpleRaidBehavior]]
        setmetatable(platoon, AIPlatoonFatboy)

        -- assign units to squads
        local fatboy = EntityCategoryFilterDown(categories.uel0401, units)
        local scouts = EntityCategoryFilterDown(categories.SCOUT, units)
        local support = EntityCategoryFilterDown(categories.ANTIAIR + categories.SHIELD, units)
        local artillery = EntityCategoryFilterDown(categories.ARTILLERY + categories.MISSILE, units)
        local directfire = EntityCategoryFilterDown(categories.DIRECTFIRE, units)

        brain:AssignUnitsToPlatoon(platoon, fatboy, 'Unassigned', 'None')
        brain:AssignUnitsToPlatoon(platoon, directfire, 'Attack', 'None')
        brain:AssignUnitsToPlatoon(platoon, scouts, 'Scout', 'None')
        brain:AssignUnitsToPlatoon(platoon, artillery, 'Artillery', 'None')
        brain:AssignUnitsToPlatoon(platoon, support, 'Support', 'None')

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end
