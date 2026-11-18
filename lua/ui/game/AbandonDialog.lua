--******************************************************************************************************
--** When a player leaves a game while their army is still in it, lets them choose the ally that
--** receives their army. The choice goes to the sim with `SetAbandonRecipient`.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
local Group = import("/lua/maui/group.lua").Group
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local ArmyListModule = import("/lua/ui/game/abandonarmylist.lua")

-- Real seconds between sending the choice and leaving. A sim command only runs on the other
-- clients once this client has sent the beat it belongs to, and `SessionEndGame` stops all sending.
-- Beats go out about every 100 ms, or after 250 ms when the game is paused, where the command still
-- runs (the sim only stops ticking).
local LeaveDelay = 0.5

-- Rows shown before the list scrolls
local VisibleRows = 5

local Leaving = false

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

    return not table.empty(ArmyListModule.GetAllies())
end

--- Asks which ally receives the army before leaving. Falls back to `confirm` (the usual exit
--- confirmation) when there is no army to hand over.
---@param leave fun()      # leaves the game
---@param confirm fun()    # the usual exit confirmation
function ConfirmLeave(leave, confirm)
    if Leaving then
        return
    end
    if not ShouldChooseRecipient() then
        confirm()
        return
    end

    local allies = ArmyListModule.GetAllies()
    local dialog = Group(GetFrame(0), "abandonDialog")
    Layouter(dialog):Width(440):End()

    local title = UIUtil.CreateText(dialog, LOC("<LOC abandon_title>Leave the game?"), 18, UIUtil.titleFont)
    Layouter(title):AtTopIn(dialog, 16):AtHorizontalCenterIn(dialog):End()

    local subtitle = UIUtil.CreateText(dialog, LOC("<LOC abandon_recipient>Your army goes to:"), 14, UIUtil.bodyFont)
    Layouter(subtitle):Below(title, 8):AtHorizontalCenterIn(dialog):End()

    local list = ArmyListModule.AbandonArmyList(dialog, allies, allies[1].Army)
    Layouter(list):Below(subtitle, 10):AtLeftIn(dialog, 20):AtRightIn(dialog, 20)
        :Height(ArmyListModule.HeightForRows(math.min(VisibleRows, table.getn(allies)))):End()
    list:Refresh()

    local leaveButton = UIUtil.CreateButtonStd(dialog, "/widgets02/small", LOC("<LOC abandon_leave>Leave"), 14)
    local cancelButton = UIUtil.CreateButtonStd(dialog, "/widgets02/small", LOC("<LOC _Cancel>Cancel"), 14)
    Layouter(leaveButton):Below(list, 14)
        :Left(function() return dialog.Left() + dialog.Width() * 0.25 - leaveButton.Width() * 0.5 end):End()
    Layouter(cancelButton):Below(list, 14)
        :Left(function() return dialog.Left() + dialog.Width() * 0.75 - cancelButton.Width() * 0.5 end):End()

    local status = UIUtil.CreateText(dialog, LOC("<LOC abandon_leaving>Leaving..."), 14, UIUtil.bodyFont)
    Layouter(status):Below(list, 20):AtHorizontalCenterIn(dialog):End()
    status:Hide()

    -- the parts and the spacing between them, with as much space below the buttons as above the title
    dialog.Height:Set(function()
        return title.Height() + subtitle.Height() + list.Height() + leaveButton.Height()
            + LayoutHelpers.ScaleNumber(16 + 8 + 10 + 14 + 16)
    end)

    local popup = Popup(GetFrame(0), dialog)

    cancelButton.OnClick = function()
        popup:Close()
    end
    popup.OnEscapePressed = function()
        if not Leaving then
            popup:Close()
        end
    end
    popup.OnShadowClicked = popup.OnEscapePressed

    leaveButton.OnClick = function()
        Leaving = true
        leaveButton:Hide()
        cancelButton:Hide()
        status:Show()
        SimCallback({ Func = "SetAbandonRecipient", Args = { To = list.Selected } })
        ForkThread(function()
            WaitSeconds(LeaveDelay)
            leave()
        end)
    end
end
