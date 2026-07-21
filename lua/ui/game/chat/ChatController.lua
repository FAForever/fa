
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")
local ChatUtils = import("/lua/ui/game/chat/ChatUtils.lua")
local ChatPayload = import("/lua/shared/ChatPayload.lua")

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

--- Flips chat window visibility.
function ToggleWindow()
    local lv = ChatModel.GetSingleton().WindowVisible
    lv:Set(not lv())
end

-------------------------------------------------------------------------------
-- Activity heartbeat

--- Stamps `LastActivity` with the current system time. Call from any
--- UI surface that counts as engagement.
function NotifyActivity()
    ChatModel.GetSingleton().LastActivity:Set(GetSystemTimeSeconds())
end

--- Sets the pinned flag.
---@param pinned boolean
function SetPinned(pinned)
    ChatModel.GetSingleton().Pinned:Set(pinned and true or false)
    if not pinned then
        NotifyActivity()
    end
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

--- Appends an entry to the history log and stamps `LastActivity`. Used by
--- the receive path and by locally-echoed outgoing messages.
---@param entry UIChatEntry
function AppendEntry(entry)
    local model = ChatModel.GetSingleton()
    local history = table.copy(model.History())
    table.insert(history, entry)
    model.History:Set(history)
    NotifyActivity()
end

--- Appends a local-only system line. Used by the slash-command dispatcher
--- to surface parse/accept errors without sending over the network.
---@param text string
function AppendLocalSystemMessage(text)
    AppendEntry {
        Name      = "System:",
        Text      = text,
        Color     = 'ffff6666',
        BodyColor = 'ffff6666',
        ArmyID    = 0,
        Recipient = ChatModel.RecipientAll,
    }
end

-------------------------------------------------------------------------------
-- Slash commands

--- (Re-)registers every built-in chat command with the registry. Idempotent.
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

--- * Calling with an `armyID`: clients authorised for that specific army
---   (private messages).
--- * Calling with no `armyID`: clients authorised for any focus-army ally
---   (`allies` broadcasts).
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

--- Resolves the session-client indices for a given chat target.
---
--- * Observing (focus == -1): every connected observer client, plus any
---   disconnected-but-recognised human player.
--- * Calling with an `armyID`: clients authorised for that specific army
---   (private messages).
--- * Calling with no `armyID`: clients authorised for any focus-army ally
---   (`allies` broadcasts).
---@param armyID? number
---@return number[]
function FindClients(armyID)
    local t = GetArmiesTable()
    if t.focusArmy == -1 then
        return FindClientsAsObserver(t.armiesTable)
    end
    return FindClientsAsPlayer(t.armiesTable, t.focusArmy, armyID)
end

--- Looks up army data by army index (number) or nickname (string). For
--- nickname lookups the returned table has `ArmyID` set to the matching index.
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

local ToStrings = ChatUtils.ToStrings

-------------------------------------------------------------------------------
-- Chat line construction

--- Builds a `UIChatEntry` from a sender's army data + message metadata and
--- appends it to the model history. Fields with natural defaults (colour,
--- army ID, faction icon) fall back when the army data is missing or the
--- sender is an observer.
---@param args { Name: string, Text?: string, ArmyData?: table, IsObserver?: boolean, Recipient: UIChatRecipient, Camera?: table, Location?: UIChatEntryLocation, Id?: string }
local function AppendChatLine(args)
    local armyData = args.ArmyData or {}
    -- Observers have no `faction`, fall through to the tail icon in
    -- `ChatLineInterface.FactionIcons`. Engine factions are 0..N-1.
    -- The view expects 1-based indices.
    local faction = not args.IsObserver and armyData.faction or nil

    -- Camera-link messages and observer broadcasts both use the link
    -- palette. Everyone else inherits the channel descriptor's `colorkey`.
    -- Unrecognised recipients fall back to `priv_color` via the
    -- `ToStrings.private` entry.
    local colorKey
    if args.Camera or args.Location then
        colorKey = ChatConfigModel.KeyLinkColor
    elseif args.IsObserver then
        colorKey = ChatConfigModel.KeyLinkColor
    else
        local descriptor = ToStrings[args.Recipient] or ToStrings.private
        colorKey = descriptor.colorkey
    end

    AppendEntry {
        Name      = args.Name,
        Text      = args.Text or '',
        Color     = armyData.color or 'ffffffff',
        ColorKey  = colorKey,
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

--- Returns true when `msg.Id` matches an entry already in history. The same
--- chat message arrives via both delivery paths in live play (engine
--- `SessionSendChatMessage` and sim `Sync.ChatMessages`), so whichever lands
--- first seeds the entry and the second is dropped here.
---@param msg ChatPayload
---@return boolean
local function IsDuplicateMessage(msg)
    if not msg.Id then return false end
    local history = ChatModel.GetSingleton().History()
    for _, entry in history do
        if entry.Id == msg.Id then return true end
    end
    return false
end

--- Handler registered with `gamemain.RegisterChatFunc`. Validates the
--- message, dedupes against history, delegates Notify-subsystem messages,
--- resolves the sender's army data, and appends a chat line.
---@param sender string
---@param msg ChatPayload
function OnReceive(sender, msg)
    if type(sender) ~= 'string' or sender == '' then
        sender = 'nil sender'
    end

    if not ChatPayload.IsValidPayload(msg) then return end
    if IsDuplicateMessage(msg) then return end

    -- only apply LOCf when Args are present, otherwise players can randomly send localized messages by including format specifiers in their text.
    if msg.Args then
        msg.text = LOCF(msg.text, unpack(msg.Args))
    end

    -- Notify owns the display decision for `to='notify'`. Only fall
    -- through to rendering a chat line if it returns false.
    if msg.to == ChatModel.RecipientNotify and not import("/lua/ui/notify/notify.lua").processIncomingMessage(sender, msg) then
        return
    end

    local armyData = GetArmyData(sender)
    if not armyData and GetFocusArmy() ~= -1 and not SessionIsReplay() then
        return
    end

    -- `msg.Observer` is only set when the sender has no army entry. A
    -- peer claiming Observer while resolving to a real army is malformed.
    -- Drop the message entirely rather than stripping the flag, which
    -- would let manipulated traffic render under a different label.
    if msg.Observer and armyData then return end

    local to = msg.to
    local descriptor = ToStrings[to] or ToStrings.private
    local towho = msg.Observer and LOC("<LOC lobui_0692>to observers:") or LOC(descriptor.text)

    local name
    if type(to) == 'number' and SessionIsReplay() then
        -- In a replay, private messages need the full routing so
        -- spectators can attribute the conversation.
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
--- `SendChatMessage` callback.
---@param msgs ChatPayload[]
function OnSyncChatMessages(msgs)
    -- In live play the same message also arrives via
    -- `SessionSendChatMessage` (`OnReceive`). `OnReceive` dedupes by
    -- `Id` so this handler can fan out unconditionally. In a replay
    -- this is the *only* source of chat. `SessionSendChatMessage` never
    -- fires.
    if type(msgs) ~= 'table' then return end
    for _, msg in msgs do
        local armyData = GetArmyData(msg.From)
        local nickname = armyData and armyData.nickname or tostring(msg.From or 'Unknown')
        OnReceive(nickname, msg)
    end
end

-------------------------------------------------------------------------------
-- Echoing (local synthesis for outgoing privates)
--
-- The engine doesn't bounce private messages back to the sender, so we
-- synthesise a "To <recipient>:" line locally instead.

---@param senderData table        # local player's army data
---@param recipientData table     # target of the private message
---@param msg ChatPayload         # outgoing message (uses `text`, `to`, `camera`)
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
--- payload to the engine. When `attachCamera` is true, snapshots the current
--- world camera so recipients can click the line to jump to the view.
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
        -- Lone '/' or unknown command falls through to the normal send path.
    end

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

    -- Observers can't target a private recipient. Bail before stamping
    -- an id or firing sim callbacks for a message the engine would
    -- refuse anyway.
    if focusArmy == -1 and type(recipient) == 'number' then return end

    -- Flag observer broadcasts so receivers render "to observers:".
    -- Both delivery paths need to see this, so set it before either
    -- fires.
    if focusArmy == -1 then msg.Observer = true end

    if attachCamera then
        msg.camera = GetCamera('WorldCamera'):SaveSettings()
    end

    -- Stamp an id for `OnSyncChatMessages` to dedupe the live and
    -- sim-routed delivery paths. Tick suffix guards against
    -- table-address recycling.
    msg.Id = string.format("%d %s", GameTick(), tostring(msg))

    -- Replay-parser backwards compat: external replay tools scrape chat
    -- out of recorded `GiveResourcesToPlayer` callback args. Fire one
    -- zero-resource callback per outgoing message so they keep working.
    -- Observers skip it (no army to ship).
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

    -- Sim-routed path: the sim re-broadcasts via `Sync.ChatMessages`.
    -- In live play it runs alongside `SessionSendChatMessage` and
    -- id-based dedupe prevents double-posting. In replays it is the
    -- *only* path.
    SimCallback({ Func = 'SendChatMessage', Args = { Msg = msg } }, false)

    if recipient == ChatModel.RecipientAllies then
        SessionSendChatMessage(FindClients(), msg)
    elseif type(recipient) == 'number' then
        SessionSendChatMessage(FindClients(recipient), msg)

        -- Engine doesn't bounce private messages back to the sender.
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
--- based on `send_type` and the Shift modifier. A specific-army recipient
--- (mid-private) is left alone.---@param modifiers? table  # engine-supplied modifier state ({Shift, Ctrl, ...})
function ActivateChat(modifiers)
    -- The engine calls this via a top-level `ActivateChat` shim in
    -- `gamemain.lua` when the user presses Enter outside the edit box.
    local model = ChatModel.GetSingleton()
    local wasVisible = model.WindowVisible()

    import("/lua/ui/game/chat/ChatInterface.lua").Toggle()

    -- Layer Shift on top of the default. Must run AFTER the toggle.
    -- Writing `Recipient` first gets clobbered by `ApplyDefaultRecipient`.
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

--- Registers the receive handler with gamemain, populates the slash-command
--- registry, and mounts the chat tree. Idempotent.
function Init()
    -- Called from `gamemain.lua` during UI setup. Kept out of module-load
    -- so mods can override the controller before any wiring happens.
    -- `RegisterChatFunc` overwrites, so re-running `Init` just rebinds
    -- the handlers.
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(OnReceive, 'Chat')
    AddOnSyncHashedCallback(OnSyncChatMessages, 'ChatMessages', 'Chat')
    RegisterBuiltinCommands()

    -- Build the chat tree eagerly so the sibling feed is mounted in
    -- time to surface messages that arrive before the user opens the
    -- dialog.
    import("/lua/ui/game/chat/ChatInterface.lua").EnsureInstance()
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-runs `Init()` on the new module.
function __moduleinfo.OnReload(newModule)
    -- The gamemain registration rebinds to the fresh `OnReceive` closure
    -- and the registry repopulates. Without this, edits leave stale code
    -- receiving messages. The fork-with-delay lets cascading reloads
    -- settle first.
    ForkThread(function()
        WaitFrames(1)
        newModule.Init()
    end)
end

--- Hot-reload hook: re-imports this module after a couple of frames so
--- cascading reloads can settle first.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
