local StringFind = string.find
local StringGmatch = string.gmatch
local StringMatch = string.match

local IoOpen = io.open

print('[FA Plugin] FA plugin starting...')

-- repository to use for hook file intellisense. Same as the one in the dev init file.
local initPath = 'C:/ProgramData/FAForever/bin/init_local_development.lua'

local initFile, err = IoOpen(initPath, 'r')
local locationOfRepository
if initFile then
    for line in initFile:lines() do
        local start, finish, repoPath = StringFind(line, 'locationOfRepository = [\'"]([%w:/]+)[\'"]')
        if repoPath then
            locationOfRepository = repoPath
            print('[FA Plugin] Using repository path: ' .. repoPath)
            break
        end
    end
    if not locationOfRepository then
        print('[FA Plugin] Could not find repository path in init file:' .. initPath)
    end
else
    print('[FA plugin] Could not open init file: ' .. tostring(initPath)
        .. '\n[FA plugin] Error message: ' .. tostring(err)
    )
end

---@class diff
---@field start  integer # The number of bytes at the beginning of the replacement
---@field finish integer # The number of bytes at the end of the replacement
---@field text   string  # What to replace

---@param  uri  string # The uri of file
---@param  text string # The content of file
---@return nil|diff[]
function OnSetText(uri, text)
    ---@type diff[]
    local diffs = {}
    -- Change `#` (valid Supcom Lua comment) to `--` (valid in language server's lua)
    -- get first line
    local pos = StringMatch(text, '^%s*()#')
    if pos ~= nil then
        diffs[#diffs + 1] = {
            start = pos,
            finish = pos,
            text = '--'
        }
    end
    -- get any lines after that
    for pos in StringGmatch(text, '\r\n%s*()#') do
        diffs[#diffs + 1] = {
            start = pos,
            finish = pos,
            text = '--'
        }
    end
    -- Change `{&1 &1}` (valid Supcom Lua) to `{}` (valid in language server's lua)
    -- It's changed inside comments too, but lua regex doesn't make that easy to fix.
    for start, finish in StringGmatch(text, '(){&%d+ &%d+}()') do
        diffs[#diffs + 1] = {
            start = start,
            finish = finish - 1,
            text = '{}',
        }
    end

    if locationOfRepository then
        -- prepend the content of hooked files just like the game would
        local first, last, hookDir = StringFind(uri, '/hook(/[%w/]+.lua)')
        if hookDir then
            local repoFile = IoOpen(locationOfRepository .. hookDir)
            if repoFile then
                local repoContent = repoFile:read("*a")
                repoFile:close()
                -- all diagnostics registered in /server/script/proto/diagnostic.lua
                local diagnostics = 'exp-in-action,unused-local,unused-function,unused-label,unused-vararg,trailing-space,redundant-return,empty-block,code-after-break,unreachable-code,redundant-value,unbalanced-assignments,redundant-parameter,missing-parameter,missing-return-value,redundant-return-value,missing-return,need-check-nil,undefined-field,cast-local-type,assign-type-mismatch,param-type-mismatch,cast-type-mismatch,return-type-mismatch,duplicate-doc-alias,undefined-doc-class,undefined-doc-name,circle-doc-class,undefined-doc-param,duplicate-doc-param,doc-field-no-class,duplicate-doc-field,unknown-diag-code,unknown-cast-variable,unknown-operator,codestyle-check,spell-check,newline-call,newfield-call,ambiguity-1,count-down-loop,different-requires,await-in-sync,not-yieldable,no-unknown,redefined-local,undefined-global,global-in-nil-env,lowercase-global,undefined-env-child,duplicate-index,duplicate-set-field,close-non-object,deprecated,discard-returns'
                local diagnosticDisable = '---@diagnostic disable:' .. diagnostics .. '\n'
                local diagnosticEnable = '---@diagnostic enable:' .. diagnostics .. '\n'
                diffs[#diffs + 1] = {
                    start = 1,
                    finish = 1,
                    text = diagnosticDisable .. repoContent .. diagnosticEnable .. text:sub(1, 1)
                }
            end
        end
    end

    return diffs
end

print('[FA Plugin] FA plugin started')
