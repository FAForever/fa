
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

local AMissileSerpentine02Projectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile

--- Serpentine Missile 03 : XAS0306
---@class AIFMissileTactical03: AMissileSerpentine02Projectile
AIFMissileTactical03 = ClassProjectile(AMissileSerpentine02Projectile) {
    -- separate trajectory components to make it feel like a barrage
    LaunchTicks = 26,
    LaunchTicksRange = 10,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,
    HeightDistanceFactor = 5,
    MinHeight = 10,
    FinalBoostAngle = 45,

    TerminalZigZagMultiplier = 1.0,
}
TypeClass = AIFMissileTactical03

--- backwards compatibility
AIFMissileTactical02 = AIFMissileTactical03