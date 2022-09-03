local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Prefs = import("/lua/user/prefs.lua")
local Tooltip = import('/lua/ui/game/tooltip.lua')

local Layouter = LayoutHelpers.ReusedLayoutFor

-- seconds to see recall voting results
local reviewResultsDuration = 5

local panel

function Create(parent)
    return RecallPanel(parent)
end

function RequestHandler(data)
    if data.CanRequest then
        import('/lua/ui/game/diplomacy.lua').UpdateCanRequestCall(Sync.CanRequest)
    end
    if data.Open then
        SPEW("Recall voting!")
        panel:StartVote(data.Open, data.CanVote)
    end
    if data.Close ~= nil then
        panel:CloseVote()
    end
    local accept, veto = data.Accept, data.Veto
    if accept or veto then
        panel:AddVotes(accept, veto)
    end
end

---@class RecallPanel : Group
RecallPanel = Class(Group) {
    DefaultHeight = 112,
    DefaultWidth = 160,

    __init = function(self, parent)
        Group.__init(self, parent)
        local pos = self:_LoadPosition()
        LayoutHelpers.AtLeftTopIn(self, parent, pos.left, 4)

        self._parent = parent
        self._collapseArrow = Checkbox(parent)
        self._leftPanel = Bitmap(self)
        self._rightPanel = Bitmap(self)
        self._centerPanel = Bitmap(self)
        self._leftBrace = Bitmap(self)
        self._rightBrace = Bitmap(self)
        self.label = UIUtil.CreateText(self, "<LOC diplomacy_0018>Ready for recall", 18, UIUtil.bodyFont, true)
        self.votes = Group(self)
        self.buttonAccept = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0016>Accept", 16)
        self.buttonVeto = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0017>Veto", 16)
        self.progressBar = UIUtil.CreateBitmapColor(self, "Yellow")

        self.votes.blocks = 0
        self:Layout()

        Tooltip.AddButtonTooltip(self.buttonAccept, "dip_recall_request_accept")
        Tooltip.AddButtonTooltip(self.buttonVeto, "dip_recall_request_veto")

        self._collapseArrow.OnCheck = function(_, checked)
            if UIUtil.GetAnimationPrefs() then
                if not checked or self:IsHidden() then
                    PlaySound(Sound {
                        Cue = "UI_Score_Window_Open",
                        Bank = "Interface"
                    })
                    self:Show()
                    self:SetNeedsFrameUpdate(true)
                    self.OnFrame = function(control, delta)
                        local newTop = control.Top() + (500 * delta)
                        if newTop > control._parent.Top() then
                            newTop = control._parent.Top()
                            control:SetNeedsFrameUpdate(false)
                        end
                        control.Top:Set(newTop + 4)
                        RecallPanel.OnFrame(control)
                    end
                else
                    PlaySound(Sound {
                        Cue = "UI_Score_Window_Close",
                        Bank = "Interface"
                    })

                    self:SetNeedsFrameUpdate(true)
                    self.OnFrame = function(control, delta)
                        local newTop = control.Top() - (500 * delta)
                        if newTop < control._parent.Top() - control.Height() then
                            newTop = control._parent.Top() - control.Height()
                            control:Hide()
                            control:SetNeedsFrameUpdate(false)
                        end
                        control.Top:Set(newTop)
                        RecallPanel.OnFrame(control)
                    end
                end
            else
                if not checked or self:IsHidden() then
                    self:Show()
                    self._collapseArrow:SetCheck(false, true)
                else
                    self:Hide()
                    self._collapseArrow:SetCheck(true, true)
                end
            end
        end
        self.buttonAccept.OnClick = function()
            SimCallback({
                Func = "SetRecallVote",
                Args = {
                    From = GetFocusArmy(),
                    Vote = true,
                }
            })
            self:SetCanVote(false)
        end
        self.buttonVeto.OnClick = function()
            SimCallback({
                Func = "SetRecallVote",
                Args = {
                    From = GetFocusArmy(),
                    Vote = false,
                }
            })
            self:SetCanVote(false)
        end
    end,

    Layout = function(self)
        self.Height:Set(LayoutHelpers.ScaleNumber(self.DefaultHeight))
        self.Width:Set(LayoutHelpers.ScaleNumber(self.DefaultWidth))
        self:Hide()
        self.Top:Set(self._parent.Top() - self.Height())

        self._leftPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_l_bmp.dds"))
        self._rightPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_r_bmp.dds"))
        self._centerPanel:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/filter-ping-panel01_c_bmp.dds"))
        self._leftBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-r_bmp.dds"))
        self._rightBrace:SetTexture(UIUtil.SkinnableFile("/game/filter-ping-panel/bracket-energy-r_bmp.dds"))

        self._centerPanel:DisableHitTest()
        self._leftPanel:DisableHitTest()
        self._rightPanel:DisableHitTest()

        self._leftBrace:DisableHitTest()
        self._rightBrace:DisableHitTest()

        self._collapseArrow:SetTexture(UIUtil.SkinnableFile("/game/tab-t-btn/tab-close_btn_up.dds"))
        self._collapseArrow:SetNewTextures(UIUtil.SkinnableFile("/game/tab-t-btn/tab-close_btn_up.dds"),
            UIUtil.SkinnableFile("/game/tab-t-btn/tab-open_btn_up.dds"),
            UIUtil.SkinnableFile("/game/tab-t-btn/tab-close_btn_over.dds"),
            UIUtil.SkinnableFile("/game/tab-t-btn/tab-open_btn_over.dds"),
            UIUtil.SkinnableFile("/game/tab-t-btn/tab-close_btn_dis.dds"),
            UIUtil.SkinnableFile("/game/tab-t-btn/tab-open_btn_dis.dds"))
        self._collapseArrow:Disable()
        LayoutHelpers.AtTopIn(self._collapseArrow, self._parent, -3)
        LayoutHelpers.AtHorizontalCenterIn(self._collapseArrow, self)

        LayoutHelpers.DepthOverParent(self._collapseArrow, self, 10)

        self._leftPanel.Top:Set(self.Top)
        self._rightPanel.Top:Set(self.Top)
        self._centerPanel.Top:Set(self.Top)

        self._leftPanel.Left:Set(self.Left)
        self._rightPanel.Right:Set(self.Right)
        self._centerPanel.Left:Set(self._leftPanel.Right)
        self._centerPanel.Right:Set(self._rightPanel.Left)

        LayoutHelpers.AtLeftIn(self._leftBrace, self, 11)
        LayoutHelpers.AtTopIn(self._leftBrace, self)

        self._leftBrace.Right:Set(function()
            return self._leftBrace.Left() - self._leftBrace.Width()
        end)

        LayoutHelpers.AnchorToRight(self._rightBrace, self, -11)
        LayoutHelpers.AtTopIn(self._rightBrace, self)

        Layouter(self.label)
            :AtTopIn(self, 5)
            :AtHorizontalCenterIn(self)
            :End()
        Layouter(self.votes)
            :AnchorToBottom(self.label, 5)
            :AtHorizontalCenterIn(self)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(function()
                local vote = self.votes[1]
                if vote then return vote.Height() end
                return 1
            end)
            :End()
        Layouter(self.buttonAccept)
            :AtLeftBottomIn(self, 8, 12)
            :End()
        Layouter(self.buttonVeto)
            :AtRightBottomIn(self, 8, 12)
            :End()
        Layouter(self.progressBar)
            :AnchorToBottom(self.buttonAccept, 5)
            :AtHorizontalCenterIn(self)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(4)
            :End()
    end,

    LayoutBlocks = function(self, blocks)
        local votes = self.votes
        local currentBlocks = votes.blocks
        if blocks ~= currentBlocks then
            votes.blocks = blocks
            for i = currentBlocks, 1, -1 do
                local block = votes[i]
                block:Destroy()
                votes[i] = nil
            end
            local width = math.floor((self.Width() - LayoutHelpers.ScaleNumber(16)) / blocks)
            local offsetX = LayoutHelpers.ScaleNumber(16) + math.floor((self.Width() - blocks * width) * 0.5) - width
            for i = 1, blocks do
                local vote = Layouter(UIUtil.CreateHorzFillGroup(votes, "/game/recall-panel/recall-vote"))
                    :AtLeftTopIn(votes, offsetX + i * width)
                    :Width(width)
                    :End()
                votes[i] = vote
            end
        end
    end;

    SetCanVote = function(self, canVote)
        if canVote then
            self.buttonFor:Show()
            self.buttonAgainst:Show()
        else
            self.buttonFor:Hide()
            self.buttonAgainst:Hide()
        end
    end;

    StartVote = function(self, blocks, duration, canVote)
        self.duration = duration
        self.startTime = GetGameTimeSeconds()
        self:LayoutBlocks(blocks)
        self:SetCanVote(canVote)
        self:SetNeedsFrameUpdate(true)
        self._collapseArrow:Show()
        self._collapseArrow:Enable()
        self._collapseArrow:SetChecked(true)
    end;

    CloseVote = function(self)
        self:SetCanVote(false)
        self.closeVote = true
    end;

    AddVotes = function(self, accept, veto)
        local function SetTextures(vote, filename)
            vote._left:SetTexture(UIUtil.UIFile(filename .. "_bmp_l.dds"))
            vote._middle:SetTexture(UIUtil.UIFile(filename .. "_bmp_m.dds"))
            vote._right:SetTexture(UIUtil.UIFile(filename .. "_bmp_r.dds"))
        end
        local index = 1
        local votes = self.votes
        for i = 1, votes.blocks do
            if not votes[i].cast then
                index = i
                break
            end
        end
        for _ = 1, accept do
            local vote = votes[index]
            index = index + 1
            vote.cast = "accept"
            SetTextures(vote, "/game/recall/recall-accept")
        end
        for _ = 1, accept do
            local vote = votes[index]
            index = index + 1
            vote.cast = "accept"
            SetTextures(vote, "/game/recall/recall-veto")
        end
    end;

    OnFrame = function(self)
        local dur = self.duration
        local len = GetGameTimeSeconds() - self.startTime
        local nominalWidth = self.Width() - LayoutHelpers.ScaleNumber(16)
        if len >= dur or self.closeVote then
            self.progressBar.Width:Set(nominalWidth)
            self:SetNeedsFrameUpdate(false)
            self.closeVote = nil
            ForkThread(function(self)
                WaitSeconds(reviewResultsDuration)
                self._collapseArrow:SetChecked(false)
                self._collapseArrow:Disable()
                self._collapseArrow:Hide()
            end, self)
        else
            self.progressBar.Width:Set((1 - len / dur) * nominalWidth)
        end
    end;

    HandleEvent = function(self, event)
        if event.Type == "ButtonPress" and event.Modifiers.Middle then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(math.min(math.max(x - offX, self._parent.Left()), self._parent.Right() - self.Width()))
                GetCursor():SetTexture(UIUtil.GetCursor("W_E"))
            end
            drag.OnRelease = function()
                self:_SavePosition()
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
            return true
        end
        return false
    end,

    _LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile("RecallPanelPos") or {
            left = 800,
        }
    end,

    _SavePosition = function(self)
        Prefs.SetToCurrentProfile("RecallPanelPos", {
            left = LayoutHelpers.InvScaleNumber(self.Left()),
        })
    end,

    OnHide = import('/lua/ui/game/gamecommon.lua').SupressShowingWhenRestoringUI,
}
