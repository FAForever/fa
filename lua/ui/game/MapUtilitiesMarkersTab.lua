
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group

--- Various marker types in categories that we support
local EnabledMarkerTypes = {
    Resources = { },
    Pathing = { },
    AI = { },
}

--- Populate marker types
EnabledMarkerTypes.Resources["Mass"] = false
EnabledMarkerTypes.Resources["Hydrocarbon"] = false
EnabledMarkerTypes.Pathing["Land Path Node"] = false
EnabledMarkerTypes.Pathing["Air Path Node"] = false
EnabledMarkerTypes.Pathing["Water Path Node"] = false
EnabledMarkerTypes.Pathing["Amphibious Path Node"] = false
EnabledMarkerTypes.AI["Spawn"] = false
EnabledMarkerTypes.AI["Rally Point"] = false
EnabledMarkerTypes.AI["Expansion Area"] = false
EnabledMarkerTypes.AI["Large Expansion Area"] = false
EnabledMarkerTypes.AI["Naval Area"] = false
EnabledMarkerTypes.AI["Naval Link"] = false
EnabledMarkerTypes.AI["Protected Experimental Construction"] = false
EnabledMarkerTypes.AI["Defensive Point"] = false
EnabledMarkerTypes.AI["Transport Marker"] = false
EnabledMarkerTypes.AI["Combat Zone"] = false
EnabledMarkerTypes.AI["Island"] = false

--- Maps the keys of the marker types to more user-friendly names
local LookUpNames = {
    Resources = "Resource markers"
  , Pathing = "Pathing markers"
  , AI = "AI Markers"
}

--- Creates the UI for the markers tab
-- @param state Complete state of the window
-- @param area The area that we have been given to work in
-- @param lastElement Vertically speaking, the element before this element
function CreateUI(state, area, lastElement)

    local group = Group(area)
    group.Left:Set(function() return area.Left() + LayoutHelpers.ScaleNumber(10) end )
    group.Right:Set(function() return area.Right() end )
    group.Top:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(8) end )
    group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(100) end )  

    do 

        local lastElement = Group(group)
        lastElement.Left:Set(function() return group.Left() + LayoutHelpers.ScaleNumber(10) end )
        lastElement.Right:Set(function() return group.Right() end )
        lastElement.Top:Set(function() return group.Top() end )
        lastElement.Bottom:Set(function() return group.Top() end )  

        -- iteratively populate the area
        for k, category in EnabledMarkerTypes do 

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
                LayoutHelpers.DepthOverParent(checkUI, area, 10)
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

        -- match bottom of group with that of the last element
        group.Bottom:Set(function() return lastElement.Bottom() + LayoutHelpers.ScaleNumber(10) end )  
    end

    group:Hide()
    return group
end