-- Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.

function BOOLEAN(b)
	return b
end

function INTEGER(i)
	return i
end

function FLOAT(f)
	return f
end

function VECTOR2(x,y)
	return { x, y, type = 'VECTOR2' }
end

function VECTOR3(x,y,z)
	return { x, y, z, type = 'VECTOR3' }
end

function RECTANGLE(x0,y0,x1,y1)
	return { x0, y0, x1, y1, type = 'RECTANGLE' }
end

function STRING(s)
	return s
end

function GROUP(group)
	group.type = 'GROUP'
	return group
end
