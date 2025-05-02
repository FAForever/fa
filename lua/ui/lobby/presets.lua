local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local Mods = import("/lua/mods.lua")
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local Prefs = import("/lua/user/prefs.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Lobby = import("/lua/ui/lobby/lobby.lua")

local LAST_GAME_PRESET_NAME = "lastGame"
local GUI

---Load and return the current list of presets from persistent storage.
---@return WatchedGameData[]
local function loadPresetsList()
    return Prefs.GetFromCurrentProfile("LobbyPresets") or {}
end

---Write the given list of preset profiles to persistent storage.
---@param list WatchedGameData[]
local function savePresetsList(list)
    Prefs.SetToCurrentProfile("LobbyPresets", list)
end

---Refresh list of presets
local function refreshAvailablePresetsList(PresetList)
    local profiles = loadPresetsList()
    PresetList:DeleteAllItems()

    for k, v in profiles do
        PresetList:AddItem(v.Name)
    end
end

-- Update the right-hand panel of the preset dialog to show the contents of the currently selected
-- profile (passed by name as a parameter)
local function showPresetDetails(preset, InfoList)
    local profiles = loadPresetsList()
    InfoList:DeleteAllItems()
    InfoList:AddItem('Preset Name: ' .. profiles[preset].Name)

    if DiskGetFileInfo(profiles[preset].MapPath) then
        InfoList:AddItem('Map: ' .. profiles[preset].MapName)
    else
        InfoList:AddItem('Map: Unavailable (' .. profiles[preset].MapName .. ')')
    end

    InfoList:AddItem('')

    -- For each mod, look up its name and pretty-print it.
    local allMods = Mods.AllMods()
    for modId, v in profiles[preset].GameMods do
        if v then
            InfoList:AddItem('Mod: ' .. (allMods[modId].name or "UNKNOWN MOD NAME"))
        end
    end

    InfoList:AddItem('')
    InfoList:AddItem('Settings :')
    for k, v in sortedpairs(profiles[preset].GameOptions) do
        InfoList:AddItem('- '..k..' : '..tostring(v))
    end
end

-- Create a preset table representing the current configuration.
local function getPresetFromSettings(presetName)
    local gameInfo = Lobby.GetGameSettings()
    -- Since GameOptions may only contain strings and ints, some added tables need to be removed before storing
    local cleanGameOptions = table.copy(gameInfo.GameOptions)
    cleanGameOptions.ClanTags = nil
    cleanGameOptions.Ratings = nil

    -- Since PlayerOptions may only contain strings and ints, some added tables need to be removed before storing
    local cleanPlayerOptions = table.copy(gameInfo.PlayerOptions)
    cleanPlayerOptions.AsTable = nil
    cleanPlayerOptions.isEmpty = nil
    cleanPlayerOptions.pairs = nil
    cleanPlayerOptions.print = nil

    return {
        Name = presetName,
        MapName = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile).name,
        MapPath = gameInfo.GameOptions.ScenarioFile,
        GameOptions = cleanGameOptions,
        GameMods = Mods.GetSelectedSimMods(),
        PlayerOptions = cleanPlayerOptions
    }
end

---Load preset by index
---@return WatchedGameData
local function loadPreset(presetIndex)
    local preset = loadPresetsList()[presetIndex]

    if not preset.GameOptions.RestrictedCategories then
        preset.GameOptions.RestrictedCategories = {}
    end

    return preset
end

---comment
---@param name string
local function getPresetByName(name)
    local presets = loadPresetsList()
    for index, preset in ipairs(presets) do
        if preset.Name == name then
            return loadPreset(index)
        end
    end
end

---
---@return WatchedGameData|nil
function GetLastGameSettings()
    return getPresetByName(LAST_GAME_PRESET_NAME)
end

---Write the current settings to the given preset profile index
---@param index integer
function SavePreset(index)
    local presets = loadPresetsList()

    local selectedPreset = index
    presets[selectedPreset] = getPresetFromSettings(presets[selectedPreset].Name)

    savePresetsList(presets)
end

---Saves the current setting into the last game preset
function SaveLastGamePreset()
    local presets = loadPresetsList()
    local found = false
    for index, preset in ipairs(presets) do
        if preset.Name == LAST_GAME_PRESET_NAME then
            presets[index] = getPresetFromSettings(LAST_GAME_PRESET_NAME)
            found = true
            break
        end
    end

    if not found then
        table.insert(presets, getPresetFromSettings(LAST_GAME_PRESET_NAME))
    end

    savePresetsList(presets)
end

---Creates the dialog window with insturctions
local function createHelpWindow()
    local dialogContent = Group(GUI)
    LayoutHelpers.SetDimensions(dialogContent, 420, 225)

    local helpWindow = Popup(GUI, dialogContent)

    -- Help textfield
    local textArea = TextArea(dialogContent, 400, 163)
    LayoutHelpers.AtLeftIn(textArea, dialogContent, 13)
    LayoutHelpers.AtTopIn(textArea, dialogContent, 10)
    textArea:SetText(LOC("<LOC tooltipui0706>This dialog allows you to save a snapshot of the current game configuration and reload it later.\n\nOnce the game settings are as you want them, use the \"Create\" button on this dialog to store it. You can reload the stored configuration by selecting it and pressing the \"Load\" button.\n\nThe \"Save\" button will overwrite a selected existing preset with the current configuration."))

    -- OK button
    local OkButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
    LayoutHelpers.AtHorizontalCenterIn(OkButton, dialogContent)
    LayoutHelpers.AtBottomIn(OkButton, dialogContent, 8)
    OkButton.OnClick = function(self)
        helpWindow:Close()
    end
end

---comment
---@param parent Group
function CreateUI(parent)
    GUI = Group(parent)
    LayoutHelpers.SetDimensions(GUI, 600, 530)

    local presetDialog = Popup(parent, GUI)
    presetDialog.OnClosed = presetDialog.Destroy

    -- Title
    local titleText = UIUtil.CreateText(GUI, LOC('<LOC tooltipui0694>Lobby Presets'), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(titleText, GUI, 0)
    LayoutHelpers.AtTopIn(titleText, GUI, 10)

    -- Preset List
    local PresetList = ItemList(GUI)
    PresetList:SetFont(UIUtil.bodyFont, 14)
    PresetList:ShowMouseoverItem(true)
    LayoutHelpers.SetDimensions(PresetList, 265, 430)
    LayoutHelpers.DepthOverParent(PresetList, GUI, 10)
    LayoutHelpers.AtLeftIn(PresetList, GUI, 14)
    LayoutHelpers.AtTopIn(PresetList, GUI, 38)
    UIUtil.CreateLobbyVertScrollbar(PresetList, 2)

    -- Info List
    local InfoList = ItemList(GUI)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    InfoList:SetColors(nil, "00000000")
    InfoList:ShowMouseoverItem(true)
    LayoutHelpers.SetDimensions(InfoList, 281, 430)
    LayoutHelpers.RightOf(InfoList, PresetList, 26)

    -- Quit button
    local QuitButton = UIUtil.CreateButtonStd(GUI, '/dialogs/close_btn/close')
    LayoutHelpers.AtRightIn(QuitButton, GUI, 1)
    LayoutHelpers.AtTopIn(QuitButton, GUI, 1)

    -- Load button
    local LoadButton = UIUtil.CreateButtonWithDropshadow(GUI, '/BUTTON/medium/', "<LOC _Load>Load")
    LayoutHelpers.AtLeftIn(LoadButton, GUI, -2)
    LayoutHelpers.AtBottomIn(LoadButton, GUI, 10)
    LoadButton:Disable()

    -- Create button. Occupies the same space as the load button, when available.
    local CreateButton = UIUtil.CreateButtonWithDropshadow(GUI, '/BUTTON/medium/', "<LOC _Create>Create")
    LayoutHelpers.RightOf(CreateButton, LoadButton, 28)

    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(GUI, '/BUTTON/medium/', "<LOC _Save>Save")
    LayoutHelpers.RightOf(SaveButton, CreateButton, 28)
    SaveButton:Disable()

    -- Delete button
    local DeleteButton = UIUtil.CreateButtonWithDropshadow(GUI, '/BUTTON/medium/', "<LOC _Delete>Delete")
    LayoutHelpers.RightOf(DeleteButton, SaveButton, 28)
    DeleteButton:Disable()

    LoadButton.OnClick = function(self)
        local settings = loadPreset(PresetList:GetSelection() + 1)
        Lobby.ApplyGameSettings(settings)
        presetDialog:Hide()
    end

    QuitButton.OnClick = function(self)
        presetDialog:Hide()
    end

    CreateButton.OnClick = function(self)
        local dialogComplete = function(self, presetName)
            if not presetName or presetName == "" then
                return
            end
            local profiles = loadPresetsList()
            table.insert(profiles, getPresetFromSettings(presetName))
            savePresetsList(profiles)

            refreshAvailablePresetsList(PresetList)

            PresetList:SetSelection(0)
            PresetList:OnClick(0)
        end

        UIUtil.CreateInputDialog(parent, "<LOC tooltipui0704>Select name for new preset", dialogComplete)
    end

    SaveButton.OnClick = function(self)
        local selectedPreset = PresetList:GetSelection() + 1

        SavePreset(selectedPreset)
        showPresetDetails(selectedPreset, InfoList)
    end

    DeleteButton.OnClick = function(self)
        local profiles = loadPresetsList()

        -- Converting between zero-based indexing in the list and the table indexing...
        table.remove(profiles, PresetList:GetSelection() + 1)

        savePresetsList(profiles)
        refreshAvailablePresetsList(PresetList)

        -- And clear the detail view.
        InfoList:DeleteAllItems()
    end

    -- Called when the selected item in the preset list changes.
    local onListItemChanged = function(self, row)
        showPresetDetails(row + 1, InfoList)
        LoadButton:Enable()
        SaveButton:Enable()
        DeleteButton:Enable()
    end

    -- Because GPG's event model is painfully retarded..
    PresetList.OnKeySelect = onListItemChanged
    PresetList.OnClick = function(self, row, event)
        self:SetSelection(row)
        onListItemChanged(self, row)
    end

    PresetList.OnDoubleClick = function(self, row)
        local settings = loadPreset(row + 1)
        Lobby.ApplyGameSettings(settings)
        presetDialog:Hide()
    end

    -- When the user double-clicks on a metadata field, give them a popup to change its value.
    InfoList.OnDoubleClick = function(self, row)
        -- Closure copy, accounting for zero-based indexing in ItemList.
        local theRow = row + 1

        local nameChanged = function(self, str)
            if str == "" then
                return
            end

            local profiles = loadPresetsList()
            profiles[theRow].Name = str
            savePresetsList(profiles)

            -- Update the name displayed in the presets list, preserving selection.
            local lastselect = PresetList:GetSelection()
            refreshAvailablePresetsList(PresetList)
            PresetList:SetSelection(lastselect)

            showPresetDetails(theRow, InfoList)
        end

        if row == 0 then
            UIUtil.CreateInputDialog(parent, "Rename your preset", nameChanged)
        end
    end

    -- Show the "Double-click to edit" tooltip when the user mouses-over an editable field.
    InfoList.OnMouseoverItem = function(self, row)
        -- Determine which metadata cell they moused-over, if any.
        local metadataType
        -- For now, only name is editable. A nice mechanism to edit game preferences seems plausible.
        if row == 0 then
            metadataType = "Preset name"
        else
            Tooltip.DestroyMouseoverDisplay()
            return
        end

        local tooltip = {
            text = metadataType,
            body = "Double-click to edit"
        }

        Tooltip.CreateMouseoverDisplay(self, tooltip, 0, true)
    end

    refreshAvailablePresetsList(PresetList)
    if PresetList:GetItemCount() == 0 then
        createHelpWindow()
    end
end
