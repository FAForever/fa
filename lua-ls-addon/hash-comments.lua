-- Converts SupCom's `#` comment marker into standard Lua `--`.
--
-- SupCom's Lua preprocessor treats `#` as a comment start (equivalent to `--`), which isn't valid
-- standard Lua, so it has to be rewritten before parsing. FA only ever uses it as a whole-line
-- comment, so lexer.lua treats a `#` as a comment only when it's the first non-blank character
-- on its line. Everything else stays an ordinary `#`:
--   - inside strings (171+ real FA literals, e.g. shared/DebugFunction.lua's `"%0#"` format
--     pattern and changelog strings starting `"# Patch ..."`)
--   - inside `--` comments, including `--#region`/`--#endregion` folding markers
--     (script/core/folding.lua matches comment text starting with `#region`; rewriting it to
--     `----region` would break folding)
--   - mid-line, where it's the length operator - tooling scripts run by standard Lua use it
--     (`for i = 1, #arg do` in wiki/Run.lua and .github/.../bake-props.lua)

local lexer = require 'lexer'

local M = {}

---@param text string
---@return fa.diff[]
function M.stripHashComments(text)
    local diffs = {}
    for _, tok in ipairs(lexer.tokenize(text)) do
        if tok.type == 'hashcomment' then
            diffs[#diffs + 1] = {
                start  = tok.start,
                finish = tok.start,
                text   = '--',
            }
        end
    end
    return diffs
end

return M
