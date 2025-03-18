--**********************************************************************************
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
--**********************************************************************************

---@alias AbsorptionType
---| "Default"
---| "StaticShield"

--- Defines what proportion of damage a shield of `AbsorptionType` absorbs from a specific `DamageType`
--- Overrides the behavior of shields absorbing damage depending on their owner's armor type
---@type table<AbsorptionType, table<DamageType, number>>
shieldAbsorptionValues = {
	["Default"] = {
		["Deathnuke"] = 0.0,
		["Overcharge"] = 1.0,
	},
	["StaticShield"] = { -- For mod support, auto-assigned if the owner has STRUCTURE category.
		["Deathnuke"] = 1.0,
		["Overcharge"] = 1.0,
	},
}
