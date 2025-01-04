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

--- A component that represent all the supported lobby <-> server communications.
---@class UIAutolobbyArgumentsComponent
AutolobbyArgumentsComponent = ClassSimple {

    --- Represent all valid command line arguments for the lobby
    ArgumentKeys = {
        ["/init"] = true,
        ["/joincustom"] = true,
        ["/gpgnet"] = true,

        -- related to player info
        ["/clan"] = true,
        ["/country"] = true,
        ["/numgames"] = true,

        -- related to player settings
        ["/team"] = true,
        ["/uef"] = true,
        ["/cybran"] = true,
        ["/aeon"] = true,
        ["/seraphim"] = true,
        ["/startspot"] = true,

        -- related to rating
        ["/deviation"] = true,
        ["/mean"] = true,

        -- related to divisions
        ["/division"] = true,
        ["/subdivision"] = true,

        -- related to game settings
        ["/gameoptions"] = true,
        ["/players"] = true,
    },

    --- Verifies that it is an expected command line argument
    ---@param self UIAutolobbyArgumentsComponent | UIAutolobbyCommunications
    ---@param option string
    ---@return boolean
    ValidCommandLineKey = function(self, option)
        if not self.ArgumentKeys[option] then
            self:DebugWarn("Unknown command line argument: ", option)
            return false
        end

        return true
    end,

    --- Attempts to retrieve a string-like command line argument
    ---@param self UIAutolobbyArgumentsComponent | UIAutolobbyCommunications
    ---@param option string
    ---@param default string
    ---@return string
    GetCommandLineArgumentString = function(self, option, default)
        if not self:ValidCommandLineKey(option) then
            return default
        end

        -- try to get the first argument
        local arguments = GetCommandLineArg(option, 1)
        if arguments and (not option[ arguments[1] ]) then
            return arguments[1]
        end

        return default
    end,

    --- Attempts to retrieve a number-like command line argument
    ---@param self UIAutolobbyArgumentsComponent | UIAutolobbyCommunications
    ---@param option string
    ---@param default number
    ---@return number
    GetCommandLineArgumentNumber = function(self, option, default)
        if not self:ValidCommandLineKey(option) then
            return default
        end

        -- try to get the first argument and parse it as a number
        local arguments = GetCommandLineArg(option, 1)
        if arguments and (not option[ arguments[1] ]) then
            local parsed = tonumber(arguments[1])
            if parsed then
                return parsed
            else
                self:DebugWarn("Failed to parse as a number: ", arguments[1], " for key ", option)
                return default
            end
        end

        return default
    end,

    --- Attempts to retrieve a table-like command line argument
    ---@param self UIAutolobbyArgumentsComponent | UIAutolobbyCommunications
    ---@param option string
    ---@return table<string, string>
    GetCommandLineArgumentArray = function(self, option)
        if not self:ValidCommandLineKey(option) then
            return {}
        end

        return import("/lua/system/utils.lua").GetCommandLineArgTable(option)
    end,
}
