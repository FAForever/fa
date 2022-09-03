-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- General Sim scripts

---@type Team[] | false
Teams = false

-- ==============================================================================
-- Diplomacy
-- ==============================================================================

local sharedUnits = {}

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
            table.insert(Sync.FormedAlliances, { From = resultData.From, To = resultData.To })
        end
    end
    import('/lua/SimPing.lua').OnAllianceChange()
end
import('/lua/SimPlayerQuery.lua').AddResultListener("OfferAlliance", OnAllianceResult)

function KillSharedUnits(owner)
    if sharedUnits[owner] and not table.empty(sharedUnits[owner]) then
        for index,unit in sharedUnits[owner] do
            if not unit.Dead and unit.oldowner == owner then
                unit:Kill()
            end
        end
        sharedUnits[owner] = {}
    end
end

local function TransferUnitsOwnershipComparator (a, b) 
    a = a.Blueprint or a:GetBlueprint()
    b = b.Blueprint or b:GetBlueprint()
    return a.Economy.BuildCostMass > b.Economy.BuildCostMass 
end

local function TransferUnitsOwnershipDelayedWeapons (weapon)
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

function TransferUnitsOwnership(units, ToArmyIndex, captured)
    local toBrain = GetArmyBrain(ToArmyIndex)
    if not toBrain or toBrain:IsDefeated() or not units or table.empty(units) then
        return
    end
    local fromBrain = GetArmyBrain(units[1].Army)
    local shareUpgrades

    if ScenarioInfo.Options.Share == 'FullShare' then
        shareUpgrades = true
    end

    -- do not gift insignificant units
    units = EntityCategoryFilterDown(categories.ALLUNITS - categories.INSIGNIFICANTUNIT, units)

    -- gift most valuable units first
    table.sort(units, TransferUnitsOwnershipComparator)

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
                                 v.CaptureProgress > 0 or
                                 v:GetFractionComplete() < 1.0

        if disallowTransfer then
            continue
        end

        local unit = v
        local bp = unit:GetBlueprint()
        local unitId = unit.UnitId

        -- B E F O R E
        local numNukes = unit:GetNukeSiloAmmoCount()  -- looks like one of these 2 works for SMDs also
        local numTacMsl = unit:GetTacticalSiloAmmoCount()
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
            fuelRatio = unit:GetFuelRatio()                             -- usage is more reliable then unit.HasFuel
            hasFuel = true                                              -- cause some buildings say they use fuel
        end
        local posblEnh = bp.Enhancements
        if posblEnh then
            for k,v in posblEnh do
                if unit:HasEnhancement(k) then
                   table.insert(enh, k)
                end
            end
        end

        if bp.CategoriesHash.ENGINEERSTATION and bp.CategoriesHash.UEF then
            --We have to kill drones which are idling inside Kennel at the moment of transfer
            --otherwise additional dummy drone will appear after transfer
            for _,drone in unit:GetCargo() do
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
        unit = ChangeUnitArmy(unit,ToArmyIndex)
        if not unit then
            continue
        end

        table.insert(newUnits, unit)

        unit.oldowner = oldowner

        if IsAlly(owner, ToArmyIndex) then
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
        if enh and not table.empty(enh) then
            for k, v in enh do
                unit:CreateEnhancement(v)
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
                    --use special thread for UEF Kennels.
                    --Give them 1 tick to spawn their drones and then pause both station and drone.
                    table.insert(pauseKennels, unit)
                else --pause cybran hives immediately
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

            table.insert(upUnits, unit)
        end

        unit.IsBeingTransferred = false

        if v.OnGiven then 
            v:OnGiven(unit)
        end
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

    -- add delay on turning on each weapon 
    for k, unit in newUnits do 
        
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

        for _, pod in unit.PodData or {} do --pause drones
            if pod.PodHandle then
                pod.PodHandle:SetPaused(true)
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
            unit:SetBuildRate(unit.UpgradeBuildRate)
            unit:SetConsumptionPerSecondMass(0)
            unit:SetConsumptionPerSecondEnergy(0)
        end
    end

    WaitTicks(1)

    for _, unit in units do
        if not unit:BeenDestroyed() then
            unit:SetBuildRate(unit.DefaultBuildRate)
            unit:SetPaused(true) --SetPaused() updates ConsumptionPerSecond values
        end
    end
end

function UpgradeTransferredKennels(upgradeKennels)
    WaitTicks(1) --spawn drones

    for _, unit in upgradeKennels do
        if not unit:BeenDestroyed() then
            for _, pod in unit.PodData or {} do --pause Kennels drones
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
            unit:SetPaused(true) --SetPaused() updates ConsumptionPerSecond values
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
        if unit:IsBeingBuilt() then
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
                table.insert(builders, builder)

                builder.UnitHealth = health
                builder.UnitPos = pos
                builder.UnitID = ID
                builder.UnitBplueprintID = bplueprintID
                builder.BuildRate = progress * buildTime * 10 --buildRate to reach required progress in 1 tick
                builder.DefaultProgress = math.floor(progress * 1000) --save current progress for some later checks

                --Save all important data because default unit will be destroyed during our first try
                failedToTransfer[ID] = {}
                failedToTransferCounter = failedToTransferCounter + 1
                failedToTransfer[ID].UnitHealth = health
                failedToTransfer[ID].UnitPos = pos
                failedToTransfer[ID].Bp = bp
                failedToTransfer[ID].BplueprintID = bplueprintID
                failedToTransfer[ID].BuildRate = progress * buildTime * 10
                failedToTransfer[ID].DefaultProgress = math.floor(progress * 1000)
                failedToTransfer[ID].Orientation = unit:GetOrientation()

                -- wrecks can prevent drone from starting construction
                local wrecks = GetReclaimablesInRect(unit:GetSkirtRect()) -- returns nil instead of empty table when empty
                if wrecks then 
                    for _, reclaim in wrecks do 
                        if reclaim.IsWreckage then
                            -- collision shape to none to prevent it from blocking, keep track to revert later
                            reclaim:SetCollisionShape('None')
                            table.insert(modifiedWrecks, reclaim)
                        end
                    end
                end

                -- units can prevent drone from starting construction
                local units = GetUnitsInRect(unit:GetSkirtRect()) -- returns nil instead of empty table when empty
                if units then 
                    for _,u in units do
                        -- collision shape to none to prevent it from blocking, keep track to revert later
                        u:SetCollisionShape('None')
                        table.insert(modifiedUnits, u)
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
                builder:SetBuildRate(builder.BuildRate) --Set crazy build rate and consumption = 0
                builder:SetConsumptionPerSecondMass(0)
                builder:SetConsumptionPerSecondEnergy(0)
            end

            WaitTicks(1)

            for _, builder in builders do
                local newUnit = builder:GetFocusUnit()
                local builderProgress = math.floor(builder:GetWorkProgress() * 1000)
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
                table.insert(builders, builder)

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
                builder:SetBuildRate(builder.BuildRate)
                builder:SetConsumptionPerSecondMass(0)
                builder:SetConsumptionPerSecondEnergy(0)
            end

            WaitTicks(1)

            for _, builder in builders do
                local newUnit = builder:GetFocusUnit()
                local builderProgress = math.floor(builder:GetWorkProgress() * 1000)
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

    local createWreckage = import('/lua/wreckage.lua').CreateWreckage

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
            u:RevertCollisionShape()
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
                units = EntityCategoryFilterDown(categories.ALLUNITS - categories.CONSTRUCTION - categories.ENGINEER, units)
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
        table.insert(Sync.BrokenAlliances, { From = data.From, To = data.To })
    end
    import('/lua/SimPing.lua').OnAllianceChange()
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
                table.insert(alive, brain)
                aliveCount = aliveCount + 1
            end
            totalCount = totalCount + 1
        end
    end

    if aliveCount > 0 then
        local currentCap = GetArmyUnitCap(alive[1].index) -- First time, this is the initial army cap, but it will update each time this function runs
        local totalCap = (aliveCount + 1) * currentCap -- Total cap for the team/game. Uses aliveCount to take account of currentCap updating
        local newCap = math.floor(totalCap / aliveCount)
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
        table.insert(Sync.UnitData.Chat, {sender=data.Sender, msg=data.Msg})
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
        local massTaken = fromBrain:TakeResource('Mass',data.Mass * fromBrain:GetEconomyStored('Mass'))
        local energyTaken = fromBrain:TakeResource('Energy',data.Energy * fromBrain:GetEconomyStored('Energy'))
        toBrain:GiveResource('Mass',massTaken)
        toBrain:GiveResource('Energy',energyTaken)
    end
end


-- ==============================================================================
-- RECALL
-- ==============================================================================

-- ticks before a team can start the first recall vote (5 minutes)
local startingRecallStart = 5 * 60 * 10
-- ticks before a player can request another recall (3 minutes)
local playerRecallRequestCooldown = 3 * 60 * 10
-- ticks before a team can have another recall vote (1 minute)
local teamRecallVoteCooldown = 1 * 60 * 10
-- ticks that the recall request is active (30 seconds)
local recallVoteTime = 30 * 10


function RecallRequestAccepted(acceptance, teammates)
    return acceptance == teammates
end

function StartingTeamRecallCooldown()
    return GetGameTick() + startingRecallStart - teamRecallVoteCooldown
end

function RecallRequestCooldown(lastTeamVote, lastPlayerRequest)
    local gametime = GetGameTick()
    return math.max(
        lastPlayerRequest + playerRecallRequestCooldown - gametime,
        lastTeamVote + teamRecallVoteCooldown - gametime,
        0
    )
end

--- Returns the recall request cooldown for an army
---@param army Army
---@return number
function ArmyRecallRequestCooldown(army)
    local brain = GetArmyBrain(army)
    if ScenarioInfo.RecallDisabled then
        local lastPlayerRequest = brain.LastRecallRequestTime
        local lastTeamVote
        if ScenarioInfo.TeamGame then
            -- if it's a team game, it's pretty simple: we need consider only the last time the
            -- player's team voted
            lastTeamVote = Teams[brain.Team].LastRecallVoteTime
        else
            -- however, if teams are unlocked, it's a little more complicated: since each player is
            -- on their own team, each ally's team needs to be considered as well
            army = brain.Army
            lastTeamVote = lastPlayerRequest
            for index, ally in ArmyBrains do
                if not ally:IsDefeated() and IsAlly(army, index) then
                    local allyTeamVote = Teams[ally.Team].LastRecallVoteTime
                    if allyTeamVote < lastTeamVote then
                        lastTeamVote = allyTeamVote
                    end
                end
            end
        end
        return RecallRequestCooldown(lastTeamVote, lastPlayerRequest)
    end
    return 36000
end

local recallVotingThread
function RecallVotingThread(requestingArmy)
    WaitTicks(recallVoteTime + 1)
    local recallAcceptance = 0
    local team = {}
    local teammates = 0
    for _, brain in ArmyBrains do
        if not brain:IsDestroyed() and IsAlly(requestingArmy, brain.Army) then
            teammates = teammates + 1
            team[teammates] = brain
            if brain.RecallVote then
                recallAcceptance = recallAcceptance + 1
            end
            brain.RecallVote = nil
        end
    end
    local recallAccepted = RecallRequestAccepted(recallAcceptance, teammates)
    Sync.RecallRequest = {
        Close = recallAccepted,
    }
    if recallAccepted then
        for _, brain in team do
            brain:RecallAllCommanders()
        end
    else
        local gametick = GetGameTick()
        local brain = GetArmyBrain(requestingArmy)
        brain.LastRecallRequestTime = gametick
        team = Teams[brain.Team]
        team.RecallVoting = false
        team.LastRecallVoteTime = gametick
        -- update UI once the cooldown dissipates
        local army = GetFocusArmy()
        local cooldown = ArmyRecallRequestCooldown(army)
        repeat
            WaitTicks(math.max(playerRecallRequestCooldown, teamRecallVoteCooldown) + 1)
            cooldown = ArmyRecallRequestCooldown(army)
        until cooldown <= 0
        Sync.RecallRequest = {
            CanRequest = true,
        }
    end
    recallVotingThread = nil
end

function ArmyVoteRecall(army, vote, lastVote)
    local recallSync = Sync.RecallRequest
    if not recallSync then
        recallSync = {}
        Sync.RecallRequest = recallSync
    end
    if vote then
        local accept = recallSync.Accept or 0
        recallSync.Accept = accept + 1
    else
        local veto = recallSync.Veto or 0
        recallSync.Veto = veto + 1
    end
    if army == GetFocusArmy() then
        recallSync.CanRequest = false
    end
    if lastVote and recallVotingThread then
        coroutine.resume(recallVotingThread)
    end
end

function ArmyRequestRecall(army, lastVote)
    ArmyVoteRecall(army, true, lastVote)
    if not lastVote then
        local recallSync = Sync.RecallRequest
        recallSync.Open = recallVoteTime * 0.1
        recallSync.CanVote = army ~= GetFocusArmy()
        recallVotingThread = ForkThread(RecallVotingThread, army)
    end
end

function SetRecallVote(data)
    local army = data.From
    --if not OkayToMessWithArmy(army) then return end
    local brain = GetArmyBrain(army)
    local vote = data.Vote

    local team = Teams[brain.Team]
    local isRequest = false
    local lastVote = true
    if ScenarioInfo.TeamGame then
        for index, ally in ArmyBrains do
            if not ally:IsDefeated() and IsAlly(army, index) then
                -- AI teams can't recall
                if not ally.Human then
                    return
                end
                if army ~= index then
                    lastVote = lastVote and ally.RecallVote ~= nil
                end
            end
        end
        isRequest = team.RecallVoting
    else
        -- search through for allies
        for index, ally in ArmyBrains do
            if not ally:IsDefeated() and IsAlly(army, index) then
                if not ally.Human then
                    return
                end
                if army ~= index then
                    lastVote = lastVote and ally.RecallVote ~= nil
                end
                isRequest = isRequest or Teams[ally.Team].RecallVoting
            end
        end
    end

    brain.RecallVote = vote
    if isRequest then
        local cooldown = ArmyRecallRequestCooldown(army)
        if cooldown >= 0 then return end
        -- the player is making a recall request; this will reset their recall request cooldown
        team.RecallVoting = true
        ArmyRequestRecall(army, lastVote)
    else
        -- the player is responding to a recall request; we don't count this against their
        -- individual recall request cooldown
        ArmyVoteRecall(army, vote, lastVote)
    end
end
