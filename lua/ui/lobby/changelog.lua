
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local data = import("/lua/ui/lobby/changelogdata.lua")

--- Test if we should display the changelog of the new game version.
---@return boolean
function OpenChangelog()
    local LastChangelogVersion = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0
    return LastChangelogVersion < data.last_version
end

--- Toggles the debug interface that shows the various groups that are used to divide the dialog
local debugInterface = false 

--- A bit of a hack, but allows us to keep track of whether the changelog is open or not. The lobby
-- is (almost aggressively) trying to keep control of the keyboard on the chat box to prevent hotkeys
-- from working :sad:
isOpen = false

---@class Changelog : Group
Changelog = ClassUI(Group) {

    __init = function(self, parent)
        Group.__init(self, parent)

        -- occupy center of screen

        LayoutHelpers.SetDimensions(self, 1000, 700)
        LayoutHelpers.AtCenterIn(self, parent)

        -- allow us to use escape to quickly get out

        isOpen = true 
        EscapeHandler.PushEscapeHandler(
            function()
                self:Close()
            end
        )

        -- make sure we're on top of everything else 

        self.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

        -- debugging

        self.Debug = Group(self)
        LayoutHelpers.FillParent(self.Debug, self)

        -- setup

        self.CommonUI = Group(self)
        LayoutHelpers.FillParent(self.CommonUI, self)

        self.Border = UIUtil.SurroundWithBorder(self.CommonUI, '/scx_menu/lan-game-lobby/frame/')

        self.Background = Bitmap(self.CommonUI)
        self.Background:SetSolidColor("99111111")
        LayoutHelpers.FillParent(self.Background, GetFrame(0))

        self.DialogBackground = Bitmap(self.CommonUI)
        self.DialogBackground:SetSolidColor("99111111")
        LayoutHelpers.FillParent(self.DialogBackground, self.CommonUI)

        -- header

        self.Header = Group(self.CommonUI)
        self.Header.Left:Set(self.CommonUI.Left)
        self.Header.Top:Set(self.CommonUI.Top)
        self.Header.Right:Set(self.CommonUI.Right)
        self.Header.Bottom:Set(function() return self.CommonUI.Top() + LayoutHelpers.ScaleNumber(50) end)

        self.HeaderDebug = Bitmap(self.Debug)
        self.HeaderDebug:SetSolidColor("ffff0000")
        LayoutHelpers.FillParent(self.HeaderDebug, self.Header)

        self.HeaderTitle = UIUtil.CreateText(self.CommonUI, LOC("Changelog of Supreme Commander: Forged Alliance Forever"), 17, 'Arial Gras', true)
        LayoutHelpers.AtVerticalCenterIn(self.HeaderTitle, self.Header)
        self.HeaderTitle.Left:Set(function() return self.Header.Left() + LayoutHelpers.ScaleNumber(10) end)

        self.HeaderEscapeButton = UIUtil.CreateButtonStd(self.CommonUI, '/game/menu-btns/close', "", 12)
        LayoutHelpers.AtVerticalCenterIn(self.HeaderEscapeButton, self.Header)
        LayoutHelpers.DepthOverParent(self.HeaderEscapeButton, self.CommonUI, 5)
        self.HeaderEscapeButton.Right:Set(function() return self.Header.Right() - LayoutHelpers.ScaleNumber(10) end)
        self.HeaderEscapeButton.OnClick = function()
            self:Close()
        end

        self.HeaderSubtitle = UIUtil.CreateText(self.CommonUI, LOC("Game version 3700"), 17, 'Arial Gras', true)
        LayoutHelpers.AtVerticalCenterIn(self.HeaderSubtitle, self.Header)
        self.HeaderSubtitle.Right:Set(function() return self.HeaderEscapeButton.Left() - LayoutHelpers.ScaleNumber(20) end)

        -- footer

        self.Footer = Group(self.CommonUI)
        self.Footer.Left:Set(self.CommonUI.Left)
        self.Footer.Top:Set(function() return self.CommonUI.Bottom() - LayoutHelpers.ScaleNumber(50) end)
        self.Footer.Right:Set(self.CommonUI.Right)
        self.Footer.Bottom:Set(self.CommonUI.Bottom)

        self.FooterDebug = Bitmap(self.Debug)
        self.FooterDebug:SetSolidColor("ff00ff00")
        LayoutHelpers.FillParent(self.FooterDebug, self.Footer)

        self.FooterGithubButton = UIUtil.CreateButtonWithDropshadow(self.Footer, '/BUTTON/medium/', "Github")
        LayoutHelpers.AtVerticalCenterIn(self.FooterGithubButton, self.Footer)
        LayoutHelpers.DepthOverParent(self.FooterGithubButton, self.Footer, 5)
        self.FooterGithubButton.Left:Set(function() return self.Footer.Left() - LayoutHelpers.ScaleNumber(10) end)
        self.FooterGithubButton.OnClick = function()
            OpenURL('http://github.com/FAForever/fa/releases')
        end

        self.FooterBetaBalanceButton = UIUtil.CreateButtonWithDropshadow(self.Footer, '/BUTTON/medium/', "Beta Balance")
        LayoutHelpers.AtVerticalCenterIn(self.FooterBetaBalanceButton, self.Footer)
        LayoutHelpers.DepthOverParent(self.FooterBetaBalanceButton, self.Footer, 5)
        self.FooterBetaBalanceButton.Left:Set(function() return self.FooterGithubButton.Right() - LayoutHelpers.ScaleNumber(20) end)
        self.FooterBetaBalanceButton.OnClick = function()
            OpenURL('http://patchnotes.faforever.com/fafbeta')
        end

        self.FooterDevelopButton = UIUtil.CreateButtonWithDropshadow(self.Footer, '/BUTTON/medium/', "FAF Develop")
        LayoutHelpers.AtVerticalCenterIn(self.FooterDevelopButton, self.Footer)
        LayoutHelpers.DepthOverParent(self.FooterDevelopButton, self.Footer, 5)
        self.FooterDevelopButton.Left:Set(function() return self.FooterBetaBalanceButton.Right() - LayoutHelpers.ScaleNumber(20) end)
        self.FooterDevelopButton.OnClick = function()
            OpenURL('http://patchnotes.faforever.com/fafdevelop')
        end

        self.FooterDiscordButton = UIUtil.CreateButtonWithDropshadow(self.Footer, '/BUTTON/medium/', "Report a bug")
        LayoutHelpers.AtVerticalCenterIn(self.FooterDiscordButton, self.Footer)
        LayoutHelpers.DepthOverParent(self.FooterDiscordButton, self.Footer, 5)
        self.FooterDiscordButton.Left:Set(function() return self.Footer.Right() - LayoutHelpers.ScaleNumber(170) end)
        self.FooterDiscordButton.OnClick = function()
            OpenURL('http://discord.gg/pK94Dk9hNz')
        end

        -- content

        self.Content = Group(self)
        self.Content.Left:Set(self.CommonUI.Left)
        self.Content.Right:Set(self.CommonUI.Right)
        self.Content.Top:Set(self.Header.Bottom)
        self.Content.Bottom:Set(self.Footer.Top)

        self.ContentDebug = Bitmap(self.Debug)
        self.ContentDebug:SetSolidColor("ff0000ff")
        LayoutHelpers.FillParent(self.ContentDebug, self.Content)

        self.ContentNotes = Group(self.Content)
        LayoutHelpers.FillParent(self.ContentNotes, self.Content)
        self.ContentNotes.Right:Set(function() return self.Content.Right() - LayoutHelpers.ScaleNumber(200) end)

        self.ContentNotesDebug = Bitmap(self.Debug)
        self.ContentNotesDebug:SetSolidColor("9900ff00")
        LayoutHelpers.FillParent(self.ContentNotesDebug, self.ContentNotes)

        self.ContentPatches = Group(self.Content)
        LayoutHelpers.FillParent(self.ContentPatches, self.Content)
        self.ContentPatches.Left:Set(function() return self.ContentNotes.Right() end)

        self.ContentPatchesDebug = Bitmap(self.Debug)
        self.ContentPatchesDebug:SetSolidColor("99ff0000")
        LayoutHelpers.FillParent(self.ContentPatchesDebug, self.ContentPatches)

        self.ContentDivider = Bitmap(self.CommonUI)
        self.ContentDivider:SetSolidColor("99ffffff")
        self.ContentDivider.Left:Set(function() return self.ContentNotes.Right() + 1 end)
        self.ContentDivider.Top:Set(function() return self.Content.Top() + LayoutHelpers.ScaleNumber(10) end)
        self.ContentDivider.Right:Set(self.ContentNotes.Right)
        self.ContentDivider.Bottom:Set(function() return self.Content.Bottom() - LayoutHelpers.ScaleNumber(10) end)

        -- patches 

        self.ContentPatchesList = ItemList(self.ContentPatches)
        LayoutHelpers.FillParentFixedBorder(self.ContentPatchesList, self.ContentPatches, 12)
        self.ContentPatchesList.Right:Set(function() return self.ContentPatches.Right() - LayoutHelpers.ScaleNumber(24) end)

        self.ContentPatchesList:SetFont(UIUtil.bodyFont, 12)
        self.ContentPatchesList:SetColors("ffffffff", "00000000")
        self.ContentPatchesList:ShowMouseoverItem(true)

        UIUtil.CreateLobbyVertScrollbar(self.ContentPatchesList)
        self.ContentPatchesList.OnClick = function(element, row, event)
            self:PopulateWithPatch(row)
        end

        -- patchnotes

        self.ContentNotesList = ItemList(self.ContentNotes)
        LayoutHelpers.FillParentFixedBorder(self.ContentNotesList, self.ContentNotes, 12)
        self.ContentNotesList.Right:Set(function() return self.ContentNotes.Right() - LayoutHelpers.ScaleNumber(24) end)

        self.ContentNotesList:SetFont(UIUtil.bodyFont, 12)
        self.ContentNotesList:SetColors("ffffffff", "00000000")
        self.ContentNotesList:ShowMouseoverItem(true)

        UIUtil.CreateLobbyVertScrollbar(self.ContentNotesList)
        self.ContentNotesList.OnClick = function(element, row, event) end

        -- Populate

        self:PopulatePatchList()
        self:PopulateWithPatch(0)

        if not debugInterface then 
            self.Debug:Hide()
        end

    end,

    --- Populates the dialog with the given patch
    PopulateWithPatch = function(self, index)
        local patch = data.gamePatches[index + 1]
        if patch then 
            self.ContentPatchesList:SetSelection(index)
            self.HeaderSubtitle:SetText(patch.name)
            self.ContentNotesList:DeleteAllItems()

            local altDescription = LOC("<LOC ChangelogDescriptionIdentifier>")
            for k, line in patch[altDescription] or patch.description do 
                self.ContentNotesList:AddItem(line)
            end
        end
    end,

    --- Populates the list of patches
    PopulatePatchList = function(self)
        self.ContentPatchesList:DeleteAllItems()
        for k, patch in data.gamePatches do 
            self.ContentPatchesList:AddItem(patch.version .. " - " .. patch.name)
        end
    end,

    --- Destroys the dialog
    Close = function(self)

        -- prevent the dialog from popping up again
        Prefs.SetToCurrentProfile('LobbyChangelog', data.last_version)

        isOpen = false
        EscapeHandler.PopEscapeHandler()

        -- go into oblivion
        self:Destroy()
    end,
}