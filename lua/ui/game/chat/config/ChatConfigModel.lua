
local Prefs = import("/lua/user/prefs.lua")
local Create = import("/lua/lazyvar.lua").Create

local ProfileKey = "chatoptions"

---@class UIChatOptions
---@field all_color      number   # color index 1-8 for "all" messages
---@field allies_color   number   # color index 1-8 for ally messages
---@field priv_color     number   # color index 1-8 for private messages
---@field link_color     number   # color index 1-8 for camera-link messages
---@field notify_color   number   # color index 1-8 for notify messages
---@field font_size      number   # 12-18
---@field fade_time      number   # seconds, 5-30
---@field win_alpha      number   # 0.0-1.0
---@field feed_background boolean
---@field feed_persist   boolean
---@field send_type      boolean  # false = all, true = allies
---@field links          boolean  # show camera-link messages

---@type UIChatOptions
local DefaultOptions = {
    all_color       = 1,
    allies_color    = 2,
    priv_color      = 3,
    link_color      = 4,
    notify_color    = 8,
    font_size       = 14,
    fade_time       = 15,
    win_alpha       = 1.0,
    feed_background = false,
    feed_persist    = true,
    send_type       = false,
    links           = true,
}

---@class UIChatConfigModel
---@field Committed LazyVar<UIChatOptions>   # the active, saved options observed by the chat feed
---@field Pending   LazyVar<UIChatOptions>   # the draft being edited in the config dialog

---@type UIChatConfigModel | nil
local ModelInstance = nil

--- Returns the model singleton, creating it if it does not exist yet.
---@return UIChatConfigModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance
end

--- Creates and initializes the model singleton from the player profile.
---@return UIChatConfigModel
function SetupSingleton()
    local saved = Prefs.GetFieldFromCurrentProfile(ProfileKey) or {}
    local committed = table.merged(DefaultOptions, saved)

    ModelInstance = {
        Committed = Create(committed),
        Pending   = Create(table.copy(committed)),
    }

    return ModelInstance
end

--- Returns a fresh copy of the built-in defaults.
---@return UIChatOptions
function GetDefaults()
    return table.copy(DefaultOptions)
end

---@return string
function GetProfileKey()
    return ProfileKey
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.Committed:Set(table.copy(ModelInstance.Committed()))
        handle.Pending:Set(table.copy(ModelInstance.Pending()))
    end
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
