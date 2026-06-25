--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The setup-presets dialog: a host-only list of named full-setup snapshots (map / options / mods /
-- restrictions) you can Load / Save / Rename / Delete — the customlobby-native rebuild of the legacy
-- `/lua/ui/lobby/presets.lua` dialog. Built to the map/mod-select shape (areas layout, three-phase
-- init, Popup singleton).
--
-- It is a transient picker, NOT a model component: it owns no synced state. Persistence is in
-- CustomLobbyPresets (pure prefs); applying a preset to the synced launch state is host-authoritative
-- and goes through the controller intents (`RequestLoadSetupPreset` / `RequestSaveSetupPreset`).
--
-- Scope note (§ O): a preset captures the *players* too, but loading does NOT reseat them yet —
-- restoring players/AIs needs infra the new lobby doesn't have (no AI-add, no per-player intents).
-- The reserved `lastGame` preset (auto-saved at launch) is shown as a pinned "Last game" entry; the
-- future rehost feature loads it. See ../CLAUDE.md.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local CustomLobbyPresets = import("/lua/ui/lobby/customlobby/customlobbypresets.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

-- five action buttons (Load / Save / Rename / Delete · Close) sit in one row; each `/BUTTON/small/`
-- is 152×40 unscaled (see /textures/texture-dimensions.csv), so the dialog is sized to hold
-- 5×152 + the inter-button gaps + padding without overlap.
local DialogWidth = 820
local DialogHeight = 470
local Pad = 12
local ColumnGap = 20
local ListWidth = 250
local ScrollbarInset = 20
local TitleHeight = 32
local ButtonGap = 8
local ActionHeight = 48

local LabelColor = 'ffc8ccd0'

--- Creates a layout area (an invisible Group with an optional debug tint).
---@param parent Control
---@param name string
---@param color string
---@return Group
local function CreateArea(parent, name, color)
    local area = Group(parent, name)
    local bg = Bitmap(area)
    bg:SetSolidColor(color)
    bg:SetAlpha(Debug and 0.18 or 0.0)
    bg:DisableHitTest()
    Layouter(bg):Fill(area):End()
    area.Bg = bg
    return area
end

--- The user-facing label for a preset name (the reserved last-game key shows as "Last game").
---@param name string
---@return string
local function DisplayName(name)
    if name == CustomLobbyPresets.LastGamePresetName then
        return "Last game"
    end
    return name
end

--- The number of seated players a snapshot captured.
---@param setup UICustomLobbySetupSnapshot
---@return number
local function CountPlayers(setup)
    local n = 0
    for _, player in setup.Players or {} do
        if player then
            n = n + 1
        end
    end
    return n
end

--- The map's display name for a snapshot, or "(none)" / the raw file when it can't be read.
---@param setup UICustomLobbySetupSnapshot
---@return string
local function MapNameOf(setup)
    local scenarioFile = setup.ScenarioFile
    if not scenarioFile then
        return "(none)"
    end
    local ok, info = pcall(function()
        return import("/lua/ui/maputil.lua").LoadScenario(scenarioFile)
    end)
    if ok and info and info.name then
        return info.name
    end
    return tostring(scenarioFile)
end

--- The read-only fact lines shown for the selected preset.
---@param setup UICustomLobbySetupSnapshot
---@return string[]
local function FactsFor(setup)
    return {
        "Map:  " .. MapNameOf(setup),
        "Mods:  " .. table.getsize(setup.GameMods or {}),
        "Restrictions:  " .. table.getn(setup.Restrictions or {}),
        "Players:  " .. CountPlayers(setup),
    }
end

---@class UICustomLobbyPresetSelect : Group
---@field Trash TrashBag
---@field OnCloseCb fun()
---@field TitleArea Group
---@field ListArea Group
---@field DetailArea Group
---@field ActionArea Group
---@field Title Text
---@field PresetList ItemList
---@field DetailList ItemList
---@field EmptyLabel Text
---@field LoadButton Button
---@field SaveButton Button
---@field RenameButton Button
---@field DeleteButton Button
---@field CloseButton Button
---@field OrderedNames string[]    # actual preset names, parallel to the list rows (0-based +1)
---@field Ready boolean
local CustomLobbyPresetSelect = ClassUI(Group) {

    ---@param self UICustomLobbyPresetSelect
    ---@param parent Control
    ---@param options { onClose: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyPresetSelect")

        self.Trash = TrashBag()
        self.OnCloseCb = options.onClose
        self.Ready = false
        self.OrderedNames = {}

        -- areas
        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.ListArea = CreateArea(self, "ListArea", 'ff4060cc')
        self.DetailArea = CreateArea(self, "DetailArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Setup presets", 22, UIUtil.titleFont)
        self.Title:DisableHitTest()

        --#region preset list (left)
        self.PresetList = ItemList(self.ListArea)
        self.PresetList:SetFont(UIUtil.bodyFont, 14)
        self.PresetList:ShowMouseoverItem(true)
        self.PresetList.OnClick = function(control, row, event)
            control:SetSelection(row)
            self:OnSelectRow(row)
        end
        self.PresetList.OnKeySelect = function(control, row)
            self:OnSelectRow(row)
        end
        self.PresetList.OnDoubleClick = function(control, row)
            self:OnSelectRow(row)
            self:LoadSelected()
        end

        self.EmptyLabel = UIUtil.CreateText(self.ListArea, "No saved presets", 14, UIUtil.bodyFont)
        self.EmptyLabel:SetColor('ff8a909a')
        self.EmptyLabel:DisableHitTest()
        self.EmptyLabel:Hide()
        --#endregion

        --#region detail (right) — a read-only fact list
        self.DetailList = ItemList(self.DetailArea)
        self.DetailList:SetFont(UIUtil.bodyFont, 13)
        self.DetailList:SetColors(LabelColor, "00000000")
        self.DetailList:DisableHitTest()
        --#endregion

        --#region actions
        self.LoadButton = UIUtil.CreateButtonStd(self.ActionArea, '/BUTTON/small/', "<LOC _Load>Load", 14, 2)
        self.LoadButton.OnClick = function(button, modifiers)
            self:LoadSelected()
        end
        Tooltip.AddControlTooltipManual(self.LoadButton, "Load preset",
            "Apply the selected preset's map, options, mods and restrictions to the lobby.")

        self.SaveButton = UIUtil.CreateButtonStd(self.ActionArea, '/BUTTON/small/', "<LOC _Save>Save", 14, 2)
        self.SaveButton.OnClick = function(button, modifiers)
            self:PromptSave()
        end
        Tooltip.AddControlTooltipManual(self.SaveButton, "Save preset", "Save the current lobby setup as a named preset.")

        self.RenameButton = UIUtil.CreateButtonStd(self.ActionArea, '/BUTTON/small/', "Rename", 14, 2)
        self.RenameButton.OnClick = function(button, modifiers)
            self:PromptRename()
        end
        Tooltip.AddControlTooltipManual(self.RenameButton, "Rename preset", "Rename the selected preset.")

        self.DeleteButton = UIUtil.CreateButtonStd(self.ActionArea, '/BUTTON/small/', "<LOC _Delete>Delete", 14, 2)
        self.DeleteButton.OnClick = function(button, modifiers)
            self:DeleteSelected()
        end
        Tooltip.AddControlTooltipManual(self.DeleteButton, "Delete preset", "Delete the selected preset.")

        self.CloseButton = UIUtil.CreateButtonStd(self.ActionArea, '/BUTTON/small/', "<LOC _Close>Close", 14, 2)
        self.CloseButton.OnClick = function(button, modifiers)
            self.OnCloseCb()
        end
        --#endregion
    end,

    ---@param self UICustomLobbyPresetSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        --#region areas
        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.ListArea)
            :AtLeftIn(self, Pad):Width(ListWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        Layouter(self.DetailArea)
            :AnchorToRight(self.ListArea, ColumnGap):AtRightIn(self, Pad)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        --#endregion

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        --#region list + detail
        Layouter(self.PresetList):AtLeftIn(self.ListArea):AtTopIn(self.ListArea):AtBottomIn(self.ListArea):End()
        self.PresetList.Right:Set(function() return self.ListArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarInset) end)
        UIUtil.CreateLobbyVertScrollbar(self.PresetList, 2)
        Layouter(self.EmptyLabel):AtHorizontalCenterIn(self.ListArea):AtVerticalCenterIn(self.ListArea):End()

        Layouter(self.DetailList):AtLeftIn(self.DetailArea):AtTopIn(self.DetailArea):AtBottomIn(self.DetailArea):End()
        self.DetailList.Right:Set(function() return self.DetailArea.Right() - LayoutHelpers.ScaleNumber(ScrollbarInset) end)
        --#endregion

        --#region actions: Load / Save / Rename / Delete on the left, Close on the right
        Layouter(self.LoadButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.SaveButton):AnchorToRight(self.LoadButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.RenameButton):AnchorToRight(self.SaveButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.DeleteButton):AnchorToRight(self.RenameButton, ButtonGap):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.CloseButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        --#endregion
    end,

    --- Post-mount first render (the opener calls this after Popup centres the dialog).
    ---@param self UICustomLobbyPresetSelect
    Initialize = function(self)
        self.Ready = true
        self:RefreshList()
    end,

    --- Rebuilds the preset list from prefs, preserving the selection by name where possible.
    ---@param self UICustomLobbyPresetSelect
    ---@param keepName? string
    RefreshList = function(self, keepName)
        local presets = CustomLobbyPresets.GetPresets()
        self.OrderedNames = {}
        self.PresetList:DeleteAllItems()
        for _, preset in presets do
            table.insert(self.OrderedNames, preset.Name)
            self.PresetList:AddItem(DisplayName(preset.Name))
        end

        local count = table.getn(self.OrderedNames)
        if count == 0 then
            self.EmptyLabel:Show()
            self:OnSelectRow(nil)
            return
        end
        self.EmptyLabel:Hide()

        -- restore the previous selection by name, else select the first row
        local select = 0
        if keepName then
            for index, name in self.OrderedNames do
                if name == keepName then
                    select = index - 1
                    break
                end
            end
        end
        self.PresetList:SetSelection(select)
        self:OnSelectRow(select)
    end,

    --- The actual preset name for a 0-based list row, or nil.
    ---@param self UICustomLobbyPresetSelect
    ---@param row number | nil
    ---@return string | nil
    NameForRow = function(self, row)
        if type(row) ~= 'number' then
            return nil
        end
        return self.OrderedNames[row + 1]
    end,

    --- Updates the detail panel + button enablement for the selected row (nil = no selection).
    ---@param self UICustomLobbyPresetSelect
    ---@param row number | nil
    OnSelectRow = function(self, row)
        local name = self:NameForRow(row)
        self.DetailList:DeleteAllItems()
        if not name then
            self.LoadButton:Disable()
            self.RenameButton:Disable()
            self.DeleteButton:Disable()
            return
        end

        self.LoadButton:Enable()
        self.DeleteButton:Enable()
        -- the reserved last-game entry can't be renamed (its name is the rehost contract)
        if name == CustomLobbyPresets.LastGamePresetName then
            self.RenameButton:Disable()
        else
            self.RenameButton:Enable()
        end

        local setup = CustomLobbyPresets.GetPreset(name)
        if setup then
            for _, line in FactsFor(setup) do
                self.DetailList:AddItem(line)
            end
        end
    end,

    --- Loads (applies) the selected preset and closes the dialog.
    ---@param self UICustomLobbyPresetSelect
    LoadSelected = function(self)
        local name = self:NameForRow(self.PresetList:GetSelection())
        if not name then
            return
        end
        CustomLobbyController.RequestLoadSetupPreset(name)
        self.OnCloseCb()
    end,

    --- Prompts for a name and saves the current lobby setup as a preset.
    ---@param self UICustomLobbyPresetSelect
    PromptSave = function(self)
        UIUtil.CreateInputDialog(GetFrame(0), "Name this preset", function(dialog, name)
            if not name or name == "" then
                return
            end
            CustomLobbyController.RequestSaveSetupPreset(name)
            self:RefreshList(name)
        end)
    end,

    --- Prompts for a new name and renames the selected preset.
    ---@param self UICustomLobbyPresetSelect
    PromptRename = function(self)
        local oldName = self:NameForRow(self.PresetList:GetSelection())
        if not oldName or oldName == CustomLobbyPresets.LastGamePresetName then
            return
        end
        UIUtil.CreateInputDialog(GetFrame(0), "Rename preset", function(dialog, newName)
            if CustomLobbyPresets.RenamePreset(oldName, newName) then
                self:RefreshList(newName)
            end
        end)
    end,

    --- Deletes the selected preset.
    ---@param self UICustomLobbyPresetSelect
    DeleteSelected = function(self)
        local name = self:NameForRow(self.PresetList:GetSelection())
        if not name then
            return
        end
        CustomLobbyPresets.DeletePreset(name)
        self:RefreshList()
    end,

    ---@param self UICustomLobbyPresetSelect
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the setup-presets dialog over `parent` (host-only entry point — the action-bar button).
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)

    if Instance then
        Instance:Close()
    end

    local popup
    local content = CustomLobbyPresetSelect(parent, {
        onClose = function()
            if popup then
                popup:Close()
            end
        end,
    })

    popup = Popup(parent, content)
    local baseOnClosed = popup.OnClosed
    popup.OnClosed = function(self)
        baseOnClosed(self)
        Instance = false
    end
    Instance = popup

    -- now that Popup has mounted + centred the content, it's safe to populate (the lists read
    -- concrete geometry)
    content:Initialize()
end

--- Closes the dialog if open.
function Close()
    if Instance then
        Instance:Close()
        Instance = false
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Close()
end

--#endregion
