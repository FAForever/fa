
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatFactionBadge = import("/lua/ui/game/chat/ChatFactionBadge.lua").ChatFactionBadge

local UIMain = import("/lua/ui/uimain.lua")

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local Debug = false

--- One picker row: label, hover backdrop, optional faction badge for player rows, and the recipient it sets.
---@class UIChatListEntry
---@field Text   Text
---@field BG     Bitmap
---@field Badge? ChatFactionBadge      # only present on player entries
---@field Target UIChatRecipient

-------------------------------------------------------------------------------
-- Popup recipient picker. Lists "All", "Allies", and one entry per
-- connected non-local human player (`GetSessionClients` excludes bots and
-- disconnected players). Each open rebuilds from fresh session state.

--- Recipient-picker popup; rebuilt from session state on every open so disconnects drop out.
---@class UIChatListInterface : Group
---@field Entries UIChatListEntry[]
---@field LTBG    Bitmap
---@field RTBG    Bitmap
---@field RBBG    Bitmap
---@field RLBG    Bitmap
---@field LBG     Bitmap
---@field RBG     Bitmap
---@field TBG     Bitmap
---@field BBG     Bitmap
---@field DebugBG? Bitmap                # semi-transparent overlay shown when `Debug` is true
ChatListInterface = ClassUI(Group) {

    ---@param self UIChatListInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatListInterface")
        self:DisableHitTest()

        -- +100 keeps us above the line rows' default ChatLinesInterface+1
        -- depth so hover and click events reach us first.
        LayoutHelpers.DepthOverParent(self, parent, 100)

        self.Entries = {}
        for _, def in ipairs(self:BuildTargetDefs()) do
            table.insert(self.Entries, self:CreateEntry(def))
        end

        self:CreateBorder()

        local function onOutsideClick() self:Destroy() end
        UIMain.AddOnMouseClickedFunc(onOutsideClick)

        self.OnDestroy = function(dself)
            UIMain.RemoveOnMouseClickedFunc(onOutsideClick)
            if dself._OnClosed then
                local cb = dself._OnClosed
                dself._OnClosed = nil
                cb()
            end
        end
    end,

    --- Returns target defs: All, Allies, then one entry per connected
    --- non-local human player.
    ---@param self UIChatListInterface
    ---@return table[]
    BuildTargetDefs = function(self)
        -- Client matched to army by nickname. Target stays an army ID
        -- so the send path is unchanged.
        local defs = {
            { Nickname = "All",    Target = ChatModel.RecipientAll },
            { Nickname = "Allies", Target = ChatModel.RecipientAllies },
        }

        local armies = GetArmiesTable().armiesTable
        for _, client in GetSessionClients() do
            if client.connected and not client['local'] then
                for armyID, armyData in armies do
                    if not armyData.civilian and armyData.nickname == client.name then
                        table.insert(defs, {
                            Nickname = client.name,
                            Target   = armyID,
                            Faction  = armyData.faction,
                            Color    = armyData.color,
                        })
                        break
                    end
                end
            end
        end

        return defs
    end,

    --- Builds one row from a target def, including the faction badge for player rows.
    ---@param self UIChatListInterface
    ---@param def table
    ---@return UIChatListEntry
    CreateEntry = function(self, def)
        local entry = {
            Target = def.Target,
            Text   = UIUtil.CreateText(self, def.Nickname, 12, "Arial"),
        }
        entry.Text:SetColor('ffffffff')
        entry.Text:DisableHitTest()

        entry.BG = Bitmap(entry.Text)
        entry.BG:SetSolidColor('ff000000')

        if def.Color then
            entry.Badge = ChatFactionBadge(self, def.Faction, def.Color)
        end

        local target = def.Target
        entry.BG.HandleEvent = function(bg, event)
            ChatController.NotifyActivity()
            if event.Type == 'MouseEnter' then
                bg:SetSolidColor('ff666666')
            elseif event.Type == 'MouseExit' then
                bg:SetSolidColor('ff000000')
            elseif event.Type == 'ButtonPress' then
                ChatController.SetRecipient(target)
                self:Destroy()
            end
        end

        return entry
    end,

    --- Eight decorative border bitmaps. Layout applied in `LayoutBorder`.
    ---@param self UIChatListInterface
    CreateBorder = function(self)
        local function makeBitmap(file)
            local bmp = Bitmap(self, UIUtil.UIFile(file))
            bmp:DisableHitTest()
            return bmp
        end

        self.LTBG = makeBitmap('/game/chat_brd/drop-box_brd_ul.dds')
        self.RTBG = makeBitmap('/game/chat_brd/drop-box_brd_ur.dds')
        self.RBBG = makeBitmap('/game/chat_brd/drop-box_brd_lr.dds')
        self.RLBG = makeBitmap('/game/chat_brd/drop-box_brd_ll.dds')
        self.LBG  = makeBitmap('/game/chat_brd/drop-box_brd_vert_l.dds')
        self.RBG  = makeBitmap('/game/chat_brd/drop-box_brd_vert_r.dds')
        self.TBG  = makeBitmap('/game/chat_brd/drop-box_brd_horz_um.dds')
        self.BBG  = makeBitmap('/game/chat_brd/drop-box_brd_lm.dds')
    end,

    ---@param self UIChatListInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local maxWidth = 0
        local totalHeight = 0
        for _, entry in ipairs(self.Entries) do
            local w = entry.Text.Width()
            if w > maxWidth then maxWidth = w end
            totalHeight = totalHeight + entry.Text.Height()
        end

        Layouter(self)
            :Width(maxWidth + 40)
            :Height(totalHeight)
            :End()

        -- Left indent reserves room for the faction badge on player rows.
        local textIndent = 20

        for i, entry in ipairs(self.Entries) do
            local below = i > 1 and self.Entries[i - 1] or nil
            self:LayoutEntry(entry, below, textIndent)
        end

        self:LayoutBorder()

        if Debug then
            self.DebugBG = Bitmap(self)
            self.DebugBG:SetSolidColor('40ffff40')
            self.DebugBG:DisableHitTest()
            Layouter(self.DebugBG):Fill(self):Over(self, 100):End()
        end
    end,

    --- Lays out one row above the previous one (or pinned to the bottom for the first).
    ---@param self UIChatListInterface
    ---@param entry UIChatListEntry
    ---@param below UIChatListEntry | nil
    ---@param textIndent number
    LayoutEntry = function(self, entry, below, textIndent)
        if below then
            Layouter(entry.Text)
                :Above(below.Text)
                :AtLeftIn(self, textIndent)
                :Over(self, 1)
                :End()
        else
            Layouter(entry.Text)
                :AtBottomIn(self)
                :AtLeftIn(self, textIndent)
                :Over(self, 1)
                :End()
        end

        if entry.Badge then
            Layouter(entry.Badge)
                :AtLeftIn(self, 3)
                :AtVerticalCenterIn(entry.Text)
                :Over(self, 2)
                :End()
        end

        -- Direct `:SetFunction` calls bypass Layouter's reused-state
        -- pool and skip its auto-scale, so pixel offsets need
        -- `ScaleNumber` by hand.
        local text = entry.Text
        local bgInsetLeft = LayoutHelpers.ScaleNumber(6)
        local bgInsetWidth = LayoutHelpers.ScaleNumber(8)
        local onePxScaled = LayoutHelpers.ScaleNumber(1)
        ---@diagnostic disable: undefined-field
        entry.BG.Depth:SetFunction(function() return text.Depth() - 1 end)
        entry.BG.Left:SetFunction(function() return self.Left() - bgInsetLeft end)
        entry.BG.Top:SetFunction(function() return text.Top() - onePxScaled end)
        entry.BG.Width:SetFunction(function() return self.Width() + bgInsetWidth end)
        entry.BG.Bottom:SetFunction(function() return text.Bottom() + onePxScaled end)
        ---@diagnostic enable: undefined-field
    end,

    --- Pins the eight border bitmaps around our rect.
    ---@param self UIChatListInterface
    LayoutBorder = function(self)
        Layouter(self.LTBG):Right(self.Left):Bottom(self.Top):End()
        Layouter(self.RTBG):Left(self.Right):Bottom(self.Top):End()
        Layouter(self.RBBG):Left(self.Right):Top(self.Bottom):End()
        Layouter(self.RLBG):Right(self.Left):Top(self.Bottom):End()
        Layouter(self.LBG):Right(self.Left):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.RBG):Left(self.Right):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.TBG):Left(self.Left):Right(self.Right):Bottom(self.Top):End()
        Layouter(self.BBG):Left(self.Left):Right(self.Right):Top(self.Bottom):End()
    end,

    --- Registers a callback to fire when this popup is destroyed (e.g. on outside click).
    ---@param self UIChatListInterface
    ---@param callback function
    SetOnClosed = function(self, callback)
        self._OnClosed = callback
    end,
}
