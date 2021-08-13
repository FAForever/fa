
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox

local Prefs = import('/lua/user/prefs.lua')
local pixelScaleFactor = Prefs.GetFromCurrentProfile('options').ui_scale or 1

-- Interactivity:
-- - Move up / down via dragger
-- - scale to the right via dragger
-- - scale down via dragger


local function CreateStructure(interface, identifier)

    -- Create arrow checkbox
    interface.arrow = Checkbox(GetFrame(0))
    
    -- create the panel.
    interface.panel = Bitmap(interface)

    interface.topPanel = Bitmap(interface)
    interface.middlePanel = Bitmap(interface)
    interface.bottomPanel = Bitmap(interface)

    -- Create the left bracket.
    interface.leftTopBracket = Bitmap(interface)
    interface.leftMiddleBracket = Bitmap(interface)
    interface.leftBottomBracket = Bitmap(interface)

    -- create the right 'bracket'.
    interface.rightGlowTop = Bitmap(interface)
    interface.rightGlowMiddle = Bitmap(interface)
    interface.rightGlowBottom = Bitmap(interface)
    
    -- title
    interface.title = UIUtil.CreateText(interface, identifier, 16, UIUtil.bodyFont)
    interface.title:SetDropShadow(true)

end

local function CreateLayout(interface, heightOffset, width, height)

    --------------------------------------------------
    -- Make the little arrow to show / hide the		--
    -- panel										--

    interface.arrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
    interface.arrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
        
    LayoutHelpers.AtLeftTopIn(interface.arrow, GetFrame(0), -3, heightOffset)
    interface.arrow.Depth:Set(function() return interface.Depth() + 10 end)

    --------------------------------------------------
    -- Make the panel and set its height according	--
    -- to the number of players.					--

    LayoutHelpers.FillParent(interface.panel, interface)
    
    interface:DisableHitTest()

    --------------------------------------------------
    -- Construct the actual panel					--

    interface.topPanel:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_t.dds'))
    interface.middlePanel:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_m.dds'))
    interface.bottomPanel:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_b.dds'))

    interface.topPanel.Depth:Set(interface.Depth() - 2)
    interface.middlePanel.Depth:Set(interface.Depth() - 2)
    interface.bottomPanel.Depth:Set(interface.Depth() - 2)

    interface.topPanel.Top:Set(function () return interface.Top() + 8 end)
    interface.topPanel.Left:Set(function () return interface.Left() + 8 end)
    interface.topPanel.Right:Set(function () return interface.Right() end)

    interface.bottomPanel.Top:Set(function () return interface.Bottom() end)
    interface.bottomPanel.Left:Set(function () return interface.Left() + 8 end)
    interface.bottomPanel.Right:Set(function () return interface.Right() end)

    interface.middlePanel.Top:Set(function () return interface.topPanel.Bottom() end)
    interface.middlePanel.Bottom:Set(function() return math.max(interface.bottomPanel.Top(), interface.topPanel.Bottom()) end)
    interface.middlePanel.Left:Set(function () return interface.Left() + 8 end)
    interface.middlePanel.Right:Set(function () return interface.Right() end)

    --------------------------------------------------
    -- Construct the left bracket					--

    interface.leftTopBracket:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_t.dds'))
    interface.leftMiddleBracket:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    interface.leftBottomBracket:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))

    interface.leftTopBracket.Top:Set(function () return interface.Top() + 2 end)
    interface.leftTopBracket.Left:Set(function () return interface.Left() - 12 * pixelScaleFactor end)

    interface.leftBottomBracket.Bottom:Set(function () return interface.Bottom() + 22 end)
    interface.leftBottomBracket.Left:Set(function () return interface.Left() - 12 * pixelScaleFactor end)

    interface.leftMiddleBracket.Top:Set(function () return interface.leftTopBracket.Bottom() end)
    interface.leftMiddleBracket.Bottom:Set(function() return math.max(interface.leftTopBracket.Bottom(), interface.leftBottomBracket.Top()) end)
    interface.leftMiddleBracket.Right:Set(function () return interface.leftTopBracket.Right() - 9 * pixelScaleFactor end)

    --------------------------------------------------
    -- Construct the right bracket					--

    interface.rightGlowTop:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    interface.rightGlowMiddle:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    interface.rightGlowBottom:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))

    interface.rightGlowTop.Top:Set(function () return interface.Top() + 5 end)
    interface.rightGlowTop.Left:Set(function () return interface.Right() - 10 end)

    interface.rightGlowBottom.Bottom:Set(function () return interface.Bottom() + 20 end)
    interface.rightGlowBottom.Left:Set(function () return interface.rightGlowTop.Left() end)

    interface.rightGlowMiddle.Top:Set(function () return interface.rightGlowTop.Bottom() end)
    interface.rightGlowMiddle.Bottom:Set(function () return math.max(interface.rightGlowTop.Bottom(), interface.rightGlowBottom.Top()) end)
    interface.rightGlowMiddle.Right:Set(function () return interface.rightGlowTop.Right() end)

    LayoutHelpers.AtLeftTopIn(interface.title, interface, 30, 11)
    interface.title:SetColor('ffffaa55')
end


local function CreateFunctionality(interface)

    --  Button Actions
    interface.arrow.OnCheck = function(self, checked)

        local parent = GetFrame(0)

        -- check if UI is hidden, if so - do nothing
        if import('/lua/ui/game/gamemain.lua').gameUIHidden and state != nil then
            return
        end
        
        -- check if we want animations
        if UIUtil.GetAnimationPrefs() then
            -- if we're closed, open up
            if interface:IsHidden() then
                PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
                interface:Show()
                interface:SetNeedsFrameUpdate(true)
                interface.OnFrame = function(self, delta)
                    local newLeft = self.Left() + (1000*delta)
                    if newLeft > parent.Left()+14 then
                        newLeft = parent.Left()+14
                        self:SetNeedsFrameUpdate(false)
                    end
                    self.Left:Set(newLeft)
                end
                interface.arrow:SetCheck(false, true)
            -- if we're open, close
            else
                PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
                interface:SetNeedsFrameUpdate(true)
                interface.OnFrame = function(self, delta)
                    local newLeft = self.Left() - (1000*delta)
                    if newLeft < parent.Left()-self.Width() then
                        newLeft = parent.Left()-self.Width()
                        self:SetNeedsFrameUpdate(false)
                        self:Hide()
                    end
                    self.Left:Set(newLeft)
                end
                interface.arrow:SetCheck(true, true)
            end

        -- no animations
        else
            -- if we're closed, open up
            if interface:IsHidden() then
                interface:Show()
                -- ShowHideElements(true)
                interface.arrow:SetCheck(false, true)
            -- if we're open, close
            else
                interface:Hide()
                -- ShowHideElements(false)
                interface.arrow:SetCheck(true, true)
            end
        end
    end
end

--- Constructs the basic.
function WindowConstructDockedLeft(identifier, heightOffset, width, height)

    -- Create group for main UI
    local main = Group(GetFrame(0))
    LayoutHelpers.AtLeftTopIn(main, GetFrame(0), 16, heightOffset - 19)
    LayoutHelpers.SetWidth(main, width)
    LayoutHelpers.SetHeight(main, height)

    CreateStructure(main, identifier)
    CreateLayout(main, heightOffset, width, height)
    CreateFunctionality(main)

    return main
end