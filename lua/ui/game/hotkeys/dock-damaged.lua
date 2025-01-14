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

local gameMain = import("/lua/ui/game/gamemain.lua")
local commandMode = import("/lua/ui/game/commandmode.lua")

--- Docks the air units that are considered to be too damaged for air engagements.
---@param ratio? number # number between 0.0 and 1.0, defaults to 0.25. All units with a health ratio lower is considered to be damaged
function DockDamaged(ratio)
    -- default to 25%
    ratio = ratio or 0.25

    local damaged = {}
    local remaining = {}

    local selection = GetSelectedUnits()
    for k = 1, table.getn(selection) do
        local unit = selection[k]
        local health = unit:GetHealth()
        local maxHealth = unit:GetMaxHealth()
        if health / maxHealth < ratio then
            table.insert(damaged, unit)
        else
            table.insert(remaining, unit)
        end
    end

    -- prevents losing command mode
    commandMode.CacheAndClearCommandMode()
    gameMain.SetIgnoreSelection(true)

    SelectUnits(damaged)
    IssueDockCommand(true)
    SelectUnits(remaining)

    -- prevents losing command mode
    gameMain.SetIgnoreSelection(false)
    commandMode.RestoreCommandMode(true)
end
