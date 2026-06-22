--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The Map tab's content: the selected scenario's details as stacked, labelled sections —
--
--   Author
--   Jip Willem Wijnia
--
--   Reclaim
--   1.0M [mass] · 120k [energy]
--
--   Description
--   <scrollable text>
--
-- Each optional section (author, reclaim) collapses when the map doesn't declare it, so the
-- description floats up. The bottom action sub-area holds the "Open page" link (secondary, left,
-- when the map has an allowed url) and the host-only "Change map" button (primary, right). The
-- preview + name + size + players + version are pinned above the tab strip by the config
-- interface (the preview's textures aren't freed, so it must not be destroyed).
--
-- A config-interface tab panel: the host creates it when the Map tab is selected and destroys it
-- on switch, so it's the live/visible panel for its lifetime. `Initialize` (called by the host
-- after sizing it) binds the description's width + builds its scrollbar and renders.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyMapSelect = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapselect.lua")
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local ActionHeight = 40
local IconSize = 14
local PreviewMaxSize = 240           -- the square preview grows with the panel, capped to this
local NameMaxChars = 28
local LabelColor = 'ff8a909a'        -- the section labels (Author / Reclaim / Description)
local ValueColor = 'ffc8ccd0'
local MassIcon = "/game/build-ui/icon-mass_bmp.dds"
local EnergyIcon = "/game/build-ui/icon-energy_bmp.dds"

-- map pages we'll open in a browser, matched against the URL host (exact or as a subdomain).
-- Mirrors the map/mod dialogs; add a line to extend.
local AllowedUrlDomains = {
    "github.com",
    "githubusercontent.com",
    "gitlab.com",
    "github.io",
    "faforever.com",
}

--- The lowercased host of a URL (between the scheme and the first `/` or `:`), or "".
---@param url string
---@return string
local function UrlHost(url)
    local rest = string.gsub(string.lower(url), "^https?://", "")
    return (string.gsub(rest, "[/:].*$", ""))
end

--- Whether `url` is an http(s) link to an allowed domain (or a subdomain of one).
---@param url any
---@return boolean
local function IsAllowedUrl(url)
    if type(url) ~= 'string' or not string.find(string.lower(url), "^https?://") then
        return false
    end
    local host = UrlHost(url)
    for _, domain in AllowedUrlDomains do
        local escaped = string.gsub(domain, "%.", "%%.")
        if host == domain or string.find(host, "%." .. escaped .. "$") then
            return true
        end
    end
    return false
end

--- Downgrades an `https://` URL to `http://` — the engine's `OpenURL` only handles `http://`.
---@param url string
---@return string
local function ToOpenableUrl(url)
    return (string.gsub(url, "^https://", "http://"))
end

--- Formats a resource amount compactly: 1016424 -> "1.0M", 119858 -> "120k", 950 -> "950".
---@param amount number
---@return string
local function FormatAmount(amount)
    if amount >= 1000000 then
        return string.format("%.1fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("%.0fk", amount / 1000)
    end
    return string.format("%d", amount)
end

--- Truncates `text` to `maxChars`, appending "…" when it had to cut.
---@param text string
---@param maxChars number
---@return string
local function Truncate(text, maxChars)
    text = text or ""
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars - 1) .. "…"
    end
    return text
end

--- Number of start spots a scenario declares, or 0.
---@param scenario UILobbyScenarioInfo
---@return number
local function ArmyCount(scenario)
    local armies = scenario.Configurations
        and scenario.Configurations.standard
        and scenario.Configurations.standard.teams
        and scenario.Configurations.standard.teams[1]
        and scenario.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
end

---@class UICustomLobbyMapPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field IsHost boolean
---@field CurrentUrl string | false
---@field Preview UICustomLobbyMapPreview
---@field Name Text
---@field Info Text
---@field AuthorLabel Text
---@field AuthorValue Text
---@field ReclaimLabel Text
---@field ReclaimValue Group
---@field ReclaimMass Text
---@field ReclaimMassIcon Bitmap
---@field ReclaimEnergy Text
---@field ReclaimEnergyIcon Bitmap
---@field DescriptionLabel Text
---@field Description TextArea
---@field DescriptionScrollbar Scrollbar | false
---@field ActionArea Group
---@field UrlButton Text
---@field ChangeButton Button
---@field ScenarioObserver LazyVar
---@field IsHostObserver LazyVar
local CustomLobbyMapPanel = ClassUI(Group) {

    ---@param self UICustomLobbyMapPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyMapPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.IsHost = false
        self.CurrentUrl = false
        self.DescriptionScrollbar = false

        --#region map preview + name + size/players/version (preview left, the rest to its right)
        self.Preview = CustomLobbyMapPreview.Create(self, { Bound = true })
        self.Name = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        self.Name:DisableHitTest()
        self.Info = UIUtil.CreateText(self, "", 13, UIUtil.bodyFont)
        self.Info:SetColor('ff9aa0a8')
        self.Info:DisableHitTest()
        --#endregion

        --#region Author section
        self.AuthorLabel = self:CreateSectionLabel("Author")
        self.AuthorValue = UIUtil.CreateText(self, "", 13, UIUtil.bodyFont)
        self.AuthorValue:SetColor(ValueColor)
        self.AuthorValue:DisableHitTest()
        --#endregion

        --#region Reclaim section (amount + mass/energy icon, amount + energy icon)
        self.ReclaimLabel = self:CreateSectionLabel("Reclaim")
        self.ReclaimValue = Group(self, "CustomLobbyMapReclaim")
        self.ReclaimValue:DisableHitTest()
        self.ReclaimMass = UIUtil.CreateText(self.ReclaimValue, "", 13, UIUtil.bodyFont)
        self.ReclaimMass:SetColor(ValueColor)
        self.ReclaimMass:DisableHitTest()
        self.ReclaimMassIcon = Bitmap(self.ReclaimValue)
        self.ReclaimMassIcon:SetTexture(UIUtil.UIFile(MassIcon))
        self.ReclaimMassIcon:DisableHitTest()
        self.ReclaimEnergy = UIUtil.CreateText(self.ReclaimValue, "", 13, UIUtil.bodyFont)
        self.ReclaimEnergy:SetColor(ValueColor)
        self.ReclaimEnergy:DisableHitTest()
        self.ReclaimEnergyIcon = Bitmap(self.ReclaimValue)
        self.ReclaimEnergyIcon:SetTexture(UIUtil.UIFile(EnergyIcon))
        self.ReclaimEnergyIcon:DisableHitTest()
        --#endregion

        --#region Description section
        self.DescriptionLabel = self:CreateSectionLabel("Description")
        self.Description = TextArea(self, 200, 80)
        self.Description:SetFont(UIUtil.bodyFont, 12)
        self.Description:SetColors(ValueColor, "00000000", ValueColor, "00000000")
        --#endregion

        --#region actions
        self.ActionArea = Group(self, "CustomLobbyMapActions")

        self.UrlButton = UIUtil.CreateText(self.ActionArea, "Open page", 12, UIUtil.bodyFont)
        self.UrlButton:SetColor('ff7fb3ff')
        self.UrlButton:Hide()
        self.UrlButton.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.CurrentUrl then
                    OpenURL(ToOpenableUrl(self.CurrentUrl))
                end
                return true
            elseif event.Type == 'MouseEnter' then
                control:SetColor('ffaecbff')
                return true
            elseif event.Type == 'MouseExit' then
                control:SetColor('ff7fb3ff')
                return true
            end
            return false
        end
        Tooltip.AddControlTooltipManual(self.UrlButton, "Map page", "Open the map's web page in your browser.")

        self.ChangeButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Change map")
        self.ChangeButton.OnClick = function(button, modifiers)
            CustomLobbyMapSelect.Open(GetFrame(0))
        end
        --#endregion

        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().ScenarioFile, function(lazy)
                lazy()
                self:Refresh()
            end))
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLocalModel.GetSingleton().IsHost, function(isHostLazy)
                self.IsHost = isHostLazy()
                self:ApplyHostVisibility()
            end))
    end,

    ---@param self UICustomLobbyMapPanel
    __post_init = function(self)
        Layouter(self.ActionArea):AtLeftIn(self):AtRightIn(self):AtBottomIn(self):Height(ActionHeight):End()
        Layouter(self.ChangeButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.UrlButton):AtLeftIn(self.ActionArea, 6):AtVerticalCenterIn(self.ActionArea):End()

        -- the preview is a square on the left, growing with the panel height but capped so it never
        -- swallows the details column; the name, info and labelled sections stack to its right
        Layouter(self.Preview):AtLeftIn(self, 6):AtTopIn(self, 6):End()
        self.Preview.Height:Set(function()
            local avail = self.ActionArea.Top() - self.Preview.Top() - LayoutHelpers.ScaleNumber(8)
            return math.min(avail, LayoutHelpers.ScaleNumber(PreviewMaxSize))
        end)
        self.Preview.Width:Set(function() return self.Preview.Height() end)
        Layouter(self.Name):AnchorToRight(self.Preview, 12):AtTopIn(self, 6):End()
        Layouter(self.Info):AnchorToRight(self.Preview, 12):AnchorToBottom(self.Name, 4):End()

        -- the reclaim value row: amount + mass icon, amount + energy icon (fixed internal layout;
        -- the group's position is set by LayoutSections)
        LayoutHelpers.SetHeight(self.ReclaimValue, IconSize + 4)
        Layouter(self.ReclaimMass):AtLeftIn(self.ReclaimValue):AtVerticalCenterIn(self.ReclaimValue):End()
        Layouter(self.ReclaimMassIcon):AnchorToRight(self.ReclaimMass, 3):AtVerticalCenterIn(self.ReclaimValue):Width(IconSize):Height(IconSize):End()
        Layouter(self.ReclaimEnergy):AnchorToRight(self.ReclaimMassIcon, 10):AtVerticalCenterIn(self.ReclaimValue):End()
        Layouter(self.ReclaimEnergyIcon):AnchorToRight(self.ReclaimEnergy, 3):AtVerticalCenterIn(self.ReclaimValue):Width(IconSize):Height(IconSize):End()

        -- the description's left/right are fixed here so its Width can be bound in Initialize
        -- (the TextArea reflows on the Width bind, which reads Left/Right); its top/bottom are set
        -- dynamically by LayoutSections. Left = right of the preview, so it sits in the right column
        Layouter(self.Description):AnchorToRight(self.Preview, 12):AtRightIn(self, 32):End()
    end,

    --- Builds a dim section label (Author / Reclaim / Description). Private.
    ---@param self UICustomLobbyMapPanel
    ---@param text string
    ---@return Text
    CreateSectionLabel = function(self, text)
        local label = UIUtil.CreateText(self, text, 12, UIUtil.titleFont)
        label:SetColor(LabelColor)
        label:DisableHitTest()
        return label
    end,

    --- Binds the description's width + builds its scrollbar, then renders. Called by the host after
    --- it sizes the panel (the TextArea wraps to Width(), so it must be bound to the laid-out span
    --- now — see the TextArea gotcha in ../CLAUDE.md).
    ---@param self UICustomLobbyMapPanel
    Initialize = function(self)
        self.Ready = true
        self.Description.Width:Set(function() return self.Description.Right() - self.Description.Left() end)
        self.DescriptionScrollbar = UIUtil.CreateVertScrollbarFor(self.Description)
        self:Refresh()
        self:ApplyHostVisibility()

        -- the scrollbar's need depends on the reflowed line count vs the laid-out box height, and
        -- neither is final until a frame after mount — Initialize can run pre-frame (the tab host
        -- calls it synchronously). Re-check once settled so a fitting description doesn't keep a bar.
        self.Trash:Add(ForkThread(function()
            WaitFrames(1)
            if not IsDestroyed(self) then
                self:UpdateScrollbar()
            end
        end))
    end,

    --- Loads the current scenario's info and fills the labelled sections (author / reclaim /
    --- description) + the url link, collapsing sections the map doesn't provide.
    ---@param self UICustomLobbyMapPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local scenarioFile = CustomLobbyLaunchModel.GetSingleton().ScenarioFile()
        -- `info` is a table when a readable scenario is selected, else false (no map) / nil
        local info = scenarioFile and CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        local fields = type(info) == "table" and info or {}

        -- header: name + the size · players · version line
        if type(info) == "table" then
            self.Name:SetText(Truncate(LOC(info.name) or "?", NameMaxChars))
            local parts = {}
            if info.size then
                table.insert(parts, string.format("%dkm", math.floor(info.size[1] / 50)))
            end
            local players = ArmyCount(info)
            if players > 0 then
                table.insert(parts, players .. " players")
            end
            if info.map_version then
                table.insert(parts, "v" .. tostring(info.map_version))
            end
            self.Info:SetText(table.concat(parts, "   ·   "))
        else
            self.Name:SetText(scenarioFile and "Unknown map" or "No map selected")
            self.Info:SetText("")
        end

        local author = fields.author
        local reclaim = fields.reclaim
        local description = fields.description
        local hasAuthor = type(author) == "string" and author ~= ""
        local hasReclaim = type(reclaim) == "table" and reclaim[1] ~= nil and reclaim[2] ~= nil

        if hasAuthor then
            self.AuthorValue:SetText(author)
        end
        if hasReclaim then
            self.ReclaimMass:SetText(FormatAmount(reclaim[1]))
            self.ReclaimEnergy:SetText(FormatAmount(reclaim[2]))
        end
        self.Description:SetText((type(description) == "string" and LOC(description)) or "")

        self.CurrentUrl = IsAllowedUrl(fields.url) and fields.url or false
        if self.CurrentUrl then
            self.UrlButton:Show()
        else
            self.UrlButton:Hide()
        end

        self:LayoutSections(hasAuthor, hasReclaim)
        self:UpdateScrollbar()
    end,

    --- Stacks the visible sections top-to-bottom (collapsing absent ones) and floats the
    --- description into the remaining space above the action area.
    ---@param self UICustomLobbyMapPanel
    ---@param hasAuthor boolean
    ---@param hasReclaim boolean
    LayoutSections = function(self, hasAuthor, hasReclaim)
        -- everything lives in the column to the right of the preview, stacking below the info line
        local prev = self.Info

        -- places a label + value pair under `prev`, or hides both
        local function place(label, value, visible)
            if visible then
                label:Show()
                value:Show()
                Layouter(label):AnchorToRight(self.Preview, 12):AnchorToBottom(prev, 8):End()
                Layouter(value):AnchorToRight(self.Preview, 12):AnchorToBottom(label, 2):End()
                prev = value
            else
                label:Hide()
                value:Hide()
            end
        end

        place(self.AuthorLabel, self.AuthorValue, hasAuthor)
        place(self.ReclaimLabel, self.ReclaimValue, hasReclaim)

        -- description always shows; its label sits under the last visible section, then it fills
        -- the rest of the right column down to the action bar
        Layouter(self.DescriptionLabel):AnchorToRight(self.Preview, 12):AnchorToBottom(prev, 8):End()
        Layouter(self.Description)
            :AnchorToRight(self.Preview, 12):AtRightIn(self, 32)
            :AnchorToBottom(self.DescriptionLabel, 4):AnchorToTop(self.ActionArea, 8)
            :End()
    end,

    --- The change-map button is host-only.
    ---@param self UICustomLobbyMapPanel
    ApplyHostVisibility = function(self)
        if self.IsHost then
            self.ChangeButton:Show()
        else
            self.ChangeButton:Hide()
        end
    end,

    --- Shows the description's scrollbar only when it overflows.
    ---@param self UICustomLobbyMapPanel
    UpdateScrollbar = function(self)
        if not self.DescriptionScrollbar then
            return
        end
        if self.Description:GetTextHeight() > self.Description.Height() then
            self.DescriptionScrollbar:Show()
        else
            self.DescriptionScrollbar:Hide()
        end
    end,

    ---@param self UICustomLobbyMapPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyMapPanel
Create = function(parent)
    return CustomLobbyMapPanel(parent)
end
