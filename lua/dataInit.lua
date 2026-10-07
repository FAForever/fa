---@declare-global
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.

---@param b boolean
---@return boolean
function BOOLEAN(b)
	return b
end

---@param i number
---@return number
function INTEGER(i)
	return i
end

---@param f number
---@return number
function FLOAT(f)
	return f
end

--- A basic 2D vector defined in the scenario
---@class UIScenarioVector2
---@field [1] number # x
---@field [2] number # y
---@field type 'VECTOR2'

---@param x number
---@param y number
---@return UIScenarioVector2
function VECTOR2(x,y)
	return { x, y, type = 'VECTOR2' }
end

--- A basic 3D vector defined in the scenario
---@class UIScenarioVector
---@field [1] number # x
---@field [2] number # y
---@field [3] number # z
---@field type 'VECTOR3'

---@param x number
---@param y number
---@param z number
---@return UIScenarioVector
function VECTOR3(x,y,z)
	return { x, y, z, type = 'VECTOR3' }
end

--- A basic area defined in the scenario.
---@class UIScenarioArea
---@field [1] number    # x0
---@field [2] number    # z0
---@field [3] number    # x1
---@field [4] number    # z1
---@field type 'RECTANGLE'

---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@return UIScenarioArea
function RECTANGLE(x0,y0,x1,y1)
	return { x0, y0, x1, y1, type = 'RECTANGLE' }
end

---@param s string
---@return string
function STRING(s)
	return s
end

---@class UIScenarioGroup : table
---@field type 'GROUP'

---@param group table
---@return UIScenarioGroup
function GROUP(group)
	group.type = 'GROUP'
	return group
end
