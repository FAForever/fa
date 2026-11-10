-----------------------------------------------------------------
-- File: lua/ui/controls.lua
-- Author: Crotalus
-- Summary: Let this file have all references to UI controls to make UI behave better
-- when hot-reloading lua files
-----------------------------------------------------------------

local controls = {}

--- Returns a table that persists between file reloads.
---@param key? string # key for the table. Defaults to the source of the calling file.
---@return table
function Get(key)
    if not key then
        key = debug.getinfo(2, "S").source
    end

    controls[key] = controls[key] or {}
    return controls[key]
end
