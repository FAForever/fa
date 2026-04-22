
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local ChatLineInterface = import("/lua/ui/game/chat/ChatLineInterface.lua").ChatLineInterface
local ChatEditInterface = import("/lua/ui/game/chat/ChatEditInterface.lua").ChatEditInterface

local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatController = import("/lua/ui/game/chat/ChatController.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

-- Fixed-size line pool for the scaffold. A later pass will size this
-- dynamically from the window height and wire up scrolling.
local LineHeight = 18
local LineCount  = 12

--- Skin textures for the chat window frame. Mirrors the layout that
--- `/lua/ui/game/layouts/chat_layout.lua` applies to the legacy chat Window
--- so the new window matches the original visual style.
local WindowTextures = {
    tl = UIUtil.UIFile('/game/chat_brd/chat_brd_ul.dds'),
    tr = UIUtil.UIFile('/game/chat_brd/chat_brd_ur.dds'),
    tm = UIUtil.UIFile('/game/chat_brd/chat_brd_horz_um.dds'),
    ml = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_l.dds'),
    m  = UIUtil.UIFile('/game/chat_brd/chat_brd_m.dds'),
    mr = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_r.dds'),
    bl = UIUtil.UIFile('/game/chat_brd/chat_brd_ll.dds'),
    bm = UIUtil.UIFile('/game/chat_brd/chat_brd_lm.dds'),
    br = UIUtil.UIFile('/game/chat_brd/chat_brd_lr.dds'),
    borderColor = 'ff415055',
}

-------------------------------------------------------------------------------
-- The main chat window: the draggable frame that hosts the line pool and the
-- edit area. Subscribes to the model for history and visibility changes.

---@class UIChatInterface : Window
---@field LinesContainer Group
---@field Lines          UIChatLineInterface[]
---@field Edit           UIChatEditInterface
local ChatInterface = ClassUI(Window) {

    ---@param self UIChatInterface
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "", false, true, true, false, false, "chat_window_v2", {
            Left = 8, Top = 460, Right = 430, Bottom = 720,
        }, WindowTextures)

        local client = self:GetClientGroup()

        -- Container for the line pool.
        self.LinesContainer = Group(client, "ChatLinesContainer")

        -- Fixed-size pool of line rows.
        self.Lines = {}
        for i = 1, LineCount do
            self.Lines[i] = ChatLineInterface(self.LinesContainer)
        end

        -- The edit area sits at the bottom of the client region.
        self.Edit = ChatEditInterface(client)

        -- Reactive: history → refresh visible rows.
        local model = ChatModel.GetSingleton()
        model.History.OnDirty = function(lv)
            self:RefreshLines(lv())
        end
        self:RefreshLines(model.History())

        -- Reactive: window visibility → show / hide the frame.
        model.WindowVisible.OnDirty = function(lv)
            if lv() then
                self:Show()
                self.Edit:AcquireFocus()
            else
                self:Hide()
            end
        end
        if model.WindowVisible() then
            self:Show()
        else
            self:Hide()
        end
    end,

    ---@param self UIChatInterface
    ---@param parent Control
    __post_init = function(self, parent)
        local client = self:GetClientGroup()
        local pad = 4

        -- Full width, flush with the bottom of the client area. The edit
        -- group derives its own height (see ChatEditInterface.__post_init).
        Layouter(self.Edit)
            :AtLeftIn(client)
            :AtRightIn(client)
            :AtBottomIn(client)
            :Over(client)
            :End()

        Layouter(self.LinesContainer)
            :AtLeftIn(client, pad)
            :AtRightIn(client, pad)
            :AtTopIn(client, pad)
            :AnchorToTop(self.Edit, pad)
            :End()

        -- Stack lines top-down inside the container.
        local prev = nil
        for _, line in ipairs(self.Lines) do
            if prev then
                Layouter(line)
                    :Below(prev)
                    :AtLeftIn(self.LinesContainer)
                    :AtRightIn(self.LinesContainer)
                    :Height(LineHeight)
                    :End()
            else
                Layouter(line)
                    :AtLeftTopIn(self.LinesContainer)
                    :AtRightIn(self.LinesContainer)
                    :Height(LineHeight)
                    :End()
            end
            prev = line
        end
    end,

    --- Fills the line pool with the most-recent history entries.
    ---@param self UIChatInterface
    ---@param history UIChatEntry[]
    RefreshLines = function(self, history)
        local count = table.getn(history)
        local poolSize = table.getn(self.Lines)
        local start = math.max(1, count - poolSize + 1)

        for i = 1, poolSize do
            local line = self.Lines[i]
            local entry = history[start + i - 1]
            if entry then
                line:SetEntry(entry)
                line:Show()
            else
                line:Clear()
                line:Hide()
            end
        end
    end,

    --- Engine-invoked when the user clicks the close button on the window frame.
    OnClose = function(self)
        ChatController.CloseWindow()
    end,
}

-------------------------------------------------------------------------------
--  Module-level singleton and standalone entry points.

---@type UIChatInterface | nil
local Instance = nil

--- Shows the chat window, creating it on first call.
function Open()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
    ChatController.OpenWindow()
end

--- Hides the chat window (the instance is kept around).
function Close()
    ChatController.CloseWindow()
end

--- Toggles the chat window, creating it on first call.
function Toggle()
    if not Instance then
        Instance = ChatInterface(GetFrame(0))
    end
    ChatController.ToggleWindow()
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        newModule.Open()
    end
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    if Instance then
        -- Clear subscriptions to avoid dangling callbacks into a destroyed view.
        local model = ChatModel.GetSingleton()
        model.History.OnDirty = nil
        model.WindowVisible.OnDirty = nil

        Instance:Destroy()
        Instance = nil
    end
    import(__moduleinfo.name)
end

--#endregion
