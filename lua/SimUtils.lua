-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

-- ==============================================================================
-- Diplomacy
-- ==============================================================================

local OkayToMessWithArmy = OkayToMessWithArmy
local EntityCategoryFilterDown = EntityCategoryFilterDown
local unit_methodsGetBuildRate = moho.unit_methods.GetBuildRate
local unit_methodsGetTacticalSiloAmmoCount = moho.unit_methods.GetTacticalSiloAmmoCount
local GetArmyUnitCap = GetArmyUnitCap
local IssueUpgrade = IssueUpgrade
local unit_methodsSetConsumptionPerSecondEnergy = moho.unit_methods.SetConsumptionPerSecondEnergy
local GetUnitsInRect = GetUnitsInRect
local aibrain_methodsTakeResource = moho.aibrain_methods.TakeResource
local tableInsert = table.insert
local ipairs = ipairs
local unit_methodsGetWorkProgress = moho.unit_methods.GetWorkProgress
local unit_methodsGiveTacticalSiloAmmo = moho.unit_methods.GiveTacticalSiloAmmo
local unit_methodsSetBuildRate = moho.unit_methods.SetBuildRate
local unit_methodsGetNukeSiloAmmoCount = moho.unit_methods.GetNukeSiloAmmoCount
local wreckageUp = import('/lua/wreckage.lua')
local IsAlly = IsAlly
local SetAlliance = SetAlliance
local tableSort = table.sort
local EntityCategoryContains = EntityCategoryContains
local SetArmyUnitCap = SetArmyUnitCap
local unit_methodsRevertCollisionShape = moho.unit_methods.RevertCollisionShape
local ChangeUnitArmy = ChangeUnitArmy
local ForkThread = ForkThread
local IssueBuildMobile = IssueBuildMobile
local unit_methodsSetPaused = moho.unit_methods.SetPaused
local next = next
local unit_methodsGetFocusUnit = moho.unit_methods.GetFocusUnit
local GetArmyBrain = GetArmyBrain
local tableEmpty = table.empty
local unit_methodsGiveNukeSiloAmmo = moho.unit_methods.GiveNukeSiloAmmo
local unit_methodsSetConsumptionPerSecondMass = moho.unit_methods.SetConsumptionPerSecondMass
local unit_methodsGetFuelRatio = moho.unit_methods.GetFuelRatio
local unit_methodsSetFuelRatio = moho.unit_methods.SetFuelRatio
local mathFloor = math.floor
local unit_methodsIsBeingBuilt = moho.unit_methods.IsBeingBuilt
local ArmyIsCivilian = ArmyIsCivilian
local CreateUnitHPR = CreateUnitHPR
local GetReclaimablesInRect = GetReclaimablesInRect
local aibrain_methodsGetEconomyStored = moho.aibrain_methods.GetEconomyStored
local aibrain_methodsGiveResource = moho.aibrain_methods.GiveResource
local unit_methodsGetCargo = moho.unit_methods.GetCargo

local sharedUnits = {}

function BreakAlliance(data)

    -- You cannot change alliances in a team game
    if ScenarioInfo.TeamGame then
        return
    end

    if OkayToMessWithArmy(data.From) then
        SetAlliance(data.From,data.To,"Enemy")

        if Sync.BrokenAlliances == nil then
            Sync.BrokenAlliances = {}
        end
        tableInsert(Sync.BrokenAlliances, { From = data.From, To = data.To })
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
            SetAlliance(resultData.From,resultData.To,"Ally")
            if Sync.FormedAlliances == nil then
                Sync.FormedAlliances = {}
            end
            tableInsert(Sync.FormedAlliances, { From = resultData.From, To = resultData.To })
        end
    end
    import('/lua/SimPing.lua').OnAllianceChange()
end
import('/lua/SimPlayerQuery.lua').AddResultListener("OfferAlliance", OnAllianceResult)

function KillSharedUnits(owner)
    if sharedUnits[owner] and not tableEmpty(sharedUnits[owner]) then
        for index,unit in sharedUnits[owner] do
            if not unit.Dead and unit.oldowner == owner then
                unit:Kill()
            end
        end
        sharedUnits[owner] = {}
    end
end

function TransferUnitsOwnership(units, ToArmyIndex, captured)
    local toBrain = GetArmyBrain(ToArmyIndex)
    if not toBrain or toBrain:IsDefeated() or not units or tableEmpty(units) then
        return
    end
    local fromBrain = GetArmyBrain(units[1].Army)
    local shareUpgrades

    if ScenarioInfo.Options.Share == 'FullShare' then
        shareUpgrades = true
    end

    tableSort(units, function (a, b) return a:GetBlueprint().Economy.BuildCostMass > b:GetBlueprint().Economy.BuildCostMass end)

    local newUnits = {}
    local upUnits = {}
    local pauseKennels = {}
    local upgradeKennels = {}

    for k,v in units do
        local owner = v.Army
        -- Only allow units not attached to be given. This is because units will give all of it's children over
        -- aswell, so we only want the top level units to be given.
        -- Units currently being captured is also denied
        local disallowTransfer = owner == ToArmyIndex or
                                 v:GetParent() ~= v or (v.Parent and v.Parent ~= v) or
                                 v.CaptureProgress > 0

        if disallowTransfer then
            continue
        end

        local unit = v
        local bp = unit:GetBlueprint()
        local unitId = unit.UnitId

        -- B E F O R E
        local numNukes = unit_methodsGetNukeSiloAmmoCount(unit)  -- looks like one of these 2 works for SMDs also
        local numTacMsl = unit_methodsGetTacticalSiloAmmoCount(unit)
        local massKilled = unit.Sync.totalMassKilled
        local massKilledTrue = unit.Sync.totalMassKilledTrue
        local unitHealth = unit:GetHealth()
        local shieldIsOn = false
        local ShieldHealth = 0
        local hasFuel = false
        local fuelRatio = 0
        local enh = {} -- enhancements
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
            fuelRatio = unit_methodsGetFuelRatio(unit)                             -- usage is more reliable then unit.HasFuel
            hasFuel = true                                              -- cause some buildings say they use fuel
        end
        local posblEnh = bp.Enhancements
        if posblEnh then
            for k,v in posblEnh do
                if unit:HasEnhancement(k) then
                   tableInsert(enh, k)
                end
            end
        end

        if bp.CategoriesHash.ENGINEERSTATION and bp.CategoriesHash.UEF then
            --We have to kill drones which are idling inside Kennel at the moment of transfer
            --otherwise additional dummy drone will appear after transfer
            for _,drone in unit_methodsGetCargo(unit) do
                drone:Destroy()
            end
        end

        if unit.TransferUpgradeProgress and shareUpgrades then
            local progress = unit_methodsGetWorkProgress(unit)
            local upgradeBuildTime = unit.UpgradeBuildTime

            defaultBuildRate = unit_methodsGetBuildRate(unit)

            if progress > 0.05 then --5%. EcoManager & auto-paused mexes etc.
                --What build rate do we need to reach required % in 1 tick?
                upgradeBuildRate = upgradeBuildTime * progress * 10
            end
        end

        unit.IsBeingTransferred = true

        -- changing owner
        unit = ChangeUnitArmy(unit,ToArmyIndex)
        if not unit then
            continue
        end

        tableInsert(newUnits, unit)

        unit.oldowner = oldowner

        if IsAlly(owner, ToArmyIndex) then
            if not unit.oldowner then
                unit.oldowner = owner
            end

            if not sharedUnits[unit.oldowner] then
                sharedUnits[unit.oldowner] = {}
            end
            tableInsert(sharedUnits[unit.oldowner], unit)
        end

        -- A F T E R
        if massKilled and massKilled > 0 then
            unit:CalculateVeterancyLevelAfterTransfer(massKilled, massKilledTrue)
        end
        if enh and not tableEmpty(enh) then
            for k, v in enh do
                unit:CreateEnhancement(v)
            end
        end
        if unitHealth > unit:GetMaxHealth() then
            unitHealth = unit:GetMaxHealth()
        end
        unit:SetHealth(unit,unitHealth)
        if hasFuel then
            unit_methodsSetFuelRatio(unit, fuelRatio)
        end
        if numNukes and numNukes > 0 then
            unit_methodsGiveNukeSiloAmmo(unit, (numNukes - unit_methodsGetNukeSiloAmmoCount(unit)))
        end
        if numTacMsl and numTacMsl > 0 then
            unit_methodsGiveTacticalSiloAmmo(unit, (numTacMsl - unit_methodsGetTacticalSiloAmmoCount(unit)))
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
                    --use special thread for UEF Kennels.
                    --Give them 1 tick to spawn their drones and then pause both station and drone.
                    tableInsert(pauseKennels, unit)
                else --pause cybran hives immediately
                    unit_methodsSetPaused(unit, true)
                end
            elseif bp.CategoriesHash.UEF then
                unit.UpgradesTo = upgradesTo
                unit.DefaultBuildRate = defaultBuildRate
                unit.UpgradeBuildRate = upgradeBuildRate

                tableInsert(upgradeKennels, unit)

                exclude = true
            end
        end

        if upgradeBuildRate and not exclude then
            unit.UpgradesTo = upgradesTo
            unit.DefaultBuildRate = defaultBuildRate
            unit.UpgradeBuildRate = upgradeBuildRate

            tableInsert(upUnits, unit)
        end

        unit.IsBeingTransferred = false

        v:OnGiven(unit)
    end

    if not captured then
        if upUnits[1] then
            ForkThread(UpgradeTransferredUnits, upUnits)
        end

        if pauseKennels[1] then
            ForkThread(PauseTransferredKennels, pauseKennels)
        end

        if upgradeKennels[1] then
            ForkThread(UpgradeTransferredKennels, upgradeKennels)
        end
    end

    return newUnits
end

function PauseTransferredKennels(pauseKennels)
    WaitTicks(1) -- spawn drones

    for _, unit in pauseKennels do
        unit_methodsSetPaused(unit, true)

        for _, pod in unit.PodData or {} do --pause drones
            if pod.PodHandle then
                unit_methodsSetPaused(pod.PodHandle, true)
            end
        end
    end
end

function UpgradeTransferredUnits(units)
    for _, unit in units do
        IssueUpgrade({unit}, unit.UpgradesTo)
    end

    WaitTicks(3) --mex needs at least 3 ticks after IssueUpgrade()

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit_methodsSetBuildRate(unit, unit.UpgradeBuildRate)
            unit_methodsSetConsumptionPerSecondMass(unit, 0)
            unit_methodsSetConsumptionPerSecondEnergy(unit, 0)
        end
    end

    WaitTicks(1)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit_methodsSetBuildRate(unit, unit.DefaultBuildRate)
            unit_methodsSetPaused(unit, true) --SetPaused() updates ConsumptionPerSecond values
        end
    end
end

function UpgradeTransferredKennels(upgradeKennels)
    WaitTicks(1) --spawn drones

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            for _, pod in unit.PodData or {} do --pause Kennels drones
                if pod.PodHandle then
                    unit_methodsSetPaused(pod.PodHandle, true)
                end
            end

            IssueUpgrade({unit}, unit.UpgradesTo)
        end
    end

    WaitTicks(3)

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            unit_methodsSetBuildRate(unit, unit.UpgradeBuildRate)
            unit_methodsSetConsumptionPerSecondMass(unit, 0)
            unit_methodsSetConsumptionPerSecondEnergy(unit, 0)
        end
    end

    WaitTicks(1)

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            unit_methodsSetBuildRate(unit, unit.DefaultBuildRate)
            unit_methodsSetPaused(unit, true) --SetPaused() updates ConsumptionPerSecond values
        end
    end
end

function TransferUnfinishedUnitsAfterDeath(units, armies)
    local unfinishedUnits = {}
    local noUnits = true
    local failedToTransfer = {}
    local failedToTransferCounter = 0
    local modifiedWrecks = {}
    local modifiedUnits = {}
    local createWreckIfTransferFailed = {}

    for _, unit in EntityCategoryFilterDown(categories.EXPERIMENTAL + categories.TECH3 * categories.STRUCTURE * categories.ARTILLERY, units) do
        --This transfer is pretty complex, so we do it only for really important units (EXPs and t3 arty).
        if unit_methodsIsBeingBuilt(unit) then
            unfinishedUnits[unit.EntityId] = unit
            noUnits = nil --have to store units using entityID and not table.insert
        end
    end

    if noUnits or not armies[1] then
        return
    end

    for key, army in armies do
        if key == 1 then --this is our first try and first army
            local builders = {}

            for ID, unit in unfinishedUnits do
                local bp = unit:GetBlueprint()
                local bplueprintID = bp.BlueprintId
                local buildTime = bp.Economy.BuildTime
                local health = unit:GetHealth()
                local pos = unit:GetPosition()
                local progress = unit:GetFractionComplete()

                --create invisible drone which belongs to allied army. BuildRange = 10000
                local builder = CreateUnitHPR('ZXA0001', army, 5, 20, 5, 0, 0, 0)
                tableInsert(builders, builder)

                builder.UnitHealth = health
                builder.UnitPos = pos
                builder.UnitID = ID
                builder.UnitBplueprintID = bplueprintID
                builder.BuildRate = progress * buildTime * 10 --buildRate to reach required progress in 1 tick
                builder.DefaultProgress = mathFloor(progress * 1000) --save current progress for some later checks

                --Save all important data because default unit will be destroyed during our first try
                failedToTransfer[ID] = {}
                failedToTransferCounter = failedToTransferCounter + 1
                failedToTransfer[ID].UnitHealth = health
                failedToTransfer[ID].UnitPos = pos
                failedToTransfer[ID].Bp = bp
                failedToTransfer[ID].BplueprintID = bplueprintID
                failedToTransfer[ID].BuildRate = progress * buildTime * 10
                failedToTransfer[ID].DefaultProgress = mathFloor(progress * 1000)
                failedToTransfer[ID].Orientation = unit:GetOrientation()

                -- wrecks can prevent drone from starting construction
                local wrecks = GetReclaimablesInRect(unit:GetSkirtRect()) -- returns nil instead of empty table when empty
                if wrecks then 
                    for _, reclaim in wrecks do 
                        if reclaim.IsWreckage then
                            -- collision shape to none to prevent it from blocking, keep track to revert later
                            reclaim:SetCollisionShape('None')
                            tableInsert(modifiedWrecks, reclaim)
                        end
                    end
                end

                -- units can prevent drone from starting construction
                local units = GetUnitsInRect(unit:GetSkirtRect()) -- returns nil instead of empty table when empty
                if units then 
                    for _,u in units do
                        -- collision shape to none to prevent it from blocking, keep track to revert later
                        u:SetCollisionShape('None')
                        tableInsert(modifiedUnits, u)
                    end
                end

                if progress > 0.5 then --if transfer failed, we have to create wreck manually. progress should be more than 50%
                    createWreckIfTransferFailed[ID] = true
                end

                unit:Destroy() --destroy unfinished unit

                IssueBuildMobile({builder}, pos, bplueprintID, {}) --Give command to our drone
            end

            WaitTicks(3) --Wait some ticks (3 is minimum), IssueBuildMobile() is not instant

            for _, builder in builders do
                unit_methodsSetBuildRate(builder, builder.BuildRate) --Set crazy build rate and consumption = 0
                unit_methodsSetConsumptionPerSecondMass(builder, 0)
                unit_methodsSetConsumptionPerSecondEnergy(builder, 0)
            end

            WaitTicks(1)

            for _, builder in builders do
                local newUnit = unit_methodsGetFocusUnit(builder)
                local builderProgress = mathFloor(unit_methodsGetWorkProgress(builder) * 1000)
                if newUnit and builderProgress == builder.DefaultProgress then --our drone is busy and progress == DefaultProgress. Everything is fine
                    --That's for cases when unit was damaged while being built
                    --For example: default unit had 100/10000 hp but 90% progress.
                    newUnit:SetHealth(newUnit, builder.UnitHealth)

                    failedToTransfer[builder.UnitID] = nil
                    createWreckIfTransferFailed[builder.UnitID] = nil
                    failedToTransferCounter = failedToTransferCounter - 1
                end
                builder:Destroy()
            end

        elseif failedToTransferCounter > 0 then --failed to transfer some units to first army, let's try others.
            --This is just slightly modified version of our first try, no comments here
            local builders = {}

            for ID, data in failedToTransfer do
                local bp = data.Bp
                local bplueprintID = data.BplueprintID
                local buildRate = data.BuildRate
                local health = data.UnitHealth
                local pos = data.UnitPos
                local progress = data.DefaultProgress

                local builder = CreateUnitHPR('ZXA0001', army, 5, 20, 5, 0, 0, 0)
                tableInsert(builders, builder)

                builder.UnitHealth = health
                builder.UnitPos = pos
                builder.UnitID = ID
                builder.UnitBplueprintID = bplueprintID
                builder.BuildRate = buildRate
                builder.DefaultProgress = progress

                IssueBuildMobile({builder}, pos, bplueprintID, {})
            end

            WaitTicks(3)

            for _, builder in builders do
                unit_methodsSetBuildRate(builder, builder.BuildRate)
                unit_methodsSetConsumptionPerSecondMass(builder, 0)
                unit_methodsSetConsumptionPerSecondEnergy(builder, 0)
            end

            WaitTicks(1)

            for _, builder in builders do
                local newUnit = unit_methodsGetFocusUnit(builder)
                local builderProgress = mathFloor(unit_methodsGetWorkProgress(builder) * 1000)
                if newUnit and builderProgress == builder.DefaultProgress then
                    newUnit:SetHealth(newUnit, builder.UnitHealth)

                    failedToTransfer[builder.UnitID] = nil
                    createWreckIfTransferFailed[builder.UnitID] = nil
                    failedToTransferCounter = failedToTransferCounter - 1
                end
                builder:Destroy()
            end
        end
    end

    local createWreckage = wreckageUp.CreateWreckage

    for ID,_ in createWreckIfTransferFailed do --create 50% wreck. Copied from Unit:CreateWreckageProp()
        local data = failedToTransfer[ID]
        local bp = data.Bp
        local pos = data.UnitPos
        local orientation = data.Orientation
        local mass = bp.Economy.BuildCostMass * 0.57 --0.57 to compensate some multipliers in CreateWreckage()
        local energy = 0
        local time = (bp.Wreckage.ReclaimTimeMultiplier or 1) * 2

        local wreck = createWreckage(bp, pos, orientation, mass, energy, time)
    end

    for key, wreck in modifiedWrecks do --revert wrecks collision shape. Copied from Prop.lua SetPropCollision()
        local radius = wreck.CollisionRadius
        local sizex = wreck.CollisionSizeX
        local sizey = wreck.CollisionSizeY
        local sizez = wreck.CollisionSizeZ
        local centerx = wreck.CollisionCenterX
        local centery = wreck.CollisionCenterY
        local centerz = wreck.CollisionCenterZ
        local shape = wreck.CollisionShape

        if radius and shape == 'Sphere' then
            wreck:SetCollisionShape(shape, centerx, centery, centerz, radius)
        else
            wreck:SetCollisionShape(shape, centerx, centery + sizey, centerz, sizex, sizey, sizez)
        end
    end

    for _, u in modifiedUnits do
        if not u:BeenDestroyed() then
            unit_methodsRevertCollisionShape(u)
        end
    end
end

function GiveUnitsToPlayer(data, units)
    if units then
        local owner = units[1].Army
        if OkayToMessWithArmy(owner) and IsAlly(owner,data.To) then
            TransferUnitsOwnership(units, data.To)
        end
    end
end

function SetResourceSharing(data)
    if not OkayToMessWithArmy(data.Army) then return end
    local brain = GetArmyBrain(data.Army)
    brain:SetResourceSharing(data.Value)
end

function RequestAlliedVictory(data)
    -- You cannot change this in a team game

    if ScenarioInfo.TeamGame then
        return
    end

    if not OkayToMessWithArmy(data.Army) then return end

    local brain = GetArmyBrain(data.Army)
    brain.RequestingAlliedVictory = data.Value
end

function SetOfferDraw(data)
    if not OkayToMessWithArmy(data.Army) then return end

    local brain = GetArmyBrain(data.Army)
    brain.OfferingDraw = data.Value
end


-- ==============================================================================
-- UNIT CAP
-- ==============================================================================
function UpdateUnitCap(deadArmy)
    -- If we are asked to share out unit cap for the defeated army, do the following...
    local mode = ScenarioInfo.Options.ShareUnitCap
    if not mode or mode == 'none' then return end

    local totalCount = 0
    local aliveCount = 0
    local alive = {}

    for index, brain in ArmyBrains do
        if (mode == 'all' or (mode == 'allies' and IsAlly(deadArmy, index))) and not ArmyIsCivilian(index) then
            if not brain:IsDefeated() then
                brain.index = index
                tableInsert(alive, brain)
                aliveCount = aliveCount + 1
            end
            totalCount = totalCount + 1
        end
    end

    if aliveCount > 0 then
        local currentCap = GetArmyUnitCap(alive[1].index) -- First time, this is the initial army cap, but it will update each time this function runs
        local totalCap = (aliveCount + 1) * currentCap -- Total cap for the team/game. Uses aliveCount to take account of currentCap updating
        local newCap = mathFloor(totalCap / aliveCount)
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
        tableInsert(Sync.UnitData.Chat, {sender=data.Sender, msg=data.Msg})
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
        local massTaken = aibrain_methodsTakeResource(fromBrain, 'Mass',data.Mass * aibrain_methodsGetEconomyStored(fromBrain, 'Mass'))
        local energyTaken = aibrain_methodsTakeResource(fromBrain, 'Energy',data.Energy * aibrain_methodsGetEconomyStored(fromBrain, 'Energy'))
        aibrain_methodsGiveResource(toBrain, 'Mass',massTaken)
        aibrain_methodsGiveResource(toBrain, 'Energy',energyTaken)
    end
end
