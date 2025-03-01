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

    return diffs
end
