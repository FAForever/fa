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

-------------------------------------------------------------------------------
--#region Game <-> Server communications

-- All the following logic is tightly coupled with functionality on either the
-- lobby server, the ice adapter, the java server and/or the client. For more
-- context you can search for the various keywords in the following repositories:
-- - Lobby server: https://github.com/FAForever/server
-- - Java server: https://github.com/FAForever/faf-java-server
-- - Java Ice adapter: https://github.com/FAForever/java-ice-adapter
-- - Kotlin Ice adapter: https://github.com/FAForever/kotlin-ice-adapter
--
-- If we do not send this information then the client is unaware of changes made
-- to the lobby after hosting. These messages are usually only accepted from the
-- host of the lobby.

--- Original function that we should not use directly
local oldGpgNetSend = GpgNetSend


---@param command string
---@param ... number | string
_G.GpgNetSend = function(command, ...)

    --- Add a hook that generates sim callbacks for communication to the
    --- server. Useful for moderation purposes.

    SPEW("GpgNetSend", command, unpack(arg))

    if SessionIsActive() and not SessionIsReplay() then
        local stringifiedArgs = ""
        for k = 1, table.getn(arg) do
            stringifiedArgs = stringifiedArgs .. tostring(arg[k]) .. ","
        end

        local currentFocusArmy = GetFocusArmy()
        SimCallback(
            {
                Func = "ModeratorEvent",
                Args = {
                    From = currentFocusArmy,
                    Message = string.format("GpgNetSend with command '%s' and data '%s'", tostring(command),
                        stringifiedArgs),
                },
            }
        )
    end

    oldGpgNetSend(command, unpack(arg))
end


