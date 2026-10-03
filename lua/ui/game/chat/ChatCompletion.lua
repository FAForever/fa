
local CommandRegistry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")

-------------------------------------------------------------------------------
-- Pure tab-completion for the chat edit box.
--
--   Compute(text, caret)  →  UIChatCompletion | nil
--
-- The caller owns the cycle state. Positions are 0-indexed codepoint
-- offsets so they line up with Edit:GetCaretPosition / SetCaretPosition
-- and stay stable across UTF-8 input.

--- One Tab-cycle's state: candidates plus where in the source they replace; caller owns the cycle position.
---@class UIChatCompletion
---@field Anchor     number    # codepoint offset (0-indexed) where the replaced word begins
---@field Consume    number    # codepoint count of the original word consumed from `Anchor`
---@field Prefix     string    # original text between Anchor and the caret (for diagnostics)
---@field Candidates string[]  # replacement strings in cycle order
---@field Index      number    # 1-based index of the currently applied candidate
---@field Suffix     string    # text appended after the candidate (' ' when unambiguous)

--- Codepoint of the last space at or before `caret`, or 0 if none.
---@param text  string
---@param caret number
---@return number
local function LastSpaceBefore(text, caret)
    local i = caret
    while i > 0 do
        if STR_Utf8SubString(text, i, 1) == ' ' then
            return i
        end
        i = i - 1
    end
    return 0
end

--- Codepoint position of the next space at or after `caret + 1`, or
--- `textLen` if the word runs to end of text.
---@param text    string
---@param caret   number
---@param textLen number
---@return number
local function NextSpaceAfter(text, caret, textLen)
    local i = caret
    while i < textLen do
        if STR_Utf8SubString(text, i + 1, 1) == ' ' then
            return i
        end
        i = i + 1
    end
    return textLen
end

--- Non-civilian nicknames from the armies table, minus the local player.
---@return string[]
local function CollectNicknames()
    -- `focusArmy` is 0 for observers, making the comparison a no-op.
    -- That is fine, observers have no nickname to complete anyway.
    local out = {}
    local armies = GetArmiesTable()
    if not armies or not armies.armiesTable then return out end
    local selfArmy = armies.focusArmy
    for id, army in armies.armiesTable do
        if id ~= selfArmy and not army.civilian and army.nickname then
            table.insert(out, army.nickname)
        end
    end
    return out
end

---@param s      string
---@param prefix string
---@return boolean
local function StartsWithCI(s, prefix)
    return string.lower(string.sub(s, 1, string.len(prefix))) == string.lower(prefix)
end

--- Returns a completion record for the caret position, or nil if nothing
--- matches.
---@param text  string
---@param caret number
---@return UIChatCompletion?
function Compute(text, caret)
    -- `Consume` covers the full word under the caret so mid-word
    -- completion overwrites the tail too.
    if not text or text == '' then return nil end

    local textLen = STR_Utf8Len(text)
    if caret > textLen then caret = textLen end

    local wordStart = LastSpaceBefore(text, caret)
    local wordEnd   = NextSpaceAfter(text, caret, textLen)
    local isCommand = (wordStart == 0) and (STR_Utf8SubString(text, 1, 1) == '/')

    -- Only append a trailing space when the completion is unambiguous AND
    -- the word runs to end of text. Otherwise we'd double up an existing
    -- separator.
    local atEnd = wordEnd == textLen

    if isCommand then
        local prefix = STR_Utf8SubString(text, 2, caret - 1)
        local matches = CommandRegistry.FindMatching(prefix)
        local n = table.getn(matches)
        if n == 0 then return nil end
        local candidates = {}
        for _, cmd in ipairs(matches) do
            table.insert(candidates, '/' .. cmd.Name)
        end
        return {
            Anchor     = 0,
            Consume    = wordEnd,
            Prefix     = '/' .. prefix,
            Candidates = candidates,
            Index      = 1,
            Suffix     = (n == 1 and atEnd) and ' ' or '',
        }
    end

    local prefix = STR_Utf8SubString(text, wordStart + 1, caret - wordStart)
    if prefix == '' then return nil end

    -- `@nick` shorthand: strip the `@` for matching but keep it in
    -- candidates so `/whisper @Jip` still works. ChatCommandTypes strips
    -- `@` symmetrically on the resolver side.
    local atSign = ''
    local matchPrefix = prefix
    if string.sub(prefix, 1, 1) == '@' then
        atSign = '@'
        matchPrefix = string.sub(prefix, 2)
        if matchPrefix == '' then return nil end
    end

    local candidates = {}
    for _, name in ipairs(CollectNicknames()) do
        if StartsWithCI(name, matchPrefix) then
            table.insert(candidates, atSign .. name)
        end
    end
    local n = table.getn(candidates)
    if n == 0 then return nil end
    table.sort(candidates)

    return {
        Anchor     = wordStart,
        Consume    = wordEnd - wordStart,
        Prefix     = prefix,
        Candidates = candidates,
        Index      = 1,
        Suffix     = (n == 1 and atEnd) and ' ' or '',
    }
end
