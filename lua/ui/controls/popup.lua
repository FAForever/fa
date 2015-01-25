local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local NinePatch = import('/lua/ui/controls/ninepatch.lua').NinePatch
local Edit = import('/lua/maui/edit.lua').Edit

-- A class for popups. A popup appears on top of other UI content, darkens the content behind it,
-- and draws a standard background behind its content.
Popup = Class(Group) {
    __init = function(self, GUI, content)
        Group.__init(self, GUI)
        content:SetParent(self)
        LayoutHelpers.AtLeftTopIn(content, self)

        self.Width:Set(content.Width())
        self.Height:Set(content.Height())

        -- We parent the background off the parent so we can get a sensible answer for the dimensions
        -- of the dialog without the need for more magic.
        local shadow = Bitmap(GUI)
        LayoutHelpers.FillParent(shadow, GUI)
        shadow.Depth:Set(GetFrame(GUI:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 10)
        self.Depth:Set(GetFrame(GUI:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 10)
        shadow:SetSolidColor('78000000')

        local background = NinePatch(self,
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/center.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/topLeft.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/topRight.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/bottomLeft.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/bottomRight.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/left.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/right.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/top.png'),
            UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/dialog/background/bottom.png')
        )

        background.Left:Set(function() return content.Left() + 64 end)
        background.Right:Set(function() return content.Right() - 64 end)
        background.Top:Set(function() return content.Top() + 64 end)
        background.Bottom:Set(function() return content.Bottom() - 64 end)

        LayoutHelpers.DepthUnderParent(background, content)

        -- Plant the dialog in the middle of the screen.
        LayoutHelpers.AtCenterIn(self, GUI)

        local this = self

        -- Dismiss dialog when shadow is clicked.
        shadow.HandleEvent = function(shadow, event)
            if event.Type == 'ButtonPress' then
                this:Hide()
            end
        end

        local main = import('/lua/ui/uimain.lua')

        -- Close when the escape key is pressed.
        local escapeHandler = function()
            this:Hide()
        end
        main.SetEscapeHandler(escapeHandler)

        -- Closure copy
        local theGUI = GUI

        -- When the visibility of the dialog is changed, drag the background along, too (and restore
        -- the default lobby escape handler when the dialog is closed. It may be worth at some point
        -- having a class to handle stacking escape handlers, should we ever find we want to stack
        -- dialogs).
        self.OnHide = function(self, hidden)
            if hidden then
                self:OnClosed()
                main.SetEscapeHandler(theGUI.exitLobbyEscapeHandler)
            else
                main.SetEscapeHandler(escapeHandler)
            end
            shadow:SetHidden(hidden)
        end
    end,

    -- Override for closure events.
    OnClosed = function(self) end
}

-- A popup that asks the user for a string.
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

        -- Textfield
        local nameEdit = Edit(dialogContent)
        LayoutHelpers.AtHorizontalCenterIn(nameEdit, dialogContent)
        LayoutHelpers.AtVerticalCenterIn(nameEdit, dialogContent)
        nameEdit.Width:Set(334)
        nameEdit.Height:Set(24)
        nameEdit:AcquireFocus()

        -- Called when the dialog is closed in the affirmative.
        local dialogComplete = function()
            self:OnInput(nameEdit:GetText())
            self:Hide()
        end
        nameEdit.OnEnterPressed = dialogComplete

        -- Exit button
        local ExitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Cancel")
        LayoutHelpers.AtLeftIn(ExitButton, dialogContent, -5)
        LayoutHelpers.AtBottomIn(ExitButton, dialogContent, 10)
        ExitButton.OnClick = function()
            self:Hide()
        end

        -- Ok button
        local OKButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
        LayoutHelpers.AtRightIn(OKButton, dialogContent, -5)
        LayoutHelpers.AtBottomIn(OKButton, dialogContent, 10)
        OKButton.OnClick = dialogComplete

        Popup.__init(self, parent, dialogContent)
    end,

    -- Called with the contents of the textfield when the presses enter or clicks the "OK" button.
    OnInput = function(self, str) end
}