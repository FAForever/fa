-- Types SupCom's bare-table `for` loops by giving LuaLS a real iterator call to read a
-- signature from.
--
-- SupCom's engine lets `for a, b in someTable do ... end` iterate a bare table directly
-- (confirmed: same semantics as pairs()) - no pairs()/ipairs()/custom iterator call needed.
-- That's not a parse error (a bare table is a perfectly valid `in`-clause expression
-- syntactically; only calling it as an iterator function is what real Lua would reject at
-- runtime), so LuaLS parses these loops fine - it just has no function call to read a
-- signature off of, so `a`/`b` end up untyped. Rewriting `in someTable do` to
-- `in pairs(someTable) do` gives LuaLS exactly what it already knows how to type, via
-- pairs()'s own (generic, not name-hardcoded) signature.
--
-- Known limitations: only a *single* `in`-expression with no top-level comma is rewritten,
-- so explicit multi-value iterator forms (`for k, v in next, t do`) are left untouched, as
-- is anything already ending in a call (`pairs(t)`, `ipairs(t)`, `SomeIterator()`) - and a
-- merely-parenthesized bare table (`in (someTable) do`) is mistaken for a call and skipped.

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
---@param i integer  position right at the opening quote
---@param n integer
---@param quote string
---@return integer  position right after the closing quote
local function skipString(text, i, n, quote)
    local j = i + 1
    while j <= n do
        local cj = text:sub(j, j)
        if cj == '\\' then
            j = j + 2
        elseif cj == quote then
            return j + 1
        else
            j = j + 1
        end
    end
    return j
end

---Skips a `--` comment (and long comments) starting at `i`.
---@param text string
---@param i integer
---@param n integer
---@return integer
local function skipComment(text, i, n)
    local afterDashes = i + 2
    local eqs = text:match('^%[(=*)%[', afterDashes)
    if eqs then
        local _, closeEnd = text:find(']' .. eqs .. ']', afterDashes + 2 + #eqs, true)
        return closeEnd and (closeEnd + 1) or (n + 1)
    end
    local nl = text:find('\n', i, true)
    return nl and (nl + 1) or (n + 1)
end

---Parses `<name> (, <name>)*` starting at `pos`, then checks what follows.
---@param text string
---@param pos integer
---@param n integer
---@return integer? exprStart  position right after `in`, or nil if this isn't a generic-for
local function parseNameListThenIn(text, pos, n)
    local k = pos
    while true do
        local _, we = text:find('^%s*', k)
        k = we + 1
        local ns, ne = text:find('^[%a_][%w_]*', k)
        if not ns then
            return nil
        end
        k = ne + 1
        local _, we2 = text:find('^%s*', k)
        k = we2 + 1
        local ch = text:sub(k, k)
        if ch == ',' then
            k = k + 1
        elseif ch == '=' and text:sub(k, k + 1) ~= '==' then
            return nil -- numeric for
        elseif text:sub(k, k + 1) == 'in' and not text:sub(k + 2, k + 2):match('[%w_]') then
            return k + 2
        else
            return nil
        end
    end
end

---@param text string
---@return fa.diff[]
function M.wrapBareIterators(text)
    local n = #text
    local i = 1
    local diffs = {}

    while i <= n do
        local c = text:sub(i, i)

        if c == '-' and text:sub(i, i + 1) == '--' then
            i = skipComment(text, i, n)

        elseif c == '"' or c == "'" then
            i = skipString(text, i, n, c)

        elseif c == '[' then
            i = skipLongBracket(text, i, n) or (i + 1)

        elseif c:match('[%a_]') then
            local _, e, word = text:find('^([%a_][%w_]*)', i)
            i = e + 1

            if word == 'for' then
                local exprStart = parseNameListThenIn(text, i, n)
                if exprStart then
                    local depth = 0
                    local hasTopComma = false
                    local doStart
                    local j = exprStart
                    while j <= n do
                        local cj = text:sub(j, j)
                        if cj == '-' and text:sub(j, j + 1) == '--' then
                            j = skipComment(text, j, n) - 1
                        elseif cj == '"' or cj == "'" then
                            j = skipString(text, j, n, cj) - 1
                        elseif cj == '[' then
                            local close = skipLongBracket(text, j, n)
                            j = close and (close - 1) or j
                            if not close then
                                depth = depth + 1
                            end
                        elseif cj == '(' or cj == '{' then
                            depth = depth + 1
                        elseif cj == ')' or cj == '}' or cj == ']' then
                            depth = depth - 1
                        elseif cj == ',' and depth == 0 then
                            hasTopComma = true
                        elseif cj:match('[%a_]') then
                            local _, we3, w3 = text:find('^([%a_][%w_]*)', j)
                            if w3 == 'do' and depth == 0 then
                                doStart = j
                                break
                            end
                            j = we3
                        end
                        j = j + 1
                    end

                    if doStart and not hasTopComma then
                        local exprEnd = doStart - 1
                        while exprEnd >= exprStart and text:sub(exprEnd, exprEnd):match('%s') do
                            exprEnd = exprEnd - 1
                        end
                        local trimStart = exprStart
                        while trimStart <= exprEnd and text:sub(trimStart, trimStart):match('%s') do
                            trimStart = trimStart + 1
                        end
                        if trimStart <= exprEnd and text:sub(exprEnd, exprEnd) ~= ')' then
                            diffs[#diffs + 1] = { start = trimStart, finish = trimStart - 1, text = 'pairs(' }
                            diffs[#diffs + 1] = { start = exprEnd + 1, finish = exprEnd, text = ')' }
                        end
                    end
                end
            end

        else
            i = i + 1
        end
    end

    return diffs
end

return M
