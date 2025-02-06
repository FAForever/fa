--******************************************************************************************************
--** Copyright (c) 2025 FAForever
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

local TableInsert = table.insert
local TableGetn = table.getn

--- Docks the air units that are considered to be too damaged for air engagements.
---@param ratio? number # number between 0.0 and 1.0, defaults to 0.9. All units with a health ratio lower are considered to be damaged
---@param clear? boolean # Defaults to false
function DockDamaged(ratio, clear)
    if clear == nil then clear = false end
    ratio = ratio or 0.9

    local gameMain = import("/lua/ui/game/gamemain.lua")
    local commandMode = import("/lua/ui/game/commandmode.lua")

    local damaged = {}
    local remaining = {}

    local selection = GetSelectedUnits()
    for k = 1, TableGetn(selection) do
        local unit = selection[k]
        local health = unit:GetHealth()
        local maxHealth = unit:GetMaxHealth()

        local isAirUnit = EntityCategoryContains(categories.AIR, unit)
        local canUseAirStaging = not EntityCategoryContains(categories.CANNOTUSEAIRSTAGING, unit)
        local isDamagedSufficiently = health / maxHealth < ratio

        if isAirUnit and canUseAirStaging and isDamagedSufficiently then
            TableInsert(damaged, unit)
        else
            TableInsert(remaining, unit)
        end
    end

    -- Since `IssueUnitCommand` does not work with docking orders, use the selection-only `IssueDockCommand` function
    -- prevents losing command mode
    commandMode.CacheAndClearCommandMode()
    gameMain.SetIgnoreSelection(true)

    SelectUnits(damaged)
    IssueDockCommand(clear)
    SelectUnits(remaining)

    -- prevents losing command mode
    gameMain.SetIgnoreSelection(false)
    commandMode.RestoreCommandMode(true)

    -- inform user
    print(string.format("Docking %d units", TableGetn(damaged)))
end
