
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Group = import('/lua/maui/group.lua').Group

local LookUpNames = {
    Resources = "Resource markers"
  , Pathing = "Pathing markers"
  , AI = "AI Markers"
}

function CreateUI(state, window, lastElement)

    local group = Group(window)
    group.Left:Set(function() return window.Left() + LayoutHelpers.ScaleNumber(10) end )
    group.Right:Set(function() return window.Right() end )
    group.Top:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(8) end )
    group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(100) end )  

    do 

        local lastElement = Group(group)
        lastElement.Left:Set(function() return group.Left() + LayoutHelpers.ScaleNumber(10) end )
        lastElement.Right:Set(function() return group.Right() end )
        lastElement.Top:Set(function() return group.Top() end )
        lastElement.Bottom:Set(function() return group.Top() end )  

        -- iteratively populate the window
        for k, category in state.EnabledMarkerTypes do 

            -- create title of group
            local groupUI = UIUtil.CreateText(group, LookUpNames[k], 14, UIUtil.bodyFont, false)
            LayoutHelpers.Below(groupUI, lastElement, 8)
            LayoutHelpers.AtLeftIn(groupUI, group)

            lastElement = groupUI 

            -- create markers of group
            for l, type in category do 

                local typeUI = UIUtil.CreateText(group, l, 14, UIUtil.bodyFont, false)
                LayoutHelpers.Below(typeUI, lastElement, 8)
                LayoutHelpers.AtLeftIn(typeUI, group, 12)

                local checkUI = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
                LayoutHelpers.DepthOverParent(checkUI, window, 10)
                LayoutHelpers.AtCenterIn(checkUI, typeUI)
                checkUI.Left:Set(function() return group.Right() - (checkUI.Width() + LayoutHelpers.ScaleNumber(8)) end )

                local identifier = l
                checkUI.OnCheck = function (self, checked)
                        SimCallback({
                            Func = 'ToggleDebugMarkersByType', 
                            Args = { Type = identifier }
                        }
                    )
                end

                -- allows the next element to be below the last element
                lastElement = typeUI
            end
        end

        group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(10) end )  
    end

    group:Hide()
    return group
end