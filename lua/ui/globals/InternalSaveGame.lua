---@declare-global

--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

do
    local DebugAllocatedSize = debug.allocatedsize
    local oldInternalSaveGame = _G.InternalSaveGame

    --- Hook to fix a buffer overflow security issue in the engine
    ---@param filename string
    _G.InternalSaveGame = function(filename, friendlyFilename, onCompletionCallback)
        local characterLimit = 260 -- Windows's max filepath length
        if DebugAllocatedSize(filename) > characterLimit then
            filename = filename:sub(1, characterLimit)
        end

        if DebugAllocatedSize(friendlyFilename) > characterLimit then
            friendlyFilename = friendlyFilename:sub(1, characterLimit)
        end

        return oldInternalSaveGame(filename, friendlyFilename, onCompletionCallback)
    end
end
