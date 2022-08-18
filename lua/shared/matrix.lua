local Statistics = import("/lua/shared/statistics.lua")

---@class Matrix : number[][]
Matrix = Class() {
    ---@overload fun(vector: number[]): Matrix
    ---@overload fun(cpyMatrix: number[][]): Matrix
    __init = function(self, rows, cols)
        if type(rows) == "table" then
            local cpy = rows
            local rows = table.getn(cpy)
            local firstRow = cpy[1]
            if type(firstRow) ~= "table" then
                cols = 1
                for j = 1, rows do
                    self[j] = {cpy[j]}
                end
            else
                cols = table.getn(firstRow)
                for j = 1, rows do
                    local row = {}
                    self[j] = row
                    local cpyRow = cpy[j]
                    for i = 1, cols do
                        row[i] = cpyRow[i]
                    end
                end
            end
            self.rows = rows
            self.cols = cols
        else
            self.rows = rows
            self.cols = cols
            for j = 1, rows do
                local row = {}
                for i = 1, cols do
                    row[i] = 0
                end
                self[j] = row
            end
        end
    end;

    Create = function(rows, cols)
        return Matrix(rows, cols)
    end;

    Identity = function(size)
        local mat = {}
        setmetatable(mat, Matrix)
        mat.rows = size
        mat.cols = size
        for j = 1, size do
            local row = {}
            for i = 1, size do
                row[i] = 0
            end
            row[j] = 1
            mat[j] = row
        end
        return mat
    end;

    Diagonal = function(list)
        local size = table.getn(list)
        mat = Matrix.Create(size, size)
        for i = 1, size do
            mat[i][i] = list[i]
        end
        return mat
    end;

    Wrap = function(mat)
        setmetatable(mat, Matrix)
        mat.rows = table.getn(mat)
        mat.cols = table.getn(mat[1])
        return mat
    end;

    Vector = function(list)
        local rows = table.getn(list)
        local mat = {}
        setmetatable(mat, Matrix)
        mat.rows = rows
        mat.cols = 1
        for i = 1, rows do
            mat[i] = {list[i]}
        end
        return mat
    end;

    WrapVector = function(vec)
        local mat = {}
        setmetatable(mat, Matrix)
        mat.rows = 1
        mat.cols = table.getn(vec)
        mat[1] = vec
        return mat
    end;

    ---@overload fun(mat: Matrix): Matrix
    ---@overload fun(mat: Matrix, rows: number, cols: number): Matrix
    ---@param mat Matrix
    ---@param rowStart number
    ---@param colStart number
    ---@param rows number
    ---@param cols number
    ---@return Matrix
    Copy = function(mat, rowStart, colStart, rows, cols)
        local cpy = {}
        setmetatable(cpy, Matrix)
        if not colStart then
            rows, cols = mat.rows, mat.cols
        elseif not cols then
            rows, cols = rowStart, colStart
            rowStart, colStart = 0, 0
        else
            rowStart, colStart = rowStart - 1, colStart - 1 -- make offsets
        end
        cpy.rows = rows
        cpy.cols = cols
        if rowStart == 0 and colStart == 0 then
            for j = 1, rows do
                local row = {}
                local matRow = mat[j]
                cpy[j] = row
                for i = 1, cols do
                    row[i] = matRow[i]
                end
            end
        else
            for j = 1, rows do
                local row = {}
                local matRow = mat[j + rowStart]
                cpy[j] = row
                for i = 1, cols do
                    row[i] = matRow[i + colStart]
                end
            end
        end
        return cpy
    end;

    CopyTranspose = function(mat, rows, cols)
        rows = rows or mat.cols
        cols = cols or mat.rows
        local cpy = {}
        cpy.rows = rows
        cpy.cols = cols
        for j = 1, rows do
            local row = {}
            cpy[j] = row
            for i = 1, cols do
                row[i] = mat[i][j]
            end
        end
        setmetatable(cpy, Matrix)
        return cpy
    end;

    -- modifying methods

    ScaleBy = function(self, scalar)
        local rows, cols = self.cols, self.rows
        for j = 1, rows do
            local row = self[j]
            for i = 1, cols do
                row[i] = row[i] * scalar
            end
        end
        return self
    end;

    RowSwap = function(self, row, moveTo)
        self[row], self[moveTo] = self[moveTo], self[row]
        return self
    end;
    RowScale = function(self, row, scaleBy)
        local cols = self.cols
        row = self[row]
        for i = 1, cols do
            row[i] = row[i] * scaleBy
        end
        return self
    end;
    RowMove = function(self, row, moveTo, scale)
        return self:RowScale(row, scale):RowSwap(row, moveTo)
    end;
    RowAdd = function(self, row, scale, addTo)
        local cols = self.cols
        row = self[row]
        addTo = self[addTo]
        for i = 1, cols do
            addTo[i] = addTo[i] + row[i] * scale;
        end
        return self
    end;

    ColumnSwap = function(self, col, moveTo)
        local rows = self.rows
        for i = 1, rows do
            local row = self[i]
            row[col], row[moveTo] = row[moveTo], row[col]
        end
        return self
    end;
    ColumnScale = function(self, col, scaleBy)
        local rows = self.rows
        for i = 1, rows do
            local row = self[i]
            row[col] = row[col] * scaleBy
        end
        return self
    end;
    ColumnMove = function(self, col, moveTo, scale)
        local rows = self.rows
        for i = 1, rows do
            local row = self[i]
            row[col], row[moveTo] = row[moveTo], row[col] * scale
        end
        return self
    end;
    ColumnAdd = function(self, col, scale, addTo)
        local rows = self.rows
        for i = 1, rows do
            local row = self[i]
            row[addTo] = row[addTo] + row[col] * scale
        end
        return self
    end;

    Ref = function(self, aug)
        local rows, cols = self.rows, self.cols
        aug = cols - aug
        local col = 0
        local rank = aug
        for j = 1, rows do
            -- find non-zero row
            local row = self[j]
            while row[col] == 0 do
                local swapWith = false
                for k = j + 1, rows do
                    if self[k][col] != 0 then
                        swapWith = k
                        break
                    end
                end
                if swapWith then
                    self:RowSwap(j, k)
                    break
                end
                -- column is not linearly independent; move on
                rank = rank - 1
                col = col + 1
                if col == aug then return self end
            end

            -- normalize to 1; we can do better than the default row op
            local norm = row[col]
            for i = j + 1, cols do
                row[i] = row[i] / norm
            end
            for k = j + 1, rows do
                local rowk = self[k]
                local scalar = rowk[col]
                if scalar ~= 0 then
                    for i = col + 1, cols do
                        rowk[i] = rowk[i] - row[i] * scalar
                    end
                end
            end
            col = col + 1
            if col == aug then return self end
        end
        return rank
    end;
    Rref = function(self, aug)
        local rows, cols = self.rows, self.cols
        aug = cols - aug
        local col = 0
        local rank = aug
        for j = 1, rows do
            -- find non-zero row
            local row = self[j]
            while row[col] == 0 do
                local swapWith = false
                for k = j + 1, rows do
                    if self[k][col] != 0 then
                        swapWith = k
                        break
                    end
                end
                if swapWith then
                    self:RowSwap(j, k)
                    break
                end
                -- column is not linearly independent; move on
                rank = rank - 1
                col = col + 1
                if col == aug then return self end
            end

            -- normalize to 1; we can do better than the default row op
            local norm = row[col]
            for i = j + 1, cols do
                row[i] = row[i] / norm
            end
            for k = 1, j - 1 do
                local rowk = self[k]
                local scalar = rowk[col]
                if scalar ~= 0 then
                    for i = col + 1, cols do
                        rowk[i] = rowk[i] - row[i] * scalar
                    end
                end
            end
            for k = j + 1, rows do
                local rowk = self[k]
                local scalar = rowk[col]
                if scalar ~= 0 then
                    for i = col + 1, cols do
                        rowk[i] = rowk[i] - row[i] * scalar
                    end
                end
            end
            col = col + 1
            if col == aug then return self end
        end
        return rank
    end;

    -- non-modifying methods

    SmallerDim = function(self)
        return math.min(self.rows, self.cols)
    end;

    IsDiagonal = function(self)
        local size = self:SmallerDim()
        for i = 1, size do
            local row = self[i]
            for j = i + 1, size do
                if row[j] ~= 0 or self[i][j] ~= 0 then
                    return false
                end
            end
        end
        return true
    end;
    IsUpTriangular = function(self)
        local size = self:SmallerDim()
        for j = 1, size do
            local row = self[j]
            for i = 1, j - 1 do
                if row[i] ~= 0 then return false end
            end
        end
        local rows = self.rows
        for j = size + 1, rows do
            local row = self[j]
            for i = 1, rows do
                if row[i] ~= 0 then return false end
            end
        end
        return true
    end;
    IsDownTriangular = function(self)
        local size = self:SmallerDim()
        local cols = self.cols
        for j = 1, size do
            local row = self[j]
            for i = j + 1, cols do
                if row[i] ~= 0 then return false end
            end
        end
        for j = 1, cols do
            row = self[j]
            for i = size + 1, cols do
                if row[i] then return false end
            end
        end
        return true
    end;

    Trace = function(self)
        local sum = 0
        local size = self:SmallerDim()
        for i = 1, size do
            sum = sum + self[i][i]
        end
        return sum
    end;
    DiagonalProd = function(self)
        local prod = 1
        local size = self:SmallerDim()
        for i = 1, size do
            if prod == 0 then return 0 end
            prod = prod * self[i][i]
        end
        return prod
    end;


    Scale = function(self, scalar)
        local rows, cols = self.cols, self.rows
        local mat = {}
        for j = 1, rows do
            local row = self[j]
            mat[j] = row
            for i = 1, cols do
                row[i] = row[i] * scalar
            end
        end
        return Matrix.Wrap(mat)
    end;

    Transpose = function(self)
        local mat = {}
        local rows, cols = self.cols, self.rows
        for j = 1, rows do
            col = {}
            mat[j] = col
            for i = 1, cols do
                col[i] = self[i][j]
            end
        end
        return Matrix.Wrap(mat)
    end;

    Add = function(m1, m2)
        local rows, cols = m1.rows, m1.cols
        if m2.rows ~= rows or m2.cols ~= cols then
            error("adding matrices of unequal size")
        end
        local added = {}
        for j = 1, rows do
            local addedRow = {}
            added[j] = addedRow
            local row1, row2 = m1[j], m2[j]
            for i = 1, cols do
                addedRow[i] = row1[i] + row2[i]
            end
        end
        return Matrix.Wrap(added)
    end;

    Sub = function(m1, m2)
        local rows, cols = m1.rows, m1.cols
        if m2.rows ~= rows or m2.cols ~= cols then
            error("subtracting matrices of unequal size")
        end
        local subbed = {}
        for j = 1, rows do
            local subbedRow = {}
            subbed[j] = subbedRow
            local row1, row2 = m1[j], m2[j]
            for i = 1, cols do
                subbedRow[i] = row1[i] - row2[i]
            end
        end
        return Matrix.Wrap(subbed)
    end;

    Mult = function(m1, m2)
        local rows, cols = m1.rows, m2.cols
        local common = m1.cols
        if common != m2.rows then
            error("cannot multiply matrices")
        end
        local mat = {}
        local m2Row1 = m2[1]
        for j = 1, rows do
            local row = {}
            mat[j] = row
            local m1Row = m1[j]
            for i = 1, cols do
                local sum = m1Row[1] * m2Row1[i]
                for k = 2, common do
                    sum = sum + m1Row[k] * m2[k][i]
                end
                row[i] = sum
            end
        end
        return Matrix.Wrap(mat)
    end;

    -- When multiplying matrices of different sizes, the order can have a huge impact on efficiency.
    -- These will maximize efficiency; if you already know that the matrices you're multiplying are the
    -- same size, you should just use the two argument version to eliminate the cost calculation overhead

    Mult3 = function(m1, m2, m3)
        local a = m1.rows
        local b = m2.rows
        local c = m2.cols
        local d = m3.cols
        if a * c * (b + d) < b * d * (c + a) then
            return m1:Mult(m2):Mult(m3)
        else
            return m1:Mult(m2:Mult(m3))
        end
    end;
    Mult4 = function(m1, m2, m3, m4)
        local cost0, cost1, cost2, cost3, cost4
        do
            local a, b, c, d, e = m1.rows, m2.rows, m3.rows, m4.rows, m4.cols
            local ad, be, bc, ce = a * d, b * e, b * c, c * e
            local abc, abe, ade, bcd, cde = a * bc, a * be, ad * e, bc * d, ce * d
            cost0 = abc + ad*c + ade
            cost1 = bcd + ad*b + ade
            cost2 = abc + ce*a + cde
            cost3 = bcd + be*d + abe
            cost4 = cde + be*c + abe
        end

        local min = 0
        local val = cost0
        if cost1 < val then min = 1 ; val = cost1 end
        if cost2 < val then min = 2 ; val = cost2 end
        if cost3 < val then min = 3 ; val = cost3 end
        if cost4 < val then min = 4 end

        if min == 0 then return m1:Mult(m2):Mult(m3):Mult(m4) end -- 1 2 3
        if min == 1 then return m1:Mult(m2:Mult(m3)):Mult(m4) end -- 2 1 3
        if min == 2 then return m1:Mult(m2):Mult(m3:Mult(m4)) end -- 2 3 1 = 1 3 2
        if min == 3 then return m1:Mult(m2:Mult(m3):Mult(m4)) end -- 3 1 2
        if min == 4 then return m1:Mult(m2:Mult(m3:Mult(m4))) end -- 3 2 1
    end;

    MultiMult = function(m1, m2, m3, m4, ...)
        if not m2 then
            return m1
        elseif not m3 then
            return m1:Mult(m2)
        elseif not m4 then
            return m1:Mult3(m2, m3)
        else
            local Mult4Method = m1.Mult4
            local reduce = Mult4Method(m1, m2, m3, m4)
            local argCount = args.n
            if argCount > 0 then
                -- in case there's more than four arguments, we no longer go for maximium efficiency
                -- since the time it takes to find that out also increases exponentially
                -- so we settle for recursively chunking the arguments into groups of 4
                local MultiMultMethod = m1.MultiMult
                local subresults = {reduce}
                local subresultCount = 0
                for i = 4, argCount, 4 do
                    m1, m2, m3, m4 = args[i - 3], args[i - 2], args[i - 1], args[i]
                    subresultCount = subresultCount + 1
                    subresults[subresultCount] = Mult4Method(m1, m2, m3, m4)
                end
                local argsUsed = subresultCount * 4
                if argsUsed ~= argCount then
                    m1, m2, m3 = args[argsUsed + 1], args[argsUsed + 2], args[argsUsed + 3]
                    subresults[subresultCount + 1] = MultiMultMethod(m1, m2, m3)
                end
                reduce = MultiMultMethod(unpack(subresults))
            end
            return reduce
        end
    end;

    MultRight = function(self, ...)
        local MultiMultMethod = self.MultiMult -- this allows extendibility from the caller
        table.reverse(args)
        return MultiMultMethod(unpack(args), self)
    end;

    GetRow = function(self, row)
        row = self[row]
        local cols = self.cols
        local li = {}
        for i = 1, cols do
            li[i] = row[i]
        end
        return li
    end;
    GetColumn = function(self, col)
        local rows = self.rows
        local li = {}
        for j = 1, rows do
            li[j] = self[j][col]
        end
        return li
    end;

    GetDiagonal = function(self)
        local diag = {}
        for i = 1, self:SmallerDim() do
            diag[i] = self[i][i]
        end
        return diag
    end;

    SubMatrix = function(self, row, col)
        local rows, cols = self.rows, self.cols
        if rows <= 1 or cols <= 1 then
            error("degenerate submatrix")
        end
        local sub = {}
        for j = 1, row - 1 do
            local rowj = {}
            sub[j] = rowj
            local selfRow = self[j]
            for i = 1, col - 1 do
                rowj[i] = selfRow[i]
            end
            for i = col + 1, cols do
                rowj[i - 1] = selfRow[i]
            end
        end
        for j = row + 1, rows do
            local rowj = {}
            sub[j - 1] = rowj
            local selfRow = self[j]
            for i = 1, col - 1 do
                rowj[i] = selfRow[i]
            end
            for i = col + 1, cols do
                rowj[i - 1] = selfRow[i]
            end
        end
        return Matrix.Wrap(sub)
    end;
    Minor = function(self, row, col)
        return self:SubMatrix(row, col):Determinate()
    end;
    MinorMatrix = function(self)
        local rows, cols = self.rows, self.cols
        local MoM = {}
        for j = 1, rows do
            local MoMrow = {}
            MoM[j] = MoMrow
            for i = 1, cols do
                MoMrow[i] = self:Minor(j, i)
            end
        end
        return Matrix.Wrap(MoM)
    end;

    Cofactor = function(self, row, col)
        local minor = self:Minor(row, col)
        if math.mod(row + col, 2) == 1 then
            minor =- minor
        end
        return minor
    end;
    CofactorMatrix = function(self)
        local rows, cols = self.rows, self.cols
        local MoC = {}
        for j = 1, rows do
            local MoCrow = {}
            MoC[j] = MoCrow
            for i = 1, cols do
                MoCrow[i] = self:Cofactor(j, i)
            end
        end
        return Matrix.Wrap(MoC)
    end;

    Adjugate = function(self)
        -- return self:CofactorMatrix():Transpose()
        local rows, cols = self.rows, self.cols
        local MoC = {}
        for j = 1, rows do
            local MoCrow = {}
            MoC[j] = MoCrow
            for i = 1, cols do
                MoCrow[i] = self:Cofactor(i, j)
            end
        end
        return Matrix.Wrap(MoC)
    end;
    Inverse = function(self)
        local size = self.rows
        if size ~= self.cols then
            error("non-square matrix")
        end
        if size == 0 then
            error("singular matrix")
        end
        -- at about this point, it becomes faster to solve the equation using Rref
        if size > 4 then
            local cpy = Matrix(self)
            -- augment with identity matrix
            cpy.cols = size * 2
            for j = 1, size do
                local row = cpy[j]
                for i = 1, size do
                    row[size + i] = 0
                end
                row[size + j] = 1
            end
            -- reduce the augmented matrix 
            local solved = cpy:Rref(size)
            -- extract augment
            return solved:Copy(size, 1, size, size)
        end
        local adj = self:Adjugate()
        -- manually calculate determinate from adjugate
        -- could have used any row- or column- dot product with original, but top row is traditional
        local vec1, vec2 = adj[1], self[1]
        local det = vec1[1] * vec2[1]
        for i = 2, size do
            det = det + vec1[i] * vec2[i]
        end
        if det == 0 then
            -- We found a singular matrix! We should throw an error... but most of the ways the user
            -- could have detected this beforehand are really slow
            return
        end
        return adj:ScaleBy(1 / det)
    end;


    Permanent = function(self)
        local size = self.rows
        if size ~= self.cols then
            error("non-square matrix")
        end
        -- trivial matrix is neither invertible nor vertible
        if size == 0 then
            error("singular matrix")
        end
        -- small-rank cases
        local row1 = self[1]
        if size == 1 then
            return row1[1]
        end
        local row2 = self[2]
        if size == 2 then
            return row1[1] * row2[2] + row1[2] * row2[1]
        end
        local row3 = self[3]
        if size == 3 then
            local a, b, c = row1[1], row2[1], row3[1]
            local d, e, f = row1[2], row2[2], row3[2]
            local g, h, i = row1[3], row2[3], row3[3]
            return
                a * (e * i + h * f) +
                b * (d * i + g * f) +
                c * (d * h + g * e)
        end
        local row4 = self[4]
        if size == 4 then
            local e, f, g, h = row1[2], row2[2], row3[2], row4[2]
            local i, j, k, l = row1[3], row2[3], row3[3], row4[3]
            local m, n, o, p = row1[4], row2[4], row3[4], row4[4]
			local kp_lo, jp_ln = k * p + l * o, j * p + l * n
			local jo_kn, ip_lm = j * o + k * n, i * p + l * m
			local io_km, in_jm = i * o + k * m, i * n + j * m
			return
				row1[1] * (f * kp_lo + g * jp_ln + h * jo_kn) +
				row2[1] * (e * kp_lo + g * ip_lm + h * io_km) +
				row3[1] * (e * jp_ln + f * ip_lm + h * in_jm) +
				row4[1] * (e * jo_kn + f * io_km + g * in_jm)
        end
        local max_width = Statistics.Choose(size, math.floor(size * 0.5)) -- LARGE NUMBER!
        if max_width > 9999 then
            -- recursive laplace expansion, if not enough memory to store subresults
            local sum = row1[1] * self:Submatrix(1, 1):Permanent()
            for i = 2, size do
                sum = sum + row1[i] * self:Submatrix(1, i):Permanent()
            end
            return sum
        end
        -- breadth-first laplace expansion caching subresults to minimize
        -- multiplications and avoid dealing with calculating partitions
        local heap = {}	-- array of LARGE NUMBER!
        local breadth = size
        local cur_heap_dif = max_width / breadth
        -- initialize heap with bottom row
        local pos = 1
        for i = 1, size do
            heap[pos] = self[breadth][i]
            pos = pos + cur_heap_dif
        end
        local last_heap_dif = cur_heap_dif
        for breadth = breadth - 1, 1, -1 do
            local last_pos = 1
            cur_heap_dif = cur_heap_dif / breadth
            for pos = 1, max_width do
                local item = heap[last_pos]
                last_pos = last_pos + last_heap_dif
                for i = 1, size do
                    heap[pos] = item * self[breadth][i]
                    pos = pos + cur_heap_dif
                end
            end
            last_heap_dif = cur_heap_dif
        end
        local sum = heap[1]
        for i = 2, max_width do
            sum = sum + heap[i]
        end
        return sum
    end;
    Determinant = function(self)
        -- Determinant(M) = Immanent(M, (p) -> {p % 2 ? +1 : -1})
        local size = self.rows
        if size ~= self.cols then
            error("non-square matrix")
        end
        -- trivial matrix is neither invertible nor vertible
        if size == 0 then
            error("singular matrix")
        end
        -- small-rank cases
        local row1 = self[1]
        if size == 1 then
            return row1[1]
        end
        local row2 = self[2]
        if size == 2 then
            return row1[1] * row2[2] - row1[2] * row2[1]
        end
        local row3 = self[3]
        if size == 3 then
            local a, b, c = row1[1], row2[1], row3[1]
            local d, e, f = row1[2], row2[2], row3[2]
            local g, h, i = row1[3], row2[3], row3[3]
            return
                a * (e * i - h * f) -
                b * (d * i - g * f) +
                c * (d * h - g * e)
        end
        local row4 = self[4]
        if size == 4 then
            local e, f, g, h = row1[2], row2[2], row3[2], row4[2]
            local i, j, k, l = row1[3], row2[3], row3[3], row4[3]
            local m, n, o, p = row1[4], row2[4], row3[4], row4[4]
			local kp_lo, jp_ln = k * p - l * o, j * p - l * n
			local jo_kn, ip_lm = j * o - k * n, i * p - l * m
			local io_km, in_jm = i * o - k * m, i * n - j * m
			return
				row1[1] * (f * kp_lo - g * jp_ln + h * jo_kn) -
				row2[1] * (e * kp_lo - g * ip_lm + h * io_km) +
				row3[1] * (e * jp_ln - f * ip_lm + h * in_jm) -
				row4[1] * (e * jo_kn - f * io_km + g * in_jm)
        end
        local max_width = Statistics.Choose(size, math.floor(size * 0.5)) -- LARGE NUMBER!
        if max_width > 9999 then
            local sum = row1[1] * self:Submatrix(1, 1):Determinant()
            for i = 3, size, 2 do
                sum = sum + row1[i] * self:Submatrix(1, i):Determinant()
            end
            for i = 2, size, 2 do
                sum = sum - row1[i] * self:Submatrix(1, i):Determinant()
            end
            return sum
        end
        -- breadth-first laplace expansion caching subresults to minimize
        -- multiplications and avoid dealing with calculating partitions
        local heap = {} -- array of LARGE NUMBER!
        local breadth = size
        local cur_heap_dif = max_width / breadth
        -- initialize heap with bottom row
        local pos = 1
        for i = 1, size do
            heap[pos] = self[breadth][i]
            pos = pos + cur_heap_dif
        end
        local last_heap_dif = cur_heap_dif
        for breadth = breadth - 1, 0, -1 do
            local last_pos = 1
            cur_heap_dif = cur_heap_dif / breadth
            for pos = 1, max_width do
                local item = heap[last_pos]
                last_pos = last_pos + last_heap_dif
                for i = 1, size do
                    heap[pos] = item * self[breadth][i]
                    pos = pos + cur_heap_dif
                end
            end
            last_heap_dif = cur_heap_dif
        end
        local sum = heap[1]
        for i = 3, max_width, 2 do
            sum = sum + heap[i]
        end
        for i = 2, max_width, 2 do
            sum = sum - heap[i]
        end
        return sum
    end;
}