-- Shared tokenizer for every scanner in this addon.
--
-- Each scanner used to carry its own copy of "skip comments, strings and long brackets", and
-- the copies disagreed in small ways: only hash-comments.lua knew that SupCom's `#` starts a
-- comment, so keywords inside `#` comment text (`do`, `end`, `function`) threw off every other
-- scanner's depth tracking. A quoted string ran to the next matching quote even across lines,
-- so one unterminated string while typing swallowed the rest of the file. Hex and exponent
-- numbers (`0xFF`, `1e5`) were read as identifiers. One tokenizer fixes all of that in one place.
--
-- Token types:
--   name        identifier that isn't a keyword
--   keyword     Lua keyword
--   number      numeric literal
--   string      quoted or long-bracket string (value = raw source, quotes included)
--   comment     `--` comment, short or long
--   hashcomment SupCom `#` comment: a `#` that is the first non-blank character on its line,
--               running to the end of the line. A `#` anywhere else is the length operator
--               (tooling scripts like wiki/Run.lua use `#arg`, which standard Lua runs).
--   op          operator or punctuation; multi-char operators are one token (`==`, `~=`, `!=`,
--               `<=`, `>=`, `..`, `...`, `<<`, `>>`, `//`, `::`)
--
-- Every token has `start`/`finish` (inclusive byte offsets into the source) and `line`
-- (1-based line of `start`).

local M = {}

local KEYWORDS = {
    ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true,
    ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['goto'] = true,
    ['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true,
    ['or'] = true, ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true,
    ['until'] = true, ['while'] = true,
}
M.KEYWORDS = KEYWORDS

local OPS3 = { ['...'] = true }
local OPS2 = {
    ['=='] = true, ['~='] = true, ['!='] = true, ['<='] = true, ['>='] = true, ['..'] = true,
    ['<<'] = true, ['>>'] = true, ['//'] = true, ['::'] = true,
}

---@class fa.token
---@field type   'name'|'keyword'|'number'|'string'|'comment'|'hashcomment'|'op'
---@field value  string
---@field start  integer
---@field finish integer
---@field line   integer

--- Position right after the long bracket opening at `i` (`[[`, `[=[`, ...) closes, or `n + 1`
--- if it never closes. Returns nil if `i` doesn't start a long bracket.
---@param text string
---@param i    integer
---@param n    integer
---@return integer?
local function skipLongBracket(text, i, n)
    local eqs = text:match('^%[(=*)%[', i)
    if not eqs then
        return nil
    end
    local _, closeEnd = text:find(']' .. eqs .. ']', i + 2 + #eqs, true)
    return closeEnd and (closeEnd + 1) or (n + 1)
end

--- Position right after the quoted string opening at `i`. Stops at an unescaped line break, so
--- an unterminated string only affects its own line.
---@param text string
---@param i    integer
---@param n    integer
---@return integer
local function skipQuoted(text, i, n)
    local quote = text:sub(i, i)
    local pattern = '[\\\n' .. quote .. ']'
    local j = i + 1
    while j <= n do
        local k = text:find(pattern, j)
        if not k then
            return n + 1
        end
        local c = text:sub(k, k)
        if c == '\\' then
            -- `\` escapes the next character, including a line break (Lua's line continuation)
            j = k + 2
        elseif c == '\n' then
            return k
        else
            return k + 1
        end
    end
    return n + 1
end

---@param text string
---@return fa.token[]
local function tokenize(text)
    local tokens = {}
    local n = #text
    local i = 1
    local line = 1
    -- Whether a token has already started on the current line - decides whether `#` is a
    -- comment (first thing on its line) or the length operator.
    local lineHasToken = false

    local function push(tokType, s, e)
        tokens[#tokens + 1] = {
            type   = tokType,
            value  = text:sub(s, e),
            start  = s,
            finish = e,
            line   = line,
        }
        lineHasToken = true
    end

    --- Advances `line` by the line breaks in text[s..e].
    local function countLines(s, e)
        local count = 0
        local p = s
        while true do
            local nl = text:find('\n', p, true)
            if not nl or nl > e then
                break
            end
            count = count + 1
            p = nl + 1
        end
        if count > 0 then
            line = line + count
            lineHasToken = false
        end
    end

    while i <= n do
        local c = text:sub(i, i)

        if c == '\n' then
            line = line + 1
            lineHasToken = false
            i = i + 1

        elseif c == ' ' or c == '\t' or c == '\r' or c == '\f' or c == '\v' then
            local _, e = text:find('^[ \t\r\f\v]+', i)
            i = e + 1

        elseif c == '-' and text:sub(i + 1, i + 1) == '-' then
            local e
            local close = skipLongBracket(text, i + 2, n)
            if close then
                e = close - 1
            else
                local nl = text:find('\n', i, true)
                e = nl and (nl - 1) or n
            end
            push('comment', i, e)
            countLines(i, e)
            i = e + 1

        elseif c == '#' and not lineHasToken then
            local nl = text:find('\n', i, true)
            local e = nl and (nl - 1) or n
            push('hashcomment', i, e)
            i = e + 1

        elseif c == '"' or c == "'" then
            local e = skipQuoted(text, i, n) - 1
            push('string', i, e)
            countLines(i, e)
            i = e + 1

        elseif c == '[' and text:find('^%[=*%[', i) then
            local e = skipLongBracket(text, i, n) - 1
            push('string', i, e)
            countLines(i, e)
            i = e + 1

        elseif c:find('^[%a_]') then
            local _, e = text:find('^[%w_]*', i + 1)
            local word = text:sub(i, e)
            push(KEYWORDS[word] and 'keyword' or 'name', i, e)
            i = e + 1

        elseif c:find('^%d') or (c == '.' and text:find('^%.%d', i)) then
            local _, e
            if text:find('^0[xX]', i) then
                _, e = text:find('^0[xX][%x%.]*', i)
                local _, pe = text:find('^[pP][%+%-]?%d+', e + 1)
                e = pe or e
            else
                _, e = text:find('^%d*%.?%d*', i)
                local _, ee = text:find('^[eE][%+%-]?%d+', e + 1)
                e = ee or e
            end
            push('number', i, e)
            i = e + 1

        else
            local three = text:sub(i, i + 2)
            local two = text:sub(i, i + 1)
            if OPS3[three] then
                push('op', i, i + 2)
                i = i + 3
            elseif OPS2[two] then
                push('op', i, i + 1)
                i = i + 2
            else
                push('op', i, i)
                i = i + 1
            end
        end
    end

    return tokens
end

-- Every scanner tokenizes the same text, so keep the last few results. Strings are compared by
-- value (interned), so a hit is a plain table lookup.
local CACHE_SIZE = 8
local cacheKeys, cacheValues = {}, {}

--- All tokens of `text`, comments included. Returns a shared array: don't modify it.
---@param text string
---@return fa.token[]
function M.tokenize(text)
    for idx = 1, #cacheKeys do
        if cacheKeys[idx] == text then
            return cacheValues[idx]
        end
    end
    local tokens = tokenize(text)
    table.insert(cacheKeys, 1, text)
    table.insert(cacheValues, 1, tokens)
    if #cacheKeys > CACHE_SIZE then
        cacheKeys[#cacheKeys] = nil
        cacheValues[#cacheValues] = nil
    end
    return tokens
end

---@type table<fa.token[], fa.token[]>
local codeCache = setmetatable({}, { __mode = 'k' })

--- Tokens of `text` without comments - what code-structure scanners walk. Returns a shared
--- array: don't modify it.
---@param text string
---@return fa.token[]
function M.codeTokens(text)
    local all = M.tokenize(text)
    local code = codeCache[all]
    if code then
        return code
    end
    code = {}
    for _, tok in ipairs(all) do
        if tok.type ~= 'comment' and tok.type ~= 'hashcomment' then
            code[#code + 1] = tok
        end
    end
    codeCache[all] = code
    return code
end

return M
