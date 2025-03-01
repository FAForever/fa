-- repository to use for hook file intellisense. Same as the one in the dev init file.
local initPath = 'C:/ProgramData/FAForever/bin/init_local_development.lua'

local initFile, err = io.open(initPath, 'r')
local locationOfRepository
if initFile then
    for line in initFile:lines() do
        local start, finish, repoPath = string.find(line, 'locationOfRepository = [\'"]([%w:/]+)[\'"]')
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
    local diffs = {}
    -- Change `#` (valid Supcom Lua comment) to `--` (valid in language server's lua)
    -- get first line
    local pos = text:match('^%s*()#')
    if pos ~= nil then
        diffs[#diffs + 1] = {
            start = pos,
            finish = pos,
            text = '--'
        }
    end
    -- get any lines after that
    for pos in text:gmatch '\r\n%s*()#' do
        diffs[#diffs + 1] = {
            start = pos,
            finish = pos,
            text = '--'
        }
    end
    -- Change `{&1 &1}` (valid Supcom Lua) to `{}` (valid in language server's lua)
    -- It's changed inside comments too, but lua regex doesn't make that easy to fix.
    for start, finish in (text):gmatch('(){&%d+ &%d+}()') do
        diffs[#diffs + 1] = {
            start = start,
            finish = finish - 1,
            text = '{}',
        }
    end

    if locationOfRepository then
        -- prepend the content of hooked files just like the game would
        local first, last, hookDir = uri:find('/hook(/[%w/]+.lua)')
        if hookDir then
            local repoFile = io.open(locationOfRepository .. hookDir)
            if repoFile then
                diffs[#diffs+1] = {
                    start = 1,
                    finish = 1,
                    text = repoFile:read("*a")
                }
            end
        end
    end

    return diffs
end
