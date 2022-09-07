local Dragger = import("/lua/maui/dragger.lua").Dragger
local Group = import("/lua/maui/group.lua").Group
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Lazyvar = import("/lua/lazyvar.lua").Create
local NinePatch = import("/lua/ui/controls/ninepatch.lua")
local Prefs = import("/lua/user/prefs.lua")
local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIUtil = import("/lua/ui/uiutil.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- seconds to see recall voting results
local reviewResultsDuration = 5

local panel

function Create(parent)
    panel = RecallPanel(parent)
    return panel
end

function RequestHandler(data)
    if data.CannotRequest ~= nil then
        import('/lua/ui/game/diplomacy.lua').UpdateCannotRequestRecall(data.CannotRequest)
    end
    if data.Open then
        panel:StartVote(data.Blocks, data.Open, data.CanVote)
    end
    local accept, veto = data.Accept, data.Veto
    if accept or veto then
        panel:AddVotes(accept, veto)
    end
    if data.Close ~= nil then
        panel:CloseVote(data.Close)
    end
end

---@class RecallPanel : NinePatch
RecallPanel = Class(NinePatch.NinePatch) {
    DefaultWidth = 320,

    __init = function(self, parent)
        NinePatch.InitStd(self, parent, "/game/filter-ping-list-panel/panel")

        self.parent = parent
        self.collapseArrow = UIUtil.CreateCollapseArrow(parent, "t")
        self.label = UIUtil.CreateText(self, "<LOC diplomacy_0018>Ready for recall", 18, UIUtil.bodyFont, true)
        self.votes = Group(self)
        self.buttonAccept = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0016>Accept", 16)
        self.buttonVeto = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0017>Veto", 16)
        self.progressBarBG = UIUtil.CreateBitmapColor(self, "Gray")
        self.progressBar = UIUtil.CreateBitmapColor(self.progressBarBG, "Yellow")

        self.votes.blocks = 0
        self.canVote = Lazyvar(true)
        self.startTime = Lazyvar(-9999)
        self:Layout()
        self:Logic()
    end;

    Layout = function(self)
        Layouter(self)
            :AtLeftIn(self.parent, self:LoadPosition().left)
            :Top(self.parent.Top() + LayoutHelpers.ScaleNumber(4) + self.t.Height())
            :Width(self.DefaultWidth)
            :Height(function()
                local Scale = LayoutHelpers.ScaleNumber
                local height = Scale(-4) + self.label.Height() + Scale(5) + self.votes.Height()
                -- make sure these register as a dependency
                local voteHeight = self.buttonAccept.Height()
                local progHeight = self.progressBarBG.Height()
                if self.canVote() then
                    height = height + Scale(5) + voteHeight
                    if self.startTime() > 0 then
                        height = height + progHeight
                    end
                elseif self.startTime() > 0 then
                    height = height + Scale(8) + progHeight
                end
                return height + Scale(-2)
            end)
            :Hide()

        Layouter(self.collapseArrow)
            :Top(self.t.Top() - 7)
            :AtHorizontalCenterIn(self)
            :Over(self, 10)
            :Disable()
            :Hide()

        Layouter(self.label)
            :AtTopCenterIn(self, -4)

        Layouter(self.votes)
            :AnchorToBottom(self.label, 5)
            :AtHorizontalCenterIn(self)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(function()
                local vote = self.votes[1]
                if vote then return vote.Height() end
                return 1
            end)

        Layouter(self.buttonAccept)
            :AtLeftIn(self, 8)
            :AnchorToBottom(self.votes, 5)

        Layouter(self.buttonVeto)
            :AtRightIn(self, 8)
            :AnchorToBottom(self.votes, 5)

        Layouter(self.progressBarBG)
            :AtBottomCenterIn(self, -2)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(4)

        Layouter(self.progressBar)
            :AtHorizontalCenterIn(self.progressBarBG)
            :Top(self.progressBarBG.Top)
            :Bottom(self.progressBarBG.Bottom)
            :Width(function() return (self.Width() - LayoutHelpers.ScaleNumber(16)) * 0.42 end)
            :Over(self.progressBarBG, 10)

        self.Top:Set(self.parent.Top() - self:TotalHeight())

        Tooltip.AddButtonTooltip(self.buttonAccept, "dip_recall_request_accept")
        Tooltip.AddButtonTooltip(self.buttonVeto, "dip_recall_request_veto")
    end;

    LayoutBlocks = function(self, blocks)
        local votes = self.votes
        local currentBlocks = votes.blocks
        if blocks ~= currentBlocks then
            votes.blocks = blocks
            for i = currentBlocks, 1, -1 do
                local block = votes[i]
                if block then
                    block:Destroy()
                end
                votes[i] = nil
            end
            if blocks > 2 then
                local panelWidth = votes.Width()
                local width = math.floor(panelWidth / blocks)
                local offsetX = math.floor((panelWidth - blocks * width) * 0.5) - width
                for i = 1, blocks do
                    local vote = Layouter(UIUtil.CreateHorzFillGroup(votes, "/game/recall-panel/recall-vote"))
                        :AtLeftTopIn(votes, offsetX + i * width)
                        :Width(width)
                        :End()
                    votes[i] = vote
                end
            else
                local text
                if self.canVote() then
                    text = "<LOC diplomacy_0026>Your teammate has requested you to recall"
                else
                    text = "<LOC diplomacy_0025>Waiting for teammate to respond..."
                end
                text = Layouter(UIUtil.CreateText(votes, text, 14))
                    :AtTopCenterIn(votes)
                    :End()
                votes[1] = text
            end
            -- manual dirtying of the lazyvar
            votes.Height[1] = nil
        end
    end;

    Logic = function(self)
        self.collapseArrow.OnCheck = function(_, checked)
            if UIUtil.GetAnimationPrefs() then
                if not checked or self:IsHidden() then
                    PlaySound(Sound {
                        Cue = "UI_Score_Window_Open",
                        Bank = "Interface"
                    })
                    self:Show()
                    self:SetNeedsFrameUpdate(true)
                    self.Slide = false
                else
                    PlaySound(Sound {
                        Cue = "UI_Score_Window_Close",
                        Bank = "Interface"
                    })
                    self:SetNeedsFrameUpdate(true)
                    self.Slide = true
                end
            else
                if not checked or self:IsHidden() then
                    self:Show()
                    self.collapseArrow:SetCheck(false, true)
                else
                    self:Hide()
                    self.collapseArrow:SetCheck(true, true)
                end
            end
        end
        -- self.collapseArrow.OnHide = function(collapse, hide)
        --     if hide ~= collapse:IsDisabled() then
        --         return true
        --     end
        -- end

        local function ShowForVote(button, hide)
            return not hide and not self.canVote()
        end
        self.buttonAccept.OnHide = ShowForVote
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
        self.buttonVeto.OnHide = ShowForVote
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
    end;

    SetCanVote = function(self, canVote)
        local buttonAccept = self.buttonAccept
        local buttonVeto = self.buttonVeto
        self.canVote:Set(canVote)
        if canVote then
            buttonAccept:Show()
            buttonVeto:Show()
        else
            buttonAccept:Hide()
            buttonVeto:Hide()
        end
    end;

    StartVote = function(self, blocks, duration, canVote)
        SPEW("Recall voting!")
        self.duration = duration
        self.startTime:Set(GetGameTimeSeconds())
        self:SetCanVote(canVote)
        self:LayoutBlocks(blocks) -- can depend on `canVote`
        self.collapseArrow:Enable()
        self.collapseArrow:Show()
        self.collapseArrow:SetCheck(false)
        if not UIUtil.GetAnimationPrefs() then
            -- update the timer in a more rudimentary fashion
            self.reviewResultsThread = ForkThread(function(self)
                local nominalWidth = self.Width() - LayoutHelpers.ScaleNumber(16)
                local incWidth = nominalWidth / duration
                for i = 1, duration do
                    if self.startTime() < 0 then -- accept the close vote signal
                        break
                    end
                    self.progressBar.Width:Set(nominalWidth - i * incWidth)
                    WaitSeconds(1)

                end
                self.progressBar.Width:Set(0)
                WaitSeconds(reviewResultsDuration)

                self:OnResultsReviewed()
                self.reviewResultsThread = nil
            end, self)
        end
    end;

    CloseVote = function(self, accepted)
        self:SetCanVote(false)
        self.startTime:Set(-9999) -- make sure the OnFrame animation ends
        if self.reviewResultsThread then
            -- continue the OnSecond animation if it exists
            coroutine.resume(self.reviewResultsThread)
        else
            -- otherwise, create our own result reviewing handler
            self.reviewResultsThread = ForkThread(function(self)
                WaitSeconds(reviewResultsDuration)

                self:OnResultsReviewed()
                self.reviewResultsThread = nil
            end, self)
        end
        if accepted then
            self:OnVoteAccepted()
        else
            self:OnVoteVetoed()
        end
    end;

    AddVotes = function(self, accept, veto)
        local votes = self.votes
        if votes.blocks < 3 then return end
        local function SetTextures(vote, filename)
            vote._left:SetTexture(UIUtil.UIFile(filename .. "_bmp_l.dds"))
            vote._middle:SetTexture(UIUtil.UIFile(filename .. "_bmp_m.dds"))
            vote._right:SetTexture(UIUtil.UIFile(filename .. "_bmp_r.dds"))
        end
        local index = 1
        for i = 1, votes.blocks do
            if not votes[i].cast then
                index = i
                break
            end
        end
        if accept then
            for _ = 1, accept do
                local vote = votes[index]
                index = index + 1
                vote.cast = "accept"
                SetTextures(vote, "/game/recall-panel/recall-accept")
            end
        end
        if veto then
            for _ = 1, veto do
                local vote = votes[index]
                index = index + 1
                vote.cast = "veto"
                SetTextures(vote, "/game/recall-panel/recall-veto")
            end
        end
    end;

    OnFrame = function(self, delta)
        local slide = self.Slide
        local notAnimating = true
        if slide ~= nil then
            local newTop = self.t.Top()
            local topLimit = self.parent.Top()
            if slide then
                newTop = newTop - 500 * delta
                topLimit = topLimit - self:TotalHeight()
                if newTop < topLimit then
                    newTop = topLimit
                    self:Hide()
                    self:SetNeedsFrameUpdate(false)
                    self.Slide = nil
                end
            else
                newTop = newTop + 500 * delta + 4
                if newTop > topLimit then
                    newTop = topLimit
                    self.Slide = nil
                end
            end
            self.Top:Set(newTop + self.t.Height())
            notAnimating = false
        end

        local time = self.startTime()
        if time > 0 then
            local dur = self.duration
            time = GetGameTimeSeconds() - time
            local nominalWidth = self.Width() - LayoutHelpers.ScaleNumber(16)
            if time >= dur then
                self.startTime:Set(-9999)
                self.progressBar.Width:Set(0)
            else
                self.progressBar.Width:Set((1 - time / dur) * nominalWidth)
            end
            notAnimating = false
        end
        if notAnimating then
            self:SetNeedsFrameUpdate(false)
        end
    end;

    OnResultsReviewed = function(self)
        local collapse = self.collapseArrow
        collapse:Disable()
        collapse:SetCheck(true)
    end;

    OnVoteAccepted = function(self)
        import('/lua/ui/game/announcement.lua').CreateAnnouncement(LOC("<LOC diplomacy_0021>The recall vote was accepted."))
        self.label:SetText(LOC("<LOC diplomacy_0023>Recalling..."))
    end;

    OnVoteVetoed = function(self)
        import('/lua/ui/game/announcement.lua').CreateAnnouncement(LOC("<LOC diplomacy_0022>The recall vote was vetoed."))
        self.label:SetText(LOC("<LOC diplomacy_0024>Not ready for recall"))
    end;

    OnHide = function(self, hide)
        local supress = import('/lua/ui/game/gamecommon.lua').SupressShowingWhenRestoringUI(self, hide)
        local collapse = self.collapseArrow
        if collapse then
            if supress or collapse:IsDisabled() then
                collapse:Hide()
            else
                collapse:Show()
                SPEW("SHOWING")
            end
        end
        return supress
    end;

    HandleEvent = function(self, event)
        if event.Type == "ButtonPress" and event.Modifiers.Middle then
            local drag = Dragger()
            local offX = event.MouseX - self.Left()
            drag.OnMove = function(dragself, x, y)
                self.Left:Set(math.min(math.max(x - offX, self.parent.Left()), self.parent.Right() - self.Width()))
                GetCursor():SetTexture(UIUtil.GetCursor("W_E"))
            end
            drag.OnRelease = function()
                self:SavePosition()
                GetCursor():Reset()
                drag:Destroy()
            end
            PostDragger(self:GetRootFrame(), event.KeyCode, drag)
            return true
        end
        return false
    end;

    LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile("RecallPanelPos") or {
            left = 800,
        }
    end;

    SavePosition = function(self)
        Prefs.SetToCurrentProfile("RecallPanelPos", {
            left = LayoutHelpers.InvScaleNumber(self.Left()),
        })
    end;
}
