
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Combo = import("/lua/ui/controls/combo.lua").Combo
local GameMain = import("/lua/ui/game/gamemain.lua")

local sessionInfo = SessionGetScenarioInfo()
local UpdateViewOfWindow
local CloseWindow

local TableGetN = table.getn

local cachedSelection = { }
cachedSelection.oldSelection = { }
cachedSelection.newSelection = { }
cachedSelection.added = { }
cachedSelection.removed = { }

-- complete state of this window
local State = {
    WindowIsOpen = false,
    GUI = false,
    SelectedTable = "Defense",
}

--- Observe selection changes
GameMain.ObserveSelection:AddObserver(
    function(cache)
        -- copy over references
        cachedSelection.oldSelection = cache.oldSelection
        cachedSelection.newSelection = cache.newSelection
        cachedSelection.added = cache.added
        cachedSelection.removed = cache.removed

        UpdateViewOfWindow()
    end
)

local cHead = 1
local cTuples = { }

--- Adds a tuple with a given key, value and depth to allow for indenting
local function AddTuple(key, value, depth)
    local tuple = cTuples[cHead] or { }
    tuple.key = key
    tuple.value = value 
    tuple.depth = depth
    
    cTuples[cHead] = tuple 
    cHead = cHead + 1
end

--- Formats the tuple, if there is no key then only the value is shown
local function FormatTuple(tuple)
    local result = ""
    if tuple.key then
        result = tuple.key .. " = " .. tuple.value
    else 
        result = tuple.value
    end

    return result 
end

--- Tuple extraction for various blueprint categories
local BlueprintConversion = { }
BlueprintConversion.Categories = function(blueprint)
    if blueprint.Categories then 
        for k, cat in blueprint.Categories do 
            AddTuple(false, cat, 0)
        end
    else 
        AddTuple(false, "No categories table", 0)
    end
end

BlueprintConversion.Defense = function(blueprint)
    if blueprint.Defense then 
        for key, val in blueprint.Defense do 
            AddTuple(key, tostring(val), 0)
        end
    else 
        AddTuple(false, "No defense table", 0)
    end
end

BlueprintConversion.Economy = function(blueprint)
    if blueprint.Economy then 
        for key, val in blueprint.Economy do 
            AddTuple(key, tostring(val), 0)
        end
    else 
        AddTuple(false, "No economy table", 0)
    end
end

BlueprintConversion.Intel = function(blueprint)
    if blueprint.Intel then 
        for key, val in blueprint.Intel do 
            AddTuple(key, tostring(val), 0)
        end
    else 
        AddTuple(false, "No intel table", 0)
    end
end

BlueprintConversion.Transport = function(blueprint)
    if blueprint.Transport then 
        for key, val in blueprint.Transport do 
            AddTuple(key, tostring(val), 0)
        end
    else 
        AddTuple(false, "No transport table", 0)
    end
end

--- Updates the UI elements of the window
function UpdateViewOfWindow()

    -- mark all for hiding
    for k, text in State.GUI.Elements do 
        text.Unused = true 
    end

    -- keep track of last shown element
    local parent = State.GUI.Combo

    -- get unit count
    local count = TableGetN(cachedSelection.newSelection) or 0

    -- nope, no units
    if count == 0 then 
        State.GUI.Info:SetText("No unit selected")
    else 

        -- at least one unit, so get the blueprint of the first one
        local blueprint = cachedSelection.newSelection[1]:GetBlueprint()

        -- acknowledge that we have multiple units
        if count > 1 then 
            State.GUI.Info:SetText("Multiple units - " .. LOC(blueprint.Description))
        end

        -- acknowledge that we have one unit
        if count == 1 then 
            State.GUI.Info:SetText(LOC(blueprint.Description))
        end

        -- reset and populate cache
        cHead = 1
        BlueprintConversion[State.SelectedTable](blueprint)

        -- visualize cache
        for k = 1, cHead - 1 do 

            -- retrieve tuple
            local tuple = cTuples[k]

            -- retrieve text
            local text = State.GUI.Elements[k] 
            if not text then 
                text = UIUtil.CreateText(State.GUI.Groups, "unknown", 14, UIUtil.bodyFont, false)
                State.GUI.Elements[k] = text
            end
            
            -- do not hide it
            text.Unused = false

            -- format tuple
            text:SetText(FormatTuple(tuple))

            -- position text
            LayoutHelpers.Below(text, parent, 4)
            LayoutHelpers.AtLeftIn(text, State.GUI.Info, tuple.depth)

            -- keep track who the parent is / was
            parent = text
        end
    end

    LayoutHelpers.AtBottomIn(State.GUI, parent, -10)

    -- hide accordingly
    for k, text in State.GUI.Elements do 
        if text.Unused then 
            text:Hide()
        else
            if State.WindowIsOpen then 
                text:Show()
            end
        end
    end
end

--- Opens up the window
function OpenWindow()

    -- prevent it from opening when there are no AIs or no cheats
    if not (GameMain.GameHasAIs or sessionInfo.Options.CheatsEnabled) then 
        WARN("Unable to open AI utilities window: no AIs and / or cheats are disabled")
        return 
    end

    -- make hotkey act as a toggle
    if State.WindowIsOpen then 
        CloseWindow()
        return
    end

    SPEW("Opening AI utilities window")

    State.WindowIsOpen = true 

    -- populate the GUI
    if not State.GUI then 

        SPEW("Created AI utilities window")

        -- create the window
        State.GUI = UIUtil.CreateWindowStd(
            GetFrame(0), 
            "AI blueprint information", 
            false, 
            false, 
            false, 
            true, 
            false, 
            "ai-utilities-window2",
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

        -- extensive info text 1 / 2
        State.GUI.Extensive1 = UIUtil.CreateText(State.GUI.Groups, "With cheats enabled, Hold Shift + F6 for a more", 14, UIUtil.bodyFont, false)
        LayoutHelpers.Below(State.GUI.Extensive1, State.GUI.Groups, 4)
        LayoutHelpers.AtLeftIn(State.GUI.Extensive1, State.GUI.Groups, 12)

        State.GUI.Extensive2 = UIUtil.CreateText(State.GUI.Groups, "extensive blueprint viewer", 14, UIUtil.bodyFont, false)
        LayoutHelpers.Below(State.GUI.Extensive2, State.GUI.Extensive1, 4)
        LayoutHelpers.AtLeftIn(State.GUI.Extensive2, State.GUI.Extensive1, 0)

        -- info text about selected unit
        State.GUI.Info = UIUtil.CreateText(State.GUI.Groups, "No unit selected", 14, UIUtil.bodyFont, false)
        LayoutHelpers.Below(State.GUI.Info, State.GUI.Extensive2, 18)
        LayoutHelpers.AtLeftIn(State.GUI.Info, State.GUI.Extensive2, 0)

        -- combo box to select info from categories
        State.GUI.Combo = Combo(State.GUI.Groups, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.Below(State.GUI.Combo, State.GUI.Info, 4)
        LayoutHelpers.AtLeftIn(State.GUI.Combo, State.GUI.Info, 0)
        LayoutHelpers.SetWidth(State.GUI.Combo, 300)
        LayoutHelpers.DepthOverParent(State.GUI.Combo, State.GUI.Groups, 10000)

        local keys = table.keys(BlueprintConversion)

        local i = 1
        for k, key in keys do 
            if key == State.SelectedTable then 
                i = k 
            end
        end

        State.GUI.Combo:AddItems(keys, i, i)

        State.GUI.Combo.OnClick = function(self, index, text)
            local keys = table.keys(BlueprintConversion)
            State.SelectedTable = keys[index]
            UpdateViewOfWindow()
        end

        State.GUI.Elements = { }
    else
        State.GUI:Show()
    end

    -- update the GUI
    UpdateViewOfWindow()
end

--- Closes the window
function CloseWindow()

    SPEW("Closing AI utilities window")

    State.WindowIsOpen = false

    if State.GUI then 
        State.GUI:Hide()
    end
end

-- kept for mod backwards compatibility
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Window = import("/lua/maui/window.lua")
local Text = import("/lua/maui/text.lua").Text