-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

-- upvalues for performance
local ArmyBrains = ArmyBrains
local GetCurrentCommandSource = GetCurrentCommandSource

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

--- Clear data for a factory so transferring it doesn't try to rebuild units again
---@param factory FactoryUnit | FactoryRebuildData
local function clearFactoryRebuildData(factory)
    factory.FacRebuild_UnitId = nil
    factory.FacRebuild_Progress = nil
    factory.FacRebuild_BuildTime = nil
    factory.FacRebuild_Health = nil
    factory.FacRebuild_OldBuildRate = nil
end

---@param factoryRebuildDataTable FactoryRebuildDataTable
function FactoryRebuildUnits(factoryRebuildDataTable)
    for buildUnitId, factories in factoryRebuildDataTable do
        -- Remove support factories that can't build their unit due to lacking an HQ
        local noFactories = false
        for i, factory in factories do
            if not factory:CanBuild(buildUnitId) then
                clearFactoryRebuildData(factory)
                factories[i] = nil
                if table.empty(factories) then
                    factoryRebuildDataTable[buildUnitId] = nil
                    noFactories = true
                end
                continue
            end
        end
        if noFactories then continue end

        IssueClearCommands(factories)
        IssueBuildFactory(factories, buildUnitId, 1)
    end
    -- wait for build order to start and then rebuild the units for free
    WaitTicks(1)
    for k, factories in factoryRebuildDataTable do
        for i, factory in factories do
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
    for k, factories in factoryRebuildDataTable do
        for i, factory in factories do
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
            -- TODO: Add a SetPaused hook into all the exfac class units (the class hierarchy is ambiguous) so this isn't necessary.
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
                    , factory.EntityId
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

            clearFactoryRebuildData(factory)
        end
    end
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

-- used to make more expensive units transfer first, in case there's a unit cap issue
local function TransferUnitsOwnershipComparator(a, b)
    a = a.Blueprint or a:GetBlueprint()
    b = b.Blueprint or b:GetBlueprint()
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
    local toBrain = ArmyBrains[toArmy]
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
        local FacRebuild_UnitId = unit.FacRebuild_UnitId
        local FacRebuild_Progress = unit.FacRebuild_Progress
        local FacRebuild_BuildTime = unit.FacRebuild_BuildTime
        local FacRebuild_Health = unit.FacRebuild_Health

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
            local newFactoryUnit = newUnit--[[@as Unit | ExternalFactoryComponent]].ExternalFactory or newUnit
            local data = factoryRebuildDataTable[FacRebuild_UnitId]
            if not data then
                factoryRebuildDataTable[FacRebuild_UnitId] = { newFactoryUnit }
            else
                table.insert(data, newFactoryUnit)
            end
            -- store data for rebuilding
            -- unit id is not needed during rebuild but is needed if transferred again in the middle of rebuild
            newFactoryUnit.FacRebuild_UnitId = FacRebuild_UnitId
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
        if not table.empty(upgradeUnits) then
            ForkThread(UpgradeUnits, upgradeUnits)
        end
        if not table.empty(pauseKennels) then
            ForkThread(PauseTransferredKennels, pauseKennels)
        end
        if not table.empty(upgradeKennels) then
            ForkThread(UpgradeTransferredKennels, upgradeKennels)
        end
        if not table.empty(factoryRebuildDataTable) then
            ForkThread(FactoryRebuildUnits, factoryRebuildDataTable)
        end
    end

    return newUnits
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

    ---@type RebuildTracker
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
    for i, unit in units do
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

    for _, rebuilder in rebuilders do
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
            local timeMult = (bp.Wreckage.ReclaimTimeMultiplier or 1) * 2
            CreateWreckage(bp, pos, orientation, mass, energy, timeMult)
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

--- Rebuilds `units`, giving a try for each army (in order) in case they can't for unit cap
--- reasons. If a unit cannot be rebuilt at all, a wreckage is placed instead. Each unit can
--- be tagged with `TargetFractionComplete` to be rebuilt with a different build progress.
---@see AddConstructionProgress # doesn't destroy and rebuild the unit
---@param units Unit[]
---@param armies Army[]
function RebuildUnits(units, armies)
    local trackers, blockingEntities = StartRebuildUnits(units)
    for _, army in armies do
        TryRebuildUnits(trackers, army)
    end
    FinalizeRebuiltUnits(trackers, blockingEntities)
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

---@param data {To: integer}
---@param units? Unit[]
function GiveUnitsToPlayer(data, units)
    local manualShare = ScenarioInfo.Options.ManualUnitShare
    if manualShare == 'none' or table.empty(units) then
        return
    end
    local toArmy = data.To
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

        local transferredUnits = TransferUnitsOwnership(units, toArmy)

        -- Whisper from giver → receiver, with an `Area` location so the
        -- receiver can click the cam-icon to jump to where the units are.
        -- The bounding box is computed from the units' positions before
        -- they scatter; padded slightly so a single-unit gift gives the
        -- camera region a non-degenerate framing rectangle.
        local count = transferredUnits and table.getn(transferredUnits) or 0
        if transferredUnits and count > 0 then
            local init = transferredUnits[1]:GetPosition()
            local x0, x1, z0, z1 = init[1], init[1], init[3], init[3]
            for _, unit in transferredUnits do
                local pos = unit:GetPosition()
                if pos[1] < x0 then x0 = pos[1] end
                if pos[1] > x1 then x1 = pos[1] end
                if pos[3] < z0 then z0 = pos[3] end
                if pos[3] > z1 then z1 = pos[3] end
            end
            local pad = 30
            local area = { x0 = x0 - pad, x1 = x1 + pad, y0 = z0 - pad, y1 = z1 + pad }
            local fromBrain = ArmyBrains[owner]
            local fromName = fromBrain.Nickname or tostring(owner)

            -- Specialize the wording when every shared unit is an engineer
            -- — "shared 5 engineers" reads more naturally than "shared 5
            -- units" when the transfer is e.g. a builder pool. Mixed
            -- transfers fall through to the generic noun.
            local allEngineers = true
            for _, unit in transferredUnits do
                if not EntityCategoryContains(categories.ENGINEER, unit) then
                    allEngineers = false
                    break
                end
            end

            local locKey, fallback
            if allEngineers then
                if count == 1 then
                    locKey, fallback = 'chat_engineers_received_one', '%s shared an engineer with you.'
                else
                    locKey, fallback = 'chat_engineers_received_many', '%s shared %d engineers with you.'
                end
            else
                if count == 1 then
                    locKey, fallback = 'chat_units_received_one', '%s shared a unit with you.'
                else
                    locKey, fallback = 'chat_units_received_many', '%s shared %d units with you.'
                end
            end

            local args = count == 1 and { fromName } or { fromName, count }
            fromBrain:SendChatToPlayer(toArmy,
                '<LOC ' .. locKey .. '>' .. fallback,
                args,
                { Area = area }
            )
        end
    end
end

--#endregion

------------------------------------------------------------------------------------------------------------------------
--#region Army Death Unit Transfer

--- Functions related to dealing with unit ownership when an army dies based on share conditions.

local CalculateBrainScore = import("/lua/sim/score.lua").CalculateBrainScore
local FakeTeleportUnits = import("/lua/scenarioframework.lua").FakeTeleportUnits

local defaultTransferCategory = categories.ALLUNITS - categories.WALL - categories.COMMAND
-- only units in this category will be shared under partial share rules
local partialShareCategory = categories.STRUCTURE + categories.ENGINEER

---@param owner integer
---@param categoriesToKill? EntityCategory defaults to all categories
function KillSharedUnits(owner, categoriesToKill)
    local sharedUnitOwner = sharedUnits[owner]
    if table.empty(sharedUnitOwner) then
        return
    end

    for i = table.getn(sharedUnitOwner), 1, -1 do
        local unit = sharedUnitOwner[i]
        if unit.Dead then
            table.remove(sharedUnitOwner, i) -- don't let them keep clogging our list!
        elseif unit.oldowner == owner and
            (not categoriesToKill or EntityCategoryContains(categoriesToKill, unit))
        then
            table.remove(sharedUnitOwner, i)
            unit:Kill()
        end
    end
end

--- Given that `deadArmy` just died, redistributes their unit cap based on the scenario options
---@param deadArmy integer
function UpdateUnitCap(deadArmy)
    local shareCapOption = ScenarioInfo.Options.ShareUnitCap
    if not shareCapOption or shareCapOption == 'none' then
        return
    end
    if not ArmyBrains[deadArmy]:IsDefeated() then
        -- this is gonna give everyone some unit cap
        WARN("Error while updating unit cap: dead army isn't defeated")
    end
    local shareToAll = false
    if shareCapOption == "all" then
        shareToAll = true
    elseif shareCapOption ~= "allies" then
        WARN("Unknown share unit cap mode: " .. tostring(shareCapOption))
    end

    local aliveCount = 0
    ---@type AIBrain[]
    local alive = {}

    for index, brain in ArmyBrains do
        if not ArmyIsCivilian(index) and not brain:IsDefeated() and
            (shareToAll or IsAlly(deadArmy, index))
        then
            aliveCount = aliveCount + 1
            alive[aliveCount] = brain
        end
    end

    if aliveCount > 0 then
        local capChng = GetArmyUnitCap(deadArmy) / aliveCount
        for _, brain in alive do
            SetArmyUnitCap(brain.Army, GetArmyUnitCap(brain.Army) + capChng)
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
    if table.empty(brains) then
        return
    end
    categoriesToTransfer = categoriesToTransfer or defaultTransferCategory

    if transferUnfinishedUnits then
        local indexes = {}
        for _, brain in brains do
            table.insert(indexes, brain.Army)
        end
        local units = self:GetListOfUnits(categoriesToTransfer, false)
        TransferUnfinishedUnitsAfterDeath(units, indexes)
    end

    local totalNewUnits = {}

    for _, brain in brains do
        local units = self:GetListOfUnits(categoriesToTransfer, false)
        if not table.empty(units) then
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

--- Returns a table of the allies and enemies of a brain, and civilians.
---@param armyIndex integer
---@return { Civilians: AIBrain[], Enemies: AIBrain[], Allies: AIBrain[] } brainCategories
function GetAllegianceCategories(armyIndex)
    local brainCategories = { Enemies = {}, Civilians = {}, Allies = {} }

    for index, brain in ArmyBrains do
        if not brain:IsDefeated() and armyIndex ~= index then
            if ArmyIsCivilian(index) then
                table.insert(brainCategories.Civilians, brain)
            elseif IsEnemy(armyIndex, brain.Army) then
                table.insert(brainCategories.Enemies, brain)
            else
                table.insert(brainCategories.Allies, brain)
            end
        end
    end

    return brainCategories
end

--- Transfer a brain's units to other brains, sorted by positive rating and then score.
---@param self AIBrain
---@param brains AIBrain[]
---@param transferUnfinishedUnits boolean
---@param categoriesToTransfer? EntityCategory      # Defaults to ALLUNITS - WALL - COMMAND
---@param reason? string Usually 'FullShare'
---@return Unit[]?
function TransferUnitsToHighestBrain(self, brains, transferUnfinishedUnits, categoriesToTransfer, reason)
    if table.empty(brains) then
        return
    end

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

--local helper functions for KillArmy

-- Seconds to wait after an army has been defeated before we begin processing
-- what to do with the rest of its units. This is so that, if the game ends
-- shortly thereafter due to the army being defeated (as is common), we then
-- have an opportunity to see the final game state as observers before everything
-- would have blown up.
EndGameGracePeriod = 10

-- Set to true in `AbstractVictoryCondition.EndGame` to prevent killing units after a
-- team is victorious but before the sim is stopped.
GameIsEnding = false

--- Kills all given units, if not already dead
---@param toKill Entity[]
local function KillUnits(toKill)
    if not table.empty(toKill) then
        for _, unit in toKill do
            if not IsDestroyed(unit) then
                unit:Kill()
            end
        end
    end
end

---@param self AIBrain
local function KillWalls(self)
    KillUnits(self:GetListOfUnits(categories.WALL, false))
end

---@param self AIBrain
local function KillRemaining(self)
    KillUnits(self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false))
end

--- Remove the borrowed status from units we lent to a set of `brains`.
---@param brains AIBrain[] Usually our allies
---@param selfIndex number
local function TransferOwnershipOfBorrowedUnits(brains, selfIndex)
    for _, brain in brains do
        local units = brain:GetListOfUnits(categories.ALLUNITS, false)
        if not table.empty(units) then
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
    for _, unit in units do
        local oldowner = unit.oldowner
        if oldowner and oldowner ~= self.Army and not ArmyBrains[oldowner]:IsDefeated() then
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
    for _, brain in brains do
        local units = brain:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
        if not table.empty(units) then
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
---@param category? EntityCategory
local function TransferUnitsToKiller(self, category)
    local units = self:GetListOfUnits(category or defaultTransferCategory, false)

    if not table.empty(units) then
        local victoryOption = ScenarioInfo.Options.Victory
        local killerIndex

        if victoryOption == 'demoralization' then
            killerIndex = self.CommanderKilledBy
        elseif victoryOption == 'decapitation' then
            local selfIndex = self.Army
            -- transfer to the killer who defeated the last acu on our team
            local lastCommanderKilledTick = self.CommanderKilledTick
            killerIndex = selfIndex
            ---@param brain AIBrain
            for _, brain in ArmyBrains do
                local brainIndex = brain.Army
                if brainIndex ~= selfIndex and IsAlly(brainIndex, selfIndex) then
                    local brainCommanderKilledTick = brain.CommanderKilledTick
                    if lastCommanderKilledTick < brainCommanderKilledTick then
                        killerIndex = brain.CommanderKilledBy
                        lastCommanderKilledTick = brainCommanderKilledTick
                    end
                end
            end
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
---@param shareOption ShareOption
function KillArmy(self, shareOption)

    -- Kill all walls while the rest of the army is taken care of
    if shareOption == 'ShareUntilDeath' then
        ForkThread(KillWalls, self)
    end

    WaitSeconds(EndGameGracePeriod)

    if GameIsEnding then return end

    local selfIndex = self.Army
    local brainCategories = GetAllegianceCategories(selfIndex)

    -- This part determines the share condition
    if shareOption == 'ShareUntilDeath' then
        KillSharedUnits(selfIndex)
        ReturnBorrowedUnits(self)
    elseif shareOption == 'FullShare' then
        TransferUnitsToHighestBrain(self, brainCategories.Allies, true, nil, "FullShare")
        TransferOwnershipOfBorrowedUnits(brainCategories.Allies, selfIndex)
    elseif shareOption == 'PartialShare' then
        KillSharedUnits(selfIndex, categories.ALLUNITS - partialShareCategory)
        ReturnBorrowedUnits(self)
        TransferUnitsToHighestBrain(self, brainCategories.Allies, true, partialShareCategory - categories.COMMAND, "PartialShare")
        TransferOwnershipOfBorrowedUnits(brainCategories.Allies, selfIndex)
    else
        GetBackUnits(selfIndex, brainCategories.Allies)
        if shareOption == 'CivilianDeserter' then
            TransferUnitsToBrain(self, brainCategories.Civilians, true)
        elseif shareOption == 'TransferToKiller' then
            TransferUnitsToKiller(self)
        elseif shareOption == 'Defectors' then
            TransferUnitsToHighestBrain(self, brainCategories.Enemies, true, nil, "Defectors")
        else -- Something went wrong in settings. Act like share until death to avoid abuse
            WARN('Invalid share condition was used for this game: `' .. (shareOption or 'nil') .. '` Defaulting to killing all units')
            KillSharedUnits(selfIndex)
            ReturnBorrowedUnits(self)
        end
    end

    KillRemaining(self)
end

--- Kills my army after the command units has done their fake recall sequence,
--- according to the given share condition.
---@param self AIBrain
---@param shareOption ShareOption
function KillRecalledArmy(self, shareOption)

    WaitSeconds(EndGameGracePeriod)

    if GameIsEnding then return end

    local brainCategories = GetAllegianceCategories(self.Army)

    -- Since the entire team recalls simultaneously, the things to look out
    -- for are greatly simplified. Note that recalling also recalls all SACU's,
    -- so they additionally shouldn't be transferred.
    local recallCat = defaultTransferCategory - categories.SUBCOMMANDER
    if shareOption == 'CivilianDeserter' then
        TransferUnitsToBrain(self, brainCategories.Civilians, true, recallCat, "CivilianDeserter")
    elseif shareOption == 'Defectors' then
        TransferUnitsToHighestBrain(self, brainCategories.Enemies, true, recallCat, "Defectors")
    end

    KillRemaining(self)
end

--- Blocks the current thread until all units in a list are dead, or until an
--- optional timeout. Returns total ticks elapsed, or the original timeout
--- (which could have been negative or fractional) if it was reached after
--- checking the units. If all units are dead upon calling, returns `0`.
---@param units Entity[]
---@param timeout? integer in ticks
---@return integer elapsed
function WaitUntilUnitsDeadOrTimeout(units, timeout)
    if table.empty(units) then
        return 0
    end
    if timeout and timeout <= 0 then
        -- It seems likely that most code will compare to the original timeout
        -- to see if the suspension did indeed timeout - returning `0` will
        -- not work in cases where the timeout was negative.
        return timeout
    end
    local elapsed = 0
    while true do
        local noneAlive = true
        for _, unit in units do
            if not unit.Dead then
                noneAlive = false
                break
            end
        end
        if noneAlive then
            return elapsed
        end
        if timeout and elapsed >= timeout then
            -- return `timeout` instead of `elapsed` in case it was fractional
            return timeout
        end
        WaitTicks(1)

        elapsed = elapsed + 1
    end
end



local StartCountdown = StartCountdown -- as defined in SimSync.lua

-- The time in ticks after taking damage that commanders are considered safe and not abusing disconnect rules
-- Also the duration used for the delayed recall disconnect option.
CommanderSafeTime = 2 * 60 * 10 -- 2 minutes
-- When using the delayed recall disconnect option, commanders will be shared at
-- least until this time in game has passed
MinimumShareTime = 5 * 60 * 10 -- 5 minutes


--- Kills all given commanders that are considered unsafe as of a given game tick
--- (defaulting to now), and returns the rest.
---@param commanders ACUUnit[]
---@param tick? integer defaults to `GetGameTick()`
---@return ACUUnit[] safeCommanders
function KillUnsafeCommanders(commanders, tick)
    tick = tick or GetGameTick()
    local safeCommanders = {}
    for _, com in commanders do
        if com.LastTickDamaged and com.LastTickDamaged + CommanderSafeTime > tick then
            com:Kill()
        else
            table.insert(safeCommanders, com)
        end
    end
    return safeCommanders
end

--- Shares all units including ACUs. When the shared ACUs die or recall after
--- `shareTime`, kills my army according to the given share condition.
---@param self AIBrain
---@param shareOption ShareOption
---@param shareTime integer Game time in ticks
function KillArmyOnDelayedRecall(self, shareOption, shareTime)
    -- Share units including ACUs and walls and keep track of ACUs
    local brainCategories = GetAllegianceCategories(self.Army)
    local newUnits = TransferUnitsToHighestBrain(self, brainCategories.Allies, true, categories.ALLUNITS, "DisconnectShareTemporary")
    ---@type (ACUUnit|Unit)[]
    local sharedCommanders = EntityCategoryFilterDown(categories.COMMAND, newUnits or {})

    -- non-assassination games could have an army abandon without having any commanders
    if not table.empty(sharedCommanders) then
        local timeout = shareTime - GetGameTick()
        if timeout < 0 then
            WARN("Given time to end sharing is in the past")
        end
        local countdown = math.floor(timeout / 10)

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
            StartCountdown(com.EntityId, countdown)
        end

        local elapsed = WaitUntilUnitsDeadOrTimeout(sharedCommanders, timeout)

        -- if all the commanders die early, assume disconnect abuse and apply standard share condition. Only makes sense in Assassination.
        local scenarioOptions = ScenarioInfo.Options
        if elapsed < timeout and scenarioOptions.Victory == "demoralization" then
            shareOption = scenarioOptions.Share
        else
            -- filter out commanders that are not currently safe and should explode because KillArmy might not
            local safeCommanders = KillUnsafeCommanders(sharedCommanders)

            if not table.empty(safeCommanders) then
                -- note: this adds 3 seconds to the grace period
                FakeTeleportUnits(safeCommanders, true)
            end
        end
    end

    KillArmy(self, shareOption)
end

--- Shares all units including ACUs. When the shared ACUs die, kills my army according to the given share condition.
---@param self AIBrain
---@param shareOption ShareOption
function KillArmyOnACUDeath(self, shareOption)
    -- Share units including ACUs and walls and keep track of ACUs
    local brainCategories = GetAllegianceCategories(self.Army)
    local newUnits = TransferUnitsToHighestBrain(self, brainCategories.Allies, true, categories.ALLUNITS, "DisconnectSharePermanent")
    local sharedCommanders = EntityCategoryFilterDown(categories.COMMAND, newUnits or {})

    if not table.empty(sharedCommanders) then
        local elapsed = WaitUntilUnitsDeadOrTimeout(sharedCommanders) -- note there's no timeout

        -- if all the commanders die early, assume disconnect abuse and apply standard share condition. Only makes sense in Assassination.
        local scenarioOptions = ScenarioInfo.Options
        if elapsed < CommanderSafeTime and scenarioOptions.Victory == "demoralization" then
            shareOption = scenarioOptions.Share
        end
    end

    KillArmy(self, shareOption)
end

---@param self AIBrain
---@param shareOption DisconnectShareOption
---@param shareAcuOption DisconnectShareCommandersOption
---@param victoryOption VictoryCondition
function KillAbandonedArmy(self, shareOption, shareAcuOption, victoryOption)
    if shareOption == 'SameAsShare' then
        shareOption = ScenarioInfo.Options.Share
    end

    -- Don't apply instant-effect disconnect rules for players/ACUs that might be defeated soon,
    -- and might have intentionally disconnected.
    if shareAcuOption == 'Explode' or shareAcuOption == 'Recall' then
        local safeCommanders
        local commanders = self:GetListOfUnits(categories.COMMAND, false)
        if shareAcuOption == 'Recall' then
            safeCommanders = KillUnsafeCommanders(commanders)
        else
            -- explode all the ACUs so they don't get shared
            KillUnits(commanders)
        end

        -- Only handle Assassination victory, as in other settings the player is unlikely to be defeated soon
        if victoryOption == 'demoralization' and table.empty(safeCommanders) then
            shareOption = ScenarioInfo.Options.Share
        end

        -- non-assassination modes can have armies abandon without commanders
        if shareAcuOption == 'Recall' and not table.empty(safeCommanders) then
            -- note: this adds 3 seconds to the grace period
            FakeTeleportUnits(safeCommanders, true)
        end

        KillArmy(self, shareOption)

    elseif shareAcuOption == 'RecallDelayed' or shareAcuOption == 'Permanent' then

        if victoryOption ~= 'demoralization' then
            shareOption = 'FullShare'
        end

        if shareAcuOption == 'RecallDelayed' then
            local shareTime = math.max(MinimumShareTime, GetGameTick() + CommanderSafeTime)
            KillArmyOnDelayedRecall(self, shareOption, shareTime)
        else
            KillArmyOnACUDeath(self, shareOption)
        end

    else
        WARN('Invalid disconnection ACU share condition was used for this game: `' .. (shareAcuOption or 'nil') .. '` Defaulting to exploding ACU.')
        KillArmy(self, shareOption)
    end
end

--#endregion

local SorianUtils = import("/lua/ai/sorianutilities.lua")

--- Disables the AI for non-player armies.
---@param self BaseAIBrain
function DisableAI(self)
    -- print AI "ilost" text to chat
    SorianUtils.AISendChat('enemies', self.Nickname, 'ilost')
    -- remove PlatoonHandle from all AI units before we kill / transfer the army
    local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
    if not table.empty(units) then
        for _, unit in units do
            if not unit.Dead then
                local handle = unit.PlatoonHandle
                if handle and self:PlatoonExists(handle) then
                    handle:Stop()
                    handle:PlatoonDisbandNoAssign()
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
        for _, manager in self.BuilderManagers do
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
                manager.EngineerManager = nil
            end

            if manager.FactoryManager then
                manager.FactoryManager:Destroy()
                manager.FactoryManager = nil
            end

            if manager.PlatoonFormManager then
                manager.PlatoonFormManager:Destroy()
                manager.PlatoonFormManager = nil
            end
            if manager.StrategyManager then
                manager.StrategyManager:SetEnabled(false)
                manager.StrategyManager:Destroy()
            end
            manager.BaseSettings = nil
            manager.BuilderHandles = nil
            manager.Position = nil
        end
    end
    -- delete the AI pathcache
    self.PathCache = nil
end

------------------------------------------------------------------------------------------------------------------------
--#region Non-Unit Transfer Diplomacy

---@param data {Army: integer, Value: boolean}
function SetResourceSharing(data)
    -- feature: resource sharing can only be changed when teams are unlocked
    if ScenarioInfo.Options.TeamLock == "locked" then
        return
    end

    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = ArmyBrains[army]
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
    local brain = ArmyBrains[army]
    brain.RequestingAlliedVictory = data.Value
end

---@param data {Army: Army, Value: boolean}
function SetOfferDraw(data)
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = ArmyBrains[army]
    brain.OfferingDraw = data.Value
end

-- Chat-relay helpers moved to `/lua/ChatUtils.lua`:
--   * `SendChatMessage`  — trusted sim relay that feeds `Sync.ChatMessages`.

---@param data {From: Army, To: Army, Mass: number, Energy: number, Sender?: string, Msg?: table}
function GiveResourcesToPlayer(data)
    -- The refactored chat path (see `ChatUtils.SendChatMessage`) still fires
    -- this callback once per outgoing chat message with `Sender`/`Msg` set,
    -- because external replay parsers scrape those fields out of the recorded
    -- args. The legacy per-receive `SendChatToReplay` write into
    -- `Sync.UnitData.Chat` is gone — chat now syncs through
    -- `Sync.ChatMessages`.

    -- Ignore observers and players trying to send resources to themselves or to enemies
    if data.From == -1 or data.From == data.To or not IsAlly(data.From, data.To) then
        return
    end
    if not OkayToMessWithArmy(data.From) then
        return
    end

    local fromBrain = ArmyBrains[data.From]
    local toBrain = ArmyBrains[data.To]
    -- Abort if any of the armies is defeated or if trying to send a negative value
    if fromBrain:IsDefeated() or toBrain:IsDefeated() or data.Mass < 0 or data.Energy < 0 then
        return
    end
    local massTaken = fromBrain:TakeResource('MASS', data.Mass * fromBrain:GetEconomyStored('MASS'))
    local energyTaken = fromBrain:TakeResource('ENERGY', data.Energy * fromBrain:GetEconomyStored('ENERGY'))

    -- `GiveResource` silently caps at the receiver's max storage, and
    -- storage stats only update next tick, so derive what actually lands
    -- up front from `MaxStorage - Stored`.
    local massCapacity = toBrain:GetArmyStat('Economy_MaxStorage_Mass', 0).Value
        - toBrain:GetEconomyStored('MASS')
    local energyCapacity = toBrain:GetArmyStat('Economy_MaxStorage_Energy', 0).Value
        - toBrain:GetEconomyStored('ENERGY')
    local massGiven = math.min(massTaken, massCapacity)
    local energyGiven = math.min(energyTaken, energyCapacity)

    toBrain:GiveResource('MASS', massGiven)
    toBrain:GiveResource('ENERGY', energyGiven)

    -- Whisper from giver → receiver so the line reads with the giver's
    -- attribution. Three LOC keys rather than one templated string so each
    -- locale gets a clean sentence per case.
    local mass = math.floor(massGiven)
    local energy = math.floor(energyGiven)
    local toArmy = data.To --[[@as integer]]
    local fromName = fromBrain.Nickname or tostring(data.From)
    if mass > 0 and energy > 0 then
        fromBrain:SendChatToPlayer(toArmy,
            "<LOC chat_resources_received_both>%s sent you %d mass and %d energy.",
            { fromName, mass, energy }
        )
    elseif mass > 0 then
        fromBrain:SendChatToPlayer(toArmy,
            "<LOC chat_resources_received_mass>%s sent you %d mass.",
            { fromName, mass }
        )
    elseif energy > 0 then
        fromBrain:SendChatToPlayer(toArmy,
            "<LOC chat_resources_received_energy>%s sent you %d energy.",
            { fromName, energy }
        )
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

        if not Sync.BrokenAlliances then
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
            if not Sync.FormedAlliances then
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

local CommandSourceToArmyMap
--- Retrieves the army index corresponding to the given command source index.
---@param source integer
---@return integer
function GetArmyOfCommandSource(source)
    if not CommandSourceToArmyMap then
        CommandSourceToArmyMap = {}
        local commandSourceIndex = 1
        for index, army in ArmyBrains do
            if army.Human then
                CommandSourceToArmyMap[commandSourceIndex] = index
                commandSourceIndex = commandSourceIndex + 1
            end
        end
    end

    return CommandSourceToArmyMap[source]
end

--- Retrieves the army index corresponding to the current command source.
---@return integer
function GetCurrentCommandSourceArmy()
    return GetArmyOfCommandSource(GetCurrentCommandSource())
end


