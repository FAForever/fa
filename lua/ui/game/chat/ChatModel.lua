
local Create = import("/lua/lazyvar.lua").Create

-------------------------------------------------------------------------------
-- Recipient constants, exported so the rest of the system never hardcodes them.

RecipientAll = 'all'

RecipientAllies = 'allies'

--- UI subsystem channel for the Notify system. Receive-only, not part of
--- `UIChatRecipient` because users can't send to this channel.
RecipientNotify = 'notify'

--- Send target: a known channel constant, or an army ID for a private whisper.
---@alias UIChatRecipient 'all' | 'allies' | number  # number = army ID for a private message

-------------------------------------------------------------------------------
-- History entry.

--- Location hint carried by a sim-originated message (AI brains, system
--- messages). The UI translates this to a camera move on click without
--- forcing the viewer's pitch/heading to match the sender's (unlike
--- `Camera`, which restores a full snapshot).
---@class UIChatEntryLocation
---@field Position? Vector         # world-space focus point
---@field Area?     Rectangle      # world-space rectangle to frame

--- One row in the append-only history log; covers both live receives and replay/sim deliveries.
---@class UIChatEntry
---@field Name        string             # formatted prefix, e.g. "Sender to allies:"
---@field Text        string             # raw message body
---@field Color       string             # ARGB hex of the sender's team color
---@field BodyColor?  string             # explicit ARGB hex for the body text; bypasses the palette lookup (used by system / synthetic lines that always render the same colour)
---@field ColorKey?   string             # palette key (e.g. `'all_color'`, `'priv_color'`, `'link_color'`) resolved against `ChatConfigModel.GetOptions()` at render time; ignored when `BodyColor` is set
---@field ArmyID      number             # sender's army index
---@field Faction     number             # faction icon index (1-based)
---@field Recipient   UIChatRecipient    # the target this message was directed to
---@field Camera?     table              # camera state (`SaveSettings` snapshot) when the sender attached their exact view
---@field Location?   UIChatEntryLocation # lightweight location hint from a sim-originated sender (AI brain, system message)
---@field Id?         string             # near-unique sender-stamped id (`tostring(msg)`); used to dedupe the `Sync.ChatMessages` replay/sim path against the live `SessionSendChatMessage` path
---@field WrappedText? string[]          # view-side cache: text wrapped to the current row width (populated by ChatInterface)

--- Reactive chat-state singleton: the single source of truth shared by every chat view.
---@class UIChatModel
---@field History       LazyVar<UIChatEntry[]>     # append-only message log (set a new table ref to trigger dirty)
---@field Recipient     LazyVar<UIChatRecipient>   # current send target
---@field WindowVisible LazyVar<boolean>           # whether the chat window is open
---@field LastActivity  LazyVar<number>            # `GetSystemTimeSeconds()` of the most recent user / receive activity; observed by the chat window's idle / fade timer
---@field Pinned        LazyVar<boolean>           # title-bar pin checkbox; while true the chat window's idle auto-close is suspended

--- Singleton handle; nil until `SetupSingleton` (or `GetSingleton`) builds the model.
---@type UIChatModel | nil
local ModelInstance = nil

--- Allocates a fresh model singleton, replacing any existing instance.
---@return UIChatModel
function SetupSingleton()
    ModelInstance = {
        History       = Create({}),
        Recipient     = Create(RecipientAll),
        WindowVisible = Create(false),
        LastActivity  = Create(GetSystemTimeSeconds()),
        Pinned        = Create(false),
    }
    return ModelInstance
end

--- Returns the model singleton, creating it on first access.
---@return UIChatModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UIChatModel]]
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton on the new module and copies
--- the current LazyVar values across so observers don't see a state reset.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.History:Set(ModelInstance.History())
        handle.Recipient:Set(ModelInstance.Recipient())
        handle.WindowVisible:Set(ModelInstance.WindowVisible())
        handle.LastActivity:Set(ModelInstance.LastActivity())
        handle.Pinned:Set(ModelInstance.Pinned())
    end
end

--- Hot-reload hook: re-imports this module after a couple of frames.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
