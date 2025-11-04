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

--- Docks the air units that are considered to be too damaged for air engagements.
---@param ratio? number # number between 0.0 and 1.0, defaults to 0.9. All units with a health ratio lower are considered to be damaged
---@param clear? boolean # Defaults to false
function DockDamaged(ratio, clear)
    if clear == nil then clear = false end
    ratio = ratio or 0.9

    local gameMain = import("/lua/ui/game/gamemain.lua")
    local commandMode = import("/lua/ui/game/commandmode.lua")

    local selection = GetSelectedUnits()
    local dockableUnits = EntityCategoryFilterDown(categories.AIR - categories.CANNOTUSEAIRSTAGING, selection)
    local damaged = {}
    local damagedCount = 0

    for _, unit in dockableUnits do
        local health = unit:GetHealth()
        local maxHealth = unit:GetMaxHealth()

        local isDamagedSufficiently = health / maxHealth < ratio

        if isDamagedSufficiently then
            damagedCount = damagedCount + 1
            damaged[damagedCount] = unit
        end
    end

    if damagedCount > 0 then
        -- Since `IssueUnitCommand` does not work with docking orders, use the selection-only `IssueDockCommand` function
        -- prevents losing command mode
        if not clear then
            commandMode.CacheAndClearCommandMode()
        end
        gameMain.SetIgnoreSelection(true)

        SelectUnits(damaged)
        IssueDockCommand(clear)
        SelectUnits(selection)

        -- prevents losing command mode
        gameMain.SetIgnoreSelection(false)
        if not clear then
            commandMode.RestoreCommandMode(true)
        else
            commandMode.EndCommandMode(true)
        end

        -- inform user
        print(string.format("Docking %d units <%d%% HP", damagedCount, ratio * 100))
    else
        print(string.format("No units <%d%% HP to dock", ratio * 100))
    end
end
