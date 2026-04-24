local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- 8 ARGB solid colors selectable as message color swatches.
local Colors = { 'ffffffff', 'ffff4242', 'ffefff42', 'ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb', 'ffff9f42' }

local ColorDefs = {
    { Key = ChatConfigModel.KeyAllColor,    Text = "All" },
    { Key = ChatConfigModel.KeyAlliesColor, Text = "Allies" },
    { Key = ChatConfigModel.KeyPrivColor,   Text = "Private" },
    { Key = ChatConfigModel.KeyLinkColor,   Text = "Links" },
    { Key = ChatConfigModel.KeyNotifyColor, Text = "Notify" },
}

local CheckboxDefs = {
    { Key = ChatConfigModel.KeySendType,       Text = "Default recipient: allies" },
    { Key = ChatConfigModel.KeyFeedBackground, Text = "Show feed background" },
    { Key = ChatConfigModel.KeyFeedPersist,    Text = "Persist feed timeout" },
    { Key = ChatConfigModel.KeyLinks,          Text = "Show camera links" },
}

-------------------------------------------------------------------------------
--  Window class

---@class UIChatConfigColorRow
---@field Label Text
---@field Combo BitmapCombo
---@field Key   string

---@class UIChatConfigMuteRow
---@field Checkbox Checkbox
---@field ArmyID   number

---@class UIChatConfigInterface : Window
---@field Trash          TrashBag                          # owns every derived subscription-LazyVar
---@field LabelColors    Text
---@field ColorRows      UIChatConfigColorRow[]
---@field LabelFontSize  Text
---@field SliderFontSize IntegerSlider
---@field LabelFadeTime  Text
---@field SliderFadeTime IntegerSlider
---@field LabelWinAlpha  Text
---@field SliderWinAlpha IntegerSlider
---@field LabelBehavior  Text
---@field Checkboxes     Checkbox[]
---@field LabelMuted     Text
---@field MuteRows       UIChatConfigMuteRow[]
---@field BtnApply       Button
---@field BtnReset       Button
---@field BtnOk          Button
---@field BtnCancel      Button
---@field PendingObserver LazyVar<UIChatOptions>  # derived from ChatConfigModel.Pending
local ChatConfigInterface = ClassUI(Window) {

    ---@param self UIChatConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "Chat Configuration", false, false, false, true, false, "chat_config_v7", {
            Left = 200, Top = 200, Right = 500, Bottom = 640,
        })

        -- Single trash bag for everything we allocate that needs explicit
        -- destruction — currently just the derived observer LazyVars.
        -- Emptied in `OnDestroy`.
        self.Trash = TrashBag()

        local client = self:GetClientGroup()

        -- ---- Color rows ----
        self.LabelColors = UIUtil.CreateText(client, "Message Colors", 12, UIUtil.titleFont)

        self.ColorRows = {}
        for i, def in ipairs(ColorDefs) do
            local row = {
                Label = UIUtil.CreateText(client, def.Text, 10, UIUtil.bodyFont),
                Combo = BitmapCombo(client, Colors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01"),
                Key   = def.Key,
            }
            local key = def.Key
            row.Combo.OnClick = function(_, index)
                ChatConfigController.SetOption(key, index)
            end
            self.ColorRows[i] = row
        end

        -- ---- Sliders ----
        local sliderBitmaps = {
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
            UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'),
        }

        self.LabelFontSize = UIUtil.CreateText(client, "Font Size: 14", 10, UIUtil.bodyFont)
        self.SliderFontSize = IntegerSlider(client, false,
            ChatConfigModel.FontSizeRange.Min,
            ChatConfigModel.FontSizeRange.Max,
            ChatConfigModel.FontSizeRange.Inc,
            unpack(sliderBitmaps))
        self.SliderFontSize.OnValueSet = function(_, value)
            ChatConfigController.SetOption(ChatConfigModel.KeyFontSize, value)
        end
        self.SliderFontSize.OnValueChanged = function(_, value)
            self.LabelFontSize:SetText(string.format("Font Size: %d", value))
        end

        self.LabelFadeTime = UIUtil.CreateText(client, "Fade Time: 15s", 10, UIUtil.bodyFont)
        self.SliderFadeTime = IntegerSlider(client, false,
            ChatConfigModel.FadeTimeRange.Min,
            ChatConfigModel.FadeTimeRange.Max,
            ChatConfigModel.FadeTimeRange.Inc,
            unpack(sliderBitmaps))
        self.SliderFadeTime.OnValueSet = function(_, value)
            ChatConfigController.SetOption(ChatConfigModel.KeyFadeTime, value)
        end
        self.SliderFadeTime.OnValueChanged = function(_, value)
            self.LabelFadeTime:SetText(string.format("Fade Time: %ds", value))
        end

        self.LabelWinAlpha = UIUtil.CreateText(client, "Window Alpha: 100%", 10, UIUtil.bodyFont)
        self.SliderWinAlpha = IntegerSlider(client, false,
            ChatConfigModel.WinAlphaSliderRange.Min,
            ChatConfigModel.WinAlphaSliderRange.Max,
            ChatConfigModel.WinAlphaSliderRange.Inc,
            unpack(sliderBitmaps))
        self.SliderWinAlpha.OnValueSet = function(_, value)
            ChatConfigController.SetOption(ChatConfigModel.KeyWinAlpha, value / 100)
        end
        self.SliderWinAlpha.OnValueChanged = function(_, value)
            self.LabelWinAlpha:SetText(string.format("Window Alpha: %d%%", value))
        end

        -- ---- Checkboxes ----
        self.LabelBehavior = UIUtil.CreateText(client, "Behavior", 12, UIUtil.titleFont)

        self.Checkboxes = {}
        for i, def in ipairs(CheckboxDefs) do
            local cb = UIUtil.CreateCheckbox(client, '/dialogs/check-box_btn/', def.Text, true)
            local key = def.Key
            cb.OnCheck = function(_, checked)
                ChatConfigController.SetOption(key, checked)
            end
            self.Checkboxes[i] = cb
        end

        -- ---- Muted players ----
        -- One checkbox per non-civilian army other than the local player.
        -- The list is captured at dialog-open time; closing and reopening the
        -- dialog rebuilds against fresh session state.
        self.LabelMuted = UIUtil.CreateText(client, "Muted players", 12, UIUtil.titleFont)

        self.MuteRows = {}
        local armies = GetArmiesTable()
        local focusArmy = armies and armies.focusArmy or -1
        if armies and armies.armiesTable then
            for armyID, army in armies.armiesTable do
                if not army.civilian and armyID ~= focusArmy and army.nickname then
                    local id = armyID
                    local cb = UIUtil.CreateCheckbox(client, '/dialogs/check-box_btn/', army.nickname, true)
                    cb.OnCheck = function(_, checked)
                        ChatConfigController.SetMuted(id, checked)
                    end
                    table.insert(self.MuteRows, { Checkbox = cb, ArmyID = id })
                end
            end
        end

        -- ---- Buttons ----
        self.BtnApply = UIUtil.CreateButtonStd(client, '/widgets02/small', "Apply", 14)
        self.BtnApply.OnClick = function() ChatConfigController.Apply() end

        self.BtnReset = UIUtil.CreateButtonStd(client, '/widgets02/small', "Reset", 14)
        self.BtnReset.OnClick = function() ChatConfigController.Reset() end

        self.BtnOk = UIUtil.CreateButtonStd(client, '/widgets02/small', "OK", 14)
        self.BtnOk.OnClick = function()
            ChatConfigController.Apply()
            import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Close()
        end

        self.BtnCancel = UIUtil.CreateButtonStd(client, '/widgets02/small', "Cancel", 14)
        self.BtnCancel.OnClick = function()
            ChatConfigController.Cancel()
            import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Close()
        end

        -- ---- Reactive: sync all controls whenever pending options change ----
        -- `LazyVarDerive` gives us a fresh per-subscriber LazyVar so we don't
        -- stomp other subscribers on Pending (see the chat CLAUDE.md).
        local model = ChatConfigModel.GetSingleton()
        self.PendingObserver = self.Trash:Add(
            LazyVarDerive(
                model.Pending,
                function(lv)
                    self:RefreshFromOptions(lv()
                    )
                end
            )
        )
    end,

    ---@param self UIChatConfigInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()
        local pad = 8

        -- Colors section header
        Layouter(self.LabelColors)
            :AtLeftTopIn(client, pad, pad)
            :End()

        -- Color rows: label left, combo to its right
        ---@type Control
        local prev = self.LabelColors
        for _, row in ipairs(self.ColorRows) do
            Layouter(row.Label)
                :Below(prev, 6)
                :AtLeftIn(client, pad)
                :End()

            Layouter(row.Combo)
                :RightOf(row.Label, 8)
                :AtVerticalCenterIn(row.Label)
                :Width(60)
                :End()

            prev = row.Label
        end

        -- Sliders
        Layouter(self.LabelFontSize)
            :Below(prev, 12)
            :AtLeftIn(client, pad)
            :End()

        Layouter(self.SliderFontSize)
            :Below(self.LabelFontSize, 4)
            :AtLeftIn(client, pad)
            :Width(200)
            :End()

        Layouter(self.LabelFadeTime)
            :Below(self.SliderFontSize, 8)
            :AtLeftIn(client, pad)
            :End()

        Layouter(self.SliderFadeTime)
            :Below(self.LabelFadeTime, 4)
            :AtLeftIn(client, pad)
            :Width(200)
            :End()

        Layouter(self.LabelWinAlpha)
            :Below(self.SliderFadeTime, 8)
            :AtLeftIn(client, pad)
            :End()

        Layouter(self.SliderWinAlpha)
            :Below(self.LabelWinAlpha, 4)
            :AtLeftIn(client, pad)
            :Width(200)
            :End()

        -- Behavior section header
        Layouter(self.LabelBehavior)
            :Below(self.SliderWinAlpha, 12)
            :AtLeftIn(client, pad)
            :End()

        -- Checkboxes
        prev = self.LabelBehavior
        for _, cb in ipairs(self.Checkboxes) do
            Layouter(cb)
                :Below(prev, 6)
                :AtLeftIn(client, pad)
                :End()
            prev = cb
        end

        -- Muted players section
        Layouter(self.LabelMuted)
            :Below(prev, 12)
            :AtLeftIn(client, pad)
            :End()

        prev = self.LabelMuted
        for _, row in ipairs(self.MuteRows) do
            Layouter(row.Checkbox)
                :Below(prev, 6)
                :AtLeftIn(client, pad)
                :End()
            prev = row.Checkbox
        end

        -- Buttons: Apply | Reset on one row, OK | Cancel on the next
        Layouter(self.BtnApply)
            :Below(prev, 12)
            :AtLeftIn(client, pad)
            :End()

        Layouter(self.BtnReset)
            :RightOf(self.BtnApply, 4)
            :AtVerticalCenterIn(self.BtnApply)
            :End()

        Layouter(self.BtnOk)
            :Below(self.BtnApply, 4)
            :AtLeftIn(client, pad)
            :End()

        Layouter(self.BtnCancel)
            :RightOf(self.BtnOk, 4)
            :AtVerticalCenterIn(self.BtnOk)
            :End()

        -- Fit the window height to its content. Width stays driven by
        -- Left/Right from the default rect — don't pin Width here, or the
        -- drag handler's Right:Set(Left + Width) will snap the window to
        -- whatever Width was pinned to (the textures render against Right,
        -- so a Width/Right mismatch is invisible until the first drag).
        self.Bottom:Set(function() return self.BtnCancel.Bottom() + 16 end)
    end,

    --- Syncs every control to reflect the given options table.
    ---@param self UIChatConfigInterface
    ---@param options UIChatOptions
    RefreshFromOptions = function(self, options)
        local defaults = ChatConfigModel.GetDefaults()

        for _, row in ipairs(self.ColorRows) do
            row.Combo:SetItem(options[row.Key] or defaults[row.Key])
        end

        self.SliderFontSize:SetValue(options.font_size or defaults.font_size)
        self.SliderFadeTime:SetValue(options.fade_time or defaults.fade_time)
        self.SliderWinAlpha:SetValue(math.floor((options.win_alpha or defaults.win_alpha) * 100))

        for i, def in ipairs(CheckboxDefs) do
            local value = options[def.Key]
            if value == nil then
                value = defaults[def.Key]
            end
            self.Checkboxes[i]:SetCheck(value, true)
        end

        local muted = options.muted or {}
        for _, row in ipairs(self.MuteRows) do
            row.Checkbox:SetCheck(muted[row.ArmyID] == true, true)
        end
    end,

    OnClose = function(self)
        import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Close()
    end,

    --- Empties our trash bag so every derived observer we allocated is
    --- destroyed — no `OnDirty` can fire into a torn-down `self`.
    ---@param self UIChatConfigInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points

---@type UIChatConfigInterface | nil
local Instance = nil

--- Opens the config dialog, creating it if it does not exist yet.
function Open()
    if Instance then
        Instance:Show()
        return
    end

    Instance = ChatConfigInterface(GetFrame(0))
end

--- Closes and destroys the config dialog.
function Close()
    if Instance then
        -- `OnDestroy` empties the trash bag, which in turn destroys every
        -- derived observer — no more `OnDirty` fires into a dead `self`.
        Instance:Destroy()
        Instance = nil
    end
end

--- Toggles the config dialog open or closed.
function Toggle()
    if Instance then
        Close()
    else
        Open()
    end
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        newModule.Open()
    end
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    if Instance then
        Instance:Destroy()
        Instance = nil
    end

    ForkThread(
        function()
            WaitFrames(2)
            local module = import(__moduleinfo.name)
            module.Open()
        end
    )
end

--#endregion
