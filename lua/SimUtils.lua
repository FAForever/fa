-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

-- ==============================================================================
-- Diplomacy
-- ==============================================================================

local CreateWreckage = import('/lua/wreckage.lua').CreateWreckage

local transferUnbuiltCategory = categories.EXPERIMENTAL + categories.TECH3 * categories.STRUCTURE * categories.ARTILLERY
local transferUnitsCategory = categories.ALLUNITS - categories.INSIGNIFICANTUNIT
local buildersCategory = categories.ALLUNITS - categories.CONSTRUCTION - categories.ENGINEER


local sharedUnits = {}


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
    import('/lua/SimPing.lua').OnAllianceChange()
end

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
    import('/lua/SimPing.lua').OnAllianceChange()
end
import('/lua/SimPlayerQuery.lua').AddResultListener("OfferAlliance", OnAllianceResult)

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

local function TransferUnitsOwnershipComparator(a, b)
    a = a.Blueprint or a:GetBlueprint()
    b = b.Blueprint or b:GetBlueprint()
    return a.Economy.BuildCostMass > b.Economy.BuildCostMass
end

local function TransferUnitsOwnershipDelayedWeapons(weapon)
    if not weapon:BeenDestroyed() then
        -- compute delay
        local bp = weapon:GetBlueprint()
        local delay = 1 / bp.RateOfFire
        WaitSeconds(delay)

        -- enable the weapon again if it still exists
        if not weapon:BeenDestroyed() then
            weapon:SetEnabled(true)
        end
    end
end

function TransferUnitsOwnership(units, toArmyIndex, captured)
    local toBrain = GetArmyBrain(toArmyIndex)
    if not toBrain or toBrain:IsDefeated() or not units or table.empty(units) then
        return
    end
    local shareUpgrades

    if ScenarioInfo.Options.Share == 'FullShare' then
        shareUpgrades = true
    end

    -- do not gift insignificant units
    units = EntityCategoryFilterDown(transferUnitsCategory, units)

    -- gift most valuable units first
    table.sort(units, TransferUnitsOwnershipComparator)

    local newUnits = {}
    local upgradeUnits = {}
    local pauseKennels = {}
    local upgradeKennels = {}

    for _, unit in units do
        local owner = unit.Army
        -- Only allow units not attached to be given. This is because units will give all of it's children over
        -- aswell, so we only want the top level units to be given.
        -- Units currently being captured is also denied
        if  owner == toArmyIndex or
            unit:GetParent() ~= unit or
            unit.Parent and unit.Parent ~= unit or
            unit.CaptureProgress > 0
        then
            continue
        end

        local bp = unit:GetBlueprint()

        -- B E F O R E
        local numNukes = unit:GetNukeSiloAmmoCount() -- nuclear missiles; SML or SMD
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
        local massKilled = unit.Sync.totalMassKilled
        local massKilledTrue = unit.Sync.totalMassKilledTrue
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local ShieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local activeEnhancements = {}
        local oldowner = unit.oldowner
        local upgradesTo = unit.UpgradesTo
        local defaultBuildRate
        local upgradeBuildRate
        local exclude

        if unit.MyShield then
            shieldIsOn = unit:ShieldIsOn()
            ShieldHealth = unit.MyShield:GetHealth()
        end
        if bp.Physics.FuelUseTime and bp.Physics.FuelUseTime > 0 then   -- going through the BP to check for fuel
            fuelRatio = unit:GetFuelRatio()                             -- usage is more reliable then unit.HasFuel
            hasFuel = true                                              -- cause some buildings say they use fuel
        end
        local enhancements = bp.Enhancements
        if enhancements then
            for _, enh in enhancements do
                if unit:HasEnhancement(enh) then
                   table.insert(activeEnhancements, enh)
                end
            end
        end

        if bp.CategoriesHash.ENGINEERSTATION and bp.CategoriesHash.UEF then
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
                --What build rate do we need to reach required % in 1 tick?
                upgradeBuildRate = upgradeBuildTime * progress * 10
            end
        end

        unit.IsBeingTransferred = true

        -- changing owner
        unit = ChangeUnitArmy(unit, toArmyIndex)
        if not unit then
            continue
        end

        table.insert(newUnits, unit)

        unit.oldowner = oldowner

        if IsAlly(owner, toArmyIndex) then
            if not unit.oldowner then
                unit.oldowner = owner
            end

            if not sharedUnits[unit.oldowner] then
                sharedUnits[unit.oldowner] = {}
            end
            table.insert(sharedUnits[unit.oldowner], unit)
        end

        -- A F T E R
        if massKilled and massKilled > 0 then
            unit:CalculateVeterancyLevelAfterTransfer(massKilled, massKilledTrue)
        end
        if activeEnhancements and not table.empty(activeEnhancements) then
            for _, enh in activeEnhancements do
                unit:CreateEnhancement(enh)
            end
        end
        if unitHealth > unit:GetMaxHealth() then
            unitHealth = unit:GetMaxHealth()
        end
        unit:SetHealth(unit,unitHealth)
        if hasFuel then
            unit:SetFuelRatio(fuelRatio)
        end
        if numNukes and numNukes > 0 then
            unit:GiveNukeSiloAmmo((numNukes - unit:GetNukeSiloAmmoCount()))
        end
        if numTacMsl and numTacMsl > 0 then
            unit:GiveTacticalSiloAmmo((numTacMsl - unit:GetTacticalSiloAmmoCount()))
        end
        if unit.MyShield then
            unit.MyShield:SetHealth(unit, ShieldHealth)
            if shieldIsOn then
                unit:EnableShield()
            else
                unit:DisableShield()
            end
        end
        if EntityCategoryContains(categories.ENGINEERSTATION, unit) then
            if not upgradeBuildRate or not shareUpgrades then
                if bp.CategoriesHash.UEF then
                    -- use special thread for UEF Kennels.
                    -- Give them 1 tick to spawn their drones and then pause both station and drone.
                    table.insert(pauseKennels, unit)
                else -- pause cybran hives immediately
                    unit:SetPaused(true)
                end
            elseif bp.CategoriesHash.UEF then
                unit.UpgradesTo = upgradesTo
                unit.DefaultBuildRate = defaultBuildRate
                unit.UpgradeBuildRate = upgradeBuildRate

                table.insert(upgradeKennels, unit)

                exclude = true
            end
        end

        if upgradeBuildRate and not exclude then
            unit.UpgradesTo = upgradesTo
            unit.DefaultBuildRate = defaultBuildRate
            unit.UpgradeBuildRate = upgradeBuildRate

            table.insert(upgradeUnits, unit)
        end

        unit.IsBeingTransferred = false

        if unit.OnGiven then
            unit:OnGiven(unit)
        end
    end

    if not captured then
        if upgradeUnits[1] then
            ForkThread(UpgradeTransferredUnits, upgradeUnits)
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

function PauseTransferredKennels(pauseKennels)
    WaitTicks(1) -- spawn drones

    for _, unit in pauseKennels do
        unit:SetPaused(true)
        local podData = unit.PodData
        if podData then
            for _, pod in podData do -- pause drones
                local podHandle = pod.PodHandle
                if podHandle then
                    podHandle:SetPaused(true)
                end
            end
        end
    end
end

function UpgradeTransferredUnits(units)
    for _, unit in units do
        IssueUpgrade({unit}, unit.UpgradesTo)
    end

    WaitTicks(3)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.UpgradeBuildRate)
            unit:SetConsumptionPerSecondMass(0)
            unit:SetConsumptionPerSecondEnergy(0)
        end
    end

    WaitTicks(1)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.DefaultBuildRate)
            unit:SetPaused(true) -- `SetPaused` updates ConsumptionPerSecond values
        end
    end
end

function UpgradeTransferredKennels(upgradeKennels)
    WaitTicks(1) -- spawn drones

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            for _, pod in unit.PodData or {} do -- pause Kennels drones
                if pod.PodHandle then
                    pod.PodHandle:SetPaused(true)
                end
            end

            IssueUpgrade({unit}, unit.UpgradesTo)
        end
    end

    WaitTicks(3)

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.UpgradeBuildRate)
            unit:SetConsumptionPerSecondMass(0)
            unit:SetConsumptionPerSecondEnergy(0)
        end
    end

    WaitTicks(1)

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.DefaultBuildRate)
            unit:SetPaused(true) -- `SetPaused` updates ConsumptionPerSecond values
        end
    end
end

--- Takes the units and tries to rebuild them for each army (in order). 
--- The transfer procedure is fairly complex, so it is filtered to important units (EXPs and T3 arty).
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


--- Rebuilds `units`, giving a try for each army (in order). If a unit cannot be rebuilt,
--- a wreckage is placed instead. Each unit can be tagged with `TargetFractionComplete` to be
--- rebuilt with a different build progress.
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
---@field UnitHealth number
---@field UnitPos Vector,
---@field UnitID string
---@field UnitOrientation Quaternion
---@field UnitBlueprint UnitBlueprint
---@field UnitBlueprintID string
---@field UnitProgress number
---@field CanCreateWreck boolean
---@field RebuildRate number
---@field Success boolean

---@alias RevertibleCollisionShapeEntity Prop | Unit

--- Initializes the rebuild process for a `unit`. It is destroyed in this method and replaced
--- with a tracker. Any possible entities that could block construction have their collision
--- shapes disabled and are placed into `blockingEntities` to be reverted later. A unit can be
--- tagged with `TargetFractionComplete` to be rebuilt with a different build progress.
---@param unit Unit
---@param blockingEntities RevertibleCollisionShapeEntity[]
---@return RebuildTracker tracker
function CreateRebuildTracker(unit, blockingEntities)
    local bp = unit:GetBlueprint()
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
        RebuildRate = progress * buildTime * 10,
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
    for _, tracker in ipairs(trackers) do
        if tracker.Success then
            continue
        end
        -- create invisible drone which belongs to allied army. BuildRange = 10000
        local rebuilder = CreateUnitHPR('ZXA0001', army, 5, 20, 5, 0, 0, 0)
        rebuilder.BuildRate = tracker.BuildRate
        rebuilders[i] = rebuilder

        IssueBuildMobile({rebuilder}, tracker.UnitPos, tracker.UnitBlueprintID, {})
    end

    WaitTicks(3) -- wait some ticks (3 is minimum), IssueBuildMobile() is not instant

    for _, rebuilder in rebuilders do
        rebuilder:SetBuildRate(rebuilder.BuildRate) -- set crazy build rate and consumption = 0
        rebuilder:SetConsumptionPerSecondMass(0)
        rebuilder:SetConsumptionPerSecondEnergy(0)
    end

    WaitTicks(1)

    for i, rebuilder in ipairs(rebuilders) do
        local tracker = trackers[i]
        local newUnit = rebuilder:GetFocusUnit()
        local progressDif = rebuilder:GetWorkProgress() - tracker.UnitProgress
        if newUnit and math.abs(progressDif) < 0.001 then
            newUnit:SetHealth(newUnit, rebuilder.UnitHealth)
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

function GiveUnitsToPlayer(data, units)
    local manualShare = ScenarioInfo.Options.ManualUnitShare
    if manualShare == 'none' then return end

    if units then
        local owner = units[1].Army
        if OkayToMessWithArmy(owner) and IsAlly(owner,data.To) then
            if manualShare == 'no_builders' then
                local unitsBefore = table.getsize(units)
                units = EntityCategoryFilterDown(buildersCategory, units)
                local unitsAfter = table.getsize(units)

                if unitsAfter ~= unitsBefore then
                    -- Maybe spawn an UI dialog instead?
                    print((unitsBefore - unitsAfter) .. " engineers/factories could not be transferred due to manual share rules")
                end
            end
            TransferUnitsOwnership(units, data.To)
        end
    end
end

function SetResourceSharing(data)
    if not OkayToMessWithArmy(data.Army) then
        return
    end
    local brain = GetArmyBrain(data.Army)
    brain:SetResourceSharing(data.Value)
end

function RequestAlliedVictory(data)
    -- You cannot change this in a team game
    if ScenarioInfo.TeamGame then
        return
    end
    if not OkayToMessWithArmy(data.Army) then
        return
    end
    local brain = GetArmyBrain(data.Army)
    brain.RequestingAlliedVictory = data.Value
end

function SetOfferDraw(data)
    if not OkayToMessWithArmy(data.Army) then
        return
    end
    local brain = GetArmyBrain(data.Army)
    brain.OfferingDraw = data.Value
end


-- ==============================================================================
-- UNIT CAP
-- ==============================================================================
local unitcapRemainder = 0
function UpdateUnitCap(deadArmy)
    -- If we are asked to share out unit cap for the defeated army, do the following...
    local mode = ScenarioInfo.Options.ShareUnitCap
    if not mode or mode == 'none' then
        return
    end

    local totalCount = 0
    local aliveCount = 0
    local alive = {}

    for index, brain in ArmyBrains do
        if (mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) and not ArmyIsCivilian(index) then
            if not brain:IsDefeated() then
                brain.index = index
                table.insert(alive, brain)
                aliveCount = aliveCount + 1
            end
            totalCount = totalCount + 1
        end
    end

    if aliveCount > 0 then
         -- First time, this is the initial army cap, but it will update each time this function runs
        local currentCap = GetArmyUnitCap(alive[1].index)
         -- Total cap for the team/game. Uses aliveCount to take account of currentCap updating
        local totalCap = (aliveCount + 1) * currentCap + unitcapRemainder
        local newCap = math.floor(totalCap / aliveCount)
        unitcapRemainder = totalCap - aliveCount * newCap
        for _, brain in alive do
            SetArmyUnitCap(brain.index, newCap)
        end
    end
end

function SendChatToReplay(data)
    if data.Sender and data.Msg then
        if not Sync.UnitData.Chat then
            Sync.UnitData.Chat = {}
        end
        table.insert(Sync.UnitData.Chat, {sender = data.Sender, msg = data.Msg})
    end
end

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
        toBrain:GiveResource('Mass',massTaken)
        toBrain:GiveResource('Energy',energyTaken)
    end
end
