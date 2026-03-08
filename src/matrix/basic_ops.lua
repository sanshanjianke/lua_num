-- 矩阵基础运算模块
local Matrix = require("matrix.matrix")
local utils = require("utils.init")
local Validator = utils.validators
local Typecheck = utils.typecheck

-- 加法
function Matrix:add(other)
    if type(other) == "number" then
        -- 标量加法
        local result = self:clone()
        for i = 1, self.rows do
            for j = 1, self.cols do
                result.data[i][j] = result.data[i][j] + other
            end
        end
        return result
    else
        -- 矩阵加法
        Validator.assert_same_dimensions(self, other)

        local result = Matrix.new({{}})
        result.rows = self.rows
        result.cols = self.cols
        result.data = {}

        for i = 1, self.rows do
            result.data[i] = {}
            for j = 1, self.cols do
                result.data[i][j] = self.data[i][j] + other.data[i][j]
            end
        end

        return result
    end
end

-- 减法
function Matrix:sub(other)
    if type(other) == "number" then
        -- 标量减法
        local result = self:clone()
        for i = 1, self.rows do
            for j = 1, self.cols do
                result.data[i][j] = result.data[i][j] - other
            end
        end
        return result
    else
        -- 矩阵减法
        Validator.assert_same_dimensions(self, other)

        local result = Matrix.new({{}})
        result.rows = self.rows
        result.cols = self.cols
        result.data = {}

        for i = 1, self.rows do
            result.data[i] = {}
            for j = 1, self.cols do
                result.data[i][j] = self.data[i][j] - other.data[i][j]
            end
        end

        return result
    end
end

-- 乘法
function Matrix:mul(other)
    if type(other) == "number" then
        -- 标量乘法
        local result = self:clone()
        for i = 1, self.rows do
            for j = 1, self.cols do
                result.data[i][j] = result.data[i][j] * other
            end
        end
        return result
    else
        -- 矩阵乘法
        Validator.assert_can_multiply(self, other)

        local result = Matrix.new({{}})
        result.rows = self.rows
        result.cols = other.cols
        result.data = {}

        for i = 1, self.rows do
            result.data[i] = {}
            for j = 1, other.cols do
                local sum = 0
                for k = 1, self.cols do
                    sum = sum + self.data[i][k] * other.data[k][j]
                end
                result.data[i][j] = sum
            end
        end

        return result
    end
end

-- 除法（标量）
function Matrix:div(scalar)
    Typecheck.check_number(scalar, "scalar")

    if math.abs(scalar) < utils.tiny then
        utils.Error.invalid_input("Division by zero or near-zero value")
    end

    return self:mul(1 / scalar)
end

-- 逐元素乘法（Hadamard 乘积）
function Matrix:elementwise_mul(other)
    Validator.assert_same_dimensions(self, other)

    local result = Matrix.new({{}})
    result.rows = self.rows
    result.cols = self.cols
    result.data = {}

    for i = 1, self.rows do
        result.data[i] = {}
        for j = 1, self.cols do
            result.data[i][j] = self.data[i][j] * other.data[i][j]
        end
    end

    return result
end

-- 逐元素除法
function Matrix:elementwise_div(other)
    Validator.assert_same_dimensions(self, other)

    local result = Matrix.new({{}})
    result.rows = self.rows
    result.cols = self.cols
    result.data = {}

    for i = 1, self.rows do
        result.data[i] = {}
        for j = 1, self.cols do
            if math.abs(other.data[i][j]) < utils.tiny then
                utils.Error.invalid_input("Division by zero in elementwise division")
            end
            result.data[i][j] = self.data[i][j] / other.data[i][j]
        end
    end

    return result
end

-- 逐元素幂
function Matrix:elementwise_pow(power)
    Typecheck.check_number(power, "power")

    local result = self:clone()
    for i = 1, self.rows do
        for j = 1, self.cols do
            result.data[i][j] = result.data[i][j] ^ power
        end
    end
    return result
end

-- 原地加法
function Matrix:add_inplace(other)
    if type(other) == "number" then
        for i = 1, self.rows do
            for j = 1, self.cols do
                self.data[i][j] = self.data[i][j] + other
            end
        end
    else
        Validator.assert_same_dimensions(self, other)
        for i = 1, self.rows do
            for j = 1, self.cols do
                self.data[i][j] = self.data[i][j] + other.data[i][j]
            end
        end
    end
    self:_invalidate_cache()
    return self
end

-- 原地减法
function Matrix:sub_inplace(other)
    if type(other) == "number" then
        for i = 1, self.rows do
            for j = 1, self.cols do
                self.data[i][j] = self.data[i][j] - other
            end
        end
    else
        Validator.assert_same_dimensions(self, other)
        for i = 1, self.rows do
            for j = 1, self.cols do
                self.data[i][j] = self.data[i][j] - other.data[i][j]
            end
        end
    end
    self:_invalidate_cache()
    return self
end

-- 原地标量乘法
function Matrix:mul_inplace(scalar)
    Typecheck.check_number(scalar, "scalar")
    for i = 1, self.rows do
        for j = 1, self.cols do
            self.data[i][j] = self.data[i][j] * scalar
        end
    end
    self:_invalidate_cache()
    return self
end

-- 运算符重载
Matrix.__add = Matrix.add
Matrix.__sub = Matrix.sub
Matrix.__mul = Matrix.mul
Matrix.__div = Matrix.div
Matrix.__unm = function(self)
    return self:mul(-1)
end
Matrix.__pow = function(self, power)
    return self:elementwise_pow(power)
end

-- 等价比较
function Matrix:__eq(other)
    if getmetatable(other) ~= Matrix then
        return false
    end
    if self.rows ~= other.rows or self.cols ~= other.cols then
        return false
    end
    for i = 1, self.rows do
        for j = 1, self.cols do
            if math.abs(self.data[i][j] - other.data[i][j]) > utils.epsilon * 10 then
                return false
            end
        end
    end
    return true
end

return Matrix
