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

-- upvalue for performance
local TablEmpty = table.empty
local TableGetn = table.getn
local StringFormat = string.format

local LOC = LOC
local print = print
local tostring = tostring
local ForkThread = ForkThread
local GetRolloverInfo = GetRolloverInfo
local GetUnitCommandDataOfUnit = GetUnitCommandDataOfUnit
local EntityCategoryGetUnitList = EntityCategoryGetUnitList
local IssueBlueprintCommandToUnit = IssueBlueprintCommandToUnit

local TechCategoryToReadable = {
    TECH1 = '(Tech 1)',
    TECH2 = '(Tech 2)',
    TECH3 = '(Tech 3)',
    EXPERIMENTAL = '(Experimental)'
}

---@param unit UserUnit
local function UpgradePauseThread(unit)
    WaitTicks(2)
    if not IsDestroyed(unit) and unit:GetArmy() == GetFocusArmy() then
        SetPausedOfUnit(unit, true)
    end
end

--- Retrieves a list of buildable upgrades for the given unit
---@param unit UserUnit
---@return UnitId[]
function GetUpgradesOfUnit(unit)
    local _, _, buildableCategories = GetUnitCommandDataOfUnit(unit)
    local buildableStructures = EntityCategoryGetUnitList(buildableCategories * categories.STRUCTURE)
    return buildableStructures
end

--- Attempts to issue an upgrade order to the unit we're hovering over. Favors upgrading to support factories when possible
function UpgradeStructure(pause)
    local unit = GetRolloverInfo().userUnit
    if unit then
        local buildableStructures = GetUpgradesOfUnit(unit)
        if buildableStructures and not TablEmpty(buildableStructures) then
            local targetBlueprint = buildableStructures[1]

            -- try and build support factories when possible
            if unit:IsInCategory('FACTORY') then
                if TableGetn(buildableStructures) > 1 then
                    targetBlueprint = buildableStructures[2]
                end
            end

            -- issue the upgrade and inform the user
            local otherBlueprint = __blueprints[targetBlueprint] --[[@as UnitBlueprint]]
            IssueBlueprintCommandToUnit(unit, 'UNITCOMMAND_Upgrade', targetBlueprint, 1, false)
            print(
                StringFormat(
                    "Upgrading to %s %s",
                    LOC(tostring(otherBlueprint.Description)),
                    tostring(TechCategoryToReadable[otherBlueprint.TechCategory] or "")
                )
            )

            -- paused units do not start upgrading, temporarily unpause
            if (GetIsPausedOfUnit(unit) or pause) and (not unit:GetFocus()) then
                SetPausedOfUnit(unit, false)
                ForkThread(UpgradePauseThread, unit)
            end
        else
            local blueprint = unit:GetBlueprint()
            print(StringFormat("Unable to upgrade %s", LOC(tostring(blueprint.Description))))
        end
    else
        print("No structure to upgrade")
    end
end
