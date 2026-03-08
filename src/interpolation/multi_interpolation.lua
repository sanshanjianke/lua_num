-- 多维插值方法模块
-- 支持双线性插值、双三次插值、径向基函数插值等

local math = math
local utils = require("utils.init")

local multi_interpolation = {}

-- =============================================================================
-- 双线性插值
-- =============================================================================

-- 在二维网格上进行双线性插值
-- @param x, y 要插值的点坐标
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组（严格递增）
-- @param z_grid 二维值网格，z_grid[i][j] 对应 (x_data[i], y_data[j])
-- @return 插值结果
function multi_interpolation.bilinear(x, y, x_data, y_data, z_grid)
    -- 参数验证
    utils.typecheck.check_type("bilinear", "x", x, "number")
    utils.typecheck.check_type("bilinear", "y", y, "number")
    utils.typecheck.check_type("bilinear", "x_data", x_data, "table")
    utils.typecheck.check_type("bilinear", "y_data", y_data, "table")
    utils.typecheck.check_type("bilinear", "z_grid", z_grid, "table")

    local nx, ny = #x_data, #y_data

    -- 检查范围
    if x < x_data[1] or x > x_data[nx] then
        error(string.format("x=%f is outside the interpolation range [%f, %f]",
            x, x_data[1], x_data[nx]))
    end
    if y < y_data[1] or y > y_data[ny] then
        error(string.format("y=%f is outside the interpolation range [%f, %f]",
            y, y_data[1], y_data[ny]))
    end

    -- 查找x区间
    local ix = 1
    for i = 1, nx - 1 do
        if x_data[i] <= x and x <= x_data[i + 1] then
            ix = i
            break
        end
    end

    -- 查找y区间
    local iy = 1
    for j = 1, ny - 1 do
        if y_data[j] <= y and y <= y_data[j + 1] then
            iy = j
            break
        end
    end

    -- 四个角点的值
    local z11 = z_grid[ix][iy]
    local z21 = z_grid[ix + 1][iy]
    local z12 = z_grid[ix][iy + 1]
    local z22 = z_grid[ix + 1][iy + 1]

    -- 双线性插值
    local x1, x2 = x_data[ix], x_data[ix + 1]
    local y1, y2 = y_data[iy], y_data[iy + 1]

    local tx = (x - x1) / (x2 - x1)
    local ty = (y - y1) / (y2 - y1)

    -- 双线性插值公式
    local z = (1 - tx) * (1 - ty) * z11 +
              tx * (1 - ty) * z21 +
              (1 - tx) * ty * z12 +
              tx * ty * z22

    return z
end

-- 批量双线性插值
-- @param points 点数组 {{x1,y1}, {x2,y2}, ...}
-- @param x_data, y_data, z_grid 同上
-- @return 插值结果数组
function multi_interpolation.bilinear_batch(points, x_data, y_data, z_grid)
    utils.typecheck.check_type("bilinear_batch", "points", points, "table")

    local results = {}
    for i, pt in ipairs(points) do
        results[i] = multi_interpolation.bilinear(pt[1], pt[2], x_data, y_data, z_grid)
    end
    return results
end

-- =============================================================================
-- 双三次插值
-- =============================================================================

-- 三次Hermite基函数
local function cubic_hermite(t)
    local t2 = t * t
    local t3 = t2 * t
    -- 使用Catmull-Rom样条的导数近似
    return {
        1 - 3*t2 + 2*t3,   -- H0
        t - 2*t2 + t3,     -- H1 (导数基)
        3*t2 - 2*t3,       -- H2
        -t2 + t3           -- H3 (导数基)
    }
end

-- 一维三次插值（用于双三次插值）
local function cubic_interp_1d(t, f0, f1, f2, f3)
    -- Catmull-Rom样条
    local t2 = t * t
    local t3 = t2 * t

    return 0.5 * (
        (2*f1) +
        (-f0 + f2) * t +
        (2*f0 - 5*f1 + 4*f2 - f3) * t2 +
        (-f0 + 3*f1 - 3*f2 + f3) * t3
    )
end

-- 双三次插值（使用Catmull-Rom样条）
-- @param x, y 要插值的点坐标
-- @param x_data x坐标数组
-- @param y_data y坐标数组
-- @param z_grid 二维值网格
-- @return 插值结果
function multi_interpolation.bicubic(x, y, x_data, y_data, z_grid)
    -- 参数验证
    utils.typecheck.check_type("bicubic", "x", x, "number")
    utils.typecheck.check_type("bicubic", "y", y, "number")
    utils.typecheck.check_type("bicubic", "x_data", x_data, "table")
    utils.typecheck.check_type("bicubic", "y_data", y_data, "table")
    utils.typecheck.check_type("bicubic", "z_grid", z_grid, "table")

    local nx, ny = #x_data, #y_data

    -- 检查范围（边界处理）
    if x < x_data[1] or x > x_data[nx] then
        error(string.format("x=%f is outside the interpolation range [%f, %f]",
            x, x_data[1], x_data[nx]))
    end
    if y < y_data[1] or y > y_data[ny] then
        error(string.format("y=%f is outside the interpolation range [%f, %f]",
            y, y_data[1], y_data[ny]))
    end

    -- 查找中心区间
    local ix = math.max(2, math.min(nx - 2, 1))
    for i = 1, nx - 1 do
        if x_data[i] <= x and x <= x_data[i + 1] then
            ix = i
            break
        end
    end

    local iy = math.max(2, math.min(ny - 2, 1))
    for j = 1, ny - 1 do
        if y_data[j] <= y and y <= y_data[j + 1] then
            iy = j
            break
        end
    end

    -- 获取4x4邻域
    local x_idx = {}
    for i = -1, 2 do
        local idx = ix + i
        if idx < 1 then idx = 1
        elseif idx > nx then idx = nx end
        x_idx[i + 2] = idx
    end

    local y_idx = {}
    for j = -1, 2 do
        local idx = iy + j
        if idx < 1 then idx = 1
        elseif idx > ny then idx = ny end
        y_idx[j + 2] = idx
    end

    -- 计算插值
    local x1, x2 = x_data[ix], x_data[ix + 1]
    local y1, y2 = y_data[iy], y_data[iy + 1]
    local tx = (x - x1) / (x2 - x1)
    local ty = (y - y1) / (y2 - y1)

    -- 沿y方向插值4次
    local col_values = {}
    for i = 1, 4 do
        local f0 = z_grid[x_idx[1]][y_idx[i]]
        local f1 = z_grid[x_idx[2]][y_idx[i]]
        local f2 = z_grid[x_idx[3]][y_idx[i]]
        local f3 = z_grid[x_idx[4]][y_idx[i]]
        col_values[i] = cubic_interp_1d(tx, f0, f1, f2, f3)
    end

    -- 沿x方向插值
    local result = cubic_interp_1d(ty, col_values[1], col_values[2], col_values[3], col_values[4])

    return result
end

-- =============================================================================
-- 径向基函数插值
-- =============================================================================

-- 常用径向基函数
local rbf_kernels = {
    -- 高斯RBF: phi(r) = exp(-(r/epsilon)^2)
    gaussian = function(r, epsilon)
        epsilon = epsilon or 1.0
        return math.exp(-(r / epsilon) ^ 2)
    end,

    -- 多二次RBF: phi(r) = sqrt(1 + (r/epsilon)^2)
    multiquadric = function(r, epsilon)
        epsilon = epsilon or 1.0
        return math.sqrt(1 + (r / epsilon) ^ 2)
    end,

    -- 逆多二次RBF: phi(r) = 1 / sqrt(1 + (r/epsilon)^2)
    inverse_multiquadric = function(r, epsilon)
        epsilon = epsilon or 1.0
        return 1 / math.sqrt(1 + (r / epsilon) ^ 2)
    end,

    -- 薄板样条RBF: phi(r) = r^2 * log(r)
    thin_plate = function(r, epsilon)
        if r < 1e-10 then return 0 end
        return r * r * math.log(r)
    end,

    -- 线性RBF: phi(r) = r
    linear = function(r, epsilon)
        return r
    end,

    -- 三次RBF: phi(r) = r^3
    cubic = function(r, epsilon)
        return r * r * r
    end
}

-- 计算两点间的欧氏距离
local function euclidean_distance(p1, p2)
    local sum = 0
    for i = 1, #p1 do
        local diff = p1[i] - p2[i]
        sum = sum + diff * diff
    end
    return math.sqrt(sum)
end

-- RBF插值求解器（内部使用）
-- @param points 已知点集合 {{x1, y1, ...}, {x2, y2, ...}, ...}
-- @param values 已知点的值
-- @param kernel RBF核函数名
-- @param epsilon RBF参数
-- @return 插值权重
local function rbf_solve(points, values, kernel, epsilon)
    local n = #points
    local kernel_func = rbf_kernels[kernel] or rbf_kernels.gaussian

    -- 构建矩阵 A[i][j] = phi(||pi - pj||)
    local A = {}
    for i = 1, n do
        A[i] = {}
        for j = 1, n do
            local r = euclidean_distance(points[i], points[j])
            A[i][j] = kernel_func(r, epsilon)
        end
    end

    -- 使用高斯消元法求解 A * w = values
    -- 创建增广矩阵
    local aug = {}
    for i = 1, n do
        aug[i] = {}
        for j = 1, n do
            aug[i][j] = A[i][j]
        end
        aug[i][n + 1] = values[i]
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

        if math.abs(aug[k][k]) < 1e-12 then
            error("RBF matrix is singular")
        end

        for i = k + 1, n do
            local factor = aug[i][k] / aug[k][k]
            for j = k, n + 1 do
                aug[i][j] = aug[i][j] - factor * aug[k][j]
            end
        end
    end

    -- 回代
    local weights = {}
    for i = n, 1, -1 do
        local sum = aug[i][n + 1]
        for j = i + 1, n do
            sum = sum - aug[i][j] * weights[j]
        end
        weights[i] = sum / aug[i][i]
    end

    return weights
end

-- 径向基函数插值
-- @param point 要插值的点 {x, y, ...}
-- @param points 已知点集合 {{x1, y1, ...}, ...}
-- @param values 已知点的值
-- @param options 选项表：
--   - kernel: RBF核函数名（"gaussian", "multiquadric", "inverse_multiquadric", "thin_plate", "linear", "cubic"）
--   - epsilon: RBF参数
--   - weights: 预计算的权重（可选，避免重复计算）
-- @return 插值结果
function multi_interpolation.rbf(point, points, values, options)
    -- 参数验证
    utils.typecheck.check_type("rbf", "point", point, "table")
    utils.typecheck.check_type("rbf", "points", points, "table")
    utils.typecheck.check_type("rbf", "values", values, "table")

    if #points ~= #values then
        error("points and values must have the same length")
    end

    options = options or {}
    local kernel = options.kernel or "gaussian"
    local epsilon = options.epsilon or 1.0
    local kernel_func = rbf_kernels[kernel]

    if not kernel_func then
        error("Unknown RBF kernel: " .. kernel)
    end

    -- 获取或计算权重
    local weights = options.weights
    if not weights then
        weights = rbf_solve(points, values, kernel, epsilon)
    end

    -- 计算插值
    local result = 0
    for i = 1, #points do
        local r = euclidean_distance(point, points[i])
        result = result + weights[i] * kernel_func(r, epsilon)
    end

    return result
end

-- 预计算RBF权重
-- @param points 已知点集合
-- @param values 已知点的值
-- @param options RBF选项
-- @return 权重数组
function multi_interpolation.rbf_weights(points, values, options)
    utils.typecheck.check_type("rbf_weights", "points", points, "table")
    utils.typecheck.check_type("rbf_weights", "values", values, "table")

    options = options or {}
    local kernel = options.kernel or "gaussian"
    local epsilon = options.epsilon or 1.0

    return rbf_solve(points, values, kernel, epsilon)
end

-- =============================================================================
-- 多元拉格朗日插值
-- =============================================================================

-- 多元拉格朗日插值（适用于散乱数据点）
-- 注意：当点数较多时，计算量会很大
-- @param point 要插值的点 {x, y, ...}
-- @param points 已知点集合
-- @param values 已知点的值
-- @return 插值结果
function multi_interpolation.multivariate_lagrange(point, points, values)
    -- 参数验证
    utils.typecheck.check_type("multivariate_lagrange", "point", point, "table")
    utils.typecheck.check_type("multivariate_lagrange", "points", points, "table")
    utils.typecheck.check_type("multivariate_lagrange", "values", values, "table")

    if #points ~= #values then
        error("points and values must have the same length")
    end

    local n = #points
    if n < 1 then
        error("At least one point is required for interpolation")
    end

    -- 计算拉格朗日插值
    local result = 0

    for i = 1, n do
        -- 计算拉格朗日基函数 L_i(point)
        local Li = 1
        for j = 1, n do
            if j ~= i then
                -- 计算分子：||point - pj||^2
                local num = 0
                for k = 1, #point do
                    local diff = point[k] - points[j][k]
                    num = num + diff * diff
                end

                -- 计算分母：||pi - pj||^2
                local denom = 0
                for k = 1, #point do
                    local diff = points[i][k] - points[j][k]
                    denom = denom + diff * diff
                end

                if denom < 1e-20 then
                    -- 两点重合
                    Li = 0
                    break
                end

                Li = Li * num / denom
            end
        end
        result = result + values[i] * Li
    end

    return result
end

-- =============================================================================
-- 最近邻插值
-- =============================================================================

-- 最近邻插值
-- @param point 要插值的点 {x, y, ...}
-- @param points 已知点集合
-- @param values 已知点的值
-- @return 插值结果
function multi_interpolation.nearest_neighbor(point, points, values)
    -- 参数验证
    utils.typecheck.check_type("nearest_neighbor", "point", point, "table")
    utils.typecheck.check_type("nearest_neighbor", "points", points, "table")
    utils.typecheck.check_type("nearest_neighbor", "values", values, "table")

    if #points ~= #values then
        error("points and values must have the same length")
    end

    local min_dist = math.huge
    local nearest_value = values[1]

    for i = 1, #points do
        local dist = euclidean_distance(point, points[i])
        if dist < min_dist then
            min_dist = dist
            nearest_value = values[i]
        end
    end

    return nearest_value
end

-- =============================================================================
-- 反距离加权插值（IDW）
-- =============================================================================

-- 反距离加权插值
-- @param point 要插值的点 {x, y, ...}
-- @param points 已知点集合
-- @param values 已知点的值
-- @param options 选项表：
--   - power: 距离权重幂次（默认2）
--   - radius: 搜索半径（可选，默认无限制）
-- @return 插值结果
function multi_interpolation.idw(point, points, values, options)
    -- 参数验证
    utils.typecheck.check_type("idw", "point", point, "table")
    utils.typecheck.check_type("idw", "points", points, "table")
    utils.typecheck.check_type("idw", "values", values, "table")

    if #points ~= #values then
        error("points and values must have the same length")
    end

    options = options or {}
    local power = options.power or 2
    local radius = options.radius

    local sum_weights = 0
    local sum_values = 0

    for i = 1, #points do
        local dist = euclidean_distance(point, points[i])

        -- 如果点重合，直接返回该值
        if dist < 1e-10 then
            return values[i]
        end

        -- 如果有搜索半径限制
        if radius and dist > radius then
            -- 跳过超出半径的点
        else
            local weight = 1 / (dist ^ power)
            sum_weights = sum_weights + weight
            sum_values = sum_values + weight * values[i]
        end
    end

    if sum_weights < 1e-10 then
        -- 没有有效点
        return 0
    end

    return sum_values / sum_weights
end

-- =============================================================================
-- 统一接口
-- =============================================================================

-- 多维插值统一接口
-- @param point 要插值的点（一维数组 {x, y, ...} 或二维点数组）
-- @param data 插值数据（格式取决于方法）
-- @param options 选项表
-- @return 插值结果
function multi_interpolation.interpolate(point, data, options)
    options = options or {}
    local method = options.method or "bilinear"

    if method == "bilinear" or method == "bicubic" then
        -- 规则网格插值
        local x, y = point[1], point[2]
        local x_data, y_data, z_grid = data.x_data, data.y_data, data.z_grid

        if method == "bilinear" then
            return multi_interpolation.bilinear(x, y, x_data, y_data, z_grid)
        else
            return multi_interpolation.bicubic(x, y, x_data, y_data, z_grid)
        end
    elseif method == "rbf" then
        -- 径向基函数插值
        return multi_interpolation.rbf(point, data.points, data.values, options)
    elseif method == "lagrange" or method == "multivariate_lagrange" then
        -- 多元拉格朗日插值
        return multi_interpolation.multivariate_lagrange(point, data.points, data.values)
    elseif method == "nearest" or method == "nearest_neighbor" then
        -- 最近邻插值
        return multi_interpolation.nearest_neighbor(point, data.points, data.values)
    elseif method == "idw" then
        -- 反距离加权插值
        return multi_interpolation.idw(point, data.points, data.values, options)
    else
        error("Unknown interpolation method: " .. method)
    end
end

-- 导出RBF核函数（供高级用户使用）
multi_interpolation.rbf_kernels = rbf_kernels

return multi_interpolation