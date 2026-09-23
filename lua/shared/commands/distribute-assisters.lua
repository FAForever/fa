--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

local OnlySupportCategory = categories.ALLUNITS
    -- Exclude armed support-capable units such as Monkeylords and Fatboys.
    - categories.DIRECTFIRE
    - categories.INDIRECTFIRE
    - categories.ANTIAIR
    - categories.ANTINAVY
    -- Air weapons use separate attack categories.
    - categories.GROUNDATTACK
    - categories.STRATEGICBOMBER
    - categories.BOMBER
    -- Exclude continental transports.
    - categories.TRANSPORTATION

---@type EntityCategory
AssisterCategory = (
    categories.SCOUT * categories.LAND
    + categories.MOBILE * OnlySupportCategory * (
        categories.SHIELD
        + categories.COUNTERINTELLIGENCE * categories.OVERLAYCOUNTERINTEL
    )
)
    - categories.DUMMYUNIT
    - categories.INSIGNIFICANTUNIT
    - categories.UNSELECTABLE

--- Separates a selection into eligible assisters and assist targets.
---@param selection Unit[] | UserUnit[]
---@return Unit[] | UserUnit[] assisters
---@return Unit[] | UserUnit[] targets
function GetAssistersAndTargets(selection)
    local assisters = EntityCategoryFilterDown(AssisterCategory, selection)
    local targets = EntityCategoryFilterDown(categories.ALLUNITS - AssisterCategory, selection)

    return assisters, targets
end
