-- 基本数值积分方法
-- 包括梯形法和辛普森法

local math = math
local utils = require("utils.init")

-- 基本积分方法模块
local basic_integration = {}

-- 梯形法
-- @param f 要积分的函数，接受一个数值参数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 子区间数（可选，默认为100）
-- @return 积分近似值
function basic_integration.trapezoidal(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 100
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    if a == b then
        return 0
    end

    local h = (b - a) / n
    local sum = (f(a) + f(b)) / 2

    for i = 1, n - 1 do
        sum = sum + f(a + i * h)
    end

    return sum * h
end

-- 辛普森法（需要偶数个子区间）
-- @param f 要积分的函数，接受一个数值参数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 子区间数（可选，默认为100，必须是偶数）
-- @return 积分近似值
function basic_integration.simpson(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 100
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    -- 辛普森法需要偶数个子区间
    if n % 2 ~= 0 then
        n = n + 1  -- 调整为偶数
    end

    if a == b then
        return 0
    end

    local h = (b - a) / n
    local sum = f(a) + f(b)

    -- 奇数索引点（系数为4）
    for i = 1, n - 1, 2 do
        sum = sum + 4 * f(a + i * h)
    end

    -- 偶数索引点（系数为2）
    for i = 2, n - 2, 2 do
        sum = sum + 2 * f(a + i * h)
    end

    return sum * h / 3
end

-- 中点法则
-- @param f 要积分的函数，接受一个数值参数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 子区间数（可选，默认为100）
-- @return 积分近似值
function basic_integration.midpoint(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 100
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    if a == b then
        return 0
    end

    local h = (b - a) / n
    local sum = 0

    for i = 0, n - 1 do
        sum = sum + f(a + (i + 0.5) * h)
    end

    return sum * h
end

-- 左端点法则
-- @param f 要积分的函数，接受一个数值参数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 子区间数（可选，默认为100）
-- @return 积分近似值
function basic_integration.left_endpoint(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 100
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    if a == b then
        return 0
    end

    local h = (b - a) / n
    local sum = 0

    for i = 0, n - 1 do
        sum = sum + f(a + i * h)
    end

    return sum * h
end

-- 右端点法则
-- @param f 要积分的函数，接受一个数值参数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 子区间数（可选，默认为100）
-- @return 积分近似值
function basic_integration.right_endpoint(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 100
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    if a == b then
        return 0
    end

    local h = (b - a) / n
    local sum = 0

    for i = 1, n do
        sum = sum + f(a + i * h)
    end

    return sum * h
end

return basic_integration
