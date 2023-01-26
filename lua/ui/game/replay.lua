--*****************************************************************************
--* File: lua/modules/ui/game/orders.lua
--* Author: Chris Blackwell
--* Summary: Unit orders UI
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Grid = import("/lua/maui/grid.lua").Grid
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Button = import("/lua/maui/button.lua").Button
local Tooltip = import("/lua/ui/game/tooltip.lua")
local TooltipInfo = import("/lua/ui/help/tooltips.lua")
local Prefs = import("/lua/user/prefs.lua")
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

controls =
{
    bg = false,
    pause = false,
    armycombo = false,
    speedSlider = false,
    currentSpeed = false,
    controlClusterGroup = false,
    mfdControl = false,
}

-- positioning controls, don't belong to file
local layoutVar = false
local glowThread = false

function SetLayout(layout)
    layoutVar = layout
    
    import(UIUtil.GetLayoutFilename('replay')).SetLayout()
    
    local itemArray = {}
    controls.armycombo.keyMap = {}
    local armyTable = GetArmiesTable()
    local index = 1
    for i, val in armyTable.armiesTable do
        if val.showScore and not val.civilian then
            itemArray[index] = val.nickname
            controls.armycombo.keyMap[val.name] = i
            index = index + 1
        end
    end
    table.insert(itemArray, "<LOC lobui_0284>Observers")
    local defValue = table.getsize(itemArray)
    controls.armycombo:AddItems(itemArray, defValue)
    controls.armycombo.OnClick = function(self, index, text)
        if index > table.getsize(itemArray) - 1 then
            SetFocusArmy(-1)
        else
            SetFocusArmy(index)
        end
    end
    controls.speedSlider.OnValueChanged = function(self, newValue)
        controls.currentSpeed:SetText(string.format("%+d", math.floor(tostring(newValue))))
    end
    
    controls.speedSlider.OnValueSet = function(self, newValue)
        ConExecute("WLD_GameSpeed " .. newValue)
    end
    
    -- set initial value
    controls.speedSlider:SetValue(0)
end

-- called from gamemain to create control
function SetupReplayControl(parent, mfd)
    controls.controlClusterGroup = parent
    controls.mfdControl = mfd

    SetLayout(UIUtil.currentLayout)

    return controls.bg
end

function AdjustGameSpeed(newSpeed)
    controls.speedSlider:SetValue(newSpeed)
end