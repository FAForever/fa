--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local luft = require "luft"

---@type UnitBlueprint[]
local BlueprintUnits = {}

-------------------------------------------------------------------------------
--#region Mock constructors

---@param t table
---@return table
function Sound(t)
    return t
end

---@param t table
---@return table
function RPCSound(t)
    return t
end

---@param bp UnitBlueprint
function UnitBlueprint(bp)
    table.insert(BlueprintUnits, bp)
end

-------------------------------------------------------------------------------

---@param directory string
---@return string[]
function DiskFindFiles(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "' .. directory .. '"')
    if (pfile) then
        for filename in pfile:lines() do
            if string.sub(filename, -4) == '.lua' then
                i = i + 1
                t[i] = filename
            end
        end

        pfile:close()
    end
    return t
end

---@type string[]
local blueprintFiles = DiskFindFiles('../units')

for k, blueprintFile in ipairs(blueprintFiles) do
    io.output(blueprintFile)
end
