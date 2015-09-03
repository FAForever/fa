--*****************************************************************************
--* File: lua/ui/dialogs/teamkill.lua
--* Author: Quark036
--* Summary: pops up to warn of a teamkill and ask if it should be reported
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local TextArea = import('/lua/ui/controls/textarea.lua').TextArea

local dialog = false
local shouldReport = false

function CreateDialog(teamkillTable)
    local killTime = teamkillTable.killTime
    WARN("Teamkill at tick" .. killTime)
    if dialog then
       return
    end
	
    local dialogContent = Group(GetFrame(0))
    dialogContent.Width:Set(600)
    dialogContent.Height:Set(200)

    dialog = Popup(GetFrame(0), dialogContent)

    local title = UIUtil.CreateText(dialogContent, "<LOC teamkill_0001>Teamkill Detected", 14, UIUtil.titleFont)
    LayoutHelpers.AtTopIn(title, dialogContent, 5)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)

    local infoText = TextArea(dialogContent, 590, 100)
    infoText:SetText(LOC("<LOC teamkill_0002>You have been killed by friendly fire. The deliberate killing of teammates is against FAF rules. If you feel your death was deliberate or unsportsmanlike, check the box below to report it."))
    LayoutHelpers.Below(infoText, title)
    LayoutHelpers.AtLeftIn(infoText, dialogContent, 5)

    local reportToMod = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', "<LOC teamkill_0003>Report this to a mod", true, 11)
    LayoutHelpers.AtBottomIn(reportToMod, dialogContent, 15)
    LayoutHelpers.AtLeftIn(reportToMod, dialogContent, 5)

    local okBtn = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Ok>")
    LayoutHelpers.AtHorizontalCenterIn(okBtn, dialogContent)
    LayoutHelpers.AtBottomIn(okBtn, dialogContent, 5)
    okBtn.OnClick = function(self, modifiers)
        dialog:Close()
    end

    dialog.OnClosed = function(self)
        dialog = false
        if reportToMod:IsChecked() then
            local armiesInfo = GetArmiesTable()
            local victimName = armiesInfo.armiesTable[teamkillTable.victim].nickname
            local killerName = armiesInfo.armiesTable[teamkillTable.instigator].nickname
            WARN("Was teamkilled: " .. victimName)
            WARN("At time: " .. killTime)
            WARN("Killed by: " .. killerName)
            GpgNetSend('Teamkill',  killTime,victimName,killerName)
        end
    end
end
