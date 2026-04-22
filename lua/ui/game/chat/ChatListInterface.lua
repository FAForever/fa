
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local UIMain = import("/lua/ui/uimain.lua")

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UIChatListEntry
---@field text   Text
---@field bg     Bitmap
---@field target UIChatRecipient

-------------------------------------------------------------------------------
-- A popup recipient picker. Lists "All", "Allies", and one entry per
-- connected non-local human player (sourced from `GetSessionClients`, so
-- bots and disconnected players are excluded). Clicking an entry calls
-- `ChatController.SetRecipient` and destroys the popup. Clicking anywhere
-- outside also destroys the popup — every open of the list rebuilds from
-- fresh session state.

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
ChatListInterface = ClassUI(Group) {

    ---@param self UIChatListInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "ChatListInterface")
        self:DisableHitTest()

        -- Popups must sit above the chat window's inner content (line rows,
        -- edit area) to receive hover and click events. A plain +1 offset
        -- ties with the line rows, which default to LinesContainer+1 —
        -- matching the list's default depth. +100 gives unambiguous headroom.
        LayoutHelpers.DepthOverParent(self, parent, 100)

        -- Build the list of selectable targets: All, Allies, then one entry
        -- per connected human player. `GetSessionClients` naturally excludes
        -- bots (they are not session clients); we additionally skip the
        -- local client (you can't privately message yourself) and any
        -- disconnected player. A client's army is found by matching
        -- nickname — the target stays an army ID so the send path continues
        -- to work unchanged.
        local defs = {
            { nickname = "All",    target = ChatModel.RecipientAll },
            { nickname = "Allies", target = ChatModel.RecipientAllies },
        }

        local armies = GetArmiesTable().armiesTable
        for _, client in GetSessionClients() do
            if client.connected and not client['local'] then
                for armyID, armyData in armies do
                    if not armyData.civilian and armyData.nickname == client.name then
                        table.insert(defs, { nickname = client.name, target = armyID })
                        break
                    end
                end
            end
        end

        self.Entries = {}
        for _, def in ipairs(defs) do
            local entry = {
                target = def.target,
                text   = UIUtil.CreateText(self, def.nickname, 12, "Arial"),
            }
            entry.text:SetColor('ffffffff')
            entry.text:DisableHitTest()

            entry.bg = Bitmap(entry.text)
            entry.bg:SetSolidColor('ff000000')

            -- Capture target in a local so each entry closes over its own value.
            local target = def.target
            entry.bg.HandleEvent = function(bg, event)
                if event.Type == 'MouseEnter' then
                    bg:SetSolidColor('ff666666')
                elseif event.Type == 'MouseExit' then
                    bg:SetSolidColor('ff000000')
                elseif event.Type == 'ButtonPress' then
                    ChatController.SetRecipient(target)
                    self:Destroy()
                end
            end

            table.insert(self.Entries, entry)
        end

        -- Decorative border bitmaps that sit outside the popup's bounds.
        self.LTBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
        self.LTBG:DisableHitTest()
        self.RTBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
        self.RTBG:DisableHitTest()
        self.RBBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
        self.RBBG:DisableHitTest()
        self.RLBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
        self.RLBG:DisableHitTest()
        self.LBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
        self.LBG:DisableHitTest()
        self.RBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
        self.RBG:DisableHitTest()
        self.TBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
        self.TBG:DisableHitTest()
        self.BBG = Bitmap(self, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
        self.BBG:DisableHitTest()

        -- Close on any mouse click outside the popup.
        local function onOutsideClick() self:Destroy() end
        UIMain.AddOnMouseClickedFunc(onOutsideClick)

        self.OnDestroy = function(dself)
            UIMain.RemoveOnMouseClickedFunc(onOutsideClick)
            if dself._onClosed then
                local cb = dself._onClosed
                dself._onClosed = nil
                cb()
            end
        end
    end,

    ---@param self UIChatListInterface
    ---@param parent Control
    __post_init = function(self, parent)
        -- Measure the text entries so we can size ourselves to fit.
        local maxWidth = 0
        local totalHeight = 0
        for _, entry in ipairs(self.Entries) do
            local w = entry.text.Width()
            if w > maxWidth then maxWidth = w end
            totalHeight = totalHeight + entry.text.Height()
        end

        Layouter(self)
            :Width(maxWidth + 40)
            :Height(totalHeight)
            :End()

        -- Stack entries bottom-up: first entry at the bottom-left, each
        -- subsequent entry above the previous.
        for i, entry in ipairs(self.Entries) do
            if i == 1 then
                Layouter(entry.text)
                    :AtLeftBottomIn(self)
                    :Over(self, 1)
                    :End()
            else
                Layouter(entry.text)
                    :Above(self.Entries[i-1].text)
                    :AtLeftIn(self)
                    :Over(self, 1)
                    :End()
            end

            -- The highlight bar extends slightly past the text in every
            -- direction and sits behind it in the depth order. Direct
            -- LazyVar `:SetFunction` calls match the original `chat.lua`
            -- pattern and avoid Layouter's reused-state quirks.
            local text = entry.text
            ---@diagnostic disable: undefined-field
            entry.bg.Depth:SetFunction(function() return text.Depth() - 1 end)
            entry.bg.Left:SetFunction(function() return text.Left() - 6 end)
            entry.bg.Top:SetFunction(function() return text.Top() - 1 end)
            entry.bg.Width:SetFunction(function() return self.Width() + 8 end)
            entry.bg.Bottom:SetFunction(function() return text.Bottom() + 1 end)
            ---@diagnostic enable: undefined-field
        end

        -- Border bitmaps hug the outside of self on all eight sides.
        Layouter(self.LTBG):Right(self.Left):Bottom(self.Top):End()
        Layouter(self.RTBG):Left(self.Right):Bottom(self.Top):End()
        Layouter(self.RBBG):Left(self.Right):Top(self.Bottom):End()
        Layouter(self.RLBG):Right(self.Left):Top(self.Bottom):End()
        Layouter(self.LBG):Right(self.Left):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.RBG):Left(self.Right):Top(self.Top):Bottom(self.Bottom):End()
        Layouter(self.TBG):Left(self.Left):Right(self.Right):Bottom(self.Top):End()
        Layouter(self.BBG):Left(self.Left):Right(self.Right):Top(self.Bottom):End()
    end,

    --- Registers a callback that fires when the popup closes for any reason.
    ---@param self UIChatListInterface
    ---@param callback function
    SetOnClosed = function(self, callback)
        self._onClosed = callback
    end,
}

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
