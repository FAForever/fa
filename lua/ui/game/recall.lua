--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local NinePatch = import("/lua/ui/controls/ninepatch.lua")
local Prefs = import("/lua/user/prefs.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Dragger = import("/lua/maui/dragger.lua").Dragger
local Group = import("/lua/maui/group.lua").Group

local Lazyvar = import("/lua/lazyvar.lua").Create
local Layouter = LayoutHelpers.ReusedLayoutFor


-- seconds to see recall voting results
local reviewResultsDuration = 5

local panel

function Create(parent)
    panel = RecallPanel(parent)
    return panel
end

function SetLayout()
    Layouter(panel)
        :AtLeftIn(panel.parent, panel:LoadPosition().left)
        -- set to uncollapsed position; lets us layout the collapse button and setup the height
        -- so we know where the panel's actual inital position is
        :Top(panel.parent.Top() + LayoutHelpers.ScaleNumber(4) + panel.t.Height())
        :Width(panel.DefaultWidth)
        :Height(function()
            -- Since the other components layout relative to the space they have available,
            -- we need to make sure the right amount of space *is* available.
            -- Note that it would have been easier to make the components layout relative to
            -- theirselves if there was only one layout to begin with, but since various components
            -- can be hidden, I figured it was easier to do it all in one place here.
            local panel = panel
            local Scale = LayoutHelpers.ScaleNumber
            local height = Scale(-4) + panel.label.Height() + Scale(5) + panel.votes.Height()
            -- make sure these register as a dependency
            local voteHeight = panel.buttonAccept.Height()
            local progHeight = panel.progressBarBG.Height()
            local startTime = panel.startTime()
            if panel.canVote() then
                height = height + Scale(5) + voteHeight
                if startTime > 0 then
                    height = height + Scale(2) + progHeight
                end
            elseif startTime > 0 then
                height = height + Scale(10) + progHeight
            end
            return height + Scale(-2)
        end)
        :Hide()
        :End()
    panel.Top:Set(panel.parent.Top() - panel:TotalHeight())
end

function ToggleControl()
    if panel and not panel.collapseArrow:IsDisabled() then
        panel.collapseArrow:ToggleCheck()
    end
end

function RequestHandler(data)
    if data.CannotRequest ~= nil then
        import("/lua/ui/game/diplomacy.lua").SetCannotRequestRecallReason(data.CannotRequest)
    end
    if data.Open then
        panel:StartVote(data.Blocks, data.Open, data.CanVote, data.StartTime)
    end
    local yes, no = data.Accept, data.Veto -- TODO: rename to `Yes` and `No`
    if yes or no then
        panel:AddVotes(yes, no)
    end
    if data.Close ~= nil then
        panel:CloseVote(data.Close)
    elseif data.Cancel then
        panel:CancelVote()
    end
end

---@class RecallPanel : NinePatch
RecallPanel = ClassUI(NinePatch.NinePatch) {
    DefaultWidth = 320,

    __init = function(self, parent)
        NinePatch.InitStd(self, parent, "/game/filter-ping-list-panel/panel")

        self.parent = parent
        self.collapseArrow = UIUtil.CreateCollapseArrow(parent, "t")
        self.label = UIUtil.CreateText(self, "<LOC diplomacy_0018>Ready for recall", 18, UIUtil.bodyFont, true)
        self.votes = Group(self)
        -- TODO: rename to `buttonYes` and `buttonNo`
        self.buttonAccept = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0016>Yes", 16)
        self.buttonVeto = UIUtil.CreateButtonStd(self, "/widgets02/small", "<LOC diplomacy_0017>No", 16)
        self.progressBarBG = UIUtil.CreateBitmapColor(self, "Gray")
        self.progressBar = UIUtil.CreateBitmapColor(self.progressBarBG, "Yellow")

        self.progressBarBG.Height:Set(LayoutHelpers.ScaleNumber(4))
        self.votes.Height:Set(LayoutHelpers.ScaleNumber(1))

        self.votes.blocks = 0
        self.canVote = Lazyvar(true)
        self.startTime = Lazyvar(-9999)

        self:Logic()
    end,

    Layout = function(self)
        local collapseArrow = Layouter(self.collapseArrow)
            :Top(self.t.Top() - 7)
            :AtHorizontalCenterIn(self)
            :Over(self, 10)
            :Disable()
            :Hide()
            :End()

        local label = Layouter(self.label)
            :AtTopCenterIn(self, -4)
            :End()

        local votes = Layouter(self.votes)
            :AnchorToBottom(label, 5)
            :AtHorizontalCenterIn(self)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(function()
                local vote = self.votes[1]
                if vote then return vote.Height() end
                return 1
            end)
            :End()

        local buttonYes = Layouter(self.buttonAccept)
            :AtLeftIn(self, 8)
            :AnchorToBottom(votes, 5)
            :End()

        local buttonNo = Layouter(self.buttonVeto)
            :AtRightIn(self, 8)
            :AnchorToBottom(votes, 5)
            :End()

        local progressBarBG = Layouter(self.progressBarBG)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Height(4)
            :AtBottomCenterIn(self, -2)
            :End()

        Layouter(self.progressBar)
            :AtHorizontalCenterIn(progressBarBG)
            :Top(progressBarBG.Top)
            :Bottom(progressBarBG.Bottom)
            :Width(function() return self.Width() - LayoutHelpers.ScaleNumber(16) end)
            :Over(progressBarBG, 10)
            :End()

        Tooltip.AddCheckboxTooltip(collapseArrow, "voting_collapse")
        -- TODO: rename to `dip_recall_request_yes` and `dip_recall_request_no`
        Tooltip.AddButtonTooltip(buttonYes, "dip_recall_request_accept")
        Tooltip.AddButtonTooltip(buttonNo, "dip_recall_request_veto")
    end,

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
    end,

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
        self.collapseArrow.OnHide = function(collapse, hide)
            if collapse:IsDisabled() and not hide then
                return true
            end
        end

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
                },
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
                },
            })
            self:SetCanVote(false)
        end
    end,

    SetCanVote = function(self, canVote)
        local buttonYes = self.buttonAccept
        local buttonNo = self.buttonVeto
        self.canVote:Set(canVote)
        if canVote then
            buttonYes:Show()
            buttonNo:Show()
        else
            buttonYes:Hide()
            buttonNo:Hide()
        end
    end,

    StartVote = function(self, blocks, duration, canVote, startingTime)
        self.duration = duration
        self.startTime:Set(startingTime or GetGameTimeSeconds())
        self:SetCanVote(canVote)
        self:LayoutBlocks(blocks) -- can depend on `canVote`, so put after it
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
    end,

    CancelVote = function(self)
        self:SetCanVote(false)
        self.startTime:Set(-9999) -- make sure the OnFrame animation ends
        if self.reviewResultsThread then
            KillThread(self.reviewResultsThread)
            self.reviewResultsThread = nil
        end
        self:OnResultsReviewed()
    end,

    CloseVote = function(self, passed)
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
        if passed then
            self:OnVoteAccepted()
        else
            self:OnVoteVetoed()
        end
    end,

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
                vote.cast = "yes"
                SetTextures(vote, "/game/recall-panel/recall-accept")
            end
        end
        if veto then
            for _ = 1, veto do
                local vote = votes[index]
                index = index + 1
                vote.cast = "no"
                SetTextures(vote, "/game/recall-panel/recall-veto")
            end
        end
    end,

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
                self.progressBar:Hide()
            else
                self.progressBar.Width:Set((1 - time / dur) * nominalWidth)
            end
            notAnimating = false
        end
        if notAnimating then
            self:SetNeedsFrameUpdate(false)
        end
    end,

    OnResultsReviewed = function(self)
        local collapse = self.collapseArrow
        collapse:Disable()
        collapse:SetCheck(true)
    end,

    OnVoteAccepted = function(self)
        import("/lua/ui/game/announcement.lua").CreateAnnouncement(LOC("<LOC diplomacy_0021>The recall vote passed."))
        self.label:SetText(LOC("<LOC diplomacy_0023>Recalling..."))
    end,

    OnVoteVetoed = function(self)
        import("/lua/ui/game/announcement.lua").CreateAnnouncement(LOC("<LOC diplomacy_0022>The recall vote did not pass."))
        self.label:SetText(LOC("<LOC diplomacy_0024>Not ready for recall"))
    end,

    OnHide = function(self, hide)
        local supress = import("/lua/ui/game/gamecommon.lua").SupressShowingWhenRestoringUI(self, hide)
        local collapse = self.collapseArrow
        if collapse then
            if supress or collapse:IsDisabled() then
                collapse:Hide()
                if not hide then
                    supress = true
                end
            else
                collapse:Show()
            end
        end
        return supress
    end,

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
    end,

    LoadPosition = function(self)
        return Prefs.GetFromCurrentProfile("RecallPanelPos") or {
            left = 800,
        }
    end,

    SavePosition = function(self)
        Prefs.SetToCurrentProfile("RecallPanelPos", {
            left = LayoutHelpers.InvScaleNumber(self.Left()),
        })
    end,
}
