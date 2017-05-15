local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local EscapeHandler = import('/lua/ui/dialogs/eschandler.lua')

--- Base class for popups. A popup appears on top of other UI content, darkens the content behind it,
-- and draws a standard background behind its content. You'll probably want to extend it to do
-- something more involved, or use it as-is if you want to manually assemble your popup UI Group.
Popup = Class(Group) {
    --- Create a new popup
    --
    -- @param GUI A reference to the lobby's GUI object (dialogs should all be parented off there)
    -- @param content A Group containing the UI to show inside the popup.
    __init = function(self, GUI, content)
        Group.__init(self, GUI)
        self.content = content
        content:SetParent(self)
        LayoutHelpers.AtLeftTopIn(content, self)

        self.Width:Set(content.Width())
        self.Height:Set(content.Height())

        -- We parent the background off the parent so we can get a sensible answer for the dimensions
        -- of the dialog without the need for more magic.
        local shadow = Bitmap(self)
        LayoutHelpers.FillParent(shadow, GetFrame(0))
        shadow.Depth:Set(GetFrame(GUI:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 10)
        self.Depth:Set(GetFrame(GUI:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 10)
        shadow:SetSolidColor('78000000')

        local background = UIUtil.CreateNinePatchStd(self, '/scx_menu/lan-game-lobby/dialog/background/')

        background.Left:Set(function() return content.Left() + 64 end)
        background.Right:Set(function() return content.Right() - 64 end)
        background.Top:Set(function() return content.Top() + 64 end)
        background.Bottom:Set(function() return content.Bottom() - 64 end)

        LayoutHelpers.DepthUnderParent(background, content)

        -- Plant the dialog in the middle of the screen.
        LayoutHelpers.AtCenterIn(self, GUI)

        -- Closure copy.
        local this = self

        -- Dismiss dialog when shadow is clicked.
        shadow.HandleEvent = function(shadow, event)
            if event.Type == 'ButtonPress' then
                this:OnShadowClicked()
            end
        end

        ---- Close when the escape key is pressed.
        EscapeHandler.PushEscapeHandler(function()
            EscapeHandler.PopEscapeHandler()
            this:OnEscapePressed()
        end)
    end,

    --- Close the dialog.
    Close = function(self)
        self:OnClosed()
        self:Destroy()
    end,

    --- Called when escape is pressed if the dialog is open. Defaults to closing the dialog.
    OnEscapePressed = function(self)
        self:Close()
    end,

    --- Called when the shadow is clicked. Defaults to closing the dialog.
    OnShadowClicked = function(self)
        self:Close()
    end,

    --- Called when the dialog is closed via any method.
    OnClosed = function(self)
        EscapeHandler.PopEscapeHandler()
    end,
}
