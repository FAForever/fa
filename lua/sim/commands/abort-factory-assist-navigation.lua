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

-- Based on the InstantAssist UI mod by 4z0t (FAF-UI-Mods, MIT)

-- upvalue scope for performance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local IsDestroyed = IsDestroyed
local TableGetn = table.getn
local MathMax = math.max
local MathCeil = math.ceil

local UnitIsUnitState = moho.unit_methods.IsUnitState
local UnitGetGuardedUnit = moho.unit_methods.GetGuardedUnit
local UnitGetNavigator = moho.unit_methods.GetNavigator
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ

--- Number of passes, one per tick, that look for engineers that started their assist move
local MaximumPasses = 3

--- Returns the size of the factory that is used for the build range check
---@param blueprint UnitBlueprint
---@return number
local function GetFactorySize(blueprint)
    -- naval factories have no footprint size. The engine then uses the rounded up unit size
    local footprint = blueprint.Footprint
    local sizeX, sizeZ = footprint.SizeX, footprint.SizeZ
    if sizeX and sizeZ then
        return MathMax(sizeX, sizeZ)
    end

    return MathMax(MathCeil(blueprint.SizeX or 1), MathCeil(blueprint.SizeZ or 1))
end

--- Aborts the initial assist move of the engineers that are in build range of the factory
---@param engineers Unit[]  # modified in place
---@param factory Unit
local function AbortNavigationOfFactoryAssistersThread(engineers, factory)
    -- An engineer that guards a factory first moves to a reserved spot around it, even when it is in range. The guard
    -- task sets the navigator goal in the unit command stage of a tick, before sim Lua threads run, so the first pass
    -- runs in the same tick. The repair task's own move into range sets GuardBusy and is never aborted

    -- The range uses footprints, which is more conservative than the engine's skirt based check. An aborted engineer
    -- that is out of range walks straight into range instead of to its reserved spot
    local fx, _, fz = EntityGetPositionXYZ(factory)
    local factorySize = GetFactorySize(factory.Blueprint)
    local pendingCount = TableGetn(engineers)

    for pass = 1, MaximumPasses do
        if pass > 1 then
            WaitTicks(1)
            if IsDestroyed(factory) then
                return
            end
        end

        local collected = nil
        local collectedCount = 0
        local remaining = 0
        for k = 1, pendingCount do
            local engineer = engineers[k]
            engineers[k] = nil
            if (not IsDestroyed(engineer)) and UnitGetNavigator(engineer) then
                local guarded = UnitGetGuardedUnit(engineer)
                if guarded == factory and
                    UnitIsUnitState(engineer, 'Guarding') and
                    UnitIsUnitState(engineer, 'Moving') and
                    not UnitIsUnitState(engineer, 'GuardBusy')
                then
                    local blueprint = engineer.Blueprint
                    local range = (blueprint.Economy.MaxBuildDistance or 5) + blueprint.Footprint.SizeMax + factorySize
                    local ex, _, ez = EntityGetPositionXYZ(engineer)
                    local dx = ex - fx
                    local dz = ez - fz
                    if dx * dx + dz * dz <= range * range then
                        collected = collected or {}
                        collectedCount = collectedCount + 1
                        collected[collectedCount] = engineer
                    end
                elseif (not guarded) or guarded == factory then
                    -- the guard task has not started its move yet
                    remaining = remaining + 1
                    engineers[remaining] = engineer
                end
            end
        end
        pendingCount = remaining

        if collected then
            import("/lua/sim/commands/abort-navigation.lua").AbortNavigation(collected, false)
        end

        if pendingCount == 0 then
            return
        end
    end
end

--- Aborts the initial assist move of the engineers that are in build range of the factory. Checks for a few ticks, as
--- the guard order may start a tick after this is called
---@param engineers Unit[]  # modified in place
---@param factory Unit
function AbortNavigationOfFactoryAssisters(engineers, factory)
    ForkThread(AbortNavigationOfFactoryAssistersThread, engineers, factory)
end
