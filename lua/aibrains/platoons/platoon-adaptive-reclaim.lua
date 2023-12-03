local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")
local TransportUtils = import("/lua/ai/transportutilities.lua")
local AIUtils = import("/lua/ai/aiutilities.lua")

local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty
local TableInsert = table.insert

-- I'm up to navigating. Specifically the reclaim check.

---@class AIPlatoonAdaptiveReclaimBehavior : AIPlatoon
---@field ThreatToEvade Vector | nil
---@field LocationToReclaim Vector | nil
AIPlatoonAdaptiveReclaimBehavior = Class(AIPlatoon) {

    PlatoonName = 'AdaptiveReclaimBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            local brain = self:GetBrain()

            if not self.SearchRadius then
                local maxMapDimension = math.max(ScenarioInfo.size[1], ScenarioInfo.size[2])
                if maxMapDimension == 256 then
                    self.SearchRadius = 8
                else
                    self.SearchRadius = 16
                end
            end

            if not brain.GridReclaim then
                self:LogWarning('requires reclaim grid to be generated and running')
                self:ChangeState(self.Error)
                return
            end
            if self.PlatoonData.LocationType then
                self.LocationType = self.PlatoonData.LocationType
            else
                self.LocationType = 'MAIN'
            end

            self.CellSize = brain.GridReclaim.CellSize * brain.GridReclaim.CellSize

            -- requires navigational mesh
            if not NavUtils.IsGenerated() then
                self:LogWarning('requires generated navigational mesh')
                self:ChangeState(self.Error)
                return
            end

            -- Set the movement layer for pathing, included for mods where water or air based engineers may exist
            self.MovementLayer = self:GetNavigationalLayer()

            self:ChangeState(self.Searching)
            return
        end,
    },

    Searching = State {

        StateName = 'Searching',

        --- The platoon searches for a target
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            -- reset state
            self.LocationToReclaim = nil
            self.ThreatToEvade = nil

            self:Stop()
            local brain = self:GetBrain()
            local reclaimGridInstance = brain.GridReclaim
            local brainGridInstance = brain.GridBrain
            local searchRadius = self.SearchRadius

            local units, unitCount = self:GetPlatoonUnits()
            local eng = units[1]
            local searchLoop = 0
            local reclaimTargetX, reclaimTargetZ
            local engPos = eng:GetPosition()
            local gx, gz = reclaimGridInstance:ToGridSpace(engPos[1], engPos[3])
            local imapRadius = brain.IMAPConfig.Rings or 0
            local pathFailTable = {}
            while searchLoop < searchRadius and (not (reclaimTargetX and reclaimTargetZ)) do
                WaitTicks(1)

                -- retrieve a list of cells with some mass value
                local cells, count = reclaimGridInstance:FilterAndSortInRadius(gx, gz, searchRadius, 10)
                -- find out if we can path to the center of the cell and check engineer maximums
                for k = 1, count do
                    local cell = cells[k] --[[@as AIGridReclaimCell]]
                    local centerOfCell = reclaimGridInstance:ToWorldSpace(cell.X, cell.Z)
                    local maxEngineers = math.min(math.ceil(cell.TotalMass / 500), 8)

                    -- make sure we can path to it and it doesnt have high threat e.g Point Defense
                    if NavUtils.CanPathToCell(self.MovementLayer, engPos, centerOfCell) 
                        and brain:GetThreatAtPosition(centerOfCell, imapRadius, true, 'AntiSurface') < 10 then

                        local brainCell = brainGridInstance:ToCellFromGridSpace(cell.X, cell.Z)
                        local engineersInCell = brainGridInstance:CountReclaimingEngineers(brainCell)
                        if engineersInCell < maxEngineers then
                            reclaimTargetX, reclaimTargetZ = cell.X, cell.Z
                            break
                        end
                    elseif brain:GetThreatAtPosition(centerOfCell, imapRadius, true, 'AntiSurface') < 10 then
                        TableInsert(pathFailTable, { center = centerOfCell, x = cell.X, z = cell.Z })
                    end
                    WaitTicks(1)
                end

                searchLoop = searchLoop + 1
                if searchLoop == searchRadius and (not (reclaimTargetX and reclaimTargetZ)) and TableGetn(pathFailTable) > 0 then
                    self:LogDebug(string.format('Loop failed and we have unpathable reclaim'))
                    local closestReclaimDistance
                    local closestReclaim
                    for _, v in pathFailTable do
                        local distance = VDist3Sq(engPos, v.center)
                        if not closestReclaim or distance < closestReclaimDistance then
                            closestReclaim = v
                            closestReclaimDistance = distance
                            reclaimTargetX, reclaimTargetZ = v.x, v.z
                        end
                    end
                end
                self:LogDebug('Search loop is ' .. searchLoop .. ' out of a possible ' .. searchRadius)
            end
            if reclaimTargetX and reclaimTargetZ then
                local brainCell = brainGridInstance:ToCellFromGridSpace(reclaimTargetX, reclaimTargetZ)
                -- Assign engineer to cell
                self.CellAssigned = { reclaimTargetX, reclaimTargetZ }
                brainGridInstance:AddReclaimingEngineer(brainCell, eng)
                self.LocationToReclaim = reclaimGridInstance:ToWorldSpace(reclaimTargetX, reclaimTargetZ)
                local dx = self.LocationToReclaim[1] - engPos[1]
                local dz = self.LocationToReclaim[3] - engPos[3]
                if dx * dx + dz * dz < 1225 then
                    self:ChangeState(self.ReclaimCell)
                    return
                else
                    self:ChangeState(self.Navigating)
                    return
                end
            else
                if self.SearchRadius < 8 then
                    self.SearchRadius = 8
                    self:LogDebug(string.format('No reclaim found, extending search range to 8'))
                    WaitTicks(10)
                    self:ChangeState(self.Searching)
                    return
                end
                self:LogWarning(string.format('no reclaim target found'))
                brain.ReclaimFailCounter = brain.ReclaimFailCounter + 1
                if brain.ReclaimFailTimeStamp == 0 then
                    brain.ReclaimFailTimeStamp = GetGameTimeSeconds()
                end
                local closestManagerDist
                local returnPos
                if eng.BuilderManagerData.EngineerManager.Location then
                    returnPos = eng.BuilderManagerData.EngineerManager.Location
                end
                if not returnPos then
                    for _,v in brain.BuilderManagers do
                        local basePos = v.EngineerManager:GetLocationCoords()
                        local baseDist = VDist3Sq(engPos, basePos)
                        if not closestManagerDist or (baseDist < closestManagerDist and NavUtils.CanPathTo('Amphibious', engPos, basePos)) then
                            closestManagerDist = baseDist
                            returnPos = basePos
                        end
                    end
                end
                if returnPos and VDist3Sq(engPos, returnPos) < 6400 then
                    self:LogDebug(string.format('Exiting Reclaim state machine'))
                    WaitTicks(20)
                    self:ExitStateMachine()
                    return
                elseif returnPos then
                    self.LocationToReclaim = returnPos
                    self:ChangeState(self.Navigating)
                else
                    self:ChangeState(self.Error)
                end
                return
            end
        end,

    },

    Navigating = State {

        StateName = 'Navigating',

        --- The platoon navigates towards a target, picking up oppertunities as it finds them
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            -- reset state
            self.ThreatToEvade = nil

            -- sanity check
            local destination = self.LocationToReclaim
            if not destination then
                self:LogWarning(string.format('no destination to navigate to'))
                WaitTicks(20)
                self:ChangeState(self.Searching)
                return
            end
            local brain = self:GetBrain()
            self:Stop()

            local units, unitCount = self:GetPlatoonUnits()
            local eng = units[1]
            local cache = { 0, 0, 0 }

            if not brain.GridPresence then
                WARN('GridPresence does not exist, unable to detect conflict line')
            end
            if not NavUtils.CanPathToCell(self.MovementLayer, eng:GetPosition(), destination) then
                self:LogDebug(string.format('Reclaim engineer is going to use transport'))
                WaitTicks(20)
                self:ChangeState(self.Transporting)
                return
            end
            self:LogDebug(string.format('Reclaim engineer navigating to position '..repr(destination)))

            while not IsDestroyed(self) do
                local origin = eng:GetPosition()

                -- generate a direction
                local waypoint, length = NavUtils.DirectionTo(self.MovementLayer, origin, destination, 60)

                -- something odd happened: no direction found
                if not waypoint then
                    self:LogWarning(string.format('No Direction waypoint returned'))
                    WaitTicks(20)
                    self:ChangeState(self.Searching)
                    return
                end

                -- we're near the destination, better start raiding it!
                if waypoint == destination then
                    self:ChangeState(self.ReclaimCell)
                    return
                end


                IssueMove({ eng }, waypoint)
                local engStuckCount = 0
                local Lastdist
                local dist = VDist3Sq(eng:GetPosition(), destination)
                local cellSize = self.CellSize

                -- Statemachine switch for engineer moving to location
                while not IsDestroyed(eng) and dist > cellSize do
                    WaitTicks(25)
                    if brain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, eng:GetPosition(), 45, 'Enemy')
                        > 0 then
                        -- Statemachine switch to avoiding/reclaiming danger
                        self:ChangeState(self.Retreating)
                        return
                    else
                        -- Jip discussed potentially getting navmesh to return mass points along the path rather than this.
                        -- Potential Statemachine switch to building extractors
                        if not IsDestroyed(eng) and not eng:IsUnitState('Reclaiming') then
                            local reclaimAction = AIUtils.EngPerformReclaim(eng, 10)
                            if reclaimAction then
                                WaitTicks(45)
                                -- Statemachine switch to evaluating next action to take
                                IssueMove({ eng }, waypoint)
                            end
                        end
                        if not IsDestroyed(eng) then
                            local bool, markers = AIUtils.CanBuildOnGridMassPoints(brain, eng:GetPosition(), 35, self.MovementLayer)
                            if bool then
                                self.MassPointTable = markers
                                self:ChangeState(self.BuilderStructure)
                                return
                            end
                        end
                    end
                    dist = VDist3Sq(eng:GetPosition(), waypoint)
                    if Lastdist ~= dist then
                        engStuckCount = 0
                        Lastdist = dist
                    elseif not eng:IsUnitState('Reclaiming') then
                        engStuckCount = engStuckCount + 1
                        if engStuckCount > 15 then
                            break
                        end
                    end
                end
                if IsDestroyed(eng) then
                    return
                end
                if dist <= cellSize then
                    -- Statemachine switch to reclaiming state
                    self:ChangeState(self.ReclaimCell)
                    return
                end

                -- always wait
                WaitTicks(1)
            end
        end,
    },

    BuilderStructure = State {

        StateName = 'BuilderStructure',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            if not self.MassPointTable then
                self:ChangeState(self.Error)
                return
            end

            self:LogDebug('Attempting to build a mass point or two')

            local units, unitCount = self:GetPlatoonUnits()
            local eng = units[1]
            local brain = self:GetBrain()
            IssueClearCommands({ eng })
            local factionIndex = brain:GetFactionIndex()
            local buildingTmplFile = import('/lua/BuildingTemplates.lua')
            local buildingTmpl = buildingTmplFile[('BuildingTemplates')][factionIndex]
            local whatToBuild = brain:DecideWhatToBuild(eng, 'T1Resource', buildingTmpl)
            for _, massMarker in self.MassPointTable do
                AIUtils.EngineerTryReclaimCaptureArea(brain, eng, massMarker.Position, 2)
                AIUtils.EngineerTryRepair(brain, eng, whatToBuild, massMarker.Position)
                if massMarker.BorderWarning then
                    IssueBuildMobile({ eng }, massMarker.Position, whatToBuild, {})
                else
                    brain:BuildStructure(eng, whatToBuild, { massMarker.Position[1], massMarker.Position[3], 0 }, false)
                end
            end
            while eng and not eng.Dead and
                (0 < table.getn(eng:GetCommandQueue()) or eng:IsUnitState('Building') or eng:IsUnitState("Moving")) do
                coroutine.yield(20)
            end
            self.MassPointTable = nil
            self:ChangeState(self.Searching)
            return
        end,
    },

    Retreating = State {

        StateName = 'Retreating',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            local units, unitCount = self:GetPlatoonUnits()
            local eng = units[1]
            local brain = self:GetBrain()

            local engPos = eng:GetPosition()
            local enemyUnits = brain:GetUnitsAroundPoint(categories.LAND * categories.MOBILE, engPos, 45, 'Enemy')
            local action = false
            for _, unit in enemyUnits do
                local enemyUnitPos = unit:GetPosition()
                if EntityCategoryContains(categories.SCOUT + categories.ENGINEER * (categories.TECH1 + categories.TECH2)
                    - categories.COMMAND, unit) then
                    if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 144 then
                        if unit and not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                            if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 156 then
                                IssueClearCommands({ eng })
                                IssueReclaim({ eng }, unit)
                                action = true
                                break
                            end
                        end
                    end
                elseif EntityCategoryContains(categories.LAND * categories.MOBILE - categories.SCOUT, unit) then
                    if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 81 then
                        if unit and not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                            if VDist2Sq(engPos[1], engPos[3], enemyUnitPos[1], enemyUnitPos[3]) < 156 then
                                IssueClearCommands({ eng })
                                IssueReclaim({ eng }, unit)
                                action = true
                                break
                            end
                        end
                    else
                        IssueClearCommands({ eng })
                        IssueMove({ eng }, AIUtils.ShiftPosition(enemyUnitPos, engPos, 50, false))
                        coroutine.yield(60)
                        action = true
                    end
                end
            end
            self:ChangeState(self.Searching)
            return
        end,
    },

    ReclaimCell = State {

        StateName = 'ReclaimCell',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            local units, unitCount = self:GetPlatoonUnits()
            local eng = units[1]
            local brain = self:GetBrain()
            local reclaimGridInstance = brain.GridReclaim
            local reclaimTargetX = self.CellAssigned[1]
            local reclaimTargetZ = self.CellAssigned[2]
            local reclaimPos = self.LocationToReclaim
            local action = false
            local time = 0
            IssueClearCommands({ eng })
            while time < 30 do
                IssueAggressiveMove({ eng }, reclaimPos)
                time = time + 1
                WaitTicks(50)
                local engPos = eng:GetPosition()
                if brain:GetNumUnitsAroundPoint(categories.LAND * categories.MOBILE, engPos, 45, 'Enemy') > 0 then
                    -- Statemachine switch to avoiding/reclaiming danger
                    local actionTaken = AIUtils.EngAvoidLocalDanger(brain, eng)
                    if actionTaken then
                        -- Statemachine switch to evaluating next action to take
                        IssueAggressiveMove({ eng }, reclaimPos)
                    end
                end
                if reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].TotalMass < 10 or
                    brain:GetEconomyStoredRatio('MASS') > 0.95 then
                    break
                end
                if VDist3Sq(engPos, reclaimPos) < 4 and
                    reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].TotalMass > 5 then
                    for _, v in reclaimGridInstance.Cells[reclaimTargetX][reclaimTargetZ].Reclaim do
                        if IsProp(v) and v.MaxMassReclaim > 0 then
                            reclaimPos = v:GetPosition()
                            IssueClearCommands({ eng })
                            break
                        end
                    end
                end
            end

            self:ChangeState(self.Searching)
            return
        end,
    },

    Transporting = State {

        StateName = 'Transporting',

        --- The platoon avoids danger or attempts to reclaim if they are too close to avoid
        ---@param self AIPlatoonAdaptiveReclaimBehavior
        Main = function(self)
            local brain = self:GetBrain()
            local usedTransports = TransportUtils.SendPlatoonWithTransports(brain, self, self.LocationToReclaim, 3, false)
            if usedTransports then
                self:LogDebug(string.format('Engineer used transports'))
                self:ChangeState(self.Navigating)
            else
                self:LogDebug(string.format('Engineer tried but didnt use transports'))
                self:ChangeState(self.Searching)
            end
            return
        end,
    },


}

---@param data { Behavior: 'AIPlatoonAdaptiveReclaimBehavior' }
---@param units Unit[]
AssignToUnitsMachine = function(data, platoon, units)
    if units and not TableEmpty(units) then

        -- meet platoon requirements
        import("/lua/sim/navutils.lua").Generate()
        import("/lua/sim/markerutilities.lua").GenerateExpansionMarkers()
        -- create the platoon
        setmetatable(platoon, AIPlatoonAdaptiveReclaimBehavior)
        local count = TableGetn(platoon:GetPlatoonUnits())
        local engineers = platoon:GetPlatoonUnits()
        if engineers then
            local platoonCount = 0
            for _, eng in engineers do
                platoonCount = platoonCount + 1
                if platoonCount > 1 then
                    eng.PlatoonHandle = nil
                    eng.AssistSet = nil
                    eng.AssistPlatoon = nil
                    eng.UnitBeingAssist = nil
                    eng.ReclaimInProgress = nil
                    eng.CaptureInProgress = nil
                    if eng:IsPaused() then
                        eng:SetPaused(false)
                    end
                    if not eng.Dead and eng.BuilderManagerData then
                        if eng.BuilderManagerData.EngineerManager then
                            eng.BuilderManagerData.EngineerManager:TaskFinished(eng)
                        end
                    end
                    if not eng.Dead then
                        IssueStop({ eng })
                        IssueClearCommands({ eng })
                    end
                end
            end
        end

        if platoon.PlatoonData.SearchType == 'MAIN' then
            platoon.SearchRadius = platoon:GetBrain().IMAPConfig.Rings
        end

        -- TODO: to be removed until we have a better system to populate the platoons
        platoon:OnUnitsAddedToPlatoon()

        -- start the behavior
        ChangeState(platoon, platoon.Start)
    end
end
