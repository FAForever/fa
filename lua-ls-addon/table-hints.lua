-- Strips SupCom's `{&N &N ...}` table-preallocation hints, which aren't valid Lua 5.1 syntax.
--
-- SupCom's Lua fork allows a table constructor to start with preallocation hints, e.g.
-- `{&15 &4}` = preallocate 15 hash-part slots, 4 array-part slots. `&` isn't a Lua 5.1 token at
-- all (no bitwise operators in 5.1), so this is a genuine parse error, not just a diagnostic -
-- it has to be stripped before the parser sees it, same as the `#` comment handling.
--
-- Assumed grammar (only a prefix, right after `{`): one or more `&<digits>` tokens, each
-- optionally followed by a single `,`/`;`, ending wherever the next `&<digits>` doesn't follow.
-- The hints carry no type information, so the whole span is blanked out.

local lexer = require 'lexer'

local M = {}

---@class fa.diff
---@field start  integer
---@field finish integer
---@field text   string

---@param text string
---@return fa.diff[]
function M.stripHints(text)
    local tokens = lexer.codeTokens(text)
    local diffs = {}
    for i, tok in ipairs(tokens) do
        if tok.type == 'op' and tok.value == '{' then
            local k = i + 1
            local lastEnd
            while tokens[k] and tokens[k].value == '&'
              and tokens[k + 1] and tokens[k + 1].type == 'number'
              and tokens[k + 1].start == tokens[k].finish + 1 do
                lastEnd = tokens[k + 1].finish
                k = k + 2
                if tokens[k] and (tokens[k].value == ',' or tokens[k].value == ';') then
                    lastEnd = tokens[k].finish
                    k = k + 1
                end
            end
            if lastEnd then
                diffs[#diffs + 1] = {
                    start  = tok.finish + 1,
                    finish = lastEnd,
                    text   = (' '):rep(lastEnd - tok.finish),
                }
            end
        end
    end
    return diffs
end

return M
