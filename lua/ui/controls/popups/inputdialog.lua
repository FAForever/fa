local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

--- A popup that asks the user for a string.
---@class InputDialog : Popup
InputDialog = ClassUI(Popup) {

    ---@param self InputDialog
    ---@param parent any
    ---@param title string
    ---@param fallbackInputbox any
    ---@param str string
    __init = function(self, parent, title, fallbackInputbox, str)
        -- For ridiculous reasons, the lobby *must* keep keyboard focus on the chat input, or
        -- in-game keybindings can be called and cause the world to end.
        -- This parameter allows you to pass the box you insist we always keep focus on to the input
        -- dialog, so when the dialog closes (and focus on its input box is lost) it can restore it
        -- to the fallback box.
        -- WHAAAAA.
        self.closeBox = fallbackInputbox

        -- Set up the UI Group to pass to the Popup constructor.
        local dialogContent = Group(parent)
        LayoutHelpers.SetDimensions(dialogContent, 364, 140)

        if title then
            local titleText = UIUtil.CreateText(dialogContent, title, 17, 'Arial', true)
            LayoutHelpers.AtHorizontalCenterIn(titleText, dialogContent)
            LayoutHelpers.AtTopIn(titleText, dialogContent, 10)
        end

        -- Input textfield.
        local nameEdit = Edit(dialogContent)
        self.inputBox = nameEdit
        LayoutHelpers.AtHorizontalCenterIn(nameEdit, dialogContent)
        LayoutHelpers.AtVerticalCenterIn(nameEdit, dialogContent)
        LayoutHelpers.SetDimensions(nameEdit, 334, 24)
        nameEdit:AcquireFocus()

        if str then
           nameEdit:SetText(str)
        end

        nameEdit.OnLoseKeyboardFocus = function(self)
            nameEdit:AcquireFocus()
        end

        -- Called when the dialog is closed in the affirmative.
        local dialogComplete = function()
            if not self:OnInput(nameEdit:GetText()) then
                self:Close()
            end
        end
        nameEdit.OnEnterPressed = dialogComplete

        -- Exit button
        local ExitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Cancel")
        LayoutHelpers.AtLeftIn(ExitButton, dialogContent, -5)
        LayoutHelpers.AtBottomIn(ExitButton, dialogContent, 10)
        local dialogCancelled = function()
            self:OnCancelled()
            self:Close()
        end

        ExitButton.OnClick = dialogCancelled

        -- Ok button
        local OKButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
        LayoutHelpers.AtRightIn(OKButton, dialogContent, -5)
        LayoutHelpers.AtBottomIn(OKButton, dialogContent, 10)
        OKButton.OnClick = dialogComplete

        Popup.__init(self, parent, dialogContent)

        -- Set up event listeners...
        self.OnEscapePressed = dialogCancelled
        self.OnShadowClicked = dialogCancelled
    end,

    ---@param self InputDialog
    Close = function(self)
        -- Don't want to restore focus to the dialog's input box any more...
        self.inputBox.OnLoseKeyboardFocus = nil
        if self.closeBox then
            self.closeBox:AcquireFocus()
        end

        Popup.Close(self)
    end,

    --- Called with the contents of the textfield when the presses enter or clicks the "OK" button.
    --- If this function returns false, the dialog will remain open afterwards, allowing for input
    --- validation (you should probably notify the user, too!)
    ---@param self InputDialog
    ---@param str string
    OnInput = function(self, str) end,

    --- Called when the user clicks "cancel", presses escape, or clicks outside the dialog.
    ---@param self InputDialog
    OnCancelled = function(self) end
}
