-- 基础常微分方程求解方法
local utils = require("utils.init")

local basic_methods = {}

-- 欧拉方法（一阶方法）
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t0 初始时间
-- @param y0 初始值（可以是标量或向量）
-- @param t_end 终止时间
-- @param h 步长（可选，默认自动选择）
-- @param options 选项表：
--   - n_steps: 步数（如果提供，忽略h）
-- @return 时间数组，解数组
function basic_methods.euler(f, t0, y0, t_end, h, options)
    -- 参数验证
    utils.typecheck.check_type("euler", "f", f, "function")
    utils.typecheck.check_type("euler", "t0", t0, "number")
    utils.typecheck.check_type("euler", "t_end", t_end, "number")
    utils.typecheck.check_type("euler", "h", h, "number", "nil")
    utils.typecheck.check_type("euler", "options", options, "table", "nil")

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

    -- 初始化结果数组
    local t_vals = {t0}
    local y_vals = {is_vector and {} or y0}
    if is_vector then
        for i = 1, #y0 do
            y_vals[1][i] = y0[i]
        end
    end

    -- 当前状态
    local t = t0
    local y = is_vector and {} or y0
    if is_vector then
        for i = 1, #y0 do y[i] = y0[i] end
    end

    -- 迭代
    for i = 1, n_steps do
        -- 计算导数
        local dy = f(t, y)

        -- 欧拉更新：y_{n+1} = y_n + h * f(t_n, y_n)
        if is_vector then
            local y_new = {}
            for j = 1, #y do
                y_new[j] = y[j] + h * dy[j]
            end
            y = y_new
        else
            y = y + h * dy
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

-- 改进欧拉方法（Heun方法，二阶方法）
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t0 初始时间
-- @param y0 初始值（可以是标量或向量）
-- @param t_end 终止时间
-- @param h 步长（可选，默认自动选择）
-- @param options 选项表
-- @return 时间数组，解数组
function basic_methods.heun(f, t0, y0, t_end, h, options)
    -- 参数验证
    utils.typecheck.check_type("heun", "f", f, "function")
    utils.typecheck.check_type("heun", "t0", t0, "number")
    utils.typecheck.check_type("heun", "t_end", t_end, "number")
    utils.typecheck.check_type("heun", "h", h, "number", "nil")
    utils.typecheck.check_type("heun", "options", options, "table", "nil")

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

    -- 初始化结果数组
    local t_vals = {t0}
    local y_vals = {is_vector and {} or y0}
    if is_vector then
        for i = 1, #y0 do
            y_vals[1][i] = y0[i]
        end
    end

    -- 当前状态
    local t = t0
    local y = is_vector and {} or y0
    if is_vector then
        for i = 1, #y0 do y[i] = y0[i] end
    end

    -- 迭代
    for i = 1, n_steps do
        -- 预测步（欧拉）
        local k1 = f(t, y)
        local y_pred
        if is_vector then
            y_pred = {}
            for j = 1, #y do
                y_pred[j] = y[j] + h * k1[j]
            end
        else
            y_pred = y + h * k1
        end

        -- 校正步
        local k2 = f(t + h, y_pred)

        -- 更新：y_{n+1} = y_n + h/2 * (k1 + k2)
        if is_vector then
            local y_new = {}
            for j = 1, #y do
                y_new[j] = y[j] + h * 0.5 * (k1[j] + k2[j])
            end
            y = y_new
        else
            y = y + h * 0.5 * (k1 + k2)
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

-- 中点方法（二阶方法）
-- @param f 微分函数 dy/dt = f(t, y)
-- @param t0 初始时间
-- @param y0 初始值（可以是标量或向量）
-- @param t_end 终止时间
-- @param h 步长
-- @param options 选项表
-- @return 时间数组，解数组
function basic_methods.midpoint(f, t0, y0, t_end, h, options)
    -- 参数验证
    utils.typecheck.check_type("midpoint", "f", f, "function")
    utils.typecheck.check_type("midpoint", "t0", t0, "number")
    utils.typecheck.check_type("midpoint", "t_end", t_end, "number")
    utils.typecheck.check_type("midpoint", "h", h, "number", "nil")
    utils.typecheck.check_type("midpoint", "options", options, "table", "nil")

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

    -- 初始化结果数组
    local t_vals = {t0}
    local y_vals = {is_vector and {} or y0}
    if is_vector then
        for i = 1, #y0 do
            y_vals[1][i] = y0[i]
        end
    end

    -- 当前状态
    local t = t0
    local y = is_vector and {} or y0
    if is_vector then
        for i = 1, #y0 do y[i] = y0[i] end
    end

    -- 迭代
    for i = 1, n_steps do
        -- 计算中点斜率
        local k1 = f(t, y)
        local y_mid
        if is_vector then
            y_mid = {}
            for j = 1, #y do
                y_mid[j] = y[j] + 0.5 * h * k1[j]
            end
        else
            y_mid = y + 0.5 * h * k1
        end

        local k2 = f(t + 0.5 * h, y_mid)

        -- 更新
        if is_vector then
            local y_new = {}
            for j = 1, #y do
                y_new[j] = y[j] + h * k2[j]
            end
            y = y_new
        else
            y = y + h * k2
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

return basic_methods