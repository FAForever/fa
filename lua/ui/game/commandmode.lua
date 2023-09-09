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

local WorldView = import("/lua/ui/controls/worldview.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")

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

---@class UserCommand


---@class MeshInfo
---@field Position Vector
---@field Blueprint string
---@field TextureName string
---@field ShaderName string
---@field UniformScale number

-- When this file is reloaded (using /EnableDiskWatch) the cursor no longer changes
-- during command mode (e.g., when you do a move order it turns your cursor into
-- the blue move marker). This is fixed by reloading the game.

---@alias CommandMode 'order' | 'build' | 'buildanchored' | false

---@class CommandModeDataBase
---@field cursor? CommandCap        # Similar to the field 'name'
---@field altCursor string          # Allows for an alternative cursor

---@class CommandModeDataOrder : CommandModeDataBase
---@field name CommandCap
---@field consistent boolean    # Allows command mode to remain after you issue a command, without queueing the commands

---@class CommandModeDataBuild : CommandModeDataBase
---@field name string # blueprint id of the unit being built

---@class CommandModeDataBuildAnchored : CommandModeDataBase

---@alias CommandModeData CommandModeDataOrder | CommandModeDataBuild | CommandModeDataBuildAnchored | false

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
---@param isCancel boolean set when we're at the end of (a sequence of) order(s), is usually always true
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

--- A helper function to add the correct feedback animation.
-- @param pos The position of the feedback animation.
-- @param type The type of feedback animation.
function AddCommandFeedbackByType(pos, type)
    if commandMeshResources[type] == nil then
        return false;
    else
        AddCommandFeedbackBlip(
            {
                Position = pos,
                MeshName = commandMeshResources[type][1],
                TextureName = commandMeshResources[type][2],
                ShaderName = 'CommandFeedback',
                UniformScale = 0.125,
            },
            0.7
        )
    end

    return true;
end

--- A helper function for a specific feedback animation.
-- @param pos The position of the feedback animation.
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
            UnitIconCameraMode = data.UnitIconCameraMode,
        }
    }, true)
end

-- cached category strings for performance
local categoriesFactories = categories.STRUCTURE * categories.FACTORY
local categoriesShields = categories.MOBILE * categories.SHIELD
local categoriesStructure = categories.STRUCTURE

--- Upgrades a tech 1 extractor that is being assisted
---@param unit UserUnit
local function OnGuardUpgrade(guardees, unit)
    if EntityCategoryContains(categories.MASSEXTRACTION * categories.TECH1, unit) and
        Prefs.GetFromCurrentProfile('options.assist_to_upgrade') == 'Tech1Extractors'
    then
        ForkThread(
            function()
                ---@type UserUnit
                local units = { unit }
                if not IsDestroyed(unit) and not unit:GetFocus() then
                    import("/lua/ui/game/selection.lua").Hidden(
                        function()
                            SelectUnits(units)
                            IssueBlueprintCommand("UNITCOMMAND_Upgrade", unit:GetBlueprint().General.UpgradesTo, 1, true)
                        end
                    )

                    WaitSeconds(0.5)

                    SetPaused(units, true)
                end
            end
        )
    end
end

--- Unpauses a
---@param guardees UserUnit[]
---@param target UserUnit
local function OnGuardUnpause(guardees, target)
    local prefs = Prefs.GetFromCurrentProfile('options.assist_to_unpause')
    if prefs == 'On' or
        (
        prefs == 'ExtractorsAndRadars' and
            EntityCategoryContains((categories.MASSEXTRACTION + categories.RADAR) * categories.STRUCTURE, target))
    then

        -- start a single thread to keep track of when to unpause, logic feels a bit convoluted
        -- but that is purely to guarantee that we still have access to the user units as the
        -- game progresses
        if not target.ThreadUnpause then
            local id = target:GetEntityId()
            target.ThreadUnpause = ForkThread(
                function()
                    WaitSeconds(1.0)
                    local target = GetUnitById(id)
                    while target do
                        local candidates = target.ThreadUnpauseCandidates
                        if (candidates and not table.empty(candidates)) then
                            for id, _ in candidates do
                                local engineer = GetUnitById(id)
                                if engineer and not engineer:IsIdle() then
                                    local focus = engineer:GetFocus()
                                    if focus == target:GetFocus() then
                                        target.ThreadUnpauseCandidates = nil
                                        target.ThreadUnpause = nil
                                        SetPaused({ target }, false)
                                        break
                                    end
                                    -- engineer is idle, died, we switch armies, ...
                                else
                                    candidates[id] = nil
                                end
                            end
                        else
                            target.ThreadUnpauseCandidates = nil
                            target.ThreadUnpause = nil
                            break
                            ;end

                        WaitSeconds(1.0)
                        target = GetUnitById(id)
                    end
                end
            )
        end

        -- add these to keep track
        target.ThreadUnpauseCandidates = target.ThreadUnpauseCandidates or {}
        for k, guardee in guardees do
            target.ThreadUnpauseCandidates[guardee:GetEntityId()] = true
        end
    end
end

--- Is called when a unit receies a guard / assist order
---@param guardees UserUnit[]
---@param unit UserUnit
local function OnGuard(guardees, unit)
    if unit:GetArmy() == GetFocusArmy() then
        OnGuardUpgrade(guardees, unit)
        OnGuardUnpause(guardees, unit)
    end
end

--- Called by the engine when a new command has been issued by the player.
-- @param command Information surrounding the command that has been issued, such as its CommandType or its Target.
---@param command UserCommand
---@return boolean
function OnCommandIssued(command)

    -- if we're trying to upgrade hives then this allows us to force the upgrade to happen immediately
    if command.CommandType == "Upgrade" and (command.Blueprint == "xrb0204" or command.Blueprint == "xrb0304") then
        if not IsKeyDown('Shift') then
            SimCallback({ Func = 'ImmediateHiveUpgrade', Args = { UpgradeTo = command.Blueprint } }, true)
        end
    end

    -- unusual command, where we use the build interface
    if modeData.callback and command.CommandType == "BuildMobile" and (not command.Units[1]) then
        modeData.callback(modeData, command)
        return false
    end

    -- part of the cheat menu
    if modeData.cheat and command.CommandType == "BuildMobile" and (not command.Units[1]) then
        CheatSpawn(command, modeData)
        command.Units = {}
        return false
    end

    -- is set when we hold shift, to queue up multiple commands. This is where the command mode stops
    if not command.Clear then
        issuedOneCommand = true
    else
        EndCommandMode(true)
    end

    -- called when:
    -- - a factory-like construction that is not finished is being continued
    -- - a (finished) unit is being guarded (right clicked)
    if command.CommandType == 'Guard' and command.Target.EntityId then

        local unit = GetUnitById(command.Target.EntityId)
        OnGuard(command.Units, unit)

        -- validate factories assisting other factories
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

        -- called when:
        -- - a construction is started
    elseif command.CommandType == 'BuildMobile' then
        -- add a small animation (just change the 2nd argument to 5 and back)
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

        -- called when:
        -- - a construction is being continued building (for non-factory units)
        -- - a construction is being repaired
    elseif command.CommandType == 'Repair' then

        -- see if we can rebuild a structure
        if command.Target.Type == 'Entity' then -- repair wreck to rebuild
            local cb = { Func = "Rebuild", Args = { entity = command.Target.EntityId, Clear = command.Clear } }
            SimCallback(cb, true)
        end

        -- called when:
        -- - ?
    elseif command.CommandType == 'Script' and command.LuaParams.TaskName == 'AttackMove' then
        local avgPoint = { 0, 0 }
        for _, unit in command.Units do
            avgPoint[1] = avgPoint[1] + unit:GetPosition()[1]
            avgPoint[2] = avgPoint[2] + unit:GetPosition()[3]
        end
        avgPoint[1] = avgPoint[1] / TableGetN(command.Units)
        avgPoint[2] = avgPoint[2] / TableGetN(command.Units)

        avgPoint[1] = command.Target.Position[1] - avgPoint[1]
        avgPoint[2] = command.Target.Position[3] - avgPoint[2]

        local rotation = MathAtan(avgPoint[1] / avgPoint[2])
        rotation = rotation * 180 / MathPi
        if avgPoint[2] < 0 then
            rotation = rotation + 180
        end
        local cb = { Func = "AttackMove", Args = { Target = command.Target.Position, Rotation = rotation,
            Clear = command.Clear } }
        SimCallback(cb, true)
        AddDefaultCommandFeedbackBlips(command.Target.Position)

        -- called when:
        -- - ?
    elseif command.Clear == true and command.CommandType ~= 'Stop' and TableGetN(command.Units) == 1 and
        checkBadClean(command.Units[1]) then
        watchForQueueChange(command.Units[1])

        -- called when:
        -- - ?
    elseif command.CommandType == 'Script' and command.LuaParams and command.LuaParams.Enhancement then
        EnhancementQueueFile.enqueueEnhancement(command.Units, command.LuaParams.Enhancement)

        -- called when:
        -- - a generic stop command is issued
    elseif command.CommandType == 'Stop' then
        EnhancementQueueFile.clearEnhancements(command.Units)

        -- called when:
        -- - none of the above applies
    else
        if AddCommandFeedbackByType(command.Target.Position, command.CommandType) == false then
            AddDefaultCommandFeedbackBlips(command.Target.Position)
        end
    end
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
