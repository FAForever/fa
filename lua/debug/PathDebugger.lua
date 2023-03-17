--*****************************************************************************
--* File: lua/modules/debug/PathDebugger.lua
--* Author: Bob Berry
--* Summary: Pathfinder debugger
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Border = import("/lua/maui/border.lua").Border
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local UIUtil = import("/lua/ui/uiutil.lua")
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Text = import("/lua/maui/text.lua").Text


local unselectedCheckboxFile = UIUtil.UIFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.UIFile('/widgets/rad_sel.dds')

local statusCluster = import("/lua/ui/game/gamemain.lua").GetStatusCluster()
local controlCluster = import("/lua/ui/game/gamemain.lua").GetControlCluster()
local gameParent = import("/lua/ui/game/gamemain.lua").GetGameParent()
local worldView = import("/lua/ui/game/worldview.lua").view

local unselectedCheckboxFile = UIUtil.UIFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.UIFile('/widgets/rad_sel.dds')

local dialog = nil
local debugger = nil
local FinderStart = nil
local FinderGoal = nil

local bStartFindMode = false
local bOverlay = false

function PDText(parent,text,font,size)
    local t = Text(parent)
    t:SetText(text)
    t:SetFont(font or "Andale Mono", size or 12)
    t:DisableHitTest()
    return t
end

function PDCheckBox(parent,label,func)
    local box = Checkbox(parent,unselectedCheckboxFile,selectedCheckboxFile)
    local text = nil

    box.OnCheck = function(self,checked)
        ExecLuaInSim(func, checked)
    end

    if label then
        local text = PDText(parent,label)
        LayoutHelpers.RightOf(text,box,1)
    end
    return box
end

function PDButton(parent,text)
    local button = UIUtil.CreateButtonStd(parent,'/widgets/gen-tab',text,12)
    button.label:SetFont('Andale Mono', 12)
    button.mClickCue = nil
    button.mRolloverCue = nil
    return button
end

function SetFinderStart()
    local s = tostring(FinderStart.x)..','..FinderStart.y..','..FinderStart.z
    ExecLuaInSim('pathdebug_SetFinderStart',s)
end

function SetFinderGoal()
    local g = tostring(FinderGoal.x)..','..FinderGoal.y..','..FinderGoal.z
    ExecLuaInSim('pathdebug_SetFinderGoal',g)
end

function CreateUI()
    bOverlay = true
    ConExecute('dbg pathfinder')
    dialog = Group(gameParent, 'path debugger')
    dialog.Depth:Set(1000)

    local backdrop = Bitmap(dialog)
    backdrop:SetSolidColor('c0000000')
    LayoutHelpers.FillParent(backdrop, dialog)

    LayoutHelpers.Below( dialog, statusCluster, 1 )
    LayoutHelpers.Above( dialog, controlCluster, 1 )
    dialog.Left:Set( function() return statusCluster.Right() - 128 end )
    dialog.Right:Set( statusCluster.Right )

    dialog:Show()

    local debugger = PathDebugger()

    --
    -- LOD Level
    --
    local lodBtnLft = PDButton(backdrop,"<")
    LayoutHelpers.AtTopIn(lodBtnLft,backdrop,1)
    lodBtnLft.Left:Set( backdrop.Left )
    function lodBtnLft.OnClick(self,modifiers)
        ExecLuaInSim('pathdebug_LodPlus',nil)
    end

    local lodText = Text(backdrop)
    lodText:SetFont("Andale Mono", 12)
    lodText:SetText("LOD")
    lodText:DisableHitTest()
    LayoutHelpers.RightOf(lodText,lodBtnLft,1)

    local lodBtnRgt = PDButton(backdrop,">")
    LayoutHelpers.RightOf(lodBtnRgt,lodText,1)
    function lodBtnRgt.OnClick(self,modifiers)
        ExecLuaInSim('pathdebug_LodMinus',nil)
    end

    --
    -- CellGroup
    --
    local grpBtnLft = PDButton(backdrop,"<")
    LayoutHelpers.Below(grpBtnLft,lodBtnLft,3)
    grpBtnLft.Left:Set( backdrop.Left )
    function grpBtnLft.OnClick(self,modifiers)
        ExecLuaInSim('pathdebug_GroupPlus',nil)
    end

    local grpText = Text(backdrop)
    grpText:SetFont("Andale Mono", 12)
    grpText:SetText("Group")
    grpText:DisableHitTest()
    LayoutHelpers.RightOf(grpText,grpBtnLft,1)

    local grpBtnRgt = PDButton(backdrop,">")
    LayoutHelpers.RightOf(grpBtnRgt,grpText,1)
    function grpBtnRgt.OnClick(self,modifiers)
        ExecLuaInSim('pathdebug_GroupMinus',nil)
    end

    --
    -- Boolean options
    --
    local gridBox = PDCheckBox(backdrop,"Grid","pathdebug_ShowGrid")
    LayoutHelpers.Below(gridBox,grpBtnLft,3)
    gridBox.Left:Set(backdrop.Left)

    local edgeBox = PDCheckBox(backdrop,"Edges","pathdebug_ShowEdges")
    LayoutHelpers.Below(edgeBox,gridBox,1)
    edgeBox.Left:Set(backdrop.Left)

    local nodeBox = PDCheckBox(backdrop,"Nodes","pathdebug_ShowNodes")
    LayoutHelpers.Below(nodeBox,edgeBox,1)
    nodeBox.Left:Set(backdrop.Left)

    local neibBox = PDCheckBox(backdrop,"Neibs","pathdebug_ShowNeighbors")
    LayoutHelpers.Below(neibBox,nodeBox,1)
    neibBox.Left:Set(backdrop.Left)

    local occBox = PDCheckBox(backdrop,"Occupy","pathdebug_ShowCanOccupy")
    LayoutHelpers.Below(occBox,neibBox,1)
    occBox.Left:Set(backdrop.Left)

    local dirtyBox = PDCheckBox(backdrop,"Dirty","pathdebug_ShowDirty")
    LayoutHelpers.Below(dirtyBox,occBox,1)
    dirtyBox.Left:Set(backdrop.Left)

    --
    -- Start / Step path finder
    --
    local startFind = PDButton(backdrop,"Start")
    startFind.Top:Set( function() return dirtyBox.Bottom() + 3 end )
    startFind.Left:Set( dialog.Left )
    startFind.OnClick = function(self,modifiers)
        bStartFindMode = true
    end

    local stepFind = PDButton(backdrop,"Step")
    stepFind.Top:Set( startFind.Top )
    stepFind.Left:Set( function() return dialog.Right() - stepFind.Width() end )
    stepFind.OnClick = function(self,modifiers)
        if modifiers.Shift == true then
            ExecLuaInSim('pathdebug_StepFinder',10)
        elseif modifiers.Ctrl == true then
            ExecLuaInSim('pathdebug_StepFinder',100)
        else
            ExecLuaInSim('pathdebug_StepFinder',1)
        end
    end

    --
    -- Set up our event handler to eat input from the WorldView when necessary
    --
    worldView.EventRedirect = function(self,event)
        if bStartFindMode then
            if event.Type == "ButtonPress" or event.Type == "ButtonDClick" then
                if FinderStart then
                    FinderGoal = GetMouseWorldPos()
                    LOG('finder goal = ', repr(FinderGoal))
                    SetFinderGoal()
                    FinderStart = nil
                    FinderGoal = nil
                    bStartFindMode = false
                else
                    FinderStart = GetMouseWorldPos()
                    SetFinderStart()
                    LOG('finder start = ', repr(FinderStart))
                end
                return true
            end
        end
        if occBox:IsChecked() then
            local p = GetMouseWorldPos()
            ExecLuaInSim('pathdebug_SetMousePos',p.x..','..p.y..','..p.z)
        end
        return false
    end
end

function DestroyUI()
    if dialog then
        dialog:Destroy()
        dialog = nil
    end
    if debugger then
        debugger:Destroy()
        debugger = nil
    end
    if bOverlay then
        bOverlay = false
        ConExecute('dbg pathfinder')
    end
    worldView.EventRedirect = nil
end

---@class PathDebugger : moho.PathDebugger_methods
PathDebugger = Class(moho.PathDebugger_methods) {
    __init = function(self,spec)
        _c_CreatePathDebugger(self,spec)
    end,
}
