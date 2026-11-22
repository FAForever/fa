-- Makes FA's implicit module system visible to LuaLS: finds each file's bare top-level
-- declarations and rewrites the file into a real Lua module, so every export resolves
-- correctly wherever it's referenced from - including forward references, from inside a
-- function defined earlier in the same file.
--
-- This is a heuristic pre-parse scanner, not a real parser. FA files never `return {...}` - a
-- file's bare top-level assignments and functions (no `local` keyword), such as
-- `Name = ...` / `function Name(...)`, ARE its exports, resolved by `import()` at runtime. We
-- rewrite the whole file into a classic Lua module: `local M = {}`, every export reachable as
-- `M.Name`, and the file ends with `return M`. That's what makes forward/mutual references
-- between exports resolve correctly, including from *inside* an earlier-defined function's
-- body: `M` itself is assigned exactly once (`local M = {}`), so its own local-scoping is
-- trivially unambiguous regardless of where in the file it's referenced from, and `M.Name`
-- field resolution (unlike a bare local) isn't restricted to "last assignment before this
-- textual position" - LuaLS resolves it by merging every known `M.Name = ...` in the file,
-- wherever it sits. This also sidesteps Lua 5.1's 200-local-per-chunk cap entirely for exported
-- names, since table fields don't consume it - only forward-declared *unsafe* names (see below)
-- do.
--
-- Depth tracks both block keywords (function/if/do/repeat...end/until) AND `{`/`}`, since
-- FA classes are one big table constructor (`Unit = ClassUnit(...) { Foo = function(self)
-- ... end, ... }`) - without counting braces too, every `Key = function(...) end,` entry
-- inside it looks exactly like a bare top-level export the moment its own function/end
-- balances back to depth 0, and gets wrongly captured (verified against real FA files:
-- lua/sim/Unit.lua alone went from 3 genuine top-level names to 329 false ones without this).
--
-- Rewriting every REFERENCE (not just each definition) to `M.Name` is only safe for a name
-- that isn't shadowed anywhere in the file - a `local`, function parameter, or `for` loop
-- variable sharing the same name would have every bare use *inside its own scope* wrongly
-- redirected to the module field otherwise (confirmed with a real example:
-- lua/system/profile.lua does `checkpoint = debug.profiledata` at the top level, then
-- `function checkpoint_to_table(checkpoint)` - the parameter shadows the export for that
-- function's whole body). A file-wide "does this name appear as a local/param/loop-var
-- anywhere" scan is a conservative, whole-file-granularity substitute for real scope
-- resolution: names it flags ("unsafe") keep today's exact behaviour (forward-declared as a
-- real `local`, bridged into `M` with one `M.Name = Name` assignment before `return M`) rather
-- than risk a wrong rewrite. Verified empirically negligible: across all 2,801 *.lua files in
-- the fa repo (102,668 top-level exports total), only 24 files / 57 names are ever shadowed
-- anywhere in their own file.
--
-- Known limitations (acceptable trade-off for a regex/state-machine scanner
-- instead of a full parser): spaced-out member access (`t . Name = x`) isn't
-- recognised as a member access and could false-positive.

local M = {}

local BLOCK_OPEN  = { ['function'] = true, ['if'] = true, ['do'] = true, ['repeat'] = true }
local BLOCK_CLOSE = { ['end'] = true, ['until'] = true }
local LOOP_HEADER = { ['for'] = true, ['while'] = true }

-- Files marked `---@declare-global` (or `---@meta`) are declaring real globals, not FA
-- module exports - e.g. the engine API stubs. Leave them as plain, untransformed Lua.
local function optsOut(text)
    return text:find('%-%-%-@declare%-global') ~= nil
        or text:find('%-%-%-@meta') ~= nil
end

--- Given the position right after an identifier, checks whether it's followed by
--- `(, <name>)* =` (not `==`) - i.e. whether this identifier is one entry in a
--- comma-separated name-list that ultimately ends in a bare assignment. Used so each name in
--- `A, B, C = 1, 2, 3` can independently confirm its own membership, regardless of position.
---@param text string
---@param pos  integer
---@param n    integer
---@return boolean
local function isNameListThenEquals(text, pos, n)
    local k = pos
    while true do
        local _, we = text:find('^%s*', k)
        k = we + 1
        if text:sub(k, k) ~= ',' then
            return false
        end
        k = k + 1
        local _, we2 = text:find('^%s*', k)
        k = we2 + 1
        local ns, ne = text:find('^[%a_][%w_]*', k)
        if not ns then
            return false
        end
        k = ne + 1
        local _, we3 = text:find('^%s*', k)
        k = we3 + 1
        if text:sub(k, k) == '=' and text:sub(k, k + 1) ~= '==' then
            return true
        end
        -- else loop again, expecting another ", name"
    end
end

--- Given the position right after `function`, finds and returns the parameter-list body text
--- (between the parens), covering `function Name(...)`, `function Obj.Name(...)`,
--- `function Obj:Method(...)` and anonymous `function(...)` alike - the name/dotted/colon
--- chain in front of the parens (if any) doesn't matter, only the parens themselves do.
---@param text string
---@param pos  integer  position right after the `function` keyword
---@return string?
local function findParamsText(text, pos)
    local j = pos
    local n = #text
    while j <= n and text:sub(j, j):match('[%s%w_%.%:]') do
        j = j + 1
    end
    if text:sub(j, j) ~= '(' then
        return nil
    end
    local closeParen = text:find(')', j, true)
    if not closeParen then
        return nil
    end
    return text:sub(j + 1, closeParen - 1)
end

--- Splits a `for` loop header's variable-name list (numeric or generic form) starting right
--- after the `for` keyword, returning every comma-separated name up to (not including) the
--- `=` or `in` that ends the list. These are implicitly local for the loop body.
---@param text string
---@param pos  integer  position right after the `for` keyword
---@return string[]
local function findForLoopVars(text, pos)
    local names = {}
    local namesText = text:match('^%s*([%a_][%w_%s,]-)%s*=', pos)
        or text:match('^%s*([%a_][%w_%s,]-)%s+in%f[%A]', pos)
    if namesText then
        for nm in namesText:gmatch('[%a_][%w_]*') do
            names[#names + 1] = nm
        end
    end
    return names
end

---@param text string
---@return string[] exports  ordered, de-duplicated bare top-level names
---@return boolean  hasTopReturn  whether the file already has a top-level `return`
---@return integer  topLevelLocalCount  count of the file's own pre-existing top-level locals
---@return table<string, boolean> unsafeNames  export names shadowed by a local/param/loop-var
---                                somewhere in the file - unsafe to rewrite every reference of
function M.scan(text)
    if optsOut(text) then
        return {}, false, 0, {}
    end

    local n = #text
    local i = 1
    local depth = 0
    local loopHeaderDepth = 0
    local lastWord = nil
    local prevChar = nil
    local hasTopReturn = false
    -- Persists across the commas in a `local a, b, c = ...` name-list, unlike `lastWord`
    -- (which resets on every comma) - needed so e.g. `local pairs, ipairs = pairs, ipairs`
    -- doesn't wrongly treat `ipairs` as a bare export just because the comma before it wiped
    -- `lastWord` back to nil.
    local localList = false
    -- Counts every top-level `local` name (including `local function Name()`) that already
    -- exists in the file, so the caller can tell whether adding more locals (for unsafe names)
    -- would cross Lua's 200-local-per-chunk cap.
    local topLevelLocalCount = 0

    -- Every name introduced as a `local` (any depth), a function parameter (any depth, any
    -- function), or a `for` loop variable (any depth) anywhere in the file - a superset used
    -- below to flag which exports are unsafe to rewrite at every reference site.
    local localOrParamNames = {}

    local exportsSet = {}
    local exports = {}
    local function addExport(name)
        if not exportsSet[name] then
            exportsSet[name] = true
            exports[#exports + 1] = name
        end
    end

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
            prevChar = quote
            lastWord = nil

        elseif c == '[' then
            local eqs = text:match('^%[(=*)%[', i)
            if eqs then
                local _, closeEnd = text:find(']' .. eqs .. ']', i + 2 + #eqs, true)
                i = closeEnd and (closeEnd + 1) or (n + 1)
            else
                i = i + 1
            end
            prevChar = ']'
            lastWord = nil

        elseif c:match('%s') then
            i = i + 1

        elseif c:match('[%a_]') then
            local _, e, word = text:find('^([%a_][%w_]*)', i)
            i = e + 1

            local k = i
            while k <= n and text:sub(k, k):match('%s') do
                k = k + 1
            end
            local nextChar = text:sub(k, k)

            if word == 'function' then
                depth = depth + 1
                if depth == 1 and loopHeaderDepth == 0 then
                    if lastWord == 'local' then
                        topLevelLocalCount = topLevelLocalCount + 1
                    else
                        local ns, _, fname = text:find('^%s*([%a_][%w_]*)%s*%(', i)
                        if ns then
                            addExport(fname)
                        end
                    end
                end
                -- this function's own parameters are locally-scoped to its body, at any depth
                local paramsText = findParamsText(text, i)
                if paramsText then
                    -- Lua 5.4 (the runtime LuaLS executes plugins under) makes generic-for
                    -- control variables implicitly const - reassigning `p` directly here is a
                    -- compile error ("attempt to assign to const variable 'p'") that fails this
                    -- whole module's `require`, taking every other scanner down with it (the
                    -- exact cause of a prior "everything is broken" regression - confirmed via
                    -- the LuaLS output log's stack traceback pointing at this line).
                    for rawParam in paramsText:gmatch('[^,]+') do
                        local p = rawParam:match('^%s*(.-)%s*$')
                        if p:match('^[%a_][%w_]*$') then
                            localOrParamNames[p] = true
                        end
                    end
                end
            elseif BLOCK_OPEN[word] then
                depth = depth + 1
                if word == 'do' and loopHeaderDepth > 0 then
                    loopHeaderDepth = loopHeaderDepth - 1
                end
            elseif BLOCK_CLOSE[word] then
                depth = math.max(0, depth - 1)
            elseif LOOP_HEADER[word] then
                loopHeaderDepth = loopHeaderDepth + 1
                if word == 'for' then
                    for _, nm in ipairs(findForLoopVars(text, i)) do
                        localOrParamNames[nm] = true
                    end
                end
            elseif word == 'return' then
                if depth == 0 and loopHeaderDepth == 0 then
                    hasTopReturn = true
                end
            elseif word == 'local' then
                localList = true
            elseif depth == 0 and loopHeaderDepth == 0
               and prevChar ~= '.' and prevChar ~= ':' then
                if localList then
                    topLevelLocalCount = topLevelLocalCount + 1
                elseif nextChar == '=' and text:sub(k, k + 1) ~= '==' then
                    addExport(word)
                elseif nextChar == ',' and isNameListThenEquals(text, i, n) then
                    addExport(word)
                end
            end

            if localList then
                localOrParamNames[word] = true
            end

            if word ~= 'local' then
                localList = localList and nextChar == ','
            end

            lastWord = word
            prevChar = nil

        elseif c == '{' then
            depth = depth + 1
            prevChar = nil
            lastWord = nil
            i = i + 1

        elseif c == '}' then
            depth = math.max(0, depth - 1)
            prevChar = nil
            lastWord = nil
            i = i + 1

        else
            prevChar = (c == '.' or c == ':') and c or nil
            lastWord = nil
            i = i + 1
        end
    end

    local unsafeNames = {}
    for _, name in ipairs(exports) do
        if localOrParamNames[name] then
            unsafeNames[name] = true
        end
    end

    return exports, hasTopReturn, topLevelLocalCount, unsafeNames
end

--- Second pass: for every bare occurrence of a name in `safeNames`, not preceded by `.`/`:`
--- (member access on something else), produces a diff inserting `M.` immediately before it.
--- Handles both definition sites (`Name = ...` -> `M.Name = ...`, `function Name(...)` ->
--- `function M.Name(...)`) and every later reference uniformly - the same insert-before-token
--- diff does both jobs, no separate "is this the definition" tracking needed.
---
--- A bare `Name` immediately followed by `=` (not `==`) is only rewritten at `depth == 0`: at
--- `depth > 0` that shape is a table-constructor key (`{ Name = value }`), not an assignment -
--- exactly the same hazard, and the same depth-based fix, as the original brace-depth bug in
--- `M.scan` above. A `Name` NOT followed by `=` is always a genuine read, safe to rewrite at
--- any depth.
---@param text       string
---@param safeNames  table<string, boolean>
---@return fa.diff[]
function M.rewriteReferences(text, safeNames)
    local n = #text
    local i = 1
    local depth = 0
    local loopHeaderDepth = 0
    local prevChar = nil
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
            prevChar = quote

        elseif c == '[' then
            local eqs = text:match('^%[(=*)%[', i)
            if eqs then
                local _, closeEnd = text:find(']' .. eqs .. ']', i + 2 + #eqs, true)
                i = closeEnd and (closeEnd + 1) or (n + 1)
            else
                i = i + 1
            end
            prevChar = ']'

        elseif c:match('%s') then
            i = i + 1

        elseif c:match('[%a_]') then
            local wordStart = i
            local _, e, word = text:find('^([%a_][%w_]*)', i)
            i = e + 1

            local k = i
            while k <= n and text:sub(k, k):match('%s') do
                k = k + 1
            end
            local nextChar = text:sub(k, k)

            if word == 'function' then
                depth = depth + 1
            elseif BLOCK_OPEN[word] then
                depth = depth + 1
                if word == 'do' and loopHeaderDepth > 0 then
                    loopHeaderDepth = loopHeaderDepth - 1
                end
            elseif BLOCK_CLOSE[word] then
                depth = math.max(0, depth - 1)
            elseif LOOP_HEADER[word] then
                loopHeaderDepth = loopHeaderDepth + 1
            elseif safeNames[word] and prevChar ~= '.' and prevChar ~= ':' then
                local isEqTarget = nextChar == '=' and text:sub(k, k + 1) ~= '=='
                if not isEqTarget or depth == 0 then
                    diffs[#diffs + 1] = { start = wordStart, finish = wordStart - 1, text = 'M.' }
                end
            end

            prevChar = nil

        elseif c == '{' then
            depth = depth + 1
            prevChar = nil
            i = i + 1

        elseif c == '}' then
            depth = math.max(0, depth - 1)
            prevChar = nil
            i = i + 1

        else
            prevChar = (c == '.' or c == ':') and c or nil
            i = i + 1
        end
    end

    return diffs
end

return M
