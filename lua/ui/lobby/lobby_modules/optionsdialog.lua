--*****************************************************************************
--* File: lua/ui/lobby/optionsdialog.lua
--* Summary: Game-option display formatting and the lobby "Settings" dialog,
--*          extracted from lobby.lua for maintainability.
--*
--* Note: RefreshOptionDisplayData rebuilds the formatted-option tables that the
--*       OptionContainer UI (still in lobby.lua) reads. Because the tables are
--*       reassigned on every refresh, lobby.lua reads them through the
--*       GetFormattedOptions()/GetNonDefaultFormattedOptions() accessors rather
--*       than holding a stale reference.
--*****************************************************************************


-- Upvalues injected by lobby.lua via OptionsDialog.Init()
local gameInfo
local GUI
local MapUtil
local Mods
local singlePlayer
local AddChatText
local Group
local Popup
local LayoutHelpers
local UIUtil
local Prefs
local RadioButton
local Slider
local Tooltip
local RefreshLobbyBackground
local SetWindowedLobby
local defaultMode

-- Formatted option lists, owned by this module and rebuilt by
-- RefreshOptionDisplayData(). Read by lobby.lua via the accessors below.
local formattedOptions = {}
local nonDefaultFormattedOptions = {}

function Init(deps)
    gameInfo               = deps.gameInfo
    GUI                    = deps.GUI
    MapUtil                = deps.MapUtil
    Mods                   = deps.Mods
    singlePlayer           = deps.singlePlayer
    AddChatText            = deps.AddChatText
    Group                  = deps.Group
    Popup                  = deps.Popup
    LayoutHelpers          = deps.LayoutHelpers
    UIUtil                 = deps.UIUtil
    Prefs                  = deps.Prefs
    RadioButton            = deps.RadioButton
    Slider                 = deps.Slider
    Tooltip                = deps.Tooltip
    RefreshLobbyBackground = deps.RefreshLobbyBackground
    SetWindowedLobby       = deps.SetWindowedLobby
    defaultMode            = deps.defaultMode
end

function GetFormattedOptions()
    return formattedOptions
end

function GetNonDefaultFormattedOptions()
    return nonDefaultFormattedOptions
end

function RefreshOptionDisplayData(scenarioInfo)
    local globalOpts = import("/lua/ui/lobby/lobbyoptions.lua").globalOpts
    local teamOptions = import("/lua/ui/lobby/lobbyoptions.lua").teamOptions
    local AIOpts = import("/lua/ui/lobby/lobbyoptions.lua").AIOpts
    if not scenarioInfo and gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    end
    formattedOptions = {}
    nonDefaultFormattedOptions = {}

    -- Show a summary of the number of active mods.
    local modStr = false
    local modNum = table.getn(Mods.GetGameMods(gameInfo.GameMods)) or 0
    local modNumUI = table.getn(Mods.GetUiMods()) or 0
    if modNum > 0 and modNumUI > 0 then
        modStr = modNum..' Mods (and '..modNumUI..' UI Mods)'
        if modNum == 1 and modNumUI > 1 then
            modStr = modNum..' Mod (and '..modNumUI..' UI Mods)'
        elseif modNum > 1 and modNumUI == 1 then
            modStr = modNum..' Mods (and '..modNumUI..' UI Mod)'
        elseif modNum == 1 and modNumUI == 1 then
            modStr = modNum..' Mod (and '..modNumUI..' UI Mod)'
        else
            modStr = modNum..' Mods (and '..modNumUI..' UI Mods)'
        end
    elseif modNum > 0 and modNumUI == 0 then
        modStr = modNum..' Mods'
        if modNum == 1 then
            modStr = modNum..' Mod'
        end
    elseif modNum == 0 and modNumUI > 0 then
        modStr = modNumUI..' UI Mods'
        if modNum == 1 then
            modStr = modNumUI..' UI Mod'
        end
    end

    local description = "No mods enabled."

    if modNum + modNumUI > 0 then
        description = ""

        local descriptionSimMods = { "", }
        if modNum > 0 then
            table.insert(descriptionSimMods, LOC("<LOC enabled_sim_mods>The host enabled the following sim mods:"))
            for k, mod in Mods.GetGameMods() do
                table.insert(descriptionSimMods, "\r\n - " .. tostring(mod.name))
            end

            table.insert(descriptionSimMods, "\r\n")
        end

        local descriptionUIMods = { "", }
        if modNumUI > 0 then
            table.insert(descriptionUIMods, LOC("<LOC enabled_ui_mods>You have enabled the following UI mods:"))
            for k, mod in Mods.GetUiMods() do
                table.insert(descriptionUIMods, "\r\n - " .. tostring(mod.name))
            end
        end

        descriptionSimMods = tostring(table.concat(descriptionSimMods))
        descriptionUIMods = tostring(table.concat(descriptionUIMods))

        if modNum > 0 and modNumUI > 0 then
            description = tostring(table.concat({descriptionSimMods, "\r\n", descriptionUIMods}))
        else
            if modNum > 0 then
                description = descriptionSimMods
            end

            if modNumUI > 0 then
                description = descriptionUIMods
            end
        end
    end

    if modStr then
        local option = {
            text = modStr,
            value = LOC('<LOC lobby_0003>Check Mod Manager'),
            mod = true,

            manualTooltipTitle = 'Enabled mods',
            manualTooltipDescription = description
        }

        table.insert(formattedOptions, option)
        table.insert(nonDefaultFormattedOptions, option)
    end

    -- Update the unit restrictions display.
    if gameInfo.GameOptions.RestrictedCategories ~= nil then
        local restrNum = table.getn(gameInfo.GameOptions.RestrictedCategories)
        if restrNum ~= 0 then
            local restrictLabel
            if restrNum == 1 then -- just 1
                restrictLabel = LOC("<LOC lobui_0415>1 Build Restriction")
            else
                restrictLabel = LOCF("<LOC lobui_0414>%d Build Restrictions", restrNum)
            end

            local option = {
                text = restrictLabel,
                value = LOC("<LOC lobui_0416>Check Unit Manager"),
                mod = true,
                tooltip = 'Lobby_BuildRestrict_Option',
                valueTooltip = 'Lobby_BuildRestrict_Option'
            }

            table.insert(formattedOptions, option)
            table.insert(nonDefaultFormattedOptions, option)
        end
    end

    -- Add an option to the formattedOption lists
    local function addFormattedOption(optData, gameOption)
        -- Don't show multiplayer-only options in single-player
        if optData.mponly and singlePlayer then
            return
        end

        -- Don't bother for options with only one value. These are usually someone trying to do
        -- something clever with a mod or such, not "real" options we care about.
        if table.getn(optData.values) <= 1 then
            return
        end

        local option = {
            text = optData.label,
            tooltip = { text = optData.label, body = optData.help }
        }

        -- Options are stored as keys from the values array in optData. We want to display the
        -- descriptive string in the UI, so let's go dig it out.

        -- Scan the values array to find the one with the key matching our value for that option.
        for k, val in optData.values do
            local key = val.key or val

            if key == gameOption then
                option.key = key
                option.value = val.text or optData.value_text
                option.valueTooltip = {text = optData.label, body = val.help or optData.value_help}

                table.insert(formattedOptions, option)

                -- Add this option to the non-default set for the UI.
                if k ~= optData.default then
                    table.insert(nonDefaultFormattedOptions, option)
                end

                break
            end
        end
    end

    local function addOptionsFrom(optionObject)
        for index, optData in optionObject do
            local gameOption = gameInfo.GameOptions[optData.key]
            addFormattedOption(optData, gameOption)
        end
    end

    -- Add the core options to the formatted option lists
    addOptionsFrom(globalOpts)
    addOptionsFrom(teamOptions)
    addOptionsFrom(AIOpts)

    -- Add options from the scenario object, if any are provided.
    if scenarioInfo.options then
        if not MapUtil.ValidateScenarioOptions(scenarioInfo.options, true) then
            AddChatText(LOC('<LOC lobui_0397>The options included in this map specified invalid defaults. See moholog for details.'))
            AddChatText(LOC('<LOC lobui_0398>An arbitrary option has been selected for now: check the game options screen!'))
        end

        for index, optData in scenarioInfo.options do
            addFormattedOption(optData, gameInfo.GameOptions[optData.key])
        end
    end

    GUI.OptionContainer:CalcVisible()
end

function ShowLobbyOptionsDialog()
    local dialogContent = Group(GUI)
    LayoutHelpers.SetDimensions(dialogContent, 420, 310)

    local dialog = Popup(GUI, dialogContent)
    GUI.lobbyOptionsDialog = dialog

    local buttons = {
        {
            label = LOC("<LOC lobui_0406>") -- Factions
        },
        {
            label = LOC("<LOC lobui_0407>")  -- Concept art
        },
        {
            label = LOC("<LOC lobui_0408>") -- Screenshot
        },
        {
            label = LOC("<LOC lobui_0409>") -- Map
        },
        {
            label = LOC("<LOC lobui_0410>") -- None
        }
    }

    -- Label shown above the background mode selection radiobutton.
    local backgroundLabel = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0405> "), 16, 'Arial', true)
    local selectedBackgroundState = Prefs.GetFromCurrentProfile("LobbyBackground") or 1
    local backgroundRadiobutton = RadioButton(dialogContent, '/RADIOBOX/', buttons, selectedBackgroundState, false, true)

    LayoutHelpers.AtLeftTopIn(backgroundLabel, dialogContent, 15, 15)
    LayoutHelpers.AtLeftTopIn(backgroundRadiobutton, dialogContent, 15, 40)

    backgroundRadiobutton.OnChoose = function(self, index, key)
        Prefs.SetToCurrentProfile("LobbyBackground", index)
        RefreshLobbyBackground()
    end
    -- label for displaying chat font size
    local currentFontSize = Prefs.GetFromCurrentProfile('LobbyChatFontSize') or 14
    local slider_Chat_SizeFont_TEXT = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0404> ").. currentFontSize, 14, 'Arial', true)
    LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont_TEXT, dialogContent, 27, 162)

    -- slider for changing chat font size
    local slider_Chat_SizeFont = Slider(dialogContent, false, 9, 20,
        UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
        UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
        UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))
        LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont, dialogContent, 20, 182)
    slider_Chat_SizeFont:SetValue(currentFontSize)
    slider_Chat_SizeFont.OnValueChanged = function(self, newValue)
        local isScrolledDown = GUI.chatPanel:IsScrolledToBottom()

        local sliderValue = math.floor(self._currentValue())
        slider_Chat_SizeFont_TEXT:SetText(LOC("<LOC lobui_0404> ").. sliderValue)

        Prefs.SetToCurrentProfile('LobbyChatFontSize', sliderValue)
        -- updating chat panel with new font size
        GUI.chatPanel:SetFont(nil, sliderValue)

        if isScrolledDown then
            GUI.chatPanel:ScrollToBottom()
        end
    end
    if true then
        --snowflakes count
        local currentSnowFlakesCount = Prefs.GetFromCurrentProfile('SnowFlakesCount') or 100
        local slider_SnowFlakes_Count_TEXT = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0447>Snowflakes count").. currentSnowFlakesCount, 14, 'Arial', true)
        LayoutHelpers.AtRightTopIn(slider_SnowFlakes_Count_TEXT, dialogContent, 27, 202)

        -- slider for changing chat font size
        local slider_SnowFlakes_Count = Slider(dialogContent, false, 100, 1000,
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))
            LayoutHelpers.AtRightTopIn(slider_SnowFlakes_Count, dialogContent, 20, 222)
        slider_SnowFlakes_Count:SetValue(currentSnowFlakesCount)
        slider_SnowFlakes_Count.OnValueChanged = function(self, newValue)
            local sliderValue = math.floor(newValue)
            slider_SnowFlakes_Count_TEXT:SetText(LOC("<LOC lobui_0447>Snowflakes count").. sliderValue)
            Prefs.SetToCurrentProfile('SnowFlakesCount', sliderValue)
            import("/lua/ui/events/snowflake.lua").Clear()
            import("/lua/ui/events/snowflake.lua").CreateSnowFlakes(GUI, sliderValue)
        end
    end


    --
    local cbox_WindowedLobby = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0402>Windowed mode"))
    LayoutHelpers.AtRightTopIn(cbox_WindowedLobby, dialogContent, 20, 42)
    Tooltip.AddCheckboxTooltip(cbox_WindowedLobby, {text=LOC('<LOC lobui_0402>Windowed mode'), body=LOC("<LOC lobui_0403>")})
    cbox_WindowedLobby.OnCheck = function(self, checked)
        local option
        if checked then
            option = 'true'
        else
            option = 'false'
        end
        Prefs.SetToCurrentProfile('WindowedLobby', option)
        SetWindowedLobby(checked)
    end
    --
    local cbox_StretchBG = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0400>Stretch Background"))
    LayoutHelpers.AtRightTopIn(cbox_StretchBG, dialogContent, 20, 68)
    Tooltip.AddCheckboxTooltip(cbox_StretchBG, {text=LOC('<LOC lobui_0400>Stretch Background'), body=LOC("<LOC lobui_0401>")})
    cbox_StretchBG.OnCheck = function(self, checked)
        if checked then
            Prefs.SetToCurrentProfile('LobbyBackgroundStretch', 'true')
        else
            Prefs.SetToCurrentProfile('LobbyBackgroundStretch', 'false')
        end
        RefreshLobbyBackground()
    end

    local cbox_FactionFontColor = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0411>Faction Font Color"))
    LayoutHelpers.AtRightTopIn(cbox_FactionFontColor, dialogContent, 20, 94)
    cbox_FactionFontColor.OnCheck = function(self, checked)
        if checked then
            Prefs.SetOption('faction_font_color', true)
        else
            Prefs.SetOption('faction_font_color', false)
        end
        UIUtil.UpdateCurrentSkin()
    end

    local cbox_ChatPlayerColor = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0460>Player color in chat"))
    LayoutHelpers.AtRightTopIn(cbox_ChatPlayerColor, dialogContent, 20, 120)
    cbox_ChatPlayerColor.OnCheck = function(self, checked)
        if checked then
            Prefs.SetToCurrentProfile('ChatPlayerColor', true)
        else
            Prefs.SetToCurrentProfile('ChatPlayerColor', false)
        end
    end

    -- Quit button
    local QuitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', LOC("<LOC _Close>Close"))
    LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialogContent, 0)
    LayoutHelpers.AtBottomIn(QuitButton, dialogContent, 10)

    QuitButton.OnClick = function(self)
        dialog:Hide()
    end
    --
    local WindowedLobby = Prefs.GetFromCurrentProfile('WindowedLobby') or 'true'
    cbox_WindowedLobby:SetCheck(WindowedLobby == 'true', true)
    if defaultMode == 'windowed' then
        -- Already set Windowed in Game
        cbox_WindowedLobby:Disable()
    end
    --
    local lobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    cbox_StretchBG:SetCheck(lobbyBackgroundStretch == 'true', true)
    --
    local factionFontColor = Prefs.GetOption('faction_font_color')
    cbox_FactionFontColor:SetCheck(factionFontColor == true, true)

    local chatPlayerColor = Prefs.GetFromCurrentProfile('ChatPlayerColor')
    cbox_ChatPlayerColor:SetCheck(chatPlayerColor == true or chatPlayerColor == nil, true)
end

