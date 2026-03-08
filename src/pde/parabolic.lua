-- 抛物型方程求解器
-- 包括热传导方程的有限差分求解方法

local utils = require("utils.init")

local parabolic = {}

-- =============================================================================
-- 辅助函数
-- =============================================================================

-- 创建一维数组
local function create_array(n, init_value)
    init_value = init_value or 0
    local arr = {}
    for i = 1, n do
        arr[i] = init_value
    end
    return arr
end

-- 复制数组
local function copy_array(arr)
    local copy = {}
    for i = 1, #arr do
        copy[i] = arr[i]
    end
    return copy
end

-- 创建二维解矩阵
local function create_solution_matrix(nt, nx)
    local sol = {}
    for t = 1, nt do
        sol[t] = create_array(nx, 0)
    end
    return sol
end

-- 三对角方程组求解器（Thomas算法）
-- 求解 a[i]*x[i-1] + b[i]*x[i] + c[i]*x[i+1] = d[i]
local function thomas_solver(a, b, c, d)
    local n = #d
    local x = create_array(n, 0)

    -- 前向消元
    local c_prime = create_array(n, 0)
    local d_prime = create_array(n, 0)

    c_prime[1] = c[1] / b[1]
    d_prime[1] = d[1] / b[1]

    for i = 2, n do
        local m = b[i] - a[i] * c_prime[i-1]
        c_prime[i] = c[i] / m
        d_prime[i] = (d[i] - a[i] * d_prime[i-1]) / m
    end

    -- 回代
    x[n] = d_prime[n]
    for i = n - 1, 1, -1 do
        x[i] = d_prime[i] - c_prime[i] * x[i+1]
    end

    return x
end

-- =============================================================================
-- 一维热传导方程求解器
-- =============================================================================

-- FTCS 显式方法求解一维热传导方程
-- ∂u/∂t = α * ∂²u/∂x²
-- @param alpha 热扩散系数
-- @param ic 初始条件函数 u0(x)
-- @param bc 边界条件 {left = {type, value}, right = {type, value}}
-- @param x_span 空间区间 {x0, x_end}
-- @param t_span 时间区间 {t0, t_end}
-- @param options 选项：{nx, nt, r} 或自动计算
-- @return x网格, t网格, 解矩阵 u[t][x]
local function heat1d_ftcs(alpha, ic, bc, x_span, t_span, options)
    options = options or {}
    local nx = options.nx or 50
    local r = options.r  -- r = alpha * dt / dx^2

    local x0, x_end = x_span[1] or 0, x_span[2] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (x_end - x0) / (nx - 1)
    local dt, nt

    -- 根据稳定性条件确定时间步长
    if r then
        dt = r * dx * dx / alpha
    else
        -- 自动选择满足稳定性条件的步长
        r = 0.4  -- 留出余量
        dt = r * dx * dx / alpha
    end

    nt = math.floor((t_end - t0) / dt) + 1
    dt = (t_end - t0) / (nt - 1)
    r = alpha * dt / (dx * dx)

    -- 稳定性检查
    if r > 0.5 then
        -- 自动调整
        nt = math.ceil(nt * r / 0.4)
        dt = (t_end - t0) / (nt - 1)
        r = alpha * dt / (dx * dx)
    end

    -- 创建坐标数组
    local x = create_array(nx, 0)
    local t = create_array(nt, 0)
    for i = 1, nx do
        x[i] = x0 + (i - 1) * dx
    end
    for n = 1, nt do
        t[n] = t0 + (n - 1) * dt
    end

    -- 创建解矩阵
    local u = create_solution_matrix(nt, nx)

    -- 初始条件
    for i = 1, nx do
        u[1][i] = ic(x[i])
    end

    -- 应用初始边界条件
    if bc.left and bc.left.type == "dirichlet" then
        u[1][1] = bc.left.value
    end
    if bc.right and bc.right.type == "dirichlet" then
        u[1][nx] = bc.right.value
    end

    -- 时间步进
    for n = 1, nt - 1 do
        -- FTCS 更新内部点
        for i = 2, nx - 1 do
            u[n+1][i] = u[n][i] + r * (u[n][i+1] - 2*u[n][i] + u[n][i-1])
        end

        -- 边界条件
        if bc.left then
            if bc.left.type == "dirichlet" then
                u[n+1][1] = bc.left.value
            elseif bc.left.type == "neumann" then
                u[n+1][1] = u[n+1][2] - dx * bc.left.value
            end
        end

        if bc.right then
            if bc.right.type == "dirichlet" then
                u[n+1][nx] = bc.right.value
            elseif bc.right.type == "neumann" then
                u[n+1][nx] = u[n+1][nx-1] + dx * bc.right.value
            end
        end
    end

    return x, t, u
end

-- Crank-Nicolson 隐式方法求解一维热传导方程
-- 无条件稳定，二阶精度
local function heat1d_crank_nicolson(alpha, ic, bc, x_span, t_span, options)
    options = options or {}
    local nx = options.nx or 50
    local nt = options.nt or 100

    local x0, x_end = x_span[1] or 0, x_span[2] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (x_end - x0) / (nx - 1)
    local dt = (t_end - t0) / (nt - 1)
    local r = alpha * dt / (dx * dx)

    -- 创建坐标数组
    local x = create_array(nx, 0)
    local t = create_array(nt, 0)
    for i = 1, nx do
        x[i] = x0 + (i - 1) * dx
    end
    for n = 1, nt do
        t[n] = t0 + (n - 1) * dt
    end

    -- 创建解矩阵
    local u = create_solution_matrix(nt, nx)

    -- 初始条件
    for i = 1, nx do
        u[1][i] = ic(x[i])
    end

    -- 应用初始边界条件
    if bc.left and bc.left.type == "dirichlet" then
        u[1][1] = bc.left.value
    end
    if bc.right and bc.right.type == "dirichlet" then
        u[1][nx] = bc.right.value
    end

    -- Crank-Nicolson 系数
    -- (1 + r) * u[i]^{n+1} - 0.5*r * (u[i-1]^{n+1} + u[i+1]^{n+1})
    -- = (1 - r) * u[i]^n + 0.5*r * (u[i-1]^n + u[i+1]^n)

    local a = create_array(nx, 0)  -- 下对角线
    local b = create_array(nx, 0)  -- 主对角线
    local c = create_array(nx, 0)  -- 上对角线
    local d = create_array(nx, 0)  -- 右端项

    -- 设置三对角矩阵系数
    for i = 2, nx - 1 do
        a[i] = -0.5 * r
        b[i] = 1 + r
        c[i] = -0.5 * r
    end

    -- 时间步进
    for n = 1, nt - 1 do
        -- 构造右端项
        for i = 2, nx - 1 do
            d[i] = (1 - r) * u[n][i] + 0.5 * r * (u[n][i-1] + u[n][i+1])
        end

        -- 边界条件处理
        if bc.left then
            if bc.left.type == "dirichlet" then
                b[1] = 1
                c[1] = 0
                d[1] = bc.left.value
                -- 修改第二个方程
                d[2] = d[2] + 0.5 * r * bc.left.value
            elseif bc.left.type == "neumann" then
                -- 使用虚拟点处理Neumann边界
                b[1] = 1 + r
                c[1] = -r
                d[1] = u[n][1] + r * dx * bc.left.value
            end
        else
            b[1] = 1
            c[1] = 0
            d[1] = u[n][1]
        end

        if bc.right then
            if bc.right.type == "dirichlet" then
                a[nx] = 0
                b[nx] = 1
                d[nx] = bc.right.value
                d[nx-1] = d[nx-1] + 0.5 * r * bc.right.value
            elseif bc.right.type == "neumann" then
                a[nx] = -r
                b[nx] = 1 + r
                d[nx] = u[n][nx] - r * dx * bc.right.value
            end
        else
            a[nx] = 0
            b[nx] = 1
            d[nx] = u[n][nx]
        end

        -- 求解三对角方程组
        local u_new = thomas_solver(a, b, c, d)

        -- 存储解
        for i = 1, nx do
            u[n+1][i] = u_new[i]
        end
    end

    return x, t, u
end

-- 统一接口：求解一维热传导方程
-- @param alpha 热扩散系数
-- @param ic 初始条件函数 u0(x)
-- @param bc 边界条件
-- @param x_span 空间区间
-- @param t_span 时间区间
-- @param options: {method = "ftcs"|"cn", nx, nt, r}
function parabolic.heat1d(alpha, ic, bc, x_span, t_span, options)
    -- 参数验证
    utils.typecheck.check_type("heat1d", "alpha", alpha, "number")
    utils.typecheck.check_type("heat1d", "ic", ic, "function")
    utils.typecheck.check_type("heat1d", "bc", bc, "table")
    utils.typecheck.check_type("heat1d", "x_span", x_span, "table")
    utils.typecheck.check_type("heat1d", "t_span", t_span, "table")

    options = options or {}
    local method = options.method or "ftcs"

    if method == "ftcs" or method == "explicit" then
        return heat1d_ftcs(alpha, ic, bc, x_span, t_span, options)
    elseif method == "cn" or method == "crank_nicolson" or method == "implicit" then
        return heat1d_crank_nicolson(alpha, ic, bc, x_span, t_span, options)
    else
        error("Unknown method for heat1d: " .. method)
    end
end

-- =============================================================================
-- 二维热传导方程求解器
-- =============================================================================

-- ADI（交替方向隐式）方法求解二维热传导方程
-- ∂u/∂t = α * (∂²u/∂x² + ∂²u/∂y²)
-- @param alpha 热扩散系数
-- @param ic 初始条件函数 u0(x, y)
-- @param bc 边界条件 {left, right, bottom, top}
-- @param bounds 区域边界 {ax, bx, ay, by}
-- @param t_span 时间区间
-- @param options: {nx, ny, nt}
function parabolic.heat2d(alpha, ic, bc, bounds, t_span, options)
    -- 参数验证
    utils.typecheck.check_type("heat2d", "alpha", alpha, "number")
    utils.typecheck.check_type("heat2d", "ic", ic, "function")
    utils.typecheck.check_type("heat2d", "bounds", bounds, "table")
    utils.typecheck.check_type("heat2d", "t_span", t_span, "table")

    options = options or {}
    local nx = options.nx or 30
    local ny = options.ny or 30
    local nt = options.nt or 50

    local ax, bx = bounds[1] or 0, bounds[2] or 1
    local ay, by = bounds[3] or 0, bounds[4] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (bx - ax) / (nx - 1)
    local dy = (by - ay) / (ny - 1)
    local dt = (t_end - t0) / nt

    local rx = alpha * dt / (dx * dx)
    local ry = alpha * dt / (dy * dy)

    -- 创建坐标数组
    local x = create_array(nx, 0)
    local y = create_array(ny, 0)
    local t = create_array(nt + 1, 0)

    for i = 1, nx do
        x[i] = ax + (i - 1) * dx
    end
    for j = 1, ny do
        y[j] = ay + (j - 1) * dy
    end
    for n = 1, nt + 1 do
        t[n] = t0 + (n - 1) * dt
    end

    -- 创建解网格（三维：时间 × x × y）
    local u = {}
    for n = 1, nt + 1 do
        u[n] = {}
        for i = 1, nx do
            u[n][i] = create_array(ny, 0)
        end
    end

    -- 初始条件
    for i = 1, nx do
        for j = 1, ny do
            u[1][i][j] = ic(x[i], y[j])
        end
    end

    -- 应用初始边界条件
    local function apply_bc_2d(u_curr)
        if bc.left and bc.left.type == "dirichlet" then
            for j = 1, ny do
                u_curr[1][j] = bc.left.value
            end
        end
        if bc.right and bc.right.type == "dirichlet" then
            for j = 1, ny do
                u_curr[nx][j] = bc.right.value
            end
        end
        if bc.bottom and bc.bottom.type == "dirichlet" then
            for i = 1, nx do
                u_curr[i][1] = bc.bottom.value
            end
        end
        if bc.top and bc.top.type == "dirichlet" then
            for i = 1, nx do
                u_curr[i][ny] = bc.top.value
            end
        end
    end

    apply_bc_2d(u[1])

    -- ADI 方法时间步进
    for n = 1, nt do
        -- 半步：x 方向隐式，y 方向显式
        local u_half = {}
        for i = 1, nx do
            u_half[i] = create_array(ny, 0)
        end

        -- 对每一行求解三对角方程组
        for j = 2, ny - 1 do
            local a = create_array(nx, 0)
            local b = create_array(nx, 0)
            local c = create_array(nx, 0)
            local d = create_array(nx, 0)

            for i = 2, nx - 1 do
                a[i] = -0.5 * rx
                b[i] = 1 + rx
                c[i] = -0.5 * rx
                d[i] = u[n][i][j] + 0.5 * ry * (u[n][i][j+1] - 2*u[n][i][j] + u[n][i][j-1])
            end

            -- 边界
            b[1] = 1; c[1] = 0; d[1] = bc.left and bc.left.value or u[n][1][j]
            a[nx] = 0; b[nx] = 1; d[nx] = bc.right and bc.right.value or u[n][nx][j]

            local row = thomas_solver(a, b, c, d)
            for i = 1, nx do
                u_half[i][j] = row[i]
            end
        end

        -- 边界行的处理
        for j = 1, ny do
            if bc.bottom and bc.bottom.type == "dirichlet" then
                for i = 1, nx do u_half[i][1] = bc.bottom.value end
            end
            if bc.top and bc.top.type == "dirichlet" then
                for i = 1, nx do u_half[i][ny] = bc.top.value end
            end
        end

        -- 半步：y 方向隐式，x 方向显式
        for i = 2, nx - 1 do
            local a = create_array(ny, 0)
            local b = create_array(ny, 0)
            local c = create_array(ny, 0)
            local d = create_array(ny, 0)

            for j = 2, ny - 1 do
                a[j] = -0.5 * ry
                b[j] = 1 + ry
                c[j] = -0.5 * ry
                d[j] = u_half[i][j] + 0.5 * rx * (u_half[i+1][j] - 2*u_half[i][j] + u_half[i-1][j])
            end

            b[1] = 1; c[1] = 0; d[1] = bc.bottom and bc.bottom.value or u_half[i][1]
            a[ny] = 0; b[ny] = 1; d[ny] = bc.top and bc.top.value or u_half[i][ny]

            local col = thomas_solver(a, b, c, d)
            for j = 1, ny do
                u[n+1][i][j] = col[j]
            end
        end

        -- 边界列
        for j = 1, ny do
            if bc.left and bc.left.type == "dirichlet" then
                u[n+1][1][j] = bc.left.value
            end
            if bc.right and bc.right.type == "dirichlet" then
                u[n+1][nx][j] = bc.right.value
            end
        end
    end

    return x, y, t, u
end

-- =============================================================================
-- 别名
-- =============================================================================

parabolic.diffusion1d = parabolic.heat1d
parabolic.diffusion2d = parabolic.heat2d

return parabolic