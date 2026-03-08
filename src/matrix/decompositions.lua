-- 矩阵分解模块
local Matrix = require("matrix.matrix")
require("matrix.basic_ops")  -- 加载基础运算
require("matrix.advanced_ops")  -- 加载高级运算
local utils = require("utils.init")
local Validator = utils.validators
local Typecheck = utils.typecheck

-- LU 分解（带部分主元选择）
-- A = P^T * L * U
-- L 是单位下三角矩阵，U 是上三角矩阵，P 是置换矩阵
function Matrix:lu()
    if self._cache.lu ~= nil then
        return table.unpack(self._cache.lu)
    end

    Validator.assert_square_matrix(self)

    local n = self.rows

    -- 初始化 L 为单位矩阵，U 为 A 的副本
    local L = Matrix.new({{}})
    local U = self:clone()
    L.rows = n
    L.cols = n
    L.data = {}
    for i = 1, n do
        L.data[i] = {}
        for j = 1, n do
            if i == j then
                L.data[i][j] = 1
            else
                L.data[i][j] = 0
            end
        end
    end

    -- 初始化置换矩阵 P 为单位矩阵
    local P = Matrix.new({{}})
    P.rows = n
    P.cols = n
    P.data = {}
    for i = 1, n do
        P.data[i] = {}
        for j = 1, n do
            if i == j then
                P.data[i][j] = 1
            else
                P.data[i][j] = 0
            end
        end
    end

    -- 高斯消元
    for k = 1, n - 1 do
        -- 部分主元选择
        local max_row = k
        local max_val = math.abs(U.data[k][k])
        for i = k + 1, n do
            if math.abs(U.data[i][k]) > max_val then
                max_row = i
                max_val = math.abs(U.data[i][k])
            end
        end

        -- 如果需要，交换行
        if max_row ~= k then
            U.data[k], U.data[max_row] = U.data[max_row], U.data[k]
            P.data[k], P.data[max_row] = P.data[max_row], P.data[k]
        end

        -- 检查是否奇异
        if math.abs(U.data[k][k]) < utils.tiny then
            utils.Error.singular_matrix(U.data[k][k])
        end

        -- 消元
        for i = k + 1, n do
            L.data[i][k] = U.data[i][k] / U.data[k][k]
            for j = k, n do
                U.data[i][j] = U.data[i][j] - L.data[i][k] * U.data[k][j]
            end
        end
    end

    self._cache.lu = { L, U, P }
    return L, U, P
end

-- QR 分解（Gram-Schmidt 正交化）
-- A = Q * R
-- Q 是正交矩阵，R 是上三角矩阵
function Matrix:qr()
    local m = self.rows
    local n = self.cols

    -- 初始化 Q 为 A 的副本，R 为零矩阵
    local Q = self:clone()
    local R = Matrix.new({{}})
    R.rows = n
    R.cols = n
    R.data = {}
    for i = 1, n do
        R.data[i] = {}
        for j = 1, n do
            R.data[i][j] = 0
        end
    end

    -- Gram-Schmidt 正交化
    for k = 1, n do
        -- R[k,k] = norm(Q[k])
        local norm_sq = 0
        for i = 1, m do
            norm_sq = norm_sq + Q.data[i][k] ^ 2
        end
        R.data[k][k] = math.sqrt(norm_sq)

        -- Q[k] = Q[k] / R[k,k]
        if R.data[k][k] > utils.tiny then
            for i = 1, m do
                Q.data[i][k] = Q.data[i][k] / R.data[k][k]
            end
        end

        -- 对后续列进行正交化
        for j = k + 1, n do
            -- R[k,j] = Q[k]' * Q[j]
            local dot = 0
            for i = 1, m do
                dot = dot + Q.data[i][k] * Q.data[i][j]
            end
            R.data[k][j] = dot

            -- Q[j] = Q[j] - R[k,j] * Q[k]
            for i = 1, m do
                Q.data[i][j] = Q.data[i][j] - R.data[k][j] * Q.data[i][k]
            end
        end
    end

    return Q, R
end

-- Cholesky 分解（仅适用于对称正定矩阵）
-- A = L * L^T
-- L 是下三角矩阵
function Matrix:cholesky()
    Validator.assert_square_matrix(self)

    local n = self.rows

    -- 检查对称性
    if not self:is_symmetric() then
        utils.Error.not_positive_definite()
    end

    -- 初始化 L 为零矩阵
    local L = Matrix.new({{}})
    L.rows = n
    L.cols = n
    L.data = {}
    for i = 1, n do
        L.data[i] = {}
        for j = 1, n do
            L.data[i][j] = 0
        end
    end

    -- Cholesky 分解
    for i = 1, n do
        for j = 1, i do
            local sum = 0

            if j == i then
                -- 对角线元素
                for k = 1, j - 1 do
                    sum = sum + L.data[j][k] ^ 2
                end
                local val = self.data[j][j] - sum
                if val < -utils.tiny then
                    utils.Error.not_positive_definite()
                end
                if val < 0 then
                    val = 0
                end
                L.data[j][j] = math.sqrt(val)

                if L.data[j][j] < utils.tiny then
                    utils.Error.not_positive_definite()
                end
            else
                -- 非对角线元素
                for k = 1, j - 1 do
                    sum = sum + L.data[i][k] * L.data[j][k]
                end
                L.data[i][j] = (self.data[i][j] - sum) / L.data[j][j]
            end
        end
    end

    return L
end

-- 计算置换矩阵的符号（奇偶性）
function Matrix:_permutation_sign()
    local n = self.rows

    -- 检查是否为置换矩阵
    for i = 1, n do
        local has_one = false
        for j = 1, n do
            if math.abs(self.data[i][j] - 1) < utils.epsilon then
                if has_one then
                    return 1  -- 不是置换矩阵
                end
                has_one = true
            elseif math.abs(self.data[i][j]) > utils.epsilon then
                return 1  -- 不是置换矩阵
            end
        end
        if not has_one then
            return 1  -- 不是置换矩阵
        end
    end

    -- 计算符号（通过跟踪交换次数）
    local visited = {}
    local sign = 1

    for i = 1, n do
        if not visited[i] then
            local cycle_length = 0
            local j = i
            while not visited[j] do
                visited[j] = true
                cycle_length = cycle_length + 1
                -- 找到 j 列中 1 的位置
                for k = 1, n do
                    if math.abs(self.data[k][j] - 1) < utils.epsilon then
                        j = k
                        break
                    end
                end
            end
            if cycle_length > 1 and cycle_length % 2 == 0 then
                sign = -sign
            end
        end
    end

    return sign
end

return Matrix
