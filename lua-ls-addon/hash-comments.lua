-- Converts SupCom's `#` comment marker into standard Lua `--`, without touching a `#` that's
-- just an ordinary character.
--
-- SupCom's Lua preprocessor treats a bare `#` as a comment-start (equivalent to `--`), which
-- isn't valid standard Lua syntax, so it has to be blanked out before parsing. But `#` outside
-- of that convention is still an ordinary character: it appears inside 171+ real FA string
-- literals (confirmed, e.g. shared/DebugFunction.lua:101's `"%0#" .. ...` format-width
-- pattern, and dozens of changelog strings literally starting `"# Patch ..."`), and inside
-- already-valid `--` comments, including `--#region`/`--#endregion` folding markers
-- (script/core/folding.lua:99-106 matches on the comment text starting with `#region` -
-- blindly rewriting the `#` there to `--` turns it into `----region`, which no longer
-- matches, silently breaking code folding). FA source never uses `#` as Lua's length
-- operator (checked: not a single occurrence outside strings/comments in a repo-wide sample -
-- consistent with `table.getn` being used everywhere instead, presumably because `#` can't
-- mean "length" and "comment" at once), so it's safe to treat every remaining `#` outside a
-- string or an existing comment as a SupCom comment-start.

local M = {}

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
function M.stripHashComments(text)
    local n = #text
    local i = 1
    local diffs = {}

    while i <= n do
        local c = text:sub(i, i)

        if c == '-' and text:sub(i, i + 1) == '--' then
            -- already a real comment (possibly a #region/#endregion folding marker) - skip
            -- the whole thing untouched, converting any '#' inside would only ever corrupt it
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

        elseif c == '#' then
            diffs[#diffs + 1] = {
                start  = i,
                finish = i,
                text   = '--',
            }
            i = i + 1

        else
            i = i + 1
        end
    end

    return diffs
end

return M
