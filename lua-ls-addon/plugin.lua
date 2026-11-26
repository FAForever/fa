-- Orchestrates every SupCom-Lua-to-standard-Lua translation this addon performs, and wires the
-- addon into LuaLS as a workspace plugin.
--
-- Each dialect quirk (comments, table hints, classes, bare iteration, the implicit module
-- system, mod hook files) has its own scanner module, each returning a list of
-- `{start, finish, text}` diffs against the *original* source text - see that module's own
-- header for what it solves and why. `OnSetText` below runs every scanner over each file LuaLS
-- opens, merges their diffs into one list, and hands LuaLS the merged result to parse instead
-- of the raw file. Merging independently-computed diffs safely - two scanners agreeing on the
-- same position, or one scanner's diff accidentally overlapping another's - turned out to need
-- real care of its own; see `mergeSameStartDiffs` and `resolveOverlappingDiffs` below.
-- `ResolveRequire` separately teaches LuaLS to follow FA's root-relative `import()`/
-- `doscript()` paths - and excludes mod hook files from ever being a resolved import target,
-- since a hook shares its target's chunk/scope at runtime (MODS.LUA:150-198) rather than being
-- an importable module in its own right. Hook-file merging itself is bidirectional: a hook
-- file's own `OnSetText` prepends its target's raw content (so the hook's code can reference the
-- target's globals while you're editing it), and - via `hookIndex`, a reverse `targetUri ->
-- {hookUri, ...}` lookup, filled in incrementally as each hook file's own OnSetText registers
-- itself (see hookIndex's own comment for why not an eager scan) - a target file's own
-- `OnSetText` appends every hook that targets it, computing its exports across the combined set,
-- so `import()`ing the target's path from anywhere else in the mod sees the union of both, not
-- just whichever file the import happened to resolve to.

local files        = require 'files'
local furi         = require 'file-uri'
local smerger      = require 'string-merger'
local exportEnv    = require 'export-env'
local tableHints   = require 'table-hints'
local classSupport = require 'class-support'
local forInPairs   = require 'for-in-pairs'
local hookFiles    = require 'hook-files'
local hashComments = require 'hash-comments'

--- Finds every file in the workspace whose path ends with `/<relPath>` (extension-optional,
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
    for fileUri in files.eachFile(uri) do
        local filePath = furi.decode(fileUri)
        if filePath then
            local normalized = filePath:gsub('\\', '/'):lower()
            if normalized:sub(-#suffix) == suffix then
                results[#results + 1] = fileUri
            end
        end
    end
    return results
end

--- Reverse of hookFiles.findTarget: targetUri -> {hookUri, ...}, which hook file(s) apply to a
--- given target. Filled in incrementally as OnSetText processes each file over the course of the
--- session - NOT via an eager, one-time, full-workspace scan (tried first, found broken): a
--- `Lua.workspace.library` setup can span multiple repos with a target in one and its hook in
--- another (confirmed real: a "missions" workspace with `Lua.workspace.library = {"../fa",
--- "../fa-coop"}`, target in fa, hook in fa-coop's `mods/coop/hook/...`), and there's no
--- guarantee the hook's owning library has finished loading into files.eachFile's visible set by
--- the time the very first OnSetText call fires and would have built the index - fa's own
--- ~2800 files alone make it near-certain the scan fires early, with fa-coop's much smaller file
--- count not loaded yet, and a *cached-forever* index built at that moment stays wrong for the
--- rest of the session no matter how much later fa-coop's files actually appear. Registering as
--- each file's own OnSetText runs sidesteps this entirely: every file in the workspace -
--- including every hook file - naturally gets its own OnSetText call at some point during normal
--- preload (LuaLS analyzes the whole project, not just reachable-by-import files), which is
--- exactly when it registers itself below, with no proactive scan needed at all. A target file
--- whose own OnSetText happens to run before its hook has registered will only briefly miss it -
--- self-corrects the next time that target file is itself opened/edited, by which point preload
--- has settled - same "reload/retouch to pick up a workspace-wide fact" pattern the rest of this
--- addon already relies on.
local hookIndex = {}

--- mergeDiff (script/string-merger.lua) sorts diffs by `start`, and table.sort isn't stable
--- for ties, so two diffs that both target the same position race: which one "wins" is
--- undefined and can corrupt output (verified by hand against mergeDiff's cur/buf bookkeeping).
--- Since we run four independent scanners into one diff list, collapse any diffs that land on
--- the same `start` into one before returning, instead of trying to keep each scanner from
--- ever colliding with the others.
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

--- mergeDiff tracks a single `cur` position through diffs *sorted by `start`*, advancing
--- `cur = diff.finish + 1` after each - it assumes diffs never overlap in range.
--- mergeSameStartDiffs only ever collapsed diffs sharing the exact same `start`; it never
--- handled two diffs with *different* starts whose ranges overlap (e.g. class-support.lua's
--- diff blanking out an entire `ClassFn(Bases...)` call, and a nested diff landing on a
--- base-class argument that happens to reference another export of the same file - a real
--- FA pattern: a file defining a base class, then deriving another class from it). When that
--- happens, the nested diff's `finish` is *less* than what `cur` already advanced to from the
--- wider diff, so `cur` moves backward - the next `text:sub(cur, nextDiff.start - 1)` then
--- re-emits already-consumed source text, corrupting everything processed afterward in that
--- file (confirmed by hand against mergeDiff's cur/buf bookkeeping, and reproduced/fixed in
--- the scratchpad Python port before writing this).
--- Resolves this by dropping any diff whose `start` falls at or before the highest `finish`
--- an already-accepted diff claimed - safe unconditionally, since that range's original
--- content is being replaced by the wider diff regardless, so a nested insertion inside it is
--- always moot, never wanted. Call this *after* mergeSameStartDiffs, so same-start collisions
--- (e.g. a `---@class` doc and an `M.` prefix landing on the same position) still combine into
--- one diff first, in append order, before this resolves genuinely overlapping ranges.
---@param diffs fa.diff[]
---@return fa.diff[]
local function resolveOverlappingDiffs(diffs)
    table.sort(diffs, function(a, b) return a.start < b.start end)
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

--- Runs every scanner over `text` (hash-comments, table-hints, class-support, for-in-pairs, in
--- that order - see each module's own header for what it fixes), then export-env's module-wrap
--- pass, then merges everything into one diff list for LuaLS to apply. Order only matters where
--- two scanners could plausibly touch the same text; otherwise each runs independently against
--- the *original* `text`, never against another scanner's output.
---@param  uri  string
---@param  text string
---@return nil|fa.diff[]
function OnSetText(uri, text)
    -- Any hook file(s) that target ME (the reverse of the hookTarget lookup below) - a mod's
    -- hook file shares the target's chunk/scope at runtime (MODS.LUA:150-198), so `import()`ing
    -- this file's own path should see the union of my own top-level declarations and every
    -- applicable hook's. See "Hook files don't merge into import() targets" for the full
    -- reasoning; without this, only a hook file's *own* OnSetText ever knew about its target
    -- (one direction only), never the other way around.
    local hooksApplyingToMe = hookIndex[uri]
    local hookTexts = {}
    if hooksApplyingToMe then
        for _, hookUri in ipairs(hooksApplyingToMe) do
            local hookText = files.getOriginText(hookUri)
            if hookText then
                -- Same BOM concern as the target-side handling below.
                hookTexts[#hookTexts + 1] = hookText:gsub('^\239\187\191', '')
            end
        end
    end

    -- Computed up front, before classSupport runs, because it needs to know which bare names
    -- are this file's own exports - see the comment on the base-class keep-alive inside
    -- class-support.lua's stripWrappers for why. Combined across this file AND every hook that
    -- targets it (if any), not just `text` alone - a name a hook adds or overrides is exactly as
    -- much a real top-level declaration of the combined runtime chunk as one this file defines
    -- itself.
    local allExports, seenExport, unsafeNamesUnion = {}, {}, {}
    local hasTopReturn, topLevelLocalCount = false, 0
    local scanParts = { text }
    for _, hookText in ipairs(hookTexts) do
        scanParts[#scanParts + 1] = hookText
    end
    for _, part in ipairs(scanParts) do
        local exports, partHasTopReturn, partTopLevelLocalCount, unsafeNames = exportEnv.scan(part)
        hasTopReturn = hasTopReturn or partHasTopReturn
        topLevelLocalCount = topLevelLocalCount + partTopLevelLocalCount
        for _, name in ipairs(exports) do
            if not seenExport[name] then
                seenExport[name] = true
                allExports[#allExports + 1] = name
            end
            if unsafeNames[name] then
                unsafeNamesUnion[name] = true
            end
        end
    end
    local safeNames = {}
    local unsafeList = {}
    for _, name in ipairs(allExports) do
        if unsafeNamesUnion[name] then
            unsafeList[#unsafeList + 1] = name
        else
            safeNames[name] = true
        end
    end

    local diffs = {}
    for _, diff in ipairs(hashComments.stripHashComments(text)) do
        diffs[#diffs + 1] = diff
    end

    for _, diff in ipairs(tableHints.stripHints(text)) do
        diffs[#diffs + 1] = diff
    end

    for _, diff in ipairs(classSupport.stripWrappers(text, safeNames)) do
        diffs[#diffs + 1] = diff
    end

    for _, diff in ipairs(forInPairs.wrapBareIterators(text)) do
        diffs[#diffs + 1] = diff
    end

    -- Hook files (MODS.LUA:150-198): the mod's file is concatenated to the END of the target
    -- at runtime, sharing its top-level scope. We reproduce that by prepending the target's
    -- content here. Deliberately use the target's RAW text (files.getOriginText), not its own
    -- transformed text: the target's own export-env pass would have turned its top-level names
    -- into locals scoped to nothing but itself, plus appended a `return {...}` - concatenated
    -- in front of the hook's own code, a mid-chunk `return` is an actual syntax error. Raw text
    -- keeps the target's names as the real globals the hook is supposed to see, and we still
    -- run the (non-scope-changing) table-hints/class-support/for-in-pairs passes over it so
    -- `Cls = Class(oldCls) {...}`-style overrides still get proper class typing.
    local hookTarget = hookFiles.findTarget(uri, text)
    if hookTarget then
        local targetUri
        for _, candidate in ipairs(findUrisBySuffix(uri, hookTarget)) do
            if candidate ~= uri then
                targetUri = candidate
                break
            end
        end
        -- Register myself into the reverse hookIndex right here, reusing the targetUri just
        -- resolved above - this is the ONLY place a hook file's relationship to its target gets
        -- recorded (see hookIndex's own comment for why this incremental approach, not an eager
        -- scan). A later OnSetText call for `targetUri` (its own, or triggered by re-opening it)
        -- will then see me in `hooksApplyingToMe` and merge my content in.
        if targetUri then
            hookIndex[targetUri] = hookIndex[targetUri] or {}
            local alreadyRegistered = false
            for _, existingHookUri in ipairs(hookIndex[targetUri]) do
                if existingHookUri == uri then
                    alreadyRegistered = true
                    break
                end
            end
            if not alreadyRegistered then
                hookIndex[targetUri][#hookIndex[targetUri] + 1] = uri
            end
        end
        local targetText = targetUri and files.getOriginText(targetUri)
        if targetText then
            -- script/encoder/init.lua's decode() is a no-op for utf8, so a target file with a
            -- literal UTF-8 BOM (confirmed on loc/*/strings_db.lua, e.g.) keeps those 3 raw
            -- bytes in files.getOriginText's result. Harmless at a real position-1 file start
            -- (editors strip it before it ever reaches didOpen), but here it'd land mid-stream,
            -- right where the target's first real line is expected - not valid Lua syntax
            -- anywhere but the very start of a file, so it has to go.
            targetText = targetText:gsub('^\239\187\191', '')
            local targetDiffs = {}
            for _, d in ipairs(hashComments.stripHashComments(targetText)) do
                targetDiffs[#targetDiffs + 1] = d
            end
            for _, d in ipairs(tableHints.stripHints(targetText)) do
                targetDiffs[#targetDiffs + 1] = d
            end
            for _, d in ipairs(classSupport.stripWrappers(targetText)) do
                targetDiffs[#targetDiffs + 1] = d
            end
            for _, d in ipairs(forInPairs.wrapBareIterators(targetText)) do
                targetDiffs[#targetDiffs + 1] = d
            end
            local transformedTarget = smerger.mergeDiff(targetText, resolveOverlappingDiffs(mergeSameStartDiffs(targetDiffs)))
            diffs[#diffs + 1] = {
                start  = 1,
                finish = 0,
                text   = '---@diagnostic disable\n' .. transformedTarget .. '\n---@diagnostic enable\n',
            }
        end
    end

    -- The reverse direction: hook(s) that target ME (hooksApplyingToMe/hookTexts, computed at
    -- the top of this function) get their own transformed content appended to the END of mine -
    -- matching the real engine's own concatenation order (MODS.LUA:150-198) and the exports
    -- computed above. Unlike the forward (hookTarget) case above, this DOES run
    -- exportEnv.rewriteReferences on the hook's own text (using the same combined `safeNames`
    -- this file uses) - so a hook's own override or addition becomes part of the SAME shared `M`
    -- below, not a separate one, which is the entire point of this fix: importing this file's
    -- own path should see the union.
    for _, hookText in ipairs(hookTexts) do
        local hookDiffs = {}
        for _, d in ipairs(hashComments.stripHashComments(hookText)) do
            hookDiffs[#hookDiffs + 1] = d
        end
        for _, d in ipairs(tableHints.stripHints(hookText)) do
            hookDiffs[#hookDiffs + 1] = d
        end
        for _, d in ipairs(classSupport.stripWrappers(hookText, safeNames)) do
            hookDiffs[#hookDiffs + 1] = d
        end
        for _, d in ipairs(forInPairs.wrapBareIterators(hookText)) do
            hookDiffs[#hookDiffs + 1] = d
        end
        for _, d in ipairs(exportEnv.rewriteReferences(hookText, safeNames)) do
            hookDiffs[#hookDiffs + 1] = d
        end
        local transformedHook = smerger.mergeDiff(hookText, resolveOverlappingDiffs(mergeSameStartDiffs(hookDiffs)))
        diffs[#diffs + 1] = {
            start  = #text + 1,
            finish = #text,
            text   = '\n---@diagnostic disable\n' .. transformedHook .. '\n---@diagnostic enable\n',
        }
    end

    if #allExports > 0 and not hasTopReturn then
        -- Turn the file into a classic module: `local M = {}`, every export becomes
        -- `M.Name = ...`, `return M`. Unlike forward-declared locals, `M.Name` field
        -- resolution isn't restricted to "last assignment before this textual position" - it
        -- resolves correctly from inside an earlier-defined function's body too, and doesn't
        -- consume any of Lua 5.1's 200-local-per-chunk budget (see export-env.lua's header for
        -- the full reasoning and the vm.getTableValue verification behind it).
        --
        -- A name that's shadowed anywhere in the file (a local/param/loop-var of the same
        -- name - `unsafeNames`, from exportEnv.scan) can't safely have every *reference*
        -- rewritten to `M.Name`, since a text scanner can't otherwise tell which bare
        -- occurrence means what inside that shadowing scope (confirmed real, not just
        -- theoretical: lua/system/profile.lua's `checkpoint` export is shadowed by
        -- `function checkpoint_to_table(checkpoint)`'s own parameter). Those names keep
        -- today's exact behaviour instead - forward-declared as a real `local`, then bridged
        -- into `M` with one `M.Name = Name` assignment before `return M` - so import()
        -- consumers still see a single, consistent table either way. Verified empirically
        -- negligible: 57 names total, across 24 files, in the whole fa repo's 102,668
        -- top-level exports.
        --
        -- `safeNames`/`unsafeList` were already computed at the top of this function, combined
        -- across this file and any hook that targets it (before classSupport ran, which needs
        -- `safeNames` too).

        -- Appended to `diffs` BEFORE the reference-rewrite diffs below, not after: if the file's
        -- very first byte is itself the start of a safe export's name (no leading comment/blank
        -- line), both this diff and that name's own `M.`-prefix diff target the same position-1
        -- insertion point, and mergeSameStartDiffs concatenates same-start diffs in append order -
        -- this header must land first, or the output would start with `M.local M = {}...`.
        local header = 'local M = {}\n'
        if #unsafeList > 0 then
            -- Same 200-local-cap safety margin as before, now scoped to just the unsafe
            -- subset - in practice always small enough that this never trips.
            local MAX_TOTAL_TOP_LEVEL_LOCALS = 190
            if (#unsafeList + topLevelLocalCount) <= MAX_TOTAL_TOP_LEVEL_LOCALS then
                header = header .. 'local ' .. table.concat(unsafeList, ', ') .. '\n'
            end
        end
        diffs[#diffs + 1] = {
            start  = 1,
            finish = 0,
            text   = header,
        }

        for _, diff in ipairs(exportEnv.rewriteReferences(text, safeNames)) do
            diffs[#diffs + 1] = diff
        end

        local footer = { '\n' }
        for _, name in ipairs(unsafeList) do
            footer[#footer + 1] = ('M.%s = %s\n'):format(name, name)
        end
        footer[#footer + 1] = 'return M\n'
        diffs[#diffs + 1] = {
            start  = #text + 1,
            finish = #text,
            text   = table.concat(footer),
        }
    end

    return resolveOverlappingDiffs(mergeSameStartDiffs(diffs))
end

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
    -- A hook file (`<mod>/hook/lua/sim/SomeFile.lua`) mirrors the target's own path suffix
    -- (`/lua/sim/SomeFile.lua`), so it always matches too - but nobody writes `import()`s
    -- pointing at a hookdir path; every import means "give me the target's module", hooks
    -- included (see OnSetText's hooksApplyingToMe/hookIndex handling above for the merge
    -- itself). Without this filter, which candidate "wins" - target or hook - depends on
    -- files.eachFile's iteration order, not anything meaningful (confirmed: LuaLS only ever
    -- uses the first entry of a multi-candidate ResolveRequire result, never a union).
    local filtered = {}
    for _, candidateUri in ipairs(results) do
        local candidateText = files.getOriginText(candidateUri)
        if not (candidateText and hookFiles.findTarget(candidateUri, candidateText)) then
            filtered[#filtered + 1] = candidateUri
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
