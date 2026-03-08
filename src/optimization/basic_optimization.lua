-- 基础优化方法：不需要导数的优化算法
local utils = require("utils.init")

local basic_optimization = {}

-- 黄金分割法：寻找单峰函数的最小值
-- @param f 目标函数
-- @param a 搜索区间左端点
-- @param b 搜索区间右端点
-- @param tol 容差（默认 1e-6）
-- @return 最小值位置，最小值，迭代次数
function basic_optimization.golden_section(f, a, b, tol)
    -- 参数验证
    utils.typecheck.check_type("golden_section", "f", f, "function")
    utils.typecheck.check_type("golden_section", "a", a, "number")
    utils.typecheck.check_type("golden_section", "b", b, "number")
    utils.typecheck.check_type("golden_section", "tol", tol, "number", "nil")

    if a >= b then
        utils.Error.invalid_argument("golden_section", "a must be less than b")
    end

    tol = tol or 1e-6

    -- 黄金分割比
    local golden_ratio = (math.sqrt(5) - 1) / 2  -- 约 0.618

    -- 初始化两点
    local c = b - golden_ratio * (b - a)
    local d = a + golden_ratio * (b - a)

    local fc = f(c)
    local fd = f(d)

    local iter = 0
    local max_iter = 1000

    -- 迭代
    while (b - a) > tol and iter < max_iter do
        iter = iter + 1

        if fc < fd then
            b = d
            d = c
            fd = fc
            c = b - golden_ratio * (b - a)
            fc = f(c)
        else
            a = c
            c = d
            fc = fd
            d = a + golden_ratio * (b - a)
            fd = f(d)
        end
    end

    -- 返回区间中点作为最优解
    local x_opt = (a + b) / 2
    return x_opt, f(x_opt), iter
end

-- 抛物线插值法：使用三点抛物线拟合寻找极值点
-- @param f 目标函数
-- @param x1, x2, x3 三个点的 x 坐标
-- @param tol 容差（默认 1e-6）
-- @return 最小值位置，最小值，迭代次数
function basic_optimization.parabolic_interpolation(f, x1, x2, x3, tol)
    -- 参数验证
    utils.typecheck.check_type("parabolic_interpolation", "f", f, "function")
    utils.typecheck.check_type("parabolic_interpolation", "x1", x1, "number")
    utils.typecheck.check_type("parabolic_interpolation", "x2", x2, "number")
    utils.typecheck.check_type("parabolic_interpolation", "x3", x3, "number")
    utils.typecheck.check_type("parabolic_interpolation", "tol", tol, "number", "nil")

    tol = tol or 1e-6

    local f1 = f(x1)
    local f2 = f(x2)
    local f3 = f(x3)

    local iter = 0
    local max_iter = 1000

    -- 找到当前最优点
    local x_best, f_best = x1, f1
    if f2 < f_best then x_best, f_best = x2, f2 end
    if f3 < f_best then x_best, f_best = x3, f3 end

    -- 迭代
    while iter < max_iter do
        iter = iter + 1

        -- 计算抛物线极值点
        local denom = 2 * ((x2 - x1) * (f3 - f2) - (x3 - x2) * (f2 - f1))

        if math.abs(denom) < utils.tiny then
            -- 分母接近零，返回当前最优点
            break
        end

        local x_opt = x2 - ((x3 - x2) * (x3 - x2) * (f2 - f1) -
                            (x1 - x2) * (x1 - x2) * (f3 - f2)) / denom

        -- 确保新点在三点确定的区间内
        local x_min = math.min(x1, x2, x3)
        local x_max = math.max(x1, x2, x3)
        if x_opt < x_min or x_opt > x_max then
            break
        end

        -- 如果变化太小，停止迭代
        if math.abs(x_opt - x_best) < tol then
            break
        end

        local f_opt = f(x_opt)

        -- 更新最优点
        if f_opt < f_best then
            x_best, f_best = x_opt, f_opt
        end

        -- 用新点替换函数值最大的点
        local x_max_f, f_max = x1, f1
        if f2 > f_max then x_max_f, f_max = x2, f2 end
        if f3 > f_max then x_max_f, f_max = x3, f3 end

        if x_max_f == x1 then
            x1, f1 = x_opt, f_opt
        elseif x_max_f == x2 then
            x2, f2 = x_opt, f_opt
        else
            x3, f3 = x_opt, f_opt
        end
    end

    return x_best, f_best, iter
end

-- 斐波那契搜索：使用斐波那契数列进行区间缩小
-- @param f 目标函数
-- @param a 搜索区间左端点
-- @param b 搜索区间右端点
-- @param n 迭代次数（默认 20）
-- @return 最小值位置，最小值
function basic_optimization.fibonacci_search(f, a, b, n)
    -- 参数验证
    utils.typecheck.check_type("fibonacci_search", "f", f, "function")
    utils.typecheck.check_type("fibonacci_search", "a", a, "number")
    utils.typecheck.check_type("fibonacci_search", "b", b, "number")
    utils.typecheck.check_type("fibonacci_search", "n", n, "number", "nil")

    if a >= b then
        utils.Error.invalid_argument("fibonacci_search", "a must be less than b")
    end

    n = n or 20

    -- 生成斐波那契数列: F[1]=1, F[2]=1, F[3]=2, ...
    local F = {}
    F[0] = 1
    F[1] = 1
    for i = 2, n + 2 do
        F[i] = F[i-1] + F[i-2]
    end

    -- 初始区间
    local left, right = a, b
    local L = right - left

    -- 初始两点位置
    local rho = 1 - F[n] / F[n+1]
    local x1 = left + rho * L
    local x2 = right - rho * L

    local f1 = f(x1)
    local f2 = f(x2)

    -- 迭代
    for k = 1, n do
        if f1 > f2 then
            -- 最小值在 [x1, right]
            left = x1
            x1 = x2
            f1 = f2
            L = right - left
            rho = 1 - F[n-k] / F[n-k+1]
            x2 = right - rho * L
            f2 = f(x2)
        else
            -- 最小值在 [left, x2]
            right = x2
            x2 = x1
            f2 = f1
            L = right - left
            rho = 1 - F[n-k] / F[n-k+1]
            x1 = left + rho * L
            f1 = f(x1)
        end
    end

    -- 返回最终区间中点
    local x_opt = (left + right) / 2
    return x_opt, f(x_opt)
end

-- 二分搜索法（用于单调函数）
-- @param f 目标函数（单调函数）
-- @param a 搜索区间左端点
-- @param b 搜索区间右端点
-- @param tol 容差（默认 1e-6）
-- @return 零点位置，函数值，迭代次数
function basic_optimization.bisection(f, a, b, tol)
    -- 参数验证
    utils.typecheck.check_type("bisection", "f", f, "function")
    utils.typecheck.check_type("bisection", "a", a, "number")
    utils.typecheck.check_type("bisection", "b", b, "number")
    utils.typecheck.check_type("bisection", "tol", tol, "number", "nil")

    if a >= b then
        utils.Error.invalid_argument("bisection", "a must be less than b")
    end

    tol = tol or 1e-6

    local fa = f(a)
    local fb = f(b)

    -- 检查端点是否已满足条件
    if math.abs(fa) < tol then
        return a, fa, 0
    end
    if math.abs(fb) < tol then
        return b, fb, 0
    end

    -- 检查是否有根（函数值异号）
    if fa * fb > 0 then
        utils.Error.invalid_argument("bisection", "function values at endpoints must have opposite signs")
    end

    local iter = 0
    local max_iter = 1000

    -- 迭代
    while (b - a) > tol and iter < max_iter do
        iter = iter + 1

        local c = (a + b) / 2
        local fc = f(c)

        if math.abs(fc) < tol then
            return c, fc, iter
        end

        if fa * fc < 0 then
            b = c
            fb = fc
        else
            a = c
            fa = fc
        end
    end

    local x_opt = (a + b) / 2
    return x_opt, f(x_opt), iter
end

return basic_optimization
