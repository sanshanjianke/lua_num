-- Vector 基础运算
local Vector = require("vector.vector")
local utils = require("utils.init")
local Typecheck = utils.typecheck

-- 深度复制数组
local function deepcopy(src)
    local dest = {}
    for i = 1, #src do
        dest[i] = src[i]
    end
    return dest
end

-- 加法（Vector + Vector 或 Vector + 标量）
function Vector.__add(a, b)
    local result

    if type(b) == "table" and getmetatable(b) == Vector then
        -- Vector + Vector
        if a.size ~= b.size then
            utils.Error.dimension_mismatch(a.size, b.size)
        end

        result = {}
        for i = 1, a.size do
            result[i] = a.data[i] + b.data[i]
        end
        return Vector.new(result)
    elseif type(b) == "number" then
        -- Vector + 标量
        result = {}
        for i = 1, a.size do
            result[i] = a.data[i] + b
        end
        return Vector.new(result)
    else
        utils.Error.invalid_input("Invalid operand for Vector addition")
    end
end

-- 减法（Vector - Vector 或 Vector - 标量）
function Vector.__sub(a, b)
    local result

    if type(b) == "table" and getmetatable(b) == Vector then
        -- Vector - Vector
        if a.size ~= b.size then
            utils.Error.dimension_mismatch(a.size, b.size)
        end

        result = {}
        for i = 1, a.size do
            result[i] = a.data[i] - b.data[i]
        end
        return Vector.new(result)
    elseif type(b) == "number" then
        -- Vector - 标量
        result = {}
        for i = 1, a.size do
            result[i] = a.data[i] - b
        end
        return Vector.new(result)
    else
        utils.Error.invalid_input("Invalid operand for Vector subtraction")
    end
end

-- 乘法（Vector * 标量）
function Vector.__mul(a, b)
    local result

    if type(a) == "number" and type(b) == "table" and getmetatable(b) == Vector then
        -- 标量 * Vector
        result = {}
        for i = 1, b.size do
            result[i] = a * b.data[i]
        end
        return Vector.new(result)
    elseif type(b) == "number" then
        -- Vector * 标量
        result = {}
        for i = 1, a.size do
            result[i] = a.data[i] * b
        end
        return Vector.new(result)
    else
        utils.Error.invalid_input("Invalid operand for Vector multiplication")
    end
end

-- 除法（Vector / 标量）
function Vector.__div(a, b)
    if type(b) ~= "number" or b == 0 then
        utils.Error.invalid_input("Vector can only be divided by a non-zero scalar")
    end

    local result = {}
    for i = 1, a.size do
        result[i] = a.data[i] / b
    end
    return Vector.new(result)
end

-- 负号（-Vector）
function Vector.__unm(a)
    local result = {}
    for i = 1, a.size do
        result[i] = -a.data[i]
    end
    return Vector.new(result)
end

-- 相等比较
function Vector.__eq(a, b)
    if type(b) ~= "table" or getmetatable(b) ~= Vector then
        return false
    end

    if a.size ~= b.size then
        return false
    end

    for i = 1, a.size do
        if math.abs(a.data[i] - b.data[i]) > utils.epsilon then
            return false
        end
    end

    return true
end

-- 点积
function Vector:dot(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local sum = 0
    for i = 1, self.size do
        sum = sum + self.data[i] * other.data[i]
    end
    return sum
end

-- 标量积（点积别名）
function Vector:scalar_product(other)
    return self:dot(other)
end

-- 原地加法
function Vector:add_inplace(other)
    if type(other) == "number" then
        for i = 1, self.size do
            self.data[i] = self.data[i] + other
        end
    elseif type(other) == "table" and getmetatable(other) == Vector then
        if self.size ~= other.size then
            utils.Error.dimension_mismatch(self.size, other.size)
        end
        for i = 1, self.size do
            self.data[i] = self.data[i] + other.data[i]
        end
    else
        utils.Error.invalid_input("Invalid operand for in-place addition")
    end

    self:_invalidate_cache()
end

-- 原地减法
function Vector:sub_inplace(other)
    if type(other) == "number" then
        for i = 1, self.size do
            self.data[i] = self.data[i] - other
        end
    elseif type(other) == "table" and getmetatable(other) == Vector then
        if self.size ~= other.size then
            utils.Error.dimension_mismatch(self.size, other.size)
        end
        for i = 1, self.size do
            self.data[i] = self.data[i] - other.data[i]
        end
    else
        utils.Error.invalid_input("Invalid operand for in-place subtraction")
    end

    self:_invalidate_cache()
end

-- 原地乘法
function Vector:mul_inplace(scalar)
    Typecheck.check_number(scalar, "scalar")

    for i = 1, self.size do
        self.data[i] = self.data[i] * scalar
    end

    self:_invalidate_cache()
end

-- 原地除法
function Vector:div_inplace(scalar)
    Typecheck.check_number(scalar, "scalar")

    if scalar == 0 then
        utils.Error.invalid_input("Division by zero")
    end

    for i = 1, self.size do
        self.data[i] = self.data[i] / scalar
    end

    self:_invalidate_cache()
end

-- 逐元素乘法（Hadamard 乘积）
function Vector:elementwise_mul(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local result = {}
    for i = 1, self.size do
        result[i] = self.data[i] * other.data[i]
    end
    return Vector.new(result)
end

-- 逐元素除法
function Vector:elementwise_div(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local result = {}
    for i = 1, self.size do
        if other.data[i] == 0 then
            utils.Error.invalid_input("Division by zero at index " .. i)
        end
        result[i] = self.data[i] / other.data[i]
    end
    return Vector.new(result)
end

-- 逐元素幂
function Vector:elementwise_pow(power)
    Typecheck.check_number(power, "power")

    local result = {}
    for i = 1, self.size do
        result[i] = self.data[i] ^ power
    end
    return Vector.new(result)
end

-- 拼接向量
function Vector:concat(other)
    Typecheck.check_type(other, Vector, "other")

    local result = {}
    for i = 1, self.size do
        result[i] = self.data[i]
    end
    for i = 1, other.size do
        result[self.size + i] = other.data[i]
    end
    return Vector.new(result)
end

-- 填充向量
function Vector:fill(value)
    Typecheck.check_number(value, "value")

    for i = 1, self.size do
        self.data[i] = value
    end

    self:_invalidate_cache()
end

-- 重置向量
function Vector:reset()
    self:fill(0)
end

-- 交换元素
function Vector:swap(i, j)
    Typecheck.check_positive_integer(i, "i")
    Typecheck.check_positive_integer(j, "j")

    if i > self.size or j > self.size then
        utils.Error.out_of_bounds("index", self.size)
    end

    self.data[i], self.data[j] = self.data[j], self.data[i]
    self:_invalidate_cache()
end

-- 反转向量
function Vector:reverse()
    local result = {}
    for i = 1, self.size do
        result[i] = self.data[self.size - i + 1]
    end
    return Vector.new(result)
end

-- 排序
function Vector:sort(reverse)
    local result = deepcopy(self.data)
    if reverse then
        table.sort(result, function(a, b) return a > b end)
    else
        table.sort(result)
    end
    return Vector.new(result)
end

-- 原地排序
function Vector:sort_inplace(reverse)
    if reverse then
        table.sort(self.data, function(a, b) return a > b end)
    else
        table.sort(self.data)
    end
end

return Vector
