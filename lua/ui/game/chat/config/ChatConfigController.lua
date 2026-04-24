
local Prefs = import("/lua/user/prefs.lua")

local function Model()
    return import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetSingleton()
end

--- Commits the pending options: marks them active for this session and
--- persists everything except `muted`. Mutes are intentionally per-game so
--- they don't follow the player into the next match.
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

--- Resets the pending options back to the built-in defaults.
function Reset()
    Model().Pending:Set(
        import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetDefaults()
    )
end

--- Discards all pending edits, reverting to the last committed options.
function Cancel()
    local model = Model()
    model.Pending:Set(table.copy(model.Committed()))
end

--- Updates a single field in the pending options.
--- Creates a new table copy to ensure the Pending LazyVar goes dirty.
---@param key string
---@param value any
function SetOption(key, value)
    local model = Model()
    local draft = table.copy(model.Pending())
    draft[key] = value
    model.Pending:Set(draft)
end

--- Toggles the muted flag for a specific army on the pending options.
--- Absent entries are treated as "not muted"; setting `muted = false` clears
--- the key so the table stays compact.
---@param armyID number
---@param muted  boolean
function SetMuted(armyID, muted)
    local model = Model()
    local draft = table.copy(model.Pending())
    local map = table.copy(draft.muted or {})
    if muted then
        map[armyID] = true
    else
        map[armyID] = nil
    end
    draft.muted = map
    model.Pending:Set(draft)
end

--- Applies a mute state directly to `Committed` so slash-command usage
--- (`/mute`, `/unmute`) takes effect immediately without going through the
--- full Apply/Cancel dance. Pending is left alone — if the config dialog is
--- open it keeps its draft, and the next open re-syncs Pending from
--- Committed via `SetupSingleton`/`Cancel`.
---@param armyID number
---@param muted  boolean
function SetMutedLive(armyID, muted)
    local model = Model()
    local options = table.copy(model.Committed())
    local map = table.copy(options.muted or {})
    if muted then
        map[armyID] = true
    else
        map[armyID] = nil
    end
    options.muted = map
    model.Committed:Set(options)
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
