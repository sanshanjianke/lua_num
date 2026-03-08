-- 数值优化模块入口
local optimization = {}

-- 加载子模块
local basic = require("optimization.basic_optimization")
local gradient = require("optimization.gradient_methods")

-- 导出基础优化方法（无梯度）
optimization.golden_section = basic.golden_section
optimization.parabolic_interpolation = basic.parabolic_interpolation
optimization.fibonacci_search = basic.fibonacci_search
optimization.bisection = basic.bisection

-- 导出梯度相关优化方法
optimization.gradient_descent = gradient.gradient_descent
optimization.newton = gradient.newton
optimization.bfgs = gradient.bfgs
optimization.conjugate_gradient = gradient.conjugate_gradient
optimization.stochastic_gradient_descent = gradient.stochastic_gradient_descent

-- 别名
optimization.gs = optimization.golden_section
optimization.poly_interpol = optimization.parabolic_interpolation
optimization.fib_search = optimization.fibonacci_search
optimization.gd = optimization.gradient_descent
optimization.sgd = optimization.stochastic_gradient_descent
optimization.cg = optimization.conjugate_gradient
optimization.pr_cg = function(f, grad, x0, options)
    options = options or {}
    options.method = "Polak-Ribiere"
    return optimization.conjugate_gradient(f, grad, x0, options)
end
optimization.fr_cg = function(f, grad, x0, options)
    options = options or {}
    options.method = "Fletcher-Reeves"
    return optimization.conjugate_gradient(f, grad, x0, options)
end

-- 便捷函数：自动选择优化方法
-- @param f 目标函数
-- @param x0 初始点（对于一维优化是标量，对于多维优化是向量）
-- @param options 选项表，可包含：
--   - method: 方法名（"golden_section", "gradient_descent", "newton", "bfgs", "conjugate_gradient"）
--   - 其他方法特定的选项
-- @return 最优解，最优值，迭代次数，收敛信息（如果可用）
function optimization.optimize(f, x0, options)
    options = options or {}
    local method = options.method or "gradient_descent"

    -- 判断是一维优化还是多维优化
    local is_scalar = type(x0) == "number"

    if is_scalar then
        -- 一维优化
        local method_map = {
            golden_section = function()
                local a = options.a or x0 - 1
                local b = options.b or x0 + 1
                return optimization.golden_section(f, a, b, options.tol)
            end,
            parabolic_interpolation = function()
                local x1 = options.x1 or x0 - 0.1
                local x2 = options.x2 or x0
                local x3 = options.x3 or x0 + 0.1
                return optimization.parabolic_interpolation(f, x1, x2, x3, options.tol)
            end,
            fibonacci_search = function()
                local a = options.a or x0 - 1
                local b = options.b or x0 + 1
                return optimization.fibonacci_search(f, a, b, options.n)
            end
        }

        local method_func = method_map[method]
        if not method_func then
            error("Unknown 1D optimization method: " .. method)
        end

        return method_func()
    else
        -- 多维优化
        if not options.grad then
            error("Gradient function required for multi-dimensional optimization")
        end

        local method_map = {
            gradient_descent = function()
                return optimization.gradient_descent(f, options.grad, x0, options)
            end,
            newton = function()
                if not options.hessian then
                    error("Hessian function required for Newton's method")
                end
                return optimization.newton(f, options.grad, options.hessian, x0, options)
            end,
            bfgs = function()
                return optimization.bfgs(f, options.grad, x0, options)
            end,
            conjugate_gradient = function()
                return optimization.conjugate_gradient(f, options.grad, x0, options)
            end
        }

        local method_func = method_map[method]
        if not method_func then
            error("Unknown multi-dimensional optimization method: " .. method)
        end

        return method_func()
    end
end

-- 一维函数最小化（推荐方法）
-- @param f 目标函数
-- @param a 搜索区间左端点
-- @param b 搜索区间右端点
-- @param options 选项表
-- @return 最小值位置，最小值，迭代次数
function optimization.minimize_1d(f, a, b, options)
    return optimization.golden_section(f, a, b, options and options.tol)
end

-- 多维函数最小化（推荐方法）
-- @param f 目标函数
-- @param grad 梯度函数
-- @param x0 初始点
-- @param options 选项表
-- @return 最优解，最优值，迭代次数，收敛信息
function optimization.minimize(f, grad, x0, options)
    return optimization.bfgs(f, grad, x0, options)
end

-- 约束优化：惩罚函数法
-- @param f 目标函数
-- @param grad 梯度函数
-- @param x0 初始点
-- @param constraints 约束函数表，每个约束返回约束值（=0表示满足）
-- @param options 选项表：
--   - penalty: 惩罚系数（默认 1000）
--   - penalty_growth: 惩罚系数增长因子（默认 10）
--   - outer_iter: 外层迭代次数（默认 5）
--   - inner_opt: 内层优化方法（默认 "bfgs"）
-- @return 最优解，最优值
function optimization.penalty_method(f, grad, x0, constraints, options)
    options = options or {}
    local penalty = options.penalty or 1000
    local penalty_growth = options.penalty_growth or 10
    local outer_iter = options.outer_iter or 5
    local inner_opt = options.inner_opt or "bfgs"

    local x = {}
    for i = 1, #x0 do x[i] = x0[i] end

    -- 外层迭代：逐渐增加惩罚系数
    for outer = 1, outer_iter do
        -- 构造惩罚函数
        local penalty_f = function(x_in)
            local fx = f(x_in)
            local penalty_term = 0

            for _, constraint in ipairs(constraints) do
                local c = constraint(x_in)
                penalty_term = penalty_term + c * c
            end

            return fx + (penalty * penalty_term) / 2
        end

        -- 构造惩罚函数的梯度
        local penalty_grad = function(x_in)
            local gx = grad(x_in)
            local penalty_gx = {}
            for i = 1, #x_in do penalty_gx[i] = 0 end

            for _, constraint in ipairs(constraints) do
                local c = constraint(x_in)
                -- 数值计算约束的梯度
                local eps = 1e-8
                for i = 1, #x_in do
                    local x_plus = {}
                    for j = 1, #x_in do x_plus[j] = x_in[j] end
                    x_plus[i] = x_plus[i] + eps
                    local c_plus = constraint(x_plus)
                    local dc = (c_plus - c) / eps
                    penalty_gx[i] = penalty_gx[i] + c * dc
                end
            end

            local grad_out = {}
            for i = 1, #x_in do
                grad_out[i] = gx[i] + penalty * penalty_gx[i]
            end

            return grad_out
        end

        -- 内层优化
        if inner_opt == "bfgs" then
            x = optimization.bfgs(penalty_f, penalty_grad, x, options)
        elseif inner_opt == "gradient_descent" then
            x = optimization.gradient_descent(penalty_f, penalty_grad, x, options)
        elseif inner_opt == "conjugate_gradient" then
            x = optimization.conjugate_gradient(penalty_f, penalty_grad, x, options)
        else
            error("Unknown inner optimization method: " .. inner_opt)
        end

        -- 增加惩罚系数
        penalty = penalty * penalty_growth
    end

    return x, f(x)
end

return optimization
