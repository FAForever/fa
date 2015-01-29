local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local main = import('/lua/ui/uimain.lua')

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
        local shadow = Bitmap(GUI)
        LayoutHelpers.FillParent(shadow, GUI)
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
                this:Hide()
            end
        end

        -- Close when the escape key is pressed.
        main.SetEscapeHandler(function()
            this:Hide()
        end)
    end,

    --- Close the dialog
    Close = function(self)
        main.SetEscapeHandler(self:GetParent().exitLobbyEscapeHandler)
        self:OnClosed()
        self:Destroy()
    end,

    --- Called when the dialog is closed.
    OnClosed = function(self) end
}
