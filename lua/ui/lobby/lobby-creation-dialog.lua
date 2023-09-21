
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local Prefs = import("/lua/user/prefs.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local function CreateEditField(parent)
    local control = Edit(parent)
    control:SetForegroundColor(UIUtil.fontColor)
    control:SetHighlightForegroundColor(UIUtil.highlightColor)
    control:SetHighlightBackgroundColor("880085EF")
    control.Height:Set(function() return control:GetFontHeight() end)
    LayoutHelpers.SetWidth(control, 250)
    control:SetFont(UIUtil.bodyFont, 16)
    return control
end

---@class UILobbyCreationDialog : Group
---@field OnAcceptCallbacks table<string, fun(name: string, port: string)>
---@field OnCancelCallbacks table<string, fun()>
---@field ValidPorts table<number, boolean>
---@field Panel Bitmap
---@field PanelShadow Bitmap
---@field PanelBrackets Group
---@field PanelTitle Text
---@field ButtonExit Button
---@field ButtonContinue Button
---@field EditName Edit
---@field EditNameLabel Text
---@field EditPort Edit
---@field EditPortLabel Text
---@field DialogError Control
---@field CheckAutoPort Checkbox
LobbyCreationDialog = Class(Group) {

    DefaultPort = 16010,
    ValidPorts = {
        [48] = true,
        [49] = true,
        [50] = true,
        [51] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [46] = true,
    },

    OnAcceptCallbacks = { },
    OnCancelCallbacks = { },

    ---@param self UILobbyCreationDialog
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'UILobbyCreationDialog')
        self:Debug(string.format("__init()"))

        LayoutHelpers.AtCenterIn(self, parent)
        LayoutHelpers.SetDimensions(self, 10, 10)

        self.Panel = UIUtil.CreateBitmap(self, '/scx_menu/gamecreate/panel-brackets_bmp.dds')
        LayoutHelpers.AtCenterIn(self.Panel, self)

        self.PanelTitle = UIUtil.CreateText(self.Panel, "<LOC _Create_LAN_Game>", 22)
        LayoutHelpers.AtHorizontalCenterIn(self.PanelTitle, self.Panel)
        LayoutHelpers.AtTopIn(self.PanelTitle, self.Panel, 50)

        self.ButtonExit = UIUtil.CreateButtonStd(self.Panel, '/scx_menu/small-btn/small', "<LOC _Cancel>", 16, 2, 0, "UI_Back_MouseDown")
        LayoutHelpers.AtLeftIn(self.ButtonExit, self.Panel, 38)
        LayoutHelpers.AtBottomIn(self.ButtonExit, self.Panel, 34)

        self.ButtonContinue = UIUtil.CreateButtonStd(self.Panel, '/scx_menu/small-btn/small', "<LOC _OK>", 16, 2)
        LayoutHelpers.AtRightIn(self.ButtonContinue, self.Panel, 38)
        LayoutHelpers.AtBottomIn(self.ButtonContinue, self.Panel, 34)

        self.EditName = CreateEditField(self.Panel)
        LayoutHelpers.SetWidth(self.EditName, 340)
        LayoutHelpers.AtHorizontalCenterIn(self.EditName, self.Panel)
        LayoutHelpers.AtTopIn(self.EditName, self.Panel, 120)

        self.EditNameLabel = UIUtil.CreateText(self.Panel, "<LOC _Game_Name>", 14, UIUtil.bodyFont)
        LayoutHelpers.Above(self.EditNameLabel, self.EditName, 5)

        self.EditPort = CreateEditField(self.Panel)
        self.EditPort.Width:Set(self.EditName.Width)
        LayoutHelpers.AtHorizontalCenterIn(self.EditPort, self.Panel)
        LayoutHelpers.Below(self.EditPort, self.EditName, 36)

        self.EditPortLabel = UIUtil.CreateText(self.Panel, "<LOC _Port>", 14, UIUtil.bodyFont)
        LayoutHelpers.Above(self.EditPortLabel, self.EditPort, 5)

        self.CheckAutoPort = UIUtil.CreateCheckboxStd(self.Panel, '/dialogs/check-box_btn/radio')
        self.CheckAutoPort.Right:Set(self.EditPort.Right)
        LayoutHelpers.AnchorToTop(self.CheckAutoPort, self.EditPort, 5)

        self.CheckAutoPortLabel = UIUtil.CreateText(self.Panel, "<LOC GAMECREATE_0003>Auto Port", 14, UIUtil.bodyFont)
        self.CheckAutoPortLabel.Right:Set(self.CheckAutoPort.Left)
        self.CheckAutoPortLabel.Bottom:Set(self.CheckAutoPort.Bottom)
    end,

    ---@param self UILobbyCreationDialog
    ---@param parent Control
    __post_init = function(self, parent)
        self:Debug(string.format("__post_init()"))

        self.EditName:SetText(Prefs.GetFromCurrentProfile('last_game_name') or "")
        self.EditName:SetMaxChars(32)
        self.EditName:ShowBackground(false)

        ---@param checkbox Checkbox
        ---@param checked boolean
        self.CheckAutoPort.OnCheck = function(checkbox, checked)
            if checked then
                self.EditPort:Disable()
                self.EditPort:SetText(LOC("<LOC GAMECREATE_0002>Auto"))
            else
                self.EditPort:Enable()
                self.EditPort:SetText(Prefs.GetFromCurrentProfile('LastPort') or self.DefaultPort)
            end
        end

        self.CheckAutoPort:SetCheck(true)

        ---@param edit Edit
        ---@param charcode number
        ---@return boolean
        self.EditPort.OnCharPressed = function(edit, charcode)
            if self.ValidPorts[charcode] then
                return false
            else
                local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                PlaySound(sound)
                return true
            end
        end

        ---@param edit Edit
        ---@param text string
        self.EditPort.OnEnterPressed = function(edit, text)
            edit:AbandonFocus()
            return true
        end

        self.EditPort:ShowBackground(false)

        self.ButtonExit.OnClick = function(button)
            for name, callback in self.OnCancelCallbacks do
                local ok, msg = pcall(callback)
                if not ok then
                    self:Warn(string.format("Callback '%s' for 'ButtonExit' failed: \r\n %s", name, msg))
                end
            end
        end

        self.ButtonContinue.OnClick = function(button)
            for name, callback in self.OnAcceptCallbacks do
                local ok, msg = pcall(callback, self.EditName:GetText(), self.EditPort:GetText())
                if not ok then
                    self:Warn(string.format("Callback '%s' for 'ButtonContinue' failed: \r\n %s", name, msg))
                end
            end
        end
    end,

    ---------------------------------------------------------------------------
    --#region Callbacks

    ---@param self UILobbyCreationDialog
    ---@param callback fun(name: string, port: string)
    ---@param name string
    AddOnAcceptCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnAcceptCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnAcceptCallback'")
            return
        end

        self.OnAcceptCallbacks[name] = callback
    end,

    ---@param self UILobbyCreationDialog
    ---@param callback fun()
    ---@param name string
    AddOnCancelCallback = function(self, callback, name)
        if (not name) or type(name) != 'string' then
            self:Warn("Ignoring callback, 'name' parameter is invalid for  'AddOnCancelCallback'")
            return
        end

        if (not callback) or type(callback) != 'function' then
            self:Warn("Ignoring callback, 'callback' parameter is invalid for 'AddOnCancelCallback'")
            return
        end

        self.OnCancelCallbacks[name] = callback
    end,

    ---------------------------------------------------------------------------
    --#region Debugging

    Debugging = true,

    ---@param self UILobbyCreationDialog
    ---@param message string
    Debug = function(self, message)
        if self.Debugging then
            SPEW(string.format("UILobbyCreationDialog: %s", message))
        end
    end,

    ---@param self UILobbyCreationDialog
    ---@param message string
    Log = function(self, message)
        LOG(string.format("UILobbyCreationDialog: %s", message))
    end,

    ---@param self UILobbyCreationDialog
    ---@param message string
    Warn = function(self, message)
        WARN(string.format("UILobbyCreationDialog: %s", message))
    end,
}

---@param parent Control
---@return UILobbyCreationDialog
CreateLobbyCreationDialog = function(parent)
    local lobbyCreationDialog = LobbyCreationDialog(parent) --[[@as UILobbyCreationDialog]]
    return lobbyCreationDialog
end
