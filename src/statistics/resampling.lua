-- Bootstrap 和重抽样模块
local resampling = {}

local utils = require("utils.init")
local descriptive = require("statistics.descriptive")
local distributions = require("statistics.distributions")

-----------------------------------------------------------------------------
-- 辅助函数
-----------------------------------------------------------------------------

-- Fisher-Yates 洗牌算法
local function shuffle(t, rng)
    rng = rng or math.random
    local n = #t
    for i = n, 2, -1 do
        local j = math.floor(rng() * i) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- 从数组中有放回地抽样
local function sample_with_replacement(t, n, rng)
    rng = rng or math.random
    n = n or #t
    local result = {}
    for i = 1, n do
        local idx = math.floor(rng() * #t) + 1
        result[i] = t[idx]
    end
    return result
end

-- 从数组中无放回地抽样
local function sample_without_replacement(t, n, rng)
    rng = rng or math.random
    n = n or #t
    if n > #t then
        utils.Error.invalid_input("sample size cannot exceed population size")
    end

    -- 复制原数组
    local copy = {}
    for i = 1, #t do
        copy[i] = t[i]
    end

    -- Fisher-Yates 部分洗牌
    for i = 1, n do
        local j = math.floor(rng() * (#copy - i + 1)) + i
        copy[i], copy[j] = copy[j], copy[i]
    end

    local result = {}
    for i = 1, n do
        result[i] = copy[i]
    end
    return result
end

-- 计算统计量的辅助函数
local function compute_statistic(data, stat_func)
    if type(stat_func) == "string" then
        -- 内置统计量
        if stat_func == "mean" then
            return descriptive.mean(data)
        elseif stat_func == "median" then
            return descriptive.median(data)
        elseif stat_func == "sd" or stat_func == "std" then
            return descriptive.std(data)
        elseif stat_func == "var" then
            return descriptive.var(data)
        elseif stat_func == "trimmed_mean" then
            return descriptive.trimmean(data, 0.1)
        else
            utils.Error.invalid_input("unknown statistic: " .. stat_func)
        end
    elseif type(stat_func) == "function" then
        return stat_func(data)
    else
        utils.Error.invalid_input("stat_func must be a string or function")
    end
end

-- 计算百分位数
local function percentile(t, p)
    if #t == 0 then return nil end

    -- 排序
    local sorted = {}
    for i = 1, #t do
        sorted[i] = t[i]
    end
    table.sort(sorted)

    local n = #sorted
    local idx = (n - 1) * p + 1
    local lower = math.floor(idx)
    local upper = math.ceil(idx)
    local frac = idx - lower

    if lower == upper then
        return sorted[lower]
    else
        return sorted[lower] * (1 - frac) + sorted[upper] * frac
    end
end

-----------------------------------------------------------------------------
-- Bootstrap 方法
-----------------------------------------------------------------------------

-- 单样本 Bootstrap
-- @param data 原始数据
-- @param stat_func 统计量函数或名称（"mean", "median", "std", "var"）
-- @param n_bootstrap Bootstrap 样本数（默认 1000）
-- @param seed 随机种子（可选）
-- @return bootstrap_samples, se, bias, ci_lower, ci_upper
function resampling.bootstrap(data, stat_func, n_bootstrap, seed)
    if type(data) ~= "table" or #data < 2 then
        utils.Error.invalid_input("data must be a table with at least 2 elements")
    end

    n_bootstrap = n_bootstrap or 1000
    if seed then
        math.randomseed(seed)
    end

    local n = #data
    local original_stat = compute_statistic(data, stat_func)
    local bootstrap_stats = {}

    for b = 1, n_bootstrap do
        -- 有放回抽样
        local sample = sample_with_replacement(data, n)
        local stat = compute_statistic(sample, stat_func)
        bootstrap_stats[b] = stat
    end

    -- 计算 Bootstrap 标准误
    local mean_stat = descriptive.mean(bootstrap_stats)
    local se = descriptive.std(bootstrap_stats)

    -- 计算 Bootstrap 偏差
    local bias = mean_stat - original_stat

    return {
        original = original_stat,
        bootstrap_samples = bootstrap_stats,
        mean = mean_stat,
        se = se,
        bias = bias
    }
end

-- Bootstrap 置信区间
-- @param data 原始数据
-- @param stat_func 统计量函数或名称
-- @param n_bootstrap Bootstrap 样本数
-- @param level 置信水平（默认 0.95）
-- @param method 方法: "percentile", "basic", "bca", "normal"（默认 "percentile"）
-- @param seed 随机种子
-- @return lower, upper
function resampling.bootstrap_ci(data, stat_func, n_bootstrap, level, method, seed)
    if type(data) ~= "table" or #data < 2 then
        utils.Error.invalid_input("data must be a table with at least 2 elements")
    end

    n_bootstrap = n_bootstrap or 1000
    level = level or 0.95
    method = method or "percentile"

    if seed then
        math.randomseed(seed)
    end

    local result = resampling.bootstrap(data, stat_func, n_bootstrap, seed)
    local bootstrap_stats = result.bootstrap_samples
    local original_stat = result.original

    local alpha = 1 - level
    local lower_p = alpha / 2
    local upper_p = 1 - alpha / 2

    if method == "percentile" then
        -- 百分位数法
        local lower = percentile(bootstrap_stats, lower_p)
        local upper = percentile(bootstrap_stats, upper_p)
        return lower, upper

    elseif method == "basic" then
        -- 基本法（反转百分位数）
        local lower_pivot = percentile(bootstrap_stats, upper_p)
        local upper_pivot = percentile(bootstrap_stats, lower_p)
        local lower = 2 * original_stat - upper_pivot
        local upper = 2 * original_stat - lower_pivot
        -- 确保 lower < upper
        if lower > upper then
            lower, upper = upper, lower
        end
        return lower, upper

    elseif method == "normal" then
        -- 正态近似法
        local z = distributions.normal.quantile(1 - alpha / 2)
        local lower = original_stat - z * result.se
        local upper = original_stat + z * result.se
        return lower, upper

    elseif method == "bca" then
        -- BCa (Bias-Corrected and Accelerated) 方法
        -- 计算偏差校正因子 z0
        local count = 0
        for i = 1, #bootstrap_stats do
            if bootstrap_stats[i] < original_stat then
                count = count + 1
            end
        end
        local p0 = count / #bootstrap_stats
        if p0 == 0 then p0 = 0.001 end
        if p0 == 1 then p0 = 0.999 end
        local z0 = distributions.normal.quantile(p0)

        -- 加速度因子 a（使用 Jackknife 近似）
        local jackknife_stats = {}
        local n = #data
        for i = 1, n do
            local leave_one_out = {}
            for j = 1, n do
                if j ~= i then
                    table.insert(leave_one_out, data[j])
                end
            end
            jackknife_stats[i] = compute_statistic(leave_one_out, stat_func)
        end
        local jack_mean = descriptive.mean(jackknife_stats)
        local num, den = 0, 0
        for i = 1, n do
            local diff = jack_mean - jackknife_stats[i]
            num = num + diff ^ 3
            den = den + diff ^ 2
        end
        local a = num / (6 * den ^ 1.5)
        if den == 0 then a = 0 end

        -- 调整后的分位点
        local z_alpha_lower = distributions.normal.quantile(lower_p)
        local z_alpha_upper = distributions.normal.quantile(upper_p)

        local function adjust(z_alpha)
            local numer = z0 + z_alpha
            local denom = 1 - a * numer
            if denom == 0 then denom = 0.001 end
            return distributions.normal.cdf(z0 + numer / denom)
        end

        local adjusted_lower_p = adjust(z_alpha_lower)
        local adjusted_upper_p = adjust(z_alpha_upper)

        -- 确保分位点在有效范围内
        adjusted_lower_p = math.max(0.001, math.min(0.999, adjusted_lower_p))
        adjusted_upper_p = math.max(0.001, math.min(0.999, adjusted_upper_p))

        local lower = percentile(bootstrap_stats, adjusted_lower_p)
        local upper = percentile(bootstrap_stats, adjusted_upper_p)
        return lower, upper

    else
        utils.Error.invalid_input("unknown method: " .. method)
    end
end

-- 双样本 Bootstrap（比较两组）
-- @param x 第一组数据
-- @param y 第二组数据
-- @param stat_func 统计量函数（接受两个参数）
-- @param n_bootstrap Bootstrap 样本数
-- @param level 置信水平
-- @param method 置信区间方法
-- @param seed 随机种子
-- @return lower, upper, bootstrap_stats
function resampling.bootstrap_two_sample(x, y, stat_func, n_bootstrap, level, method, seed)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("each sample must have at least 2 elements")
    end

    n_bootstrap = n_bootstrap or 1000
    level = level or 0.95
    method = method or "percentile"

    if seed then
        math.randomseed(seed)
    end

    local original_stat = stat_func(x, y)
    local bootstrap_stats = {}

    for b = 1, n_bootstrap do
        local sample_x = sample_with_replacement(x, #x)
        local sample_y = sample_with_replacement(y, #y)
        bootstrap_stats[b] = stat_func(sample_x, sample_y)
    end

    local alpha = 1 - level

    if method == "percentile" then
        local lower = percentile(bootstrap_stats, alpha / 2)
        local upper = percentile(bootstrap_stats, 1 - alpha / 2)
        return lower, upper, bootstrap_stats
    elseif method == "basic" then
        local lower = 2 * original_stat - percentile(bootstrap_stats, 1 - alpha / 2)
        local upper = 2 * original_stat - percentile(bootstrap_stats, alpha / 2)
        return lower, upper, bootstrap_stats
    else
        utils.Error.invalid_input("unknown method: " .. method)
    end
end

-----------------------------------------------------------------------------
-- Jackknife 方法
-----------------------------------------------------------------------------

-- Jackknife 重抽样
-- @param data 原始数据
-- @param stat_func 统计量函数或名称
-- @return jackknife_samples, mean, se, bias
function resampling.jackknife(data, stat_func)
    if type(data) ~= "table" or #data < 2 then
        utils.Error.invalid_input("data must be a table with at least 2 elements")
    end

    local n = #data
    local original_stat = compute_statistic(data, stat_func)
    local jackknife_stats = {}

    for i = 1, n do
        -- 留一抽样
        local leave_one_out = {}
        for j = 1, n do
            if j ~= i then
                table.insert(leave_one_out, data[j])
            end
        end
        jackknife_stats[i] = compute_statistic(leave_one_out, stat_func)
    end

    -- Jackknife 估计
    local jack_mean = descriptive.mean(jackknife_stats)

    -- Jackknife 标准误
    local sum_sq = 0
    for i = 1, n do
        sum_sq = sum_sq + (jackknife_stats[i] - jack_mean) ^ 2
    end
    local se = math.sqrt((n - 1) / n * sum_sq)

    -- Jackknife 偏差
    local bias = (n - 1) * (jack_mean - original_stat)

    return {
        original = original_stat,
        jackknife_samples = jackknife_stats,
        mean = jack_mean,
        se = se,
        bias = bias,
        bias_corrected = original_stat - bias
    }
end

-- Jackknife 置信区间
-- @param data 原始数据
-- @param stat_func 统计量函数或名称
-- @param level 置信水平
-- @return lower, upper
function resampling.jackknife_ci(data, stat_func, level)
    level = level or 0.95

    local result = resampling.jackknife(data, stat_func)
    local alpha = 1 - level
    local z = distributions.normal.quantile(1 - alpha / 2)

    -- 使用偏差校正后的估计值
    local corrected = result.bias_corrected or result.original
    local lower = corrected - z * result.se
    local upper = corrected + z * result.se

    return lower, upper
end

-----------------------------------------------------------------------------
-- 置换检验
-----------------------------------------------------------------------------

-- 两独立样本置换检验
-- @param x 第一组数据
-- @param y 第二组数据
-- @param stat_func 检验统计量函数（默认为均值差）
-- @param n_permutations 置换次数（默认 1000）
-- @param alternative 备择假设: "two.sided", "less", "greater"
-- @param seed 随机种子
-- @return observed_stat, p_value, permutation_stats
function resampling.permutation_test(x, y, stat_func, n_permutations, alternative, seed)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 1 or #y < 1 then
        utils.Error.invalid_input("each sample must have at least 1 element")
    end

    n_permutations = n_permutations or 1000
    alternative = alternative or "two.sided"

    if seed then
        math.randomseed(seed)
    end

    -- 默认统计量：均值差
    stat_func = stat_func or function(a, b)
        return descriptive.mean(a) - descriptive.mean(b)
    end

    local n1, n2 = #x, #y
    local observed_stat = stat_func(x, y)

    -- 合并数据
    local combined = {}
    for i = 1, n1 do
        combined[i] = x[i]
    end
    for i = 1, n2 do
        combined[n1 + i] = y[i]
    end

    local permutation_stats = {}
    local extreme_count = 0

    for p = 1, n_permutations do
        -- 随机重排
        local permuted = {}
        for i = 1, #combined do
            permuted[i] = combined[i]
        end
        shuffle(permuted)

        -- 分成两组
        local perm_x = {}
        local perm_y = {}
        for i = 1, n1 do
            perm_x[i] = permuted[i]
        end
        for i = 1, n2 do
            perm_y[i] = permuted[n1 + i]
        end

        local perm_stat = stat_func(perm_x, perm_y)
        permutation_stats[p] = perm_stat

        -- 计算极端值数量
        if alternative == "two.sided" then
            if math.abs(perm_stat) >= math.abs(observed_stat) then
                extreme_count = extreme_count + 1
            end
        elseif alternative == "greater" then
            if perm_stat >= observed_stat then
                extreme_count = extreme_count + 1
            end
        else  -- less
            if perm_stat <= observed_stat then
                extreme_count = extreme_count + 1
            end
        end
    end

    -- p 值（加 1 法以避免 p = 0）
    local p_value = (extreme_count + 1) / (n_permutations + 1)

    return observed_stat, p_value, permutation_stats
end

-- 配对样本置换检验
-- @param x 第一组数据
-- @param y 第二组数据
-- @param n_permutations 置换次数
-- @param alternative 备择假设
-- @param seed 随机种子
-- @return observed_stat, p_value
function resampling.permutation_test_paired(x, y, n_permutations, alternative, seed)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x ~= #y then
        utils.Error.dimension_mismatch(#x, #y, "paired samples must have equal length")
    end
    if #x < 1 then
        utils.Error.invalid_input("samples must have at least 1 element")
    end

    n_permutations = n_permutations or 1000
    alternative = alternative or "two.sided"

    if seed then
        math.randomseed(seed)
    end

    local n = #x

    -- 计算差值
    local diff = {}
    for i = 1, n do
        diff[i] = x[i] - y[i]
    end

    -- 观测统计量：差值均值
    local observed_stat = descriptive.mean(diff)

    local extreme_count = 0

    for p = 1, n_permutations do
        -- 对每个差值随机分配符号
        local perm_diff = {}
        for i = 1, n do
            if math.random() < 0.5 then
                perm_diff[i] = -diff[i]
            else
                perm_diff[i] = diff[i]
            end
        end

        local perm_stat = descriptive.mean(perm_diff)

        if alternative == "two.sided" then
            if math.abs(perm_stat) >= math.abs(observed_stat) then
                extreme_count = extreme_count + 1
            end
        elseif alternative == "greater" then
            if perm_stat >= observed_stat then
                extreme_count = extreme_count + 1
            end
        else  -- less
            if perm_stat <= observed_stat then
                extreme_count = extreme_count + 1
            end
        end
    end

    local p_value = (extreme_count + 1) / (n_permutations + 1)

    return observed_stat, p_value
end

-----------------------------------------------------------------------------
-- 自助法假设检验
-----------------------------------------------------------------------------

-- Bootstrap t 检验
-- @param x 样本数据
-- @param mu 假设的总体均值
-- @param n_bootstrap Bootstrap 样本数
-- @param alternative 备择假设
-- @param seed 随机种子
-- @return t_stat, p_value
function resampling.bootstrap_t_test(x, mu, n_bootstrap, alternative, seed)
    if type(x) ~= "table" or #x < 2 then
        utils.Error.invalid_input("x must be a table with at least 2 elements")
    end

    mu = mu or 0
    n_bootstrap = n_bootstrap or 1000
    alternative = alternative or "two.sided"

    if seed then
        math.randomseed(seed)
    end

    local n = #x
    local sample_mean = descriptive.mean(x)
    local sample_std = descriptive.std(x)
    local observed_t = (sample_mean - mu) / (sample_std / math.sqrt(n))

    -- Bootstrap 检验：在原假设下生成数据
    local extreme_count = 0

    for b = 1, n_bootstrap do
        -- 从样本中 Bootstrap
        local sample = sample_with_replacement(x, n)
        local boot_mean = descriptive.mean(sample)
        local boot_std = descriptive.std(sample)

        -- 构建在原假设下的 t 统计量
        local boot_t = (boot_mean - mu) / (boot_std / math.sqrt(n))

        if alternative == "two.sided" then
            if math.abs(boot_t) >= math.abs(observed_t) then
                extreme_count = extreme_count + 1
            end
        elseif alternative == "greater" then
            if boot_t >= observed_t then
                extreme_count = extreme_count + 1
            end
        else  -- less
            if boot_t <= observed_t then
                extreme_count = extreme_count + 1
            end
        end
    end

    local p_value = (extreme_count + 1) / (n_bootstrap + 1)

    return observed_t, p_value
end

-- Bootstrap 方差检验
-- @param x 第一组数据
-- @param y 第二组数据
-- @param n_bootstrap Bootstrap 样本数
-- @param seed 随机种子
-- @return f_stat, p_value
function resampling.bootstrap_var_test(x, y, n_bootstrap, seed)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("each sample must have at least 2 elements")
    end

    n_bootstrap = n_bootstrap or 1000

    if seed then
        math.randomseed(seed)
    end

    local v1 = descriptive.var(x)
    local v2 = descriptive.var(y)
    local observed_f = v1 / v2

    -- 合并数据
    local combined = {}
    for i = 1, #x do
        combined[i] = x[i]
    end
    for i = 1, #y do
        combined[#x + i] = y[i]
    end

    local n1, n2 = #x, #y
    local extreme_count = 0

    for b = 1, n_bootstrap do
        local sample1 = sample_with_replacement(combined, n1)
        local sample2 = sample_with_replacement(combined, n2)

        local boot_v1 = descriptive.var(sample1)
        local boot_v2 = descriptive.var(sample2)
        local boot_f = boot_v1 / boot_v2

        if boot_f >= observed_f then
            extreme_count = extreme_count + 1
        end
    end

    -- 双侧 p 值
    local p_value = 2 * math.min(extreme_count, n_bootstrap - extreme_count) / n_bootstrap

    return observed_f, p_value
end

-----------------------------------------------------------------------------
-- 其他重抽样方法
-----------------------------------------------------------------------------

-- 交叉验证（K-fold）
-- @param data 数据（x, y 或只有 y）
-- @param k 折数（默认 10）
-- @param model_func 模型训练函数（返回预测函数）
-- @param loss_func 损失函数（默认为平方误差）
-- @param seed 随机种子
-- @return mean_error, std_error, fold_errors
function resampling.cross_validation(data, k, model_func, loss_func, seed)
    if type(data) ~= "table" then
        utils.Error.invalid_input("data must be a table")
    end

    k = k or 10
    loss_func = loss_func or function(y_true, y_pred)
        return (y_true - y_pred) ^ 2
    end

    if seed then
        math.randomseed(seed)
    end

    local n
    local x, y

    -- 判断数据格式
    if type(data.x) == "table" and type(data.y) == "table" then
        x = data.x
        y = data.y
        n = #y
    elseif type(data.y) == "table" then
        -- 只有 y 的情况：data = {y = {...}}
        y = data.y
        n = #y
    elseif type(data) == "table" then
        -- data 直接是数组
        y = data
        n = #data
        if n == 0 then
            utils.Error.invalid_input("data must be a non-empty table")
        end
    else
        utils.Error.invalid_input("data must be a table with values or {y=...} format")
    end

    if k > n then
        k = n  -- 如果 k > n，使用 n 折（留一法）
    end

    -- 随机排列索引
    local indices = {}
    for i = 1, n do
        indices[i] = i
    end
    shuffle(indices)

    local fold_size = math.floor(n / k)
    local fold_errors = {}

    for fold = 1, k do
        -- 划分训练集和验证集
        local test_start = (fold - 1) * fold_size + 1
        local test_end = (fold == k) and n or (fold * fold_size)

        local train_idx = {}
        local test_idx = {}
        for i = 1, n do
            if i >= test_start and i <= test_end then
                table.insert(test_idx, indices[i])
            else
                table.insert(train_idx, indices[i])
            end
        end

        -- 训练模型
        local predict = model_func(train_idx, test_idx)

        -- 计算测试误差
        local total_error = 0
        for i = 1, #test_idx do
            local idx = test_idx[i]
            local y_true = y[idx]
            local y_pred
            if x then
                y_pred = predict(x[idx])
            else
                y_pred = predict(idx)
            end
            total_error = total_error + loss_func(y_true, y_pred)
        end
        fold_errors[fold] = total_error / #test_idx
    end

    local mean_error = descriptive.mean(fold_errors)
    local std_error = descriptive.std(fold_errors)

    return mean_error, std_error, fold_errors
end

-- 蒙特卡洛模拟
-- @param n_simulations 模拟次数
-- @param sim_func 模拟函数（返回一个值）
-- @param seed 随机种子
-- @return mean, se, results
function resampling.monte_carlo(n_simulations, sim_func, seed)
    if type(n_simulations) ~= "number" or n_simulations < 1 then
        utils.Error.invalid_input("n_simulations must be a positive integer")
    end
    if type(sim_func) ~= "function" then
        utils.Error.invalid_input("sim_func must be a function")
    end

    if seed then
        math.randomseed(seed)
    end

    local results = {}
    for i = 1, n_simulations do
        results[i] = sim_func()
    end

    local mean = descriptive.mean(results)
    local se = descriptive.std(results)

    return mean, se, results
end

return resampling