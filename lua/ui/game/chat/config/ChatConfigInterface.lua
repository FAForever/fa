local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatConfigController = import("/lua/ui/game/chat/config/ChatConfigController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- 8 ARGB solid colors selectable as message color swatches.
local Colors = { 'ffffffff', 'ffff4242', 'ffefff42', 'ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb', 'ffff9f42' }

local ColorDefs = {
    { key = 'all_color', text = "All" },
    { key = 'allies_color', text = "Allies" },
    { key = 'priv_color', text = "Private" },
    { key = 'link_color', text = "Links" },
    { key = 'notify_color', text = "Notify" },
}

local CheckboxDefs = {
    { key = 'send_type', text = "Default recipient: allies" },
    { key = 'feed_background', text = "Show feed background" },
    { key = 'feed_persist', text = "Persist feed timeout" },
    { key = 'links', text = "Show camera links" },
}

-------------------------------------------------------------------------------
--  Window class

---@class UIChatConfigColorRow
---@field label Text
---@field combo BitmapCombo
---@field key   string

---@class UIChatConfigInterface : Window
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
---@field BtnApply       Button
---@field BtnReset       Button
---@field BtnOk          Button
---@field BtnCancel      Button
local ChatConfigInterface = ClassUI(Window) {

    ---@param self UIChatConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "Chat Configuration", false, false, false, true, false, "chat_config_v7", {
            Left = 200, Top = 200, Right = 524, Bottom = 640,
        })

        local client = self:GetClientGroup()

        -- ---- Color rows ----
        self.LabelColors = UIUtil.CreateText(client, "Message Colors", 12, UIUtil.titleFont)

        self.ColorRows = {}
        for i, def in ipairs(ColorDefs) do
            local row = {
                label = UIUtil.CreateText(client, def.text, 10, UIUtil.bodyFont),
                combo = BitmapCombo(client, Colors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01"),
                key   = def.key,
            }
            local key = def.key
            row.combo.OnClick = function(_, index)
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
        self.SliderFontSize = IntegerSlider(client, false, 12, 18, 1, unpack(sliderBitmaps))
        self.SliderFontSize.OnValueSet = function(_, value)
            ChatConfigController.SetOption('font_size', value)
        end
        self.SliderFontSize.OnValueChanged = function(_, value)
            self.LabelFontSize:SetText(string.format("Font Size: %d", value))
        end

        self.LabelFadeTime = UIUtil.CreateText(client, "Fade Time: 15s", 10, UIUtil.bodyFont)
        self.SliderFadeTime = IntegerSlider(client, false, 5, 30, 1, unpack(sliderBitmaps))
        self.SliderFadeTime.OnValueSet = function(_, value)
            ChatConfigController.SetOption('fade_time', value)
        end
        self.SliderFadeTime.OnValueChanged = function(_, value)
            self.LabelFadeTime:SetText(string.format("Fade Time: %ds", value))
        end

        self.LabelWinAlpha = UIUtil.CreateText(client, "Window Alpha: 100%", 10, UIUtil.bodyFont)
        self.SliderWinAlpha = IntegerSlider(client, false, 20, 100, 1, unpack(sliderBitmaps))
        self.SliderWinAlpha.OnValueSet = function(_, value)
            ChatConfigController.SetOption('win_alpha', value / 100)
        end
        self.SliderWinAlpha.OnValueChanged = function(_, value)
            self.LabelWinAlpha:SetText(string.format("Window Alpha: %d%%", value))
        end

        -- ---- Checkboxes ----
        self.LabelBehavior = UIUtil.CreateText(client, "Behavior", 12, UIUtil.titleFont)

        self.Checkboxes = {}
        for i, def in ipairs(CheckboxDefs) do
            local cb = UIUtil.CreateCheckbox(client, '/dialogs/check-box_btn/', def.text, true)
            local key = def.key
            cb.OnCheck = function(_, checked)
                ChatConfigController.SetOption(key, checked)
            end
            self.Checkboxes[i] = cb
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
        local model = ChatConfigModel.GetSingleton()
        model.Pending.OnDirty = function(lv)
            self:RefreshFromOptions(lv())
        end
        self:RefreshFromOptions(model.Pending())
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
            Layouter(row.label)
                :Below(prev, 6)
                :AtLeftIn(client, pad)
                :End()

            Layouter(row.combo)
                :RightOf(row.label, 8)
                :AtVerticalCenterIn(row.label)
                :Width(60)
                :End()

            prev = row.label
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

        -- Fit the window height to its content
        self.Bottom:Set(function() return self.BtnCancel.Bottom() + 16 end)

        Layouter(self)
            :Width(300)
            :End()
    end,

    --- Syncs every control to reflect the given options table.
    ---@param self UIChatConfigInterface
    ---@param options UIChatOptions
    RefreshFromOptions = function(self, options)
        for _, row in ipairs(self.ColorRows) do
            row.combo:SetItem(options[row.key] or 1)
        end

        self.SliderFontSize:SetValue(options.font_size or 14)
        self.SliderFadeTime:SetValue(options.fade_time or 15)
        self.SliderWinAlpha:SetValue(math.floor((options.win_alpha or 1.0) * 100))

        for i, def in ipairs(CheckboxDefs) do
            -- treat absent value as the default (send_type/feed_background default false, the rest true)
            local value = options[def.key]
            if value == nil then
                value = (def.key == 'feed_persist' or def.key == 'links')
            end
            self.Checkboxes[i]:SetCheck(value, true)
        end
    end,

    OnClose = function(self)
        import("/lua/ui/game/chat/config/ChatConfigInterface.lua").Close()
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
        -- Remove the reactive subscription before destroying to avoid stale callbacks.
        ChatConfigModel.GetSingleton().Pending.OnDirty = nil

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

    LOG(__moduleinfo.name .. " is dirty, re-importing...")
    ForkThread(
        function()
            WaitSeconds(0.1)
            local module = import(__moduleinfo.name)
            module.Open()
        end
    )
end

--#endregion
