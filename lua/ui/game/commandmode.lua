--*****************************************************************************
--* File: lua/modules/ui/game/commandmode.lua
--* Author: Chris Blackwell
--* Summary: Manages the current command mode, which determines what action
--* the mouse will take when next clicked in the world
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Construction = import('/lua/ui/game/construction.lua')
local UIMain = import('/lua/ui/uimain.lua')
local Orders = import('/lua/ui/game/orders.lua')
local commandMeshResources = import('/lua/ui/game/commandmeshes.lua').commandMeshResources
local Prefs = import('/lua/user/prefs.lua')

local watchForQueueChange = import('/lua/ui/game/construction.lua').watchForQueueChange
local checkBadClean = import('/lua/ui/game/construction.lua').checkBadClean
local EnhancementQueueFile = import('/lua/ui/notify/enhancementqueue.lua')

local WorldView = import('/lua/ui/controls/worldview.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')

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


-- When this file is reloaded (using /EnableDiskWatch) the cursor no longer changes
-- during command mode (e.g., when you do a move order it turns your cursor into
-- the blue move marker). This is fixed by reloading the game.

--- Can be one of three values:
-- - order (called when performing an order)
-- - build (called when trying to build something)
-- - buildanchored (called when ... ?)
local commandMode = false

--- Contains additional information for the current command mode:
-- - order -> name (order type, e.g., RULEUCC_Move)
-- - build -> name (blueprint type, e.g., xsb1101)
-- - buildanchored -> ?
local modeData = false

--- Auto-disable command mode right after one command - used when shift is not pressed down.
local issuedOneCommand = false

--- Behavior to run when entering command mode. If f is a function, it is called as f(commandMode, modeData).
local startBehaviors = {}

--- Behavior to run when exiting command mode. If f is a function, it is called as f(commandMode, modeData).
local endBehaviors = {}

--- Adds a starting behavior.
-- @param behavior The behavior to add, called as behavior(commandMode, modeData).
function AddStartBehavior(behavior)
    TableInsert(startBehaviors, behavior)
end

--- Adds a starting behavior.
-- @param behavior The behavior to add, called as behavior(commandMode, modeData).
function AddEndBehavior(behavior)
    TableInsert(endBehaviors, behavior)
end

--- ???
local ignoreSelection = false
function SetIgnoreSelection(ignore)
    ignoreSelection = ignore
end

--- Called when the command mode starts and initialises all the data.
-- @param newCommandMode The new command mode.
-- @param data The new mode data.
function StartCommandMode(newCommandMode, data)

    -- clean up previous command mode
    if commandMode then
        EndCommandMode(true)
    end

    -- update our local state
    commandMode = newCommandMode
    modeData = data

    -- do start behaviors
    for i,v in startBehaviors do
        v(commandMode, modeData)
    end

    -- update cursor
    WorldView.OnStartCommandMode(newCommandMode, data)
end

--- Called when the command mode ends and deconstructs all the data.
-- @param isCancel Is set to true when it cancels a current command mode for a new one.
function EndCommandMode(isCancel)

    --- ???
    if ignoreSelection then
        return
    end

    -- add information to modeData for end behavior
    modeData.isCancel = isCancel or false

    -- do end behaviors
    for i,v in endBehaviors do
        v(commandMode, modeData)
    end

    -- ???
    if modeData.isCancel then
        ClearBuildTemplates()
    end

    -- update our local state
    commandMode = false
    modeData = false
    issuedOneCommand = false
end

-- allocate the table once for performance
local commandModeTable = { }

--- Retrieves the current command mode information.
function GetCommandMode()
    commandModeTable[1] = commandMode
    commandModeTable[2] = modeData
    return commandModeTable
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

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- are we a structure?
    if structure:IsInCategory('STRUCTURE') then 

        local isDoubleTapped = structure ~= nil and (pStructure1 == structure)
        local isTripleTapped = structure ~= nil and (pStructure2 == structure)

        LOG("structure: " .. tostring(structure))
        LOG("isDoubleTapped: " .. tostring(isDoubleTapped))
        LOG("isTripleTapped: " .. tostring(isTripleTapped))

        -- if we have a non-t1 extractor, create storages and / or fabricators around it
        if structure:IsInCategory('MASSEXTRACTION') then 

            -- various conditions written out for clarity
            local isTech1 = structure:IsInCategory('TECH1')
            local isTech2 = structure:IsInCategory('TECH2')
            local isTech3 = structure:IsInCategory('TECH3')

            local isUpgrading = (structure:GetFocus() ~= nil) and IsKeyDown('Shift')
     
            local isTech1AndUpgrading = (isTech1 and isUpgrading and isDoubleTapped)
            local isTech2AndTapped = (isTech2 and (not isUpgrading) and isDoubleTapped)
            local isTech3AndTapped = (isTech3 and isDoubleTapped)

            LOG("isTech1AndUpgrading: " .. tostring(isTech1AndUpgrading))
            LOG("isTech2AndTapped: " .. tostring(isTech2AndTapped))
            LOG("isTech3AndTapped: " .. tostring(isTech3AndTapped))

            LOG("isTech1: " .. tostring(isTech1))
            LOG("isTech2: " .. tostring(isTech2))
            LOG("isTech3: " .. tostring(isTech3))

            -- check what type of buildings we'd like to make
            local buildStorages = (isTech1AndUpgrading or isTech2AndTapped or isTech3AndTapped)
            local buildFabs = (isTech2 and isUpgrading and isTripleTapped) or (isTech3 and isTripleTapped)

            if buildStorages then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)

                -- only clear state if we can't make fabricators 
                if isTech1AndUpgrading or isTech2AndTapped then 
                    structure = nil
                    pStructure1 = nil
                    pStructure2 = nil
    
                end
            end

            if buildFabs then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 2, id = "b1104" }}, true)
                
                -- reset state
                structure = nil
                pStructure1 = nil
                pStructure2 = nil
            end

        -- if we have a t3 fabricator, create storages around it
        elseif structure:IsInCategory('MASSFABRICATION') and structure:IsInCategory('TECH3') and isDoubleTapped then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil

        -- if we have a t2 artillery, create t1 pgens around it
        elseif structure:IsInCategory('ARTILLERY') and structure:IsInCategory('TECH2') and isDoubleTapped then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil

        -- if we have a radar, create t1 pgens around it
        elseif structure:IsInCategory('RADAR') and isDoubleTapped then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil

        -- if we have a radar, create t1 pgens around it
        elseif (structure:IsInCategory('RADAR') or structure:IsInCategory('OMNI')) and isDoubleTapped then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil

        -- if we have a t1 point defense, create walls around it
        elseif structure:IsInCategory('DIRECTFIRE') and structure:IsInCategory('TECH1') and isDoubleTapped then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b5101" }}, true)

            -- reset state
            structure = nil
            pStructure1 = nil
            pStructure2 = nil
        end
    else 
        -- reset state
        structure = nil
        pStructure1 = nil
        pStructure2 = nil
    end

    -- keep track of previous structure to identify a 2nd / 3rd click
    pStructure2 = pStructure1
    pStructure1 = structure
end

-- cached category strings for performance
local categoriesFactories = categories.STRUCTURE * categories.FACTORY
local categoriesShields = categories.MOBILE * categories.SHIELD
local categoriesStructure = categories.STRUCTURE

--- Called by the engine when a new command has been issued by the player.
-- @param command Information surrounding the command that has been issued, such as its CommandType or its Target.
function OnCommandIssued(command)

    -- ???
    if not command.Clear then
        issuedOneCommand = true
    else
        EndCommandMode(true)
    end

    -- called when:
    -- - a factory-like construction that is not finished is being continued
    -- - a (finished) unit is being guarded (right clicked)
    if command.CommandType == 'Guard' and command.Target.EntityId then

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
            local options = Prefs.GetFromCurrentProfile('options')
            if options['assist_mex'] then CapStructure(command) end
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
                UniformScale = 5,
            }, 
            0.7
        )

    -- called when:
    -- - a construction is being continued building (for non-factory units)
    -- - a construction is being repaired
    elseif command.CommandType == 'Repair' then

        -- see if we can rebuild a structure
        if command.Target.Type == 'Entity' then -- repair wreck to rebuild
            local cb = {Func = "Rebuild", Args={entity=command.Target.EntityId, Clear=command.Clear}}
            SimCallback(cb, true)
        end

    -- called when:
    -- - ?
    elseif command.CommandType == 'Script' and command.LuaParams.TaskName == 'AttackMove' then
        local avgPoint = {0,0}
        for _,unit in command.Units do
            avgPoint[1] = avgPoint[1] + unit:GetPosition()[1]
            avgPoint[2] = avgPoint[2] + unit:GetPosition()[3]
        end
        avgPoint[1] = avgPoint[1] / TableGetN(command.Units)
        avgPoint[2] = avgPoint[2] / TableGetN(command.Units)

        avgPoint[1] = command.Target.Position[1] - avgPoint[1]
        avgPoint[2] = command.Target.Position[3] - avgPoint[2]

        local rotation = MathAtan(avgPoint[1]/avgPoint[2])
        rotation = rotation * 180 / MathPi
        if avgPoint[2] < 0 then
            rotation = rotation + 180
        end
        local cb = {Func="AttackMove", Args={Target=command.Target.Position, Rotation = rotation, Clear=command.Clear}}
        SimCallback(cb, true)
        AddDefaultCommandFeedbackBlips(command.Target.Position)

    -- called when: 
    -- - ?
    elseif command.Clear == true and command.CommandType ~= 'Stop' and TableGetN(command.Units) == 1 and checkBadClean(command.Units[1]) then
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
    import('/lua/spreadattack.lua').MakeShadowCopyOrders(command)
end

--- ???
--- Ensures the command mode ends when one one command should be passed through?
function OnCommandModeBeat()
    if issuedOneCommand and not IsKeyDown('Shift') then
        EndCommandMode(true)
    end
end

GameMain.AddBeatFunction(OnCommandModeBeat)

-- The follow tables are just for reference and are not used:

-- -- All possible values for commandMode
-- local commandModes = {
--      "order",
--      "build",
--      "buildanchored",
--  }

-- -- A subset of possible values for the 'name' value of modeData
-- local orderModes = {

--     -- unit general rules
--     RULEUCC_Move                = (1 << 0),
--     RULEUCC_Stop                = (1 << 1),
--     RULEUCC_Attack              = (1 << 2),
--     RULEUCC_Guard               = (1 << 3),
--     RULEUCC_Patrol              = (1 << 4),
--     RULEUCC_RetaliateToggle     = (1 << 5),

--     -- unit specific rules
--     RULEUCC_Repair              = (1 << 6),
--     RULEUCC_Capture             = (1 << 7),
--     RULEUCC_Transport           = (1 << 8),
--     RULEUCC_CallTransport       = (1 << 9),
--     RULEUCC_Nuke                = (1 << 10),
--     RULEUCC_Tactical            = (1 << 11),
--     RULEUCC_Teleport            = (1 << 12),
--     RULEUCC_Ferry               = (1 << 13),
--     RULEUCC_SiloBuildTactical   = (1 << 14),
--     RULEUCC_SiloBuildNuke       = (1 << 15),
--     RULEUCC_Sacrifice           = (1 << 16),
--     RULEUCC_Pause               = (1 << 17),
--     RULEUCC_Overcharge          = (1 << 18),
--     RULEUCC_Dive                = (1 << 19),
--     RULEUCC_Reclaim             = (1 << 20),
--     RULEUCC_SpecialAction       = (1 << 21),
--     RULEUCC_Dock                = (1 << 22),

--     -- unit general
--     RULEUCC_Script              = (1 << 23),
--  }

-- -- ???
-- local toggleModes = {
--     -- unit toggle rules
--     RULEUTC_ShieldToggle        = (1 << 0),
--     RULEUTC_WeaponToggle        = (1 << 1),
--     RULEUTC_JammingToggle       = (1 << 2),
--     RULEUTC_IntelToggle         = (1 << 3),
--     RULEUTC_ProductionToggle    = (1 << 4),
--     RULEUTC_StealthToggle       = (1 << 5),
--     RULEUTC_GenericToggle       = (1 << 6),
--     RULEUTC_SpecialToggle       = (1 << 7),
--     RULEUTC_CloakToggle         = (1 << 8),
-- }