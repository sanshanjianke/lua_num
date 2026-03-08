-- 输入验证模块
local Validator = {}
local Error = require("utils.error")

-- 矩阵验证
function Validator.is_matrix(data)
    if type(data) ~= "table" then
        return false
    end
    if #data == 0 then
        return true  -- 空矩阵
    end
    local cols = #data[1]
    for i, row in ipairs(data) do
        if type(row) ~= "table" or #row ~= cols then
            return false
        end
        for j, val in ipairs(row) do
            if type(val) ~= "number" then
                return false
            end
        end
    end
    return true
end

function Validator.is_square_matrix(matrix)
    return matrix.rows == matrix.cols
end

function Validator.same_dimensions(m1, m2)
    return m1.rows == m2.rows and m1.cols == m2.cols
end

function Validator.can_multiply(m1, m2)
    return m1.cols == m2.rows
end

-- 函数验证
function Validator.is_callable(fn)
    if type(fn) == "function" then
        return true
    end
    -- 检查是否有 __call 元方法
    local mt = getmetatable(fn)
    return mt and mt.__call ~= nil
end

-- 区间验证
function Validator.valid_interval(a, b)
    return type(a) == "number" and type(b) == "number" and a < b
end

function Validator.contains_root(f, a, b)
    local fa = f(a)
    local fb = f(b)
    return fa * fb <= 0
end

-- 数值验证
function Validator.is_finite(x)
    return type(x) == "number" and x == x and math.abs(x) < math.huge
end

function Validator.is_positive(x)
    return type(x) == "number" and x > 0
end

function Validator.is_integer(x)
    return type(x) == "number" and x == math.floor(x)
end

-- 向量验证
function Validator.is_vector(data)
    if type(data) ~= "table" then
        return false
    end
    for i, val in ipairs(data) do
        if type(val) ~= "number" then
            return false
        end
    end
    return true
end

-- 断言函数（抛出错误）
function Validator.assert_matrix(data)
    if not Validator.is_matrix(data) then
        Error.invalid_input("Input must be a valid matrix (2D array of numbers)")
    end
end

function Validator.assert_square_matrix(matrix)
    if not Validator.is_square_matrix(matrix) then
        Error.invalid_input("Matrix must be square")
    end
end

function Validator.assert_same_dimensions(m1, m2)
    if not Validator.same_dimensions(m1, m2) then
        Error.dimension_mismatch(
            string.format("%dx%d", m1.rows, m1.cols),
            string.format("%dx%d", m2.rows, m2.cols)
        )
    end
end

function Validator.assert_can_multiply(m1, m2)
    if not Validator.can_multiply(m1, m2) then
        Error.dimension_mismatch(
            string.format("%dx%d", m1.rows, m1.cols),
            string.format("%dx%d", m2.rows, m2.cols)
        )
    end
end

function Validator.assert_callable(fn, name)
    name = name or "function"
    if not Validator.is_callable(fn) then
        Error.invalid_input(string.format("%s must be callable", name))
    end
end

function Validator.assert_valid_interval(a, b)
    if not Validator.valid_interval(a, b) then
        Error.invalid_input(string.format("Invalid interval: [%f, %f]", a, b))
    end
end

return Validator
