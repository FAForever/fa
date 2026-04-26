
-- Pure, side-agnostic shape validation for chat payloads. Loaded by both the
-- sim relay (`/lua/ChatUtils.lua`) and the UI receive path
-- (`/lua/ui/game/chat/ChatController.lua`) so the shape rules and the length
-- cap can't drift between sender and receiver.
--
-- Anything that needs session context (sender identity, focus army, ally
-- relationships, replay state) belongs on the call site, not here.

---@alias ChatPayloadRecipient
---|  'all'      # broadcast to every connected client
---|  'allies'   # broadcast to allied players (or all observers when observing)
---|  'notify'   # UI subsystem channel — internal traffic, not player chat
---|  number     # army ID for a private whisper

--- Wire-format chat payload — what travels through both
--- `SessionSendChatMessage` and the sim-routed `Sync.ChatMessages`. Defined
--- here so the sim relay (`/lua/ChatUtils.lua`) and the UI receive path
--- (`/lua/ui/game/chat/ChatController.lua`) validate against the same
--- contract. `From` is intentionally optional: originating clients leave it
--- blank and the sim relay overwrites it with the trusted command-source
--- army before broadcasting.
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
---@field From        number               # sim-stamped trusted sender army index — written by the relay before broadcast, so every consumer past `RelayChatMessage` sees it set

--- Maximum UTF-8 character length for a chat message body. The UI edit box
--- enforces this on input via `Edit:SetMaxChars`; both the sim relay and
--- the UI receive path gate on the same bound so a peer that bypassed the
--- input cap can't push every client into laying out arbitrarily long
--- lines.
MaxMessageLength = 200

--- Type guard for the `ChatPayload` shape. Returns `true` only when every
--- required field is present with the expected type and every optional
--- field, when present, has the engine-API shape it must have for
--- downstream rendering / camera-jump code to treat it safely. After a
--- `true` return, callers can narrow with `--[[@as ChatPayload]]`.
---
--- Each rule is its own `return false` — malformed input is dropped, never
--- coerced or "repaired". A peer that ships an inconsistent shape is
--- either modded, buggy, or hostile; in any of those cases letting the
--- message through would let manipulated traffic render somewhere it
--- shouldn't.
---
--- The recipient set permits `'notify'` (the UI subsystem channel). Sim
--- callers that don't relay `'notify'` traffic must reject it separately
--- at their call site.
---@param msg any
---@return boolean
function IsValidPayload(msg)
    if type(msg) ~= 'table' then return false end
    if msg.Chat ~= true then return false end
    if type(msg.text) ~= 'string' or msg.text == '' then return false end
    if STR_Utf8Len(msg.text) > MaxMessageLength then return false end

    -- Recipient must be one of the supported shapes. Without this guard,
    -- a bare string like 'admin' or a non-string truthy value would fall
    -- through to the UI's recipient-formatting fallback and let a peer
    -- fake a "to you:" header on what is actually a broadcast.
    if msg.to ~= 'all'
        and msg.to ~= 'allies'
        and msg.to ~= 'notify'
        and type(msg.to) ~= 'number' then
        return false
    end

    -- Optional payloads consumed UI-side by `WorldCamera:RestoreSettings`
    -- and the camera-link click handler must be tables; reject other
    -- shapes here so malformed values don't crash those handlers on click.
    if msg.camera   ~= nil and type(msg.camera)   ~= 'table' then return false end
    if msg.location ~= nil and type(msg.location) ~= 'table' then return false end

    -- Optional `Args` payload used by `LOCF`-style format-on-receive lines.
    if msg.Args ~= nil and type(msg.Args) ~= 'table' then return false end

    return true
end
