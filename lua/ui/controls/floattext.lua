
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- Padding (unscaled) between the inner text and the background's edges.
local PaddingX = 8
local PaddingY = 2

-------------------------------------------------------------------------------
-- A short-lived overlay text + background that floats vertically while
-- fading, then destroys itself. Useful for ephemeral feedback like
-- "Copied to clipboard!" toasts. The caller anchors `Left`/`Top`; the
-- Group sizes itself to fit its inner text.

--- Animation parameters for `FloatText:Float`. All fields optional.
---@class UIFloatTextOptions
---@field Distance? number    # vertical pixels to travel (positive = up); default 30
---@field Duration? number    # animation length in seconds; default 1.2

--- An auto-destroying floating text-with-background control.
---@class UIFloatText : Group
---@field Background Bitmap
---@field Text       Text
FloatText = ClassUI(Group) {

    ---@param self UIFloatText
    ---@param parent Control
    ---@param text string
    ---@param fontSize? number          # default 14
    ---@param font? string              # default `UIUtil.bodyFont`
    ---@param color? string             # ARGB hex; default 'ffffffff'
    ---@param backgroundColor? string   # ARGB hex; default '80000000' (semi-transparent black)
    __init = function(self, parent, text, fontSize, font, color, backgroundColor)
        Group.__init(self, parent, "FloatText")

        self.Background = Bitmap(self)
        self.Background:SetSolidColor(backgroundColor or '80000000')
        self.Background:DisableHitTest()

        self.Text = UIUtil.CreateText(self, text, fontSize or 14, font or UIUtil.bodyFont)
        self.Text:SetColor(color or 'ffffffff')
        self.Text:SetDropShadow(true)
        self.Text:DisableHitTest()

        self:DisableHitTest()

        -- Pin above everything else currently on the frame so the toast
        -- isn't occluded by windows / popups / map dialogs that sit at a
        -- higher depth than the toast's own parent. Same trick as the
        -- chat config dialog uses on Open.
        self.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    end,

    ---@param self UIFloatText
    __post_init = function(self)
        -- Auto-fit the Text to its rendered string so the parent Group
        -- can wrap it tightly. `TextAdvance` / `FontAscent` / `FontDescent`
        -- are LazyVars exposed by the engine's `moho.text_methods`.
        self.Text.Width:Set(function() return self.Text.TextAdvance() end)
        self.Text.Height:Set(function()
            return self.Text.FontAscent() + self.Text.FontDescent()
        end)

        Layouter(self.Text):AtLeftTopIn(self, PaddingX, PaddingY):End()
        Layouter(self.Background):Fill(self):End()

        local scaledPadX2 = LayoutHelpers.ScaleNumber(PaddingX * 2)
        local scaledPadY2 = LayoutHelpers.ScaleNumber(PaddingY * 2)
        self.Width:Set(function() return self.Text.Width() + scaledPadX2 end)
        self.Height:Set(function() return self.Text.Height() + scaledPadY2 end)
    end,

    --- Starts the float-up + fade-out animation. The control moves
    --- `distance` pixels upward over `duration` seconds, fading from full
    --- opacity to zero, then destroys itself. The alpha cascade applies
    --- to the background bitmap and the text via `SetAlpha(_, true)`.
    ---@param self UIFloatText
    ---@param opts? UIFloatTextOptions
    Float = function(self, opts)
        opts = opts or {}
        local duration = opts.Duration or 1.2
        local scaledDistance = LayoutHelpers.ScaleNumber(opts.Distance or 30)
        local startTop = self.Top()
        local startTime = GetSystemTimeSeconds()

        self:SetNeedsFrameUpdate(true)
        self.OnFrame = function(control)
            local t = (GetSystemTimeSeconds() - startTime) / duration
            if t >= 1 then
                control:Destroy()
                return
            end
            control.Top:Set(startTop - scaledDistance * t)
            control:SetAlpha(math.sqrt(1 - t), true)
        end
    end,
}
