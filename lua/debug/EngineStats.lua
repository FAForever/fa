--*****************************************************************************
--* File: lua/modules/debug/EngineStats.lua
--* Author: Bob Berry
--* Summary: Displays Engine Statistics
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local ipairs = ipairs
local tostring = tostring
local stringFormat = string.format
local stringLower = string.lower
local stringFind = string.find
local stringGsub = string.gsub
local stringSub = string.sub
local next = next

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList

local statusCluster = import('/lua/ui/game/gamemain.lua').GetStatusCluster()
local controlCluster = import('/lua/ui/game/gamemain.lua').GetControlCluster()
local gameParent = import('/lua/ui/game/gamemain.lua').GetGameParent()
local UIUtil = import('/lua/ui/uiutil.lua')

local dialog = nil
local filter = nil
local hideItems = {}

function Toggle(section)
    if dialog then
        dialog:Destroy()
        dialog = nil
        return
    end

    filter = stringLower(section)

    dialog = Group(gameParent, 'Engine Stats')
    dialog.Depth:Set(1000)
    LayoutHelpers.Below( dialog, statusCluster, 1 )
    LayoutHelpers.Above( dialog, controlCluster, 1 )
    LayoutHelpers.AtLeftIn(dialog, statusCluster, 30)
    LayoutHelpers.AnchorToLeft(dialog, statusCluster, -384)
    dialog:SetNeedsFrameUpdate(true)

    statList = ItemList(dialog,"root stat list")
    LayoutHelpers.Below( statList, statusCluster, 1 )
    LayoutHelpers.Above( statList, controlCluster, 1 )
    LayoutHelpers.AtLeftIn(statList, statusCluster, 30)
    LayoutHelpers.AnchorToLeft(statList, statusCluster, -384)
    statList:SetFont('Andale Mono', 12)
    statList:SetColors('FFFFFFFF','00000000','FFFFFF00','FF0000FF')
    local sb = UIUtil.CreateVertScrollbarFor(statList)
    sb.Left:Set(statusCluster.Left)

    -- Hide/Show children on doubleclick
    function statList.OnDoubleClick(self,row)
        local item i = self:GetItem(row)
        i = stringGsub(i,"^%s*%[[+-]%]","")
        local from,to = stringFind(i,'%a+:')
        if from then
            i = stringSub(i,from,to-1)
        end

        hideItems[i] = not hideItems[i]
    end

    function dialog.OnFrame(self,elapsed)
        local add = false
        if filter == "all" then
            add = true
        end

        statList:DeleteAllItems()
        if __EngineStats.Children then
            AddStats(statList,__EngineStats.Children,'',add)
        end
    end

    dialog:Show()
end

function AddStats(parentCtrl, children, indent, add)
    for k,v in children do
        local isFilter = stringLower(v.Name) == filter
        local addChildren = add or isFilter

        local name = stringGsub(v.Name,"Moho::","")

        local value = ""
        if v.Value ~= nil then
            if v.Type == "Float" then
                value = ": " .. stringFormat("%.4f",v.Value)
            elseif v.Type == "Integer" then
                value = ": " .. tostring(v.Value)
            else
                value = ": " .. v.Value
            end
        end

        -- If we're adding an item we've never seen before default
        -- to collapsed mode (unless it's specifically our filter item)
        if hideItems[name] == nil then
            if isFilter then
                hideItems[name] = false
            else
                hideItems[name] = true
            end
            repr(hideItems)
        end

        local hidden = hideItems[name]

        if addChildren then
            local treeMode = ""
            if v.Children ~= nil then
                if hidden then
                    treeMode = "[+]"
                else
                    treeMode = "[-]"
                end
            end
            parentCtrl:AddItem(tostring(indent) .. treeMode .. name .. value)
        end
        if v.Children ~= nil and not hidden then
            AddStats(parentCtrl,v.Children,indent..'  ',addChildren)
        end
    end
end
