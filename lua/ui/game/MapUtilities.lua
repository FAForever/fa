
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Group = import('/lua/maui/group.lua').Group
local Window = import('/lua/maui/window.lua')

local sessionInfo = SessionGetScenarioInfo()

-- complete state of this window
local State = {
    WindowIsOpen = false,
    GUI = false,

    ActiveTab = "Resources",
    GUITabs = { },

    GridEnabled = false,
    GridArmy = 1,
}

local function SwitchTab(target)

    -- keep track what active tab we had
    State.ActiveTab = target

    -- hide all tabs
    for k, tab in State.GUITabs do 
        tab:Hide()
    end
    -- show the tab we're interested in
    State.GUITabs[target]:Show()

    -- adjust window height
    State.GUI.Bottom:Set(function() return State.GUITabs[target].Bottom() end )
end

--- Opens up the window
function OpenWindow()

    -- prevent it from opening when cheats are enabled
    if not sessionInfo.Options.CheatsEnabled then 
        WARN("Unable to open marker utilities window: cheats are disabled")
        return 
    end

    -- make hotkey act as a toggle
    if State.WindowIsOpen then 
        CloseWindow()
        return
    end

    SPEW("Opening marker utilities window")

    State.WindowIsOpen = true 

    -- populate the GUI
    if not State.GUI then 

        SPEW("Created marker utilities window")

        -- create the window
        State.GUI = Window.CreateDefaultWindow(
            GetFrame(0), 
            "Map utilities", 
            false, 
            false, 
            false, 
            true, 
            false, 
            "map-utilities-window7",
            10,
            300, 
            830,
            460
        )

        State.GUI.Border = UIUtil.SurroundWithBorder(State.GUI, '/scx_menu/lan-game-lobby/frame/')

        -- functionality of exit button
        State.GUI.OnClose = function(self)
            CloseWindow()
        end

        -- create group that will become the parent of all the elements
        State.GUI.Groups = Group(State.GUI)
        LayoutHelpers.FillParent(State.GUI.Groups, State.GUI.TitleGroup)

        -- initialize state
        local window = State.GUI

        -- construct navigation header

        local groupNavigation = Group(window)
        groupNavigation.Left:Set(function() return window.Left() end )
        groupNavigation.Right:Set(function() return window.Right() end)
        groupNavigation.Top:Set(function() return window.TitleGroup.Bottom() + LayoutHelpers.ScaleNumber(10) end)
        groupNavigation.Bottom:Set(function() return window.TitleGroup.Bottom() + LayoutHelpers.ScaleNumber(100 ) end) -- dummy value

        do 

            local buttonResources = UIUtil.CreateButtonStd(groupNavigation, '/widgets02/small', "Resources", 16, 2)
            LayoutHelpers.AtTopIn(buttonResources, groupNavigation, 4)
            LayoutHelpers.FromLeftIn(buttonResources, groupNavigation, 0.010)
            LayoutHelpers.DepthOverParent(buttonResources, window, 10)
            buttonResources.OnClick = function (self)
                SwitchTab("Resources")
            end

            local buttonGrid = UIUtil.CreateButtonStd(groupNavigation, '/widgets02/small', "Grid", 16, 2)
            LayoutHelpers.AtTopIn(buttonGrid, groupNavigation, 4)
            LayoutHelpers.FromLeftIn(buttonGrid, groupNavigation, 0.340)
            LayoutHelpers.DepthOverParent(buttonGrid, window, 10)
            buttonGrid.OnClick = function (self)
                SwitchTab("Grid")
            end

            local buttonMarkers = UIUtil.CreateButtonStd(groupNavigation, '/widgets02/small', "Markers", 16, 2)
            LayoutHelpers.AtTopIn(buttonMarkers, groupNavigation, 4)
            LayoutHelpers.FromLeftIn(buttonMarkers, groupNavigation, 0.670)
            LayoutHelpers.DepthOverParent(buttonMarkers, window, 10)
            buttonMarkers.OnClick = function (self)
                SwitchTab("Markers")
            end

            groupNavigation.Bottom:Set(function() return buttonResources.Bottom() end )

        end

        -- -- add various content
        State.GUITabs.Resources = import("/lua/ui/game/MapUtilitiesResourcesTab.lua").CreateUI(State, window, groupNavigation)
        State.GUITabs.Grid = import("/lua/ui/game/MapUtilitiesGridTab.lua").CreateUI(State, window, groupNavigation)
        State.GUITabs.Markers = import("/lua/ui/game/MapUtilitiesMarkersTab.lua").CreateUI(State, window, groupNavigation)

        -- switch to initial tab
        SwitchTab(State.ActiveTab)

    else
        -- show all of the window
        State.GUI:Show()

        -- hide unrelated tabs
        SwitchTab(State.ActiveTab)
    end
end

--- Closes the window
function CloseWindow()

    SPEW("Closing marker utilities window")

    State.WindowIsOpen = false

    if State.GUI then 
        State.GUI:Hide()
    end
end