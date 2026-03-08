-- 高级插值方法模块
local advanced_interpolation = {}
local Validator = require("utils.validators")

-- 辅助函数：验证插值点
local function validate_interpolation_points(x_data, y_data)
    if not Validator.is_vector(x_data) then
        error("x_data must be a vector (1D array of numbers)")
    end
    if not Validator.is_vector(y_data) then
        error("y_data must be a vector (1D array of numbers)")
    end
    if #x_data ~= #y_data then
        error(string.format("x_data and y_data must have the same length (x: %d, y: %d)",
            #x_data, #y_data))
    end
    if #x_data < 2 then
        error("At least 2 data points are required for interpolation")
    end

    -- 检查x点是否严格递增
    for i = 2, #x_data do
        if x_data[i] <= x_data[i-1] then
            error(string.format("x_data must be strictly increasing (x[%d]=%f <= x[%d]=%f)",
                i, x_data[i], i-1, x_data[i-1]))
        end
    end
end

-- 辅助函数：三对角矩阵求解器（追赶法）
-- 用于求解样条插值的线性方程组
-- @param a 下对角线元素
-- @param b 主对角线元素
-- @param c 上对角线元素
-- @param d 右端向量
-- @return 解向量
local function tridiagonal_solver(a, b, c, d)
    local n = #b

    -- 前向消元
    local c_prime = {}
    local d_prime = {}

    c_prime[1] = c[1] / b[1]
    d_prime[1] = d[1] / b[1]

    for i = 2, n do
        local denom = b[i] - a[i] * c_prime[i-1]
        c_prime[i] = (i < n) and (c[i] / denom) or 0
        d_prime[i] = (d[i] - a[i] * d_prime[i-1]) / denom
    end

    -- 回代
    local x = {}
    x[n] = d_prime[n]

    for i = n - 1, 1, -1 do
        x[i] = d_prime[i] - c_prime[i] * x[i + 1]
    end

    return x
end

-- 辅助函数：查找插值区间
local function find_interval(x, x_data)
    local n = #x_data
    if x < x_data[1] or x > x_data[n] then
        error(string.format("x is outside the interpolation range [%f, %f]",
            x_data[1], x_data[n]))
    end

    -- 二分查找
    local low, high = 1, n - 1
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if x_data[mid] <= x and x <= x_data[mid + 1] then
            return mid
        elseif x < x_data[mid] then
            high = mid - 1
        else
            low = mid + 1
        end
    end

    return n - 1
end

-- 三次样条插值 - 自然样条（自然边界条件）
-- 使用三次样条函数进行插值，两端二阶导数为0
-- @param x 要插值的点（单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @return 插值结果
function advanced_interpolation.spline(x, x_data, y_data)
    validate_interpolation_points(x_data, y_data)

    local n = #x_data

    if n == 2 then
        -- 只有两个点，退化为线性插值
        local basic = require("interpolation.basic_interpolation")
        return basic.linear(x, x_data, y_data)
    end

    -- 计算三次样条系数
    local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, "natural")

    -- 判断输入是单个值还是数组
    local is_array = type(x) == "table" and #x > 0

    if is_array then
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = advanced_interpolation.spline_single(xi, x_data, coeffs)
        end
        return results
    else
        return advanced_interpolation.spline_single(x, x_data, coeffs)
    end
end

-- 计算三次样条系数（内部使用）
-- @param x_data x坐标数组
-- @param y_data y坐标数组
-- @param bc 边界条件类型： "natural" 或 "clamped"
-- @param bc_values 边界值（仅用于clamped条件）[dy0, dyn]
-- @return 样条系数表 {a, b, c, d}
function advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)
    local n = #x_data
    bc = bc or "natural"

    -- 计算区间长度和斜率
    local h = {}  -- 区间长度
    local mu = {} -- 比值 h[i]/(h[i] + h[i+1])
    local lam = {} -- 比值 h[i+1]/(h[i] + h[i+1])
    local delta = {} -- 斜率

    for i = 1, n - 1 do
        h[i] = x_data[i + 1] - x_data[i]
        if h[i] <= 0 then
            error("x_data must be strictly increasing")
        end
        delta[i] = (y_data[i + 1] - y_data[i]) / h[i]
    end

    for i = 2, n - 1 do
        mu[i] = h[i - 1] / (h[i - 1] + h[i])
        lam[i] = h[i] / (h[i - 1] + h[i])
    end

    -- 建立三对角矩阵，求解二阶导数 M[i]
    local a = {}
    local b = {}
    local c = {}
    local d = {}

    -- 自然边界条件：M[1] = M[n] = 0
    if bc == "natural" then
        b[1] = 1
        a[1] = 0
        c[1] = 0
        d[1] = 0

        b[n] = 1
        a[n] = 0
        c[n] = 0
        d[n] = 0

        for i = 2, n - 1 do
            a[i] = mu[i]
            b[i] = 2
            c[i] = lam[i]
            d[i] = 6 * (delta[i] - delta[i - 1]) / (h[i - 1] + h[i])
        end
    elseif bc == "clamped" then
        -- 固定边界条件：指定端点的一阶导数
        if not bc_values or #bc_values ~= 2 then
            error("clamped boundary condition requires bc_values = {dy0, dyn}")
        end

        local dy0, dyn = bc_values[1], bc_values[2]

        b[1] = 2 * h[1]
        a[1] = 0
        c[1] = h[1]
        d[1] = 6 * (delta[1] - dy0)

        a[n] = h[n - 1]
        b[n] = 2 * h[n - 1]
        c[n] = 0
        d[n] = 6 * (dyn - delta[n - 1])

        for i = 2, n - 1 do
            a[i] = mu[i]
            b[i] = 2
            c[i] = lam[i]
            d[i] = 6 * (delta[i] - delta[i - 1]) / (h[i - 1] + h[i])
        end
    else
        error(string.format("Unknown boundary condition: %s", bc))
    end

    -- 求解三对角方程组
    local M = tridiagonal_solver(a, b, c, d)

    -- 计算样条系数
    local coeffs = {
        a = {},  -- y[i]
        b = {},  -- (y[i+1] - y[i])/h[i] - h[i]*M[i]/2 - h[i]*(M[i+1] - M[i])/6
        c = {},  -- M[i]/2
        d = {}   -- (M[i+1] - M[i])/(6*h[i])
    }

    for i = 1, n - 1 do
        coeffs.a[i] = y_data[i]
        coeffs.b[i] = delta[i] - h[i] * (2 * M[i] + M[i + 1]) / 6
        coeffs.c[i] = M[i] / 2
        coeffs.d[i] = (M[i + 1] - M[i]) / (6 * h[i])
    end

    coeffs.M = M  -- 存储二阶导数，用于边界条件检查
    coeffs.h = h  -- 存储区间长度

    return coeffs
end

-- 三次样条插值的单个点计算（内部使用）
-- @param x 要插值的点
-- @param x_data x坐标数组
-- @param coeffs 样条系数表
-- @return 插值结果
function advanced_interpolation.spline_single(x, x_data, coeffs)
    local n = #x_data

    -- 处理端点
    if x == x_data[1] then
        return coeffs.a[1]
    elseif x == x_data[n] then
        return coeffs.a[n - 1] +
               coeffs.b[n - 1] * coeffs.h[n - 1] +
               coeffs.c[n - 1] * coeffs.h[n - 1]^2 +
               coeffs.d[n - 1] * coeffs.h[n - 1]^3
    end

    -- 查找区间
    local i = find_interval(x, x_data)
    local dx = x - x_data[i]

    -- 三次样条公式
    return coeffs.a[i] +
           coeffs.b[i] * dx +
           coeffs.c[i] * dx^2 +
           coeffs.d[i] * dx^3
end

-- 三次样条插值 - 固定边界条件
-- 在端点处指定一阶导数值
-- @param x 要插值的点
-- @param x_data x坐标数组
-- @param y_data y坐标数组
-- @param dy0 起点的一阶导数
-- @param dyn 终点的一阶导数
-- @return 插值结果
function advanced_interpolation.spline_clamped(x, x_data, y_data, dy0, dyn)
    validate_interpolation_points(x_data, y_data)

    local n = #x_data
    if n < 3 then
        local basic = require("interpolation.basic_interpolation")
        return basic.linear(x, x_data, y_data)
    end

    -- 计算固定边界条件的样条系数
    local coeffs = advanced_interpolation.compute_spline_coefficients(
        x_data, y_data, "clamped", {dy0, dyn}
    )

    -- 判断输入是单个值还是数组
    local is_array = type(x) == "table" and #x > 0

    if is_array then
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = advanced_interpolation.spline_single(xi, x_data, coeffs)
        end
        return results
    else
        return advanced_interpolation.spline_single(x, x_data, coeffs)
    end
end

-- 样条插值的导数计算
-- 计算样条函数在给定点的一阶导数
-- @param x 要计算导数的点
-- @param x_data x坐标数组
-- @param y_data y坐标数组
-- @param bc 边界条件类型（可选，默认"natural"）
-- @param bc_values 边界值（可选）
-- @return 导数值
function advanced_interpolation.spline_derivative(x, x_data, y_data, bc, bc_values)
    local n = #x_data
    if n < 3 then
        -- 退化为线性插值，导数为常数
        local basic = require("interpolation.basic_interpolation")
        local h = x_data[2] - x_data[1]
        return (y_data[2] - y_data[1]) / h
    end

    bc = bc or "natural"
    local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)

    -- 计算导数
    local i = find_interval(x, x_data)
    local dx = x - x_data[i]

    -- 样条一阶导数: S'(x) = b + 2*c*dx + 3*d*dx^2
    return coeffs.b[i] + 2 * coeffs.c[i] * dx + 3 * coeffs.d[i] * dx^2
end

-- 样条插值的二阶导数计算
-- @param x 要计算导数的点
-- @param x_data x坐标数组
-- @param y_data y坐标数组
-- @param bc 边界条件类型（可选，默认"natural"）
-- @param bc_values 边界值（可选）
-- @return 二阶导数值
function advanced_interpolation.spline_derivative2(x, x_data, y_data, bc, bc_values)
    local n = #x_data
    if n < 3 then
        -- 退化为线性插值，二阶导数为0
        return 0
    end

    bc = bc or "natural"
    local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)

    -- 计算二阶导数
    local i = find_interval(x, x_data)
    local dx = x - x_data[i]

    -- 样条二阶导数: S''(x) = 2*c + 6*d*dx
    return 2 * coeffs.c[i] + 6 * coeffs.d[i] * dx
end

return advanced_interpolation
