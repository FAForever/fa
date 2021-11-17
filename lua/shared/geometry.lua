
--- Determines whether the given point is inside the provided polygon. Returns a true / false value.
-- @param polygon A table of tables with edge coordinates, e.g., { {x1, ... xn}, {y1 ... yn} }.
-- @param point A point, e.g., { [1], [2], [3] }.
function PointInPolygon(polygon, point)
    return false 
end 

--- Computes the barcy centric coordinates of the point given the triangle corners. Ouputs the u / v coordinates of the point.
-- source: https://gamedev.stackexchange.com/questions/23743/whats-the-most-efficient-way-to-find-barycentric-coordinates
-- @param t1 A point of the triangle, e.g., { [1], [2], [3] }
-- @param t2 A point of the triangle, e.g., { [1], [2], [3] }
-- @param t3 A point of the triangle, e.g., { [1], [2], [3] }
-- @param point The point we wish to compute the barycentric coordinates of, e.g., { [1], [2], [3] }
function ComputeBarycentricCoordinates(t1, t2, t3, point)

    -- retrieve data from tables
    local t1x = t1[1]
    local t1z = t1[3]

    local t2x = t2[1]
    local t2z = t2[3]

    local t3x = t3[1]
    local t3z = t3[3]

    local px = point[1]
    local pz = point[3]

    -- compute directions
    local v0x = t2x - t1x 
    local v0z = t2z - t1z 

    local v1x = t3x - t1x 
    local v1z = t3z - t1z 

    local v2x = px - t1x 
    local v2z = pz - t1z 

    local d00 = v0x * v0x + v0z * voz 
    local d01 = v0x * v1x + v0z * v1z 
    local d11 = v1x * v1x + v1z * v1z 
    local d20 = v2x * v0x + v2z * v0z 
    local d21 = v2x * v1x + v2z * v1z 

    local denom = d00 * d11 - d01 * d01

    local v = (d11 * d20 - d01 * d21) / denom
    local w = (d00 * d21 - d01 * d20) / denom
    local u = 1.0 - v - w 

    return u, v, w
end