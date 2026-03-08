-- 多重积分方法模块
-- 支持二重积分、三重积分和蒙特卡罗积分

local math = math
local utils = require("utils.init")

local multi_integration = {}

-- 高斯-勒让德节点和权重（标准化区间[-1, 1]）
local gauss_nodes_weights = {
    [2] = {
        nodes = {-0.5773502691896257, 0.5773502691896257},
        weights = {1, 1}
    },
    [3] = {
        nodes = {-0.7745966692414834, 0, 0.7745966692414834},
        weights = {0.5555555555555556, 0.8888888888888888, 0.5555555555555556}
    },
    [4] = {
        nodes = {-0.8611363115940526, -0.3399810435848563, 0.3399810435848563, 0.8611363115940526},
        weights = {0.3478548451374538, 0.6521451548625461, 0.6521451548625461, 0.3478548451374538}
    },
    [5] = {
        nodes = {-0.9061798459386640, -0.5384693101056831, 0, 0.5384693101056831, 0.9061798459386640},
        weights = {0.2369268850561891, 0.4786286704993665, 0.5688888888888889, 0.4786286704993665, 0.2369268850561891}
    },
    [6] = {
        nodes = {-0.9324695142031521, -0.6612093864662645, -0.2386191860831969, 0.2386191860831969, 0.6612093864662645, 0.9324695142031521},
        weights = {0.1713244923791704, 0.3607615730481386, 0.4679139345726910, 0.4679139345726910, 0.3607615730481386, 0.1713244923791704}
    },
    [7] = {
        nodes = {-0.9491079123427585, -0.7415311855993945, -0.4058451513773972, 0, 0.4058451513773972, 0.7415311855993945, 0.9491079123427585},
        weights = {0.1294849661688697, 0.2797053914892766, 0.3818300505051189, 0.4179591836734694, 0.3818300505051189, 0.2797053914892766, 0.1294849661688697}
    },
    [8] = {
        nodes = {-0.9602898564975363, -0.7966664774136267, -0.5255324099163290, -0.1834346424956498, 0.1834346424956498, 0.5255324099163290, 0.7966664774136267, 0.9602898564975363},
        weights = {0.1012285362903763, 0.2223810344533745, 0.3137066458778873, 0.3626837833783620, 0.3626837833783620, 0.3137066458778873, 0.2223810344533745, 0.1012285362903763}
    }
}

-- =============================================================================
-- 二重积分
-- =============================================================================

-- 二重积分 - 迭代梯形法
-- @param f 二元函数 f(x, y)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param nx, ny 各方向的分割数（可选，默认50）
-- @return 积分近似值
local function double_trapezoidal(f, ax, bx, ay, by, nx, ny)
    nx = nx or 50
    ny = ny or 50

    local hx = (bx - ax) / nx
    local hy = (by - ay) / ny
    local sum = 0

    for i = 0, nx do
        local x = ax + i * hx
        local wx = 1
        if i == 0 or i == nx then wx = 0.5 end

        for j = 0, ny do
            local y = ay + j * hy
            local wy = 1
            if j == 0 or j == ny then wy = 0.5 end

            sum = sum + wx * wy * f(x, y)
        end
    end

    return sum * hx * hy
end

-- 二重积分 - 迭代辛普森法
-- @param f 二元函数 f(x, y)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param nx, ny 各方向的分割数（可选，必须是偶数）
-- @return 积分近似值
local function double_simpson(f, ax, bx, ay, by, nx, ny)
    nx = nx or 50
    ny = ny or 50

    -- 确保是偶数
    if nx % 2 ~= 0 then nx = nx + 1 end
    if ny % 2 ~= 0 then ny = ny + 1 end

    local hx = (bx - ax) / nx
    local hy = (by - ay) / ny
    local sum = 0

    for i = 0, nx do
        local x = ax + i * hx
        local wx = 1
        if i == 0 or i == nx then
            wx = 1
        elseif i % 2 == 1 then
            wx = 4
        else
            wx = 2
        end

        for j = 0, ny do
            local y = ay + j * hy
            local wy = 1
            if j == 0 or j == ny then
                wy = 1
            elseif j % 2 == 1 then
                wy = 4
            else
                wy = 2
            end

            sum = sum + wx * wy * f(x, y)
        end
    end

    return sum * hx * hy / 9
end

-- 二重积分 - 高斯求积法
-- @param f 二元函数 f(x, y)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param n 每个方向的高斯节点数（可选，默认5，最大8）
-- @return 积分近似值
local function double_gauss(f, ax, bx, ay, by, n)
    n = n or 5
    -- 限制节点数最大为8
    if n > 8 then n = 8 end
    local nw = gauss_nodes_weights[n]
    if not nw then
        n = 5
        nw = gauss_nodes_weights[n]
    end

    -- 坐标变换
    local half_x = (bx - ax) / 2
    local center_x = (ax + bx) / 2
    local half_y = (by - ay) / 2
    local center_y = (ay + by) / 2

    local sum = 0
    for i = 1, n do
        local x = center_x + half_x * nw.nodes[i]
        local wx = nw.weights[i]

        for j = 1, n do
            local y = center_y + half_y * nw.nodes[j]
            local wy = nw.weights[j]

            sum = sum + wx * wy * f(x, y)
        end
    end

    return sum * half_x * half_y
end

-- 二重积分 - 统一接口
-- @param f 二元函数 f(x, y)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param options 选项表：
--   - method: 方法名（"trapezoidal", "simpson", "gauss"）
--   - nx, ny: 各方向的分割数
--   - n: 高斯节点数（用于gauss方法）
-- @return 积分近似值
function multi_integration.double(f, ax, bx, ay, by, options)
    -- 参数验证
    utils.typecheck.check_type("double", "f", f, "function")
    utils.typecheck.check_type("double", "ax", ax, "number")
    utils.typecheck.check_type("double", "bx", bx, "number")
    utils.typecheck.check_type("double", "ay", ay, "number")
    utils.typecheck.check_type("double", "by", by, "number")
    utils.typecheck.check_type("double", "options", options, "table", "nil")

    options = options or {}
    local method = options.method or "simpson"
    local nx = options.nx or options.n or 50
    local ny = options.ny or options.n or 50

    if method == "trapezoidal" then
        return double_trapezoidal(f, ax, bx, ay, by, nx, ny)
    elseif method == "simpson" then
        return double_simpson(f, ax, bx, ay, by, nx, ny)
    elseif method == "gauss" then
        return double_gauss(f, ax, bx, ay, by, options.n or 5)
    else
        utils.Error.invalid_argument("method", "'trapezoidal', 'simpson', or 'gauss'", method)
    end
end

-- 别名
multi_integration.double_integral = multi_integration.double

-- =============================================================================
-- 三重积分
-- =============================================================================

-- 三重积分 - 迭代辛普森法
-- @param f 三元函数 f(x, y, z)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param az, bz z 的积分区间
-- @param nx, ny, nz 各方向的分割数
-- @return 积分近似值
local function triple_simpson(f, ax, bx, ay, by, az, bz, nx, ny, nz)
    nx = nx or 20
    ny = ny or 20
    nz = nz or 20

    -- 确保是偶数
    if nx % 2 ~= 0 then nx = nx + 1 end
    if ny % 2 ~= 0 then ny = ny + 1 end
    if nz % 2 ~= 0 then nz = nz + 1 end

    local hx = (bx - ax) / nx
    local hy = (by - ay) / ny
    local hz = (bz - az) / nz
    local sum = 0

    for i = 0, nx do
        local x = ax + i * hx
        local wx = 1
        if i == 0 or i == nx then
            wx = 1
        elseif i % 2 == 1 then
            wx = 4
        else
            wx = 2
        end

        for j = 0, ny do
            local y = ay + j * hy
            local wy = 1
            if j == 0 or j == ny then
                wy = 1
            elseif j % 2 == 1 then
                wy = 4
            else
                wy = 2
            end

            for k = 0, nz do
                local z = az + k * hz
                local wz = 1
                if k == 0 or k == nz then
                    wz = 1
                elseif k % 2 == 1 then
                    wz = 4
                else
                    wz = 2
                end

                sum = sum + wx * wy * wz * f(x, y, z)
            end
        end
    end

    return sum * hx * hy * hz / 27
end

-- 三重积分 - 高斯求积法
-- @param f 三元函数 f(x, y, z)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param az, bz z 的积分区间
-- @param n 每个方向的高斯节点数（默认5，最大8）
-- @return 积分近似值
local function triple_gauss(f, ax, bx, ay, by, az, bz, n)
    n = n or 5
    -- 限制节点数最大为8
    if n > 8 then n = 8 end
    local nw = gauss_nodes_weights[n]
    if not nw then
        n = 5
        nw = gauss_nodes_weights[n]
    end

    -- 坐标变换
    local half_x = (bx - ax) / 2
    local center_x = (ax + bx) / 2
    local half_y = (by - ay) / 2
    local center_y = (ay + by) / 2
    local half_z = (bz - az) / 2
    local center_z = (az + bz) / 2

    local sum = 0
    for i = 1, n do
        local x = center_x + half_x * nw.nodes[i]
        local wx = nw.weights[i]

        for j = 1, n do
            local y = center_y + half_y * nw.nodes[j]
            local wy = nw.weights[j]

            for k = 1, n do
                local z = center_z + half_z * nw.nodes[k]
                local wz = nw.weights[k]

                sum = sum + wx * wy * wz * f(x, y, z)
            end
        end
    end

    return sum * half_x * half_y * half_z
end

-- 三重积分 - 统一接口
-- @param f 三元函数 f(x, y, z)
-- @param ax, bx x 的积分区间
-- @param ay, by y 的积分区间
-- @param az, bz z 的积分区间
-- @param options 选项表
-- @return 积分近似值
function multi_integration.triple(f, ax, bx, ay, by, az, bz, options)
    -- 参数验证
    utils.typecheck.check_type("triple", "f", f, "function")
    utils.typecheck.check_type("triple", "ax", ax, "number")
    utils.typecheck.check_type("triple", "bx", bx, "number")
    utils.typecheck.check_type("triple", "ay", ay, "number")
    utils.typecheck.check_type("triple", "by", by, "number")
    utils.typecheck.check_type("triple", "az", az, "number")
    utils.typecheck.check_type("triple", "bz", bz, "number")
    utils.typecheck.check_type("triple", "options", options, "table", "nil")

    options = options or {}
    local method = options.method or "simpson"
    local nx = options.nx or options.n or 20
    local ny = options.ny or options.n or 20
    local nz = options.nz or options.n or 20

    if method == "simpson" then
        return triple_simpson(f, ax, bx, ay, by, az, bz, nx, ny, nz)
    elseif method == "gauss" then
        return triple_gauss(f, ax, bx, ay, by, az, bz, options.n or 5)
    else
        utils.Error.invalid_argument("method", "'simpson' or 'gauss'", method)
    end
end

-- 别名
multi_integration.triple_integral = multi_integration.triple

-- =============================================================================
-- 蒙特卡罗积分
-- =============================================================================

-- 蒙特卡罗积分（适用于高维积分）
-- @param f n元函数，接受一个表参数 {x1, x2, ..., xn}
-- @param bounds 积分区域边界，形式为 {{a1, b1}, {a2, b2}, ..., {an, bn}}
-- @param options 选项表：
--   - n_samples: 采样点数（默认10000）
--   - seed: 随机种子（可选）
-- @return 积分近似值，估计误差
function multi_integration.monte_carlo(f, bounds, options)
    -- 参数验证
    utils.typecheck.check_type("monte_carlo", "f", f, "function")
    utils.typecheck.check_type("monte_carlo", "bounds", bounds, "table")
    utils.typecheck.check_type("monte_carlo", "options", options, "table", "nil")

    options = options or {}
    local n_samples = options.n_samples or 10000
    local dim = #bounds

    -- 设置随机种子
    if options.seed then
        math.randomseed(options.seed)
    end

    -- 计算区域体积
    local volume = 1
    for i = 1, dim do
        volume = volume * (bounds[i][2] - bounds[i][1])
    end

    -- 采样
    local sum = 0
    local sum_sq = 0

    for s = 1, n_samples do
        -- 生成随机点
        local point = {}
        for i = 1, dim do
            local a, b = bounds[i][1], bounds[i][2]
            point[i] = a + math.random() * (b - a)
        end

        -- 计算函数值
        local fx = f(point)
        sum = sum + fx
        sum_sq = sum_sq + fx * fx
    end

    -- 计算均值和标准差
    local mean = sum / n_samples
    local variance = (sum_sq / n_samples - mean * mean) / n_samples
    local std_error = math.sqrt(variance)

    -- 返回积分值和估计误差
    return mean * volume, std_error * volume
end

-- =============================================================================
-- 一般区域积分（通过指示函数）
-- =============================================================================

-- 一般区域上的蒙特卡罗积分
-- @param f 被积函数
-- @param bounds 包围盒边界 {{a1,b1}, {a2,b2}, ...}
-- @param region 判断点是否在积分区域的函数，返回 true/false
-- @param options 选项
-- @return 积分近似值，估计误差
function multi_integration.monte_carlo_region(f, bounds, region, options)
    -- 参数验证
    utils.typecheck.check_type("monte_carlo_region", "f", f, "function")
    utils.typecheck.check_type("monte_carlo_region", "bounds", bounds, "table")
    utils.typecheck.check_type("monte_carlo_region", "region", region, "function")
    utils.typecheck.check_type("monte_carlo_region", "options", options, "table", "nil")

    options = options or {}
    local n_samples = options.n_samples or 10000
    local dim = #bounds

    -- 设置随机种子
    if options.seed then
        math.randomseed(options.seed)
    end

    -- 计算包围盒体积
    local volume = 1
    for i = 1, dim do
        volume = volume * (bounds[i][2] - bounds[i][1])
    end

    -- 采样
    local sum = 0
    local sum_sq = 0
    local count_in_region = 0

    for s = 1, n_samples do
        -- 生成随机点
        local point = {}
        for i = 1, dim do
            local a, b = bounds[i][1], bounds[i][2]
            point[i] = a + math.random() * (b - a)
        end

        -- 检查是否在区域内
        if region(point) then
            local fx = f(point)
            sum = sum + fx
            sum_sq = sum_sq + fx * fx
            count_in_region = count_in_region + 1
        end
    end

    -- 计算积分
    local mean = sum / n_samples
    local variance = (sum_sq / n_samples - mean * mean) / n_samples
    local std_error = math.sqrt(math.abs(variance))

    return mean * volume, std_error * volume, count_in_region / n_samples
end

return multi_integration