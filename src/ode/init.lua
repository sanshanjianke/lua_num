-- 常微分方程模块入口
local ode = {}

-- 加载子模块
local basic = require("ode.basic_methods")
local advanced = require("ode.advanced_methods")

-- 导出基础方法
ode.euler = basic.euler
ode.heun = basic.heun
ode.midpoint = basic.midpoint

-- 导出高级方法
ode.runge_kutta4 = advanced.runge_kutta4
ode.rk4 = advanced.runge_kutta4
ode.rk45 = advanced.rk45
ode.adaptive_rk = advanced.adaptive_rk

-- 别名
ode.improved_euler = ode.heun
ode.rkf45 = ode.rk45

-- 便捷函数：求解ODE
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t_span 时间区间 {t0, t_end}
-- @param y0 初始值
-- @param options 选项表：
--   - method: 方法名（默认 "rk4"）
--   - h: 步长
--   - n_steps: 步数
--   - tol: 容差（自适应方法）
-- @return 时间数组，解数组
function ode.solve(f, t_span, y0, options)
    options = options or {}
    local method = options.method or "rk4"

    local t0 = t_span[1]
    local t_end = t_span[2]
    local h = options.h

    local method_map = {
        euler = function()
            return ode.euler(f, t0, y0, t_end, h, options)
        end,
        heun = function()
            return ode.heun(f, t0, y0, t_end, h, options)
        end,
        improved_euler = function()
            return ode.heun(f, t0, y0, t_end, h, options)
        end,
        midpoint = function()
            return ode.midpoint(f, t0, y0, t_end, h, options)
        end,
        rk4 = function()
            return ode.runge_kutta4(f, t0, y0, t_end, h, options)
        end,
        runge_kutta4 = function()
            return ode.runge_kutta4(f, t0, y0, t_end, h, options)
        end,
        rk45 = function()
            return ode.rk45(f, t0, y0, t_end, options)
        end,
        adaptive_rk = function()
            return ode.adaptive_rk(f, t0, y0, t_end, options)
        end
    }

    local method_func = method_map[method]
    if not method_func then
        error("Unknown ODE method: " .. method)
    end

    return method_func()
end

-- 求解ODE系统（方程组）
-- @param f_vec 微分函数向量 {f1, f2, ...}
-- @param t_span 时间区间
-- @param y0_vec 初始值向量
-- @param options 选项表
-- @return 时间数组，解数组
function ode.solve_system(f_vec, t_span, y0_vec, options)
    -- 构造统一的微分函数
    local f_combined = function(t, y)
        local dy = {}
        for i, f in ipairs(f_vec) do
            dy[i] = f(t, y)
        end
        return dy
    end

    return ode.solve(f_combined, t_span, y0_vec, options)
end

return ode