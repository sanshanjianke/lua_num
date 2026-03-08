-- 特殊矩阵生成模块
local Matrix = require("matrix.matrix")
local Typecheck = require("utils.init").typecheck

local M = {}

-- 零矩阵
function M.zeros(rows, cols)
    Typecheck.check_positive_integer(rows, "rows")
    Typecheck.check_positive_integer(cols, "cols")

    local data = {}
    for i = 1, rows do
        data[i] = {}
        for j = 1, cols do
            data[i][j] = 0
        end
    end

    return Matrix.new(data)
end

-- 全1矩阵
function M.ones(rows, cols)
    Typecheck.check_positive_integer(rows, "rows")
    Typecheck.check_positive_integer(cols, "cols")

    local data = {}
    for i = 1, rows do
        data[i] = {}
        for j = 1, cols do
            data[i][j] = 1
        end
    end

    return Matrix.new(data)
end

-- 单位矩阵（方阵）
function M.eye(n)
    Typecheck.check_positive_integer(n, "n")

    local data = {}
    for i = 1, n do
        data[i] = {}
        for j = 1, n do
            if i == j then
                data[i][j] = 1
            else
                data[i][j] = 0
            end
        end
    end

    return Matrix.new(data)
end

-- 对角矩阵
function M.diag(diagonal_values)
    Typecheck.check_table(diagonal_values, "diagonal_values")

    local n = #diagonal_values
    local data = {}
    for i = 1, n do
        data[i] = {}
        for j = 1, n do
            if i == j then
                data[i][j] = diagonal_values[i]
            else
                data[i][j] = 0
            end
        end
    end

    local m = Matrix.new(data)
    m._metadata.is_diagonal = true
    m._metadata.is_square = true
    return m
end

-- 随机矩阵（均匀分布 [0, 1)）
function M.rand(rows, cols)
    Typecheck.check_positive_integer(rows, "rows")
    Typecheck.check_positive_integer(cols, "cols")

    local data = {}
    for i = 1, rows do
        data[i] = {}
        for j = 1, cols do
            data[i][j] = math.random()
        end
    end

    return Matrix.new(data)
end

-- 随机整数矩阵
function M.rand_int(rows, cols, min, max)
    Typecheck.check_positive_integer(rows, "rows")
    Typecheck.check_positive_integer(cols, "cols")
    Typecheck.check_integer(min, "min")
    Typecheck.check_integer(max, "max")

    if min > max then
        error("min must be less than or equal to max")
    end

    local data = {}
    for i = 1, rows do
        data[i] = {}
        for j = 1, cols do
            data[i][j] = math.random(min, max)
        end
    end

    return Matrix.new(data)
end

-- 随机正定矩阵（对称）
function M.rand_spd(n)
    Typecheck.check_positive_integer(n, "n")

    -- 生成随机矩阵 A
    local A = M.rand(n, n)

    -- 计算 A * A^T，保证对称正定
    local A_T = A:transpose()
    local spd = A:mul(A_T)

    -- 添加对角线元素以保证正定性
    for i = 1, n do
        spd.data[i][i] = spd.data[i][i] + n
    end

    spd._metadata.is_symmetric = true
    spd._metadata.is_square = true
    return spd
end

-- Hilbert 矩阵（著名的病态矩阵）
function M.hilbert(n)
    Typecheck.check_positive_integer(n, "n")

    local data = {}
    for i = 1, n do
        data[i] = {}
        for j = 1, n do
            data[i][j] = 1 / (i + j - 1)
        end
    end

    local m = Matrix.new(data)
    m._metadata.is_symmetric = true
    m._metadata.is_square = true
    return m
end

-- Vandermonde 矩阵
function M.vandermonde(x, n)
    Typecheck.check_table(x, "x")
    Typecheck.check_positive_integer(n, "n")

    local m = #x
    local data = {}
    for i = 1, m do
        data[i] = {}
        for j = 1, n do
            data[i][j] = x[i] ^ (n - j)
        end
    end

    return Matrix.new(data)
end

-- Toeplitz 矩阵（每条对角线上的元素相同）
function M.toeplitz(first_row, first_col)
    Typecheck.check_table(first_row, "first_row")

    -- 如果只提供 first_row，假设对称
    if first_col == nil then
        first_col = {}
        for i, val in ipairs(first_row) do
            first_col[i] = val
        end
    end

    local rows = #first_col
    local cols = #first_row

    local data = {}
    for i = 1, rows do
        data[i] = {}
        for j = 1, cols do
            local diff = j - i
            if diff == 0 then
                data[i][j] = first_col[1]
            elseif diff > 0 then
                if diff <= #first_row then
                    data[i][j] = first_row[diff + 1]
                else
                    data[i][j] = 0
                end
            else
                if -diff <= #first_col then
                    data[i][j] = first_col[-diff + 1]
                else
                    data[i][j] = 0
                end
            end
        end
    end

    return Matrix.new(data)
end

-- 循环矩阵（每行是前一行的循环移位）
function M.circulant(first_row)
    Typecheck.check_table(first_row, "first_row")

    local n = #first_row
    local data = {}
    for i = 1, n do
        data[i] = {}
        for j = 1, n do
            local idx = (j - i) % n
            if idx < 0 then
                idx = idx + n
            end
            data[i][j] = first_row[idx + 1]
        end
    end

    local m = Matrix.new(data)
    m._metadata.is_square = true
    return m
end

-- 块对角矩阵
function M.block_diagonal(blocks)
    Typecheck.check_table(blocks, "blocks")

    if #blocks == 0 then
        return Matrix.new({{}})
    end

    -- 计算总维度
    local total_rows = 0
    local total_cols = 0
    for _, block in ipairs(blocks) do
        total_rows = total_rows + block.rows
        total_cols = total_cols + block.cols
    end

    -- 创建块对角矩阵
    local data = {}
    for i = 1, total_rows do
        data[i] = {}
        for j = 1, total_cols do
            data[i][j] = 0
        end
    end

    -- 填入块
    local row_offset = 0
    local col_offset = 0
    for _, block in ipairs(blocks) do
        for i = 1, block.rows do
            for j = 1, block.cols do
                data[row_offset + i][col_offset + j] = block.data[i][j]
            end
        end
        row_offset = row_offset + block.rows
        col_offset = col_offset + block.cols
    end

    return Matrix.new(data)
end

return M
