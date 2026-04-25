
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")

-------------------------------------------------------------------------------
-- Window visibility

--- Shows the chat window.
function OpenWindow()
    ChatModel.GetSingleton().WindowVisible:Set(true)
end

--- Hides the chat window.
function CloseWindow()
    ChatModel.GetSingleton().WindowVisible:Set(false)
end

--- Toggles the chat window open or closed.
function ToggleWindow()
    local lv = ChatModel.GetSingleton().WindowVisible
    lv:Set(not lv())
end

-------------------------------------------------------------------------------
-- Activity heartbeat
--
-- Every UI surface that wants to count as "user is engaged with chat" calls
-- this — keystrokes, scrolling, recipient-picker hovers, etc. The chat
-- window observes `model.LastActivity` to drive its idle / fade timeout, but
-- any future subscriber (a feed-mode line fader, an away-status indicator)
-- can read the same field without rewiring the call sites.

--- Records a user / system activity event by stamping `LastActivity` with the
--- current system time. Cheap and idempotent — call freely from anywhere
--- that detects engagement with the chat UI.
function NotifyActivity()
    ChatModel.GetSingleton().LastActivity:Set(GetSystemTimeSeconds())
end

-------------------------------------------------------------------------------
-- Recipient

--- Sets the current send target.
---@param target UIChatRecipient
function SetRecipient(target)
    ChatModel.GetSingleton().Recipient:Set(target)
end

-------------------------------------------------------------------------------
-- Messages

--- Appends an entry to the history log. Called by the receive path as well as
--- by locally-echoed outgoing messages. Doubles as an activity heartbeat —
--- every new line counts as engagement, so a burst of incoming chat keeps
--- the window from auto-fading mid-conversation.
---@param entry UIChatEntry
function AppendEntry(entry)
    local model = ChatModel.GetSingleton()
    local history = table.copy(model.History())
    table.insert(history, entry)
    model.History:Set(history)
    NotifyActivity()
end

--- Appends a synthetic, local-only system line to the history. Used by the
--- slash-command dispatcher to surface parse/accept errors in the chat feed
--- without sending anything over the network.
---@param text string
function AppendLocalSystemMessage(text)
    AppendEntry {
        Name      = "System:",
        Text      = text,
        Color     = 'ffff6666',
        ArmyID    = 0,
        Recipient = ChatModel.RecipientAll,
    }
end

-------------------------------------------------------------------------------
-- Slash commands

--- (Re-)registers every built-in chat command with the registry. `Register`
--- overwrites, so calling this repeatedly is safe and cheap — we do so on
--- every slash-entry path so hot-reloading `ChatCommandRegistry.lua` (which
--- resets its internal tables) doesn't leave us with an empty registry.
function RegisterBuiltinCommands()
    local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/All.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Allies.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Whisper.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/GiftUnits.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/GiftResources.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Recall.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/ToEngineers.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Taunt.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Mute.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Unmute.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Clear.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Restart.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Save.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Load.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Pause.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Resume.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Speed.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/EndMission.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/DebugLog.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/DebugDumpControls.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/DebugStatistics.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Debugger.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/ToTick.lua")
    Registry.RegisterFromPath("/lua/ui/game/chat/commands/builtin/Help.lua")
end

-------------------------------------------------------------------------------
-- Address book
--
-- These helpers resolve engine-level routing info (session-client indices,
-- army-data lookups) without depending on the legacy `chat.lua`. They are
-- the only place in the refactored chat system that touches
-- `GetSessionClients` / `GetArmiesTable`.

--- Observer-mode branch of `FindClients`: every connected observer client,
--- plus any disconnected-but-recognised human player, is included. The
--- per-client inner loop tries to find a matching army by nickname — if
--- none matches, the client is treated as an observer and included.
---@param armiesTable table
---@return number[]
local function FindClientsAsObserver(armiesTable)
    local result = {}
    for index, client in GetSessionClients() do
        if not client.connected then continue end
        local playerIsObserver = true
        for _, player in armiesTable do
            if player.outOfGame and player.human and player.nickname == client.name then
                table.insert(result, index)
                playerIsObserver = false
                break
            elseif player.nickname == client.name then
                playerIsObserver = false
                break
            end
        end
        if playerIsObserver then
            table.insert(result, index)
        end
    end
    return result
end

--- In-play branch of `FindClients`: gathers the `authorizedCommandSources`
--- of the target army (private-message case) or every focus-army ally
--- (`allies`-broadcast case), then returns the clients whose sources
--- intersect that set.
---@param armiesTable table
---@param focus number
---@param armyID? number
---@return number[]
local function FindClientsAsPlayer(armiesTable, focus, armyID)
    local result = {}
    local srcs = {}
    for army, info in armiesTable do
        if armyID then
            if army == armyID then
                for _, cmdsrc in info.authorizedCommandSources do
                    srcs[cmdsrc] = true
                end
                break
            end
        else
            if IsAlly(focus, army) then
                for _, cmdsrc in info.authorizedCommandSources do
                    srcs[cmdsrc] = true
                end
            end
        end
    end
    for index, client in GetSessionClients() do
        for _, cmdsrc in client.authorizedCommandSources do
            if srcs[cmdsrc] then
                table.insert(result, index)
                break
            end
        end
    end
    return result
end

--- Resolves the session-client indices for a given chat target. Mirrors the
--- legacy `chat.lua` behavior:
---
--- * Observing (focus == -1): every connected observer client, plus any
---   disconnected-but-recognised human player, is included.
--- * Playing with an `armyID`: the clients authorised for that specific army
---   — used for private messages.
--- * Playing with no `armyID`: the clients authorised for any of the focus
---   army's allies — used for `allies` broadcasts.
---
--- Exported so other UI modules (notify, score, painting canvas) can migrate
--- away from `/lua/ui/game/chat.lua`'s copy.
---@param armyID? number
---@return number[]
function FindClients(armyID)
    local t = GetArmiesTable()
    if t.focusArmy == -1 then
        return FindClientsAsObserver(t.armiesTable)
    end
    return FindClientsAsPlayer(t.armiesTable, t.focusArmy, armyID)
end

--- Looks up army data by army index (number) or nickname (string). Returns
--- the entry from `armiesTable` or nil if no match; for nickname lookups the
--- returned table has `ArmyID` set to the matching index.
---@param army number | string
---@return table | nil
local function GetArmyData(army)
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
-- Recipient label formatting
--
-- Keyed by recipient value so both `RecipientAll` ('all') and
-- `RecipientAllies` ('allies') index directly, with 'private'/'notify'/'to'
-- as named fallbacks. Loc keys mirror the legacy `chat.lua` table so the
-- rendered prefix reads identically.

local ToStrings = {
    [ChatModel.RecipientAll]    = { text = '<LOC chat_0004>to all:',    caps = '<LOC chat_0005>To All:',    colorkey = 'all_color'    },
    [ChatModel.RecipientAllies] = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'allies_color' },
    private                     = { text = '<LOC chat_0006>to you:',    caps = '<LOC chat_0007>To You:',    colorkey = 'priv_color'   },
    notify                      = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'notify_color' },
    to                          = { text = '<LOC chat_0000>to',         caps = '<LOC chat_0001>To',         colorkey = 'all_color'    },
}

-------------------------------------------------------------------------------
-- Chat line construction
--
-- Receive and echo share the same "package sender + message into a
-- `UIChatEntry` and push it onto history" work. The only thing they
-- disagree on is how the name prefix reads and whose army data they pull
-- from — so that's where they diverge; everything else goes through
-- `AppendChatLine`.

--- Builds a `UIChatEntry` from a sender's army data + message metadata and
--- appends it to the model history. Fields with natural defaults (colour,
--- army ID, faction icon) fall back when the army data is missing or the
--- sender is an observer.
---@param args { Name: string, Text?: string, ArmyData?: table, IsObserver?: boolean, Recipient: UIChatRecipient, Camera?: table, Location?: UIChatEntryLocation, Id?: string }
local function AppendChatLine(args)
    local armyData = args.ArmyData or {}
    -- Observers have no `faction`; fall through to the tail icon in
    -- `ChatLineInterface.FactionIcons` (observer). Real factions are 0..N-1
    -- in engine data; the view expects 1-based indices.
    local faction = not args.IsObserver and armyData.faction or nil
    AppendEntry {
        Name      = args.Name,
        Text      = args.Text or '',
        Color     = armyData.color or 'ffffffff',
        ArmyID    = armyData.ArmyID or 1,
        Faction   = (faction or 4) + 1,
        Recipient = args.Recipient,
        Camera    = args.Camera,
        Location  = args.Location,
        Id        = args.Id,
    }
end

-------------------------------------------------------------------------------
-- Receiving (network)

--- Handler registered with `gamemain.RegisterChatFunc`. Normalises the
--- message, delegates Notify-subsystem messages, resolves the sender's army
--- data, and appends a chat line.
---
--- Defensive against malformed input: messages that aren't tables, that
--- lack the `Chat` flag, or whose `text` isn't a string are dropped early.
--- The receive path is reachable from any gamemain `RegisterChatFunc`
--- caller — including external mods — so we can't trust the shape.
---@param sender string
---@param msg table
function OnReceive(sender, msg)
    -- Coerce sender to a non-empty string so the formatting concatenations
    -- below can't blow up on a number, table, or nil. The guard is wider
    -- than `or "nil sender"` because that left non-string truthy values
    -- (e.g. a number sender from a misbehaving caller) flowing through.
    if type(sender) ~= 'string' or sender == '' then
        sender = 'nil sender'
    end

    -- Hard shape guards: anything that isn't a populated chat-shaped
    -- table never reaches the formatting / model writes below.
    if type(msg) ~= 'table' then return end
    if not msg.Chat then return end
    if type(msg.text) ~= 'string' then return end

    -- Length cap: matches the edit box's `SetMaxChars(MaxMessageLength)`
    -- on the send side, so a peer that bypassed the input cap (mod, bug,
    -- or hostile client) can't push us into laying out arbitrary-length
    -- lines. UTF-8 length to mirror the input enforcement exactly.
    if STR_Utf8Len(msg.text) > ChatUtils.MaxMessageLength then return end

    -- Notify routing: the Notify subsystem tags messages with `to='notify'`
    -- and owns the display decision. Only fall through to rendering a chat
    -- line if Notify declines (returns false).
    if msg.to == 'notify' and not import("/lua/ui/notify/notify.lua").processIncomingMessage(sender, msg) then
        return
    end

    local armyData = GetArmyData(sender)
    if not armyData and GetFocusArmy() ~= -1 and not SessionIsReplay() then
        return
    end

    local to = msg.to
    local descriptor = ToStrings[to] or ToStrings.private
    local towho = msg.Observer and LOC("<LOC lobui_0692>to observers:") or LOC(descriptor.text)

    local name
    if type(to) == 'number' and SessionIsReplay() then
        -- In a replay, private messages need the full routing so spectators
        -- can attribute the conversation.
        name = string.format("%s %s %s:", sender, LOC(ToStrings.to.text),
            (GetArmyData(to) or {}).nickname or tostring(to))
    else
        name = sender .. ' ' .. towho
    end

    AppendChatLine {
        Name       = name,
        Text       = msg.text,
        ArmyData   = armyData,
        IsObserver = msg.Observer,
        Recipient  = to,
        Camera     = msg.camera,
        Location   = msg.location,
        Id         = msg.Id,
    }
end

--- Handler for the `Sync.ChatMessages` category, populated by the sim-side
--- `SendChatMessage` callback. Each entry in `msgs` is a message table the
--- sim has stamped with a trusted `From` army index.
---
--- In live play the same message also arrives via `SessionSendChatMessage`
--- (handled by `OnReceive`) — whichever path lands first seeds the entry's
--- `Id`, and this handler skips any message whose id is already there.
--- Sim-originated messages have no `SessionSendChatMessage` counterpart, so
--- they flow straight through.
---
--- Replays are the case where `SessionSendChatMessage` never fires: this
--- handler is the *only* source of chat in a replay.
---@param msgs table[]
function OnSyncChatMessages(msgs)
    if type(msgs) ~= 'table' then return end

    local history = ChatModel.GetSingleton().History()
    local seen = {}
    for _, entry in history do
        if entry.Id then seen[entry.Id] = true end
    end

    for _, msg in msgs do
        if not (msg.Id and seen[msg.Id]) then
            local armyData = GetArmyData(msg.From)
            local nickname = armyData and armyData.nickname or tostring(msg.From or 'Unknown')
            OnReceive(nickname, msg)
            if msg.Id then seen[msg.Id] = true end
        end
    end
end

-------------------------------------------------------------------------------
-- Echoing (local synthesis for outgoing privates)
--
-- The engine only routes a private message to its target, so the sender
-- would otherwise never see their own whispers. `OnEcho` synthesises a
-- "To <recipient>:" line from the send-side data directly — no round-trip
-- through a fake `msg.echo` field, no pretending the message was received
-- from the network.

--- Appends a locally-echoed line for a private message the local player
--- just sent. Called only from `Send`; not registered with gamemain.
---@param senderData table        # local player's army data
---@param recipientData table     # target of the private message
---@param msg table               # outgoing message (uses `text`, `to`, `camera`)
local function OnEcho(senderData, recipientData, msg)
    local name = string.format("%s %s:", LOC(ToStrings.to.caps), recipientData.nickname)
    AppendChatLine {
        Name      = name,
        Text      = msg.text,
        ArmyData  = senderData,
        Recipient = msg.to,
        Camera    = msg.camera,
        Location  = msg.location,
        Id        = msg.Id,
    }
end

-------------------------------------------------------------------------------
-- Sending

--- Sends a chat message to the current recipient. Dispatches slash commands,
--- drops all-whitespace bodies, short-circuits taunts, then routes the
--- payload to the engine based on the recipient and whether the local player
--- is observing. When `attachCamera` is true, snapshots the current world
--- camera and ships it on the message so recipients can jump to the view
--- by clicking the line.
---@param text string
---@param attachCamera? boolean
function Send(text, attachCamera)
    if not text or text == '' then return end

    if string.sub(text, 1, 1) == '/' then
        RegisterBuiltinCommands()
        local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")
        local handled, err = Registry.Dispatch(text)
        if handled then return end
        if err then
            AppendLocalSystemMessage(err)
            return
        end
        -- Lone '/' or a slash-prefixed body with no matching command falls
        -- through to the normal send path.
    end

    -- Drop all-whitespace bodies. `string.find` with `%s+` returns the first
    -- run of whitespace; if it spans the entire text there's nothing to send.
    local wsStart, wsEnd = string.find(text, "%s+")
    if wsStart == 1 and wsEnd == string.len(text) then return end

    if import("/lua/ui/game/taunt.lua").CheckForAndHandleTaunt(text) then
        return
    end

    local recipient = ChatModel.GetSingleton().Recipient()
    local focusArmy = GetFocusArmy()
    local msg = {
        to         = recipient,
        Chat       = true,
        Identifier = 'Chat',
        text       = text,
    }

    -- Observers can't target a private recipient; silently drop (old
    -- chat.lua did the same — the command simply had no effect). Bail
    -- before stamping an id or firing sim callbacks so we don't leak
    -- a message the engine would have refused to deliver anyway.
    if focusArmy == -1 and type(recipient) == 'number' then return end

    -- Flag observer broadcasts so receivers render "to observers:". Both
    -- delivery paths (engine-routed and sim-routed) need to see this bit,
    -- so set it before either fires.
    if focusArmy == -1 then msg.Observer = true end

    if attachCamera then
        msg.camera = GetCamera('WorldCamera'):SaveSettings()
    end

    -- Stamp a near-unique id on the message *before* it leaves this function.
    -- The same `msg` table travels through two parallel delivery paths — the
    -- live `SessionSendChatMessage` broadcast and the sim-routed
    -- `SendChatMessage`→`Sync.ChatMessages` path — and the receiver-side
    -- dedupe uses this id to tell the two apart. `tostring(msg)` yields the
    -- table's address, which collides only if the same address is reused for
    -- another chat message within the dedupe window — vanishingly rare.
    msg.Id = tostring(msg)

    -- Replay-parser backwards compat: external replay tools scrape chat out
    -- of recorded `GiveResourcesToPlayer` callback args. We fire one zero-
    -- resource callback per outgoing message so they keep working, regardless
    -- of who the real recipient is. `From`/`To` are both the focus army so
    -- the sim-side ally/self-transfer guard short-circuits without doing
    -- anything. Observers skip it — no army to ship.
    if focusArmy ~= -1 then
        local senderData = GetArmyData(focusArmy)
        SimCallback({
            Func = 'GiveResourcesToPlayer',
            Args = {
                From = focusArmy, To = focusArmy, Mass = 0, Energy = 0,
                Sender = senderData and senderData.nickname or tostring(focusArmy),
                Msg = msg,
            },
        }, false)
    end

    -- Sim-routed path: hand the message to the sim, which validates and
    -- re-broadcasts it via `Sync.ChatMessages` to every connected UI. In live
    -- play this runs alongside `SessionSendChatMessage` and our id-based
    -- dedupe keeps it from double-posting; in replays it is the *only* path
    -- the viewer sees, which is exactly what we want.
    SimCallback({ Func = 'SendChatMessage', Args = { Msg = msg } }, false)

    if recipient == ChatModel.RecipientAllies then
        SessionSendChatMessage(FindClients(), msg)
    elseif type(recipient) == 'number' then
        SessionSendChatMessage(FindClients(recipient), msg)

        -- The engine does not bounce private messages back to the sender;
        -- locally synthesise a line so the sender sees what they just wrote.
        local senderData = GetArmyData(focusArmy)
        local targetData = GetArmyData(recipient)
        if senderData and targetData then
            OnEcho(senderData, targetData, msg)
        end
    else
        if focusArmy == -1 then
            SessionSendChatMessage(FindClients(), msg)
        else
            SessionSendChatMessage(msg)
        end
    end
end

-------------------------------------------------------------------------------
-- Engine hotkey entry point

--- Opens the chat window with the recipient forced to `allies` or `all`
--- based on the `send_type` preference and the Shift modifier. The engine
--- calls this via a top-level `ActivateChat` shim in `gamemain.lua` when
--- the user presses Enter outside the edit box.
---
--- Truth table (`send_type` reads as "default to allies"):
--- * `send_type=false`, no Shift → `all`
--- * `send_type=false`, Shift    → `allies`
--- * `send_type=true`,  no Shift → `allies`
--- * `send_type=true`,  Shift    → `all`
---
--- If the current recipient is already a specific army ID (mid-private
--- message), it is left alone — Shift only switches between the two
--- broadcast channels.
---@param modifiers? table  # engine-supplied modifier state ({Shift, Ctrl, ...})
function ActivateChat(modifiers)
    local model = ChatModel.GetSingleton()
    local wasVisible = model.WindowVisible()

    -- Toggle first. On open this runs `ApplyDefaultRecipient`, which picks
    -- a recipient from `send_type` alone — it doesn't see modifiers. On
    -- close it just flips visibility and we leave the recipient alone.
    import("/lua/ui/game/chat/ChatInterface.lua").Toggle()

    -- Layer the Shift modifier on top of the default. Must happen AFTER
    -- the toggle above — writing to `Recipient` before `ToggleWindow` runs
    -- gets clobbered by its own `ApplyDefaultRecipient` call.
    if not wasVisible and type(model.Recipient()) ~= 'number' then
        local sendType = ChatConfigModel.GetOptions().send_type or false
        local shift = modifiers and modifiers.Shift or false
        if (not shift) == sendType then
            model.Recipient:Set(ChatModel.RecipientAllies)
        else
            model.Recipient:Set(ChatModel.RecipientAll)
        end
    end
end

-------------------------------------------------------------------------------
-- Lifecycle

--- One-shot initialisation: registers the receive handler with gamemain and
--- populates the slash-command registry with the built-ins. Called from
--- `gamemain.lua` during UI setup — kept out of module-load so mods can hook
--- the controller (replacing `Init`, `OnReceive`, or `RegisterBuiltinCommands`)
--- before any wiring happens.
---
--- `RegisterChatFunc` keys by identifier and overwrites, so calling `Init`
--- more than once simply replaces the previous handler — no duplicate
--- dispatches, safe under hot reload.
function Init()
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(OnReceive, 'Chat')
    AddOnSyncHashedCallback(OnSyncChatMessages, 'ChatMessages', 'Chat')
    RegisterBuiltinCommands()
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-runs `Init()` on the freshly imported module so
--- `gamemain.chatFuncs['Chat']` rebinds to the NEW `OnReceive` closure and
--- `RegisterBuiltinCommands` repopulates the registry. Without this, edits
--- to this file leave the old function registered and the new command set
--- empty — sending continues to "work" but receives keep flowing through
--- stale code, and slash commands stop dispatching.
---
--- The short delay + re-import gives any cascading reloads (command files,
--- ChatModel, etc.) time to settle before we wire things up — calling
--- `newModule.Init()` synchronously can capture stale references partway
--- through the reload pipeline.
function __moduleinfo.OnReload(newModule)
    ForkThread(function()
        WaitFrames(1)
        newModule.Init()
    end)
end

function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
