-- 回归分析模块
local regression = {}

local utils = require("utils.init")
local descriptive = require("statistics.descriptive")
local distributions = require("statistics.distributions")
local hypothesis = require("statistics.hypothesis")

-----------------------------------------------------------------------------
-- 辅助函数
-----------------------------------------------------------------------------

-- 构建设计矩阵（包含截距项）
local function build_design_matrix(x, add_intercept)
    if add_intercept == nil then add_intercept = true end
    local n
    local p  -- 预测变量数

    if type(x[1]) == "table" then
        -- 多元回归：x 是二维数组
        n = #x
        p = #x[1]
        if add_intercept then
            p = p + 1
        end
    else
        -- 简单回归：x 是一维数组
        n = #x
        p = add_intercept and 2 or 1
    end

    local X = {}
    for i = 1, n do
        X[i] = {}
        local col = 1
        if add_intercept then
            X[i][col] = 1
            col = col + 1
        end
        if type(x[1]) == "table" then
            for j = 1, #x[i] do
                X[i][col] = x[i][j]
                col = col + 1
            end
        else
            X[i][col] = x[i]
        end
    end

    return X, n, p
end

-- 矩阵转置
local function transpose(A)
    local m, n = #A, #A[1]
    local B = {}
    for j = 1, n do
        B[j] = {}
        for i = 1, m do
            B[j][i] = A[i][j]
        end
    end
    return B
end

-- 矩阵乘法
local function matmul(A, B)
    local m, n, p = #A, #A[1], #B[1]
    local C = {}
    for i = 1, m do
        C[i] = {}
        for j = 1, p do
            local sum = 0
            for k = 1, n do
                sum = sum + A[i][k] * B[k][j]
            end
            C[i][j] = sum
        end
    end
    return C
end

-- 矩阵求逆（高斯-约旦消元法）
local function inverse(A)
    local n = #A
    -- 创建增广矩阵 [A | I]
    local aug = {}
    for i = 1, n do
        aug[i] = {}
        for j = 1, n do
            aug[i][j] = A[i][j]
        end
        for j = 1, n do
            aug[i][n + j] = (i == j) and 1 or 0
        end
    end

    -- 高斯-约旦消元
    for col = 1, n do
        -- 找主元
        local max_row = col
        for row = col + 1, n do
            if math.abs(aug[row][col]) > math.abs(aug[max_row][col]) then
                max_row = row
            end
        end

        -- 交换行
        aug[col], aug[max_row] = aug[max_row], aug[col]

        -- 检查奇异性
        if math.abs(aug[col][col]) < 1e-12 then
            utils.Error.invalid_input("Matrix is singular or nearly singular")
        end

        -- 归一化主元行
        local pivot = aug[col][col]
        for j = 1, 2 * n do
            aug[col][j] = aug[col][j] / pivot
        end

        -- 消去其他行
        for row = 1, n do
            if row ~= col then
                local factor = aug[row][col]
                for j = 1, 2 * n do
                    aug[row][j] = aug[row][j] - factor * aug[col][j]
                end
            end
        end
    end

    -- 提取逆矩阵
    local inv = {}
    for i = 1, n do
        inv[i] = {}
        for j = 1, n do
            inv[i][j] = aug[i][n + j]
        end
    end

    return inv
end

-----------------------------------------------------------------------------
-- 线性回归
-----------------------------------------------------------------------------

-- 简单线性回归
-- @param x 自变量
-- @param y 因变量
-- @return result 表，包含系数、R²、标准误等
function regression.linear(x, y)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x ~= #y then
        utils.Error.dimension_mismatch(#x, #y)
    end
    if #x < 2 then
        utils.Error.invalid_input("need at least 2 data points")
    end

    local n = #x
    local mean_x = descriptive.mean(x)
    local mean_y = descriptive.mean(y)

    -- 计算 Sxx, Syy, Sxy
    local Sxx, Syy, Sxy = 0, 0, 0
    for i = 1, n do
        local dx = x[i] - mean_x
        local dy = y[i] - mean_y
        Sxx = Sxx + dx * dx
        Syy = Syy + dy * dy
        Sxy = Sxy + dx * dy
    end

    -- 回归系数
    local slope = Sxy / Sxx
    local intercept = mean_y - slope * mean_x

    -- 预测值和残差
    local y_pred = {}
    local residuals = {}
    local SSR, SSE = 0, 0  -- 回归平方和，残差平方和
    for i = 1, n do
        y_pred[i] = intercept + slope * x[i]
        residuals[i] = y[i] - y_pred[i]
        SSE = SSE + residuals[i] * residuals[i]
        SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
    end

    -- R²
    local SST = SSR + SSE
    local R2 = SSR / SST
    local R2_adj = 1 - (1 - R2) * (n - 1) / (n - 2)

    -- 标准误
    local MSE = SSE / (n - 2)
    local se_slope = math.sqrt(MSE / Sxx)
    local se_intercept = math.sqrt(MSE * (1/n + mean_x * mean_x / Sxx))

    -- t 检验
    local t_slope = slope / se_slope
    local t_intercept = intercept / se_intercept
    local p_slope = 2 * (1 - distributions.t.cdf(math.abs(t_slope), n - 2))
    local p_intercept = 2 * (1 - distributions.t.cdf(math.abs(t_intercept), n - 2))

    -- F 检验
    local F_stat = (SSR / 1) / MSE
    local p_F = 1 - distributions.f.cdf(F_stat, 1, n - 2)

    -- 标准误（残差标准误）
    local s = math.sqrt(MSE)

    -- 协方差矩阵
    local cov_matrix = {
        {MSE * (1/n + mean_x * mean_x / Sxx), -mean_x * MSE / Sxx},
        {-mean_x * MSE / Sxx, MSE / Sxx}
    }

    return {
        intercept = intercept,
        slope = slope,
        coefficients = {intercept, slope},
        R2 = R2,
        R2_adj = R2_adj,
        MSE = MSE,
        RMSE = math.sqrt(MSE),
        SSR = SSR,
        SSE = SSE,
        SST = SST,
        F = F_stat,
        p_F = p_F,
        se = {se_intercept, se_slope},
        t = {t_intercept, t_slope},
        p = {p_intercept, p_slope},
        residuals = residuals,
        fitted = y_pred,
        n = n,
        df = n - 2,
        s = s,
        cov_matrix = cov_matrix
    }
end

-- 多元线性回归
-- @param X 设计矩阵（二维数组，每行一个观测，每列一个变量）
-- @param y 因变量
-- @param add_intercept 是否添加截距项（默认true）
-- @return result 表
function regression.multiple(X, y, add_intercept)
    if type(X) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("X and y must be tables")
    end
    if #X ~= #y then
        utils.Error.dimension_mismatch(#X, #y)
    end

    if add_intercept == nil then add_intercept = true end
    local n = #X
    local design, _, p = build_design_matrix(X, add_intercept)

    if n < p then
        utils.Error.invalid_input("not enough observations for the number of predictors")
    end

    -- 最小二乘法: beta = (X'X)^(-1) X'y
    local Xt = transpose(design)
    local XtX = matmul(Xt, design)

    local ok, XtX_inv = pcall(inverse, XtX)
    if not ok then
        utils.Error.invalid_input("cannot invert X'X matrix: " .. tostring(XtX_inv))
    end

    -- 将 y 转换为列向量
    local y_col = {}
    for i = 1, n do
        y_col[i] = {y[i]}
    end

    local Xty = matmul(Xt, y_col)
    local beta_col = matmul(XtX_inv, Xty)

    -- 提取系数
    local coefficients = {}
    for i = 1, p do
        coefficients[i] = beta_col[i][1]
    end

    -- 预测值和残差
    local y_pred = {}
    local residuals = {}
    for i = 1, n do
        local pred = 0
        for j = 1, p do
            pred = pred + design[i][j] * coefficients[j]
        end
        y_pred[i] = pred
        residuals[i] = y[i] - pred
    end

    -- 统计量
    local mean_y = descriptive.mean(y)
    local SSR, SSE = 0, 0
    for i = 1, n do
        SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
        SSE = SSE + residuals[i] * residuals[i]
    end

    local SST = SSR + SSE
    local R2 = SSR / SST
    local R2_adj = 1 - (1 - R2) * (n - 1) / (n - p)

    local MSE = SSE / (n - p)
    local RMSE = math.sqrt(MSE)

    -- F 检验
    local F_stat = (SSR / (p - 1)) / MSE
    local p_F = 1 - distributions.f.cdf(F_stat, p - 1, n - p)

    -- 系数的标准误和 t 检验
    local se = {}
    local t_values = {}
    local p_values = {}
    for j = 1, p do
        se[j] = math.sqrt(MSE * XtX_inv[j][j])
        t_values[j] = coefficients[j] / se[j]
        p_values[j] = 2 * (1 - distributions.t.cdf(math.abs(t_values[j]), n - p))
    end

    -- 协方差矩阵
    local cov_matrix = {}
    for i = 1, p do
        cov_matrix[i] = {}
        for j = 1, p do
            cov_matrix[i][j] = MSE * XtX_inv[i][j]
        end
    end

    return {
        coefficients = coefficients,
        intercept = add_intercept and coefficients[1] or nil,
        R2 = R2,
        R2_adj = R2_adj,
        MSE = MSE,
        RMSE = RMSE,
        SSR = SSR,
        SSE = SSE,
        SST = SST,
        F = F_stat,
        p_F = p_F,
        se = se,
        t = t_values,
        p = p_values,
        residuals = residuals,
        fitted = y_pred,
        n = n,
        df = n - p,
        p_predictors = p,
        cov_matrix = cov_matrix
    }
end

-----------------------------------------------------------------------------
-- 多项式回归
-----------------------------------------------------------------------------

-- 多项式回归
-- @param x 自变量
-- @param y 因变量
-- @param degree 多项式阶数（默认2）
-- @return result 表
function regression.polynomial(x, y, degree)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x ~= #y then
        utils.Error.dimension_mismatch(#x, #y)
    end

    degree = degree or 2
    local n = #x

    if degree < 1 then
        utils.Error.invalid_input("degree must be at least 1")
    end
    if n <= degree + 1 then
        utils.Error.invalid_input("need more data points than degree + 1")
    end

    -- 构建设计矩阵
    local X = {}
    for i = 1, n do
        X[i] = {}
        X[i][1] = 1  -- 截距
        for d = 1, degree do
            X[i][d + 1] = x[i] ^ d
        end
    end

    local p = degree + 1

    -- 最小二乘法
    local Xt = transpose(X)
    local XtX = matmul(Xt, X)
    local XtX_inv = inverse(XtX)

    local y_col = {}
    for i = 1, n do
        y_col[i] = {y[i]}
    end

    local Xty = matmul(Xt, y_col)
    local beta_col = matmul(XtX_inv, Xty)

    local coefficients = {}
    for i = 1, p do
        coefficients[i] = beta_col[i][1]
    end

    -- 预测值和残差
    local y_pred = {}
    local residuals = {}
    for i = 1, n do
        y_pred[i] = 0
        for j = 1, p do
            y_pred[i] = y_pred[i] + X[i][j] * coefficients[j]
        end
        residuals[i] = y[i] - y_pred[i]
    end

    -- 统计量
    local mean_y = descriptive.mean(y)
    local SSR, SSE = 0, 0
    for i = 1, n do
        SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
        SSE = SSE + residuals[i] * residuals[i]
    end

    local SST = SSR + SSE
    local R2 = SSR / SST
    local R2_adj = 1 - (1 - R2) * (n - 1) / (n - p)

    local MSE = SSE / (n - p)
    local RMSE = math.sqrt(MSE)

    local F_stat = (SSR / degree) / MSE
    local p_F = 1 - distributions.f.cdf(F_stat, degree, n - p)

    -- 系数的标准误和 t 检验
    local se = {}
    local t_values = {}
    local p_values = {}
    for j = 1, p do
        se[j] = math.sqrt(MSE * XtX_inv[j][j])
        t_values[j] = coefficients[j] / se[j]
        p_values[j] = 2 * (1 - distributions.t.cdf(math.abs(t_values[j]), n - p))
    end

    return {
        coefficients = coefficients,
        intercept = coefficients[1],
        degree = degree,
        R2 = R2,
        R2_adj = R2_adj,
        MSE = MSE,
        RMSE = RMSE,
        SSR = SSR,
        SSE = SSE,
        SST = SST,
        F = F_stat,
        p_F = p_F,
        se = se,
        t = t_values,
        p = p_values,
        residuals = residuals,
        fitted = y_pred,
        n = n,
        df = n - p
    }
end

-----------------------------------------------------------------------------
-- 预测和诊断
-----------------------------------------------------------------------------

-- 使用回归模型预测
-- @param model 回归结果
-- @param x_new 新数据（简单/多项式回归为1D数组，多元回归为2D数组）
-- @return 预测值数组
function regression.predict(model, x_new)
    if not model or not model.coefficients then
        utils.Error.invalid_input("invalid model")
    end

    local coef = model.coefficients
    local p = #coef
    local predictions = {}

    if type(x_new[1]) == "table" then
        -- 多元回归预测
        for i = 1, #x_new do
            local pred = coef[1]  -- 截距
            for j = 1, #x_new[i] do
                pred = pred + coef[j + 1] * x_new[i][j]
            end
            table.insert(predictions, pred)
        end
    else
        -- 简单回归或多项式回归
        if model.degree then
            -- 多项式回归
            for i = 1, #x_new do
                local pred = 0
                for d = 0, model.degree do
                    pred = pred + coef[d + 1] * (x_new[i] ^ d)
                end
                table.insert(predictions, pred)
            end
        else
            -- 简单线性回归
            for i = 1, #x_new do
                table.insert(predictions, coef[1] + coef[2] * x_new[i])
            end
        end
    end

    return predictions
end

-- 计算预测区间
-- @param model 回归结果
-- @param x_new 新数据点
-- @param level 置信水平（默认0.95）
-- @return lower, upper 置信区间
function regression.predict_interval(model, x_new, level)
    level = level or 0.95
    local predictions = regression.predict(model, {x_new})
    local pred = predictions[1]

    local alpha = 1 - level
    local t_crit = distributions.t.quantile(1 - alpha/2, model.df)

    -- 预测标准误
    local rmse = model.RMSE or model.s or math.sqrt(model.MSE)
    local margin = t_crit * rmse
    return pred - margin, pred + margin
end

-- 计算置信区间（均值的置信区间）
function regression.confidence_interval(model, x_new, level)
    level = level or 0.95
    local predictions = regression.predict(model, {x_new})
    local pred = predictions[1]

    local alpha = 1 - level
    local t_crit = distributions.t.quantile(1 - alpha/2, model.df)

    -- 均值的标准误（简化）
    local se_mean = model.RMSE / math.sqrt(model.n)
    local margin = t_crit * se_mean

    return pred - margin, pred + margin
end

-----------------------------------------------------------------------------
-- 模型诊断
-----------------------------------------------------------------------------

-- 计算残差诊断指标
function regression.diagnostics(model, y)
    local residuals = model.residuals
    local n = #residuals

    -- 标准化残差
    local std_residuals = {}
    local rmse = model.RMSE or model.s or math.sqrt(model.MSE)
    for i = 1, n do
        std_residuals[i] = residuals[i] / rmse
    end

    -- 学生化残差
    local student_residuals = {}
    local p_pred = model.p_predictors or 2  -- 简单回归默认为2个参数
    local h_bar = p_pred / n  -- 平均杠杆值（近似）
    for i = 1, n do
        local h_i = h_bar  -- 简化处理
        student_residuals[i] = residuals[i] / (rmse * math.sqrt(1 - h_i))
    end

    -- 残差统计
    local res_mean = descriptive.mean(residuals)
    local res_std = descriptive.std(residuals)
    local res_skew = descriptive.skewness(residuals)
    local res_kurt = descriptive.kurtosis(residuals)

    -- Durbin-Watson 统计量（自相关检验）
    local dw_num, dw_den = 0, 0
    for i = 1, n do
        dw_den = dw_den + residuals[i] * residuals[i]
    end
    for i = 2, n do
        dw_num = dw_num + (residuals[i] - residuals[i-1]) * (residuals[i] - residuals[i-1])
    end
    local DW = dw_den > 0 and dw_num / dw_den or 0

    return {
        std_residuals = std_residuals,
        student_residuals = student_residuals,
        residual_mean = res_mean,
        residual_std = res_std,
        residual_skewness = res_skew,
        residual_kurtosis = res_kurt,
        durbin_watson = DW
    }
end

-- 方差分析表
function regression.anova(model)
    local df_reg = model.p_predictors and (model.p_predictors - 1) or 1
    local df_res = model.df
    local df_total = model.n - 1

    local MS_reg = model.SSR / df_reg
    local MS_res = model.SSE / df_res

    return {
        {
            source = "Regression",
            SS = model.SSR,
            df = df_reg,
            MS = MS_reg,
            F = model.F,
            p = model.p_F
        },
        {
            source = "Residual",
            SS = model.SSE,
            df = df_res,
            MS = MS_res,
            F = nil,
            p = nil
        },
        {
            source = "Total",
            SS = model.SST,
            df = df_total,
            MS = nil,
            F = nil,
            p = nil
        }
    }
end

-----------------------------------------------------------------------------
-- 其他回归方法
-----------------------------------------------------------------------------

-- 加权最小二乘法
function regression.wls(x, y, weights)
    if type(x) ~= "table" or type(y) ~= "table" or type(weights) ~= "table" then
        utils.Error.invalid_input("x, y, and weights must be tables")
    end
    if #x ~= #y or #x ~= #weights then
        utils.Error.dimension_mismatch("x, y, and weights must have the same length")
    end

    local n = #x
    local sum_w = 0
    local sum_wx = 0
    local sum_wy = 0
    local sum_wxx = 0
    local sum_wxy = 0

    for i = 1, n do
        local w = weights[i]
        sum_w = sum_w + w
        sum_wx = sum_wx + w * x[i]
        sum_wy = sum_wy + w * y[i]
        sum_wxx = sum_wxx + w * x[i] * x[i]
        sum_wxy = sum_wxy + w * x[i] * y[i]
    end

    local denom = sum_w * sum_wxx - sum_wx * sum_wx
    local slope = (sum_w * sum_wxy - sum_wx * sum_wy) / denom
    local intercept = (sum_wy * sum_wxx - sum_wx * sum_wxy) / denom

    -- 计算残差和统计量
    local y_pred = {}
    local residuals = {}
    local SSE = 0
    local mean_y = descriptive.mean(y)

    for i = 1, n do
        y_pred[i] = intercept + slope * x[i]
        residuals[i] = y[i] - y_pred[i]
        SSE = SSE + weights[i] * residuals[i] * residuals[i]
    end

    local SSR = 0
    for i = 1, n do
        SSR = SSR + weights[i] * (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
    end

    local SST = SSR + SSE
    local R2 = SSR / SST

    return {
        intercept = intercept,
        slope = slope,
        coefficients = {intercept, slope},
        R2 = R2,
        MSE = SSE / (n - 2),
        residuals = residuals,
        fitted = y_pred,
        n = n,
        weights = weights
    }
end

-- 岭回归（Ridge Regression）
-- @param X 设计矩阵（2D数组）
-- @param y 因变量
-- @param lambda 正则化参数
-- @param add_intercept 是否添加截距项
-- @return result 表
function regression.ridge(X, y, lambda, add_intercept)
    if type(X) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("X and y must be tables")
    end

    lambda = lambda or 1.0
    if add_intercept == nil then add_intercept = true end

    local design, n, p = build_design_matrix(X, add_intercept)

    -- 岭回归: beta = (X'X + lambda*I)^(-1) X'y
    local Xt = transpose(design)
    local XtX = matmul(Xt, design)

    -- 添加正则化项（不对截距惩罚）
    local start_idx = add_intercept and 2 or 1
    for i = start_idx, p do
        XtX[i][i] = XtX[i][i] + lambda
    end

    local XtX_inv = inverse(XtX)

    local y_col = {}
    for i = 1, n do
        y_col[i] = {y[i]}
    end

    local Xty = matmul(Xt, y_col)
    local beta_col = matmul(XtX_inv, Xty)

    local coefficients = {}
    for i = 1, p do
        coefficients[i] = beta_col[i][1]
    end

    -- 预测值
    local y_pred = {}
    local residuals = {}
    for i = 1, n do
        local pred = 0
        for j = 1, p do
            pred = pred + design[i][j] * coefficients[j]
        end
        y_pred[i] = pred
        residuals[i] = y[i] - pred
    end

    -- R²
    local mean_y = descriptive.mean(y)
    local SSR, SSE = 0, 0
    for i = 1, n do
        SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
        SSE = SSE + residuals[i] * residuals[i]
    end
    local SST = SSR + SSE
    local R2 = SSR / SST

    return {
        coefficients = coefficients,
        intercept = add_intercept and coefficients[1] or nil,
        lambda = lambda,
        R2 = R2,
        MSE = SSE / (n - p),
        residuals = residuals,
        fitted = y_pred,
        n = n,
        p_predictors = p
    }
end

-- 打印回归摘要
function regression.summary(model)
    print("=" .. string.rep("=", 50))
    print("Regression Summary")
    print("=" .. string.rep("=", 50))

    print(string.format("\nObservations: %d", model.n))
    print(string.format("Predictors: %d", model.p_predictors or 2))
    print(string.format("Degrees of Freedom: %d", model.df))

    print("\nCoefficients:")
    print(string.format("%-12s %10s %10s %10s %10s", "", "Estimate", "Std.Err", "t-value", "p-value"))
    print(string.rep("-", 55))

    local coef_names = {"Intercept", "X1", "X2", "X3", "X4", "X5"}
    for i = 1, #model.coefficients do
        local name = coef_names[i] or ("X" .. i)
        if model.se then
            print(string.format("%-12s %10.4f %10.4f %10.4f %10.4f",
                name, model.coefficients[i], model.se[i], model.t[i], model.p[i]))
        else
            print(string.format("%-12s %10.4f", name, model.coefficients[i]))
        end
    end

    print("\nModel Fit:")
    print(string.format("  R²:          %.4f", model.R2))
    print(string.format("  Adj. R²:     %.4f", model.R2_adj or model.R2))
    print(string.format("  RMSE:        %.4f", model.RMSE or math.sqrt(model.MSE)))

    if model.F then
        print(string.format("\nF-statistic: %.4f (p = %.4f)", model.F, model.p_F))
    end

    print("=" .. string.rep("=", 50))
end

return regression