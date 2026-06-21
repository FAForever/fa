
local Prefs = import("/lua/user/prefs.lua")
local Create = import("/lua/lazyvar.lua").Create

local ProfileKey = "chatoptions"

--- User-tunable chat options; persisted via prefs except for the `muted` table, which is per-game.
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

--- Factory defaults; merged on top of any saved profile during `SetupSingleton`.
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
-- Option keys, exported so call sites address fields without magic strings.

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
-- Slider ranges, exported so the view doesn't duplicate the limits.

--- Inclusive `[Min, Max]` range with a step `Inc`; consumed by the config dialog's IntegerSlider rows.
---@class UIChatSliderRange
---@field Min number
---@field Max number
---@field Inc number

--- Range for the chat font-size slider (`font_size` option).
---@type UIChatSliderRange
FontSizeRange = { Min = 12, Max = 18, Inc = 1 }

--- Range for the idle-fade slider in seconds (`fade_time` option).
---@type UIChatSliderRange
FadeTimeRange = { Min = 5, Max = 30, Inc = 1 }

--- Window opacity slider range; stored as 0.0-1.0 but edited as an integer percent.
---@type UIChatSliderRange
WinAlphaSliderRange = { Min = 20, Max = 100, Inc = 1 }

--- Two-LazyVar split: `Committed` is observed by chat; `Pending` is the dialog's editable draft.
---@class UIChatConfigModel
---@field Committed LazyVar<UIChatOptions>   # the active, saved options observed by the chat feed
---@field Pending   LazyVar<UIChatOptions>   # the draft being edited in the config dialog

--- Singleton handle; nil until `SetupSingleton` (or `GetSingleton`) builds the model.
---@type UIChatConfigModel | nil
local ModelInstance = nil

--- Mutes are per-game: any `muted` payload read from prefs is discarded
--- here, and `Apply` strips it before saving.
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

--- Returns the model singleton, creating it on first access.
---@return UIChatConfigModel
function GetSingleton()
    return ModelInstance or SetupSingleton()
end

--- Shorthand for one-shot reads of `Committed`. Reactive consumers
--- should still subscribe via `LazyVarDerive`.
---@return UIChatOptions
function GetOptions()
    return GetSingleton().Committed()
end

--- Returns a fresh copy of the factory-default options.
---@return UIChatOptions
function GetDefaults()
    return table.copy(DefaultOptions)
end

--- Returns the prefs profile key under which Apply persists options.
---@return string
function GetProfileKey()
    return ProfileKey
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton on the new module and copies
--- current LazyVar values across so observers don't see a state reset.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.Committed:Set(table.copy(ModelInstance.Committed()))
        handle.Pending:Set(table.copy(ModelInstance.Pending()))
    end
end

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
