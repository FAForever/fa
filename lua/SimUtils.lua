-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

------------------------------------------------------------------------------------------------------------------------
--#region General Unit Transfer Scripts

local CreateWreckage = import("/lua/wreckage.lua").CreateWreckage

local transferUnbuiltCategory = categories.ALLUNITS
local transferUnitsCategory = categories.ALLUNITS - categories.INSIGNIFICANTUNIT
local buildersCategory = categories.ALLUNITS - categories.CONSTRUCTION - categories.ENGINEER

---@class FactoryRebuildData
---@field FacRebuild_Progress number # progress -- save current progress for some later checks
---@field FacRebuild_BuildTime number # progress * bp.Economy.BuildTime
---@field FacRebuild_Health number # unitBeingBuilt:GetHealth()
---@field FacRebuild_OldBuildRate? number

---@alias FactoryRebuildDataTable table<UnitId, (FactoryUnit | FactoryRebuildData)[]>

---@param factoryRebuildDataTable FactoryRebuildDataTable
function FactoryRebuildUnits(factoryRebuildDataTable)
    for buildUnitId, factories in factoryRebuildDataTable do
        IssueClearCommands(factories)
        IssueBuildFactory(factories, buildUnitId, 1)
    end
    -- wait for build order to start and then rebuild the units for free
    WaitTicks(1)
    for k, factories in pairs(factoryRebuildDataTable) do
        for i, factory in pairs(factories) do
            if factory.Dead then
                factories[i] = nil
                if table.empty(factories) then
                    factoryRebuildDataTable[k] = nil
                end
                continue
            end

            factory.FacRebuild_OldBuildRate = factory:GetBuildRate()
            factory:SetBuildRate(factory.FacRebuild_BuildTime * 10)
            factory:SetConsumptionPerSecondEnergy(0)
            factory:SetConsumptionPerSecondMass(0)
        end
    end
    -- wait for buildpower to apply then return the factories to normal and pause them
    WaitTicks(1)
    for k, factories in pairs(factoryRebuildDataTable) do
        for i, factory in pairs(factories) do
            if factory.Dead then
                factories[i] = nil
                if table.empty(factories) then
                    factoryRebuildDataTable[k] = nil
                end
                continue
            end

            factory:SetBuildRate(factory.FacRebuild_OldBuildRate)
            -- consumption values will update back to normal through `Unit:OnPaused`
            factory:SetPaused(true)
            -- A hack to make the UI show the pause icon over the base unit.
            -- I hope nobody else uses `Unit.Parent` in any other way. `GetParent` for exfacs doesn't return the base unit.
            -- TODO: Add a SetPaused hook into all the exfac class units (the class hiearchy is ambiguous) so this isn't necessary.
            local parent = factory--[[@as ExternalFactoryUnit]].Parent
            if parent then
                parent:SetPaused(true)
            end

            -- First make sure rebuilding went correctly
            local rebuiltUnit = factory.UnitBeingBuilt
            if not rebuiltUnit or math.abs(rebuiltUnit:GetFractionComplete() - factory.FacRebuild_Progress) > 0.001 then
                if rebuiltUnit then
                    rebuiltUnit:Destroy()
                    rebuiltUnit = nil
                end
                IssueClearCommands({ factory })
                factory:SetPaused(false)
                WARN(string.format(
                    [[FactoryRebuildUnits failed to rebuild correctly for factory %s (entity ID %d).
Rebuild data:
Progress: %f
BuildTime: %f
Health: %f
%s]]
                    , factory.UnitId
                    , factory:GetEntityId()
                    , factory.FacRebuild_Progress
                    , factory.FacRebuild_BuildTime
                    , factory.FacRebuild_Health
                    , factory.FacRebuild_OldBuildRate
                    , debug.traceback()
                ))
            end

            if rebuiltUnit then
                -- Set correct health for the rebuilt unit in case it was damaged in the factory
                rebuiltUnit:SetHealth(nil, factory.FacRebuild_Health)
            end

            -- clean up after the rebuilding
            factory.FacRebuild_Progress = nil
            factory.FacRebuild_BuildTime = nil
            factory.FacRebuild_Health = nil
            factory.FacRebuild_OldBuildRate = nil
        end
    end
end

-- used to make more expensive units transfer first, in case there's a unit cap issue
local function TransferUnitsOwnershipComparator(a, b)
    a = a.Blueprint or a.Blueprint
    b = b.Blueprint or b.Blueprint
    return a.Economy.BuildCostMass > b.Economy.BuildCostMass
end

local sharedUnits = {}

--- Transfers units to an army, returning the new units (since changing the army
--- replaces the units with new ones)
---@param units Unit[]
---@param toArmy integer
---@param captured? boolean
---@param noRestrictions? boolean
---@return Unit[]?
function TransferUnitsOwnership(units, toArmy, captured, noRestrictions)
    local toBrain = GetArmyBrain(toArmy)
    if not toBrain or (not noRestrictions and toBrain:IsDefeated())
        or table.empty(units)
    then
        return
    end
    local categoriesENGINEERSTATION = categories.ENGINEERSTATION
    local shareUpgrades = ScenarioInfo.Options.Share ~= 'ShareUntilDeath'

    -- do not gift insignificant units
    units = EntityCategoryFilterDown(transferUnitsCategory, units)

    -- gift most valuable units first
    table.sort(units, TransferUnitsOwnershipComparator)

    local newUnitCount = 0
    local newUnits = {}
    local upgradeUnitCount = 0
    local upgradeUnits = {}
    local pauseKennelCount = 0
    local pauseKennels = {}
    local upgradeKennelCount = 0
    local upgradeKennels = {}
    ---@type FactoryRebuildDataTable
    local factoryRebuildDataTable = {}

    for _, unit in units do
        local owner = unit.Army
        -- Only allow units not attached to be given. This is because units will give all of its
        -- children over as well, so we only want the top level units to be given.
        -- Units currently being captured are also denied
        if owner == toArmy or
            unit:GetParent() ~= unit or (unit.Parent and unit.Parent ~= unit) or
            unit.CaptureProgress > 0 or
            unit:GetFractionComplete() < 1.0
        then
            continue
        end

        local bp = unit.Blueprint
        local bpPhysics = bp.Physics
        local categoriesHash = bp.CategoriesHash

        -- B E F O R E
        local orientation = unit:GetOrientation()
        local workprogress = unit:GetWorkProgress()
        local numNukes = unit:GetNukeSiloAmmoCount() -- nuclear missiles; SML or SMD
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local massKilled = unit.VetExperience
        local unitHealth = unit:GetHealth()
        local tarmacs = unit--[[@as StructureUnit]].TarmacBag
        local shieldIsOn = false
        local shieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local activeEnhancements
        local oldowner = unit.oldowner
        local LastTickDamaged = unit--[[@as ACUUnit]].LastTickDamaged
        local upgradesTo = unit.UpgradesTo
        local defaultBuildRate
        local upgradeBuildTimeComplete
        local exclude
        local FacRebuild_UnitId
        local FacRebuild_Progress
        local FacRebuild_BuildTime
        local FacRebuild_Health

        local shield = unit.MyShield
        if shield then
            shieldIsOn = unit:ShieldIsOn()
            shieldHealth = shield:GetHealth()
        end
        local fuelUseTime = bpPhysics.FuelUseTime
        if fuelUseTime and fuelUseTime > 0 then -- going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio() -- usage is more reliable then unit.HasFuel
            hasFuel = true -- cause some buildings say they use fuel
        end
        local enhancements = bp.Enhancements
        if enhancements then
            local unitEnh = SimUnitEnhancements[unit.EntityId]
            if unitEnh then
                activeEnhancements = {}
                for i, enh in unitEnh do
                    activeEnhancements[i] = enh
                end
                if not activeEnhancements[1] then
                    activeEnhancements = nil
                end
            end
        end

        if categoriesHash['ENGINEERSTATION'] and categoriesHash['UEF'] then
            -- We have to kill drones which are idling inside Kennel at the moment of transfer
            -- otherwise additional dummy drone will appear after transfer
            for _, drone in unit:GetCargo() do
                drone:Destroy()
            end
        end

        if unit.TransferUpgradeProgress and shareUpgrades then
            local progress = unit:GetWorkProgress()
            local upgradeBuildTime = unit.UpgradeBuildTime

            defaultBuildRate = unit:GetBuildRate()

            if progress > 0.05 then --5%. EcoManager & auto-paused mexes etc.
                upgradeBuildTimeComplete = upgradeBuildTime * progress
            end
        end

        unit.IsBeingTransferred = true

        -- If this unit is a factory building a unit (parent of the unit being built is our unit)
        -- then store data to rebuild the factory progress after transfer

        local unitExternalFactory = unit.ExternalFactory
        local factoryUnit = unitExternalFactory or unit
        local unitBeingBuilt = factoryUnit.UnitBeingBuilt
        if unitBeingBuilt
            and not unitBeingBuilt.Dead
            and not unitBeingBuilt.isFinishedUnit
            -- In external factories, the units are parented to the base unit instead of the exfac.
            -- Checking the parent also excludes upgrading factories (the upgrade's parent is the upgrade itself)
            and unitBeingBuilt:GetParent() == unit
        then
            local bpBeingBuilt = unitBeingBuilt.Blueprint

            FacRebuild_UnitId = unitBeingBuilt.UnitId
            FacRebuild_Progress = unitBeingBuilt:GetFractionComplete()
            FacRebuild_BuildTime = FacRebuild_Progress * bpBeingBuilt.Economy.BuildTime
            FacRebuild_Health = unitBeingBuilt:GetHealth()

            -- For external factories, destroy the unit being built since otherwise it will be transferred as a built unit because it is attached indirectly
            if unitExternalFactory then
                unitBeingBuilt:Destroy()
            end
        end

        -- changing owner
        local newUnit = ChangeUnitArmy(unit, toArmy, noRestrictions or false)
        if not newUnit then
            continue
        end

        newUnitCount = newUnitCount + 1
        newUnits[newUnitCount] = newUnit

        if IsAlly(owner, toArmy) then
            if not oldowner then
                oldowner = owner
            end

            local sharedUnitsTable = sharedUnits[oldowner]
            if not sharedUnitsTable then
                sharedUnitsTable = {}
                sharedUnits[oldowner] = sharedUnitsTable
            end
            table.insert(sharedUnitsTable, newUnit)
        end

        newUnit.oldowner = oldowner

        -- A F T E R

        -- for the disconnect ACU share option
        if LastTickDamaged then
            newUnit.LastTickDamaged = LastTickDamaged
        end

        newUnit:SetOrientation(orientation, true)

        if massKilled and massKilled > 0 then
            newUnit:CalculateVeterancyLevelAfterTransfer(massKilled, true)
        end

        if activeEnhancements then
            for _, enh in activeEnhancements do
                newUnit:CreateEnhancement(enh)
            end
        end

        local maxHealth = newUnit:GetMaxHealth()
        if unitHealth > maxHealth then
            unitHealth = maxHealth
        end
        newUnit:SetHealth(newUnit, unitHealth)

        if hasFuel then
            newUnit:SetFuelRatio(fuelRatio)
        end

        if tarmacs then
            newUnit.TarmacBag = tarmacs
        end

        if numNukes and numNukes > 0 then
            newUnit:GiveNukeSiloAmmo(numNukes - newUnit:GetNukeSiloAmmoCount())
        end

        if numTacMsl and numTacMsl > 0 then
            newUnit:GiveTacticalSiloAmmo(numTacMsl - newUnit:GetTacticalSiloAmmoCount())
        end

        if newUnit.Blueprint.CategoriesHash["SILO"] then
            newUnit:GiveNukeSiloBlocks(workprogress)
        end

        local newShield = newUnit.MyShield

        if newShield then
            newShield:SetHealth(newUnit, shieldHealth)
            if shieldIsOn then
                newUnit:EnableShield()
            else
                newUnit:DisableShield()
            end
        end

        if EntityCategoryContains(categoriesENGINEERSTATION, newUnit) then
            if not upgradeBuildTimeComplete or not shareUpgrades then
                if categoriesHash['UEF'] then
                    -- use special thread for UEF Kennels
                    -- Give them 1 tick to spawn their drones and then pause both station and drone
                    pauseKennelCount = pauseKennelCount + 1
                    pauseKennels[pauseKennelCount] = newUnit
                else -- pause cybran hives immediately
                    newUnit:SetPaused(true)
                end
            elseif categoriesHash['UEF'] then
                newUnit.UpgradesTo = upgradesTo
                newUnit.DefaultBuildRate = defaultBuildRate
                newUnit.TargetUpgradeBuildTime = upgradeBuildTimeComplete

                upgradeKennelCount = upgradeKennelCount + 1
                upgradeKennels[upgradeKennelCount] = newUnit

                exclude = true
            end
        end

        if upgradeBuildTimeComplete and not exclude then
            newUnit.UpgradesTo = upgradesTo
            newUnit.DefaultBuildRate = defaultBuildRate
            newUnit.TargetUpgradeBuildTime = upgradeBuildTimeComplete

            upgradeUnitCount = upgradeUnitCount + 1
            upgradeUnits[upgradeUnitCount] = newUnit
        end

        if FacRebuild_UnitId then
            local newFactoryUnit = newUnit.ExternalFactory or newUnit
            local data = factoryRebuildDataTable[FacRebuild_UnitId]
            if not data then
                factoryRebuildDataTable[FacRebuild_UnitId] = { newFactoryUnit }
            else
                table.insert(data, newFactoryUnit)
            end
            newFactoryUnit.FacRebuild_Progress = FacRebuild_Progress
            newFactoryUnit.FacRebuild_BuildTime = FacRebuild_BuildTime
            newFactoryUnit.FacRebuild_Health = FacRebuild_Health
        end

        unit.IsBeingTransferred = nil

        if unit.OnGiven then
            unit:OnGiven(newUnit)
        end
    end

    if not captured then
        if upgradeUnits[1] then
            ForkThread(UpgradeUnits, upgradeUnits)
        end
        if pauseKennels[1] then
            ForkThread(PauseTransferredKennels, pauseKennels)
        end
        if upgradeKennels[1] then
            ForkThread(UpgradeTransferredKennels, upgradeKennels)
        end
        if next(factoryRebuildDataTable) then
            ForkThread(FactoryRebuildUnits, factoryRebuildDataTable)
        end
    end

    return newUnits
end

--- Pauses all drones in `kennels`
---@param kennels TPodTowerUnit[]
function PauseTransferredKennels(kennels)
    -- wait for drones to spawn
    WaitTicks(1)

    for _, unit in kennels do
        unit:SetPaused(true)
        local podData = unit.PodData
        if podData then
            for _, pod in podData do
                local podHandle = pod.PodHandle
                if podHandle then
                    podHandle:SetPaused(true)
                end
            end
        end
    end
end

--- Upgrades `kennels` to their `TargetUpgradeBuildTime` value, allowing for drones to spawn and get paused
---@param kennels TPodTowerUnit[]
function UpgradeTransferredKennels(kennels)
    WaitTicks(1) -- spawn drones

    for _, unit in kennels do
        if not unit:BeenDestroyed() then
            for _, pod in unit.PodData or {} do -- pause Kennels drones
                local podHandle = pod.PodHandle
                if podHandle then
                    podHandle:SetPaused(true)
                end
            end

            IssueUpgrade({ unit }, unit.UpgradesTo)
        end
    end

    WaitTicks(3)

    for _, unit in kennels do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.TargetUpgradeBuildTime * 10)
            unit:SetConsumptionPerSecondMass(0)
            unit:SetConsumptionPerSecondEnergy(0)
        end
    end

    WaitTicks(1)

    for _, unit in kennels do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.DefaultBuildRate)
            unit:SetPaused(true) -- `SetPaused` updates ConsumptionPerSecond values
            unit.TargetUpgradeBuildTime = nil
            unit.DefaultBuildRate = nil
        end
    end
end

--- Takes the units and tries to rebuild them for each army (in order).
---@param units Unit[]
---@param armies Army[]
function TransferUnfinishedUnitsAfterDeath(units, armies)
    local unbuiltUnits = {}
    local unbuiltUnitCount = 0
    for _, unit in EntityCategoryFilterDown(transferUnbuiltCategory, units) do
        if unit:IsBeingBuilt()
            -- Check if a unit is an upgrade to prevent duplicating it along with `UpgradeUnits`
            and not unit.IsUpgrade
            -- Make sure units are parents of themselves to avoid units being built in factories,
            -- since they are awkward to finish building and they can even block factories.
            -- `FactoryRebuildUnits` handles units inside factories correctly.
            and unit == unit:GetParent()
        then
            unbuiltUnitCount = unbuiltUnitCount + 1
            unbuiltUnits[unbuiltUnitCount] = unit
        end
    end
    if not (unbuiltUnits[1] and armies[1]) then
        return
    end
    RebuildUnits(unbuiltUnits, armies)
end

--- Upgrades `units` to `UpgradesTo` at their `TargetUpgradeBuildTime` values (defaulting to
--- `UpgradeBuildTime`, i.e. completion) and resets the build rate to `DefaultBuildRate` (defaulting
--- to the build rate at the start)
---@param units Unit[]
function UpgradeUnits(units)
    for _, unit in units do
        IssueUpgrade({ unit }, unit.UpgradesTo)
        if not unit.DefaultBuildRate then
            unit.DefaultBuildRate = unit:GetBuildRate()
        end
        unit:SetBuildRate(0)
    end

    WaitTicks(3)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            local targetUpgradeBuildTime = unit.TargetUpgradeBuildTime or unit.UpgradeBuildTime
            unit:SetBuildRate(targetUpgradeBuildTime * 10)
            unit:SetConsumptionPerSecondMass(0)
            unit:SetConsumptionPerSecondEnergy(0)
        end
    end

    WaitTicks(1)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.DefaultBuildRate)
            unit:SetPaused(true) -- `SetPaused` updates ConsumptionPerSecond values
            unit.TargetUpgradeBuildTime = nil
            unit.DefaultBuildRate = nil
        end
    end
end

--- Rebuilds `units`, giving a try for each army (in order) in case they can't for unit cap
--- reasons. If a unit cannot be rebuilt at all, a wreckage is placed instead. Each unit can
--- be tagged with `TargetFractionComplete` to be rebuilt with a different build progress.
---@see AddConstructionProgress # doesn't destroy and rebuild the unit
---@param units Unit[]
---@param armies Army[]
function RebuildUnits(units, armies)
    local trackers, blockingEntities = StartRebuildUnits(units)
    for _, army in ipairs(armies) do
        TryRebuildUnits(trackers, army)
    end
    FinalizeRebuiltUnits(trackers, blockingEntities)
end

---@class RebuildTracker
---@field CanCreateWreck boolean
---@field Success boolean
---@field TargetBuildTime number
---@field UnitBlueprint UnitBlueprint
---@field UnitBlueprintID string
---@field UnitHealth number
---@field UnitID string
---@field UnitOrientation Quaternion
---@field UnitPos Vector
---@field UnitProgress number

---@alias RevertibleCollisionShapeEntity Prop | Unit

--- Initializes the rebuild process for a `unit`. It is destroyed in this method and replaced
--- with a tracker. Any possible entities that could block construction have their collision
--- shapes disabled and are placed into `blockingEntities` to be reverted later. A unit can be
--- tagged with `TargetFractionComplete` to be rebuilt with a different build progress.
---@param unit Unit
---@param blockingEntities RevertibleCollisionShapeEntity[]
---@return RebuildTracker tracker
function CreateRebuildTracker(unit, blockingEntities)
    local bp = unit.Blueprint
    local blueprintID = bp.BlueprintId
    local buildTime = bp.Economy.BuildTime
    local health = unit:GetHealth()
    local pos = unit:GetPosition()
    local progress = unit.TargetFractionComplete or unit:GetFractionComplete()

    local tracker = {
        -- save all important data because the unit will be destroyed
        UnitHealth = health,
        UnitPos = pos,
        UnitID = unit.EntityId,
        UnitOrientation = unit:GetOrientation(),
        UnitBlueprint = bp,
        UnitBlueprintID = blueprintID,
        UnitProgress = progress, -- save current progress for some later checks
        CanCreateWreck = progress > 0.5, -- if rebuilding fails, we have to create a wreck manually
        TargetBuildTime = progress * buildTime,
        Success = false,
    }

    -- wrecks can prevent drone from starting construction
    local wrecks = GetReclaimablesInRect(unit:GetSkirtRect()) --[[@as ReclaimObject[] | Wreckage[] ]]
    if wrecks then
        for _, reclaim in wrecks do
            if reclaim.IsWreckage then
                -- collision shape to none to prevent it from blocking, keep track to revert later
                reclaim:CacheAndRemoveCollisionExtents()
                table.insert(blockingEntities, reclaim)
            end
        end
    end

    -- units can prevent drone from starting construction
    local nearbyUnits = GetUnitsInRect(unit:GetSkirtRect())
    if nearbyUnits then
        for _, nearbyUnit in nearbyUnits do
            nearbyUnit:SetCollisionShape('None')
            table.insert(blockingEntities, nearbyUnit)
        end
    end

    unit:Destroy()

    return tracker
end

--- Attempts to rebuild `units` for an `army`, returning the resulting rebuild trackers
--- and any entities needing their collision shape reverted
---@param units Unit[]
---@param trackers? RebuildTracker[]
---@param blockingEntities? RevertibleCollisionShapeEntity[]
---@return RebuildTracker[] blockingEntities
---@return RevertibleCollisionShapeEntity[] blockingEntities
function StartRebuildUnits(units, trackers, blockingEntities)
    trackers = trackers or {}
    blockingEntities = blockingEntities or {}
    for i, unit in ipairs(units) do
        trackers[i] = CreateRebuildTracker(unit, blockingEntities)
    end
    return trackers, blockingEntities
end

--- Attempts to rebuild units for an `army`, using `trackers`
---@param trackers RebuildTracker[]
---@param army Army
function TryRebuildUnits(trackers, army)
    local rebuilders = {}
    for k, tracker in trackers do
        if tracker.Success then
            continue
        end
        -- create invisible drone which belongs to allied army. BuildRange = 10000
        local rebuilder = CreateUnitHPR('ZXA0001', army, 5, 20, 5, 0, 0, 0)
        rebuilder.TargetBuildTime = tracker.TargetBuildTime
        rebuilders[k] = rebuilder

        IssueBuildMobile({ rebuilder }, tracker.UnitPos, tracker.UnitBlueprintID, {})
    end

    WaitTicks(3) -- wait some ticks (3 is minimum), IssueBuildMobile() is not instant

    for k, rebuilder in rebuilders do
        rebuilder:SetBuildRate(rebuilder.TargetBuildTime * 10) -- set crazy build rate and consumption = 0
        rebuilder:SetConsumptionPerSecondMass(0)
        rebuilder:SetConsumptionPerSecondEnergy(0)
    end

    WaitTicks(1)

    for k, rebuilder in rebuilders do
        local tracker = trackers[k]
        local newUnit = rebuilder:GetFocusUnit()
        local progressDif = rebuilder:GetWorkProgress() - tracker.UnitProgress
        if newUnit and math.abs(progressDif) < 0.001 then
            newUnit:SetHealth(newUnit, tracker.UnitHealth)
            tracker.Success = true
        end
        rebuilder:Destroy()
    end
end

--- Finalizes the unit rebuilding process. Any failed rebuilding attempts are replaced with
--- wreckage and all blocking entities have their collision shapes reverted.
---@param trackers RebuildTracker[]
---@param blockingEntities RevertibleCollisionShapeEntity[]
function FinalizeRebuiltUnits(trackers, blockingEntities)
    for _, tracker in trackers do
        if not tracker.Success and tracker.CanCreateWreck then
            local bp = tracker.UnitBlueprint
            local pos = tracker.UnitPos
            local orientation = tracker.UnitOrientation
            -- Refund exactly how much mass was put into the unit
            local completionFactor = tracker.TargetBuildTime / bp.Economy.BuildTime
            local mass = bp.Economy.BuildCostMass * completionFactor
            -- Don't refund energy because it would be counterintuitive for wreckage
            local energy = 0
            -- global 2x time multiplier for unit wrecks, see `Unit:CreateWreckageProp`
            local time = (bp.Wreckage.ReclaimTimeMultiplier or 1) * 2
            CreateWreckage(bp, pos, orientation, mass, energy, time)
        end
    end

    -- revert collision shapes of any blocking units or wreckage
    for _, entity in blockingEntities do
        if not entity:BeenDestroyed() then
            if entity.IsProp then
                entity:ApplyCachedCollisionExtents()
            else
                entity:RevertCollisionShape()
            end
        end
    end
end

---@param data {To: integer}
---@param units Unit[]
function GiveUnitsToPlayer(data, units)
    local manualShare = ScenarioInfo.Options.ManualUnitShare
    if manualShare == 'none' then
        return
    end
    local toArmy = data.To

    if units then
        local owner = units[1].Army
        if OkayToMessWithArmy(owner) and IsAlly(owner, toArmy) then
            if manualShare == 'no_builders' then
                local unitsBefore = table.getsize(units)
                units = EntityCategoryFilterDown(buildersCategory, units)
                local unitsAfter = table.getsize(units)

                if unitsAfter ~= unitsBefore then
                    -- Maybe spawn an UI dialog instead?
                    print((unitsBefore - unitsAfter) .. " engineers/factories could not be transferred due to manual share rules")
                end
            end

            TransferUnitsOwnership(units, toArmy)
        end
    end
end

--#endregion

------------------------------------------------------------------------------------------------------------------------
--#region Army Death Unit Transfer

--- Functions related to dealing with unit ownership when an army dies based on share conditions.

local CalculateBrainScore = import("/lua/sim/score.lua").CalculateBrainScore
local FakeTeleportUnits = import("/lua/scenarioframework.lua").FakeTeleportUnits

---@param owner number
-- categoriesToKill is an optional input (it defaults to all categories)
function KillSharedUnits(owner, categoriesToKill)
    local sharedUnitOwner = sharedUnits[owner]
    if sharedUnitOwner and not table.empty(sharedUnitOwner) then
        local sharedUnitOwnerSize = table.getn(sharedUnitOwner)
        for i = sharedUnitOwnerSize, 1, -1 do
            local unit = sharedUnitOwner[i]
            if not unit.Dead and unit.oldowner == owner then
                if categoriesToKill then
                    if EntityCategoryContains(categoriesToKill, unit) then
                        table.remove(sharedUnits[owner], i)
                        unit:Kill()
                    end
                else
                    unit:Kill()
                end
            end
        end
        if not categoriesToKill then
            sharedUnits[owner] = {}
        end
    end
end

--- Given that `deadArmy` just died, redistributes their unit cap based on the scenario options
---@param deadArmy integer
function UpdateUnitCap(deadArmy)
    -- If we are asked to share out unit cap for the defeated army, do the following...
    local options = ScenarioInfo.Options
    local mode = options.ShareUnitCap
    if not mode or mode == 'none' then
        return
    end
    local aliveCount = 0
    ---@type table<number, AIBrain>
    local alive = {}
    local caps = {}

    for index, brain in ArmyBrains do
        if (mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) and not ArmyIsCivilian(index) then
            if not brain:IsDefeated() then
                aliveCount = aliveCount + 1
                alive[aliveCount] = brain
                local cap = GetArmyUnitCap(index)
                caps[aliveCount] = cap
            end
        end
    end

    if aliveCount > 0 then
        local capChng = GetArmyUnitCap(deadArmy) / aliveCount
        for i, brain in alive do
            SetArmyUnitCap(brain.Army, caps[i] + capChng)
        end
    end
end

--- Transfer a brain's units to other brains.
---@param self AIBrain
---@param brains AIBrain[]
---@param transferUnfinishedUnits boolean
---@param categoriesToTransfer? EntityCategory      # Defaults to ALLUNITS - WALL - COMMAND
---@param reason? string # Defaults to "FullShare"
---@return Unit[]?
function TransferUnitsToBrain(self, brains, transferUnfinishedUnits, categoriesToTransfer, reason)
    if not table.empty(brains) then
        local units
        if transferUnfinishedUnits then
            local indexes = {}
            for _, brain in brains do
                table.insert(indexes, brain.Army)
            end
            units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
            TransferUnfinishedUnitsAfterDeath(units, indexes)
        end

        local totalNewUnits = {}

        for k, brain in brains do
            if categoriesToTransfer then
                units = self:GetListOfUnits(categoriesToTransfer, false)
            else
                units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
            end
            if units and not table.empty(units) then
                local newUnits = TransferUnitsOwnership(units, brain.Army, false, true)

                -- we might not transfer any newUnits
                if not table.empty(newUnits) then
                    table.destructiveCat(totalNewUnits, newUnits)

                    Sync.ArmyTransfer = { {
                        from = self.Army,
                        to = brain.Army,
                        reason = reason or "FullShare"
                    } }
                end

                -- Prevent giving the same units to multiple armies
                WaitSeconds(1)
            end
        end

        return totalNewUnits
    end
end

--- Returns a table of the allies and enemies of a brain, and civilians.
---@param armyIndex integer
---@return { Civilians: AIBrain[], Enemies: AIBrain[], Allies: AIBrain[] } BrainCategories
function GetAllegianceCategories(armyIndex)
    local BrainCategories = { Enemies = {}, Civilians = {}, Allies = {} }

    for index, brain in ArmyBrains do
        if not brain:IsDefeated() and armyIndex ~= index then
            if ArmyIsCivilian(index) then
                table.insert(BrainCategories.Civilians, brain)
            elseif IsEnemy(armyIndex, brain:GetArmyIndex()) then
                table.insert(BrainCategories.Enemies, brain)
            else
                table.insert(BrainCategories.Allies, brain)
            end
        end
    end

    return BrainCategories
end

--- Transfer a brain's units to other brains, sorted by positive rating and then score.
---@param self AIBrain
---@param brains AIBrain[]
---@param transferUnfinishedUnits boolean
---@param categoriesToTransfer? EntityCategory      # Defaults to ALLUNITS - WALL - COMMAND
---@param reason? string Usually 'FullShare'
---@return Unit[]?
function TransferUnitsToHighestBrain(self, brains, transferUnfinishedUnits, categoriesToTransfer, reason)
    if not table.empty(brains) then
        local ratings = ScenarioInfo.Options.Ratings
        ---@type table<AIBrain, number>
        local brainRatings = {}
        for _, brain in brains do
            -- AI can have a rating set in the lobby
            if brain.BrainType == "Human" and ratings[brain.Nickname] then
                brainRatings[brain] = ratings[brain.Nickname]
            else
                -- if there is no rating, create a fake negative rating based on score
                -- leave -1000 rating for negative rated players
                brainRatings[brain] = -1000 - 1 / CalculateBrainScore(brain)
            end
        end
        -- sort brains by rating
        table.sort(brains, function(a, b) return brainRatings[a] > brainRatings[b] end)
        return TransferUnitsToBrain(self, brains, transferUnfinishedUnits, categoriesToTransfer, reason)
    end
end

--local helper functions for KillArmy

---@param self AIBrain
local function KillWalls(self)
    local tokill = self:GetListOfUnits(categories.WALL, false)
    if tokill and not table.empty(tokill) then
        for index, unit in tokill do
            unit:Kill()
        end
    end
end

--- Remove the borrowed status from units we lent to a set of `brains`.
---@param brains AIBrain[] Usually our allies
---@param selfIndex number
local function TransferOwnershipOfBorrowedUnits(brains, selfIndex)
    for index, brain in brains do
        local units = brain:GetListOfUnits(categories.ALLUNITS, false)
        if units and not table.empty(units) then
            for _, unit in units do
                if unit.oldowner == selfIndex then
                    unit.oldowner = nil
                end
            end
        end
    end
end

--- Return units transferred to me to their original owner (if alive)
---@param self AIBrain
local function ReturnBorrowedUnits(self)
    local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
    local borrowed = {}
    for index, unit in units do
        local oldowner = unit.oldowner
        if oldowner and oldowner ~= self:GetArmyIndex() and not GetArmyBrain(oldowner):IsDefeated() then
            if not borrowed[oldowner] then
                borrowed[oldowner] = {}
            end
            table.insert(borrowed[oldowner], unit)
        end
    end

    for owner, units in borrowed do
        TransferUnitsOwnership(units, owner, false, true)
    end

    WaitSeconds(1)
end

--- Take back units I gave away. Mainly needed to stop mods that auto-give after death from bypassing share conditions.
---@param selfIndex integer
---@param brains AIBrain[]
local function GetBackUnits(selfIndex, brains)
    local given = {}
    for index, brain in brains do
        local units = brain:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
        if units and not table.empty(units) then
            for _, unit in units do
                if unit.oldowner == selfIndex then
                    table.insert(given, unit)
                    unit.oldowner = nil
                end
            end
        end
    end

    TransferUnitsOwnership(given, selfIndex, false, true)
end

--- Transfer units to the player who killed me
---@param self AIBrain
local function TransferUnitsToKiller(self)
    local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)

    if units and not table.empty(units) then
        local victoryOption = ScenarioInfo.Options.Victory
        local killerIndex

        if victoryOption == 'demoralization' then
            killerIndex = self.CommanderKilledBy
        elseif victoryOption == 'decapitation' then
            local selfIndex = self.Army
            -- transfer to the killer who defeated the last acu on our team
            local lastCommanderKilledTick = self.CommanderKilledTick
            local lastKilledAllyIndex = selfIndex
            ---@param brain AIBrain
            for _, brain in ArmyBrains do
                local brainIndex = brain.Army
                if brainIndex ~= selfIndex and IsAlly(brainIndex, selfIndex) then
                    local brainCommanderKilledTick = brain.CommanderKilledTick
                    if lastCommanderKilledTick < brainCommanderKilledTick then
                        lastKilledAllyIndex = brainIndex
                        lastCommanderKilledTick = brainCommanderKilledTick
                    end
                end
            end
            KillerIndex = ArmyBrains[lastKilledAllyIndex].CommanderKilledBy or selfIndex
            TransferUnitsOwnership(units, KillerIndex)
        else
            killerIndex = self.LastUnitKilledBy
        end

        if killerIndex then
            TransferUnitsToBrain(self, { ArmyBrains[killerIndex] }, true, nil, "TransferToKiller")
        end
        -- if not transferred, units will simply be killed
    end
    -- give some time to transfer before units are killed
    WaitSeconds(1)
end

--- Kills my army according to the given share condition.
---@param self AIBrain
---@param shareOption 'FullShare' | 'ShareUntilDeath' | 'PartialShare' | 'TransferToKiller' | 'Defectors' | 'CivilianDeserter'
function KillArmy(self, shareOption)

    -- Kill all walls while the ACU is blowing up
    if shareOption == 'ShareUntilDeath' then
        ForkThread(KillWalls, self)
    end

    WaitSeconds(10) -- Wait for commander explosion, then transfer units.

    local selfIndex = self:GetArmyIndex()

    local BrainCategories = GetAllegianceCategories(selfIndex)

    -- This part determines the share condition
    if shareOption == 'ShareUntilDeath' then
        KillSharedUnits(selfIndex)
        ReturnBorrowedUnits(self)
    elseif shareOption == 'FullShare' then
        TransferUnitsToHighestBrain(self, BrainCategories.Allies, true, nil, "FullShare")
        TransferOwnershipOfBorrowedUnits(BrainCategories.Allies, selfIndex)
    elseif shareOption == 'PartialShare' then
        KillSharedUnits(selfIndex, categories.ALLUNITS - categories.STRUCTURE - categories.ENGINEER)
        ReturnBorrowedUnits(self)
        TransferUnitsToHighestBrain(self, BrainCategories.Allies, true, categories.STRUCTURE + categories.ENGINEER - categories.COMMAND, "PartialShare")
        TransferOwnershipOfBorrowedUnits(BrainCategories.Allies, selfIndex)
    else
        GetBackUnits(selfIndex, BrainCategories.Allies)
        if shareOption == 'CivilianDeserter' then
            TransferUnitsToBrain(self, BrainCategories.Civilians, true)
        elseif shareOption == 'TransferToKiller' then
            TransferUnitsToKiller(self)
        elseif shareOption == 'Defectors' then
            TransferUnitsToHighestBrain(self, BrainCategories.Enemies, true, nil, "Defectors")
        else -- Something went wrong in settings. Act like share until death to avoid abuse
            WARN('Invalid share condition was used for this game: `' .. (shareOption or 'nil') .. '` Defaulting to killing all units')
            KillSharedUnits(selfIndex)
            ReturnBorrowedUnits(self)
        end
    end

    -- Kill all units left over
    local tokill = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
    if tokill and not table.empty(tokill) then
        for index, unit in tokill do
            unit:Kill()
        end
    end
end

local StartCountdown = StartCountdown -- as defined in SymSync.lua

-- The time in ticks after taking damage that commanders are considered safe and not abusing disconnect rules
---@see aibrain.lua:AbandonedByPlayer
CommanderSafeTime = 1200

--- Shares all units including ACUs. When the shared ACUs die or recall after `shareTime`, kills my army according to the given share condition.
---@param self AIBrain
---@param shareOption 'FullShare' | 'ShareUntilDeath' | 'PartialShare' | 'TransferToKiller' | 'Defectors' | 'CivilianDeserter'
---@param shareTime number Game time in ticks
function KillArmyOnDelayedRecall(self, shareOption, shareTime)
    -- Share units including ACUs and walls and keep track of ACUs
    local brainCategories = GetAllegianceCategories(self:GetArmyIndex())
    local newUnits = TransferUnitsToHighestBrain(self, brainCategories.Allies, true, categories.ALLUNITS, "DisconnectShareTemporary")
    ---@type (ACUUnit|Unit)[]
    local sharedCommanders = EntityCategoryFilterDown(categories.COMMAND, newUnits or {})

    -- non-assassination games could have an army abandon without having any commanders
    if not table.empty(sharedCommanders) then
        -- create a countdown to show when the ACU recalls (similar to the one used for timed self-destruct)
        for i, com in sharedCommanders do
            -- don't recall shared ACUs
            if com.RecallingAfterDefeat then
                sharedCommanders[i] = nil
                continue
            end
            -- The shared ACUs don't count as keeping the army in the game since they will eventually be removed from the game.
            -- See the victory conditions, and especially `AbstractVictoryCondition` class with the method `UnitIsEligible`
            com.RecallingAfterDefeat = true
            StartCountdown(com.EntityId, math.floor((shareTime - GetGameTick()) / 10))
        end

        local oneComAlive = true
        while GetGameTick() < shareTime and oneComAlive do
            oneComAlive = false
            for _, com in sharedCommanders do
                if not com.Dead then
                    oneComAlive = true
                    break
                end
            end
            WaitTicks(1)
        end

        -- if all the commanders die early, assume disconnect abuse and apply standard share condition. Only makes sense in Assassination.
        local scenarioOptions = ScenarioInfo.Options
        if not oneComAlive and scenarioOptions.Victory == "demoralization" then
            KillArmy(self, scenarioOptions.Share)
            return
        end

        -- filter out commanders that are not currently safe and should explode
        local gameTick = GetGameTick()
        for i, com in sharedCommanders do
            if com.LastTickDamaged and com.LastTickDamaged > gameTick - CommanderSafeTime then
                sharedCommanders[i] = nil
                -- explode unsafe ACUs because KillArmy might not
                com:Kill()
            end
        end

        -- KillArmy waits 10 seconds before acting, while FakeTeleport waits 3 seconds, so the ACU shouldn't explode.
        ForkThread(FakeTeleportUnits, sharedCommanders, true)
    end
    KillArmy(self, shareOption)
end

--- Shares all units including ACUs. When the shared ACUs die, kills my army according to the given share condition.
---@param self AIBrain
---@param shareOption 'FullShare' | 'ShareUntilDeath' | 'PartialShare' | 'TransferToKiller' | 'Defectors' | 'CivilianDeserter'
function KillArmyOnACUDeath(self, shareOption)
    -- Share units including ACUs and walls and keep track of ACUs
    local brainCategories = GetAllegianceCategories(self:GetArmyIndex())
    local newUnits = TransferUnitsToHighestBrain(self, brainCategories.Allies, true, categories.ALLUNITS, "DisconnectSharePermanent")
    local sharedCommanders = EntityCategoryFilterDown(categories.COMMAND, newUnits or {})

    if not table.empty(sharedCommanders) then
        local shareTick = GetGameTick()

        local oneComAlive = true
        while oneComAlive do
            oneComAlive = false
            for _, com in sharedCommanders do
                if not com.Dead then
                    oneComAlive = true
                    break
                end
            end
            WaitTicks(1)
        end

        -- if all the commanders die early, assume disconnect abuse and apply standard share condition. Only makes sense in Assassination.
        local scenarioOptions = ScenarioInfo.Options
        if not oneComAlive and shareTick + CommanderSafeTime <= GetGameTick() and scenarioOptions.Victory == "demoralization" then
            KillArmy(self, scenarioOptions.Share)
            return
        end
    end

    KillArmy(self, shareOption)
end

--#endregion

local SorianUtils = import("/lua/ai/sorianutilities.lua")

--- Disables the AI for non-player armies.
---@param self BaseAIBrain
function DisableAI(self)
    local army = self.Army
    -- print AI "ilost" text to chat
    SorianUtils.AISendChat('enemies', ArmyBrains[self:GetArmyIndex()].Nickname, 'ilost')
    -- remove PlatoonHandle from all AI units before we kill / transfer the army
    local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
    if units and not table.empty(units) then
        for _, unit in units do
            if not unit.Dead then
                if unit.PlatoonHandle and self:PlatoonExists(unit.PlatoonHandle) then
                    unit.PlatoonHandle:Stop()
                    unit.PlatoonHandle:PlatoonDisbandNoAssign()
                end
                IssueStop({ unit })
                IssueToUnitClearCommands(unit)
            end
        end
    end
    -- Stop the AI from executing AI plans
    self.RepeatExecution = false
    -- removing AI BrainConditionsMonitor
    if self.ConditionsMonitor then
        self.ConditionsMonitor:Destroy()
    end
    -- removing AI BuilderManagers
    if self.BuilderManagers then
        for k, manager in self.BuilderManagers do
            if manager.EngineerManager then
                manager.EngineerManager:SetEnabled(false)
            end

            if manager.FactoryManager then
                manager.FactoryManager:SetEnabled(false)
            end

            if manager.PlatoonFormManager then
                manager.PlatoonFormManager:SetEnabled(false)
            end

            if manager.EngineerManager then
                manager.EngineerManager:Destroy()
            end

            if manager.FactoryManager then
                manager.FactoryManager:Destroy()
            end

            if manager.PlatoonFormManager then
                manager.PlatoonFormManager:Destroy()
            end
            if manager.StrategyManager then
                manager.StrategyManager:SetEnabled(false)
                manager.StrategyManager:Destroy()
            end
            self.BuilderManagers[k].EngineerManager = nil
            self.BuilderManagers[k].FactoryManager = nil
            self.BuilderManagers[k].PlatoonFormManager = nil
            self.BuilderManagers[k].BaseSettings = nil
            self.BuilderManagers[k].BuilderHandles = nil
            self.BuilderManagers[k].Position = nil
        end
    end
    -- delete the AI pathcache
    self.PathCache = nil
end

------------------------------------------------------------------------------------------------------------------------
--#region Non-Unit Transfer Diplomacy

---@param data {Army: integer, Value: boolean}
function SetResourceSharing(data)
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = GetArmyBrain(army)
    brain:SetResourceSharing(data.Value)
end

---@param data {Army: integer, Value: boolean}
function RequestAlliedVictory(data)
    -- You cannot change this in a team game
    if ScenarioInfo.TeamGame then
        return
    end
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = GetArmyBrain(army)
    brain.RequestingAlliedVictory = data.Value
end

---@param data {Army: Army, Value: boolean}
function SetOfferDraw(data)
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = GetArmyBrain(army)
    brain.OfferingDraw = data.Value
end

---@param data {Sender: integer, Msg: string}
function SendChatToReplay(data)
    if data.Sender and data.Msg then
        if not Sync.UnitData.Chat then
            Sync.UnitData.Chat = {}
        end
        table.insert(Sync.UnitData.Chat, { sender = data.Sender, msg = data.Msg })
    end
end

---@param data {From: Army, To: Army, Mass: number, Energy: number}
function GiveResourcesToPlayer(data)
    SendChatToReplay(data)
    -- Ignore observers and players trying to send resources to themselves or to enemies
    if data.From ~= -1 and data.From ~= data.To and IsAlly(data.From, data.To) then
        if not OkayToMessWithArmy(data.From) then
            return
        end
        local fromBrain = GetArmyBrain(data.From)
        local toBrain = GetArmyBrain(data.To)
        -- Abort if any of the armies is defeated or if trying to send a negative value
        if fromBrain:IsDefeated() or toBrain:IsDefeated() or data.Mass < 0 or data.Energy < 0 then
            return
        end
        local massTaken = fromBrain:TakeResource('MASS', data.Mass * fromBrain:GetEconomyStored('MASS'))
        local energyTaken = fromBrain:TakeResource('ENERGY', data.Energy * fromBrain:GetEconomyStored('ENERGY'))

        toBrain:GiveResource('MASS', massTaken)
        toBrain:GiveResource('ENERGY', energyTaken)
    end
end

---@param data {From: Army, To: Army}
function BreakAlliance(data)
    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(data.From) then
        SetAlliance(data.From, data.To, "Enemy")

        if Sync.BrokenAlliances == nil then
            Sync.BrokenAlliances = {}
        end
        table.insert(Sync.BrokenAlliances, { From = data.From, To = data.To })
    end
    import("/lua/simping.lua").OnAllianceChange()
    import("/lua/sim/recall.lua").OnAllianceChange(data)
end

---@param resultData {From: Army, To: Army, ResultValue: DiplomacyActionType}
function OnAllianceResult(resultData)
    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(resultData.From) then
        if resultData.ResultValue == "accept" then
            SetAlliance(resultData.From, resultData.To, "Ally")
            if Sync.FormedAlliances == nil then
                Sync.FormedAlliances = {}
            end
            table.insert(Sync.FormedAlliances, { From = resultData.From, To = resultData.To })
        end
    end
    import("/lua/simping.lua").OnAllianceChange()
end

import("/lua/simplayerquery.lua").AddResultListener("OfferAlliance", OnAllianceResult)

local vectorCross = import('/lua/utilities.lua').Cross
local upVector = Vector(0, 1, 0)

--#endregion

--- Draw XYZ axes of an entity's bone for one tick
---@param entity moho.entity_methods
---@param bone Bone
---@param length number? # length of axes, defaults to 0.2
function DrawBone(entity, bone, length)
    if not length then length = 0.2 end

    local pos = entity:GetPosition(bone)
    local dirX, dirY, dirZ = entity:GetBoneDirection(bone)

    local forward = Vector(dirX, dirY, dirZ)
    local left = vectorCross(upVector, forward)
    local up = vectorCross(forward, left)

    -- X axis
    DrawLine(pos, pos + left * length, 'FF0000')
    -- Y axis
    DrawLine(pos, pos + up * length, '00ff00')
    -- Z axis
    DrawLine(pos, pos + forward * length, '0000ff')
end
