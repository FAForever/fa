--**********************************************************************************
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
--**********************************************************************************

-- upvalue scope for performance
local WARN = WARN

local StringFormat = string.format

---@class Observable<T>
---@field Name string
---@field Subjects table<string, fun(value: any)>
Subject = ClassSimple {

    ---@generic T
    ---@param self Observable
    ---@param name string
    __init = function(self, name)
        self.Name = name
        self.Subjects = {}
    end,

    --- Adds an observer.
    ---@generic T
    ---@param self Observable
    ---@param callback fun(entity: T)
    ---@param identifier string
    AddObserver = function(self, callback, identifier)
        if not type(identifier) == "string" then
            WARN(StringFormat("Invalid subject identifier %s for observable %s", tostring(identifier), self.Name))
            return
        end

        local oldSubject = self.Subjects[identifier]
        if oldSubject then
            WARN(StringFormat("Overwriting subject with identifier '%s' for observable '%s'", identifier, self.Name))
        end

        self.Subjects[identifier] = callback
    end,

    --- Removes an observer.
    ---@param self Observable
    ---@param identifier string
    RemoveObserver = function(self, identifier)
        if not type(identifier) == "string" then
            WARN(StringFormat("Invalid subject identifier %s for observable %s", tostring(identifier), self.Name))
            return
        end

        self.Subjects[identifier] = nil;
    end,

    ---
    ---@generic T
    ---@param self Observable
    ---@param value T
    Next = function(self, value)
        for k, callback in self.Listeners do
            callback(value)
        end
    end,
}
