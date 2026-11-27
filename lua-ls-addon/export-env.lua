-- Makes FA's implicit module system visible to LuaLS by rewriting each file into a real Lua
-- module.
--
-- At runtime, `import()` (lua/system/import.lua) runs a file with a fresh table as its
-- environment (`__index = _G`), so every assignment to a name that isn't a local - at the top
-- level, inside an `if`/`do`/`for` block, or inside a function body - writes into that module
-- table, and `import()` returns it. FA files never `return {...}`; their free assignments ARE
-- their exports. LuaLS knows nothing about per-file environments (no annotation can express
-- one), so it would treat all of those names as workspace-wide globals.
--
-- The rewrite: `local M = {}` at the top, every free occurrence of an exported name becomes
-- `M.Name` (definitions and references alike), and `return M` at the end. `M.Name` field
-- resolution, unlike a bare local, isn't restricted to "last assignment before this position":
-- LuaLS merges every `M.Name = ...` in the file, so forward references and mutual recursion
-- resolve, including from inside an earlier-defined function. Table fields also don't count
-- toward Lua 5.1's 200-locals-per-chunk limit.
--
-- "Free" is decided by real scope tracking over lexer.lua's tokens: a frame stack of
-- function / block / if / loop / repeat scopes (holding their locals, parameters and loop
-- variables) plus table-constructor and paren frames. A name is free when it isn't a field
-- (`x.Name`, `x:Name`), isn't a table-constructor key (`{ Name = ... }`), and no enclosing scope
-- declares it at that point. `local a = <expr>` only takes effect once its statement ends, so
-- `local Foo = Foo` still reads the outer `Foo`. Exports are the free names assigned anywhere in
-- the file (`Name = ...`, `a, Name = ...`, `function Name(...)`), and only free occurrences get
-- rewritten - a parameter or local that shadows an export inside its own scope is left alone.
--
-- Files that run in the global environment opt out with `---@declare-global` (or `---@meta`):
-- their names are real globals. So does a file that already ends in its own top-level `return`.
--
-- Known limitations (a token scanner, not a full parser):
--   - `until <expr>` is scanned in the enclosing scope, not the repeat body's.
--   - A hook file appended to its target can see the target's top-level locals at runtime;
--     each text is analysed on its own, so that isn't modelled.

local lexer = require 'lexer'

local M = {}

--- Files marked `---@declare-global` (or `---@meta`) declare real globals, not module exports -
--- e.g. engine API stubs and the files globalInit.lua `doscript`s into _G.
---@param text string
---@return boolean
local function optsOut(text)
    return text:find('%-%-%-@declare%-global') ~= nil
        or text:find('%-%-%-@meta') ~= nil
end

-- Keywords that start a statement.
local STATEMENT_KEYWORDS = {
    ['local'] = true, ['if'] = true, ['for'] = true, ['while'] = true, ['do'] = true,
    ['repeat'] = true, ['return'] = true, ['break'] = true, ['end'] = true, ['else'] = true,
    ['elseif'] = true, ['until'] = true, ['goto'] = true,
}

--- Whether `tok` can be the last token of an expression - two expressions in a row (`a b`)
--- means a new statement started.
---@param tok fa.token?
---@return boolean
local function endsExpression(tok)
    if not tok then
        return false
    end
    if tok.type == 'name' or tok.type == 'number' or tok.type == 'string' then
        return true
    end
    if tok.type == 'keyword' then
        return tok.value == 'end' or tok.value == 'true' or tok.value == 'false' or tok.value == 'nil'
    end
    if tok.type == 'op' then
        return tok.value == ')' or tok.value == ']' or tok.value == '}' or tok.value == '...'
    end
    return false
end

--- Whether tokens[i] starts a new statement.
---@param tokens fa.token[]
---@param i integer
---@return boolean
local function isStatementStart(tokens, i)
    local tok = tokens[i]
    if tok.type == 'op' then
        return tok.value == ';' or tok.value == '::'
    end
    if tok.type == 'keyword' then
        if STATEMENT_KEYWORDS[tok.value] then
            return true
        end
        return tok.value == 'function' and endsExpression(tokens[i - 1])
    end
    if tok.type == 'name' then
        return endsExpression(tokens[i - 1])
    end
    return false
end

--- From the token right after a name, checks for `(, <name>(.<name>)*)* =` - whether that name
--- is one target of a multiple assignment (`a, b.c, Name = ...`).
---@param tokens fa.token[]
---@param j integer
---@return boolean
local function isNameListThenEquals(tokens, j)
    while tokens[j] and tokens[j].value == ',' do
        j = j + 1
        if not (tokens[j] and tokens[j].type == 'name') then
            return false
        end
        j = j + 1
        while tokens[j] and tokens[j].value == '.' and tokens[j + 1] and tokens[j + 1].type == 'name' do
            j = j + 2
        end
    end
    return tokens[j] ~= nil and tokens[j].type == 'op' and tokens[j].value == '='
end

---@class fa.nameUse
---@field name   string
---@field start  integer
---@field assign boolean  whether this occurrence assigns the name

---@class fa.exportAnalysis
---@field optOut       boolean  `---@declare-global`/`---@meta` file
---@field exports      string[] free names assigned somewhere in the file, in order of first assignment
---@field hasTopReturn boolean  the file already ends with its own top-level `return`
---@field usesM        boolean  `M` appears as a bare name, so the module table needs another name
---@field uses         fa.nameUse[] every free name occurrence

---@class fa.frame
---@field kind      'function'|'block'|'if'|'loop'|'repeat'|'table'|'paren'
---@field scope?    table<string, boolean>  locals declared in this frame (nil: not a scope yet)
---@field loopVars? string[]  `for` variables, declared once the body (`do`) starts
---@field body?     boolean   loop frame whose `do` has been seen

---@param text string
---@return fa.exportAnalysis
local function analyze(text)
    ---@type fa.exportAnalysis
    local result = { optOut = false, exports = {}, hasTopReturn = false, usesM = false, uses = {} }
    if optsOut(text) then
        result.optOut = true
        return result
    end

    local tokens = lexer.codeTokens(text)
    local topScope = {}
    ---@type fa.frame[]
    local frames = {}
    -- `local a, b = <expr>`: names waiting for their statement to end before they're in scope
    local pending
    local exportSet = {}

    local function currentScope()
        for k = #frames, 1, -1 do
            if frames[k].scope then
                return frames[k].scope
            end
        end
        return topScope
    end

    local function isDeclared(name)
        for k = #frames, 1, -1 do
            local scope = frames[k].scope
            if scope and scope[name] then
                return true
            end
        end
        return topScope[name] == true
    end

    local function activatePending()
        if pending then
            for _, name in ipairs(pending.names) do
                pending.scope[name] = true
            end
            pending = nil
        end
    end

    --- Pops frames down to and including the innermost one of a kind in `kinds`, as long as
    --- only frames of a kind in `through` lie above it. Recovers from unbalanced code mid-edit.
    local function popTo(kinds, through)
        for k = #frames, 1, -1 do
            local kind = frames[k].kind
            if kinds[kind] then
                for _ = #frames, k, -1 do
                    frames[#frames] = nil
                end
                return
            end
            if not through[kind] then
                return
            end
        end
    end

    local SCOPE_KINDS = { ['function'] = true, block = true, ['if'] = true, loop = true, ['repeat'] = true }
    local BRACKET_KINDS = { table = true, paren = true }
    local TABLE_ONLY = { table = true }
    local PAREN_ONLY = { paren = true }
    local REPEAT_ONLY = { ['repeat'] = true }

    local function use(name, start, assign)
        result.uses[#result.uses + 1] = { name = name, start = start, assign = assign }
        if assign and not exportSet[name] then
            exportSet[name] = true
            result.exports[#result.exports + 1] = name
        end
    end

    --- Declares the parameters of the function frame just pushed, given the index of its `(`.
    --- Returns the index after the closing `)`.
    ---@param j integer
    ---@return integer
    local function parseParams(j)
        if not (tokens[j] and tokens[j].value == '(') then
            return j
        end
        local scope = frames[#frames].scope
        j = j + 1
        while tokens[j] and tokens[j].value ~= ')' do
            if tokens[j].type == 'name' then
                scope[tokens[j].value] = true
            end
            j = j + 1
        end
        return j + 1
    end

    --- Collects `<name> (, <name>)*` starting at j. Returns the names and the index after them.
    ---@param j integer
    ---@return string[]
    ---@return integer
    local function parseNameList(j)
        local names = {}
        while tokens[j] and tokens[j].type == 'name' do
            names[#names + 1] = tokens[j].value
            if tokens[j].value == 'M' then
                result.usesM = true
            end
            j = j + 1
            if tokens[j] and tokens[j].value == ',' and tokens[j + 1] and tokens[j + 1].type == 'name' then
                j = j + 1
            else
                break
            end
        end
        return names, j
    end

    local i = 1
    local n = #tokens
    while i <= n do
        local tok = tokens[i]
        local nextI = i + 1

        if pending and #frames == pending.depth and i >= pending.from and isStatementStart(tokens, i) then
            activatePending()
        end

        if tok.type == 'keyword' then
            local kw = tok.value
            if kw == 'local' then
                local fnTok, nameTok = tokens[i + 1], tokens[i + 2]
                if fnTok and fnTok.value == 'function' and nameTok and nameTok.type == 'name' then
                    -- `local function Name` - in scope immediately, so it can call itself
                    currentScope()[nameTok.value] = true
                    if nameTok.value == 'M' then
                        result.usesM = true
                    end
                    frames[#frames + 1] = { kind = 'function', scope = {} }
                    nextI = parseParams(i + 3)
                else
                    local names, j = parseNameList(i + 1)
                    if tokens[j] and tokens[j].value == '=' then
                        activatePending()
                        pending = { names = names, scope = currentScope(), depth = #frames, from = j + 1 }
                        nextI = j + 1
                    else
                        local scope = currentScope()
                        for _, name in ipairs(names) do
                            scope[name] = true
                        end
                        nextI = j
                    end
                end

            elseif kw == 'function' then
                local j = i + 1
                local isMethod = false
                local nameTok = tokens[j]
                if nameTok and nameTok.type == 'name' then
                    -- `function Name.a.b:c(...)` - `Name` is a reference in the enclosing scope
                    j = j + 1
                    local dotted = false
                    while tokens[j] and (tokens[j].value == '.' or tokens[j].value == ':')
                      and tokens[j + 1] and tokens[j + 1].type == 'name' do
                        dotted = true
                        if tokens[j].value == ':' then
                            isMethod = true
                        end
                        j = j + 2
                    end
                    if nameTok.value == 'M' then
                        result.usesM = true
                    end
                    if not isDeclared(nameTok.value) then
                        use(nameTok.value, nameTok.start, not dotted)
                    end
                end
                local scope = {}
                if isMethod then
                    scope.self = true
                end
                frames[#frames + 1] = { kind = 'function', scope = scope }
                nextI = parseParams(j)

            elseif kw == 'do' then
                local top = frames[#frames]
                if top and top.kind == 'loop' and not top.body then
                    top.body = true
                    for _, name in ipairs(top.loopVars) do
                        top.scope[name] = true
                    end
                else
                    frames[#frames + 1] = { kind = 'block', scope = {} }
                end

            elseif kw == 'for' then
                -- loop variables are only visible inside the body, not in the header expressions
                local loopVars, j = parseNameList(i + 1)
                frames[#frames + 1] = { kind = 'loop', scope = {}, loopVars = loopVars }
                nextI = j

            elseif kw == 'while' then
                frames[#frames + 1] = { kind = 'loop', scope = {}, loopVars = {} }

            elseif kw == 'if' then
                frames[#frames + 1] = { kind = 'if' }

            elseif kw == 'then' or kw == 'else' then
                local top = frames[#frames]
                if top and top.kind == 'if' then
                    top.scope = {}
                end

            elseif kw == 'elseif' then
                local top = frames[#frames]
                if top and top.kind == 'if' then
                    top.scope = nil
                end

            elseif kw == 'repeat' then
                frames[#frames + 1] = { kind = 'repeat', scope = {} }

            elseif kw == 'until' then
                popTo(REPEAT_ONLY, BRACKET_KINDS)

            elseif kw == 'end' then
                popTo(SCOPE_KINDS, BRACKET_KINDS)
                if pending and #frames < pending.depth then
                    activatePending()
                end

            elseif kw == 'return' then
                if #frames == 0 then
                    result.hasTopReturn = true
                end
            end

        elseif tok.type == 'op' then
            local v = tok.value
            if v == '{' then
                frames[#frames + 1] = { kind = 'table' }
            elseif v == '(' or v == '[' then
                frames[#frames + 1] = { kind = 'paren' }
            elseif v == '}' then
                popTo(TABLE_ONLY, PAREN_ONLY)
            elseif v == ')' or v == ']' then
                popTo(PAREN_ONLY, {})
            end

        elseif tok.type == 'name' then
            local prev = tokens[i - 1]
            local nextTok = tokens[i + 1]
            local top = frames[#frames]
            local isField = prev and prev.type == 'op' and (prev.value == '.' or prev.value == ':')
            local isKey = top and top.kind == 'table' and nextTok and nextTok.value == '='
            if not isField and not isKey then
                if tok.value == 'M' then
                    result.usesM = true
                end
                if not isDeclared(tok.value) then
                    local inStatement = not (top and BRACKET_KINDS[top.kind])
                    local assign = inStatement and nextTok ~= nil
                        and (nextTok.value == '=' or (nextTok.value == ',' and isNameListThenEquals(tokens, i + 1)))
                    use(tok.value, tok.start, assign == true)
                end
            end
        end

        i = nextI
    end

    return result
end

-- Small cache: plugin.lua analyses the same text more than once per OnSetText.
local CACHE_SIZE = 8
local cacheKeys, cacheValues = {}, {}

--- Scope analysis of `text` (cached).
---@param text string
---@return fa.exportAnalysis
function M.analyze(text)
    for idx = 1, #cacheKeys do
        if cacheKeys[idx] == text then
            return cacheValues[idx]
        end
    end
    local result = analyze(text)
    table.insert(cacheKeys, 1, text)
    table.insert(cacheValues, 1, result)
    if #cacheKeys > CACHE_SIZE then
        cacheKeys[#cacheKeys] = nil
        cacheValues[#cacheValues] = nil
    end
    return result
end

--- Prefixes every free occurrence of a name in `exportSet` with `<moduleName>.`.
---@param text       string
---@param exportSet  table<string, boolean>
---@param moduleName string
---@return fa.diff[] diffs
---@return table<integer, boolean> rewritten  start offsets of the rewritten names
function M.rewriteReferences(text, exportSet, moduleName)
    local diffs = {}
    local rewritten = {}
    local analysis = M.analyze(text)
    if analysis.optOut then
        return diffs, rewritten
    end
    local prefix = moduleName .. '.'
    for _, nameUse in ipairs(analysis.uses) do
        if exportSet[nameUse.name] then
            diffs[#diffs + 1] = { start = nameUse.start, finish = nameUse.start - 1, text = prefix }
            rewritten[nameUse.start] = true
        end
    end
    return diffs, rewritten
end

return M
