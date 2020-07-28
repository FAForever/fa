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

local commandMode = false
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

function GetCommandMode()
    return {commandMode, modeData}
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

function AddCommandFeedbackByType(pos, type)

    if commandMeshResources[type] == nil then
        return false;
    else
        AddCommandFeedbackBlip({
                    Position = pos,
                    MeshName = commandMeshResources[type][1],
                    TextureName = commandMeshResources[type][2],
                    ShaderName = 'CommandFeedback',
                    UniformScale = 0.125,
                }, 0.7)
    end

    return true;
end

function AddDefaultCommandFeedbackBlips(pos)
    AddCommandFeedbackBlip({
        Position = pos,
        MeshName = '/meshes/game/flag02d_lod0.scm',
        TextureName = '/meshes/game/flag02d_albedo.dds',
        ShaderName = 'CommandFeedback',
        UniformScale = 0.5,
    }, 0.7)

    AddCommandFeedbackBlip({
        Position = pos,
        MeshName = '/meshes/game/crosshair02d_lod0.scm',
        TextureName = '/meshes/game/crosshair02d_albedo.dds',
        ShaderName = 'CommandFeedback2',
        UniformScale = 0.5,
    }, 0.75)
end

local lastMex = nil
function AssistMex(command)
    local units = EntityCategoryFilterDown(categories.ENGINEER, command.Units)
    if not units[1] then return end
    local mex = GetUnitById(command.Target.EntityId)
    if not mex or IsDestroyed(mex) then return end

    local eco = mex:GetEconData()
    local bp = mex:GetBlueprint()
    local is_capped = eco.massProduced == bp.Economy.ProductionPerSecondMass * 1.5
    if is_capped then return end

    local cap = false
    local focus = mex:GetFocus()

    if focus then -- upgrading
        cap = IsKeyDown('Shift') and lastMex == mex
        lastMex = mex
    elseif not mex:IsInCategory('TECH1')  then
        cap = true
    end

    if cap then
        SimCallback({Func = 'CapMex', Args = {target = command.Target.EntityId}}, true)
    end
end

function OnCommandIssued(command)
    if not command.Clear then
        issuedOneCommand = true
    else
        EndCommandMode(true)
    end

    if command.CommandType == 'Guard' and command.Target.EntityId then
        local c = categories.STRUCTURE * categories.FACTORY
        if EntityCategoryContains(c, command.Blueprint) then
            local factories = EntityCategoryFilterDown(c, command.Units) or {}
            if table.getsize(factories) > 0 then
                local cb = { Func = 'ValidateAssist', Args = { target = command.Target.EntityId } }
                SimCallback(cb, true)
            end
        end
        if EntityCategoryContains(categories.STRUCTURE * categories.MASSEXTRACTION, command.Blueprint) then
            local options = Prefs.GetFromCurrentProfile('options')
            if options['assist_mex'] then AssistMex(command) end
        end
        --EQ:this is the only bit we add - a callback for shields so they can disable their pointers.
        local shieldCat = categories.MOBILE * categories.SHIELD
        
        local mobShields = EntityCategoryFilterDown(shieldCat, command.Units)
        
        if mobShields[1] then
            local cb = { Func = 'FlagShield', Args = { target = command.Target.EntityId } }
            SimCallback(cb, true)
        end
    elseif command.CommandType == 'BuildMobile' then
    AddCommandFeedbackBlip({
        Position = command.Target.Position,
        BlueprintID = command.Blueprint,
        TextureName = '/meshes/game/flag02d_albedo.dds',
        ShaderName = 'CommandFeedback',
        UniformScale = 1,
    }, 0.7)
    elseif command.CommandType == 'Repair' then
        local target = command.Target
        if target.Type == 'Entity' then -- repair wreck to rebuild
            local cb = {Func="Rebuild", Args={entity=target.EntityId, Clear=command.Clear}}
            SimCallback(cb, true)
        end
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
    elseif command.Clear == true and command.CommandType ~= 'Stop' and table.getn(command.Units) == 1 and checkBadClean(command.Units[1]) then
        watchForQueueChange(command.Units[1])
    elseif command.CommandType == 'Script' and command.LuaParams and command.LuaParams.Enhancement then
        EnhancementQueueFile.enqueueEnhancement(command.Units, command.LuaParams.Enhancement)
    elseif command.CommandType == 'Stop' then
        EnhancementQueueFile.clearEnhancements(command.Units)
    else
        if AddCommandFeedbackByType(command.Target.Position, command.CommandType) == false then
            AddDefaultCommandFeedbackBlips(command.Target.Position)
        end
    end

    import('/lua/spreadattack.lua').MakeShadowCopyOrders(command)
end
