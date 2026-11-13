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
local IsDestroyed = IsDestroyed
local TableGetn = table.getn
local MathMax = math.max

local UnitIsUnitState = moho.unit_methods.IsUnitState
local UnitGetGuardedUnit = moho.unit_methods.GetGuardedUnit
local UnitGetNavigator = moho.unit_methods.GetNavigator
local EntityGetPositionXYZ = moho.entity_methods.GetPositionXYZ

--- Aborts the initial assist move of the engineers that are in build range of the factory
---@param engineers Unit[] # modified in place
---@param factory Unit
function AbortNavigationOfFactoryAssisters(engineers, factory)
    local fx, _, fz = EntityGetPositionXYZ(factory)
    local facPhysics = factory.Blueprint.Physics
    local factorySize = MathMax(facPhysics.SkirtSizeX, facPhysics.SkirtSizeZ)

    local nEngis = TableGetn(engineers)
    local i = 1
    while i < nEngis do
        local engineer = engineers[i]
        if not IsDestroyed(engineer) then
            local guarded = UnitGetGuardedUnit(engineer)
            if guarded == factory
                and UnitIsUnitState(engineer, 'Guarding')
                and UnitIsUnitState(engineer, 'Moving')
                and not UnitIsUnitState(engineer, 'GuardBusy')
            then
                local blueprint = engineer.Blueprint
                local range = blueprint.Economy.MaxBuildDistance + blueprint.Footprint.SizeMax + factorySize
                local ex, _, ez = EntityGetPositionXYZ(engineer)
                local dx = ex - fx
                local dz = ez - fz
                if dx * dx + dz * dz <= range * range then
                    i = i + 1
                    continue
                end
            end
        end
        engineers[i] = engineers[nEngis]
        engineers[nEngis] = nil
        nEngis = nEngis - 1
    end

    if nEngis > 0 then
        import("/lua/sim/commands/abort-navigation.lua").AbortNavigation(engineers, true)
    end
end
