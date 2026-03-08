-- 椭圆型方程求解器
-- 包括泊松方程和拉普拉斯方程的有限差分求解方法

local utils = require("utils.init")

local elliptic = {}

-- =============================================================================
-- 辅助函数
-- =============================================================================

-- 初始化网格
local function create_grid(nx, ny, init_value)
    init_value = init_value or 0
    local grid = {}
    for i = 1, nx do
        grid[i] = {}
        for j = 1, ny do
            grid[i][j] = init_value
        end
    end
    return grid
end

-- 复制网格
local function copy_grid(u)
    local copy = {}
    for i = 1, #u do
        copy[i] = {}
        for j = 1, #u[1] do
            copy[i][j] = u[i][j]
        end
    end
    return copy
end

-- 计算最大差异（用于收敛判断）
local function max_diff(u1, u2)
    local max_d = 0
    for i = 1, #u1 do
        for j = 1, #u1[1] do
            local d = math.abs(u1[i][j] - u2[i][j])
            if d > max_d then
                max_d = d
            end
        end
    end
    return max_d
end

-- 计算残差范数
local function residual_norm(u, f, nx, ny, dx, dy)
    local sum = 0
    local dx2 = dx * dx
    local dy2 = dy * dy

    for i = 2, nx - 1 do
        for j = 2, ny - 1 do
            local laplacian = (u[i+1][j] - 2*u[i][j] + u[i-1][j]) / dx2
                          + (u[i][j+1] - 2*u[i][j] + u[i][j-1]) / dy2
            local f_val = type(f) == "function" and f(i, j) or f
            local r = laplacian - f_val
            sum = sum + r * r
        end
    end

    return math.sqrt(sum)
end

-- =============================================================================
-- 边界条件处理
-- =============================================================================

-- 应用边界条件
local function apply_boundary_conditions(u, bc, nx, ny, dx, dy)
    -- 左边界 (i = 1)
    if bc.left then
        if bc.left.type == "dirichlet" then
            for j = 1, ny do
                u[1][j] = bc.left.value
            end
        elseif bc.left.type == "neumann" then
            -- 使用一阶差分: (u[2][j] - u[1][j]) / dx = value
            for j = 1, ny do
                u[1][j] = u[2][j] - dx * bc.left.value
            end
        end
    end

    -- 右边界 (i = nx)
    if bc.right then
        if bc.right.type == "dirichlet" then
            for j = 1, ny do
                u[nx][j] = bc.right.value
            end
        elseif bc.right.type == "neumann" then
            for j = 1, ny do
                u[nx][j] = u[nx-1][j] + dx * bc.right.value
            end
        end
    end

    -- 下边界 (j = 1)
    if bc.bottom then
        if bc.bottom.type == "dirichlet" then
            for i = 1, nx do
                u[i][1] = bc.bottom.value
            end
        elseif bc.bottom.type == "neumann" then
            for i = 1, nx do
                u[i][1] = u[i][2] - dy * bc.bottom.value
            end
        end
    end

    -- 上边界 (j = ny)
    if bc.top then
        if bc.top.type == "dirichlet" then
            for i = 1, nx do
                u[i][ny] = bc.top.value
            end
        elseif bc.top.type == "neumann" then
            for i = 1, nx do
                u[i][ny] = u[i][ny-1] + dy * bc.top.value
            end
        end
    end
end

-- =============================================================================
-- 迭代求解方法
-- =============================================================================

-- Jacobi 迭代法
local function jacobi_iteration(u, f, bc, nx, ny, dx, dy)
    local u_new = copy_grid(u)
    local dx2 = dx * dx
    local dy2 = dy * dy
    local factor = 2 * (1/dx2 + 1/dy2)

    -- 内部点更新
    for i = 2, nx - 1 do
        for j = 2, ny - 1 do
            local f_val = type(f) == "function" and f(i, j) or f
            u_new[i][j] = ((u[i+1][j] + u[i-1][j]) / dx2
                        + (u[i][j+1] + u[i][j-1]) / dy2
                        - f_val) / factor
        end
    end

    -- 应用边界条件
    apply_boundary_conditions(u_new, bc, nx, ny, dx, dy)

    return u_new
end

-- Gauss-Seidel 迭代法
local function gauss_seidel_iteration(u, f, bc, nx, ny, dx, dy)
    local dx2 = dx * dx
    local dy2 = dy * dy
    local factor = 2 * (1/dx2 + 1/dy2)

    -- 原地更新
    for i = 2, nx - 1 do
        for j = 2, ny - 1 do
            local f_val = type(f) == "function" and f(i, j) or f
            u[i][j] = ((u[i+1][j] + u[i-1][j]) / dx2
                    + (u[i][j+1] + u[i][j-1]) / dy2
                    - f_val) / factor
        end
    end

    -- 应用边界条件
    apply_boundary_conditions(u, bc, nx, ny, dx, dy)

    return u
end

-- SOR（逐次超松弛）迭代法
local function sor_iteration(u, f, bc, nx, ny, dx, dy, omega)
    local dx2 = dx * dx
    local dy2 = dy * dy
    local factor = 2 * (1/dx2 + 1/dy2)

    -- 原地更新
    for i = 2, nx - 1 do
        for j = 2, ny - 1 do
            local f_val = type(f) == "function" and f(i, j) or f
            local gs_val = ((u[i+1][j] + u[i-1][j]) / dx2
                        + (u[i][j+1] + u[i][j-1]) / dy2
                        - f_val) / factor
            u[i][j] = (1 - omega) * u[i][j] + omega * gs_val
        end
    end

    -- 应用边界条件
    apply_boundary_conditions(u, bc, nx, ny, dx, dy)

    return u
end

-- 计算最优松弛因子（对于矩形区域）
local function optimal_omega(nx, ny, dx, dy)
    -- 对于正方形区域的最优omega
    local pi = math.pi
    local hx = dx / (nx - 1)
    local hy = dy / (ny - 1)

    -- Jacobi迭代矩阵的最大特征值
    local rho_j = math.cos(pi / (nx - 1)) * (hx * hx) / (hx * hx + hy * hy)
                + math.cos(pi / (ny - 1)) * (hy * hy) / (hx * hx + hy * hy)

    -- 最优松弛因子
    return 2 / (1 + math.sqrt(1 - rho_j * rho_j))
end

-- =============================================================================
-- 主求解函数
-- =============================================================================

-- 求解二维泊松方程: ∇²u = f
-- @param f 源项函数 f(x, y) 或常数值
-- @param bounds 区域边界 {ax, bx, ay, by}
-- @param bc 边界条件表 {left, right, top, bottom}
--   每个边界条件: {type = "dirichlet"|"neumann", value = ...}
-- @param options 选项表：
--   - nx, ny: 网格点数（默认 50）
--   - max_iter: 最大迭代次数（默认 10000）
--   - tol: 收敛容差（默认 1e-6）
--   - method: 求解方法 "jacobi"|"gauss_seidel"|"sor"（默认 "sor"）
--   - omega: SOR松弛因子（可选，默认自动计算）
--   - verbose: 是否打印迭代信息
-- @return 解网格 u[i][j]，收敛信息
function elliptic.poisson(f, bounds, bc, options)
    -- 参数验证
    utils.typecheck.check_type("poisson", "bounds", bounds, "table")
    utils.typecheck.check_type("poisson", "bc", bc, "table")
    utils.typecheck.check_type("poisson", "options", options, "table", "nil")

    options = options or {}
    local nx = options.nx or 50
    local ny = options.ny or 50
    local max_iter = options.max_iter or 10000
    local tol = options.tol or 1e-6
    local method = options.method or "sor"
    local verbose = options.verbose or false

    -- 解析边界
    local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
    local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1

    local dx = (bx - ax) / (nx - 1)
    local dy = (by - ay) / (ny - 1)

    -- 初始化解网格
    local u = create_grid(nx, ny, 0)

    -- 应用初始边界条件
    apply_boundary_conditions(u, bc, nx, ny, dx, dy)

    -- 选择迭代方法
    local iterate
    local omega = options.omega

    if method == "jacobi" then
        iterate = function(u_curr)
            return jacobi_iteration(u_curr, f, bc, nx, ny, dx, dy)
        end
    elseif method == "gauss_seidel" then
        iterate = function(u_curr)
            return gauss_seidel_iteration(u_curr, f, bc, nx, ny, dx, dy)
        end
    elseif method == "sor" then
        omega = omega or optimal_omega(nx, ny, bx - ax, by - ay)
        if verbose then
            print(string.format("  SOR omega: %.4f", omega))
        end
        iterate = function(u_curr)
            return sor_iteration(u_curr, f, bc, nx, ny, dx, dy, omega)
        end
    else
        error("Unknown method: " .. method)
    end

    -- 迭代求解
    local converged = false
    local iter

    for iter = 1, max_iter do
        local u_old = (method == "jacobi") and copy_grid(u) or nil
        u = iterate(u)

        -- 检查收敛
        local diff
        if method == "jacobi" then
            diff = max_diff(u, u_old)
        else
            -- 对于Gauss-Seidel和SOR，使用残差估计
            diff = residual_norm(u, f, nx, ny, dx, dy)
        end

        if verbose and iter % 100 == 0 then
            print(string.format("  iter %d: diff = %.2e", iter, diff))
        end

        if diff < tol then
            converged = true
            break
        end
    end

    -- 返回结果
    local info = {
        converged = converged,
        iterations = iter or max_iter,
        method = method,
        omega = omega
    }

    return u, info
end

-- 求解二维拉普拉斯方程: ∇²u = 0
-- @param bounds 区域边界 {ax, bx, ay, by}
-- @param bc 边界条件表
-- @param options 选项表
-- @return 解网格 u[i][j]，收敛信息
function elliptic.laplace(bounds, bc, options)
    -- 拉普拉斯方程是泊松方程 f = 0 的特例
    return elliptic.poisson(0, bounds, bc, options)
end

-- 求解带狄利克雷边界条件的泊松方程（简化接口）
-- @param f 源项函数
-- @param bounds 区域边界
-- @param boundary_values 边界值 {left, right, bottom, top}
-- @param options 选项
-- @return 解网格
function elliptic.poisson_simple(f, bounds, boundary_values, options)
    local bc = {
        left = {type = "dirichlet", value = boundary_values[1] or boundary_values.left or 0},
        right = {type = "dirichlet", value = boundary_values[2] or boundary_values.right or 0},
        bottom = {type = "dirichlet", value = boundary_values[3] or boundary_values.bottom or 0},
        top = {type = "dirichlet", value = boundary_values[4] or boundary_values.top or 0}
    }
    return elliptic.poisson(f, bounds, bc, options)
end

-- =============================================================================
-- 辅助输出函数
-- =============================================================================

-- 获取网格坐标
function elliptic.grid_coords(bounds, nx, ny)
    local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
    local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1

    local x = {}
    local y = {}

    for i = 1, nx do
        x[i] = ax + (i - 1) * (bx - ax) / (nx - 1)
    end

    for j = 1, ny do
        y[j] = ay + (j - 1) * (by - ay) / (ny - 1)
    end

    return x, y
end

-- 获取解在特定点的值（双线性插值）
function elliptic.interpolate(u, bounds, x, y)
    local nx, ny = #u, #u[1]
    local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
    local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1

    local dx = (bx - ax) / (nx - 1)
    local dy = (by - ay) / (ny - 1)

    -- 找到所在的网格单元
    local i = math.floor((x - ax) / dx) + 1
    local j = math.floor((y - ay) / dy) + 1

    -- 边界处理
    i = math.max(1, math.min(nx - 1, i))
    j = math.max(1, math.min(ny - 1, j))

    -- 双线性插值
    local tx = (x - (ax + (i - 1) * dx)) / dx
    local ty = (y - (ay + (j - 1) * dy)) / dy

    tx = math.max(0, math.min(1, tx))
    ty = math.max(0, math.min(1, ty))

    local u00 = u[i][j]
    local u10 = u[i + 1][j]
    local u01 = u[i][j + 1]
    local u11 = u[i + 1][j + 1]

    return (1 - tx) * (1 - ty) * u00 + tx * (1 - ty) * u10
         + (1 - tx) * ty * u01 + tx * ty * u11
end

return elliptic