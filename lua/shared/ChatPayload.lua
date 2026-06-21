
-- Side-agnostic chat-payload validation, shared by the sim relay
-- (`/lua/ChatUtils.lua`) and the UI receive path
-- (`/lua/ui/game/chat/ChatController.lua`) so shape rules and the length
-- cap can't drift. Session-context checks (sender identity, focus army,
-- ally relationships, replay state) belong at the call sites.

---@alias ChatPayloadRecipient
---|  'all'      # broadcast to every connected client
---|  'allies'   # broadcast to allied players (or all observers when observing)
---|  'notify'   # UI subsystem channel — internal traffic, not player chat
---|  number     # army ID for a private whisper

--- Wire-format chat payload — what travels through `SessionSendChatMessage`
--- and the sim-routed `Sync.ChatMessages`. `From` is filled by the sim relay
--- (originating clients leave it blank), so every consumer past
--- `RelayChatMessage` sees it set.
---@class ChatPayload
---@field Chat        true                 # must be exactly `true` — gate flag for the chat handlers
---@field text        string               # UTF-8 message body, length capped at `MaxMessageLength`
---@field to          ChatPayloadRecipient # recipient channel
---@field Identifier? string               # usually `'Chat'`; legacy / synthetic paths may set other values
---@field Observer?   boolean              # sender was in observer mode (`GetFocusArmy() == -1`)
---@field camera?     table                # `WorldCamera:SaveSettings()` snapshot for click-to-jump links
---@field location?   table                # lightweight location hint — see `UIChatEntryLocation` for the inner shape
---@field Args?       any[]                # `LOCF`-style format args spread alongside `text` on render
---@field Id?         string               # sender-stamped near-unique id; dedupes the two delivery paths
---@field From        number               # sim-stamped trusted sender army index — written by the relay before broadcast

--- Maximum UTF-8 character length for a chat message body. The UI edit box
--- enforces this on input; the sim relay and the receive path gate on the
--- same bound so a peer that bypassed the input cap can't push the session
--- into laying out arbitrarily long lines.
MaxMessageLength = 200

--- Type guard for `ChatPayload`. Callers can narrow with
--- `--[[@as ChatPayload]]` after a `true` return. Permits `'notify'`
--- recipients; sim callers that don't relay notify traffic must reject it
--- separately.
---@param msg any
---@return boolean
function IsValidPayload(msg)
    if type(msg) ~= 'table' then return false end
    if msg.Chat ~= true then return false end
    if type(msg.text) ~= 'string' or msg.text == '' then return false end
    if STR_Utf8Len(msg.text) > MaxMessageLength then return false end

    -- Without this guard, a bare string like 'admin' would fall through to
    -- the UI's recipient-formatting fallback and let a peer fake a "to you:"
    -- header on what is actually a broadcast.
    if msg.to ~= 'all'
        and msg.to ~= 'allies'
        and msg.to ~= 'notify'
        and type(msg.to) ~= 'number' then
        return false
    end

    -- Optional payloads must be tables — `WorldCamera:RestoreSettings` and
    -- the camera-link click handler crash on non-table inputs.
    if msg.camera   ~= nil and type(msg.camera)   ~= 'table' then return false end
    if msg.location ~= nil and type(msg.location) ~= 'table' then return false end
    if msg.Args     ~= nil and type(msg.Args)     ~= 'table' then return false end

    return true
end
