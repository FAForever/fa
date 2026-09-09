-- Makes FA's `Class()`-family OOP sugar readable as a real class to LuaLS, by stripping the
-- wrapper call down to a plain table and adding the `---@class` doc it implies.
--
-- FA classes are defined as `Name = ClassFn(Base1, Base2, ...) { specs }` (or the no-base
-- `Name = ClassFn { specs }` form), per lua/system/class.lua. Even though class.lua carries
-- `---@generic T / @param specs T / @return T` annotations aimed at propagating the spec
-- table's fields through the call, LuaLS's class-doc-to-declaration binding only reliably
-- merges fields from a table constructor assigned *directly* - not one arriving through an
-- opaque (if generically-annotated) function call. So we strip the `ClassFn(...)` wrapper
-- text entirely, leaving a plain `Name = { specs }`, and inject a `---@class Name: Bases`
-- doc comment when the file doesn't already have one for that name - both are things LuaLS
-- already handles natively and reliably once the call is out of the way. Blanking the wrapper
-- also erases the only reference to any bare-identifier base argument (`Class(NullShell) {}`),
-- which would otherwise make its `local NullShell = ...` declaration look unused - a harmless
-- `local _ = NullShell` keep-alive line is inserted alongside to prevent that (see the
-- comment at its call site for why `_` specifically, and why it reads `M.Name` instead of the
-- bare name when the base is one of the file's own exports). A base that's itself a local
-- import-alias with a different name than what it holds (`local Foo = Module.Bar`, then
-- `Class(Foo)`) gets resolved to `Bar` for the doc specifically - see buildReferenceMaps. A
-- NESTED class (one inside another class's own spec table, e.g. a state override) is named
-- `<enclosing top-level class>_<field name>` rather than the bare field name, matching FA's own
-- hand-written convention (`DefaultProjectileWeapon_IdleState`) - this both avoids every file's
-- undocumented same-named nested state (`IdleState`, `Start`, ...) merging into one shared
-- global type, and lets an `Owner.Field` base reference (`State(DefaultBeamWeapon.IdleState)`,
-- FA's own "override the parent's state" pattern) resolve to exactly that name - see
-- sanitizeBase/buildReferenceMaps.
--
-- Known limitations: only the `Name = ClassFn(...) { ... }` assignment shape is handled
-- (bare identifier target only, no dotted targets like `t.Name = ...`); an anonymous
-- `ClassFn(...) {}` with nothing assignable to its left is left untouched.

local M = {}

local CLASS_FUNCTIONS = {
    Class = true, ClassSimple = true, ClassUI = true, ClassShield = true,
    ClassProjectile = true, ClassDummyProjectile = true, ClassUnit = true,
    ClassDummyUnit = true, ClassWeapon = true, ClassTrashBag = true, State = true,
}

local BLOCK_OPEN  = { ['function'] = true, ['if'] = true, ['do'] = true, ['repeat'] = true }
local BLOCK_CLOSE = { ['end'] = true, ['until'] = true }
local LOOP_HEADER = { ['for'] = true, ['while'] = true }
local KEYWORDS = {
    ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true,
    ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['if'] = true,
    ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true,
    ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true, ['until'] = true,
    ['while'] = true,
}

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
---@param j integer  index to start skipping a string at (points at the closing quote's opener)
---@param n integer
---@param quote string
---@return integer  position right after the closing quote
local function skipString(text, j, n, quote)
    j = j + 1
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

--- Finds the bare identifier immediately assigned right before `pos` (i.e. `Name =` ending
--- right at `pos`, skipping whitespace, and rejecting `==`/`~=`/`<=`/`>=`).
---@param text string
---@param pos integer
---@return integer? nameStart
---@return string?  name
local function findPrecedingName(text, pos)
    local j = pos - 1
    while j >= 1 and text:sub(j, j):match('%s') do
        j = j - 1
    end
    if j < 1 or text:sub(j, j) ~= '=' then
        return nil
    end
    j = j - 1
    if j >= 1 and text:sub(j, j):match('[=~<>]') then
        return nil
    end
    while j >= 1 and text:sub(j, j):match('%s') do
        j = j - 1
    end
    local nameEnd = j
    while j >= 1 and text:sub(j, j):match('[%w_]') do
        j = j - 1
    end
    local nameStart = j + 1
    if nameStart > nameEnd or not text:sub(nameStart, nameStart):match('[%a_]') then
        return nil
    end
    return nameStart, text:sub(nameStart, nameEnd)
end

--- If `local` immediately precedes `nameStart` as a whole word (i.e. `local Name = ...`),
--- returns the position of that `local` instead - the TRUE start of the statement. Otherwise
--- returns `nameStart` unchanged. Needed because findPrecedingName only ever returns the bare
--- name's own position, never accounting for an optional `local` prefix - inserting a new
--- statement right at `nameStart` when `local` precedes it produces `local <inserted>Name = ...`,
--- i.e. a literal double `local` and a real syntax error (reproduced on
--- lua/maui/layouthelpers.lua's `local LayouterAttributeEditor = Class(LayouterAttributeFont)
--- {` - an internal, local-scoped helper class, not FA's usual bare-global export).
---@param text      string
---@param nameStart integer
---@return integer
local function findStatementStart(text, nameStart)
    local j = nameStart - 1
    while j >= 1 and text:sub(j, j):match('%s') do
        j = j - 1
    end
    if j >= 5 and text:sub(j - 4, j) == 'local' then
        local before = j - 5
        if before < 1 or not text:sub(before, before):match('[%w_]') then
            return j - 4
        end
    end
    return nameStart
end

--- Walks backward from `pos` through a contiguous run of `--` comment lines (stopping at a
--- blank line or real code - same walk as hasImmediatePrecedingClassDoc below), returning the
--- start position of the topmost comment line in that run, or `pos` itself if no such block
--- immediately precedes it. Lets a synthetic statement be inserted BEFORE any doc-comment block
--- (hand-written or injected) instead of between it and the statement it documents, which would
--- break a LuaDoc annotation's "immediately precedes" binding requirement - see the base-class
--- keep-alive in stripWrappers below for why that matters here.
---@param text string
---@param pos  integer
---@return integer
local function findCommentBlockStart(text, pos)
    local boundary = pos
    -- `pos` itself may be indented (any nested class field, e.g. `    RackSalvoChargeState =
    -- State {`) - `pos - 2` alone would land inside THAT indentation rather than the actual
    -- previous line, misreading it as blank. Find pos's own line start first (tolerating its
    -- indentation), then step back over the newline before it to reach the true previous line.
    local ownLineStart = text:sub(1, pos - 1):match('.*\n()') or 1
    local lineEnd = ownLineStart - 2
    while lineEnd >= 1 do
        local lineStart = text:sub(1, lineEnd):match('.*\n()') or 1
        local line = text:sub(lineStart, lineEnd)
        local trimmed = line:match('^%s*(.-)%s*$')
        if trimmed == '' then
            break
        elseif trimmed:match('^%-%-') then
            boundary = lineStart
            lineEnd = lineStart - 2
        else
            break
        end
    end
    return boundary
end

--- Checks whether a `---@class` line (any name) already sits in the contiguous block of
--- comment lines immediately above `pos` - i.e. whether *this* statement already has a class
--- doc, regardless of what name it uses. FA often names the doc differently than the
--- assigned variable on purpose (e.g. `---@class EasyAIBrain: ...` directly above
--- `AIBrain = Class(...) {...}`, specifically so multiple files' generic `AIBrain` locals
--- don't collide globally) - relying only on "does a doc named after the variable exist
--- anywhere in the file" misses that and injects a second, conflicting same-named class that
--- merges fields across every file that hits this pattern. Walks backward line by line: a
--- blank line or real code stops the scan (no doc found); a comment line that isn't
--- `---@class` keeps walking (covers `---@field`/description lines that sit between
--- `---@class` and the code, as in the real examples above).
---@param text string
---@param pos  integer
---@return boolean
local function hasImmediatePrecedingClassDoc(text, pos)
    -- Same indentation pitfall as findCommentBlockStart above: find pos's own line start first
    -- (tolerating its indentation), then step back over the newline before it to reach the true
    -- previous line, instead of assuming pos sits at column 1. Confirmed real:
    -- lua/sim/weapons/DefaultProjectileWeapon.lua's `    RackSalvoChargeState = State {` (an
    -- indented field, already hand-annotated with `---@class
    -- DefaultProjectileWeapon_RackSalvoChargeState : DefaultProjectileWeapon, State` directly
    -- above it) - assuming pos-2 landed on the doc line, when it actually landed inside
    -- RackSalvoChargeState's own leading indentation, misread as a blank line. That made this
    -- return false, so stripWrappers injected a second, competing, base-less `---@class
    -- RackSalvoChargeState` doc that (being textually closer) won the LuaDoc binding over the
    -- real one - losing the `: State` relationship entirely and breaking `ChangeState(self,
    -- self.RackSalvoChargeState)`'s type check ("Cannot assign RackSalvoChargeState to parameter
    -- State"). Top-level (unindented) statements were never affected - there, pos already sits
    -- at column 1, so ownLineStart below equals pos and this is a no-op.
    local ownLineStart = text:sub(1, pos - 1):match('.*\n()') or 1
    local lineEnd = ownLineStart - 2
    while lineEnd >= 1 do
        local lineStart = text:sub(1, lineEnd):match('.*\n()') or 1
        local line = text:sub(lineStart, lineEnd)
        local trimmed = line:match('^%s*(.-)%s*$')
        if trimmed == '' then
            return false
        elseif trimmed:match('^%-%-%-@class') then
            return true
        elseif trimmed:match('^%-%-') then
            lineEnd = lineStart - 2
        else
            return false
        end
    end
    return false
end

--- Splits a `(...)` argument-list body on top-level commas (paren/string aware).
---@param argsText string
---@return string[]
local function splitTopLevelArgs(argsText)
    local parts = {}
    local n = #argsText
    local depth = 0
    local start = 1
    local j = 1
    while j <= n do
        local c = argsText:sub(j, j)
        if c == '"' or c == "'" then
            j = skipString(argsText, j, n, c) - 1
        elseif c == '(' then
            depth = depth + 1
        elseif c == ')' then
            depth = depth - 1
        elseif c == ',' and depth == 0 then
            parts[#parts + 1] = argsText:sub(start, j - 1):match('^%s*(.-)%s*$')
            start = j + 1
        end
        j = j + 1
    end
    local last = argsText:sub(start):match('^%s*(.-)%s*$')
    if last ~= '' then
        parts[#parts + 1] = last
    end
    return parts
end

---@param s string
---@return boolean
local function isSimpleTypeName(s)
    if s == '' then
        return false
    end
    for segment in (s .. '.'):gmatch('([^.]*)%.') do
        if not segment:match('^[%a_][%w_]*$') then
            return false
        end
    end
    return true
end

--- Returns the identifier before the first `.` in a dotted chain (or the whole string, if
--- there's no dot) - e.g. `"Shield.OnState"` -> `"Shield"`. Used to decide whether a base's
--- keep-alive (see stripWrappers below) needs an `M.` prefix: only the base's own OUTERMOST
--- name can possibly be one of this file's own exports.
---@param s string
---@return string
local function firstSegment(s)
    local dot = s:find('.', 1, true)
    if dot then
        return s:sub(1, dot - 1)
    end
    return s
end

--- One pass, extending the original alias-only scan, collecting THREE maps used to resolve a
--- Class()/State() base argument (see sanitizeBase below):
---
--- `aliasMap`: TOP-LEVEL `local Alias = RHS` declarations where RHS is either `import(...).Name`
--- or a bare dotted-identifier chain not immediately followed by `(` (a real reference, not a
--- function call), resolved to a canonical name that differs from Alias's own - i.e. cases where
--- FA renamed an import at the point of use. Depth-tracked (block keywords + braces, same shape
--- as export-env.lua's own scan) so nested function-body locals - which commonly look like
--- `local brain = self` or `local bp = unit.Enhancements` and have nothing to do with file-level
--- import aliasing - are never mistaken for one; Lua keywords (`local dialog = false`) are
--- excluded from being treated as a type name either as the alias or the resolved name.
--- Confirmed real on units/XSL0001/XSL0001_script.lua, where `local
--- SDFChronotronOverChargeCannonWeapon = SWeapons.SDFChronotronCannonOverChargeWeapon` is later
--- used as a Class() base by its own (differently-spelled) name - the real, registered type is
--- `SDFChronotronCannonOverChargeWeapon` (confirmed: lua/seraphimweapons.lua's own export uses
--- that exact spelling), so injecting the local's own name into the doc produces "Undefined
--- class".
---
--- `moduleImports`: names bound via `local X = import(path)` with NO trailing `.Name` - a WHOLE
--- MODULE table (e.g. `local SWeapon = import("/lua/seraphimweapons.lua")`). Distinguishes a
--- module-table reference (`X.Field` means "the module's own top-level export Field") from a
--- class reference below.
---
--- `classOwners`: names bound via `local X = import(path).Name` (a SINGLE class import, e.g.
--- `local DefaultProjectileWeapon = import(...).DefaultProjectileWeapon`) OR a bare top-level
--- `X = ClassFn(...) { ... }` defined in this same file (a self-reference, e.g. `Shield =
--- ClassShield(...) { ... OnState = State(Shield.OnState) {...} ... }` in lua/shield.lua,
--- confirmed real). For these, `X.Field` means "X's own nested Field state" - see sanitizeBase.
---@param text string
---@return table<string, string>  aliasMap
---@return table<string, boolean> moduleImports
---@return table<string, boolean> classOwners
local function buildReferenceMaps(text)
    local n = #text
    local i = 1
    local depth = 0
    local loopHeaderDepth = 0
    local aliasMap = {}
    local moduleImports = {}
    local classOwners = {}
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
            i = skipString(text, i, n, c)
        elseif c == '[' then
            i = skipLongBracket(text, i, n) or (i + 1)
        elseif c:match('[%a_]') then
            local wordStart = i
            local _, e, word = text:find('^([%a_][%w_]*)', i)
            i = e + 1

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
            elseif word == 'local' and depth == 0 and loopHeaderDepth == 0 then
                local _, _, aliasName = text:find('^%s*([%a_][%w_]*)%s*=%s*', i)
                if aliasName then
                    local _, afterEqEnd = text:find('^%s*[%a_][%w_]*%s*=%s*', i)
                    local afterEq = afterEqEnd + 1
                    local canonical = nil
                    if text:match('^import%s*%b()', afterEq) then
                        local importName = text:match('^import%s*%b()%.([%a_][%w_]*)', afterEq)
                        if importName then
                            canonical = importName
                            classOwners[aliasName] = true
                        else
                            moduleImports[aliasName] = true
                        end
                    else
                        local rhs = text:match('^[%a_][%w_%.]*', afterEq)
                        if rhs and isSimpleTypeName(rhs) and not KEYWORDS[firstSegment(rhs)] then
                            local rhsEnd = afterEq + #rhs
                            local _, afterSpaceEnd = text:find('^%s*', rhsEnd)
                            local afterSpace = afterSpaceEnd + 1
                            if text:sub(afterSpace, afterSpace) ~= '(' then
                                canonical = rhs:match('([%a_][%w_]*)$')
                            end
                        end
                    end
                    if canonical and KEYWORDS[canonical] then
                        canonical = nil
                    end
                    if canonical and canonical ~= aliasName then
                        aliasMap[aliasName] = canonical
                    end
                end
            elseif CLASS_FUNCTIONS[word] and depth == 0 and loopHeaderDepth == 0 then
                -- A bare top-level `X = ClassFn(...) { ... }` in THIS file self-defines a class
                -- owner - same word/preceding-name checks stripWrappers itself uses below.
                local j = wordStart - 1
                while j >= 1 and text:sub(j, j):match('%s') do
                    j = j - 1
                end
                local prevChar = j >= 1 and text:sub(j, j) or nil
                if prevChar ~= '.' and prevChar ~= ':' then
                    local _, className = findPrecedingName(text, wordStart)
                    if className then
                        classOwners[className] = true
                    end
                end
            end
        elseif c == '{' then
            depth = depth + 1
            i = i + 1
        elseif c == '}' then
            depth = math.max(0, depth - 1)
            i = i + 1
        else
            i = i + 1
        end
    end
    return aliasMap, moduleImports, classOwners
end

--- Classifies a raw `Class(...)` base-argument's source text into something usable in a
--- `---@class X: Base` doc. Only a bare type-name (dotted-identifier chain, e.g.
--- `moho.unit_methods`) is a valid LuaLS type reference; anything else - a call, indexing on a
--- call result, etc. - isn't, and dropping the raw text in verbatim (e.g.
--- `import("/lua/sim/prop.lua").Prop`) produces a malformed reference LuaLS reports as an
--- undefined class (confirmed: env/*/Props/*/*_script.lua's recurring `Class(import(path).Name)`
--- pattern). That specific shape is common enough to special-case: extract just `Name` and use
--- that - correct whenever the target file kept its default, unrenamed class name, which fails
--- safe even when wrong (a missing inherited-member completion, not a new diagnostic). Anything
--- else unrecognised is dropped rather than guessed at.
---
--- `aliasMap` (from buildReferenceMaps) is checked first: if `baseText` is itself a local alias
--- for something with a different canonical name, that canonical name is used instead - see
--- buildReferenceMaps' own comment for the real example this fixes.
---
--- Otherwise, if `baseText` is a dotted `Owner.Field` chain, `moduleImports`/`classOwners` (also
--- from buildReferenceMaps) decide what it means: a module-table export access
--- (`SWeapon.SDFShriekerCannon` -> `SDFShriekerCannon`, dropping the module prefix - same
--- resolution as the `import(...).Name` handling below, just via a pre-bound local instead of an
--- inline call) or a nested state/class override (`DefaultBeamWeapon.IdleState` ->
--- `DefaultBeamWeapon_IdleState`, dots replaced with underscores - matching the SAME
--- owner-qualified naming stripWrappers below now uses for its own auto-generated nested-class
--- docs, so a reference from another file resolves to exactly what the owner's own file
--- produces, with no need to read that file). Confirmed real: lua/sim/weapons/cybran/
--- CAMZapperWeapon.lua's `State(DefaultBeamWeapon.IdleState)` and lua/shield.lua's
--- self-referential `State(Shield.OnState)` (Shield.lua's own `Shield = ClassShield(...) {...}`
--- makes `Shield` a classOwner of itself). Neither map matching (e.g. `moho.unit_methods`, a
--- genuine namespaced engine type, never a local import) falls through to the dotted text
--- unchanged, same as before this resolution existed.
---@param baseText string
---@param aliasMap table<string, string>
---@param moduleImports table<string, boolean>
---@param classOwners table<string, boolean>
---@return string?
local function sanitizeBase(baseText, aliasMap, moduleImports, classOwners)
    if aliasMap[baseText] then
        return aliasMap[baseText]
    end
    if isSimpleTypeName(baseText) then
        local owner = firstSegment(baseText)
        if owner ~= baseText then
            if moduleImports[owner] then
                return baseText:match('([%a_][%w_]*)$')
            elseif classOwners[owner] then
                return (baseText:gsub('%.', '_'))
            end
        end
        return baseText
    end
    return baseText:match('^import%s*%b()%.([%a_][%w_]*)$')
end

--- `safeNames` is the set of this file's own bare top-level exports that export-env.lua will
--- rewrite *every* occurrence of (definition included) to `M.Name` - see the base-class
--- keep-alive below for why stripWrappers needs to know this. Pass an empty table (or omit) for
--- text that never goes through export-env's rewrite at all (e.g. a hook file's stitched
--- target - see plugin.lua's OnSetText).
---@param text       string
---@param safeNames? table<string, boolean>
---@return fa.diff[]
function M.stripWrappers(text, safeNames)
    safeNames = safeNames or {}
    local n = #text
    local i = 1
    local diffs = {}
    local lastWord = nil
    local prevChar = nil
    -- Counts ONLY '{'/'}' - tells us whether we're inside some table constructor's field list,
    -- where a synthetic *statement* (the base-class keep-alive below) can never legally go, vs
    -- a real statement context (top level, or inside a function/if/for/while/do body - all of
    -- which allow statements). The blanking/doc-injection logic below stays depth-independent
    -- on purpose (already correct for nested classes, e.g. a class nested in another's spec
    -- table); only the keep-alive needs this.
    local braceDepth = 0
    -- Stack of top-level (braceDepth 0) class names currently "open" - only ever has 0 or 1
    -- entries (a new top-level class only starts once the previous one has fully closed back to
    -- braceDepth 0), used to owner-qualify any NESTED class doc this scan auto-generates. See
    -- the docClassName computation below.
    local topLevelStack = {}

    local existingClassDocs = {}
    for name in text:gmatch('%-%-%-@class%s+([%a_][%w_%.]*)') do
        existingClassDocs[name] = true
    end
    local aliasMap, moduleImports, classOwners = buildReferenceMaps(text)

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
            lastWord = nil
            prevChar = nil

        elseif c == '"' or c == "'" then
            i = skipString(text, i, n, c)
            prevChar = c
            lastWord = nil

        elseif c == '[' then
            i = skipLongBracket(text, i, n) or (i + 1)
            prevChar = ']'
            lastWord = nil

        elseif c:match('%s') then
            i = i + 1

        elseif c:match('[%a_]') then
            local wordStart = i
            local _, e, word = text:find('^([%a_][%w_]*)', i)
            i = e + 1

            if CLASS_FUNCTIONS[word] and prevChar ~= '.' and prevChar ~= ':' and lastWord ~= 'function' then
                local k = i
                local _, we1 = text:find('^%s*', k)
                k = we1 + 1

                local bases = nil
                local rawBases = nil
                if text:sub(k, k) == '(' then
                    local depth = 0
                    local j = k
                    while j <= n do
                        local cj = text:sub(j, j)
                        if cj == '"' or cj == "'" then
                            j = skipString(text, j, n, cj) - 1
                        elseif cj == '(' then
                            depth = depth + 1
                        elseif cj == ')' then
                            depth = depth - 1
                            if depth == 0 then
                                break
                            end
                        end
                        j = j + 1
                    end
                    if j <= n then
                        rawBases = splitTopLevelArgs(text:sub(k + 1, j - 1))
                        bases = {}
                        for _, raw in ipairs(rawBases) do
                            local sanitized = sanitizeBase(raw, aliasMap, moduleImports, classOwners)
                            if sanitized then
                                bases[#bases + 1] = sanitized
                            end
                        end
                        k = j + 1
                        local _, we2 = text:find('^%s*', k)
                        k = we2 + 1
                    else
                        k = nil -- unbalanced parens, bail on this occurrence
                    end
                end

                if k and text:sub(k, k) == '{' then
                    diffs[#diffs + 1] = {
                        start  = wordStart,
                        finish = k - 1,
                        text   = (' '):rep(k - wordStart),
                    }

                    local nameStart, className = findPrecedingName(text, wordStart)
                    -- The TRUE start of the statement - accounts for an optional `local` prefix
                    -- (`local Name = ClassFn(...)`, e.g. lua/maui/layouthelpers.lua's internal
                    -- helper classes) that `nameStart` alone doesn't. Both insertions below use
                    -- this, not `nameStart` directly, to avoid landing between `local` and the
                    -- name it declares.
                    local statementStart = nameStart and findStatementStart(text, nameStart)

                    -- Blanking `ClassFn(Bases...)` above erases the only reference to a
                    -- bare-identifier base like `NullShell` from LuaLS's view - if it came from
                    -- a `local NullShell = ...` declaration, that local now looks unused
                    -- (confirmed real: effects/**/*_script.lua files routinely do
                    -- `local NullShell = import(...).NullShell` then `Class(NullShell) {...}` -
                    -- and it's common: 324/600 files in a random fa-repo sample hit this). A
                    -- harmless `local _ = NullShell` right before the class statement "reads" it
                    -- again - `_` is itself exempt from the unused-local check
                    -- (script/core/diagnostics/unused-local.lua checks `name == '_'` and skips),
                    -- so this satisfies the original local without ever tripping its own
                    -- warning. Inserted at the *top* of any immediately-preceding comment block
                    -- (findCommentBlockStart), not at statementStart directly - otherwise it
                    -- would land between an existing hand-written `---@class` doc and the class
                    -- statement it documents, breaking that doc's binding.
                    --
                    -- If the base's own outermost name is one of THIS file's exports (`safeNames`),
                    -- export-env.lua rewrites *every* occurrence of it - including its own
                    -- definition - to `M.Name`, so the bare name never exists anywhere in the
                    -- transformed output; the keep-alive has to read `M.Name` instead, or it
                    -- becomes an undefined-global itself (confirmed real:
                    -- lua/terranprojectiles.lua's `TDFGaussCannonProjectile = ClassProjectile(
                    -- TDFGeneralGaussCannonProjectile) {...}`, where the base is this same
                    -- file's own earlier-defined class). An imported/non-exported local (like
                    -- `NullShell` above) isn't in `safeNames` and keeps the bare reference.
                    --
                    -- Only at braceDepth 0: `OnState = State(Shield.OnState) {...}` nested as a
                    -- FIELD inside an outer class's own table constructor (a self-referential
                    -- state-override pattern, confirmed real: lua/shield.lua:1135) has no legal
                    -- place for a synthetic *statement* - a table constructor's field list only
                    -- accepts `[expr]=v`/`name=v`/`v` entries, never a `local` statement.
                    -- Reproduced: inserting one there produced "<keyword> cannot be used as
                    -- name" (the parser hitting `local` where a field name was expected). Nested
                    -- bases also don't need the keep-alive in the first place - they're
                    -- typically dotted references into the very class being defined
                    -- (`Shield.OnState`), not a separate local at risk of going unused.
                    if statementStart and rawBases and braceDepth == 0 then
                        local keepAlive = {}
                        for _, raw in ipairs(rawBases) do
                            if isSimpleTypeName(raw) then
                                if safeNames[firstSegment(raw)] then
                                    keepAlive[#keepAlive + 1] = 'local _ = M.' .. raw
                                else
                                    keepAlive[#keepAlive + 1] = 'local _ = ' .. raw
                                end
                            end
                        end
                        if #keepAlive > 0 then
                            local insertAt = findCommentBlockStart(text, statementStart)
                            diffs[#diffs + 1] = {
                                start  = insertAt,
                                finish = insertAt - 1,
                                text   = table.concat(keepAlive, '; ') .. '\n',
                            }
                        end
                    end

                    -- A NESTED class (braceDepth > 0, e.g. `IdleState = State {...}` inside
                    -- `DefaultBeamWeapon`'s own spec table) gets its auto-generated doc name
                    -- qualified with the innermost currently-open TOP-LEVEL class's own name -
                    -- `DefaultBeamWeapon_IdleState`, not bare `IdleState` - matching FA's own
                    -- hand-written convention for nested state overrides (e.g.
                    -- `DefaultProjectileWeapon_IdleState`). Without this, every file's
                    -- undocumented nested `IdleState`/`Start`/`Error`/etc. shares the exact same
                    -- bare global name, and LuaLS merges same-named classes workspace-wide (the
                    -- very `AIBrain`/`EasyAIBrain` collision hasImmediatePrecedingClassDoc's own
                    -- comment above already warns about) - silently smearing dozens of unrelated
                    -- files' same-named nested states into one shared type. It also makes an
                    -- `Owner.Field` base reference (see sanitizeBase) resolvable at all: nothing
                    -- was ever registered under that dotted name before this. Top-level
                    -- (braceDepth 0) classes are unaffected (docClassName == className).
                    local docClassName = className
                    if braceDepth > 0 and #topLevelStack > 0 and className then
                        docClassName = topLevelStack[#topLevelStack] .. '_' .. className
                    end

                    if docClassName
                    and statementStart
                    and not existingClassDocs[docClassName]
                    and not hasImmediatePrecedingClassDoc(text, statementStart) then
                        local doc
                        if bases and #bases > 0 then
                            doc = '---@class ' .. docClassName .. ': ' .. table.concat(bases, ', ') .. '\n'
                        else
                            doc = '---@class ' .. docClassName .. '\n'
                        end
                        diffs[#diffs + 1] = {
                            start  = statementStart,
                            finish = statementStart - 1,
                            text   = doc,
                        }
                        existingClassDocs[docClassName] = true
                    end

                    if braceDepth == 0 and className then
                        topLevelStack[#topLevelStack + 1] = className
                    end
                end
            end

            lastWord = word
            prevChar = nil

        elseif c == '{' then
            braceDepth = braceDepth + 1
            prevChar = nil
            lastWord = nil
            i = i + 1

        elseif c == '}' then
            braceDepth = math.max(0, braceDepth - 1)
            if braceDepth == 0 and #topLevelStack > 0 then
                topLevelStack[#topLevelStack] = nil
            end
            prevChar = nil
            lastWord = nil
            i = i + 1

        else
            prevChar = (c == '.' or c == ':') and c or nil
            lastWord = nil
            i = i + 1
        end
    end

    return diffs
end

return M
