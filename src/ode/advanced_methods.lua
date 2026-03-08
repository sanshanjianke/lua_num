-- 高级常微分方程求解方法
local utils = require("utils.init")

local advanced_methods = {}

-- 四阶龙格-库塔方法（经典RK4）
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t0 初始时间
-- @param y0 初始值（可以是标量或向量）
-- @param t_end 终止时间
-- @param h 步长（可选）
-- @param options 选项表
-- @return 时间数组，解数组
function advanced_methods.runge_kutta4(f, t0, y0, t_end, h, options)
    -- 参数验证
    utils.typecheck.check_type("runge_kutta4", "f", f, "function")
    utils.typecheck.check_type("runge_kutta4", "t0", t0, "number")
    utils.typecheck.check_type("runge_kutta4", "t_end", t_end, "number")
    utils.typecheck.check_type("runge_kutta4", "h", h, "number", "nil")
    utils.typecheck.check_type("runge_kutta4", "options", options, "table", "nil")

    options = options or {}

    -- 确定步长和步数
    local n_steps
    if options.n_steps then
        n_steps = options.n_steps
        h = (t_end - t0) / n_steps
    else
        h = h or 0.01
        n_steps = math.floor((t_end - t0) / h)
    end

    -- 判断是标量还是向量
    local is_vector = type(y0) == "table"

    -- 辅助函数：向量加法
    local function vec_add_scaled(a, b, scale)
        if not is_vector then return a + scale * b end
        local result = {}
        for i = 1, #a do
            result[i] = a[i] + scale * b[i]
        end
        return result
    end

    -- 初始化结果数组
    local t_vals = {t0}
    local y_vals = {}
    if is_vector then
        y_vals[1] = {}
        for i = 1, #y0 do
            y_vals[1][i] = y0[i]
        end
    else
        y_vals[1] = y0
    end

    -- 当前状态
    local t = t0
    local y
    if is_vector then
        y = {}
        for i = 1, #y0 do y[i] = y0[i] end
    else
        y = y0
    end

    -- 迭代
    for i = 1, n_steps do
        -- RK4 系数
        local k1 = f(t, y)
        local k2 = f(t + 0.5 * h, vec_add_scaled(y, k1, 0.5 * h))
        local k3 = f(t + 0.5 * h, vec_add_scaled(y, k2, 0.5 * h))
        local k4 = f(t + h, vec_add_scaled(y, k3, h))

        -- 更新：y_{n+1} = y_n + h/6 * (k1 + 2*k2 + 2*k3 + k4)
        if is_vector then
            local y_new = {}
            for j = 1, #y do
                y_new[j] = y[j] + h / 6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j])
            end
            y = y_new
        else
            y = y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        end

        t = t + h

        -- 存储结果
        t_vals[i + 1] = t
        if is_vector then
            y_vals[i + 1] = {}
            for j = 1, #y do
                y_vals[i + 1][j] = y[j]
            end
        else
            y_vals[i + 1] = y
        end
    end

    return t_vals, y_vals
end

-- RK45 自适应步长方法（使用步长加倍法）
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t0 初始时间
-- @param y0 初始值
-- @param t_end 终止时间
-- @param options 选项表：
--   - tol: 容差（默认 1e-6）
--   - h_init: 初始步长（可选）
--   - h_min: 最小步长（默认 1e-10）
--   - h_max: 最大步长（可选）
--   - max_steps: 最大步数（默认 10000）
-- @return 时间数组，解数组
function advanced_methods.rk45(f, t0, y0, t_end, options)
    -- 参数验证
    utils.typecheck.check_type("rk45", "f", f, "function")
    utils.typecheck.check_type("rk45", "t0", t0, "number")
    utils.typecheck.check_type("rk45", "t_end", t_end, "number")
    utils.typecheck.check_type("rk45", "options", options, "table", "nil")

    options = options or {}
    local tol = options.tol or 1e-6
    local h_min = options.h_min or 1e-10
    local h_max = options.h_max or (t_end - t0) / 4
    local max_steps = options.max_steps or 10000

    -- 初始步长
    local h = options.h_init or math.min(0.1, (t_end - t0) / 10, h_max)

    -- 判断是标量还是向量
    local is_vector = type(y0) == "table"

    -- 辅助函数：RK4单步
    local function rk4_step(t, y, h)
        local k1 = f(t, y)
        local k2, k3, k4

        if is_vector then
            local y2, y3, y4 = {}, {}, {}
            for i = 1, #y do
                y2[i] = y[i] + 0.5 * h * k1[i]
            end
            k2 = f(t + 0.5 * h, y2)
            for i = 1, #y do
                y3[i] = y[i] + 0.5 * h * k2[i]
            end
            k3 = f(t + 0.5 * h, y3)
            for i = 1, #y do
                y4[i] = y[i] + h * k3[i]
            end
            k4 = f(t + h, y4)

            local y_new = {}
            for i = 1, #y do
                y_new[i] = y[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i])
            end
            return y_new
        else
            k2 = f(t + 0.5 * h, y + 0.5 * h * k1)
            k3 = f(t + 0.5 * h, y + 0.5 * h * k2)
            k4 = f(t + h, y + h * k3)
            return y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        end
    end

    -- 计算误差范数
    local function error_norm(y1, y2)
        if is_vector then
            local sum = 0
            for i = 1, #y1 do
                local diff = y1[i] - y2[i]
                sum = sum + diff * diff
            end
            return math.sqrt(sum)
        else
            return math.abs(y1 - y2)
        end
    end

    -- 初始化结果
    local t_vals = {t0}
    local y_vals = {}
    if is_vector then
        y_vals[1] = {}
        for i = 1, #y0 do
            y_vals[1][i] = y0[i]
        end
    else
        y_vals[1] = y0
    end

    -- 当前状态
    local t = t0
    local y
    if is_vector then
        y = {}
        for i = 1, #y0 do y[i] = y0[i] end
    else
        y = y0
    end

    local step_count = 0

    -- 主循环
    while t < t_end and step_count < max_steps do
        step_count = step_count + 1

        -- 确保最后一步正好到达 t_end
        if t + h > t_end then
            h = t_end - t
        end

        -- 步长加倍法：比较一步和两步的结果
        local y_one_step = rk4_step(t, y, h)
        local y_half = rk4_step(t, y, 0.5 * h)
        local y_two_steps = rk4_step(t + 0.5 * h, y_half, 0.5 * h)

        -- 误差估计
        local err = error_norm(y_one_step, y_two_steps)

        -- 步长调整
        if err < tol or h <= h_min then
            -- 接受步（使用更精确的两步结果）
            t = t + h
            y = y_two_steps

            t_vals[#t_vals + 1] = t
            if is_vector then
                y_vals[#y_vals + 1] = {}
                for j = 1, #y do
                    y_vals[#y_vals][j] = y[j]
                end
            else
                y_vals[#y_vals + 1] = y
            end
        end

        -- 计算新步长
        if err > 1e-15 then
            local factor = 0.9 * (tol / err) ^ 0.2
            factor = math.max(0.1, math.min(2.0, factor))
            h = math.max(h_min, math.min(h_max, h * factor))
        else
            h = math.min(h_max, h * 2)
        end
    end

    return t_vals, y_vals
end

-- 自适应RK方法别名
function advanced_methods.adaptive_rk(f, t0, y0, t_end, options)
    return advanced_methods.rk45(f, t0, y0, t_end, options)
end

return advanced_methods