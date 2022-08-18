
---@class Triangle
---@field [1] number x1
---@field [2] number y1
---@field [3] number x2
---@field [4] number y2
---@field [5] number x3
---@field [6] number y3

---@class Rectangle
---@field [1] number x1
---@field [2] number y1
---@field [3] number x2
---@field [4] number y2

--- Computes the barycentric coordinates of the point given the triangle corners. Ouputs the u / v coordinates of the point.
--- source: https://blackpawn.com/texts/pointinpoly/default.html
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param px number
---@param py number
---@return boolean
function PointInTriangle(x1, y1, x2, y2, x3, y3, px, py)
    -- compute directions
    local v0x = x2 - x1
    local v0y = y2 - y1

    local v1x = x3 - x1
    local v1y = y3 - y1

    local v2x = px - x1
    local v2y = py - y1

    -- compute dot products
    local d00 = v0x * v0x + v0y * v0y
    local d01 = v0x * v1x + v0y * v1y
    local d11 = v1x * v1x + v1y * v1y
    local d20 = v2x * v0x + v2y * v0y
    local d21 = v2x * v1x + v2y * v1y

    -- compute barycentric coordinates
    local invDenom = 1 / (d00 * d11 - d01 * d01)
    local u = invDenom * (d11 * d20 - d01 * d21)
    local v = invDenom * (d00 * d21 - d01 * d20)

    -- check if we're inside
    return (u >= 0) and (v >= 0) and (u + v < 1)
end

function PointInRectangle(x1, y1, x2, y2, px, py)
    return x1 <= px and px <= x2
       and y1 <= py and py <= y2
end

function PointInCircle(cx, cy, rad, px, py)
    local x, y = cx - px, cy - py
    return x*x + y*y <= rad*rad
end


function RectanglesCollide(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
    return ax1 < bx2 and bx1 < ax2
       and ay1 < by2 and by1 < ay2
end



--- Determines whether the given point is inside the provided polygon. Returns a true / false value.
--- source: http://erich.realtimerendering.com/ptinpoly/
---@param ts Triangle[] A table of triangles, e.g. { { ax, ay, bx, by, cx, cy }, ...}
---@param n  number The number of triangles
---@param px number The x coordinate of the point to check
---@param py number The y coordinate of the point to check
function PointInPolygon(ts, n, px, py)
    -- loop over triangles and return on the triangle we hit
    for k = 1, n do
        local triangle = ts[k]
        if PointInTriangle(triangle[1], triangle[2], triangle[3], triangle[4], triangle[5], triangle[6], px, py) then
            return k
        end
    end

    -- oh noes
    return 0
end

function PointInTriangleFan(xList, yList, n, px, py)
    -- loop over triangles and return on the triangle we hit
    local x1, x2 = xList[1], xList[2]
    local y1, y2 = yList[1], yList[2]
    for k = 3, n, 2 do
        local x3, y3 = xList[k], yList[k]
        if PointInTriangle(x1, y1, x2, y2, x3, y3, px, py) then
            return k - 2
        end
        x1, y1, x2, y2 = x2, y2, x3, y3
    end
    return 0
end

function PointInQuad(x1, y1, x2, y2, x3, y3, x4, y4, px, py)
    return PointInTriangle(x1, y1, x2, y2, x3, y3, px, py)
        or PointInTriangle(x2, y2, x3, y3, x4, y4, px, py)
end