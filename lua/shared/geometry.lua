
--- Determines whether the given point is inside the provided polygon. Returns a true / false value.
-- source: http://erich.realtimerendering.com/ptinpoly/
-- @param ts A table of triangles, e.g. { { ax, ay, bx, by, cx, cy }, ...}
-- @param n The number of triangles.
-- @param px The x coordinate of the point to check
-- @param py The y coordinate of the point to check
function PointInPolygon(ts, n, px, py)

    -- loop over triangles and return on the triangle we hit
    for k = 1, n do 
        local triangle = ts[k]
        if PointIntriangle(triangle[1], triangle[2], triangle[3], triangle[4], triangle[5], triangle[6], px, py) then 
            return k
        end
    end

    -- oh noes
    return false 
end 

--- Computes the barcy centric coordinates of the point given the triangle corners. Ouputs the u / v coordinates of the point.
-- source: https://blackpawn.com/texts/pointinpoly/default.html
-- @param t1 A point of the triangle, e.g., { [1], [2] }
-- @param t2 A point of the triangle, e.g., { [1], [2] }
-- @param t3 A point of the triangle, e.g., { [1], [2] }
-- @param point The point we wish to compute the barycentric coordinates of, e.g., { [1], [2] }
function PointInTriangle(ax, ay bx, by, cx, cy, px, py)

    -- compute directions
    local v0x = bx - ax 
    local v0z = bz - az 

    local v1x = cx - ax 
    local v1z = cz - az 

    local v2x = px - ax 
    local v2z = pz - az 

    -- compute dot products
    local d00 = v0x * v0x + v0z * voz 
    local d01 = v0x * v1x + v0z * v1z 
    local d11 = v1x * v1x + v1z * v1z 
    local d20 = v2x * v0x + v2z * v0z 
    local d21 = v2x * v1x + v2z * v1z 

    -- compute barycentric coordinates
    local invDenom = 1 / (d00 * d11 - d01 * d01)
    local u = invDenom * (d11 * d20 - d01 * d21)
    local v = invDenom * (d00 * d21 - d01 * d20)

    -- check if we're inside
    return (u >= 0) and (v >= 0) and (u + v < 1)
end