local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local data = import('/lua/ui/lobby/changelogData.lua')

function CreateUI(parent, showPatch)
    local dialogContent = Group(parent)
    dialogContent.Width:Set(1000)
    dialogContent.Height:Set(700)

    local Changelog = import('/lua/ui/lobby/changelogData.lua')
    local changelogPopup = Popup(parent, dialogContent)
    changelogPopup.OnClosed = function()
        Prefs.SetToCurrentProfile('LobbyChangelog', Changelog.last_version)
    end

    -- Title
    local Title = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0412>What's new to FAF?"), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(Title, dialogContent, 0)
    LayoutHelpers.AtTopIn(Title, dialogContent, 10)

    -- Info List
    local InfoList = ItemList(dialogContent)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    InfoList:SetColors(nil, "00000000")
    InfoList.Width:Set(972)
    InfoList.Height:Set(610)
    LayoutHelpers.AtLeftIn(InfoList, dialogContent, 10)
    LayoutHelpers.AtRightIn(InfoList, dialogContent, 26)
    LayoutHelpers.AtTopIn(InfoList, dialogContent, 38)
    UIUtil.CreateLobbyVertScrollbar(InfoList)
    InfoList.OnClick = function(self)
    end

    -- See only new Changelog by version
    local Last_Changelog_Version = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0
    if showPatch == true then
        Last_Changelog_Version = Last_Changelog_Version -1
    end
    for i, d in Changelog.changelog do
        if Last_Changelog_Version < d.version then
            InfoList:AddItem(d.name)
            for k, v in d.description do
                InfoList:AddItem(v)
            end
            InfoList:AddItem('')
        end
    end

    -- Close button
    local CloseButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', '<LOC _Close>Close')
    LayoutHelpers.AtLeftIn(CloseButton, dialogContent, 0)
    LayoutHelpers.AtBottomIn(CloseButton, dialogContent, 10)
    CloseButton.OnClick = function()
        changelogPopup:Close()
    end

    -- Link to the changelog on github
    local ChangelogButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "All Changes")
    LayoutHelpers.AtRightIn(ChangelogButton, dialogContent, 0)
    LayoutHelpers.AtBottomIn(ChangelogButton, dialogContent, 10)
    ChangelogButton.OnClick = function()
        OpenURL('http://github.com/FAForever/fa/blob/develop/changelog.md')
    end
end

--- Test if we should display the changelog of the new game version.
-- @return true/false
function NeedChangelog()
    local LastChangelogVersion = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0

    if LastChangelogVersion < data.last_version then
        return true
    end
    return false
end