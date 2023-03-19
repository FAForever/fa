
local tl = { 0, 0, 0 }
local tr = { 0, 0, 0 }
local bl = { 0, 0, 0 }
local br = { 0, 0, 0 }

---@class AIGridCell
---@field Identifier string
---@field X number
---@field Z number

---@class AIGrid
---@field Cells table[][]
---@field CellCount number
---@field CellSize number
Grid = ClassSimple {

    ---@param self AIGrid
    __init = function(self)
        local cellCount = 16
        local mx = ScenarioInfo.size[1]
        local mz = ScenarioInfo.size[2]

        -- smaller maps have 8x8 iMAP setup
        if mx == mz and mx == 256 then
            cellCount = 8
        end

        local cells = {}
        for k = 1, cellCount do
            cells[k] = {}
            for l = 1, cellCount do
                cells[k][l] = {
                    X = k, Z = l,
                    Identifier = string.format('%d - %d', k, l),
                }
            end
        end

        self.CellCount = cellCount
        self.CellSize = 1 / cellCount * (math.max(mx, mz))
        self.Cells = cells
    end,

    --- Converts a world position to a grid position, always returns a valid position
    ---@param self AIGrid
    ---@param px number     # in world space
    ---@param pz number     # in world space
    ---@return number       # in grid space
    ---@return number       # in grid space
    ToCellIndices = function(self, px, pz)
        local cellCount = self.CellCount
        local cellSize = self.CellSize
        local inverse = 1 / cellSize

        local bx = 1
        if px > 0 then
            bx = ((px * inverse) ^ 0) + 1
            if bx > cellCount then
                bx = cellCount
            end
        end

        local bz = 1
        if pz > 0 then
            bz = ((pz * inverse) ^ 0) + 1
            if bz > cellCount then
                bz = cellCount
            end
        end

        return bx, bz
    end,

    --- Converts a cell into a rectangle
    ---@param self AIGrid
    ---@param bx number     # in grid space
    ---@param bz number     # in grid space
    ToRectangle = function(self, bx, bz)
        local cellSize = self.CellSize
        return {
            x0 = (bx - 1) * cellSize,
            x1 = (bx - 0) * cellSize,
            y0 = (bz - 1) * cellSize,
            y1 = (bz - 0) * cellSize,
        }
    end,

    -------------------------
    -- Debug functionality --

    ---@param self AIGrid
    ---@param bx number
    ---@param bz number
    ---@param inset number
    ---@param color Color
    DrawCell = function(self, bx, bz, inset, color)
        local cellSize = self.CellSize
        bx = (bx - 1) * cellSize
        bz = (bz - 1) * cellSize
        inset = inset or 0

        tl[1], tl[2], tl[3] = bx + inset, GetSurfaceHeight(bx + inset, bz + inset), bz + inset
        tr[1], tr[2], tr[3] = bx + cellSize - inset, GetSurfaceHeight(bx + cellSize - inset, bz + inset), bz + inset
        bl[1], bl[2], bl[3] = bx + inset, GetSurfaceHeight(bx + inset, bz + cellSize - inset), bz + cellSize - inset
        br[1], br[2], br[3] = bx + cellSize - inset, GetSurfaceHeight(bx + cellSize - inset, bz + cellSize - inset), bz + cellSize - inset

        DrawLine(tl, tr, color)
        DrawLine(tl, bl, color)
        DrawLine(br, bl, color)
        DrawLine(br, tr, color)
    end,
}
