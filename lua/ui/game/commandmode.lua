--*****************************************************************************
--* File: lua/modules/ui/game/commandmode.lua
--* Author: Chris Blackwell
--* Summary: Manages the current command mode, which determines what action
--* the mouse will take when next clicked in the world
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local commandMeshResources = import("/lua/ui/game/commandmeshes.lua").commandMeshResources
local Prefs = import("/lua/user/prefs.lua")

local watchForQueueChange = import("/lua/ui/game/construction.lua").watchForQueueChange
local checkBadClean = import("/lua/ui/game/construction.lua").checkBadClean
local EnhancementQueueFile = import("/lua/ui/notify/enhancementqueue.lua")

local GameMain = import("/lua/ui/game/gamemain.lua")
local RadialDragger = import("/lua/ui/controls/draggers/radial.lua").RadialDragger

-- upvalue globals for performance
local IsKeyDown = IsKeyDown
local GetUnitById = GetUnitById
local IsDestroyed = IsDestroyed
local SimCallback = SimCallback
local EntityCategoryContains = EntityCategoryContains
local EntityCategoryFilterDown = EntityCategoryFilterDown
local AddCommandFeedbackBlip = AddCommandFeedbackBlip

-- upvalue table operations for performance
local TableInsert = table.insert
local TableEmpty = table.empty
local TableGetN = table.getn
local MathPi = math.pi
local MathAtan = math.atan

---@alias UserCommandType
--- | 'None' # by-product of other commands
--- | 'Stop'
--- | 'Reclaim'
--- | 'Move'
--- | 'Attack'
--- | 'Guard'
--- | 'AggressiveMove'
--- | 'Upgrade'
--- | 'Build'
--- | 'BuildMobile'
--- | 'Tactical'
--- | 'Nuke'
--- | 'TransportReverseLoadUnits' # when you select a transport and right click a unit
--- | 'TransportLoadUnits' # when you select a unit and right click a transport
--- | 'TransportUnloadUnits'
--- | 'TransportUnloadSpecificUnits' # when you click to unload specific units
--- | 'Ferry'
--- | 'AssistMove' # by-product of other commands
--- | 'Script' # as an example: enhancements
--- | 'Capture'
--- | 'FormMove'
--- | 'FormAggressiveMove'
--- | 'OverCharge'
--- | 'FormAttack'
--- | 'Teleport'
--- | 'Patrol'
--- | 'FormPatrol'
--- | 'Sacrifice'
--- | 'Pause'
--- | 'Dock'
--- | 'DetachFromTransport'
--- | 'Repair'

---@class UserCommand
---@field Blueprint UnitId
---@field Clear boolean
---@field CommandType UserCommandType
---@field LuaParams table
---@field Target UserCommandTarget
---@field Units UserUnit[]
---@field SkipBlip? boolean # if we don't have a feedback blip defined, skips the default command blip

---@class UserCommandTarget
---@field EntityId? EntityId
---@field Position Vector
---@field Type 'Position' | 'Entity' | 'None'

---@class MeshInfo
---@field Position Vector
---@field Blueprint string
---@field TextureName string
---@field ShaderName string
---@field UniformScale number

-- When this file is reloaded (using /EnableDiskWatch) the cursor no longer changes
-- during command mode (e.g., when you do a move order it turns your cursor into
-- the blue move marker). This is fixed by reloading the game.

---@alias CommandMode
---| 'order' 
---| 'build' 
---| 'buildanchored' 
---| 'ping' # Does not issue commands or get canceled by right click. Basically passes data from `StartCommandMode` to `EndCommandMode`.
---| false

---@class CommandModeDataBase
---@field cursor? CommandCap        # Similar to the field 'name'
---@field altCursor? string          # Allows for an alternative cursor

---@class CommandModeDataOrder : CommandModeDataBase
---@field name CommandCap
---@field consistent boolean    # Allows command mode to remain after you issue a command, without queueing the commands

---@class CommandModeDataBuild : CommandModeDataBase
---@field name string # blueprint id of the unit being built

--- Like 'build' mode but can only place structures within `MaxBuildDistance` of all selected units.
--- Shows the distance as a range ring which jitters while the unit moves due to not using interpolated position.
--- This distance does not represent the actual maximum build range (which adds builder footprint and target skirt).
--- Not recommended for use.
---@class CommandModeDataBuildAnchored : CommandModeDataBase
---@field name string # blueprint id of the unit being built

---@class CommandModeDataOrderScript : CommandModeDataOrder
---@field TaskName string

---@alias CommandModeData CommandModeDataOrder | CommandModeDataOrderScript | CommandModeDataBuild | CommandModeDataBuildAnchored | false

---@type CommandMode
local cachedCommandMode = false

---@type CommandMode
local commandMode = false

---@type CommandModeData
local modeData = false

---@type CommandModeData
local cachedModeData = false

--- Auto-disable command mode right after one command - used when shift is not pressed down.
local issuedOneCommand = false
local startBehaviors = {}
local endBehaviors = {}

--- Callback triggers when command mode starts
---@param behavior fun(mode?: CommandMode, data?: CommandModeData)
---@param identifier? string
function AddStartBehavior(behavior, identifier)
    if identifier then
        if startBehaviors[identifier] then
            WARN("Overwriting command mode start behavior: " .. identifier)
        end
        startBehaviors[identifier] = behavior
    else
        TableInsert(startBehaviors, behavior)
    end
end

--- Callback triggers when command mode ends
---@param behavior fun(mode?: CommandMode, data?: CommandModeData)
---@param identifier? string
function AddEndBehavior(behavior, identifier)
    if identifier then
        if endBehaviors[identifier] then
            WARN("Overwriting command mode end behavior: " .. identifier)
        end
        endBehaviors[identifier] = behavior
    else
        TableInsert(endBehaviors, behavior)
    end
end

--- usually changing selection ends the command mode, this allows us to ignore that
local ignoreSelection = false
function SetIgnoreSelection(ignore)
    ignoreSelection = ignore
end

--- Called when the command mode starts and initialises all the data.
---@param newCommandMode CommandMode
---@param data CommandModeData
function StartCommandMode(newCommandMode, data)
    -- clean up previous command mode
    if commandMode then
        EndCommandMode(true)
    end

    -- update our local state
    commandMode = newCommandMode
    modeData = data

    -- do start behaviors
    for i, v in startBehaviors do
        v(commandMode, modeData)
    end
end

--- Called when the command mode ends and deconstructs all the data.
---@param isCancel boolean # set when we're at the end of (a sequence of) order(s), is usually always true. False when the mode is ended with right click, except for "ping" mode.
function EndCommandMode(isCancel)
    if ignoreSelection then
        return
    end

    -- in case we want to end the command mode, without knowing it has already ended or not
    if modeData then
        -- add information to modeData for end behavior
        modeData.isCancel = isCancel or false

        -- ???
        if modeData.isCancel then
            ClearBuildTemplates()
        end

        -- regain selection if we were cheating in units
        if modeData.cheat and modeData.selection then
            SelectUnits(modeData.selection)
        end
    end

    -- do end behaviors
    for i, v in endBehaviors do
        v(commandMode, modeData)
    end

    -- update our local state
    commandMode = false
    modeData = false
    issuedOneCommand = false
end

--- Caches the command mode, allows us to restore it
function CacheCommandMode()
    cachedCommandMode = commandMode
    cachedModeData = modeData
end

function CacheAndClearCommandMode()
    CacheCommandMode()
    commandMode = false
    modeData = false
end

--- Restores the cached command mode
---@param ignorePreviousCommands? boolean when set resets the command mode as if no commands were issued
function RestoreCommandMode(ignorePreviousCommands)
    if cachedCommandMode and cachedModeData then
        if ignorePreviousCommands then
            issuedOneCommand = false
        end
        StartCommandMode(cachedCommandMode, cachedModeData)
    end
end

-- allocate the table once for performance
local commandModeTable = {}

--- Retrieves the current command mode information.
---@return { [1]: CommandModeDataOrder, [2]: CommandModeData }
function GetCommandMode()
    commandModeTable[1] = commandMode
    commandModeTable[2] = modeData
    return commandModeTable
end

--- Returns true if we are in command mode
---@return boolean
function InCommandMode()
    return commandMode ~= false
end

---Helper function for a default feedback blip animation
---@param pos Vector Position of the feedback animation
function AddDefaultCommandFeedbackBlips(pos)
    AddCommandFeedbackBlip(
        {
            Position = pos,
            MeshName = '/meshes/game/flag02d_lod0.scm',
            TextureName = '/meshes/game/flag02d_albedo.dds',
            ShaderName = 'CommandFeedback',
            UniformScale = 0.5,
        },
        0.7
    )

    AddCommandFeedbackBlip(
        {
            Position = pos,
            MeshName = '/meshes/game/crosshair02d_lod0.scm',
            TextureName = '/meshes/game/crosshair02d_albedo.dds',
            ShaderName = 'CommandFeedback2',
            UniformScale = 0.5,
        },
        0.75
    )
end

---Helper function for a feedback blip animation based on the command type
---@param command UserCommand
function AddCommandFeedbackByType(command)
    local meshResource = commandMeshResources[command.CommandType]
    if meshResource then
        AddCommandFeedbackBlip(
            {
                Position = command.Target.Position,
                MeshName = meshResource[1],
                TextureName = meshResource[2],
                ShaderName = 'CommandFeedback',
                UniformScale = 0.125,
            },
            0.7
        )
    elseif not command.SkipBlip then
        AddDefaultCommandFeedbackBlips(command.Target.Position)
    end
end

--- Creates a callback to spawn a unit triggered by the cheat menu.
-- @param command Command that contains the position of the click
-- @param data A shallow copy of the modeData to make the function pure data-wise
local function CheatSpawn(command, data)
    SimCallback({
        Func = data.prop and 'CheatBoxSpawnProp' or 'CheatSpawnUnit',
        Args = {
            army = data.army,
            pos = command.Target.Position,
            bpId = data.unit or data.prop or command.Blueprint,
            count = data.count,
            yaw = data.yaw,
            rand = data.rand,
            veterancy = data.vet,
            CreateTarmac = data.CreateTarmac,
            MeshOnly = data.MeshOnly,
            ShowRaisedPlatforms = data.ShowRaisedPlatforms,
            UnitIconCameraMode = data.UnitIconCameraMode,
        }
    }, true)
end

-- cached category strings for performance
local categoriesFactories = categories.STRUCTURE * categories.FACTORY
local categoriesShields = categories.MOBILE * categories.SHIELD
local categoriesStructure = categories.STRUCTURE

---@param unit UserUnit
local function UpgradeUnit(unit)
    -- do not upgrade units that are already upgrading
    if unit:GetFocus() then
        return
    end

    ---@type UserUnit[]
    local units = { unit }

    -- paused units do not start upgrades
    if GetIsPaused(units) then
        SetPaused(units, false)
        WaitTicks(5)
    end

    -- check if unit still exists
    if IsDestroyed(unit) then
        return
    end

    -- verify build restrictions ui-side so sim doesn't log a warning
    local availableOrders, availableToggles, buildableCategories = GetUnitCommandDataOfUnit(unit)
    local unitUpgrade = unit:GetBlueprint().General.UpgradesTo
    if not unitUpgrade or not EntityCategoryContains(buildableCategories, unitUpgrade) then
        return
    end

    -- issue the upgrade
    IssueBlueprintCommandToUnit(
        unit, "UNITCOMMAND_Upgrade",
        unitUpgrade,
        1, true
    )

    -- inform the user
    print("Upgrade unit")

    -- wait one tick for the upgrade to start
    WaitTicks(5)

    if IsDestroyed(unit) then
        return
    end

    -- pause the unit (again)
    SetPaused(units, true)
end

---@param guardees UserUnit[]
---@param unit UserUnit
local function OnGuardUpgrade(guardees, unit)
    local unitBlueprint = unit:GetBlueprint()

    -- check for radars
    local upgradeRadar = Prefs.GetFieldFromCurrentProfile('options').assist_to_upgrade_radar
    local upgradeRadarTech1 = upgradeRadar == 'Tech1Radars' or upgradeRadar == 'Tech1Tech2Radars'
    local upgradeRadarTech2 = upgradeRadar == 'Tech1Tech2Radars'
    if upgradeRadarTech1 and
        EntityCategoryContains(categories.STRUCTURE * categories.RADAR * categories.TECH1, unit)
    then
        ForkThread(UpgradeUnit, unit)
        return
    end

    if upgradeRadarTech2 and
        EntityCategoryContains(categories.STRUCTURE * categories.RADAR * categories.TECH2, unit) and
        unitBlueprint.Economy.ConsumptionPerSecondEnergy > unit:GetEconData().energyConsumed -- check for any adjacency
    then
        ForkThread(UpgradeUnit, unit)
        return
    end

    -- check for mass extractors
    local upgradeExtractor = Prefs.GetFieldFromCurrentProfile('options').assist_to_upgrade
    local upgradeExtractorTech1 = upgradeExtractor == 'Tech1Extractors' or upgradeExtractor == 'Tech1Tech2Extractors'
    local upgradeExtractorTech2 = upgradeExtractor == 'Tech1Tech2Extractors'
    if upgradeExtractorTech1 and
        EntityCategoryContains(categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH1, unit)
    then
        ForkThread(UpgradeUnit, unit)
        return
    end

    if upgradeExtractorTech2 and
        EntityCategoryContains(categories.STRUCTURE * categories.MASSEXTRACTION * categories.TECH2, unit) and
        unitBlueprint.Economy.ProductionPerSecondMass < unit:GetEconData().massProduced -- check for any adjacency
    then
        ForkThread(UpgradeUnit, unit)
        return
    end
end

--- Thread to keep track of when to unpause, 
--- logic is a bit convoluted but guarantees that we still have access to the user units as the game progresses
---@param targetId EntityId
local function UnpauseThread(targetId)
    WaitTicks(10)
    local target = GetUnitById(targetId)
    while target do
        local candidates = target.ThreadUnpauseCandidates
        if (candidates and not table.empty(candidates)) then
            for id, _ in candidates do
                local engineer = GetUnitById(id)
                -- check if it is idle instead of its guarded entity to allow queuing orders before the assist command
                if engineer and not engineer:IsIdle() then
                    -- ensure the target focus exists, since this thread may be targeted at something that is not building anything,
                    -- but might start to build something after some network delay, which you won't want to unpause due to `nil == nil`
                    local targetFocus = target:GetFocus()
                    if targetFocus and targetFocus == engineer:GetFocus() then
                        target.ThreadUnpauseCandidates = nil
                        target.ThreadUnpause = nil
                        SetPaused({ target }, false)
                        return
                    end
                else
                    -- engineer is idle, died, we switch armies, ...
                    candidates[id] = nil
                end
            end
        else
            target.ThreadUnpauseCandidates = nil
            target.ThreadUnpause = nil
            return
        end

        WaitTicks(10)
        target = GetUnitById(targetId)
    end
end

---@param guardees UserUnit[]
---@param target UserUnit
local function OnGuardUnpause(guardees, target)
    local prefs = Prefs.GetFieldFromCurrentProfile('options').assist_to_unpause
    local bp = __blueprints[target:GetUnitId()]
    -- only create the unpause thread for units that have the ability to unpause
    if  (
            prefs == 'On' and 
            (
                EntityCategoryContains(categories.REPAIR + categories.FACTORY + categories.SILO, target)  -- REPAIR includes mantis and harbs, compared to ENGINEER category
                or (bp.General.UpgradesTo and bp.General.UpgradesTo ~= '') -- upgradeables can also be assisted
            )
        )
        or
        (   
            prefs == 'ExtractorsAndRadars'
            and EntityCategoryContains((categories.MASSEXTRACTION + categories.RADAR) * categories.STRUCTURE, target) 
            and (bp.General.UpgradesTo and bp.General.UpgradesTo ~= '') -- use `and` to make sure the mex/radar is upgradeable
        )
    then
        -- save the guardees' entity ids to keep track of in the unpause thread
        target.ThreadUnpauseCandidates = target.ThreadUnpauseCandidates or {}
        for k, guardee in guardees do
            target.ThreadUnpauseCandidates[guardee:GetEntityId()] = true
        end

        -- start a single thread to keep track of when to unpause
        if not target.ThreadUnpause then
            target.ThreadUnpause = ForkThread(UnpauseThread, target:GetEntityId())
        end
    end
end

---@param guardees UserUnit[]
---@param unit UserUnit
local function OnGuardCopy(guardees, unit)
    local prefs = Prefs.GetFieldFromCurrentProfile('options').assist_to_copy_command_queue
    local engineers = EntityCategoryFilterDown(categories.ENGINEER, guardees)
    if table.getn(engineers) > 0 and
        (prefs == 'OnlyEngineers' or prefs == 'OnlyEngineersAddToSelection') and
        EntityCategoryContains(categories.ENGINEER, unit)
    then
        if IsKeyDown('Control') then
            SimCallback({ Func = 'CopyOrders', Args = { Target = unit:GetEntityId(), ClearCommands = true } }, true)

            if prefs == 'OnlyEngineersAddToSelection' then
                AddSelectUnits({ unit })
            end
        end
    end
end

---@param command UserCommand
local function OnGuardIssued(command)
    if command.Target.EntityId then
        local unit = GetUnitById(command.Target.EntityId) ---@cast unit UserUnit
        local guards = command.Units
        if unit:GetArmy() == GetFocusArmy() then
            OnGuardUpgrade(guards, unit)
            OnGuardUnpause(guards, unit)
            OnGuardCopy(guards, unit)
        end

        -- Detect and fix a simulation freeze by clearing the command queue of all factories that take part in a cycle
        if EntityCategoryContains(categoriesFactories, command.Blueprint) then
            local factories = EntityCategoryFilterDown(categoriesFactories, command.Units) or {}
            if factories[1] then
                local cb = { Func = 'ValidateAssist', Args = { target = command.Target.EntityId } }
                SimCallback(cb, true)
            end
        end

        -- validate shields
        if EntityCategoryFilterDown(categoriesShields, command.Units)[1] then
            local cb = { Func = 'FlagShield', Args = { target = command.Target.EntityId } }
            SimCallback(cb, true)
        end

        -- see if we can cap a structure
        if EntityCategoryContains(categoriesStructure, command.Blueprint) then

            local target = GetUnitById(command.Target.EntityId) --[[@as UserUnit]]
            local units = command.Units --[[@as (UserUnit[])]]
            import("/lua/ui/game/hotkeys/capping.lua").AssistToCap(target, units)
        end
    end
end

---@param command UserCommand
local function OnBuildMobileIssued(command)
    if not command.Units[1] then
        if modeData.callback then -- unusual command, where we use the build interface
            modeData.callback(modeData, command)
            return true
        elseif modeData.cheat then -- part of the cheat menu
            CheatSpawn(command, modeData)
            command.Units = {}
            return true
        end
    end
    -- We want our command feedback blip to match the blueprint, and we want to skip the default
    command.SkipBlip = true
    AddCommandFeedbackBlip(
        {
            Position = command.Target.Position,
            BlueprintID = command.Blueprint,
            TextureName = '/meshes/game/flag02d_albedo.dds',
            ShaderName = 'CommandFeedback',
            UniformScale = 1,
        },
        0.7
    )
end

---@param command UserCommand
local function OnReclaimIssued(command)
    -- feature: area commands
    -- -- Area reclaim dragger, command mode only
    -- if command.Target.EntityId and modeData.name == "RULEUCC_Reclaim" then
    --     import("/lua/ui/game/hotkeys/area-reclaim-order.lua").AreaReclaimOrder(command)
    -- end
end

---@param command UserCommand
local function OnRepairIssued(command)
    -- see if we can rebuild a structure
    if command.Target.Type == 'Entity' then -- repair wreck to rebuild
        local cb = { Func = "Rebuild", Args = { entity = command.Target.EntityId, Clear = command.Clear } }
        SimCallback(cb, true)
    end
end

---@param command UserCommand
local function OnAttackIssued(command)
    -- feature: area commands
    -- Area attack dragger, command mode only
    if command.Target.Type == 'Position' and modeData.name == "RULEUCC_Attack" then
        import("/lua/ui/game/hotkeys/area-attack-order.lua").AreaAttackOrder(command)
    end
end

---@param command UserCommand
local function OnUpgradeIssued(command)
    -- if we're trying to upgrade hives then this allows us to force the upgrade to happen immediately
    if (command.Blueprint == "xrb0204" or command.Blueprint == "xrb0304") then
        if not IsKeyDown('Shift') then
            SimCallback({ Func = 'ImmediateHiveUpgrade', Args = { UpgradeTo = command.Blueprint } }, true)
        end
    end
end

---@param command UserCommand
local function OnScriptIssued(command)
    if command.LuaParams then
        if command.LuaParams.TaskName == 'AttackMove' then
            ---@type SimCallback
            local cb = { Func = "AttackMove", Args = { Clear = command.Clear } }
            SimCallback(cb, true)
        elseif command.LuaParams.Enhancement then
            EnhancementQueueFile.enqueueEnhancement(command.Units, command.LuaParams.Enhancement)
        end
    end
end

---@param command UserCommand
local function OnStopIssued(command)
    EnhancementQueueFile.clearEnhancements(command.Units)
end

-- Callbacks for different command types, nil values for reference to functions that don't exist yet
local OnCommandIssuedCallback = {
    None = nil,
    Stop = OnStopIssued,
    Reclaim = OnReclaimIssued,
    Move = nil,
    Attack = OnAttackIssued,
    Guard = OnGuardIssued,
    AggressiveMove = nil,
    Upgrade = OnUpgradeIssued,
    Build = nil,
    BuildMobile = OnBuildMobileIssued,
    Tactical = nil,
    Nuke = nil,
    TransportReverseLoadUnits = nil,
    TransportLoadUnits = nil,
    TransportUnloadUnits = nil,
    TransportUnloadSpecificUnits = nil,
    Ferry = nil,
    AssistMove = nil,
    Script = OnScriptIssued,
    Capture = nil,
    FormMove = nil,
    FormAggressiveMove = nil,
    OverCharge = nil,
    FormAttack = nil,
    Teleport = nil,
    Patrol = nil,
    FormPatrol = nil,
    Sacrifice = nil,
    Pause = nil,
    Dock = nil,
    DetachFromTransport = nil,
    Repair = OnRepairIssued,
}

--- Called by the engine when a new command has been issued by the player.
-- @param command Information surrounding the command that has been issued, such as its CommandType or its Target.
---@param command UserCommand
function OnCommandIssued(command)
    -- not command.Clear = when we hold shift, to queue up multiple commands.
    if not command.Clear then
        -- signal for OnCommandModeBeat to end commandMode at the next beat
        -- potentially removable? dont see the effect
        issuedOneCommand = true
    end

    -- If our callback returns true or we don't have a command type, we skip the rest of our logic
    if (OnCommandIssuedCallback[command.CommandType] and OnCommandIssuedCallback[command.CommandType](command))
    or command.CommandType == 'None' then
        -- we do still need to end the commandmode for things like HotBuild.
        if command.Clear then
            -- but only when not using the cheat menu, which should stay open.
            if modeData and not modeData.cheat or not modeData then
                EndCommandMode(true)
            end
        end
        return
    end
    
    if command.Clear then
        EndCommandMode(true)
        if command.CommandType ~= 'Stop'
        and TableGetN(command.Units) == 1
        and checkBadClean(command.Units[1]) then
            watchForQueueChange(command.Units[1])
        end
    end

    AddCommandFeedbackByType(command)
end

--- ???
--- Ensures the command mode ends when one one command should be passed through?
function OnCommandModeBeat()
    if issuedOneCommand and not IsKeyDown('Shift')
    then
        EndCommandMode(true)
    end
end

GameMain.AddBeatFunction(OnCommandModeBeat)

-- kept for mod backwards compatibility
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Construction = import("/lua/ui/game/construction.lua")
local UIMain = import("/lua/ui/uimain.lua")
local Orders = import("/lua/ui/game/orders.lua")