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

-- The Logs tab of the lobby's bottom-left tabbed panel: a live, scrolling view of this peer's
-- network traffic (every message it broadcasts / sends / receives), fed by `CustomLobbyLog`. Each
-- line is `mm:ss  <arrow> Type [→/← peer]` — outgoing broadcasts (»»), single sends (»), and
-- incoming messages («). Because each peer logs only its own traffic, the host's and a client's
-- views differ naturally.
--
-- A bottom-left tab content component: created when its tab is selected and destroyed on switch (see
-- ../CustomLobbyTabs.lua), so it's the live panel for its whole lifetime — the model observer just
-- rebuilds it (Refresh is Ready-gated). `Initialize` (called by the tabs container after sizing it)
-- builds the scrollbar + does the first render (the list needs a concrete height — three-phase init).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local CustomLobbyLog = import("/lua/ui/lobby/customlobby/customlobbylog.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local Inset = 4
local TextColor = 'ffb0b6be'
local Transparent = '00000000'

-- per-kind arrow prefix (no colour — ItemList colours are list-wide, so the glyph carries direction)
local KindPrefix = {
    broadcast = "»»",
    send = "»",
    recv = "«",
}

--- `mm:ss` from a seconds offset (Lua 5.0 — no `%`, use `math.mod`).
---@param seconds number
---@return string
local function FormatClock(seconds)
    local whole = math.floor(seconds)
    return string.format("%02d:%02d", math.floor(whole / 60), math.mod(whole, 60))
end

--- One log line: `mm:ss  <arrow> Type [→/← peer]`.
---@param entry UICustomLobbyLogEntry
---@return string
local function FormatEntry(entry)
    local line = FormatClock(entry.Time) .. "  " .. (KindPrefix[entry.Kind] or "·") .. " " .. entry.Type
    if entry.Peer then
        if entry.Kind == 'recv' then
            line = line .. "  ← " .. tostring(entry.Peer)
        elseif entry.Kind == 'send' then
            line = line .. "  → " .. tostring(entry.Peer)
        end
    end
    return line
end

---@class UICustomLobbyLogsPanel : Group
---@field Trash TrashBag
---@field Ready boolean
---@field List ItemList
---@field Scrollbar Scrollbar | false
---@field Empty Text
---@field EntriesObserver LazyVar
local CustomLobbyLogsPanel = ClassUI(Group) {

    ---@param self UICustomLobbyLogsPanel
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyLogsPanel")

        self.Trash = TrashBag()
        self.Ready = false
        self.Scrollbar = false

        self.List = ItemList(self, "CustomLobbyLogList")
        self.List:SetFont(UIUtil.bodyFont, 12)
        -- foreground only; background / selection / mouseover transparent (read-only feed)
        self.List:SetColors(TextColor, Transparent, TextColor, Transparent, TextColor, Transparent)
        self.List:DeleteAllItems()

        self.Empty = UIUtil.CreateText(self, "No messages yet", 13, UIUtil.bodyFont)
        self.Empty:SetColor('ff5a606a')
        self.Empty:DisableHitTest()
        self.Empty:Hide()

        -- created/destroyed with its tab, so always the live panel while it exists — the observer
        -- just rebuilds (Refresh is Ready-gated until Initialize sizes the list)
        self.EntriesObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLog.GetSingleton().Entries, function(entriesLazy)
                entriesLazy()
                self:Refresh()
            end))
    end,

    ---@param self UICustomLobbyLogsPanel
    __post_init = function(self)
        Layouter(self.List)
            :AtLeftIn(self, Inset):AtTopIn(self, Inset):AtBottomIn(self, Inset)
            :End()
        -- leave room for the scrollbar on the right
        self.List.Right:Set(function() return self.Right() - LayoutHelpers.ScaleNumber(Inset + 14) end)
        Layouter(self.Empty):AtHorizontalCenterIn(self):AtTopIn(self, 8):End()
    end,

    --- Builds the scrollbar + does the first render. Called by the tabs container after it has sized
    --- the panel (the list needs a concrete height — three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyLogsPanel
    Initialize = function(self)
        self.Ready = true
        self.Scrollbar = UIUtil.CreateVertScrollbarFor(self.List)
        self:Refresh()
    end,

    --- Rebuilds the list from the current log entries and scrolls to the newest.
    ---@param self UICustomLobbyLogsPanel
    Refresh = function(self)
        if not self.Ready then
            return
        end
        local entries = CustomLobbyLog.GetSingleton().Entries()
        self.List:DeleteAllItems()
        for _, entry in entries do
            self.List:AddItem(FormatEntry(entry))
        end
        if table.getn(entries) > 0 then
            self.Empty:Hide()
            self.List:ScrollToBottom()
        else
            self.Empty:Show()
        end
    end,

    ---@param self UICustomLobbyLogsPanel
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

---@param parent Control
---@return UICustomLobbyLogsPanel
Create = function(parent)
    return CustomLobbyLogsPanel(parent)
end
