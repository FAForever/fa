
local Prefs = import("/lua/user/prefs.lua")

--- Convenience accessor for the config model singleton.
local function Model()
    return import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetSingleton()
end

--- Marks pending options active and persists everything except `muted`,
--- which is intentionally per-game.
function Apply()
    local model = Model()
    local options = table.copy(model.Pending())
    model.Committed:Set(options)

    local persisted = table.copy(options)
    persisted.muted = nil
    Prefs.SetToCurrentProfile(
        import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetProfileKey(),
        persisted
    )
end

--- Reverts the draft (Pending) to factory defaults; does not commit until Apply.
function Reset()
    Model().Pending:Set(
        import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetDefaults()
    )
end

--- Discards the draft and re-syncs Pending from Committed.
function Cancel()
    local model = Model()
    model.Pending:Set(table.copy(model.Committed()))
end

--- Creates a new table copy to ensure the Pending LazyVar goes dirty.
---@param key string
---@param value any
function SetOption(key, value)
    local model = Model()
    local draft = table.copy(model.Pending())
    draft[key] = value
    model.Pending:Set(draft)
end

--- Returns a deep-enough copy of `options` with `muted[armyID]` flipped
--- to the requested state. `muted = false` clears the key so the table
--- stays compact (absent keys read as "not muted"). Always returns a
--- fresh `options` and a fresh `muted` map so the LazyVar dirty check
--- fires in the caller's `:Set`.
---@param options UIChatOptions
---@param armyID  number
---@param muted   boolean
---@return UIChatOptions
local function WithMuteChange(options, armyID, muted)
    local copy = table.copy(options)
    local map = table.copy(copy.muted or {})
    if muted then
        map[armyID] = true
    else
        map[armyID] = nil
    end
    copy.muted = map
    return copy
end

--- Updates the dialog's draft `Pending` mute map.
---@param armyID number
---@param muted  boolean
function SetMuted(armyID, muted)
    local model = Model()
    model.Pending:Set(WithMuteChange(model.Pending(), armyID, muted))
end

--- Writes a mute change to both `Committed` (so `/mute` and `/unmute`
--- take effect immediately) and `Pending` (so an open config dialog's
--- draft doesn't overwrite the live change on Apply). Only the entry
--- for `armyID` is touched, so other in-flight Pending edits are
--- preserved.
---@param armyID number
---@param muted  boolean
function SetMutedLive(armyID, muted)
    local model = Model()
    model.Committed:Set(WithMuteChange(model.Committed(), armyID, muted))
    model.Pending:Set(WithMuteChange(model.Pending(), armyID, muted))
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
