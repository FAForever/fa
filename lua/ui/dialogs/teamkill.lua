--*****************************************************************************
--* File: lua/ui/dialogs/teamkill.lua
--* Author: Quark036
--* Summary: pops up to warn of a teamkill and ask if it should be reported
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local dialog = false
local shouldReport = false
local waitingTimeBeforeReport = 10;

function CreateDialog(teamkill)
    if dialog then
       return
    end

    local dialogContent = Group(GetFrame(0))
    LayoutHelpers.SetDimensions(dialogContent, 360, 180)

    dialog = Popup(GetFrame(0), dialogContent)

    local title = UIUtil.CreateText(dialogContent, "<LOC teamkill_0001>Teamkill Detected", 14, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local infoText = TextArea(dialogContent, 340, 100)
    infoText:SetText(LOC("<LOC teamkill_0002>You have been killed by friendly fire. The deliberate killing of teammates is against FAF rules. If you feel your death was deliberate or unsportsmanlike, press the button below to report it."))
    LayoutHelpers.Below(infoText, title)
    LayoutHelpers.AtLeftIn(infoText, dialogContent, 10)

    local forgiveBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC teamkill_0004>Forgive")
    LayoutHelpers.AtBottomIn(forgiveBtn, dialogContent, 10)
    LayoutHelpers.AtLeftIn(forgiveBtn, dialogContent, 10)
    forgiveBtn.OnClick = function(self, modifiers)
        KillThread(dialog.countdownThread)
        dialog:Close()
    end

    local reportBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC teamkill_0003>Report")
    LayoutHelpers.AtBottomIn(reportBtn, dialogContent, 10)
    LayoutHelpers.AtRightIn(reportBtn, dialogContent, 10)
    UIUtil.setEnabled(reportBtn, false)
    reportBtn.OnClick = function(self, modifiers)
        GpgNetSend('TeamkillReport',  teamkill.time, teamkill.victim.id, teamkill.victim.name, teamkill.instigator.id, teamkill.instigator.name)
        WARN("TEAMKILL WAS REPORTED")
        dialog:Close()
    end

    dialog.OnClosed = function(self)
        dialog = false
    end

    dialog.OnEscapePressed = function(self)
    end

    dialog.OnShadowClicked = function(self)
    end

    dialog.countdownThread = ForkThread(WaitBeforeEnablingReportButton, reportBtn)
end

function WaitBeforeEnablingReportButton(reportBtn)
    local waitedTime = 0;
    while waitedTime < waitingTimeBeforeReport do
        reportBtn.label:SetText(LOC("<LOC teamkill_0003>Report").."["..(waitingTimeBeforeReport-waitedTime).."]")
        WaitSeconds(1)
        waitedTime = waitedTime + 1
    end
    reportBtn.label:SetText(LOC("<LOC teamkill_0003>Report"))
    UIUtil.setEnabled(reportBtn, true)
end
