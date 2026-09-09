-- Identifies which target file a SupCom mod "hook" file extends, so plugin.lua can stitch the
-- two together before LuaLS sees either.
--
-- SupCom mods can define "hook" files under a mod's hookdir (a folder mirroring the game's own
-- file structure - MODS.LUA:150-198, default `/hook`, configurable per-mod). After the target
-- script loads, a matching hook file's content is concatenated to the END of it, and the
-- combined chunk is what actually runs - sharing the target's top-level scope (that's how the
-- documented `local oldFn = Fn` / `Cls = Class(oldCls) {...}` override patterns work at all).
--
-- Detection: prefer an explicit `---@declare-hook <path>` annotation (works for any hookdir);
-- fall back to the `/hook/<relpath>` path convention (covers the documented default with zero
-- annotation effort, but misses mods with a custom hookdir).

local M = {}

---@param uri  string
---@param text string
---@return string?  relPath  workspace-relative path of the file this hooks, or nil if this
---                          doesn't look like a hook file at all
function M.findTarget(uri, text)
    local explicit = text:match('%-%-%-@declare%-hook%s+(%S+)')
    if explicit then
        return explicit
    end
    return uri:match('/[Hh]ook/(.+)$')
end

return M
