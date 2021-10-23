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
--[[
 THESE TABLES ARE NOT ACTUALLY USED IN SCRIPT. Just here for reference

 -- these are the strings which represent a command mode
 commandModes = {
     "order",
     "build",
     "buildanchored",
 }

 these strings come from the cpp code in UnitBP, don't change them please!
 orderModes = {

    RULEUCC_Move                = (1 << 0),
    RULEUCC_Stop                = (1 << 1),
    RULEUCC_Attack              = (1 << 2),
    RULEUCC_Guard               = (1 << 3),
    RULEUCC_Patrol              = (1 << 4),
    RULEUCC_RetaliateToggle     = (1 << 5),

    // Unit specific rules
    RULEUCC_Repair              = (1 << 6),
    RULEUCC_Capture             = (1 << 7),
    RULEUCC_Transport           = (1 << 8),
    RULEUCC_CallTransport       = (1 << 9),
    RULEUCC_Nuke                = (1 << 10),
    RULEUCC_Tactical            = (1 << 11),
    RULEUCC_Teleport            = (1 << 12),
    RULEUCC_Ferry               = (1 << 13),
    RULEUCC_SiloBuildTactical   = (1 << 14),
    RULEUCC_SiloBuildNuke       = (1 << 15),
    RULEUCC_Sacrifice           = (1 << 16),
    RULEUCC_Pause               = (1 << 17),
    RULEUCC_Overcharge          = (1 << 18),
    RULEUCC_Dive                = (1 << 19),
    RULEUCC_Reclaim             = (1 << 20),
    RULEUCC_SpecialAction       = (1 << 21),
    RULEUCC_Dock                = (1 << 22),

    // Unit general
    RULEUCC_Script              = (1 << 23),
 }

 toggleModes = {

    // Unit toggle rules
    RULEUTC_ShieldToggle        = (1 << 0),
    RULEUTC_WeaponToggle        = (1 << 1),
    RULEUTC_JammingToggle       = (1 << 2),
    RULEUTC_IntelToggle         = (1 << 3),
    RULEUTC_ProductionToggle    = (1 << 4),
    RULEUTC_StealthToggle       = (1 << 5),
    RULEUTC_GenericToggle       = (1 << 6),
    RULEUTC_SpecialToggle       = (1 << 7),
    RULEUTC_CloakToggle         = (1 << 8),
}

--]]

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
local issuedOneCommand = false

local startBehaviors = {}
local endBehaviors = {}

local ignoreSelection = false
function SetIgnoreSelection(ignore)
    ignoreSelection = ignore
end

function OnCommandModeBeat()
    if issuedOneCommand and not IsKeyDown('Shift') then
        EndCommandMode(true)
    end
end

import('/lua/ui/game/gamemain.lua').AddBeatFunction(OnCommandModeBeat)

-- behaviors are functions that take a single string parameter, the commandMode (or false if none)
function AddStartBehavior(behavior)
    table.insert(startBehaviors, behavior)
end

function AddEndBehavior(behavior)
    table.insert(endBehaviors, behavior)
end

function StartCommandMode(newCommandMode, data)
    if commandMode then
        EndCommandMode(true)
    end

    commandMode = newCommandMode
    modeData = data
    for i,v in startBehaviors do
        v(commandMode, modeData)
    end

    import('/lua/ui/controls/worldview.lua').OnStartCommandMode(newCommandMode, data)
end

-- allocate the table once for performance
local commandModeTable = { }

--- Retrieves the command mode information.
function GetCommandMode()
    commandModeTable[1] = commandMode
    commandModeTable[2] = modeData

    if commandMode and modeData then 
        LOG(repr(commandMode))
        LOG(repr(modeData))
    end

    return commandModeTable
end

function EndCommandMode(isCancel)
    if ignoreSelection then
        return
    end

    modeData.isCancel = isCancel or false
    for i,v in endBehaviors do
        v(commandMode, modeData)
    end

    if modeData.isCancel then
        ClearBuildTemplates()
    end

    commandMode = false
    modeData = false
    issuedOneCommand = false
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

--- Allows us to detect a double tab
local previousStructure = nil
function AssistMex(command)

    -- check if we have engineers
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end

    -- check if we have a building that we target
    local structure = GetUnitById(command.Target.EntityId)
    if not structure or IsDestroyed(structure) then return end

    -- are we a structure?
    if structure:IsInCategory('STRUCTURE') then 

        -- if we have a non-t1 extractor, create storages and / or fabricators around it
        if structure:IsInCategory('MASSEXTRACTION') then 

            -- conditions 
            local isTech1 = structure:IsInCategory('TECH1')
            local isTech2 = structure:IsInCategory('TECH2')
            local isTech3 = structure:IsInCategory('TECH3')

            local isDoubleTapped = previousStructure == structure
            previousStructure = structure

            local isUpgrading = IsKeyDown('Shift') and isDoubleTapped
     
            -- check what type of buildings we'd like to make
            local buildStorages = (isTech1 and isUpgrading) or (isTech2 and not isUpgrading) or (isTech3 and not isDoubleTapped)
            local buildFabs = (isTech2 and isUpgrading) or (isTech3 and isDoubleTapped)

            if buildStorages then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)
            end

            if buildFabs then 
                SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 2, id = "b1104" }}, true)
                -- reset state in case we want storages after cancel
                previousStructure = nil
            end
        end

        -- if we have a t3 fabricator, create storages around it
        if structure:IsInCategory('MASSFABRICATION') and structure:IsInCategory('TECH3') then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id = "b1106" }}, true)
        end

        -- if we have a t2 artillery, create t1 pgens around it
        if structure:IsInCategory('ARTILLERY') then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)
        end

        -- if we have a radar, create t1 pgens around it
        if structure:IsInCategory('RADAR') then 
            SimCallback({Func = 'CapStructure', Args = {target = command.Target.EntityId, layer = 1, id =  "b1101" }}, true)
        end
    end
end

-- cached category strings for performance
local categoriesFactories = categories.STRUCTURE * categories.FACTORY
local categoriesShields = categories.MOBILE * categories.SHIELD
local categoriesStructure = categories.STRUCTURE

function OnCommandIssued(command)

    -- ?
    if not command.Clear then
        issuedOneCommand = true
    else
        EndCommandMode(true)
    end


    -- called when:
    -- - a factory-like construction that is not finished is being continued
    -- - a (finished) unit is being guarded (right clicked)
    if command.CommandType == 'Guard' and command.Target.EntityId then
        LOG("Guard")

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
            if options['assist_mex'] then AssistMex(command) end
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

        LOG("Repair")

        -- see if we can rebuild a structure
        if command.Target.Type == 'Entity' then -- repair wreck to rebuild
            local cb = {Func="Rebuild", Args={entity=command.Target.EntityId, Clear=command.Clear}}
            SimCallback(cb, true)
        end

    -- called when:
    -- - ?
    elseif command.CommandType == 'Script' and command.LuaParams.TaskName == 'AttackMove' then
        local view = import('/lua/ui/game/worldview.lua').viewLeft
        local avgPoint = {0,0}
        for _,unit in command.Units do
            avgPoint[1] = avgPoint[1] + unit:GetPosition()[1]
            avgPoint[2] = avgPoint[2] + unit:GetPosition()[3]
        end
        avgPoint[1] = avgPoint[1] / table.getn(command.Units)
        avgPoint[2] = avgPoint[2] / table.getn(command.Units)

        avgPoint[1] = command.Target.Position[1] - avgPoint[1]
        avgPoint[2] = command.Target.Position[3] - avgPoint[2]

        local rotation = math.atan(avgPoint[1]/avgPoint[2])
        rotation = rotation * 180 / math.pi
        if avgPoint[2] < 0 then
            rotation = rotation + 180
        end
        local cb = {Func="AttackMove", Args={Target=command.Target.Position, Rotation = rotation, Clear=command.Clear}}
        SimCallback(cb, true)
        AddDefaultCommandFeedbackBlips(command.Target.Position)

    -- called when: 
    -- - ?
    elseif command.Clear == true and command.CommandType ~= 'Stop' and table.getn(command.Units) == 1 and checkBadClean(command.Units[1]) then
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
