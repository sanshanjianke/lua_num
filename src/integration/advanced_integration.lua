-- 高级数值积分方法
-- 包括自适应积分、龙贝格积分和高斯求积

local math = math
local utils = require("utils.init")
local basic = require("integration.basic_integration")

-- 高级积分方法模块
local advanced_integration = {}

-- 自适应积分（基于辛普森法）
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param tol 容差（可选，默认为1e-8）
-- @param max_iter 最大迭代次数（可选，默认为50）
-- @return 积分近似值
function advanced_integration.adaptive(f, a, b, tol, max_iter)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    tol = tol or 1e-8
    max_iter = max_iter or 50

    if type(tol) ~= "number" or tol <= 0 then
        utils.Error.invalid_argument("tol", "positive number", type(tol))
    end
    if type(max_iter) ~= "number" or max_iter <= 0 then
        utils.Error.invalid_argument("max_iter", "positive integer", type(max_iter))
    end

    if a == b then
        return 0
    end

    -- 递归函数
    local function adaptive_recursive(a, b, tol)
        local c = (a + b) / 2
        local whole = basic.simpson(f, a, b, 2)
        local left = basic.simpson(f, a, c, 2)
        local right = basic.simpson(f, c, b, 2)

        if math.abs(left + right - whole) < 15 * tol then
            return left + right + (left + right - whole) / 15
        else
            return adaptive_recursive(a, c, tol/2) + adaptive_recursive(c, b, tol/2)
        end
    end

    return adaptive_recursive(a, b, tol)
end

-- 龙贝格积分
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 最大迭代次数（可选，默认为20）
-- @param tol 容差（可选，默认为1e-10）
-- @return 积分近似值
function advanced_integration.romberg(f, a, b, n, tol)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 20
    tol = tol or 1e-10

    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end
    if type(tol) ~= "number" or tol <= 0 then
        utils.Error.invalid_argument("tol", "positive number", type(tol))
    end

    if a == b then
        return 0
    end

    -- 初始化龙贝格表
    local R = {}
    for i = 0, n do
        R[i] = {}
    end

    -- 梯形法则的递归关系
    local function trapezoid(n)
        local h = (b - a) / n
        local sum = f(a) + f(b)
        for i = 1, n - 1 do
            sum = sum + 2 * f(a + i * h)
        end
        return sum * h / 2
    end

    -- 计算第一列
    for k = 0, n do
        local points = 2^k
        R[k][0] = trapezoid(points)
    end

    -- 龙贝格外推
    for j = 1, n do
        for k = j, n do
            R[k][j] = R[k][j-1] + (R[k][j-1] - R[k-1][j-1]) / (4^j - 1)
        end
    end

    -- 检查收敛性
    for j = n, 2, -1 do
        if math.abs(R[n][j] - R[n][j-1]) < tol then
            return R[n][j]
        end
    end

    return R[n][n]
end

-- 高斯-勒让德求积（使用预计算的节点和权重）
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 节点数（可选，默认为5，支持2,3,4,5）
-- @return 积分近似值
function advanced_integration.gauss(f, a, b, n)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 5
    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end

    if a == b then
        return 0
    end

    -- 高斯-勒让德节点和权重（标准化区间[-1, 1]）
    local nodes_weights = {
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

    -- 如果没有预计算的节点权重，使用梯形法
    local nw = nodes_weights[n]
    if not nw then
        return basic.trapezoidal(f, a, b, 100)
    end

    -- 坐标变换：从[a, b]到[-1, 1]
    local half_length = (b - a) / 2
    local center = (a + b) / 2

    local sum = 0
    for i = 1, n do
        local x_transformed = center + half_length * nw.nodes[i]
        sum = sum + nw.weights[i] * f(x_transformed)
    end

    return sum * half_length
end

-- 复合高斯求积
-- 将积分区间分成若干子区间，在每个子区间上应用高斯求积
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param n 每个子区间的节点数（可选，默认为5）
-- @param m 子区间数（可选，默认为10）
-- @return 积分近似值
function advanced_integration.composite_gauss(f, a, b, n, m)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    n = n or 5
    m = m or 10

    if type(n) ~= "number" or n <= 0 then
        utils.Error.invalid_argument("n", "positive integer", type(n))
    end
    if type(m) ~= "number" or m <= 0 then
        utils.Error.invalid_argument("m", "positive integer", type(m))
    end

    if a == b then
        return 0
    end

    local h = (b - a) / m
    local sum = 0

    for i = 0, m - 1 do
        local left = a + i * h
        local right = a + (i + 1) * h
        sum = sum + advanced_integration.gauss(f, left, right, n)
    end

    return sum
end

-- 奇异积分处理（使用变量替换）
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param type 奇异类型："left"（左端点）、"right"（右端点）、"both"（两端）
-- @param method 积分方法（可选，默认为"gauss"）
-- @return 积分近似值
function advanced_integration.singular(f, a, b, singular_type, method)
    -- 参数验证
    if type(f) ~= "function" then
        utils.Error.invalid_argument("f", "function", type(f))
    end
    if type(a) ~= "number" then
        utils.Error.invalid_argument("a", "number", type(a))
    end
    if type(b) ~= "number" then
        utils.Error.invalid_argument("b", "number", type(b))
    end

    singular_type = singular_type or "both"
    method = method or "gauss"

    if singular_type ~= "left" and singular_type ~= "right" and singular_type ~= "both" then
        utils.Error.invalid_argument("type", "'left', 'right', or 'both'", type(singular_type))
    end

    if a == b then
        return 0
    end

    -- 定义被积函数（直接计算，避免中间变量的数值问题）
    local function transformed_f(t)
        if singular_type == "left" then
            -- 左端点奇异：x = a + (b-a)*t^2, t∈[0,1]
            local x = a + (b - a) * t * t
            return f(x) * 2 * (b - a) * t
        elseif singular_type == "right" then
            -- 右端点奇异：x = b - (b-a)*t^2, t∈[0,1]
            local x = b - (b - a) * t * t
            return f(x) * 2 * (b - a) * t
        else
            -- 两端奇异：x = a + (b-a)*(t+1)/2, t∈[-1,1]
            local x = a + (b - a) * (t + 1) / 2
            return f(x) * (b - a) / 2
        end
    end

    if method == "gauss" then
        if singular_type == "left" or singular_type == "right" then
            -- 积分区间为[0, 1]
            return advanced_integration.gauss(transformed_f, 0, 1, 5)
        else
            -- 积分区间为[-1, 1]
            return advanced_integration.gauss(transformed_f, -1, 1, 5)
        end
    else
        if singular_type == "left" or singular_type == "right" then
            return basic.simpson(transformed_f, 0, 1, 100)
        else
            return basic.simpson(transformed_f, -1, 1, 100)
        end
    end
end

return advanced_integration
