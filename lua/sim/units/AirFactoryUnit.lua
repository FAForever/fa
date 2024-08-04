--**********************************************************************************
--** Copyright (c) 2023 FAForever
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

local FactoryUnit = import("/lua/sim/units/factoryunit.lua").FactoryUnit
local IssueOrderQueue = import("/lua/sim/commands/copy-queue.lua").IssueOrderQueue

---Because the rally point orders are applied after 1 tick, we need
---to wait 1 tick before clearing them and adding our own
---@param transport AirTransport
---@param unitToLoad Unit
local AutoLoadThread = function(transport, unitToLoad)
    WaitTicks(1)
    if transport.Dead or unitToLoad.Dead then
        return
    end
    local rallyQueue = transport:GetCommandQueue()
    IssueClearCommands({transport, unitToLoad})
    IssueTransportLoad({unitToLoad}, transport)
    IssueOrderQueue({transport}, rallyQueue)
end

---@class AirFactoryUnit : FactoryUnit
AirFactoryUnit = ClassUnit(FactoryUnit) {

    ---@param self AirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        FactoryUnit.OnStopBuild(self, unitBeingBuilt, order)
        if EntityCategoryContains(categories.TRANSPORTATION, unitBeingBuilt) then
            local guards = EntityCategoryFilterDown(categories.MOBILE * categories.LAND - categories.ENGINEER, self:GetGuards())
            if not table.empty(guards) then
                local unitToBeLoaded = guards[1]
                ForkThread(AutoLoadThread, unitBeingBuilt, unitToBeLoaded)
                --IssueTransportLoad({unitToBeLoaded}, unitBeingBuilt)
            end
        end
    end,
}