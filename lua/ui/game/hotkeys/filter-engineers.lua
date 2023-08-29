
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

--- Filters your selection to the highest tech of engineers. All other engineers assist one of those engineers.
function SelectHighestEngineerAndAssist()
    local selection = GetSelectedUnits()

    if selection then

        local tech2 = EntityCategoryFilterDown(categories.TECH2 - categories.COMMAND, selection)
        local tech3 = EntityCategoryFilterDown(categories.TECH3 - categories.COMMAND, selection)
        local sACUs = EntityCategoryFilterDown(categories.SUBCOMMANDER - categories.COMMAND, selection)

        if next(sACUs) then
            SimCallback({ Func = 'SelectHighestEngineerAndAssist', Args = { TargetId = sACUs[1]:GetEntityId() } }, true)
            SelectUnits(sACUs)
        elseif next(tech3) then
            SimCallback({ Func = 'SelectHighestEngineerAndAssist', Args = { TargetId = tech3[1]:GetEntityId() } }, true)
            SelectUnits(tech3)
        elseif next(tech2) then
            SimCallback({ Func = 'SelectHighestEngineerAndAssist', Args = { TargetId = tech2[1]:GetEntityId() } }, true)
            SelectUnits(tech2)
        else
            -- do nothing
        end
    end
end