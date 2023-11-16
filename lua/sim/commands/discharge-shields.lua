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

-- upvalue scope for performance
local TableGetn = table.getn
local MathMin = math.min
local StringFormat = string.format

local CElectronBurstCloud01 = import("/lua/EffectTemplates.lua").CElectronBurstCloud01

--- Discharges the shields of the provided units
---@param units Unit[]
---@param doPrint boolean           # if true, prints information about the order
function DischargeShields(units, doPrint)
    local unitCount = TableGetn(units)

    if unitCount == 0 then
        return
    end

    local dischargedUnits = 0

    for k = 1, unitCount do
        local unit = units[k]
        if not IsDestroyed(unit) then
            local shield = unit.MyShield
            if shield and shield:IsOn() then
                local shieldHealth = shield:GetHealth()
                shield:ApplyDamage(nil, shieldHealth, unit:GetPosition(), 'Discharge', false)

                local army = unit.Army
                local bone = unit.ShieldEffectsBone or -1
                local blueprint = unit.Blueprint
                local size = MathMin(blueprint.SizeX, blueprint.SizeZ)

                -- particle effect with sparkles
                for _, effect in CElectronBurstCloud01 do
                    local effect = CreateEmitterAtBone(unit, bone, army, effect)
                    effect:ScaleEmitter(0.75 * size)
                end

                -- light particle for bloom effect
                CreateLightParticleIntel(unit, bone, army, 1.5 * size, 8, 'glow_02', 'ramp_flare_02')

                dischargedUnits = dischargedUnits + 1
            end
        end
    end

    local brain = units[1]:GetAIBrain()
    if doPrint and (GetFocusArmy() == brain:GetArmyIndex()) then
        print(StringFormat("Discharged %s shield(s)", dischargedUnits))
    end
end
