local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Edit = import('/lua/maui/edit.lua').Edit
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

--- A popup that asks the user for a string.
InputDialog = Class(Popup) {
    __init = function(self, parent, title)
        -- Set up the UI Group to pass to the Popup constructor.
        local dialogContent = Group(parent)
        dialogContent.Width:Set(364)
        dialogContent.Height:Set(140)

        if title then
            local titleText = UIUtil.CreateText(dialogContent, title, 17, 'Arial', true)
            LayoutHelpers.AtHorizontalCenterIn(titleText, dialogContent)
            LayoutHelpers.AtTopIn(titleText, dialogContent, 10)
        end

        -- Input textfield.
        local nameEdit = Edit(dialogContent)
        LayoutHelpers.AtHorizontalCenterIn(nameEdit, dialogContent)
        LayoutHelpers.AtVerticalCenterIn(nameEdit, dialogContent)
        nameEdit.Width:Set(334)
        nameEdit.Height:Set(24)
        nameEdit:AcquireFocus()

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
        ExitButton.OnClick = function()
            self:OnCancelled()
            self:Close()
        end

        -- Ok button
        local OKButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
        LayoutHelpers.AtRightIn(OKButton, dialogContent, -5)
        LayoutHelpers.AtBottomIn(OKButton, dialogContent, 10)
        OKButton.OnClick = dialogComplete

        Popup.__init(self, parent, dialogContent)

        -- Set up event listeners...
        self.OnEscapePressed = self.OnCancelled
        self.OnShadowClicked = self.OnCancelled
    end,

    --- Called with the contents of the textfield when the presses enter or clicks the "OK" button.
    -- If this function returns false, the dialog will remain open afterwards, allowing for input
    -- validation (you should probably notify the user, too!)
    OnInput = function(self, str) end,

    --- Called when the user clicks "cancel", presses escape, or clicks outside the dialog.
    OnCancelled = function(self) end
}
