-- 线性方程组求解模块
local Matrix = require("matrix.matrix")
require("matrix.basic_ops")  -- 加载基础运算
require("matrix.advanced_ops")  -- 加载高级运算
require("matrix.decompositions")  -- 加载矩阵分解
local utils = require("utils.init")
local Validator = utils.validators
local Typecheck = utils.typecheck

-- 求解线性方程组 Ax = b
-- 使用 LU 分解
function Matrix:solve(b)
    Validator.assert_square_matrix(self)

    if self.rows ~= b.rows then
        utils.Error.dimension_mismatch(
            string.format("A has %d rows, b has %d rows", self.rows, b.rows)
        )
    end

    -- 使用 LU 分解求解
    local L, U, P = self:lu()

    -- 应用置换矩阵: Pb
    local Pb = P:mul(b)

    -- 前向代入: Ly = Pb
    local y = Matrix.new({{}})
    y.rows = self.rows
    y.cols = b.cols
    y.data = {}

    for j = 1, b.cols do
        for i = 1, self.rows do
            local sum = 0
            for k = 1, i - 1 do
                sum = sum + L.data[i][k] * y.data[k][j]
            end
            y.data[i] = y.data[i] or {}
            y.data[i][j] = Pb.data[i][j] - sum
        end
    end

    -- 回代: Ux = y
    local x = Matrix.new({{}})
    x.rows = self.rows
    x.cols = b.cols
    x.data = {}

    for j = 1, b.cols do
        for i = self.rows, 1, -1 do
            local sum = 0
            for k = i + 1, self.rows do
                sum = sum + U.data[i][k] * x.data[k][j]
            end
            x.data[i] = x.data[i] or {}
            x.data[i][j] = (y.data[i][j] - sum) / U.data[i][i]
        end
    end

    return x
end

-- 矩阵求逆（使用 LU 分解）
function Matrix:inverse()
    if self._cache.inv ~= nil then
        return self._cache.inv
    end

    Validator.assert_square_matrix(self)

    -- 创建单位矩阵
    local I = Matrix.new({{}})
    I.rows = self.rows
    I.cols = self.cols
    I.data = {}

    for i = 1, self.rows do
        I.data[i] = {}
        for j = 1, self.cols do
            if i == j then
                I.data[i][j] = 1
            else
                I.data[i][j] = 0
            end
        end
    end

    -- 求解 AI = I 的列
    local inv = self:solve(I)
    self._cache.inv = inv
    return inv
end

-- 伪逆（Moore-Penrose 伪逆）
-- 使用 SVD 近似实现（这里使用 QR 分解简化）
function Matrix:pseudo_inverse()
    local m = self.rows
    local n = self.cols

    if m == n then
        -- 方阵，尝试求逆
        local det = self:det()
        if math.abs(det) > utils.tiny then
            return self:inverse()
        end
    end

    if m > n then
        -- 高矩阵：使用 QR 分解
        local Q, R = self:qr()
        local R_inv = R:inverse()
        local Q_T = Q:transpose()
        return R_inv:mul(Q_T)
    else
        -- 宽矩阵：使用转置的伪逆
        return self:transpose():pseudo_inverse():transpose()
    end
end

-- 最小二乘解
-- 求解 min ||Ax - b||²
function Matrix:least_squares(b)
    local m = self.rows
    local n = self.cols

    if m >= n then
        -- 使用正规方程: (A'A)x = A'b
        local A_T = self:transpose()
        local A_T_A = A_T:mul(self)
        local A_T_b = A_T:mul(b)

        return A_T_A:solve(A_T_b)
    else
        -- 欠定系统，返回最小范数解
        return self:pseudo_inverse():mul(b)
    end
end

return Matrix
