
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
---@field send_type      boolean  # false = all, true = allies
---@field links          boolean  # show camera-link messages
---@field muted          table<number, boolean>   # armyID -> true when muted; absent = not muted

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
    send_type       = false,
    links           = true,
    muted           = {},
}


-------------------------------------------------------------------------------
-- Option keys exported as module globals so views and controllers can address
-- fields without magic strings. Each constant's value matches the field name
-- on `UIChatOptions`.

KeyAllColor       = 'all_color'
KeyAlliesColor    = 'allies_color'
KeyPrivColor      = 'priv_color'
KeyLinkColor      = 'link_color'
KeyNotifyColor    = 'notify_color'
KeyFontSize       = 'font_size'
KeyFadeTime       = 'fade_time'
KeyWinAlpha       = 'win_alpha'
KeyFeedBackground = 'feed_background'
KeySendType       = 'send_type'
KeyLinks          = 'links'
KeyMuted          = 'muted'

-------------------------------------------------------------------------------
-- Value ranges for numeric options. Exported as module globals so the view
-- can construct sliders without duplicating the limits.

---@class UIChatSliderRange
---@field Min number
---@field Max number
---@field Inc number

---@type UIChatSliderRange
FontSizeRange = { Min = 12, Max = 18, Inc = 1 }

---@type UIChatSliderRange
FadeTimeRange = { Min = 5, Max = 30, Inc = 1 }

--- Window alpha is stored as 0.0-1.0 but edited via an integer percent slider.
---@type UIChatSliderRange
WinAlphaSliderRange = { Min = 20, Max = 100, Inc = 1 }

---@class UIChatConfigModel
---@field Committed LazyVar<UIChatOptions>   # the active, saved options observed by the chat feed
---@field Pending   LazyVar<UIChatOptions>   # the draft being edited in the config dialog

---@type UIChatConfigModel | nil
local ModelInstance = nil

--- Creates and initializes the model singleton from the player profile.
--- Mutes are deliberately per-game: any `muted` payload read from prefs is
--- discarded, and `Apply` strips it before saving.
---@return UIChatConfigModel
function SetupSingleton()
    local saved = Prefs.GetFieldFromCurrentProfile(ProfileKey) or {}
    local committed = table.merged(DefaultOptions, saved)
    committed.muted = {}

    ModelInstance = {
        Committed = Create(committed),
        Pending   = Create(table.copy(committed)),
    }

    return ModelInstance
end

--- Returns the model singleton, creating it if it does not exist yet.
---@return UIChatConfigModel
function GetSingleton()
    return ModelInstance or SetupSingleton()
end

--- Shorthand for `GetSingleton().Committed()` — the current, applied
--- options snapshot. Use it for one-shot reads at the point of use; views
--- that need to react to changes should still subscribe via
--- `LazyVarDerive(GetSingleton().Committed, ...)`.
---@return UIChatOptions
function GetOptions()
    return GetSingleton().Committed()
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
