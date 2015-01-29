local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

-- A class for popups. A popup appears on top of other UI content, darkens the content behind it,
-- and draws a standard background behind its content.
Popup = Class(Group) {
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
            self.isHidden = hidden
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
