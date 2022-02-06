
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Window = import('/lua/maui/window.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Text = import('/lua/maui/text.lua').Text

-- complete state of this window
local State = {
    WindowIsOpen = false,
    GUI = false,
    EnabledMarkerTypes = {
        Resources = { },
        Pathing = { },
        AI = { },
    },
}

-- populate marker types
State.EnabledMarkerTypes.Resources["Mass"] = false
State.EnabledMarkerTypes.Resources["Hydrocarbon"] = false
State.EnabledMarkerTypes.Pathing["Land Path Node"] = false
State.EnabledMarkerTypes.Pathing["Air Path Node"] = false
State.EnabledMarkerTypes.Pathing["Water Path Node"] = false
State.EnabledMarkerTypes.Pathing["Amphibious Path Node"] = false
State.EnabledMarkerTypes.AI["Rally Point"] = false
State.EnabledMarkerTypes.AI["Expansion Area"] = false
State.EnabledMarkerTypes.AI["Large Expansion Area"] = false
State.EnabledMarkerTypes.AI["Naval Area"] = false
State.EnabledMarkerTypes.AI["Naval Link"] = false
State.EnabledMarkerTypes.AI["Protected Experimental Construction"] = false
State.EnabledMarkerTypes.AI["Defensive Point"] = false
State.EnabledMarkerTypes.AI["Transport Marker"] = false
State.EnabledMarkerTypes.AI["Combat Zone"] = false
State.EnabledMarkerTypes.AI["Island"] = false

--- Updates the UI elements of the window
function UpdateViewOfWindow()

    -- State.GUI:Show()

end

--- Opens up the window
function OpenWindow()

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
            "Marker utilities", 
            false, 
            false, 
            false, 
            true, 
            false, 
            "marker-utilities-window13",
            10,
            300, 
            830,
            360
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
        local parent = State.GUI.Groups
        local lastElement = parent

        -- iteratively populate the window
        for k, group in State.EnabledMarkerTypes do 

            -- create title of group
            local groupUI = UIUtil.CreateText(parent, k, 16, UIUtil.titleFont, false)
            LayoutHelpers.Below(groupUI, lastElement, 8)
            LayoutHelpers.AtLeftIn(groupUI, parent, 12)

            lastElement = groupUI 

            -- create markers of group
            for l, type in group do 

                local typeUI = UIUtil.CreateText(parent, l, 14, UIUtil.bodyFont, false)
                LayoutHelpers.Below(typeUI, lastElement, 8)
                LayoutHelpers.AtLeftIn(typeUI, groupUI, 12)

                local checkUI = UIUtil.CreateCheckboxStd(parent, '/dialogs/check-box_btn/radio')
                LayoutHelpers.DepthOverParent(checkUI, State.GUI, 10)
                LayoutHelpers.AtCenterIn(checkUI, typeUI)
                LayoutHelpers.AtLeftIn(checkUI, parent, 300)

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
    else
        State.GUI:Show()
    end

    -- update the GUI
    UpdateViewOfWindow()
end

--- Closes the window
function CloseWindow()

    SPEW("Closing marker utilities window")

    State.WindowIsOpen = false

    if State.GUI then 
        State.GUI:Hide()
    end
end