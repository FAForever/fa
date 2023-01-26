
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Combo = import("/lua/ui/controls/combo.lua").Combo
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ThreatInformation = import("/lua/shared/maputilities.lua").ThreatInformation

--- Creates the UI for the iMAP grid tab
-- @param state Complete state of the window
-- @param area The area that we have been given to work in
-- @param lastElement Vertically speaking, the element before this element
function CreateUI(state, area, lastElement)

    -- determine nicknames of non-civilian armies
    local nonCivs = { }
    local nonCivsh = 1 
    for k, army in GetArmiesTable().armiesTable do 
        if not army.civilian then 
            nonCivs[nonCivsh] = army.nickname
            nonCivsh = nonCivsh + 1
        end
    end

    local group = Group(area)
    group.Left:Set(function() return area.Left() + LayoutHelpers.ScaleNumber(10) end )
    group.Right:Set(function() return area.Right() end )
    group.Top:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(10) end )
    group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(100) end ) -- dummy value 

    do 
        local label = UIUtil.CreateText(group, "Toggle AI grid", 14, UIUtil.bodyFont, false)
        LayoutHelpers.AtTopIn(label, group, 0)
        LayoutHelpers.AtLeftIn(label, group)

        -- we need the reference to enable / disable it
        local combo = Combo(group, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")

        local checkbox = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
        LayoutHelpers.DepthOverParent(checkbox, area, 10)
        LayoutHelpers.AtCenterIn(checkbox, label)
        checkbox.Left:Set(function() return group.Right() - (checkbox.Width() + LayoutHelpers.ScaleNumber(10)) end )
        checkbox.OnCheck = function (self, checked)
            state.GridEnabled = checked 

            -- inform sim about changes
            SimCallback({
                Func = 'iMapToggleRendering', Args = { Checked = state.GridEnabled }
            })

            if checked then 
                combo:Enable()
            else
                combo:Disable()
            end
        end

        combo.Left:Set(function() return label.Right() + LayoutHelpers.ScaleNumber(10) end )
        combo.Right:Set(function() return checkbox.Left() - LayoutHelpers.ScaleNumber(10)  end )
        combo.Top:Set(function() return label.Top() end)
        LayoutHelpers.DepthOverParent(combo, group, 10)

        combo.OnClick = function(self, index, text)
            state.GridArmy = index 

            -- inform sim about changes
            SimCallback({
                Func = 'iMapSwitchPerspective', Args = { Army = state.GridArmy }
            })
        end

        combo:AddItems(nonCivs, 1, 1)
        combo:Disable()

        local description = ItemList(group)
        description:SetFont(UIUtil.bodyFont, 14)
        description:SetColors(UIUtil.bodyColor, "00000000",  UIUtil.highlightColor, "00000000")
        description.Left:Set(function() return group.Left() end)
        description.Right:Set(function() return group.Right() end)
        description.Top:Set(function() return label.Bottom() + LayoutHelpers.ScaleNumber(8) end )
        description.Bottom:Set(function() return label.Bottom() + LayoutHelpers.ScaleNumber(64) end )

        UIUtil.SetTextBoxText(
            description, 
            "Toggles the iMAP grid that the AI uses to determine threat values. The threat in each square is the summation of the threat of the individual units. Each line indicates 50 points worth of threat."
        )

        local lastElement = UIUtil.CreateText(group, "Threat values", 14, UIUtil.bodyFont, false)
        LayoutHelpers.Below(lastElement, description)
        LayoutHelpers.AtLeftIn(lastElement, description)

        -- iteratively populate the area
        for k, threat in ThreatInformation do 

            local bitmap = Bitmap(group)
            bitmap:InternalSetSolidColor(threat.color)
            LayoutHelpers.Below(bitmap, lastElement, 8)
            LayoutHelpers.AtLeftIn(bitmap, group, 10)
            bitmap.Width:Set(function() return LayoutHelpers.ScaleNumber(10) end)
            bitmap.Height:Set(function() return LayoutHelpers.ScaleNumber(10) end)

            local name = UIUtil.CreateText(group, threat.identifier, 14, UIUtil.bodyFont, false)
            LayoutHelpers.AtCenterIn(name, bitmap)
            name.Left:Set(function() return bitmap.Right() + LayoutHelpers.ScaleNumber(8) end)

            local check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
            LayoutHelpers.DepthOverParent(check, area, 10)
            LayoutHelpers.AtCenterIn(check, bitmap)
            check.Left:Set(function() return group.Right() - (check.Width() + LayoutHelpers.ScaleNumber(8)) end )

            -- catch in closure as upvalue
            local identifier = threat.identifier
            check.OnCheck = function (self, checked)
                    SimCallback({
                        Func = 'iMapToggleThreat', 
                        Args = { Identifier = identifier }
                    }
                )
            end

            -- allows the next element to be below the last element
            lastElement = name
        end

        -- match bottom of group with that of the last element
        group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(10) end)
    end

    group:Hide()
    return group
end
