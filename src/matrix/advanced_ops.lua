-- 矩阵高级运算模块
local Matrix = require("matrix.matrix")
require("matrix.basic_ops")  -- 加载基础运算
local utils = require("utils.init")
local Validator = utils.validators
local Typecheck = utils.typecheck

-- 行列式（使用 LU 分解）
function Matrix:det()
    -- 检查缓存
    if self._cache.det ~= nil then
        return self._cache.det
    end

    Validator.assert_square_matrix(self)

    -- 特殊情况优化
    if self._metadata.is_diagonal then
        local det = 1
        for i = 1, self.rows do
            det = det * self.data[i][i]
        end
        self._cache.det = det
        return det
    end

    if self._metadata.is_triangular then
        local det = 1
        for i = 1, self.rows do
            det = det * self.data[i][i]
        end
        self._cache.det = det
        return det
    end

    -- 对于小矩阵，直接计算
    if self.rows <= 3 then
        local det = self:_det_small()
        self._cache.det = det
        return det
    end

    -- 使用 LU 分解计算行列式
    local L, U, P = self:lu()
    local det = 1
    for i = 1, #U.data do
        det = det * U.data[i][i]
    end
    -- 考虑置换矩阵的奇偶性
    local sign = P:_permutation_sign()
    self._cache.det = sign * det
    return self._cache.det
end

-- 小矩阵行列式计算（直接展开）
function Matrix:_det_small()
    local n = self.rows

    if n == 1 then
        return self.data[1][1]
    elseif n == 2 then
        return self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]
    elseif n == 3 then
        return self.data[1][1] * (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2])
             - self.data[1][2] * (self.data[2][1] * self.data[3][3] - self.data[2][3] * self.data[3][1])
             + self.data[1][3] * (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1])
    end

    return 0
end

-- 矩阵范数
function Matrix:norm(norm_type)
    norm_type = norm_type or "fro"

    if norm_type == "fro" then
        -- Frobenius 范数
        local sum = 0
        for i = 1, self.rows do
            for j = 1, self.cols do
                sum = sum + self.data[i][j] ^ 2
            end
        end
        return math.sqrt(sum)

    elseif norm_type == 1 or norm_type == "1" then
        -- 1-范数（最大列和）
        local max_sum = 0
        for j = 1, self.cols do
            local col_sum = 0
            for i = 1, self.rows do
                col_sum = col_sum + math.abs(self.data[i][j])
            end
            if col_sum > max_sum then
                max_sum = col_sum
            end
        end
        return max_sum

    elseif norm_type == "inf" or norm_type == "infinity" then
        -- 无穷范数（最大行和）
        local max_sum = 0
        for i = 1, self.rows do
            local row_sum = 0
            for j = 1, self.cols do
                row_sum = row_sum + math.abs(self.data[i][j])
            end
            if row_sum > max_sum then
                max_sum = row_sum
            end
        end
        return max_sum

    else
        utils.Error.invalid_input("Unknown norm type: " .. tostring(norm_type))
    end
end

-- 矩阵的迹（对角线元素之和）
function Matrix:trace()
    Validator.assert_square_matrix(self)

    local sum = 0
    for i = 1, self.rows do
        sum = sum + self.data[i][i]
    end
    return sum
end

-- 矩阵的秩（使用高斯消元）
function Matrix:rank()
    if self._cache.rank ~= nil then
        return self._cache.rank
    end

    local A = self:clone()
    local rows, cols = A.rows, A.cols
    local rank = 0
    local lead = 1

    for r = 1, rows do
        if cols < lead then
            break
        end

        local i = r
        while A.data[i][lead] == 0 do
            i = i + 1
            if rows == i then
                i = r
                lead = lead + 1
                if cols == lead then
                    A._cache.rank = rank
                    return rank
                end
            end
        end

        -- 交换行
        if i ~= r then
            A.data[i], A.data[r] = A.data[r], A.data[i]
        end

        local val = A.data[r][lead]
        for j = 1, cols do
            A.data[r][j] = A.data[r][j] / val
        end

        for i = 1, rows do
            if i ~= r then
                val = A.data[i][lead]
                for j = 1, cols do
                    A.data[i][j] = A.data[i][j] - val * A.data[r][j]
                end
            end
        end

        lead = lead + 1
        rank = rank + 1
    end

    self._cache.rank = rank
    return rank
end

-- 检查是否为对称矩阵
function Matrix:is_symmetric()
    if not self._metadata.is_square then
        return false
    end

    if self._metadata.is_symmetric ~= nil then
        return self._metadata.is_symmetric
    end

    for i = 1, self.rows do
        for j = i + 1, self.cols do
            if math.abs(self.data[i][j] - self.data[j][i]) > utils.epsilon * 10 then
                self._metadata.is_symmetric = false
                return false
            end
        end
    end

    self._metadata.is_symmetric = true
    return true
end

-- 检查是否为对角矩阵
function Matrix:is_diagonal()
    if not self._metadata.is_square then
        return false
    end

    if self._metadata.is_diagonal ~= nil then
        return self._metadata.is_diagonal
    end

    for i = 1, self.rows do
        for j = 1, self.cols do
            if i ~= j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                self._metadata.is_diagonal = false
                return false
            end
        end
    end

    self._metadata.is_diagonal = true
    return true
end

-- 检查是否为三角矩阵（上三角或下三角）
function Matrix:is_triangular()
    if not self._metadata.is_square then
        return false
    end

    if self._metadata.is_triangular ~= nil then
        return self._metadata.is_triangular
    end

    local is_upper = true
    local is_lower = true

    for i = 1, self.rows do
        for j = 1, self.cols do
            if i > j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                is_upper = false
            end
            if i < j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                is_lower = false
            end
        end
    end

    self._metadata.is_triangular = is_upper or is_lower
    return self._metadata.is_triangular
end

-- 返回矩阵的形状
function Matrix:shape()
    return self.rows, self.cols
end

-- 重塑矩阵（元素数量必须相同）
function Matrix:reshape(new_rows, new_cols)
    Typecheck.check_positive_integer(new_rows, "new_rows")
    Typecheck.check_positive_integer(new_cols, "new_cols")

    if new_rows * new_cols ~= self.rows * self.cols then
        utils.Error.invalid_input(
            string.format("Cannot reshape %dx%d to %dx%d: element count mismatch",
                self.rows, self.cols, new_rows, new_cols)
        )
    end

    -- 展平当前矩阵
    local flat = {}
    for i = 1, self.rows do
        for j = 1, self.cols do
            table.insert(flat, self.data[i][j])
        end
    end

    -- 重塑为新矩阵
    local new_data = {}
    local idx = 1
    for i = 1, new_rows do
        new_data[i] = {}
        for j = 1, new_cols do
            new_data[i][j] = flat[idx]
            idx = idx + 1
        end
    end

    return Matrix.new(new_data)
end

return Matrix
