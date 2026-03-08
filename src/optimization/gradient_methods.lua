-- 梯度相关优化方法：使用导数的优化算法
local utils = require("utils.init")

local gradient_methods = {}

-- 梯度下降法
-- @param f 目标函数
-- @param grad 梯度函数，返回梯度向量
-- @param x0 初始点（向量）
-- @param options 选项表：
--   - learning_rate: 学习率（默认 0.01）
--   - max_iter: 最大迭代次数（默认 1000）
--   - tol: 收敛容差（默认 1e-6）
--   - momentum: 动量系数（默认 0，不使用动量）
--   - decay: 学习率衰减因子（默认 1，不衰减）
-- @return 最优解，最优值，迭代次数，收敛信息表
function gradient_methods.gradient_descent(f, grad, x0, options)
    -- 参数验证
    utils.typecheck.check_type("gradient_descent", "f", f, "function")
    utils.typecheck.check_type("gradient_descent", "grad", grad, "function")
    utils.typecheck.check_type("gradient_descent", "x0", x0, "table")
    utils.typecheck.check_type("gradient_descent", "options", options, "table", "nil")

    options = options or {}
    local learning_rate = options.learning_rate or 0.01
    local max_iter = options.max_iter or 1000
    local tol = options.tol or 1e-6
    local momentum = options.momentum or 0
    local decay = options.decay or 1

    -- 检查维度
    local n = #x0

    -- 初始化
    local x = {}
    for i = 1, n do x[i] = x0[i] end

    local v = {}  -- 动量项
    for i = 1, n do v[i] = 0 end

    local g = grad(x)
    local prev_g_norm = utils.norm(g)
    local iter = 0
    local converged = false
    local lr = learning_rate

    -- 迭代
    while iter < max_iter and not converged do
        iter = iter + 1

        -- 计算梯度
        g = grad(x)
        local g_norm = utils.norm(g)

        -- 检查收敛
        if g_norm < tol then
            converged = true
            break
        end

        -- 更新动量项
        for i = 1, n do
            v[i] = momentum * v[i] - lr * g[i]
        end

        -- 更新参数
        for i = 1, n do
            x[i] = x[i] + v[i]
        end

        -- 学习率衰减
        lr = lr * decay

        prev_g_norm = g_norm
    end

    local info = {
        iterations = iter,
        converged = converged,
        final_gradient_norm = utils.norm(g)
    }

    return x, f(x), iter, info
end

-- 牛顿法（使用海森矩阵）
-- @param f 目标函数
-- @param grad 梯度函数，返回梯度向量
-- @param hessian 海森矩阵函数，返回海森矩阵
-- @param x0 初始点（向量）
-- @param options 选项表：
--   - max_iter: 最大迭代次数（默认 100）
--   - tol: 收敛容差（默认 1e-6）
--   - alpha: 阻尼因子（默认 1）
--   - regularize: 是否正则化海森矩阵（默认 false）
-- @return 最优解，最优值，迭代次数，收敛信息表
function gradient_methods.newton(f, grad, hessian, x0, options)
    -- 参数验证
    utils.typecheck.check_type("newton", "f", f, "function")
    utils.typecheck.check_type("newton", "grad", grad, "function")
    utils.typecheck.check_type("newton", "hessian", hessian, "function")
    utils.typecheck.check_type("newton", "x0", x0, "table")
    utils.typecheck.check_type("newton", "options", options, "table", "nil")

    options = options or {}
    local max_iter = options.max_iter or 100
    local tol = options.tol or 1e-6
    local alpha = options.alpha or 1
    local regularize = options.regularize or false

    local matrix = require("matrix.init")

    -- 检查维度
    local n = #x0

    -- 初始化
    local x = {}
    for i = 1, n do x[i] = x0[i] end

    local iter = 0
    local converged = false

    -- 迭代
    while iter < max_iter and not converged do
        iter = iter + 1

        -- 计算梯度和海森矩阵
        local g = grad(x)
        local g_norm = utils.norm(g)
        local H = hessian(x)

        -- 检查收敛
        if g_norm < tol then
            converged = true
            break
        end

        -- 正则化海森矩阵（如果需要）
        if regularize then
            for i = 1, n do
                H[i][i] = H[i][i] + utils.epsilon
            end
        end

        -- 将梯度转换为列向量（注意：求解 H * delta = -g）
        local g_vec = {}
        for i = 1, n do g_vec[i] = {-g[i]} end

        -- 求解 H * delta_x = -g
        local H_mat = matrix.new(H)
        local delta = H_mat:solve(matrix.new(g_vec))

        -- 更新参数
        for i = 1, n do
            x[i] = x[i] + alpha * delta.data[i][1]
        end
    end

    local info = {
        iterations = iter,
        converged = converged,
        final_gradient_norm = utils.norm(grad(x))
    }

    return x, f(x), iter, info
end

-- BFGS 拟牛顿法
-- @param f 目标函数
-- @param grad 梯度函数，返回梯度向量
-- @param x0 初始点（向量）
-- @param options 选项表：
--   - max_iter: 最大迭代次数（默认 1000）
--   - tol: 收敛容差（默认 1e-6）
--   - B0: 初始逆海森矩阵近似（默认单位矩阵）
-- @return 最优解，最优值，迭代次数，收敛信息表
function gradient_methods.bfgs(f, grad, x0, options)
    -- 参数验证
    utils.typecheck.check_type("bfgs", "f", f, "function")
    utils.typecheck.check_type("bfgs", "grad", grad, "function")
    utils.typecheck.check_type("bfgs", "x0", x0, "table")
    utils.typecheck.check_type("bfgs", "options", options, "table", "nil")

    options = options or {}
    local max_iter = options.max_iter or 1000
    local tol = options.tol or 1e-6
    local B0 = options.B0  -- 初始逆海森矩阵近似

    local n = #x0

    -- 初始化
    local x = {}
    for i = 1, n do x[i] = x0[i] end

    -- 初始化逆海森矩阵近似
    local B = {}
    if B0 then
        for i = 1, n do
            B[i] = {}
            for j = 1, n do
                B[i][j] = B0[i][j]
            end
        end
    else
        -- 单位矩阵
        for i = 1, n do
            B[i] = {}
            for j = 1, n do
                B[i][j] = (i == j) and 1 or 0
            end
        end
    end

    -- 初始梯度
    local g = grad(x)

    local iter = 0
    local converged = false

    -- 迭代
    while iter < max_iter and not converged do
        iter = iter + 1

        local g_norm = utils.norm(g)

        -- 检查收敛
        if g_norm < tol then
            converged = true
            break
        end

        -- 计算 B * g（搜索方向）
        local Bg = {}
        for i = 1, n do
            Bg[i] = 0
            for j = 1, n do
                Bg[i] = Bg[i] + B[i][j] * g[j]
            end
        end

        -- 线搜索找步长（简化版：固定步长）
        local alpha = 1.0
        local x_new = {}
        for i = 1, n do
            x_new[i] = x[i] - alpha * Bg[i]
        end

        -- 计算新梯度
        local g_new = grad(x_new)

        -- BFGS 更新
        local s = {}  -- x_new - x
        local y = {}  -- g_new - g
        for i = 1, n do
            s[i] = x_new[i] - x[i]
            y[i] = g_new[i] - g[i]
        end

        -- 计算 s^T * y
        local sTy = 0
        for i = 1, n do
            sTy = sTy + s[i] * y[i]
        end

        -- 确保 s^T * y > 0
        if sTy > 0 then
            -- 计算 B * y
            local By = {}
            for i = 1, n do
                By[i] = 0
                for j = 1, n do
                    By[i] = By[i] + B[i][j] * y[j]
                end
            end

            -- 计算 y^T * B * y
            local yTBy = 0
            for i = 1, n do
                yTBy = yTBy + y[i] * By[i]
            end

            -- BFGS 更新公式
            -- B = (I - rho * s * y^T) * B * (I - rho * y * s^T) + rho * s * s^T
            local rho = 1 / sTy

            for i = 1, n do
                for j = 1, n do
                    B[i][j] = B[i][j] - rho * s[i] * By[j] - rho * By[i] * s[j] +
                              rho * rho * yTBy * s[i] * s[j] + rho * s[i] * s[j]
                end
            end
        end

        -- 更新
        x = x_new
        g = g_new
    end

    local info = {
        iterations = iter,
        converged = converged,
        final_gradient_norm = utils.norm(g)
    }

    return x, f(x), iter, info
end

-- 共轭梯度法
-- @param f 目标函数
-- @param grad 梯度函数，返回梯度向量
-- @param x0 初始点（向量）
-- @param options 选项表：
--   - max_iter: 最大迭代次数（默认 1000）
--   - tol: 收敛容差（默认 1e-6）
--   - restart: 重启间隔（默认 n，即维度数）
--   - method: 共轭梯度方法（" Fletcher-Reeves", "Polak-Ribiere"）
-- @return 最优解，最优值，迭代次数，收敛信息表
function gradient_methods.conjugate_gradient(f, grad, x0, options)
    -- 参数验证
    utils.typecheck.check_type("conjugate_gradient", "f", f, "function")
    utils.typecheck.check_type("conjugate_gradient", "grad", grad, "function")
    utils.typecheck.check_type("conjugate_gradient", "x0", x0, "table")
    utils.typecheck.check_type("conjugate_gradient", "options", options, "table", "nil")

    options = options or {}
    local max_iter = options.max_iter or 1000
    local tol = options.tol or 1e-6
    local restart = options.restart or #x0
    local method = options.method or "Fletcher-Reeves"

    local n = #x0

    -- 初始化
    local x = {}
    for i = 1, n do x[i] = x0[i] end

    -- 初始梯度
    local g = grad(x)
    local d = {}  -- 搜索方向
    for i = 1, n do d[i] = -g[i] end

    local iter = 0
    local converged = false

    -- 迭代
    while iter < max_iter and not converged do
        iter = iter + 1

        local g_norm = utils.norm(g)

        -- 检查收敛
        if g_norm < tol then
            converged = true
            break
        end

        -- 线搜索找步长（简化版：固定步长）
        local alpha = 0.01

        -- 计算新点
        local x_new = {}
        for i = 1, n do
            x_new[i] = x[i] + alpha * d[i]
        end

        -- 计算新梯度
        local g_new = grad(x_new)

        -- 计算新搜索方向
        if iter % restart == 0 then
            -- 重启：最速下降方向
            for i = 1, n do
                d[i] = -g_new[i]
            end
        else
            -- 计算共轭参数 beta
            local beta = 0
            local g_new_norm_sq = 0
            local g_norm_sq = 0

            for i = 1, n do
                g_new_norm_sq = g_new_norm_sq + g_new[i] * g_new[i]
                g_norm_sq = g_norm_sq + g[i] * g[i]
            end

            if method == "Polak-Ribiere" then
                -- Polak-Ribiere 公式
                local y_g_new = 0
                for i = 1, n do
                    y_g_new = y_g_new + (g_new[i] - g[i]) * g_new[i]
                end
                beta = y_g_new / g_norm_sq
                if beta < 0 then beta = 0 end  -- 确保下降方向
            else
                -- Fletcher-Reeves 公式（默认）
                beta = g_new_norm_sq / g_norm_sq
            end

            -- 更新搜索方向
            for i = 1, n do
                d[i] = -g_new[i] + beta * d[i]
            end
        end

        -- 更新
        x = x_new
        g = g_new
    end

    local info = {
        iterations = iter,
        converged = converged,
        final_gradient_norm = utils.norm(g)
    }

    return x, f(x), iter, info
end

-- 随机梯度下降（SGD）
-- @param f 目标函数（接受数据和参数）
-- @param grad 梯度函数（接受单个样本和参数）
-- @param data 数据集
-- @param x0 初始参数（向量）
-- @param options 选项表：
--   - epochs: 训练轮数（默认 100）
--   - batch_size: 批次大小（默认 1，即纯SGD）
--   - learning_rate: 学习率（默认 0.01）
--   - shuffle: 是否打乱数据（默认 true）
-- @return 最优解，最终损失
function gradient_methods.stochastic_gradient_descent(f, grad, data, x0, options)
    -- 参数验证
    utils.typecheck.check_type("stochastic_gradient_descent", "f", f, "function")
    utils.typecheck.check_type("stochastic_gradient_descent", "grad", grad, "function")
    utils.typecheck.check_type("stochastic_gradient_descent", "data", data, "table")
    utils.typecheck.check_type("stochastic_gradient_descent", "x0", x0, "table")
    utils.typecheck.check_type("stochastic_gradient_descent", "options", options, "table", "nil")

    options = options or {}
    local epochs = options.epochs or 100
    local batch_size = options.batch_size or 1
    local learning_rate = options.learning_rate or 0.01
    local shuffle = options.shuffle ~= false

    local n = #x0
    local N = #data  -- 数据集大小

    -- 初始化
    local x = {}
    for i = 1, n do x[i] = x0[i] end

    -- 辅助函数：打乱数据
    local function shuffle_data()
        local indices = {}
        for i = 1, N do indices[i] = i end

        for i = N, 2, -1 do
            local j = math.random(1, i)
            indices[i], indices[j] = indices[j], indices[i]
        end

        return indices
    end

    -- 训练循环
    for epoch = 1, epochs do
        local indices = shuffle and shuffle_data() or {}

        for start = 1, N, batch_size do
            local batch_grad = {}
            for i = 1, n do batch_grad[i] = 0 end

            local batch_count = 0

            -- 处理当前批次
            for b = start, math.min(start + batch_size - 1, N) do
                local idx = shuffle and indices[b] or b
                local sample = data[idx]
                local g = grad(sample, x)

                for i = 1, n do
                    batch_grad[i] = batch_grad[i] + g[i]
                end

                batch_count = batch_count + 1
            end

            -- 平均梯度
            for i = 1, n do
                batch_grad[i] = batch_grad[i] / batch_count
            end

            -- 更新参数
            for i = 1, n do
                x[i] = x[i] - learning_rate * batch_grad[i]
            end
        end
    end

    return x, f(data, x)
end

return gradient_methods
