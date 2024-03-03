--******************************************************************************************************
--** Copyright (c) 2024 IL1I1
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

-- All functions in this file (inside /lua/shared) should be:
-- - pure: they should only use the arguments provided, do not touch any global state.
-- - sim / ui proof: they should work for both sim code and ui code.

--- Formula to compute the energy and time cost of capturing.
---@param blueprint UnitBlueprint
---@param number buildRate
---@return number time
---@return number energy
GetBlueprintCaptureCost = function(blueprint, buildRate)
    local blueprintEconomy = blueprint.Economy
    
    local time = ((blueprintEconomy.BuildTime or 10) / buildRate) / 2
    local energy = blueprintEconomy.BuildCostEnergy or 100
    if time < 0 then
        time = 0.1
    end

    return time, energy
end
