--******************************************************************************************************
--** When a player leaves a game while their army is still in it, lets them choose the ally that
--** receives their army. The choice goes to the sim (`SetAbandonRecipient`), and the player only
--** leaves once the sim has run it, so that every client knows the choice before the player is gone.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

---@class AbandonDialogRecipient
---@field Army number
---@field Name string
---@field Rating number
---@field Score number

---@type { Popup: Popup, Status: Text, LeaveAnyway: Button, Id: string, Leave: fun() } | false
local Waiting = false

--- Allies that can receive the focus army, in the order the sim uses by default: rating, then score.
---@return AbandonDialogRecipient[]
function GetRecipients()
    local focus = GetFocusArmy()
    local ratings = SessionGetScenarioInfo().Options.Ratings or {}
    local score = import("/lua/ui/game/score.lua")
    local recipients = {}
    for index, info in GetArmiesTable().armiesTable do
        if index ~= focus and not info.outOfGame and not info.civilian and IsAlly(focus, index) then
            table.insert(recipients, {
                Army = index,
                Name = info.nickname,
                -- AI and unrated players come after rated players, as in `SimUtils.SortBrainsByRating`
                Rating = info.human and ratings[info.nickname] or -1000,
                Score = score.GetArmyScore(index) or 0,
            })
        end
    end
    table.sort(recipients, function(a, b)
        if a.Rating ~= b.Rating then
            return a.Rating > b.Rating
        end
        return a.Score > b.Score
    end)
    return recipients
end

--- Whether leaving now abandons an army that allies could receive.
---@return boolean
function ShouldChooseRecipient()
    if not SessionIsActive() or SessionIsReplay() or not SessionIsMultiplayer() then
        return false
    end

    local focus = GetFocusArmy()
    local armies = GetArmiesTable().armiesTable
    if focus < 1 or not armies[focus] or armies[focus].outOfGame then
        return false
    end

    return not table.empty(GetRecipients())
end

--- Called from `UserSync.lua` when the sim ran a `SetAbandonRecipient` command.
---@param data { Army: number, To: number, Id: string }
function OnRecipientSet(data)
    if Waiting and data.Id == Waiting.Id then
        local leave = Waiting.Leave
        Waiting = false
        leave()
    end
end

--- Shows the waiting state until the sim replies. A paused game doesn't run the sim, so the player
--- can then leave anyway, with the default recipients.
local function WaitForSim()
    ForkThread(function()
        while Waiting do
            local paused = SessionIsPaused()
            if paused then
                Waiting.Status:SetText(LOC("<LOC abandon_paused>The game is paused. Your army is handed over when it resumes."))
                Waiting.LeaveAnyway:Show()
            else
                Waiting.Status:SetText(LOC("<LOC abandon_waiting>Handing over your army..."))
            end
            WaitSeconds(0.1)
        end
    end)
end

--- Asks which ally receives the army before leaving. Falls back to `confirm` (the usual exit
--- confirmation) when there is no army to hand over.
---@param leave fun()      # leaves the game
---@param confirm fun()    # the usual exit confirmation
function ConfirmLeave(leave, confirm)
    if Waiting then
        return
    end
    if not ShouldChooseRecipient() then
        confirm()
        return
    end

    local recipients = GetRecipients()
    local dialog = Group(GetFrame(0), "abandonDialog")
    Layouter(dialog):Width(440):End()

    local title = UIUtil.CreateText(dialog, LOC("<LOC abandon_title>Leave the game?"), 18, UIUtil.titleFont)
    Layouter(title):AtTopIn(dialog, 12):AtHorizontalCenterIn(dialog):End()

    local subtitle = UIUtil.CreateText(dialog, LOC("<LOC abandon_recipient>Your army goes to:"), 14, UIUtil.bodyFont)
    Layouter(subtitle):Below(title, 8):AtHorizontalCenterIn(dialog):End()

    local selected = recipients[1].Army
    local rows = {}
    local function UpdateRows()
        for _, row in rows do
            row:SetSolidColor(row.Army == selected and "ff1d6f42" or "66000000")
        end
    end

    local previous = subtitle
    for _, recipient in recipients do
        local army = recipient.Army
        local row = Bitmap(dialog)
        row.Army = army
        Layouter(row):Width(400):Height(26):Below(previous, previous == subtitle and 10 or 3):AtHorizontalCenterIn(dialog):End()

        local label = UIUtil.CreateText(row, recipient.Name, 14, UIUtil.bodyFont)
        Layouter(label):AtLeftIn(row, 10):AtVerticalCenterIn(row):DisableHitTest():End()

        row.HandleEvent = function(self, event)
            if event.Type == "ButtonPress" and event.Modifiers.Left and not Waiting then
                selected = army
                UpdateRows()
                return true
            end
            return false
        end

        table.insert(rows, row)
        previous = row
    end
    UpdateRows()

    local status = UIUtil.CreateText(dialog, "", 12, UIUtil.bodyFont)
    Layouter(status):Below(previous, 8):AtHorizontalCenterIn(dialog):End()

    local leaveButton = UIUtil.CreateButtonStd(dialog, "/widgets02/small", LOC("<LOC abandon_leave>Leave"), 14)
    local cancelButton = UIUtil.CreateButtonStd(dialog, "/widgets02/small", LOC("<LOC _Cancel>Cancel"), 14)
    local leaveAnywayButton = UIUtil.CreateButtonStd(dialog, "/widgets02/small", LOC("<LOC abandon_leave_anyway>Leave anyway"), 14)
    Layouter(leaveButton):Below(status, 8)
        :Left(function() return dialog.Left() + dialog.Width() * 0.25 - leaveButton.Width() * 0.5 end):End()
    Layouter(cancelButton):Below(status, 8)
        :Left(function() return dialog.Left() + dialog.Width() * 0.75 - cancelButton.Width() * 0.5 end):End()
    Layouter(leaveAnywayButton):Below(status, 8):AtHorizontalCenterIn(dialog):End()
    leaveAnywayButton:Hide()

    -- title, subtitle, rows, status line and buttons
    dialog.Height:Set(LayoutHelpers.ScaleNumber(132 + 29 * table.getn(recipients)))

    local popup = Popup(GetFrame(0), dialog)

    cancelButton.OnClick = function()
        Waiting = false
        popup:Close()
    end
    popup.OnEscapePressed = function()
        cancelButton:OnClick()
    end
    popup.OnShadowClicked = function()
        if not Waiting then
            cancelButton:OnClick()
        end
    end

    leaveButton.OnClick = function()
        leaveButton:Hide()
        cancelButton:Hide()
        Waiting = {
            Popup = popup,
            Status = status,
            LeaveAnyway = leaveAnywayButton,
            -- identifies the reply to this command
            Id = string.format("%d-%d", GameTick(), math.random(1, 1000000000)),
            Leave = leave,
        }
        SimCallback({ Func = "SetAbandonRecipient", Args = { To = selected, Id = Waiting.Id } })
        WaitForSim()
    end

    leaveAnywayButton.OnClick = function()
        Waiting = false
        leave()
    end
end
