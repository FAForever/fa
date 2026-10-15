-- Strips SupCom's `{&N &N ...}` table-preallocation hints, which aren't valid Lua 5.1 syntax
-- at all.
--
-- SupCom's Lua fork allows a table constructor to start with preallocation hints,
-- e.g. `{&15 &4}` = preallocate 15 hash-part slots, 4 array-part slots. `&` isn't a
-- Lua 5.1 token at all (no bitwise operators in 5.1), so this is a genuine parse
-- error, not just a diagnostic - has to be stripped from the source text before the
-- real parser ever sees it, same as the `#` comment handling.
--
-- Assumed grammar (only a prefix, right after `{`; count and separator can vary):
-- one or more `&<digits>` tokens, each optionally followed by whitespace and/or a
-- single `,`/`;`, ending wherever the next `&<digits>` doesn't follow. The hints
-- carry no type/value information, so the whole span is just blanked out.

local M = {}

---@class fa.diff
---@field start  integer
---@field finish integer
---@field text   string

---@param text string
---@param i integer  position of '['
---@param n integer
---@return integer? closeEnd
local function skipLongBracket(text, i, n)
    local eqs = text:match('^%[(=*)%[', i)
    if not eqs then
        return nil
    end
    local _, closeEnd = text:find(']' .. eqs .. ']', i + 2 + #eqs, true)
    return closeEnd and (closeEnd + 1) or (n + 1)
end

---@param text string
---@return fa.diff[]
function M.stripHints(text)
    local n = #text
    local i = 1
    local diffs = {}

    while i <= n do
        local c = text:sub(i, i)

        if c == '-' and text:sub(i, i + 1) == '--' then
            local afterDashes = i + 2
            local eqs = text:match('^%[(=*)%[', afterDashes)
            if eqs then
                local _, closeEnd = text:find(']' .. eqs .. ']', afterDashes + 2 + #eqs, true)
                i = closeEnd and (closeEnd + 1) or (n + 1)
            else
                local nl = text:find('\n', i, true)
                i = nl and (nl + 1) or (n + 1)
            end

        elseif c == '"' or c == "'" then
            local quote = c
            local j = i + 1
            while j <= n do
                local cj = text:sub(j, j)
                if cj == '\\' then
                    j = j + 2
                elseif cj == quote then
                    j = j + 1
                    break
                else
                    j = j + 1
                end
            end
            i = j

        elseif c == '[' then
            i = skipLongBracket(text, i, n) or (i + 1)

        elseif c == '{' then
            local k = i + 1
            local sawHint = false
            while true do
                local _, we1 = text:find('^%s*', k)
                k = we1 + 1
                local hs, he = text:find('^&%d+', k)
                if not hs then
                    break
                end
                sawHint = true
                k = he + 1
                local _, we2 = text:find('^%s*', k)
                k = we2 + 1
                local _, ce = text:find('^[,;]', k)
                if ce then
                    k = ce + 1
                end
            end
            if sawHint then
                diffs[#diffs + 1] = {
                    start  = i + 1,
                    finish = k - 1,
                    text   = (' '):rep(k - i - 1),
                }
            end
            i = i + 1

        else
            i = i + 1
        end
    end

    return diffs
end

return M
