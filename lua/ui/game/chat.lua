-------------------------------------------------------------------------------
-- DEPRECATED LEGACY CHAT API SHIM
--
-- The original `/lua/ui/game/chat.lua` was replaced by the MVC tree under
-- `/lua/ui/game/chat/` (see [GAPS.md](chat/GAPS.md) and [CHANGES.md](chat/CHANGES.md)).
-- The original implementation is preserved on disk as `chat.legacy.lua`
-- for reference; this file is a compatibility layer for external mods that
-- still import the old `/lua/ui/game/chat.lua` path.
--
-- Every export here logs a one-shot deprecation warning the first time it
-- is touched and forwards to the equivalent new API. Once mods have
-- migrated, this file can be deleted outright (along with `chat.legacy.lua`).
-------------------------------------------------------------------------------

local ChatController = import("/lua/ui/game/chat/ChatController.lua")
local ChatInterface = import("/lua/ui/game/chat/ChatInterface.lua")
local ChatConfigInterface = import("/lua/ui/game/chat/config/ChatConfigInterface.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

-- One-shot per name, dedupe a chatty caller into a single warning so the
-- log doesn't drown when a mod is busy hammering a deprecated entry point.
local _warned = {}
local function _deprecate(name, replacement)
    if _warned[name] then return end
    _warned[name] = true
    WARN(string.format(
        "chat.lua %s is deprecated — use %s instead",
        name, replacement or 'the new chat MVC API'
    ))
end

-------------------------------------------------------------------------------
-- Active entry points (still wired in keymaps / engine hooks)

--- Called by the engine when the user presses Enter outside the chat edit
--- box — the default "open chat" shortcut. Thin shim that delegates to the
--- chat controller, which picks the initial recipient from `send_type` and
--- the Shift modifier before toggling the window.
---@param modifiers? table  # {Shift, Ctrl, Alt, ...}
function ActivateChat(modifiers)
    ChatController.ActivateChat(modifiers)
end

-------------------------------------------------------------------------------
-- Deprecated forwards

--- @deprecated use [ChatController.OnReceive](chat/ChatController.lua) instead
function ReceiveChat(sender, msg)
    _deprecate('ReceiveChat', 'ChatController.OnReceive')
    ChatController.OnReceive(sender, msg)
end

--- @deprecated use [ChatController.OnReceive](chat/ChatController.lua) instead
function ReceiveChatFromSim(sender, msg)
    _deprecate('ReceiveChatFromSim', 'ChatController.OnReceive')
    ChatController.OnReceive(sender, msg)
end

--- @deprecated use [ChatController.Init](chat/ChatController.lua) instead. The new `Init` takes no arguments — chat layout no longer needs a `mapGroup` reference because the tree mounts on `GetFrame(0)` directly.
function SetupChatLayout(_)
    _deprecate('SetupChatLayout', 'ChatController.Init')
    ChatController.Init()
end

--- @deprecated no replacement; the new chat is hidden by default and follows `model.WindowVisible`, so the legacy "hide on NIS start" hook is no longer required
function OnNISBegin()
    _deprecate('OnNISBegin', 'no replacement (no longer required)')
end

--- @deprecated use [ChatInterface.OpenAndScrollLines](chat/ChatInterface.lua) with a negative delta
function ChatPageUp(mod)
    _deprecate('ChatPageUp', 'ChatInterface.OpenAndScrollLines(-mod)')
    ChatInterface.OpenAndScrollLines(-(mod or 10))
end

--- @deprecated use [ChatInterface.OpenAndScrollLines](chat/ChatInterface.lua) with a positive delta
function ChatPageDown(mod)
    _deprecate('ChatPageDown', 'ChatInterface.OpenAndScrollLines(mod)')
    ChatInterface.OpenAndScrollLines(mod or 10)
end

--- @deprecated use [ChatConfigInterface.Close](chat/config/ChatConfigInterface.lua) instead
function CloseChatConfig()
    _deprecate('CloseChatConfig', 'ChatConfigInterface.Close')
    ChatConfigInterface.Close()
end

--- @deprecated use [ChatController.CloseWindow](chat/ChatController.lua) instead
function CloseChat()
    _deprecate('CloseChat', 'ChatController.CloseWindow')
    ChatController.CloseWindow()
end

---@deprecated use [ChatController.FindClients](chat/ChatController.lua) instead
function FindClients(id)
    _deprecate('FindClients', 'ChatController.FindClients')
    return ChatController.FindClients(id)
end

--- @deprecated subscribe to [ChatConfigModel.GetSingleton().Committed](chat/config/ChatConfigModel.lua) via `LazyVarDerive` instead. Best-effort shim — fires the callback once with the current options so legacy callers see a value, then wires a one-way derived observer so subsequent changes propagate. Mods should migrate to a real `LazyVarDerive` they can destroy on teardown.
function AddChatOptionSetCallback(callback, _)
    _deprecate('AddChatOptionSetCallback', 'LazyVarDerive(ChatConfigModel.GetSingleton().Committed, ...)')
    if type(callback) ~= 'function' then return end

    -- Best-effort: keep a derived observer alive until the module is
    -- reloaded. We don't hand it back to the caller (the legacy API
    -- didn't expose a destroy path), so it leaks on intent — same
    -- behaviour as the legacy callback list.
    _warned[callback] = LazyVarDerive(
        ChatConfigModel.GetSingleton().Committed,
        function(lv) callback(lv()) end
    )
end

--- @deprecated no caller-driven equivalent. The legacy `SetLayout` was the
--- *layout* hook (HUD-arrangement preset: `bottom` / `left` / `right`),
--- not the *skin* hook — it called `import(UIUtil.GetLayoutFilename('chat')).SetLayout()`
--- to apply layout-specific positions. The new chat uses a single rect
--- regardless of layout (see [CHANGES.md](chat/CHANGES.md)), so there is
--- nothing to re-apply. Skin-driven theming is independent and is
--- handled reactively via `UIUtil.SkinnableFile` (border, drag handles,
--- scrollbar, buttons all follow the active skin without an explicit call).
function SetLayout(_)
    _deprecate('SetLayout', 'no replacement (chat is single-layout; skin theming auto-updates via SkinnableFile)')
end

--- @deprecated multiple `GetArmyData`-style helpers exist elsewhere; the new chat tree uses a private one in `ChatController`
function GetArmyData(army)
    _deprecate('GetArmyData', 'GetArmiesTable().armiesTable[ArmyID]')
    local armies = GetArmiesTable()
    if type(army) == 'number' then
        return armies.armiesTable[army]
    elseif type(army) == 'string' then
        for i, v in armies.armiesTable do
            if v.nickname == army then
                v.ArmyID = i
                return v
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Deprecated legacy API proxies
--
-- The legacy file exposed `GUI`, `ChatLines`, and `CreateChatEdit` as
-- legacy chat API entry points. There's no clean way to recreate those
-- against the MVC tree — the new view doesn't pin its controls to a
-- globally-addressable structure. Mods that read or call these entries
-- directly were always coupled to internals that could move.
--
-- We expose empty tables proxied through metatables so any access logs
-- a deprecation warning and returns the proxy table. This preserves
-- legacy reads and chained accesses without pretending the field exists.
-- Function-style calls also log a deprecation warning and return the
-- proxy, allowing old APIs to fail gracefully while steering mods toward
-- the new chat MVC view tree.

local function _deprecationProxy(name)
    return setmetatable({}, {
        __index = function(self, k)
            _deprecate(name .. '.' .. tostring(k), 'the new chat MVC view tree')
            return self
        end,
        __newindex = function(_, k, _)
            _deprecate(name .. '.' .. tostring(k) .. ' (assignment)', 'the new chat MVC view tree')
        end,
        __call = function(self)
            _deprecate(name .. ' (function call)', 'the new chat MVC view tree')
            return self
        end,
    })
end

GUI = _deprecationProxy('GUI')
ChatLines = _deprecationProxy('ChatLines')
CreateChatEdit = _deprecationProxy('CreateChatEdit')
