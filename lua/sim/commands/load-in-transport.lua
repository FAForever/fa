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

local AveragePositionOfUnitsXZ = import("/lua/sim/commands/shared.lua").AveragePositionOfUnitsXZ
local SortUnitsByDistanceToPoint = import("/lua/sim/commands/shared.lua").SortUnitsByDistanceToPoint
local PointOnUnitCircle = import("/lua/sim/commands/shared.lua").PointOnUnitCircle

---@param unit Unit
---@return number   # small slots
---@return number   # medium slots
---@return number   # large slots
function GetAvailableTransportSlots(unit)
    local transportBlueprint = unit.Blueprint.Transport
    if transportBlueprint then
        -- try and decipher based on values added in FAForever
        local small = transportBlueprint.SlotsSmall
        local medium = transportBlueprint.SlotsMedium
        local large = transportBlueprint.SlotsLarge
        if small and medium and large then
            return small, medium, large
        end

        -- try and decipher based on engine values
        local class1Capacity = transportBlueprint.Class1Capacity
        local class2AttachSize = transportBlueprint.Class2AttachSize
        local class3AttachSize = transportBlueprint.Class3AttachSize
        if class1Capacity and class2AttachSize and class3AttachSize then
            return class1Capacity, math.floor(class1Capacity / class2AttachSize),
                math.floor(class1Capacity / class3AttachSize)
        end
    end

    return 0, 0, 0
end

---@param unit Unit
---@return number?  # small slots
---@return number?  # medium slots
---@return number?  # large slots
function GetTransportSlotRequirements(unit)
    local class = unit.Blueprint.Transport.TransportClass
    if class then
        if class == 1 then
            return 1, 0, 0
        elseif class == 2 then
            return 2, 1, 0
        else
            return 4, 2, 1
        end
    else
        return nil, nil, nil
    end
end

---@param a Unit
---@param b Unit
function SortByTransportCapacity(a, b)
    return (a.Blueprint.Transport.Class1Capacity or 0) > (b.Blueprint.Transport.Class1Capacity or 0)
end

---
---@param units Unit[]
---@param transports Unit
---@param clearCommands boolean     # if true, transport orders are applied immediately
---@param doPrint boolean           # if true, prints the number of units that are being transported
---@return Unit[]   # Units that are transported
---@return Unit[]   # Transports that are used
---@return Unit[]   # Remaining units that are not transported
---@return Unit[]   # Remaining transports that are not required
LoadIntoTransports = function(units, transports, clearCommands, doPrint)

    ---------------------------------------------------------------------------
    -- defensive programming

    if table.empty(units) then
        return {}, {}, units, transports
    end

    if table.empty(transports) then
        return {}, {}, units, transports
    end

    local brain = units[1]:GetAIBrain()

    ---------------------------------------------------------------------------
    -- clear existing orders

    if clearCommands then
        IssueClearCommands(units)
        IssueClearCommands(transports)
    end

    ---------------------------------------------------------------------------
    -- sort transports based on class

    local transportCount = table.getn(transports)

    -- determine total clamp count
    local totalNumberOfSmallClamps = 0
    local totalNumberOfMediumClamps = 0
    local totalNumberOfLargeClamps = 0
    for k = 1, transportCount do
        local transport = transports[k]
        local transportSmallClamps, transportMediumClamps, transportLargeClamps = GetAvailableTransportSlots(transport)
        totalNumberOfSmallClamps = totalNumberOfSmallClamps + transportSmallClamps
        totalNumberOfMediumClamps = totalNumberOfMediumClamps + transportMediumClamps
        totalNumberOfLargeClamps = totalNumberOfLargeClamps + transportLargeClamps
    end

    -- sort units by average transport position (nearest to furthest)
    local tcx, tcz = AveragePositionOfUnitsXZ(transports)
    SortUnitsByDistanceToPoint(units, tcx, tcz)

    -- sort transport by transport capacity (largest to smallest)
    table.sort(transports, SortByTransportCapacity)

    ---------------------------------------------------------------------------
    -- load units into transports

    local isLoaded = {}
    local transportedUnits = {}
    local transportsUsed = {}
    local remainingTransports = {}
    local remainingTech3Units = EntityCategoryFilterDown(categories.TECH3, units)
    local remainingTech3UnitCount = table.getn(remainingTech3Units)
    local remainingTech2Units = EntityCategoryFilterDown(categories.TECH2, units)
    local remainingTech2UnitCount = table.getn(remainingTech2Units)
    local remainingTech1Units = EntityCategoryFilterDown(categories.TECH1, units)
    local remainingTech1UnitCount = table.getn(remainingTech1Units)

    local unitsToLoadTech3Head = 1
    local unitsToLoadTech3 = {}
    local unitsToLoadTech2Head = 1
    local unitsToLoadTech2 = {}
    local unitsToLoadTech1Head = 1
    local unitsToLoadTech1 = {}

    -- start loading in units
    for t = 1, transportCount do
        -- find units to attach
        local transport = transports[t]
        local transportSmallClamps, transportMediumClamps, transportLargeClamps = GetAvailableTransportSlots(transport)

        do -- process tech 3 units

            -- clear previous cargo
            for k = 1, unitsToLoadTech3Head do
                unitsToLoadTech3[k] = nil
            end
            unitsToLoadTech3Head = 1

            for u = 1, remainingTech3UnitCount do
                if (transportSmallClamps <= 0) or (transportMediumClamps <= 0) or (transportLargeClamps <= 0) then
                    break
                end

                local canLoad = false
                local unit = remainingTech3Units[u]
                local unitSmallClamps, unitMediumClamps, unitLargeClamps = GetTransportSlotRequirements(unit)
                if (unitLargeClamps > 0) and (transportLargeClamps >= unitLargeClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - unitLargeClamps
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitMediumClamps > 0) and (transportMediumClamps >= unitMediumClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.5 * unitMediumClamps)
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitSmallClamps > 0) and (transportSmallClamps >= unitSmallClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.25 * unitSmallClamps)
                    transportMediumClamps = transportMediumClamps - (0.5 * unitSmallClamps)
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                end

                if canLoad then
                    isLoaded[unit.EntityId] = true
                    unitsToLoadTech3[unitsToLoadTech3Head] = unit
                    unitsToLoadTech3Head = unitsToLoadTech3Head + 1
                end
            end

            -- cleanup list of units
            local unitsHead = 1
            for k = 1, remainingTech3UnitCount do
                local unit = remainingTech3Units[k]
                if not isLoaded[unit.EntityId] then
                    remainingTech3Units[unitsHead] = unit
                    unitsHead = unitsHead + 1
                end
            end

            for k = unitsHead, remainingTech3UnitCount do
                remainingTech3Units[k] = nil
            end

            remainingTech3UnitCount = unitsHead - 1
        end

        do -- process tech 2 units

            -- clear previous cargo
            for k = 1, unitsToLoadTech2Head do
                unitsToLoadTech2[k] = nil
            end
            unitsToLoadTech2Head = 1

            for u = 1, remainingTech2UnitCount do
                if (transportSmallClamps <= 0) or (transportMediumClamps <= 0) then
                    break
                end

                local canLoad = false
                local unit = remainingTech2Units[u]
                local unitSmallClamps, unitMediumClamps, unitLargeClamps = GetTransportSlotRequirements(unit)
                if (unitLargeClamps > 0) and (transportLargeClamps >= unitLargeClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - unitLargeClamps
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitMediumClamps > 0) and (transportMediumClamps >= unitMediumClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.5 * unitMediumClamps)
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitSmallClamps > 0) and (transportSmallClamps >= unitSmallClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.25 * unitSmallClamps)
                    transportMediumClamps = transportMediumClamps - (0.5 * unitSmallClamps)
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                end

                if canLoad then
                    isLoaded[unit.EntityId] = true
                    unitsToLoadTech2[unitsToLoadTech2Head] = unit
                    unitsToLoadTech2Head = unitsToLoadTech2Head + 1
                end
            end

            -- cleanup list of units
            local unitsHead = 1
            for k = 1, remainingTech2UnitCount do
                local unit = remainingTech2Units[k]
                if not isLoaded[unit.EntityId] then
                    remainingTech2Units[unitsHead] = unit
                    unitsHead = unitsHead + 1
                end
            end

            for k = unitsHead, remainingTech2UnitCount do
                remainingTech2Units[k] = nil
            end

            remainingTech2UnitCount = unitsHead - 1
        end

        do -- process tech 1 units

            -- clear previous cargo
            for k = 1, unitsToLoadTech1Head do
                unitsToLoadTech1[k] = nil
            end
            unitsToLoadTech1Head = 1

            for u = 1, remainingTech1UnitCount do
                if (transportSmallClamps <= 0) then
                    break
                end

                local canLoad = false
                local unit = remainingTech1Units[u]
                local unitSmallClamps, unitMediumClamps, unitLargeClamps = GetTransportSlotRequirements(unit)
                if (unitLargeClamps > 0) and (transportLargeClamps >= unitLargeClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - unitLargeClamps
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitMediumClamps > 0) and (transportMediumClamps >= unitMediumClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.5 * unitMediumClamps)
                    transportMediumClamps = transportMediumClamps - unitMediumClamps
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                elseif (unitSmallClamps > 0) and (transportSmallClamps >= unitSmallClamps) then
                    canLoad = true
                    transportLargeClamps = transportLargeClamps - (0.25 * unitSmallClamps)
                    transportMediumClamps = transportMediumClamps - (0.5 * unitSmallClamps)
                    transportSmallClamps = transportSmallClamps - unitSmallClamps
                end

                if canLoad then
                    isLoaded[unit.EntityId] = true
                    unitsToLoadTech1[unitsToLoadTech1Head] = unit
                    unitsToLoadTech1Head = unitsToLoadTech1Head + 1
                end
            end

            -- cleanup list of units
            local unitsHead = 1
            for k = 1, remainingTech1UnitCount do
                local unit = remainingTech1Units[k]
                if not isLoaded[unit.EntityId] then
                    remainingTech1Units[unitsHead] = unit
                    unitsHead = unitsHead + 1
                end
            end

            for k = unitsHead, remainingTech1UnitCount do
                remainingTech1Units[k] = nil
            end

            remainingTech1UnitCount = unitsHead - 1
        end

        -- load in units. Units that can not load in immediately but are supposed to load in together are ordered to gather to prepare
        if (unitsToLoadTech3Head > 1) or (unitsToLoadTech2Head) or (unitsToLoadTech1Head > 1) then
            if unitsToLoadTech3Head > 1 then
                -- keep track of units that we're transporting
                for k = 1, unitsToLoadTech3Head - 1 do
                    table.insert(transportedUnits, unitsToLoadTech3[k])
                end

                IssueTransportLoad(unitsToLoadTech3, transport)
            end

            -- load tech 2, gather if we're also loading tech 3
            if unitsToLoadTech2Head > 1 then
                if unitsToLoadTech3Head > 1 then
                    local cx, cz = AveragePositionOfUnitsXZ(unitsToLoadTech2)
                    for k, unit in unitsToLoadTech2 do
                        local point = PointOnUnitCircle(cx, cz, unitsToLoadTech2Head,
                            (k / (unitsToLoadTech2Head - 1)) * 360)
                        unit:GetNavigator():SetGoal(point)

                        -- keep track of units that we're transporting
                        table.insert(transportedUnits, unit)
                    end
                end

                -- keep track of units that we're transporting
                for k = 1, unitsToLoadTech2Head - 1 do
                    table.insert(transportedUnits, unitsToLoadTech2[k])
                end

                IssueTransportLoad(unitsToLoadTech2, transport)
            end

            -- load tech 1, gather if we're also loading tech 2 or tech 3
            if unitsToLoadTech1Head > 1 then
                if (unitsToLoadTech3Head > 1) or (unitsToLoadTech2Head > 1) then
                    local cx, cz = AveragePositionOfUnitsXZ(unitsToLoadTech1)
                    for k, unit in unitsToLoadTech1 do
                        local point = PointOnUnitCircle(cx, cz, unitsToLoadTech1Head + 4,
                            (k / (unitsToLoadTech1Head - 1)) * 360)
                        unit:GetNavigator():SetGoal(point)

                        -- keep track of units that we're transporting
                        table.insert(transportedUnits, unit)
                    end
                end

                -- keep track of units that we're transporting
                for k = 1, unitsToLoadTech1Head - 1 do
                    table.insert(transportedUnits, unitsToLoadTech1[k])
                end

                IssueTransportLoad(unitsToLoadTech1, transport)
            end

            -- keep track of the transports that we're using
            table.insert(transportsUsed, transport)
        else
            table.insert(remainingTransports, transport)
        end
    end

    ---------------------------------------------------------------------------
    -- inform user and observers

    if doPrint and (GetFocusArmy() == brain:GetArmyIndex()) then
        print(string.format("Loading %d units into %d transports", table.getn(transportedUnits), table.getn(transportsUsed)))
    end

    local remainingUnits = table.concatenate(remainingTech3Units, remainingTech2Units, remainingTech1Units)
    return transportedUnits, transportsUsed, remainingUnits, remainingTransports
end
