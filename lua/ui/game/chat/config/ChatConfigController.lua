
local Prefs = import("/lua/user/prefs.lua")

local function Model()
    return import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetSingleton()
end

--- Commits the pending options: saves them to the profile and marks them active.
function Apply()
    local model = Model()
    local options = table.copy(model.Pending())
    model.Committed:Set(options)
    Prefs.SetToCurrentProfile(
        import("/lua/ui/game/chat/config/ChatConfigModel.lua").GetProfileKey(),
        options
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

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
