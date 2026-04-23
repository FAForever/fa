
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

-------------------------------------------------------------------------------
-- Window visibility

--- Applies the `send_type` default-recipient option when the chat window
--- opens. If the user has already selected a specific player for a private
--- message, their choice is left alone.
local function ApplyDefaultRecipient()
    local model = ChatModel.GetSingleton()
    if type(model.Recipient()) == 'number' then
        return
    end
    local options = ChatConfigModel.GetSingleton().Committed()
    local target = options.send_type and ChatModel.RecipientAllies or ChatModel.RecipientAll
    model.Recipient:Set(target)
end

--- Shows the chat window.
function OpenWindow()
    ApplyDefaultRecipient()
    ChatModel.GetSingleton().WindowVisible:Set(true)
end

--- Hides the chat window.
function CloseWindow()
    ChatModel.GetSingleton().WindowVisible:Set(false)
end

--- Toggles the chat window open or closed.
function ToggleWindow()
    local lv = ChatModel.GetSingleton().WindowVisible
    local willOpen = not lv()
    if willOpen then
        ApplyDefaultRecipient()
    end
    lv:Set(willOpen)
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
--- by locally-echoed outgoing messages.
---@param entry UIChatEntry
function AppendEntry(entry)
    local model = ChatModel.GetSingleton()
    local history = table.copy(model.History())
    table.insert(history, entry)
    model.History:Set(history)
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
    local Builtins = import("/lua/ui/game/chat/commands/BuiltinCommands.lua")

    Registry.Register(Builtins.All)
    Registry.Register(Builtins.Allies)
    Registry.Register(Builtins.Whisper)
    Registry.Register(Builtins.Help)
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
---@param args { Name: string, Text?: string, ArmyData?: table, IsObserver?: boolean, Recipient: UIChatRecipient, Camera?: table }
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
    }
end

-------------------------------------------------------------------------------
-- Receiving (network)

--- Handler registered with `gamemain.RegisterChatFunc`. Normalises the
--- message, delegates Notify-subsystem messages, resolves the sender's army
--- data, and appends a chat line.
---@param sender string
---@param msg table
function OnReceive(sender, msg)
    sender = sender or "nil sender"

    if not msg.Chat then return end

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
    }
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
    }
end

-------------------------------------------------------------------------------
-- Sending

--- Sends a chat message to the current recipient. Dispatches slash commands,
--- drops all-whitespace bodies, short-circuits taunts, then routes the
--- payload to the engine based on the recipient and whether the local player
--- is observing.
---@param text string
function Send(text)
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

    if recipient == ChatModel.RecipientAllies then
        if focusArmy == -1 then msg.Observer = true end
        SessionSendChatMessage(FindClients(), msg)
    elseif type(recipient) == 'number' then
        -- Observers can't target a private recipient; silently drop (old
        -- chat.lua did the same — the command simply had no effect).
        if focusArmy == -1 then return end
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
            msg.Observer = true
            SessionSendChatMessage(FindClients(), msg)
        else
            SessionSendChatMessage(msg)
        end
    end
end

-------------------------------------------------------------------------------
-- Engine registration
--
-- Registered at module load. `RegisterChatFunc` keys by identifier and
-- overwrites, so re-imports (hot reload) simply replace the previous handler
-- with the freshly-loaded one — no duplicate dispatches.

import("/lua/ui/game/gamemain.lua").RegisterChatFunc(OnReceive, 'Chat')

-- Slash-command registry also needs to be populated before the first hint
-- opens or the first `/cmd` is typed. `RegisterBuiltinCommands` is
-- idempotent, so re-imports and the belt-and-suspenders calls from `Send` /
-- `OpenCommandHint` all converge on the same state.
RegisterBuiltinCommands()

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
