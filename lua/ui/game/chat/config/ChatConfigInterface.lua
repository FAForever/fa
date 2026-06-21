local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Window = import("/lua/maui/window.lua").Window
local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

--- Generic `panel_brd_*` chrome rather than the chat window's bespoke
--- art (the two dialogs are different sizes).
---@diagnostic disable: param-type-mismatch
local WindowTextures = {
    tl          = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
    tr          = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
    tm          = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
    ml          = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
    m           = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
    mr          = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
    bl          = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
    bm          = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
    br          = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
    borderColor = 'ff415055',
}
---@diagnostic enable: param-type-mismatch

-- Same `chat_color` tooltip on every colour combo. The per-row label
-- already names the recipient, so the tooltip just explains the control.
local ColorDefs = {
    { Key = ChatConfigModel.KeyAllColor,    Text = "All",     Tooltip = 'chat_color' },
    { Key = ChatConfigModel.KeyAlliesColor, Text = "Allies",  Tooltip = 'chat_color' },
    { Key = ChatConfigModel.KeyPrivColor,   Text = "Private", Tooltip = 'chat_color' },
    { Key = ChatConfigModel.KeyLinkColor,   Text = "Links",   Tooltip = 'chat_color' },
    { Key = ChatConfigModel.KeyNotifyColor, Text = "Notify",  Tooltip = 'chat_color' },
}

local CheckboxDefs = {
    { Key = ChatConfigModel.KeySendType,       Text = "Default recipient: allies", Tooltip = 'chat_send_type' },
    { Key = ChatConfigModel.KeyFeedBackground, Text = "Show feed background",      Tooltip = 'chat_feed_background' },
    { Key = ChatConfigModel.KeyLinks,          Text = "Show camera links",         Tooltip = 'chat_filter' },
}

-------------------------------------------------------------------------------
--  Window class

--- One label-plus-bitmap-combo row in the colour section; `Key` is the option this row writes.
---@class UIChatConfigColorRow
---@field Label Text
---@field Combo BitmapCombo
---@field Key   string

--- One per-player mute row; the checkbox writes the `muted[ArmyID]` entry on the Pending options.
---@class UIChatConfigMuteRow
---@field Checkbox Checkbox
---@field ArmyID   number

--- Chat options dialog: edits a draft (`Pending`) and commits via Apply; nothing here writes the model directly.
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
---@field DragTL         Bitmap                  # decorative top-left corner grip
---@field DragTR         Bitmap                  # decorative top-right corner grip
---@field DragBL         Bitmap                  # decorative bottom-left corner grip
---@field DragBR         Bitmap                  # decorative bottom-right corner grip
---@field PendingObserver LazyVar<UIChatOptions>  # derived from ChatConfigModel.Pending
---@field DebugBG?       Bitmap                  # semi-transparent overlay shown when `Debug` is true
local ChatConfigInterface = ClassUI(Window) {

    ---@param self UIChatConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "Chat Configuration", false, false, false, true, false, "chat_config_v7", {
            Left = 200, Top = 200, Right = 500, Bottom = 640,
        }, WindowTextures)

        self.Trash = TrashBag()

        local client = self:GetClientGroup()

        -- ---- Color rows ----
        self.LabelColors = UIUtil.CreateText(client, "Message Colors", 12, UIUtil.titleFont)

        self.ColorRows = {}
        for i, def in ipairs(ColorDefs) do
            local row = {
                Label = UIUtil.CreateText(client, def.Text, 10, UIUtil.bodyFont),
                Combo = BitmapCombo(client, ChatUtils.ColorPalette, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01"),
                Key   = def.Key,
            }
            local key = def.Key
            row.Combo.OnClick = function(_, index)
                ChatConfigController.SetOption(key, index)
            end
            -- Tooltip on both label and combo so either hover works.
            Tooltip.AddControlTooltip(row.Label, def.Tooltip)
            Tooltip.AddControlTooltip(row.Combo, def.Tooltip)
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
        Tooltip.AddControlTooltip(self.LabelFontSize, 'chat_fontsize')
        Tooltip.AddControlTooltip(self.SliderFontSize, 'chat_fontsize')

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
        Tooltip.AddControlTooltip(self.LabelFadeTime, 'chat_fadetime')
        Tooltip.AddControlTooltip(self.SliderFadeTime, 'chat_fadetime')

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
        Tooltip.AddControlTooltip(self.LabelWinAlpha, 'chat_alpha')
        Tooltip.AddControlTooltip(self.SliderWinAlpha, 'chat_alpha')

        -- ---- Checkboxes ----
        self.LabelBehavior = UIUtil.CreateText(client, "Behavior", 12, UIUtil.titleFont)

        self.Checkboxes = {}
        for i, def in ipairs(CheckboxDefs) do
            local cb = UIUtil.CreateCheckbox(client, '/dialogs/check-box_btn/', def.Text, true)
            local key = def.Key
            cb.OnCheck = function(_, checked)
                ChatConfigController.SetOption(key, checked)
            end
            Tooltip.AddCheckboxTooltip(cb, def.Tooltip)
            self.Checkboxes[i] = cb
        end

        -- ---- Muted players ----
        -- One checkbox per non-civilian army other than the local player.
        -- Captured at dialog-open; closing and reopening rebuilds state.
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
        -- Apply also opens the chat window so the user immediately sees
        -- the result of the tuning they just did.
        self.BtnApply = UIUtil.CreateButtonStd(client, '/widgets02/small', "Apply", 14)
        self.BtnApply.OnClick = function()
            ChatConfigController.Apply()
            import("/lua/ui/game/chat/ChatInterface.lua").Open()
        end

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

        -- ---- Decorative corner grips ----
        -- Pure decoration. `lockSize` is true on this window, so routing
        -- clicks through them would only confuse the title-bar drag.
        self.DragTL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        self.DragTR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        self.DragBL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        self.DragBR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))
        for _, grip in { self.DragTL, self.DragTR, self.DragBL, self.DragBR } do
            grip:DisableHitTest()
        end

        -- ---- Reactive: sync controls when pending options change ----
        local model = ChatConfigModel.GetSingleton()
        self.PendingObserver = self.Trash:Add(
            LazyVarDerive(
                model.Pending,
                function(pendingLazy)
                    local pending = pendingLazy()
                    self:RefreshFromOptions(pending)
                end
            )
        )
    end,

    ---@param self UIChatConfigInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()
        local pad = 8

        Layouter(self.LabelColors)
            :AtLeftTopIn(client, pad, pad)
            :End()

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

        Layouter(self.LabelBehavior)
            :Below(self.SliderWinAlpha, 12)
            :AtLeftIn(client, pad)
            :End()

        prev = self.LabelBehavior
        for _, cb in ipairs(self.Checkboxes) do
            Layouter(cb)
                :Below(prev, 6)
                :AtLeftIn(client, pad)
                :End()
            prev = cb
        end

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

        -- Apply | Reset on one row, OK | Cancel on the next.
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

        -- Don't pin Width here. The drag handler's Right:Set(Left + Width)
        -- would snap to whatever Width got pinned to. Width stays driven
        -- by Left/Right from the default rect.
        local bottomPadScaled = LayoutHelpers.ScaleNumber(16)
        self.Bottom:Set(function() return self.BtnCancel.Bottom() + bottomPadScaled end)

        Layouter(self.DragTL):AtLeftTopIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragTR):AtRightTopIn(self, -22, -8):Over(self, 5):End()
        Layouter(self.DragBL):AtLeftBottomIn(self, -26, -8):Over(self, 5):End()
        Layouter(self.DragBR):AtRightBottomIn(self, -22, -8):Over(self, 5):End()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ff8040')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Syncs every control to the supplied options snapshot. Driven by the Pending observer.
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

    --- Title-bar close button. Mirrors the Cancel button.
    OnClose = function(self)
        -- Discards any Pending draft (re-syncs from Committed) and tears
        -- down the dialog.
        ChatConfigController.Cancel()
        import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Close()
    end,

    --- Destroys derived observers so dangling OnDirty callbacks don't fire into a dead self.
    ---@param self UIChatConfigInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points

--- Singleton handle; nil until `Open` builds the dialog for the first time.
---@type UIChatConfigInterface | nil
local Instance = nil

--- Standalone entry point: shows the config dialog, building it on first open.
function Open()
    -- Always re-syncs `Pending` from `Committed` first so a reopen
    -- reflects the current committed state (including any `SetMutedLive`
    -- writes that landed while the dialog was hidden) instead of a stale
    -- draft from a previous session.
    local Controller = import("/lua/ui/game/chat/config/ChatConfigController.lua")
    Controller.Cancel()
    if Instance then
        Instance:Show()
        return
    end

    -- Dismiss any open map dialog (build/order popup, etc.) and pin our
    -- depth above everything so a later popup can't slide on top of us.
    import("/lua/ui/game/multifunction.lua").CloseMapDialog()
    Instance = ChatConfigInterface(GetFrame(0))
    Instance.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
end

--- Standalone entry point: tears down the dialog if it exists.
function Close()
    if Instance then
        Instance:Destroy()
        Instance = nil
    end
end

--- Standalone entry point: flips visibility, building the dialog if needed.
function Toggle()
    if Instance then
        Close()
    else
        Open()
    end
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: reopens the dialog on the freshly loaded module if it was open.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        newModule.Open()
    end
end

--- Hot-reload hook: tears down the old instance and re-imports this module.
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
