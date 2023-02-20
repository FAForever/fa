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

---@param x number
---@param y number
---@return Vector2
function VECTOR2(x,y)
	return { x, y, type = 'VECTOR2' }
end

---@param x number
---@param y number
---@param z number
---@return Vector
function VECTOR3(x,y,z)
	return { x, y, z, type = 'VECTOR3' }
end

---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@return table
function RECTANGLE(x0,y0,x1,y1)
	return { x0, y0, x1, y1, type = 'RECTANGLE' }
end

---@param s string
---@return string
function STRING(s)
	return s
end

---@param group Group
---@return table
function GROUP(group)
	group.type = 'GROUP'
	return group
end
