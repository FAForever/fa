-- Types SupCom's bare-table `for` loops by giving LuaLS a real iterator call to read a
-- signature from.
--
-- SupCom's engine lets `for a, b in someTable do ... end` iterate a bare table directly (same
-- semantics as pairs()) - no pairs()/ipairs()/custom iterator call needed. That's not a parse
-- error (a bare table is a valid `in`-clause expression syntactically; only calling it as an
-- iterator is what real Lua rejects at runtime), so LuaLS parses these loops fine - it just has
-- no function call to read a signature off of, so `a`/`b` end up untyped. Rewriting
-- `in someTable do` to `in pairs(someTable) do` gives LuaLS exactly what it already knows how to
-- type, via pairs()'s own generic signature. No annotation can do this instead: LuaLS has no
-- annotation for generic-for variables, and FA has ~3,500 such loops.
--
-- Known limitations: only a *single* `in`-expression with no top-level comma is rewritten, so
-- explicit multi-value iterator forms (`for k, v in next, t do`) are left untouched, as is
-- anything already ending in a call (`pairs(t)`, `ipairs(t)`, `SomeIterator()`) - and a merely
-- parenthesized bare table (`in (someTable) do`) is mistaken for a call and skipped.

local lexer = require 'lexer'

local M = {}

local OPEN  = { ['('] = true, ['{'] = true, ['['] = true }
local CLOSE = { [')'] = true, ['}'] = true, [']'] = true }
-- Keywords that can't appear inside an iterator expression at depth 0: seeing one means the
-- loop header is malformed (e.g. mid-edit), so give up on this loop.
local STOP = { ['end'] = true, ['local'] = true, ['for'] = true, ['while'] = true,
               ['if'] = true, ['return'] = true, ['then'] = true }

---@param text string
---@return fa.diff[]
function M.wrapBareIterators(text)
    local tokens = lexer.codeTokens(text)
    local diffs = {}

    for i, tok in ipairs(tokens) do
        if tok.type == 'keyword' and tok.value == 'for' then
            -- `for <name> (, <name>)* in`
            local k = i + 1
            local exprStart
            while tokens[k] and tokens[k].type == 'name' do
                local after = tokens[k + 1]
                if after and after.value == ',' then
                    k = k + 2
                elseif after and after.type == 'keyword' and after.value == 'in' then
                    exprStart = k + 2
                    break
                else
                    break
                end
            end

            if exprStart and tokens[exprStart] then
                local depth = 0
                local hasTopComma = false
                local doIndex
                local j = exprStart
                while tokens[j] do
                    local t = tokens[j]
                    if t.type == 'op' and OPEN[t.value] then
                        depth = depth + 1
                    elseif t.type == 'op' and CLOSE[t.value] then
                        depth = depth - 1
                    elseif depth == 0 and t.type == 'op' and t.value == ',' then
                        hasTopComma = true
                    elseif depth == 0 and t.type == 'keyword' and t.value == 'do' then
                        doIndex = j
                        break
                    elseif depth == 0 and t.type == 'keyword' and STOP[t.value] then
                        break
                    end
                    j = j + 1
                end

                if doIndex and doIndex > exprStart and not hasTopComma then
                    local first = tokens[exprStart]
                    local last = tokens[doIndex - 1]
                    if last.value ~= ')' then
                        diffs[#diffs + 1] = { start = first.start, finish = first.start - 1, text = 'pairs(' }
                        diffs[#diffs + 1] = { start = last.finish + 1, finish = last.finish, text = ')' }
                    end
                end
            end
        end
    end

    return diffs
end

return M
