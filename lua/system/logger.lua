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

--- This module is responsible for periodically logging various information
--- about the current session that can be useful for debugging purposes.

--- Retrieves various engine statistics.
---@return integer  # Heap committed
---@return integer  # Heap total
local function GetEngineStatistics()

    local heapCommitted = 0
    local heapTotal = 0

    if __EngineStats and __EngineStats.Children then
        for _, a in pairs(__EngineStats.Children) do
            if a.Name == 'Heap' then
                for _, b in pairs(a.Children) do
                    if b.Name == 'Committed' then
                        heapCommitted = b.Value
                    end

                    if b.Name == 'Total' then
                        heapTotal = b.Value
                    end
                end
            end
        end
    end

    return heapCommitted, heapTotal
end

function LoggingThread()
    while true do
        local sessionTime = CurrentTime()
        local gameTime = GameTime()
        local heapCommitted, heapTotal = GetEngineStatistics()

        SPEW(
            string.format("Session time: %s", FormatTime(sessionTime)),
            string.format("Game time: %s", FormatTime(gameTime)),
            string.format("Heap: %s / %s", heapTotal, heapCommitted)
        )

        WaitSeconds(10)
    end
end

ForkThread(LoggingThread)
