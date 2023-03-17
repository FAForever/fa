--*****************************************************************************
--* File: lua/modules/debug/EngineStats.lua
--* Author: Bob Berry
--* Summary: Displays Engine Statistics
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local statusCluster = import("/lua/ui/game/gamemain.lua").GetStatusCluster()
local controlCluster = import("/lua/ui/game/gamemain.lua").GetControlCluster()
local gameParent = import("/lua/ui/game/gamemain.lua").GetGameParent()
local UIUtil = import("/lua/ui/uiutil.lua")

local dialog = nil
local filter = nil
local lastTick = -1

function Show(army,section)
    if army == -1 or (dialog and dialog.Army == army) then
        if dialog then
            dialog:Destroy()
            dialog = nil
            ExecLuaInSim('SetArmyStatsSyncArmy',-1)
        end
        return
    end

    if not dialog then
        CreateDialog(army,section)
    end
    dialog.Army = army
    ExecLuaInSim('SetArmyStatsSyncArmy',army)
end

function CreateDialog(army,section)

    filter = string.lower(section)

    dialog = Group(gameParent, 'Army Stats')
    dialog.Depth:Set(1000)
    LayoutHelpers.Below( dialog, statusCluster, 1 )
    LayoutHelpers.Above( dialog, controlCluster, 1 )
    LayoutHelpers.AtLeftIn(dialog, statusCluster, 30)
    LayoutHelpers.AnchorToLeft(dialog, statusCluster, -256)
    dialog:SetNeedsFrameUpdate(true)

    statList = ItemList(dialog,"root sim list")
    LayoutHelpers.Below( statList, statusCluster, 1 )
    LayoutHelpers.Above( statList, controlCluster, 1 )
    LayoutHelpers.AtLeftIn(statList, statusCluster, 30)
    LayoutHelpers.AnchorToLeft(statList, statusCluster, -256)
    statList:SetFont('Andale Mono', 12)
    statList:SetColors('FFFFFFFF','00000000','FFFFFF00','FF0000FF')
    local sb = UIUtil.CreateVertScrollbarFor(statList)
    sb.Left:Set(statusCluster.Left)

    function dialog.OnFrame(self,elapsed)
        local add = false
        if filter == "all" then
            add = true
        end

        if Sync.__ArmyStats.Tick and Sync.__ArmyStats.Tick > lastTick then
            statList:DeleteAllItems()
            if Sync.__ArmyStats.Children then
                AddStats(statList,Sync.__ArmyStats.Children,'',add)
            end
            lastTick = Sync.__ArmyStats.Tick
        end
    end

    dialog:Show()
end

function AddStats(parentCtrl, children, indent, add)
    for k,v in children do
        local addChildren = add or string.lower(v.Name) == filter

        local value = ""
        if v.Value ~= nil then
            if v.Type == "Float" then
                value = ": " .. string.format("%.4f",v.Value)
            elseif v.Type == "Integer" then
                value = ": " .. tostring(v.Value)
            else
                value = ": " .. v.Value
            end
        end
        if addChildren then
            parentCtrl:AddItem(indent .. v.Name .. value)

            if v.Blueprints ~= nil then
                for bp,val in v.Blueprints do
                    parentCtrl:AddItem(indent..' '..bp..': '..val)
                end
            end
        end
        if v.Children ~= nil then
            AddStats(parentCtrl,v.Children,indent..'  ',addChildren)
        end
    end
end
