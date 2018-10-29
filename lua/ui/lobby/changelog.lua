local Combo = import('/lua/ui/controls/combo.lua').Combo
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local data = import('/lua/ui/lobby/changelogData.lua')

--- Creates the popup window with the game patch changelog.
function CreateUI(parent, showPatch)
    local dialogContent = Group(parent)
    dialogContent.Width:Set(1000)
    dialogContent.Height:Set(700)

    local changelogPopup = Popup(parent, dialogContent)
    changelogPopup.OnClosed = function()
        Prefs.SetToCurrentProfile('LobbyChangelog', data.last_version)
    end

    -- Title
    local Title = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0412>What's new to FAF?"), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(Title, dialogContent, 0)
    LayoutHelpers.AtTopIn(Title, dialogContent, 10)

    -- Dropdown menu to select a patch
    local VersionSelection = Combo(dialogContent, 12, 20, false, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
    VersionSelection._text:SetFont('Arial Gras', 15)
    VersionSelection.Width:Set(70)
    -- Fill it with all patch numbers
    local items = {}
    for _, patch in data.gamePatches do
        table.insert(items, patch.version)
    end
    VersionSelection:AddItems(items, 1)
    VersionSelection.OnClick = function(self, index, text)
        dialogContent.InfoList:DeleteAllItems()
        dialogContent.InfoList:AddItem(data.gamePatches[index].name)
        for _, v in data.gamePatches[index].description do
            dialogContent.InfoList:AddItem(v)
        end
        dialogContent.InfoList:AddItem('')
    end
    LayoutHelpers.AtTopIn(VersionSelection, dialogContent, 10)
    LayoutHelpers.AtRightIn(VersionSelection, dialogContent, 55)

    local VersionText = UIUtil.CreateText(dialogContent, "Select a patch: ", 15, UIUtil.bodyFont)
    VersionText:SetDropShadow(true)
    LayoutHelpers.CenteredLeftOf(VersionText, VersionSelection)

    -- Info List
    local InfoList = ItemList(dialogContent)
    dialogContent.InfoList = InfoList
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
    local LastChangelogVersion = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0
    if showPatch == true then
        LastChangelogVersion = LastChangelogVersion -1
    end
    for _, patch in data.gamePatches do
        if LastChangelogVersion < patch.version then
            InfoList:AddItem(patch.name)
            for _, v in patch.description do
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

    return LastChangelogVersion < data.last_version
end