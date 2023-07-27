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
--- @param behavior function<CommandMode, CommandModeData>
function AddStartBehavior(behavior)
    TableInsert(startBehaviors, behavior)
end

--- Callback triggers when command mode ends
--- @param behavior function<CommandMode, CommandModeData>
function AddEndBehavior(behavior)
    TableInsert(endBehaviors, behavior)
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
function RestoreCommandMode()
    if cachedCommandMode and cachedModeData then
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

--- Allows us to detect a double / triple click
local pStructure1 = nil
local pStructure2 = nil
function CapStructure(command)

    -- retrieve the option in question, can have values: 'off', 'only-storages-extractors' and 'full-suite'
    local option = Prefs.GetFromCurrentProfile('options.structure_capping_feature_01')

    -- bail out - we're not interested
    if option == 'off' then
        return
    end

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- various conditions written out for maintainability
    local isShiftDown = IsKeyDown('Shift')

    local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
    local isTripleTapped = structure ~= nil and (pStructure1 == structure) and (pStructure2 == structure)

    local isUpgrading = structure:GetFocus() ~= nil

    local isTech1 = structure:IsInCategory('TECH1')
    local isTech2 = structure:IsInCategory('TECH2')
    local isTech3 = structure:IsInCategory('TECH3')
    local isTech4 = structure:IsInCategory('EXPERIMENTAL')

    -- only run logic for structures
    if structure:IsInCategory('STRUCTURE') then

        -- try and create storages and / or fabricators around it
        if structure:IsInCategory('MASSEXTRACTION') then

            -- check what type of buildings we'd like to make
            local buildFabs =
            option == 'full-suite'
                and (
                (isTech2 and isUpgrading and isTripleTapped and isShiftDown)
                    or (isTech3 and isDoubleTapped and isShiftDown)
                )

            local buildStorages =
            (
                (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and not isUpgrading)
                    or isTech3
                ) and not buildFabs

            if buildStorages then

                -- prevent consecutive calls
                local gametime = GetGameTimeSeconds()
                if structure.RingStoragesStamp then
                    if structure.RingStoragesStamp + 0.75 > gametime then
                        return
                    end
                end

                structure.RingStoragesStamp = gametime

                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1106" } }, true)

                -- only clear state if we can't make fabricators
                if (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) then
                    structure = nil
                    pStructure1 = nil
                    pStructure2 = nil
                end
            end

            if buildFabs then

                -- prevent consecutive calls
                local gametime = GetGameTimeSeconds()
                if structure.RingFabsStamp then
                    if structure.RingFabsStamp + 0.75 > gametime then
                        return
                    end
                end

                structure.RingFabsStamp = gametime

                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 2, id = "b1104" } }, true)

                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end

            -- only apply these if we're interested in them
        elseif option == 'full-suite' then

            -- prevent consecutive calls
            local gametime = GetGameTimeSeconds()
            if structure.RingStamp then
                if structure.RingStamp + 0.75 > gametime then
                    return
                end
            end

            structure.RingStamp = gametime

            -- if we have a T3 fabricator, create storages around it
            if structure:IsInCategory('MASSFABRICATION') and isTech3 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1106" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a T2 fabricator, create storages around it
            elseif structure:IsInCategory('MASSFABRICATION') and isTech2 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1106" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a T2 artillery, create T1 pgens around it
            elseif structure:IsInCategory('ARTILLERY') and isTech2 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1101" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a T3 artillery, create T3 pgens around it
            elseif structure:IsInCategory('ARTILLERY') and isTech3 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1301" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a T4 artillery, create T3 pgens around it
            elseif structure:IsInCategory('ARTILLERY') and isTech4 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1301" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- -- if we have a T3 Air Factory, create T3 pgens around it
            -- elseif structure:IsInCategory('AIR') and structure:IsInCategory('FACTORY') and isTech3 then
            --     SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1301" } }, true)
            --     -- reset state
            --     structure = nil
            --     pStructure1 = nil
            --     pStructure2 = nil

            -- if we have a radar, create T1 pgens around it
            elseif structure:IsInCategory('RADAR')
                and (
                (isTech1 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and isUpgrading and isDoubleTapped and isShiftDown)
                    or (isTech2 and not isUpgrading)
                )
                or structure:IsInCategory('OMNI')
            then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b1101" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil

            -- if we have a T1 point defense, create walls around it
            elseif structure:IsInCategory('DIRECTFIRE') and isTech1 then
                SimCallback({ Func = 'CapStructure', Args = { target = command.Target.EntityId, layer = 1, id = "b5101" } }, true)
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end
        end
    end

    -- keep track of previous structure to identify a 2nd / 3rd click
    pStructure2 = pStructure1
    pStructure1 = structure

    -- prevent building up state when upgrading but shift isn't pressed
    if isUpgrading and not isShiftDown then
        structure = nil
        pStructure1 = nil
        pStructure2 = nil
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
                function ()
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
                            break;
                        end

                        WaitSeconds(1.0)
                        target = GetUnitById(id)
                    end
                end
            )
        end

        -- add these to keep track
        target.ThreadUnpauseCandidates = target.ThreadUnpauseCandidates or { }
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
            CapStructure(command)
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

    -- used by spread attack to keep track of the orders of units
    import("/lua/spreadattack.lua").MakeShadowCopyOrders(command)
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
