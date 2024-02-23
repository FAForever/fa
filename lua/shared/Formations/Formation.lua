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

--- A list of formation positions. The number of entries represents the number of units in the formation.
---@alias Formation FormationEntry[]

--- We do not assign a formation position to a specific unit. Instead, we define an offset 
--- and which categories a units needs to satisfy to occupy that location. 
---@class FormationEntry
---@field [1] number            # x offset
---@field [2] number            # z offset
---@field [3] EntityCategory    # categories of the unit that can occupy this position
---@field [4] number            # formation delay, is floored and therefore decimal values are meaningless. All units of a given number will move at once, starting at 0
---@field [5] boolean           # flag whether rotation matters for this position

---@type FormationEntry[]
local TacticalFormationEntries = { }

--- Retrieves a (cached) formation entry.
---@param index number
---@return FormationEntry
GetFormationEntry = function(index)
    local formationEntry = TacticalFormationEntries[index]
    if not formationEntry then
        formationEntry = { 
            0, 0, categories.ALLUNITS, 0, false
        }
        TacticalFormationEntries[index] = formationEntry
    end

    return formationEntry
end