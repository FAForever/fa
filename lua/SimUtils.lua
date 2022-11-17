-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

-- ==============================================================================
-- Diplomacy
-- ==============================================================================

local CreateWreckage = import("/lua/wreckage.lua").CreateWreckage

local transferUnbuiltCategory = categories.EXPERIMENTAL + categories.TECH3 * categories.STRUCTURE * categories.ARTILLERY
local transferUnitsCategory = categories.ALLUNITS - categories.INSIGNIFICANTUNIT
local buildersCategory = categories.ALLUNITS - categories.CONSTRUCTION - categories.ENGINEER

local sharedUnits = {}

---@param owner number
function KillSharedUnits(owner)
    local sharedUnitOwner = sharedUnits[owner]
    if sharedUnitOwner and not table.empty(sharedUnitOwner) then
        for _, unit in sharedUnitOwner do
            if not unit.Dead and unit.oldowner == owner then
                unit:Kill()
            end
        end
        sharedUnits[owner] = {}
    end
end

-- used to make more expensive units transfer first, in case there's a unit cap issue
local function TransferUnitsOwnershipComparator(a, b)
    a = a.Blueprint or a.Blueprint
    b = b.Blueprint or b.Blueprint
    return a.Economy.BuildCostMass > b.Economy.BuildCostMass
end

--- Temporarily disables the weapons of gifted units
---@param weapon Weapon
local function TransferUnitsOwnershipDelayedWeapons(weapon)
    if not weapon:BeenDestroyed() then
        -- compute delay
        local bp = weapon.Blueprint
        local delay = 1 / bp.RateOfFire
        WaitSeconds(delay)

        -- enable the weapon again if it still exists
        if not weapon:BeenDestroyed() then
            weapon:SetEnabled(true)
        end
    end
end

--- Transfers units to an army, returning the new units (since changing the army
--- replaces the units with new ones)
---@param units Unit[]
---@param toArmy number 
---@param captured boolean
---@return Unit[]?
function TransferUnitsOwnership(units, toArmy, captured)
    local toBrain = GetArmyBrain(toArmy)
    if not toBrain or toBrain:IsDefeated() or not units or table.empty(units) then
        return
    end
    local categoriesENGINEERSTATION = categories.ENGINEERSTATION
    local shareUpgrades = ScenarioInfo.Options.Share == 'FullShare'

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

    for _, unit in units do
        local owner = unit.Army
        -- Only allow units not attached to be given. This is because units will give all of its
        -- children over as well, so we only want the top level units to be given.
        -- Units currently being captured are also denied
        if  owner == toArmy or
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
        local numNukes = unit:GetNukeSiloAmmoCount() -- nuclear missiles; SML or SMD
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local unitSync = unit.Sync
        local massKilled = unitSync.totalMassKilled
        local massKilledTrue = unitSync.totalMassKilledTrue
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local shieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local activeEnhancements
        local oldowner = unit.oldowner
        local upgradesTo = unit.UpgradesTo
        local defaultBuildRate
        local upgradeBuildTimeComplete
        local exclude

        local shield = unit.MyShield
        if shield then
            shieldIsOn = unit:ShieldIsOn()
            shieldHealth = shield:GetHealth()
        end
        local fuelUseTime = bpPhysics.FuelUseTime
        if fuelUseTime and fuelUseTime > 0 then   -- going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio()       -- usage is more reliable then unit.HasFuel
            hasFuel = true                        -- cause some buildings say they use fuel
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

        if categoriesHash.ENGINEERSTATION and categoriesHash.UEF then
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

        -- changing owner
        unit = ChangeUnitArmy(unit, toArmy)
        if not unit then
            continue
        end

        newUnitCount = newUnitCount + 1
        newUnits[newUnitCount] = unit

        if IsAlly(owner, toArmy) then
            if not oldowner then
                oldowner = owner
            end

            local sharedUnitsTable = sharedUnits[oldowner]
            if not sharedUnitsTable then
                sharedUnitsTable = {}
                sharedUnits[oldowner] = sharedUnitsTable
            end
            table.insert(sharedUnitsTable, unit)
        end

        unit.oldowner = oldowner

        -- A F T E R
        if massKilled and massKilled > 0 then
            unit:CalculateVeterancyLevelAfterTransfer(massKilled, massKilledTrue)
        end
        if activeEnhancements then
            for _, enh in activeEnhancements do
                unit:CreateEnhancement(enh)
            end
        end
        local maxHealth = unit:GetMaxHealth()
        if unitHealth > maxHealth then
            unitHealth = maxHealth
        end
        unit:SetHealth(unit, unitHealth)
        if hasFuel then
            unit:SetFuelRatio(fuelRatio)
        end
        if numNukes and numNukes > 0 then
            unit:GiveNukeSiloAmmo(numNukes - unit:GetNukeSiloAmmoCount())
        end
        if numTacMsl and numTacMsl > 0 then
            unit:GiveTacticalSiloAmmo(numTacMsl - unit:GetTacticalSiloAmmoCount())
        end
        local newShield = unit.MyShield
        if newShield then
            newShield:SetHealth(unit, shieldHealth)
            if shieldIsOn then
                unit:EnableShield()
            else
                unit:DisableShield()
            end
        end
        if EntityCategoryContains(categoriesENGINEERSTATION, unit) then
            if not upgradeBuildTimeComplete or not shareUpgrades then
                if categoriesHash.UEF then
                    -- use special thread for UEF Kennels
                    -- Give them 1 tick to spawn their drones and then pause both station and drone
                    pauseKennelCount = pauseKennelCount + 1
                    pauseKennels[pauseKennelCount] = unit
                else -- pause cybran hives immediately
                    unit:SetPaused(true)
                end
            elseif categoriesHash.UEF then
                unit.UpgradesTo = upgradesTo
                unit.DefaultBuildRate = defaultBuildRate
                unit.TargetUpgradeBuildTime = upgradeBuildTimeComplete

                upgradeKennelCount = upgradeKennelCount + 1
                upgradeKennels[upgradeKennelCount] = unit

                exclude = true
            end
        end

        if upgradeBuildTimeComplete and not exclude then
            unit.UpgradesTo = upgradesTo
            unit.DefaultBuildRate = defaultBuildRate
            unit.TargetUpgradeBuildTime = upgradeBuildTimeComplete

            upgradeUnitCount = upgradeUnitCount + 1
            upgradeUnits[upgradeUnitCount] =  unit
        end

        unit.IsBeingTransferred = nil

        if unit.OnGiven then
            unit:OnGiven(unit)
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
    end

    -- add delay on turning on each weapon 
    for _, unit in newUnits do
        -- disable all weapons, enable with a delay
        for k = 1, unit.WeaponCount do
            local weapon = unit:GetWeapon(k)
            weapon:SetEnabled(false)
            weapon:ForkThread(TransferUnitsOwnershipDelayedWeapons)
        end
    end

    return newUnits
end

--- Pauses all drones in `kennels`
---@param kennels Unit[]
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
---@param kennels any
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

            IssueUpgrade({unit}, unit.UpgradesTo)
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
--- The transfer procedure is fairly expensive, so it is filtered to important units (EXPs and T3 arty).
---@param units Unit[]
---@param armies Army[]
function TransferUnfinishedUnitsAfterDeath(units, armies)
    local unbuiltUnits = {}
    local unbuiltUnitCount = 0
    for _, unit in EntityCategoryFilterDown(transferUnbuiltCategory, units) do
        if unit:IsBeingBuilt() then
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
        IssueUpgrade({unit}, unit.UpgradesTo)
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
    local wrecks = GetReclaimablesInRect(unit:GetSkirtRect()) -- returns nil instead of empty table when empty
    if wrecks then
        for _, reclaim in wrecks do
            if reclaim.IsWreckage then
                -- collision shape to none to prevent it from blocking, keep track to revert later
                reclaim:SetCollisionShape('None')
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
    for k, tracker in ipairs(trackers) do
        if tracker.Success then
            continue
        end
        -- create invisible drone which belongs to allied army. BuildRange = 10000
        local rebuilder = CreateUnitHPR('ZXA0001', army, 5, 20, 5, 0, 0, 0)
        rebuilder.TargetBuildTime = tracker.TargetBuildTime
        rebuilders[k] = rebuilder

        IssueBuildMobile({rebuilder}, tracker.UnitPos, tracker.UnitBlueprintID, {})
    end

    WaitTicks(3) -- wait some ticks (3 is minimum), IssueBuildMobile() is not instant

    for k, rebuilder in rebuilders do
        rebuilder:SetBuildRate(rebuilder.TargetBuildTime * 10) -- set crazy build rate and consumption = 0
        rebuilder:SetConsumptionPerSecondMass(0)
        rebuilder:SetConsumptionPerSecondEnergy(0)
    end

    WaitTicks(1)

    for k, rebuilder in ipairs(rebuilders) do
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
        if not tracker.Success and tracker.CanCreateWreck then -- create 50% wreck. Copied from Unit:CreateWreckageProp()
            local bp = tracker.UnitBlueprint
            local pos = tracker.UnitPos
            local orientation = tracker.UnitOrientation
            local mass = bp.Economy.BuildCostMass * 0.57 --0.57 to compensate some multipliers in CreateWreckage()
            local energy = 0
            local time = (bp.Wreckage.ReclaimTimeMultiplier or 1) * 2
            CreateWreckage(bp, pos, orientation, mass, energy, time)
        end
    end

    -- revert collision shapes of any blocking units or wreckage
    for _, entity in blockingEntities do
        if not entity:BeenDestroyed() then
            entity:RevertCollisionShape()
        end
    end
end

---@param data {To: number}
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

---@param data {Army: number, Value: boolean}
function SetResourceSharing(data)
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = GetArmyBrain(army)
    brain:SetResourceSharing(data.Value)
end

---@param data {Army: number, Value: boolean}
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

---@param data {Army: number, Value: boolean}
function SetOfferDraw(data)
    local army = data.Army
    if not OkayToMessWithArmy(army) then
        return
    end
    local brain = GetArmyBrain(army)
    brain.OfferingDraw = data.Value
end

-- ==============================================================================
-- UNIT CAP
-- ==============================================================================

--- Given that `deadArmy` just died, redistributes their unit cap based on the scenario options
---@param deadArmy number
function UpdateUnitCap(deadArmy)
    -- If we are asked to share out unit cap for the defeated army, do the following...
    local options = ScenarioInfo.Options
    local mode = options.ShareUnitCap
    if not mode or mode == 'none' then
        return
    end
    local aliveCount = 0
    local alive = {}
    local caps = {}

    for index, brain in ArmyBrains do
        if (mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) and not ArmyIsCivilian(index) then
            if not brain:IsDefeated() then
                brain.index = index
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
            SetArmyUnitCap(brain.index, caps[i] + capChng)
        end
    end
end

---@param data {Sender: number, Msg: string}
function SendChatToReplay(data)
    if data.Sender and data.Msg then
        if not Sync.UnitData.Chat then
            Sync.UnitData.Chat = {}
        end
        table.insert(Sync.UnitData.Chat, {sender = data.Sender, msg = data.Msg})
    end
end

---@param data {From: number, To: number, Mass: number, Energy: number}
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
        local massTaken = fromBrain:TakeResource('Mass', data.Mass * fromBrain:GetEconomyStored('Mass'))
        local energyTaken = fromBrain:TakeResource('Energy', data.Energy * fromBrain:GetEconomyStored('Energy'))

        toBrain:GiveResource('Mass', massTaken)
        toBrain:GiveResource('Energy', energyTaken)
    end
end

---@param data {From: number, To: number}
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

---@param resultData {From: number, To: number, ResultValue: DiplomacyActionType}
function OnAllianceResult(resultData)
    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(resultData.From) then
        if resultData.ResultValue == "accept" then
            SetAlliance(resultData.From,resultData.To, "Ally")
            if Sync.FormedAlliances == nil then
                Sync.FormedAlliances = {}
            end
            table.insert(Sync.FormedAlliances, { From = resultData.From, To = resultData.To })
        end
    end
    import("/lua/simping.lua").OnAllianceChange()
end
import("/lua/simplayerquery.lua").AddResultListener("OfferAlliance", OnAllianceResult)
