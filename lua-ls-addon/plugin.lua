-- Orchestrates every SupCom-Lua-to-standard-Lua translation this addon performs, and wires the
-- addon into LuaLS as a workspace plugin.
--
-- Each dialect quirk (comments, table hints, classes, bare iteration, the implicit module
-- system, mod hook files) has its own scanner module, each returning a list of
-- `{start, finish, text}` diffs against the *original* source text - see that module's own
-- header for what it solves and why. All of them read lexer.lua's tokens. `OnSetText` below
-- runs every scanner over each file LuaLS opens, merges their diffs into one list, and hands
-- LuaLS the merged result to parse instead of the raw file. Merging independently-computed
-- diffs safely needs care of its own; see `mergeSameStartDiffs` and `resolveOverlappingDiffs`.
--
-- `ResolveRequire` teaches LuaLS to follow FA's root-relative `import()`/`doscript()` paths, and
-- never resolves to a mod hook file, since a hook shares its target's chunk at runtime
-- (MODS.LUA:150-198) rather than being an importable module of its own.
--
-- Hook files are merged both ways. A hook file's own text gets its target's content prepended
-- (so the hook's code sees the target's names while you edit it), and a target's text gets every
-- hook that targets it appended (so `import()`ing the target sees the union). Exports are
-- computed over the combined chunk, and `files.watch` re-processes the other side whenever
-- either file changes.

local files        = require 'files'
local furi         = require 'file-uri'
local smerger      = require 'string-merger'
local exportEnv    = require 'export-env'
local tableHints   = require 'table-hints'
local classSupport = require 'class-support'
local forInPairs   = require 'for-in-pairs'
local hookFiles    = require 'hook-files'
local hashComments = require 'hash-comments'

local okScope, workspaceScope = pcall(require, 'workspace.scope')

---------------------------------------------------------------------------------------------
-- Path lookup
---------------------------------------------------------------------------------------------

--- Normalized (forward slashes, lower case) path of a URI.
---@param uri string
---@return string?
local function normalizedPath(uri)
    local path = furi.decode(uri)
    return path and path:gsub('\\', '/'):lower()
end

--- Per-scope index `fileName (lower case) -> {{path = normalized path, uri = uri}, ...}`.
--- `files.eachFile` builds and sorts the full URI list on every call, and an `import()`
--- resolution used to walk all of it, decoding every path - thousands of times during preload.
--- Built once per scope, then kept up to date from `files.watch` create/remove events.
---@type table<any, table<string, {path: string, uri: string}[]>>
local suffixIndexes = setmetatable({}, { __mode = 'k' })

local function scopeKey(uri)
    if okScope and workspaceScope.getScope then
        return workspaceScope.getScope(uri)
    end
    return 'default'
end

local function addToIndex(index, uri)
    local path = normalizedPath(uri)
    if not path then
        return
    end
    local name = path:match('[^/]+$')
    local bucket = index[name]
    if not bucket then
        bucket = {}
        index[name] = bucket
    end
    for _, entry in ipairs(bucket) do
        if entry.uri == uri then
            return
        end
    end
    bucket[#bucket + 1] = { path = path, uri = uri }
end

local function removeFromIndex(index, uri)
    local path = normalizedPath(uri)
    local bucket = path and index[path:match('[^/]+$')]
    if not bucket then
        return
    end
    for k = #bucket, 1, -1 do
        if bucket[k].uri == uri then
            table.remove(bucket, k)
        end
    end
end

local function getSuffixIndex(uri)
    local key = scopeKey(uri)
    local index = suffixIndexes[key]
    if not index then
        index = {}
        for fileUri in files.eachFile(uri) do
            addToIndex(index, fileUri)
        end
        suffixIndexes[key] = index
    end
    return index
end

--- Finds every file in `uri`'s scope whose path ends with `/<relPath>` (extension-optional,
--- case-insensitive) - shared by ResolveRequire and the hook-file target lookup below.
---@param uri     string
---@param relPath string
---@return string[]
local function findUrisBySuffix(uri, relPath)
    local target = relPath:gsub('\\', '/'):gsub('^/', ''):lower()
    if not target:match('%.lua$') then
        target = target .. '.lua'
    end
    local suffix = '/' .. target
    local results = {}
    local bucket = getSuffixIndex(uri)[target:match('[^/]+$')]
    if bucket then
        for _, entry in ipairs(bucket) do
            if entry.path:sub(-#suffix) == suffix then
                results[#results + 1] = entry.uri
            end
        end
        table.sort(results)
    end
    return results
end

---------------------------------------------------------------------------------------------
-- Hook bookkeeping
---------------------------------------------------------------------------------------------

--- targetUri -> {hookUri, ...}: which hook file(s) apply to a target. Filled in as OnSetText
--- processes each hook file, NOT by an eager one-time scan: a `Lua.workspace.library` setup can
--- span several repos (target in fa, hook in fa-coop's `mods/coop/hook/...`), and nothing
--- guarantees the hook's library has loaded by the time the first OnSetText fires. Every file
--- gets its own OnSetText during preload, which is when it registers itself; the watcher below
--- then re-processes the target so it picks the hook up straight away.
---@type table<string, string[]>
local hookIndex = {}
--- hookUri -> targetUri, the reverse of hookIndex.
---@type table<string, string>
local hookTargetOf = {}

local function registerHook(hookUri, targetUri)
    hookTargetOf[hookUri] = targetUri
    local list = hookIndex[targetUri]
    if not list then
        list = {}
        hookIndex[targetUri] = list
    end
    for _, existing in ipairs(list) do
        if existing == hookUri then
            return
        end
    end
    list[#list + 1] = hookUri
end

local function unregisterHook(hookUri)
    local targetUri = hookTargetOf[hookUri]
    if not targetUri then
        return
    end
    hookTargetOf[hookUri] = nil
    local list = hookIndex[targetUri]
    if list then
        for k = #list, 1, -1 do
            if list[k] == hookUri then
                table.remove(list, k)
            end
        end
        if #list == 0 then
            hookIndex[targetUri] = nil
        end
    end
end

---------------------------------------------------------------------------------------------
-- Diff merging
---------------------------------------------------------------------------------------------

--- mergeDiff (script/string-merger.lua) sorts diffs by `start`, and table.sort isn't stable for
--- ties, so two diffs that both target the same position race: which one "wins" is undefined
--- and can corrupt output. Since several independent scanners feed one diff list, collapse any
--- diffs that land on the same `start` into one, concatenating their text in list order.
---@param diffs fa.diff[]
---@return fa.diff[]
local function mergeSameStartDiffs(diffs)
    local groups, order = {}, {}
    for _, d in ipairs(diffs) do
        if not groups[d.start] then
            groups[d.start] = {}
            order[#order + 1] = d.start
        end
        table.insert(groups[d.start], d)
    end

    local merged = {}
    for _, start in ipairs(order) do
        local group = groups[start]
        if #group == 1 then
            merged[#merged + 1] = group[1]
        else
            local finish = start - 1
            local text = {}
            for _, d in ipairs(group) do
                if d.finish >= start then
                    finish = math.max(finish, d.finish)
                end
                text[#text + 1] = d.text
            end
            merged[#merged + 1] = { start = start, finish = finish, text = table.concat(text) }
        end
    end
    return merged
end

--- mergeDiff walks diffs sorted by `start`, advancing `cur = diff.finish + 1` after each - it
--- assumes ranges never overlap. A diff nested inside a wider one (e.g. an `M.` prefix on a base
--- name inside the `ClassFn(Bases...)` range class-support.lua blanks) would move `cur` backward
--- and re-emit already-consumed text. Drop any diff starting at or before the furthest `finish`
--- already accepted: its range is being replaced by the wider diff anyway. Call this *after*
--- mergeSameStartDiffs, so same-start insertions still combine first.
---@param diffs fa.diff[]
---@return fa.diff[]
local function resolveOverlappingDiffs(diffs)
    table.sort(diffs, function (a, b) return a.start < b.start end)
    local result = {}
    local claimedUntil = 0
    for _, d in ipairs(diffs) do
        if d.start > claimedUntil then
            result[#result + 1] = d
            claimedUntil = math.max(claimedUntil, d.finish)
        end
    end
    return result
end

---@param diffs fa.diff[]
---@return fa.diff[]
local function finalizeDiffs(diffs)
    return resolveOverlappingDiffs(mergeSameStartDiffs(diffs))
end

---------------------------------------------------------------------------------------------
-- OnSetText
---------------------------------------------------------------------------------------------

--- A target's or hook's text as stored by LuaLS. A UTF-8 BOM is fine at a real file start, but
--- not spliced into the middle of another file's text.
---@param uri string
---@return string?
local function getPartText(uri)
    local text = files.getOriginText(uri)
    return text and (text:gsub('^\239\187\191', ''))
end

--- Every dialect rewrite for one piece of text, as diffs against that text.
---@param text      string
---@param module?   {exportSet: table<string, boolean>, name: string}  nil: no module rewrite
---@return fa.diff[]
local function dialectDiffs(text, module)
    local diffs = {}
    local function add(list)
        for _, d in ipairs(list) do
            diffs[#diffs + 1] = d
        end
    end

    local rewriteDiffs, rewritten = {}, {}
    if module then
        rewriteDiffs, rewritten = exportEnv.rewriteReferences(text, module.exportSet, module.name)
    end

    add(hashComments.stripHashComments(text))
    add(tableHints.stripHints(text))
    -- class-support's keep-alive goes before the statement, so it must come before an `M.`
    -- prefix that lands on the same position.
    add(classSupport.stripWrappers(text, rewritten, module and module.name))
    add(forInPairs.wrapBareIterators(text))
    add(rewriteDiffs)
    return diffs
end

--- `text` with every dialect rewrite applied.
---@param text    string
---@param module? {exportSet: table<string, boolean>, name: string}
---@return string
local function transform(text, module)
    return (smerger.mergeDiff(text, finalizeDiffs(dialectDiffs(text, module))))
end

---@param  uri  string
---@param  text string
---@return nil|fa.diff[]
function OnSetText(uri, text)
    -- If this is a hook file, its target's content runs first, in the same chunk.
    local targetText
    local relTarget = hookFiles.findTarget(uri, text)
    if relTarget then
        local targetUri
        for _, candidate in ipairs(findUrisBySuffix(uri, relTarget)) do
            if candidate ~= uri then
                targetUri = candidate
                break
            end
        end
        if targetUri then
            registerHook(uri, targetUri)
            targetText = getPartText(targetUri)
        end
    else
        unregisterHook(uri)
    end

    -- Hook files that target this file run right after it, in the same chunk.
    local hookTexts = {}
    for _, hookUri in ipairs(hookIndex[uri] or {}) do
        local hookText = getPartText(hookUri)
        if hookText then
            hookTexts[#hookTexts + 1] = hookText
        end
    end

    -- The module rewrite covers the combined chunk: exports are the union over every part.
    local parts = { text }
    if targetText then
        parts[#parts + 1] = targetText
    end
    for _, hookText in ipairs(hookTexts) do
        parts[#parts + 1] = hookText
    end
    local exportSet, exportCount = {}, 0
    local globalChunk, hasTopReturn, usesM = false, false, false
    local targetReturns = false
    for index, part in ipairs(parts) do
        local analysis = exportEnv.analyze(part)
        if part == targetText and analysis.hasTopReturn then
            targetReturns = true
        end
        -- This file or its target running in the global env makes the whole chunk global.
        -- (An appended hook marked global doesn't change what its target is.)
        if analysis.optOut and (index == 1 or part == targetText) then
            globalChunk = true
        end
        hasTopReturn = hasTopReturn or analysis.hasTopReturn
        usesM = usesM or analysis.usesM
        for _, name in ipairs(analysis.exports) do
            if not exportSet[name] then
                exportSet[name] = true
                exportCount = exportCount + 1
            end
        end
    end
    local module
    if not globalChunk and not hasTopReturn and exportCount > 0 then
        module = { exportSet = exportSet, name = usesM and '__fa_module' or 'M' }
    end

    local diffs = {}

    -- Position 1: module header, then the hook target's content. Added before every scanner's
    -- diffs so that mergeSameStartDiffs keeps it in front of a scanner diff at position 1
    -- (e.g. a `#` comment on the first line becoming `--`).
    local prefix = {}
    if module then
        prefix[#prefix + 1] = ('local %s = {}\n'):format(module.name)
    end
    if targetText then
        local body = transform(targetText, module)
        if targetReturns then
            -- A top-level `return` can only end a block: keep it valid mid-chunk.
            body = 'do\n' .. body .. '\nend'
        end
        prefix[#prefix + 1] = '---@diagnostic disable\n' .. body .. '\n---@diagnostic enable\n'
    end
    if #prefix > 0 then
        diffs[#diffs + 1] = { start = 1, finish = 0, text = table.concat(prefix) }
    end

    for _, d in ipairs(dialectDiffs(text, module)) do
        diffs[#diffs + 1] = d
    end

    -- End of file: hooks targeting this file, then `return M`.
    local suffix = {}
    for _, hookText in ipairs(hookTexts) do
        suffix[#suffix + 1] = '\n---@diagnostic disable\n' .. transform(hookText, module) .. '\n---@diagnostic enable\n'
    end
    if module then
        suffix[#suffix + 1] = ('\nreturn %s\n'):format(module.name)
    end
    if #suffix > 0 then
        diffs[#diffs + 1] = { start = #text + 1, finish = #text, text = table.concat(suffix) }
    end

    return finalizeDiffs(diffs)
end

---------------------------------------------------------------------------------------------
-- Keeping hook merges and the path index current
---------------------------------------------------------------------------------------------

--- URIs we asked LuaLS to re-process: their next `update` is our own doing, not an edit, and
--- must not propagate further (a target reset would otherwise reset its hooks, and so on).
local resetting = {}

local function reset(uri)
    if files.resetText and files.getOriginText(uri) then
        resetting[uri] = true
        files.resetText(uri)
    end
end

local function onWatch(ev, uri)
    if ev == 'create' then
        for key, index in pairs(suffixIndexes) do
            if key == 'default' or key:isChildUri(uri) or key:isLinkedUri(uri) then
                addToIndex(index, uri)
            end
        end
    elseif ev == 'remove' then
        for _, index in pairs(suffixIndexes) do
            removeFromIndex(index, uri)
        end
        if hookTargetOf[uri] then
            local targetUri = hookTargetOf[uri]
            unregisterHook(uri)
            reset(targetUri)
        end
    elseif ev == 'update' then
        if resetting[uri] then
            resetting[uri] = nil
            return
        end
        -- A hook changed: its target appends the hook's text.
        if hookTargetOf[uri] then
            reset(hookTargetOf[uri])
        end
        -- A target changed: its hooks prepend the target's text.
        local hooks = hookIndex[uri]
        if hooks then
            for _, hookUri in ipairs(hooks) do
                reset(hookUri)
            end
        end
    end
end

-- LuaLS re-runs this file whenever the plugin reloads (e.g. a settings change), but its watch
-- list only grows. Register one trampoline per addon copy, and point it at the newest handler.
if files.watch then
    local key = debug.getinfo(1, 'S').source
    local handlers = files.__faAddonWatchHandlers
    if not handlers then
        handlers = {}
        files.__faAddonWatchHandlers = handlers
    end
    if not handlers[key] then
        files.watch(function (ev, uri)
            local handler = handlers[key]
            if handler then
                handler(ev, uri)
            end
        end)
    end
    handlers[key] = onWatch
end

---------------------------------------------------------------------------------------------
-- ResolveRequire
---------------------------------------------------------------------------------------------

-- import()/doscript() take root-relative paths like '/lua/sim/Weapon.lua', optionally without
-- the extension and with inconsistent case/slash direction. Only take over resolution for
-- names that look like a path; anything else (plain `require 'foo'`) falls through untouched
-- by returning nil.
---@param uri  string
---@param name string
---@param suri string
---@return uri[]|nil
function ResolveRequire(uri, name, suri)
    if not name:find('[/\\]') then
        return nil
    end

    local results = findUrisBySuffix(uri, name)
    -- A hook file (`<mod>/hook/lua/sim/SomeFile.lua`) mirrors its target's path suffix
    -- (`/lua/sim/SomeFile.lua`), so it always matches too - but an import always means the
    -- target's module (hooks included, via OnSetText's merge). LuaLS only uses the first entry
    -- of a multi-candidate result, so leave hooks out rather than depend on iteration order.
    local filtered = {}
    for _, candidateUri in ipairs(results) do
        if not hookTargetOf[candidateUri] then
            local candidateText = files.getOriginText(candidateUri)
            if not (candidateText and hookFiles.findTarget(candidateUri, candidateText)) then
                filtered[#filtered + 1] = candidateUri
            end
        end
    end
    if #filtered > 0 then
        return filtered
    end
    if #results > 0 then
        return results
    end
    return nil
end
