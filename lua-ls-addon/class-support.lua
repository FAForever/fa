-- Makes FA's `Class()`-family OOP sugar readable as a real class to LuaLS by stripping the
-- wrapper call down to a plain table.
--
-- FA classes are defined as `Name = ClassFn(Base1, Base2, ...) { specs }` (or the no-base
-- `Name = ClassFn { specs }` form), per lua/system/class.lua. LuaLS only takes a `---@class`
-- doc's fields from `---@field` lines, from a table constructor assigned *directly* to the
-- documented variable, or from `setmetatable({...})` (script/vm/compiler.lua, the doc.class
-- branch of the field search). Once a doc is bound it doesn't compile the assigned value at all,
-- so the `---@generic T ... @return fun(specs: T): T|T_Base` annotations on `Class()` never get
-- a say. Annotations can't fix that, so we blank the `ClassFn(...)` text, leaving a plain
-- `Name = { specs }` that LuaLS binds natively.
--
-- The `---@class Name: Bases` doc itself is NOT generated here: it belongs in the source, where
-- FA already writes it for its classes (nested states follow FA's `Owner_Field` naming, e.g.
-- `DefaultProjectileWeapon_IdleState`). A class without a doc still gets its spec table's
-- fields; it just has no named type or inheritance.
--
-- Blanking the wrapper also erases the only reference to a bare-identifier base
-- (`Class(NullShell) {}`), which would make its `local NullShell = ...` declaration look unused
-- (324 of 600 files in a random fa sample hit this). A `local _ = NullShell` line is inserted
-- before the statement - `_` is exempt from LuaLS's unused-local check - and above any comment
-- block directly preceding it, so it doesn't split a `---@class` doc from the statement it
-- documents. If export-env.lua rewrote that base reference to `M.Base`, the keep-alive reads
-- `M.Base` too, since the bare name no longer exists in the output.

local lexer = require 'lexer'

local M = {}

local CLASS_FUNCTIONS = {
    Class = true, ClassSimple = true, ClassUI = true, ClassShield = true,
    ClassProjectile = true, ClassDummyProjectile = true, ClassUnit = true,
    ClassDummyUnit = true, ClassWeapon = true, ClassTrashBag = true, State = true,
}

--- Walks backward from `pos` through a contiguous run of `--` comment lines (stopping at a blank
--- line or code), returning the start of the topmost comment line, or the start of `pos`'s own
--- line if no comment block directly precedes it. A statement inserted there doesn't separate a
--- doc comment from the statement it documents.
---@param text string
---@param pos  integer
---@return integer
local function findCommentBlockStart(text, pos)
    local ownLineStart = text:sub(1, pos - 1):match('.*\n()') or 1
    local boundary = ownLineStart
    local lineEnd = ownLineStart - 2
    while lineEnd >= 1 do
        local lineStart = text:sub(1, lineEnd):match('.*\n()') or 1
        local trimmed = text:sub(lineStart, lineEnd):match('^%s*(.-)%s*$')
        if trimmed:match('^%-%-') then
            boundary = lineStart
            lineEnd = lineStart - 2
        else
            break
        end
    end
    return boundary
end

--- Whether tokens[first..last] are a dotted name chain (`a`, `a.b.c`).
---@param tokens fa.token[]
---@param first integer
---@param last integer
---@return boolean
local function isDottedName(tokens, first, last)
    if (last - first) % 2 ~= 0 then
        return false
    end
    for k = first, last do
        local t = tokens[k]
        if (k - first) % 2 == 0 then
            if t.type ~= 'name' then
                return false
            end
        elseif t.value ~= '.' then
            return false
        end
    end
    return true
end

--- Index of the first token of the assignment target ending at tokens[i] (`Name`, `a.b.Name`,
--- `local Name`), or nil if tokens[i] isn't the end of one.
---@param tokens fa.token[]
---@param i integer
---@return integer?
local function findTargetStart(tokens, i)
    if not (tokens[i] and tokens[i].type == 'name') then
        return nil
    end
    local j = i
    while tokens[j - 1] and tokens[j - 1].value == '.' and tokens[j - 2] and tokens[j - 2].type == 'name' do
        j = j - 2
    end
    local before = tokens[j - 1]
    if before and before.type == 'op' and (before.value == '.' or before.value == ':') then
        return nil
    end
    if j == i and before and before.type == 'keyword' and before.value == 'local' then
        return j - 1
    end
    return j
end

---@param text        string
---@param rewritten?  table<integer, boolean>  start offsets export-env.lua prefixed with the module name
---@param moduleName? string                   the module table's name (default `M`)
---@return fa.diff[]
function M.stripWrappers(text, rewritten, moduleName)
    rewritten = rewritten or {}
    moduleName = moduleName or 'M'
    local tokens = lexer.codeTokens(text)
    local diffs = {}
    -- Only table-constructor braces: a keep-alive statement can't go inside a table's field list.
    local braceDepth = 0

    for i, tok in ipairs(tokens) do
        if tok.type == 'op' then
            if tok.value == '{' then
                braceDepth = braceDepth + 1
            elseif tok.value == '}' then
                braceDepth = math.max(0, braceDepth - 1)
            end

        elseif tok.type == 'name' and CLASS_FUNCTIONS[tok.value] then
            local prev = tokens[i - 1]
            local isMember = prev and prev.type == 'op' and (prev.value == '.' or prev.value == ':')
            local isDefinition = prev and prev.type == 'keyword' and prev.value == 'function'
            if not isMember and not isDefinition then
                -- Optional `(bases...)`, then the spec table's `{`.
                local k = i + 1
                local bases = {}
                local balanced = true
                if tokens[k] and tokens[k].value == '(' then
                    local depth = 0
                    local argStart = k + 1
                    while tokens[k] do
                        local v = tokens[k].type == 'op' and tokens[k].value
                        if v == '(' or v == '{' or v == '[' then
                            depth = depth + 1
                        elseif v == ')' or v == '}' or v == ']' then
                            depth = depth - 1
                            if depth == 0 then
                                if k > argStart then
                                    bases[#bases + 1] = { first = argStart, last = k - 1 }
                                end
                                break
                            end
                        elseif v == ',' and depth == 1 then
                            bases[#bases + 1] = { first = argStart, last = k - 1 }
                            argStart = k + 1
                        end
                        k = k + 1
                    end
                    balanced = tokens[k] ~= nil
                    k = k + 1
                end

                local brace = tokens[k]
                if balanced and brace and brace.value == '{' then
                    diffs[#diffs + 1] = {
                        start  = tok.start,
                        finish = brace.start - 1,
                        text   = (' '):rep(brace.start - tok.start),
                    }

                    local eq = tokens[i - 1]
                    local targetStart = eq and eq.value == '=' and findTargetStart(tokens, i - 2)
                    if targetStart and braceDepth == 0 then
                        local keepAlive = {}
                        for _, base in ipairs(bases) do
                            if isDottedName(tokens, base.first, base.last) then
                                local raw = text:sub(tokens[base.first].start, tokens[base.last].finish)
                                if rewritten[tokens[base.first].start] then
                                    raw = moduleName .. '.' .. raw
                                end
                                keepAlive[#keepAlive + 1] = 'local _ = ' .. raw
                            end
                        end
                        if #keepAlive > 0 then
                            local insertAt = findCommentBlockStart(text, tokens[targetStart].start)
                            diffs[#diffs + 1] = {
                                start  = insertAt,
                                finish = insertAt - 1,
                                text   = table.concat(keepAlive, '; ') .. '\n',
                            }
                        end
                    end
                end
            end
        end
    end

    return diffs
end

return M
