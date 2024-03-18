--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

-- upvalue scope for performance
local TableKeys = table.keys

local IsAlly = IsAlly

--- Returns all clients in the game
---@return number[]
function GetAll()
    local clients = GetSessionClients()
    local focusArmy = GetFocusArmy()

    -- skip for observers
    if focusArmy <= 0 then
        return {}
    end

    local recipients = {}
    for k, client in clients do
        for l, source in client.authorizedCommandSources do
            recipients[source] = true
        end
    end

    return TableKeys(recipients)
end

--- Returns all allied clients in the game
---@return number[]
function GetAllies()
    local clients = GetSessionClients()
    local focusArmy = GetFocusArmy()

    -- skip for observers
    if focusArmy <= 0 then
        return {}
    end

    local recipients = {}
    for k, client in clients do
        for l, source in client.authorizedCommandSources do
            if IsAlly(focusArmy, source) then
                recipients[source] = true
            end
        end
    end

    return TableKeys(recipients)
end
