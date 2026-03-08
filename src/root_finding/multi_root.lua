-- 多维根求解模块
-- 支持求解非线性方程组 F(x) = 0

local math = math
local utils = require("utils.init")

local multi_root = {}

-- =============================================================================
-- 辅助函数
-- =============================================================================

-- 向量范数
local function vec_norm(v)
    local sum = 0
    for i = 1, #v do
        sum = sum + v[i] * v[i]
    end
    return math.sqrt(sum)
end

-- 向量减法
local function vec_sub(a, b)
    local result = {}
    for i = 1, #a do
        result[i] = a[i] - b[i]
    end
    return result
end

-- 向量加法
local function vec_add(a, b)
    local result = {}
    for i = 1, #a do
        result[i] = a[i] + b[i]
    end
    return result
end

-- 标量乘向量
local function vec_scale(a, s)
    local result = {}
    for i = 1, #a do
        result[i] = a[i] * s
    end
    return result
end

-- 复制向量
local function vec_copy(v)
    local result = {}
    for i = 1, #v do
        result[i] = v[i]
    end
    return result
end

-- =============================================================================
-- 数值雅可比矩阵计算
-- =============================================================================

-- 数值计算雅可比矩阵（前向差分）
-- @param F 函数向量 F(x) 返回 {f1, f2, ...}
-- @param x 当前点
-- @param eps 差分步长（可选，默认 1e-8）
-- @return 雅可比矩阵 J[i][j] = dfi/dxj
local function numerical_jacobian(F, x, eps)
    eps = eps or 1e-8
    local n = #x
    local fx = F(x)
    local m = #fx

    local J = {}
    for i = 1, m do
        J[i] = {}
        for j = 1, n do
            J[i][j] = 0
        end
    end

    for j = 1, n do
        -- 构造扰动点
        local x_plus = vec_copy(x)
        local h = eps * math.max(1, math.abs(x[j]))
        x_plus[j] = x_plus[j] + h

        local fx_plus = F(x_plus)

        -- 计算差分
        for i = 1, m do
            J[i][j] = (fx_plus[i] - fx[i]) / h
        end
    end

    return J
end

-- =============================================================================
-- 线性求解器（用于求解线性方程组）
-- =============================================================================

-- 高斯消元法求解 Ax = b
local function solve_linear(A, b)
    local n = #A

    -- 创建增广矩阵
    local aug = {}
    for i = 1, n do
        aug[i] = {}
        for j = 1, n do
            aug[i][j] = A[i][j]
        end
        aug[i][n + 1] = b[i]
    end

    -- 前向消元
    for k = 1, n do
        -- 选主元
        local max_val = math.abs(aug[k][k])
        local max_row = k
        for i = k + 1, n do
            if math.abs(aug[i][k]) > max_val then
                max_val = math.abs(aug[i][k])
                max_row = i
            end
        end

        -- 交换行
        aug[k], aug[max_row] = aug[max_row], aug[k]

        if math.abs(aug[k][k]) < 1e-14 then
            error("Matrix is singular or nearly singular")
        end

        for i = k + 1, n do
            local factor = aug[i][k] / aug[k][k]
            for j = k, n + 1 do
                aug[i][j] = aug[i][j] - factor * aug[k][j]
            end
        end
    end

    -- 回代
    local x = {}
    for i = n, 1, -1 do
        local sum = aug[i][n + 1]
        for j = i + 1, n do
            sum = sum - aug[i][j] * x[j]
        end
        x[i] = sum / aug[i][i]
    end

    return x
end

-- =============================================================================
-- 牛顿法
-- =============================================================================

-- 牛顿法求解非线性方程组
-- @param F 函数向量 F(x) 返回 {f1, f2, ...}
-- @param x0 初始猜测
-- @param options 选项表：
--   - jacobian: 雅可比矩阵函数（可选，默认数值计算）
--   - tol: 收敛容差（默认 1e-10）
--   - max_iter: 最大迭代次数（默认 100）
--   - verbose: 是否打印迭代信息（默认 false）
-- @return 解向量，收敛标志，迭代次数
function multi_root.newton(F, x0, options)
    -- 参数验证
    utils.typecheck.check_type("newton", "F", F, "function")
    utils.typecheck.check_type("newton", "x0", x0, "table")

    options = options or {}
    local tol = options.tol or 1e-10
    local max_iter = options.max_iter or 100
    local verbose = options.verbose or false
    local jacobian_func = options.jacobian

    local x = vec_copy(x0)
    local n = #x

    for iter = 1, max_iter do
        -- 计算函数值
        local fx = F(x)

        -- 检查收敛
        local fx_norm = vec_norm(fx)
        if verbose then
            print(string.format("  iter %d: |F(x)| = %.2e", iter, fx_norm))
        end

        if fx_norm < tol then
            return x, true, iter
        end

        -- 计算雅可比矩阵
        local J
        if jacobian_func then
            J = jacobian_func(x)
        else
            J = numerical_jacobian(F, x)
        end

        -- 求解 J * delta = -F(x)
        local neg_fx = vec_scale(fx, -1)
        local delta = solve_linear(J, neg_fx)

        -- 更新 x
        x = vec_add(x, delta)

        -- 检查 delta 是否足够小
        if vec_norm(delta) < tol * math.max(1, vec_norm(x)) then
            return x, true, iter
        end
    end

    -- 未收敛
    return x, false, max_iter
end

-- =============================================================================
-- Broyden方法（拟牛顿法）
-- =============================================================================

-- Broyden方法求解非线性方程组
-- 不需要显式计算雅可比矩阵，使用秩1更新近似
-- @param F 函数向量
-- @param x0 初始猜测
-- @param options 选项表
-- @return 解向量，收敛标志，迭代次数
function multi_root.broyden(F, x0, options)
    -- 参数验证
    utils.typecheck.check_type("broyden", "F", F, "function")
    utils.typecheck.check_type("broyden", "x0", x0, "table")

    options = options or {}
    local tol = options.tol or 1e-10
    local max_iter = options.max_iter or 100
    local verbose = options.verbose or false

    local x = vec_copy(x0)
    local n = #x

    -- 初始雅可比逆的近似（使用单位矩阵的缩放）
    local fx = F(x)
    local fx_norm = vec_norm(fx)

    if fx_norm < tol then
        return x, true, 0
    end

    -- 初始 B（雅可比逆的近似）
    local B = {}
    for i = 1, n do
        B[i] = {}
        for j = 1, n do
            if i == j then
                B[i][j] = 1
            else
                B[i][j] = 0
            end
        end
    end

    -- 第一次迭代使用数值雅可比初始化
    local J = numerical_jacobian(F, x)
    -- 计算 J 的逆（使用高斯消元）
    local I = {}
    for i = 1, n do
        I[i] = {}
        for j = 1, n do
            if i == j then
                I[i][j] = 1
            else
                I[i][j] = 0
            end
        end
    end
    for i = 1, n do
        B[i] = solve_linear(J, I[i])
    end
    -- 转置
    local B_inv = {}
    for i = 1, n do
        B_inv[i] = {}
        for j = 1, n do
            B_inv[i][j] = B[j][i]
        end
    end
    B = B_inv

    for iter = 1, max_iter do
        -- 计算 delta = -B * F(x)
        local delta = {}
        for i = 1, n do
            local sum = 0
            for j = 1, n do
                sum = sum + B[i][j] * fx[j]
            end
            delta[i] = -sum
        end

        -- 更新 x
        local x_new = vec_add(x, delta)

        -- 计算新的函数值
        local fx_new = F(x_new)
        local fx_new_norm = vec_norm(fx_new)

        if verbose then
            print(string.format("  iter %d: |F(x)| = %.2e", iter, fx_new_norm))
        end

        if fx_new_norm < tol then
            return x_new, true, iter
        end

        -- Broyden更新
        -- s = x_new - x = delta
        -- y = F(x_new) - F(x)
        local y = vec_sub(fx_new, fx)

        -- B_new = B + (s - B*y) * y^T / (y^T * y)
        local By = {}
        for i = 1, n do
            local sum = 0
            for j = 1, n do
                sum = sum + B[i][j] * y[j]
            end
            By[i] = sum
        end

        local s_minus_By = vec_sub(delta, By)

        local yty = 0
        for i = 1, n do
            yty = yty + y[i] * y[i]
        end

        if yty > 1e-20 then
            for i = 1, n do
                for j = 1, n do
                    B[i][j] = B[i][j] + s_minus_By[i] * y[j] / yty
                end
            end
        end

        -- 更新
        x = x_new
        fx = fx_new
    end

    return x, false, max_iter
end

-- =============================================================================
-- 不动点迭代
-- =============================================================================

-- 不动点迭代求解 x = G(x)
-- @param G 迭代函数 G(x)
-- @param x0 初始猜测
-- @param options 选项表：
--   - tol: 收敛容差（默认 1e-10）
--   - max_iter: 最大迭代次数（默认 100）
--   - relaxation: 松弛因子（默认 1.0，< 1 为低松弛）
--   - verbose: 是否打印迭代信息
-- @return 解向量，收敛标志，迭代次数
function multi_root.fixed_point(G, x0, options)
    -- 参数验证
    utils.typecheck.check_type("fixed_point", "G", G, "function")
    utils.typecheck.check_type("fixed_point", "x0", x0, "table")

    options = options or {}
    local tol = options.tol or 1e-10
    local max_iter = options.max_iter or 100
    local relaxation = options.relaxation or 1.0
    local verbose = options.verbose or false

    local x = vec_copy(x0)

    for iter = 1, max_iter do
        local x_new = G(x)

        -- 应用松弛
        if relaxation ~= 1.0 then
            for i = 1, #x_new do
                x_new[i] = x[i] + relaxation * (x_new[i] - x[i])
            end
        end

        -- 计算差值
        local diff = vec_norm(vec_sub(x_new, x))

        if verbose then
            print(string.format("  iter %d: |x_new - x| = %.2e", iter, diff))
        end

        if diff < tol then
            return x_new, true, iter
        end

        x = x_new
    end

    return x, false, max_iter
end

-- =============================================================================
-- 信赖域方法
-- =============================================================================

-- 信赖域Dogleg方法
-- @param F 函数向量
-- @param x0 初始猜测
-- @param options 选项表
-- @return 解向量，收敛标志，迭代次数
function multi_root.trust_region(F, x0, options)
    -- 参数验证
    utils.typecheck.check_type("trust_region", "F", F, "function")
    utils.typecheck.check_type("trust_region", "x0", x0, "table")

    options = options or {}
    local tol = options.tol or 1e-10
    local max_iter = options.max_iter or 100
    local verbose = options.verbose or false
    local delta_max = options.delta_max or 10.0
    local eta = options.eta or 0.15

    local x = vec_copy(x0)
    local n = #x
    local delta = options.delta or 1.0

    for iter = 1, max_iter do
        local fx = F(x)
        local fx_norm = vec_norm(fx)

        if verbose then
            print(string.format("  iter %d: |F(x)| = %.2e, delta = %.4f", iter, fx_norm, delta))
        end

        if fx_norm < tol then
            return x, true, iter
        end

        -- 计算雅可比矩阵
        local J = numerical_jacobian(F, x)

        -- 计算 J^T * F（梯度）
        local JTF = {}
        for j = 1, n do
            local sum = 0
            for i = 1, n do
                sum = sum + J[i][j] * fx[i]
            end
            JTF[j] = sum
        end

        -- 计算柯西点（最速下降方向）
        local JTJ = {}
        for i = 1, n do
            JTJ[i] = {}
            for j = 1, n do
                local sum = 0
                for k = 1, n do
                    sum = sum + J[k][i] * J[k][j]
                end
                JTJ[i][j] = sum
            end
        end

        local JTFJTJ = {}
        for i = 1, n do
            local sum = 0
            for j = 1, n do
                sum = sum + JTJ[i][j] * JTF[j]
            end
            JTFJTJ[i] = sum
        end

        local alpha_c = 0
        local JTF_norm_sq = 0
        local JTFJTJ_norm_sq = 0
        for i = 1, n do
            JTF_norm_sq = JTF_norm_sq + JTF[i] * JTF[i]
            JTFJTJ_norm_sq = JTFJTJ_norm_sq + JTFJTJ[i] * JTFJTJ[i]
        end

        if JTFJTJ_norm_sq > 1e-20 then
            alpha_c = JTF_norm_sq / JTFJTJ_norm_sq
        end

        -- 柯西点
        local p_c = vec_scale(JTF, -alpha_c)
        local p_c_norm = vec_norm(p_c)

        -- 计算高斯-牛顿步
        local neg_fx = vec_scale(fx, -1)
        local p_gn = solve_linear(J, neg_fx)
        local p_gn_norm = vec_norm(p_gn)

        -- 选择步长
        local p
        if p_gn_norm <= delta then
            -- 使用高斯-牛顿步
            p = p_gn
        elseif p_c_norm >= delta then
            -- 沿柯西方向截断
            p = vec_scale(p_c, delta / p_c_norm)
        else
            -- Dogleg步
            -- 在 p_c 和 p_gn 之间插值
            local diff = vec_sub(p_gn, p_c)
            local a = 0
            for i = 1, n do
                a = a + diff[i] * diff[i]
            end
            local b = 0
            for i = 1, n do
                b = b + p_c[i] * diff[i]
            end
            local c = p_c_norm * p_c_norm - delta * delta

            local tau
            if a < 1e-20 then
                tau = 0
            else
                local disc = b * b - a * c
                if disc < 0 then
                    tau = -b / a
                else
                    tau = (-b + math.sqrt(disc)) / a
                end
            end
            tau = math.max(0, math.min(1, tau))

            p = vec_add(p_c, vec_scale(diff, tau))
        end

        -- 计算预测下降
        local predicted = 0
        for i = 1, n do
            predicted = predicted + fx[i] * fx[i]
        end
        local Jp = {}
        for i = 1, n do
            local sum = 0
            for j = 1, n do
                sum = sum + J[i][j] * p[j]
            end
            Jp[i] = sum
        end
        for i = 1, n do
            predicted = predicted + 2 * fx[i] * Jp[i]
        end
        for i = 1, n do
            predicted = predicted + Jp[i] * Jp[i]
        end
        predicted = -0.5 * predicted

        -- 试探新点
        local x_new = vec_add(x, p)
        local fx_new = F(x_new)
        local fx_new_norm = vec_norm(fx_new)

        -- 计算实际下降
        local actual = 0.5 * (fx_norm * fx_norm - fx_new_norm * fx_new_norm)

        -- 计算比率
        local rho = 0
        if math.abs(predicted) > 1e-20 then
            rho = actual / predicted
        end

        -- 更新信赖域半径
        if rho < 0.25 then
            delta = 0.25 * delta
        elseif rho > 0.75 and math.abs(vec_norm(p) - delta) < 1e-10 then
            delta = math.min(2 * delta, delta_max)
        end

        -- 接受或拒绝步
        if rho > eta then
            x = x_new
        end
    end

    return x, false, max_iter
end

-- =============================================================================
-- 统一接口
-- =============================================================================

-- 多维根求解统一接口
-- @param F 函数向量 F(x) 或函数表 {f1, f2, ...}
-- @param x0 初始猜测
-- @param options 选项表：
--   - method: 方法名（"newton", "broyden", "fixed_point", "trust_region"）
--   - 其他方法特定选项
-- @return 解向量，收敛标志，迭代次数
function multi_root.find_root(F, x0, options)
    options = options or {}
    local method = options.method or "newton"

    -- 如果 F 是函数表，转换为单一函数
    local F_func
    if type(F) == "table" then
        F_func = function(x)
            local result = {}
            for i, f in ipairs(F) do
                result[i] = f(x)
            end
            return result
        end
    else
        F_func = F
    end

    if method == "newton" then
        return multi_root.newton(F_func, x0, options)
    elseif method == "broyden" then
        return multi_root.broyden(F_func, x0, options)
    elseif method == "fixed_point" then
        -- 对于不动点迭代，需要构造 G(x) = x - F(x)
        local G = function(x)
            local fx = F_func(x)
            return vec_sub(x, fx)
        end
        return multi_root.fixed_point(G, x0, options)
    elseif method == "trust_region" then
        return multi_root.trust_region(F_func, x0, options)
    else
        error("Unknown root finding method: " .. method)
    end
end

-- 别名
multi_root.solve = multi_root.find_root
multi_root.nsolve = multi_root.find_root

return multi_root