
local Create = import("/lua/lazyvar.lua").Create

-------------------------------------------------------------------------------
-- Recipient constants, exported so the rest of the system never hardcodes them.

--- Broadcast to every connected client.
RecipientAll = 'all'

--- Broadcast to allied players (or all observers when observing).
RecipientAllies = 'allies'

---@alias UIChatRecipient 'all' | 'allies' | number  # number = army ID for a private message

-------------------------------------------------------------------------------
-- History entry.

---@class UIChatEntry
---@field name        string             # formatted prefix, e.g. "Sender to allies:"
---@field text        string             # raw message body
---@field color       string             # ARGB hex of the sender's team color
---@field armyID      number             # sender's army index
---@field faction     number             # faction icon index (1-based)
---@field recipient   UIChatRecipient    # the target this message was directed to
---@field camera?     table              # camera state when the message is a ping link
---@field wrappedText? string[]          # view-side cache: text wrapped to the current row width (populated by ChatInterface)

-------------------------------------------------------------------------------
-- Model.

---@class UIChatModel
---@field History       LazyVar<UIChatEntry[]>     # append-only message log (set a new table ref to trigger dirty)
---@field Recipient     LazyVar<UIChatRecipient>   # current send target
---@field WindowVisible LazyVar<boolean>           # whether the chat window is open

---@type UIChatModel | nil
local ModelInstance = nil

--- Creates and initializes the model singleton.
---@return UIChatModel
function SetupSingleton()
    ModelInstance = {
        History       = Create({}),
        Recipient     = Create(RecipientAll),
        WindowVisible = Create(false),
    }
    return ModelInstance
end

--- Returns the model singleton, creating it if it does not exist yet.
---@return UIChatModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UIChatModel]]
end

-------------------------------------------------------------------------------
--#region Debugging

---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.History:Set(ModelInstance.History())
        handle.Recipient:Set(ModelInstance.Recipient())
        handle.WindowVisible:Set(ModelInstance.WindowVisible())
    end
end

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
