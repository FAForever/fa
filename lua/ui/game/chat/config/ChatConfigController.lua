
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

--- Setting `muted = false` clears the key so the table stays compact;
--- absent keys read as "not muted".
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

--- Writes directly to `Committed` so `/mute` and `/unmute` take effect
--- immediately. Pending is left alone — an open config dialog keeps its
--- draft, and the next open re-syncs Pending from Committed.
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

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
