
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Window = import('/lua/maui/window.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Text = import('/lua/maui/text.lua').Text


local cachedSelection = { }
cachedSelection.oldSelection = { }
cachedSelection.newSelection = { }
cachedSelection.added = { }
cachedSelection.removed = { }

-- complete state of this window
local State = {
    WindowIsOpen = false,
    GUI = false,
    SelectedTable = "Categories",
}

--- Observe selection changes
GameMain.ObserveSelection:AddObserver(
    function(cache)
        cachedSelection = cache
        UpdateViewOfWindow()
    end
)

local cHead = 1
local cTuples = { }

local function AddTuple(key, value, depth)
    local tuple = cTuples[cHead] or { }
    tuple.key = key
    tuple.value = value 
    tuple.depth = depth
    
    cTuples[cHead] = tuple 
    cHead = cHead + 1
end

local function FormatTuple(tuple)
    local result = ""
    if tuple.key then
        result = tuple.key .. " = " .. tuple.value
    else 
        result = tuple.value
    end

    return result 
end

local BlueprintConversion = { }
BlueprintConversion.Categories = function(blueprint)
    for k, cat in blueprint.Categories do 
        AddTuple(false, cat, 0)
    end
end

BlueprintConversion.Defense = function(blueprint)
    for key, val in blueprint.Defense do 
        AddTuple(key, tostring(val), 0)
    end
end

BlueprintConversion.Defense = function(blueprint)
    for key, val in blueprint.Defense do 
        AddTuple(key, tostring(val), 0)
    end
end

BlueprintConversion.Economy = function(blueprint)
    for key, val in blueprint.Economy do 
        AddTuple(key, tostring(val), 0)
    end
end

BlueprintConversion.Intel = function(blueprint)
    for key, val in blueprint.Intel do 
        AddTuple(key, tostring(val), 0)
    end
end

BlueprintConversion.Transport = function(blueprint)
    for key, val in blueprint.Transport do 
        AddTuple(key, tostring(val), 0)
    end
end

BlueprintConversion.Weapon = function(blueprint)
    for key, weapon in blueprint.Weapon do 
        AddTuple(false, weapon.DisplayName, 0)
        AddTuple("WeaponCategory", weapon.WeaponCategory, 4)
        AddTuple("Damage", tostring(weapon.Damage), 4)
        AddTuple("Radius", tostring(weapon.Radius), 4)

        AddTuple(false, "FireTargetLayerCapsTable", 4)
        if weapon.FireTargetLayerCapsTable then 
        for k, caps in weapon.FireTargetLayerCapsTable do 
            AddTuple(tostring(k), tostring(caps), 8)
        end
        else 
            AddTuple(false, "No pre-defined fire target layers", 8)
        end

        AddTuple(false, "TargetPriorities", 4)
        if weapon.TargetPriorities then 
            for k, cats in weapon.TargetPriorities do 
                AddTuple(false, tostring(cats), 8)
            end
        else 
            AddTuple(false, "No pre-defined target categories", 8)
        end
    end
end

-- BlueprintConversion.Transport = function(blueprint)
--     for key, val in blueprint.Transport do 
--         AddTuple(key, tostring(val), 0)
--     end
-- end

--- Updates the UI elements of the window
function UpdateViewOfWindow()

    -- mark all for hiding
    for k, text in State.GUI.Elements do 
        text.Unused = true 
    end

    -- keep track of last shown element
    local parent = State.GUI.Combo

    -- get unit count
    local count = table.getn(cachedSelection.newSelection) or 0

    -- nope, no units
    if count == 0 then 
        State.GUI.Info:SetText("No unit selected")
    else 

        -- at least one unit, so get the blueprint of the first one
        local blueprint = cachedSelection.newSelection[1]:GetBlueprint()

        -- acknowledge that we have multiple units
        if count > 1 then 
            State.GUI.Info:SetText("Multiple units - AI info of: " .. LOC(blueprint.Description))
        end

        -- acknowledge that we have one unit
        if count == 1 then 
            State.GUI.Info:SetText("AI information of: " .. LOC(blueprint.Description))
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

        State.GUI.Info = UIUtil.CreateText(State.GUI.Groups, "No unit selected", 14, UIUtil.bodyFont, false)
        LayoutHelpers.Below(State.GUI.Info, State.GUI.Groups, 4)
        LayoutHelpers.AtLeftIn(State.GUI.Info, State.GUI.Groups, 12)

        State.GUI.Combo = Combo(State.GUI.Groups, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.Below(State.GUI.Combo, State.GUI.Info, 4)
        LayoutHelpers.AtLeftIn(State.GUI.Combo, State.GUI.Info, 0)
        LayoutHelpers.SetWidth(State.GUI.Combo, 300)
        LayoutHelpers.DepthOverParent(State.GUI.Combo, State.GUI.Groups, 10000)

        local keys = table.keys(BlueprintConversion)
        State.GUI.Combo:AddItems(keys, 1, 1)

        State.GUI.Combo.OnClick = function(self, index, text)
            local keys = table.keys(BlueprintConversion)
            State.SelectedTable = keys[index]
            UpdateViewOfWindow()
        end

        State.GUI.Elements = { }

        -- -- initialize state
        -- local parent = State.GUI.Groups
        -- local lastElement = parent

        -- -- iteratively populate the window
        -- for k, group in State.EnabledMarkerTypes do 

        --     -- create title of group
        --     local groupUI = UIUtil.CreateText(parent, k, 16, UIUtil.titleFont, false)
        --     LayoutHelpers.Below(groupUI, lastElement, 8)
        --     LayoutHelpers.AtLeftIn(groupUI, parent, 12)

        --     lastElement = groupUI 

        --     -- create markers of group
        --     for l, type in group do 

        --         local typeUI = UIUtil.CreateText(parent, l, 14, UIUtil.bodyFont, false)
        --         LayoutHelpers.Below(typeUI, lastElement, 8)
        --         LayoutHelpers.AtLeftIn(typeUI, groupUI, 12)

        --         local checkUI = UIUtil.CreateCheckboxStd(parent, '/dialogs/check-box_btn/radio')
        --         LayoutHelpers.DepthOverParent(checkUI, State.GUI, 10)
        --         LayoutHelpers.AtCenterIn(checkUI, typeUI)
        --         LayoutHelpers.AtLeftIn(checkUI, parent, 300)

        --         local identifier = l
        --         checkUI.OnCheck = function (self, checked)
        --                 SimCallback({
        --                     Func = 'ToggleDebugMarkersByType', 
        --                     Args = { Type = identifier }
        --                 }
        --             )
        --         end

        --         -- allows the next element to be below the last element
        --         lastElement = typeUI
        --     end
        -- end
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