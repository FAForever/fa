#*****************************************************************************
#* File: lua/modules/ui/game/commandmode.lua
#* Author: Chris Blackwell
#* Summary: Manages the current command mode, which determines what action
#* the mouse will take when next clicked in the world
#*
#* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Construction = import('/lua/ui/game/construction.lua')
local UIMain = import('/lua/ui/uimain.lua')
local Orders = import('/lua/ui/game/orders.lua')
local commandMeshResources = import('/lua/ui/game/commandmeshes.lua').commandMeshResources

--[[
 THESE TABLES ARE NOT ACTUALLY USED IN SCRIPT. Just here for reference

 # these are the strings which represent a command mode
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
end

function GetCommandMode()
    return {commandMode, modeData}
end

function EndCommandMode(isCancel)
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


function OnCommandIssued(command)
    if not command.Clear then
        issuedOneCommand = true
    else
        EndCommandMode(true)
    end

    if command.CommandType == 'Attack' then
        if command.Clear then
            local cb = { Func = 'ClearTargets', Args = { } }
            SimCallback(cb, true)
        end

        local cb = { Func = 'AddTarget', Args = { target = command.Target.EntityId, position = command.Target.Position } }
        SimCallback(cb, true)

    --else
    --  local cc = { Func = 'ClearTargets', Args = { } }
    --  SimCallback(cc, true)
    end
    -- end of issue:#43

    if command.CommandType == 'Reclaim' and (command.Target.Type == 'Position' or IsKeyDown('Menu')) then
        import('/modules/reclaimground.lua').ReclaimGround(command)
    end

    if command.CommandType == 'BuildMobile' then
        AddCommandFeedbackBlip({
            Position = command.Target.Position,
            BlueprintID = command.Blueprint,
            TextureName = '/meshes/game/flag02d_albedo.dds',
            ShaderName = 'CommandFeedback',
            UniformScale = 1,
        }, 0.7)
    else

        if AddCommandFeedbackByType(command.Target.Position, command.CommandType) == false then
            AddCommandFeedbackBlip({
                Position = command.Target.Position,
                MeshName = '/meshes/game/flag02d_lod0.scm',
                TextureName = '/meshes/game/flag02d_albedo.dds',
                ShaderName = 'CommandFeedback',
                UniformScale = 0.5,
            }, 0.7)

            AddCommandFeedbackBlip({
                Position = command.Target.Position,
                MeshName = '/meshes/game/crosshair02d_lod0.scm',
                TextureName = '/meshes/game/crosshair02d_albedo.dds',
                ShaderName = 'CommandFeedback2',
                UniformScale = 0.5,
            }, 0.75)
        end
    end
    import('/lua/spreadattack.lua').MakeShadowCopyOrders(command)
end
