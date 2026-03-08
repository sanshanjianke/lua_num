-- 双曲型方程求解器
-- 包括波动方程和对流方程的有限差分求解方法

local utils = require("utils.init")

local hyperbolic = {}

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

-- 创建二维解矩阵
local function create_solution_matrix(nt, nx)
    local sol = {}
    for t = 1, nt do
        sol[t] = create_array(nx, 0)
    end
    return sol
end

-- =============================================================================
-- 一维波动方程求解器
-- =============================================================================

-- 显式有限差分方法求解一维波动方程
-- ∂²u/∂t² = c² * ∂²u/∂x²
-- 使用中心差分格式，二阶精度
-- @param c 波速
-- @param ic_u 初始位移 u(x, 0)
-- @param ic_v 初始速度 ∂u/∂t(x, 0)
-- @param bc 边界条件
-- @param x_span 空间区间
-- @param t_span 时间区间
-- @param options: {nx, nt, cfl}
-- @return x网格, t网格, 解矩阵 u[t][x]
function hyperbolic.wave1d(c, ic_u, ic_v, bc, x_span, t_span, options)
    -- 参数验证
    utils.typecheck.check_type("wave1d", "c", c, "number")
    utils.typecheck.check_type("wave1d", "ic_u", ic_u, "function")
    utils.typecheck.check_type("wave1d", "ic_v", ic_v, "function", "nil")
    utils.typecheck.check_type("wave1d", "bc", bc, "table")
    utils.typecheck.check_type("wave1d", "x_span", x_span, "table")
    utils.typecheck.check_type("wave1d", "t_span", t_span, "table")

    options = options or {}
    local nx = options.nx or 100
    local cfl = options.cfl or 0.8  -- CFL数，需 <= 1 保持稳定

    local x0, x_end = x_span[1] or 0, x_span[2] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (x_end - x0) / (nx - 1)
    local dt = cfl * dx / c  -- 根据 CFL 条件确定时间步长
    local nt = math.floor((t_end - t0) / dt) + 1
    dt = (t_end - t0) / (nt - 1)

    -- 更新实际的 CFL 数
    cfl = c * dt / dx
    if cfl > 1 then
        -- 如果 CFL > 1，增加时间步数
        nt = math.ceil(nt * cfl)
        dt = (t_end - t0) / (nt - 1)
        cfl = c * dt / dx
    end

    local r2 = cfl * cfl  -- r = c * dt / dx

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

    -- 初始条件：位移
    for i = 1, nx do
        u[1][i] = ic_u(x[i])
    end

    -- 初始条件：速度（用于计算第二步）
    -- 使用 Taylor 展开: u(x, dt) ≈ u(x, 0) + dt * v(x, 0) + 0.5 * dt² * c² * u_xx(x, 0)
    if ic_v then
        for i = 2, nx - 1 do
            local u_xx = (u[1][i+1] - 2*u[1][i] + u[1][i-1]) / (dx * dx)
            u[2][i] = u[1][i] + dt * ic_v(x[i]) + 0.5 * dt * dt * c * c * u_xx
        end
    else
        -- 如果没有初始速度，使用简单外推
        for i = 2, nx - 1 do
            u[2][i] = u[1][i]
        end
    end

    -- 边界条件（初始时刻）
    if bc.left then
        u[1][1] = bc.left.value or 0
        u[2][1] = bc.left.value or 0
    end
    if bc.right then
        u[1][nx] = bc.right.value or 0
        u[2][nx] = bc.right.value or 0
    end

    -- 时间步进（显式格式）
    for n = 2, nt - 1 do
        -- 内部点更新
        for i = 2, nx - 1 do
            u[n+1][i] = 2*(1 - r2)*u[n][i] + r2*(u[n][i+1] + u[n][i-1]) - u[n-1][i]
        end

        -- 边界条件
        if bc.left then
            if bc.left.type == "dirichlet" then
                u[n+1][1] = bc.left.value
            elseif bc.left.type == "neumann" then
                -- 反射边界
                u[n+1][1] = u[n+1][2]
            elseif bc.left.type == "absorbing" then
                -- 吸收边界（一阶）
                u[n+1][1] = u[n][2] + (cfl - 1) / (cfl + 1) * (u[n+1][2] - u[n][1])
            end
        end

        if bc.right then
            if bc.right.type == "dirichlet" then
                u[n+1][nx] = bc.right.value
            elseif bc.right.type == "neumann" then
                u[n+1][nx] = u[n+1][nx-1]
            elseif bc.right.type == "absorbing" then
                u[n+1][nx] = u[n][nx-1] + (cfl - 1) / (cfl + 1) * (u[n+1][nx-1] - u[n][nx])
            end
        end
    end

    return x, t, u
end

-- =============================================================================
-- 一阶对流方程求解器
-- =============================================================================

-- 求解一阶对流方程: ∂u/∂t + a * ∂u/∂x = 0
-- @param a 对流速度（a > 0 波向右传播，a < 0 波向左传播）
-- @param ic 初始条件函数
-- @param bc 边界条件
-- @param x_span 空间区间
-- @param t_span 时间区间
-- @param options: {scheme = "upwind"|"lax_friedrichs"|"lax_wendroff", nx, cfl}
function hyperbolic.advection1d(a, ic, bc, x_span, t_span, options)
    -- 参数验证
    utils.typecheck.check_type("advection1d", "a", a, "number")
    utils.typecheck.check_type("advection1d", "ic", ic, "function")
    utils.typecheck.check_type("advection1d", "x_span", x_span, "table")
    utils.typecheck.check_type("advection1d", "t_span", t_span, "table")

    options = options or {}
    local scheme = options.scheme or "upwind"
    local nx = options.nx or 100
    local cfl = options.cfl or 0.8

    local x0, x_end = x_span[1] or 0, x_span[2] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (x_end - x0) / (nx - 1)
    local dt = cfl * dx / math.abs(a)
    local nt = math.floor((t_end - t0) / dt) + 1
    dt = (t_end - t0) / (nt - 1)
    cfl = math.abs(a) * dt / dx

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

    -- 时间步进
    for n = 1, nt - 1 do
        if scheme == "upwind" then
            -- 迎风格式（一阶精度）
            if a > 0 then
                -- 波向右传播，使用左差分
                for i = 2, nx do
                    u[n+1][i] = u[n][i] - cfl * (u[n][i] - u[n][i-1])
                end
                -- 左边界
                if bc and bc.left then
                    u[n+1][1] = bc.left.value or ic(x0 - a * t[n+1])
                end
            else
                -- 波向左传播，使用右差分
                for i = 1, nx - 1 do
                    u[n+1][i] = u[n][i] - cfl * (u[n][i+1] - u[n][i])
                end
                -- 右边界
                if bc and bc.right then
                    u[n+1][nx] = bc.right.value or ic(x_end - a * t[n+1])
                end
            end

        elseif scheme == "lax_friedrichs" then
            -- Lax-Friedrichs 格式（一阶精度，但有数值耗散）
            for i = 2, nx - 1 do
                u[n+1][i] = 0.5 * (u[n][i+1] + u[n][i-1])
                          - 0.5 * cfl * (a / math.abs(a)) * (u[n][i+1] - u[n][i-1])
            end
            -- 边界
            u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
            u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]

        elseif scheme == "lax_wendroff" then
            -- Lax-Wendroff 格式（二阶精度）
            local sigma = a * dt / dx
            for i = 2, nx - 1 do
                u[n+1][i] = u[n][i]
                          - 0.5 * sigma * (u[n][i+1] - u[n][i-1])
                          + 0.5 * sigma * sigma * (u[n][i+1] - 2*u[n][i] + u[n][i-1])
            end
            -- 边界
            u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
            u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]

        elseif scheme == "beam_warming" then
            -- Beam-Warming 格式（二阶迎风格式）
            if a > 0 then
                for i = 3, nx do
                    local sigma = a * dt / dx
                    u[n+1][i] = u[n][i]
                              - 0.5 * sigma * (3*u[n][i] - 4*u[n][i-1] + u[n][i-2])
                              + 0.5 * sigma * sigma * (u[n][i] - 2*u[n][i-1] + u[n][i-2])
                end
                u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
                u[n+1][2] = u[n][2]
            else
                for i = 1, nx - 2 do
                    local sigma = a * dt / dx
                    u[n+1][i] = u[n][i]
                              - 0.5 * sigma * (-3*u[n][i] + 4*u[n][i+1] - u[n][i+2])
                              + 0.5 * sigma * sigma * (u[n][i] - 2*u[n][i+1] + u[n][i+2])
                end
                u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]
                u[n+1][nx-1] = u[n][nx-1]
            end

        else
            error("Unknown advection scheme: " .. scheme)
        end
    end

    return x, t, u
end

-- =============================================================================
-- 二维波动方程求解器
-- =============================================================================

-- 显式有限差分方法求解二维波动方程
-- ∂²u/∂t² = c² * (∂²u/∂x² + ∂²u/∂y²)
-- @param c 波速
-- @param ic_u 初始位移
-- @param ic_v 初始速度
-- @param bc 边界条件
-- @param bounds 区域边界
-- @param t_span 时间区间
-- @param options: {nx, ny, cfl}
function hyperbolic.wave2d(c, ic_u, ic_v, bc, bounds, t_span, options)
    -- 参数验证
    utils.typecheck.check_type("wave2d", "c", c, "number")
    utils.typecheck.check_type("wave2d", "ic_u", ic_u, "function")
    utils.typecheck.check_type("wave2d", "bounds", bounds, "table")
    utils.typecheck.check_type("wave2d", "t_span", t_span, "table")

    options = options or {}
    local nx = options.nx or 50
    local ny = options.ny or 50
    local cfl = options.cfl or 0.5  -- 二维情况下 CFL 需更小

    local ax, bx = bounds[1] or 0, bounds[2] or 1
    local ay, by = bounds[3] or 0, bounds[4] or 1
    local t0, t_end = t_span[1] or 0, t_span[2] or 1

    local dx = (bx - ax) / (nx - 1)
    local dy = (by - ay) / (ny - 1)
    local dt = cfl * math.min(dx, dy) / (c * math.sqrt(2))
    local nt = math.floor((t_end - t0) / dt) + 1
    dt = (t_end - t0) / (nt - 1)

    local rx2 = (c * dt / dx) ^ 2
    local ry2 = (c * dt / dy) ^ 2

    -- 创建坐标数组
    local x = create_array(nx, 0)
    local y = create_array(ny, 0)
    local t = create_array(nt, 0)

    for i = 1, nx do
        x[i] = ax + (i - 1) * dx
    end
    for j = 1, ny do
        y[j] = ay + (j - 1) * dy
    end
    for n = 1, nt do
        t[n] = t0 + (n - 1) * dt
    end

    -- 创建解网格
    local u = {}
    for n = 1, nt do
        u[n] = {}
        for i = 1, nx do
            u[n][i] = create_array(ny, 0)
        end
    end

    -- 初始条件
    for i = 1, nx do
        for j = 1, ny do
            u[1][i][j] = ic_u(x[i], y[j])
        end
    end

    -- 使用初始速度计算第二步
    if ic_v then
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                local u_xx = (u[1][i+1][j] - 2*u[1][i][j] + u[1][i-1][j]) / (dx * dx)
                local u_yy = (u[1][i][j+1] - 2*u[1][i][j] + u[1][i][j-1]) / (dy * dy)
                u[2][i][j] = u[1][i][j] + dt * ic_v(x[i], y[j])
                           + 0.5 * dt * dt * c * c * (u_xx + u_yy)
            end
        end
    else
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                u[2][i][j] = u[1][i][j]
            end
        end
    end

    -- 应用边界条件
    local function apply_bc(u_curr)
        if bc.left then
            for j = 1, ny do u_curr[1][j] = bc.left.value or 0 end
        end
        if bc.right then
            for j = 1, ny do u_curr[nx][j] = bc.right.value or 0 end
        end
        if bc.bottom then
            for i = 1, nx do u_curr[i][1] = bc.bottom.value or 0 end
        end
        if bc.top then
            for i = 1, nx do u_curr[i][ny] = bc.top.value or 0 end
        end
    end

    apply_bc(u[1])
    apply_bc(u[2])

    -- 时间步进
    for n = 2, nt - 1 do
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                u[n+1][i][j] = 2*u[n][i][j] - u[n-1][i][j]
                             + rx2 * (u[n][i+1][j] - 2*u[n][i][j] + u[n][i-1][j])
                             + ry2 * (u[n][i][j+1] - 2*u[n][i][j] + u[n][i][j-1])
            end
        end
        apply_bc(u[n+1])
    end

    return x, y, t, u
end

-- =============================================================================
-- 别名
-- =============================================================================

hyperbolic.transport1d = hyperbolic.advection1d

return hyperbolic