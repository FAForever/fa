-- from: https://gist.github.com/ColonelThirtyTwo/1735522#file-quaternions-lua

-- faster access to some math library functions
local abs   = math.abs
-- local Round = math.Round
local sqrt  = math.sqrt
local exp   = math.exp
local log   = math.log
local sin   = math.sin
local cos   = math.cos
local sinh  = math.sinh
local cosh  = math.cosh
local acos  = math.acos

local deg2rad = math.pi/180
local rad2deg = 180/math.pi

local delta = 0.0000001000000

Quaternion = {}
Quaternion.__index = Quaternion

---@param q number
---@param r number
---@param s number
---@param t number
---@return Quaternion
function Quaternion.new(q,r,s,t)
	return setmetatable({q,r,s,t},Quaternion)
end
local quat_new = Quaternion.new

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
local function qmul(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return quat_new(
		lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
		lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
		lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
	)
end
Quaternion.__mul = qmul

---@param q Quaternion
---@return Quaternion
local function qexp(q)
	local m = sqrt(q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	local u1, u2, u3 = 0, 0, 0
	if m ~= 0 then
		u1 = q[2]*sin(m)/m
		u2 = q[3]*sin(m)/m
		u3 = q[4]*sin(m)/m
	end
	local r = exp(q[1])
	return quat_new(r*cos(m), r*u1, r*u2, r*u3)
end

---@param q Quaternion
---@return Quaternion
local function qlog(q)
	local l = sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	if l == 0 then return { -1e+100, 0, 0, 0 } end
	local u2, u3, u4 = q[2]/l, q[3]/l, q[4]/l -- u1 is never used
	local a = acos(u[1])
	local m = sqrt(u2*u2 + u3*u3 + u4*u4)
	if abs(m) > delta then
		return quat_new( log(l), a*u2/m, a*u3/m, a*u4/m )
	else
		return quat_new( log(l), 0, 0, 0 )  --when m is 0, u[2], u[3] and u[4] are 0 too
	end
end
Quaternion.log = qlog

--- Converts <ang> to a quaternion
---@param pitch number
---@param yaw number
---@param roll number
---@return Quaternion
function Quaternion.fromAngle(pitch, yaw, roll)
	pitch = pitch*deg2rad*0.5
	yaw = yaw*deg2rad*0.5
	roll = roll*deg2rad*0.5
	local qr = {cos(roll), sin(roll), 0, 0}
	local qp = {cos(pitch), 0, sin(pitch), 0}
	local qy = {cos(yaw), 0, 0, sin(yaw)}
	return qmul(qy,qmul(qp,qr))
end

-- ---@param forward Vector
-- ---@param up Vector
-- ---@return Quaternion
-- function Quaternion.fromVectors(forward, up)
-- 	local x = forward
-- 	local z = up
-- 	local y = z:Cross(x):GetNormalized() --up x forward = left
	
-- 	local ang = x:Angle()
-- 	if ang.p > 180 then ang.p = ang.p - 360 end
-- 	if ang.y > 180 then ang.y = ang.y - 360 end
	
-- 	local yyaw = Vector(0,1,0)
-- 	yyaw:Rotate(Angle(0,ang.y,0))
	
-- 	local roll = acos(y:Dot(yyaw))*rad2deg
	
-- 	local dot = y:Dot(z)
-- 	if dot < 0 then roll = -roll end
	
-- 	local p, y, r = ang.p, ang.y, roll
-- 	p = p*deg2rad*0.5
-- 	y = y*deg2rad*0.5
-- 	r = r*deg2rad*0.5
-- 	local qr = {cos(r), sin(r), 0, 0}
-- 	local qp = {cos(p), 0, sin(p), 0}
-- 	local qy = {cos(y), 0, 0, sin(y)}
-- 	return qmul(qy,qmul(qp,qr))
-- end

--- Returns quaternion for rotation about axis <axis> by angle <ang>. If ang is left out, then it is computed as the magnitude of <axis>
-- function Quaternion.fromRotation(axis, ang)
-- 	-- if ang then
-- 	-- 	axis:Normalize()
-- 	-- 	local ang2 = ang*deg2rad*0.5
-- 	-- 	return quat_new( cos(ang2), axis.x*sin(ang2), axis.y*sin(ang2), axis.z*sin(ang2) )
-- 	-- else
-- 	-- 	local angSquared = axis:LengthSqr()
-- 	-- 	if angSquared == 0 then return quat_new( 1, 0, 0, 0 ) end
-- 	-- 	local len = sqrt(angSquared)
-- 	-- 	local ang = (len + 180) % 360 - 180
-- 	-- 	local ang2 = ang*deg2rad*0.5
-- 	-- 	local sang2len = sin(ang2) / len
-- 	-- 	return quat_new( cos(ang2), rv1[1] * sang2len , rv1[2] * sang2len, rv1[3] * sang2len )
-- 	-- end
-- end

---@return Quaternion
function Quaternion:__neg()
	return quat_new( -self[1], -self[2], -self[3], -self[4] )
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
function Quaternion.__add(lhs, rhs)
	return quat_new( lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3], lhs[4] + rhs[4] )
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
function Quaternion.__sub(lhs, rhs)
	return quat_new( lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4] )
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
function Quaternion.__mul(lhs, rhs)
	if type(rhs) == "number" then
		return quat_new( rhs * lhs[1], rhs * lhs[2], rhs * lhs[3], rhs * lhs[4] )
	elseif type(rhs) == "Vector" then
		local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
		local rhs2, rhs3, rhs4 = rhs.x, rhs.y, rhs.z
		return quat_new(
			-lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
			 lhs1 * rhs2 + lhs3 * rhs4 - lhs4 * rhs3,
			 lhs1 * rhs3 + lhs4 * rhs2 - lhs2 * rhs4,
			 lhs1 * rhs4 + lhs2 * rhs3 - lhs3 * rhs2
		)
	else
		local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
		local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
		return quat_new(
			lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
			lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
			lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
			lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
		)
	end
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
function Quaternion.__div(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	return quat_new(
		lhs1/rhs,
		lhs2/rhs,
		lhs3/rhs,
		lhs4/rhs
	)
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return Quaternion
function Quaternion.__pow(lhs, rhs)
	local l = qlog(lhs)
	return qexp({ l[1]*rhs, l[2]*rhs, l[3]*rhs, l[4]*rhs })
end

---@param lhs Quaternion
---@param rhs Quaternion
---@return boolean
function Quaternion.__eq(lhs, rhs)
	if getmetatable(lhs) ~= Quaternion or getmetatable(lhs) ~= getmetatable(rhs) then return false end
	local rvd1, rvd2, rvd3, rvd4 = lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4]
	return rvd1 <= delta and rvd1 >= -delta and
	   rvd2 <= delta and rvd2 >= -delta and
	   rvd3 <= delta and rvd3 >= -delta and
	   rvd4 <= delta and rvd4 >= -delta
end

--- Returns absolute value of self
---@return number
function Quaternion:abs()
	return sqrt(self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4])
end

--- Returns the conjugate of self
---@return Quaternion
function Quaternion:conj()
	return quat_new(self[1], -self[2], -self[3], -self[4])
end

--- Returns the inverse of self
---@return Quaternion
function Quaternion:inv()
	local l = self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4]
	return quat_new( self[1]/l, -self[2]/l, -self[3]/l, -self[4]/l )
end


--- Raises Euler's constant e to the power self
---@return Quaternion
function Quaternion:exp()
	return qexp(self)
end

--- Calculates natural logarithm of self
---@return Quaternion
function Quaternion:log()
	return qlog(self)
end

--- Changes quaternion <self> so that the represented rotation is by an angle between 0 and 180 degrees (by coder0xff)
---@return Quaternion?
function Quaternion:mod()
	if self[1]<0 then return quat_new(-self[1], -self[2], -self[3], -self[4]) else return quat_new(self[1], self[2], self[3], self[4]) end
end

--- Performs spherical linear interpolation between <q0> and <q1>. Returns <q0> for <t>=0, <q1> for <t>=1
---@param q0 Quaternion
---@param q1 Quaternion
---@param t number
---@return Quaternion
function Quaternion.slerp(q0, q1, t)
	local dot = q0[1]*q1[1] + q0[2]*q1[2] + q0[3]*q1[3] + q0[4]*q1[4]
	local q11
	if dot<0 then
		q11 = {-q1[1], -q1[2], -q1[3], -q1[4]}
	else
		q11 = { q1[1], q1[2], q1[3], q1[4] }  -- dunno if just q11 = q1 works
	end
	
	local l = q0[1]*q0[1] + q0[2]*q0[2] + q0[3]*q0[3] + q0[4]*q0[4]
	if l==0 then return { 0, 0, 0, 0 } end
	local invq0 = { q0[1]/l, -q0[2]/l, -q0[3]/l, -q0[4]/l }
	local logq = qlog(qmul(invq0,q11))
	local q = qexp( { logq[1]*t, logq[2]*t, logq[3]*t, logq[4]*t } )
	return qmul(q0,q)
end

--- Returns vector pointing forward for <self>
---@return Vector
function Quaternion:forward()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector (
		this1 * this1 + this2 * this2 - this3 * this3 - this4 * this4,
		t3 * this2 + t4 * this1,
		t4 * this2 - t3 * this1
	)
end

--- Returns vector pointing right for <self>
---@return Vector
function Quaternion:right()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector(
		t4 * this1 - t2 * this3,
		this2 * this2 - this1 * this1 + this4 * this4 - this3 * this3,
		- t2 * this1 - t3 * this4
	)
end

--- Returns vector pointing up for <self>
---@return Vector
function Quaternion:up()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return Vector(
		t3 * this1 + t2 * this4,
		t3 * this4 - t2 * this1,
		this1 * this1 - this2 * this2 - this3 * this3 + this4 * this4
	)
end

--- Returns the angle of rotation in degrees
---@return number
function Quaternion:rotationAngle()
	local l2 = self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4]
	if l2 == 0 then return 0 end
	local l = sqrt(l2)
	local ang = 2*acos(self[1]/l)*rad2deg  -- this returns angle from 0 to 360
	if ang > 180 then ang = ang - 360 end  -- make it -180 - 180
	return ang
end

--- Returns the axis of rotation
---@return Vector
function Quaternion:rotationAxis()
	local m2 = self[2] * self[2] + self[3] * self[3] + self[4] * self[4]
	if m2 == 0 then return Vector( 0, 0, 1 ) end
	local m = sqrt(m2)
	return Vector( self[2] / m, self[3] / m, self[4] / m)
end

--- Returns angle represented by <self>
---@return unknown
-- function Quaternion:toAngle()
-- 	local l = sqrt(self[1]*self[1]+self[2]*self[2]+self[3]*self[3]+self[4]*self[4])
-- 	local q1, q2, q3, q4 = self[1]/l, self[2]/l, self[3]/l, self[4]/l

-- 	local x = Vector(q1*q1 + q2*q2 - q3*q3 - q4*q4,
-- 		2*q3*q2 + 2*q4*q1,
-- 		2*q4*q2 - 2*q3*q1)

-- 	local y = Vector(2*q2*q3 - 2*q4*q1,
-- 		q1*q1 - q2*q2 + q3*q3 - q4*q4,
-- 		2*q2*q1 + 2*q3*q4)

-- 	local ang = x:Angle()
-- 	if ang.p > 180 then ang.p = ang.p - 360 end
-- 	if ang.y > 180 then ang.y = ang.y - 360 end

-- 	local yyaw = Vector(0,1,0)
-- 	yyaw:Rotate(Angle(0,ang.y,0))

-- 	local roll = acos(y:Dot(yyaw))*rad2deg

-- 	local dot = q2*q1 + q3*q4
-- 	if dot < 0 then roll = -roll end

-- 	return Angle(ang.p, ang.y, roll)
-- end

---@return string
function Quaternion:__tostring()
	return string.format("<%d,%d,%d,%d>",self[1],self[2],self[3],self[4])
end