-- 假设检验模块
local hypothesis = {}

local utils = require("utils.init")
local descriptive = require("statistics.descriptive")
local distributions = require("statistics.distributions")

-----------------------------------------------------------------------------
-- 辅助函数
-----------------------------------------------------------------------------


-- 计算合并标准误差
local function pooled_std(x, y)
    local n1, n2 = #x, #y
    local v1 = descriptive.var(x)
    local v2 = descriptive.var(y)

    -- 合并方差
    local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
    return math.sqrt(pooled_var)
end

-----------------------------------------------------------------------------


-- 单样本 t 检验
-- 检验样本均值是否与假设值有显著差异
-- @param x 样本数据
-- @param mu 假设的总体均值
-- @param alternative 备择假设类型: "two.sided", "less", "greater"
-- @return t_statistic, p_value, df
function hypothesis.t_test_one_sample(x, mu, alternative)
    if type(x) ~= "table" or #x < 2 then
        utils.Error.invalid_input("x must be a table with at least 2 elements")
    end

    mu = mu or 0
    alternative = alternative or "two.sided"

    local n = #x
    local sample_mean = descriptive.mean(x)
    local sample_std = descriptive.std(x)

    -- t 统计量
    local se = sample_std / math.sqrt(n)
    local t_stat = (sample_mean - mu) / se

    -- 自由度
    local df = n - 1

    -- 计算 p 值
    local p_value
    if alternative == "two.sided" then
        p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
    elseif alternative == "less" then
        p_value = distributions.t.cdf(t_stat, df)
    elseif alternative == "greater" then
        p_value = 1 - distributions.t.cdf(t_stat, df)
    else
        utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
    end

    return t_stat, p_value, df
end

-- 双样本 t 检验（等方差）
-- @param x 第一个样本
-- @param y 第二个样本
-- @param mu 差值的假设值（默认为0）
-- @param alternative 备择假设类型
-- @param paired 是否为配对样本
-- @return t_statistic, p_value, df
function hypothesis.t_test_two_sample(x, y, mu, alternative, paired)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("samples must have at least 2 elements")
    end

    mu = mu or 0
    alternative = alternative or "two.sided"
    paired = paired or false

    local t_stat, df, p_value

    if paired then
        -- 配对样本 t 检验
        if #x ~= #y then
            utils.Error.dimension_mismatch(#x, #y, "paired samples must have equal length")
        end

        local n = #x
        local diff = {}
        for i = 1, n do
            diff[i] = x[i] - y[i]
        end

        return hypothesis.t_test_one_sample(diff, mu, alternative)
    else
        -- 独立样本 t 检验
        local n1, n2 = #x, #y
        local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
        local v1, v2 = descriptive.var(x), descriptive.var(y)

        -- 使用合并方差（假设等方差）
        local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
        local se = math.sqrt(pooled_var * (1/n1 + 1/n2))

        t_stat = ((mean1 - mean2) - mu) / se
        df = n1 + n2 - 2

        -- 计算 p 值
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
        elseif alternative == "less" then
            p_value = distributions.t.cdf(t_stat, df)
        elseif alternative == "greater" then
            p_value = 1 - distributions.t.cdf(t_stat, df)
        else
            utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
        end
    end

    return t_stat, p_value, df
end

-- Welch's t 检验（异方差）
-- @param x 第一个样本
-- @param y 第二个样本
-- @param mu 差值的假设值
-- @param alternative 备择假设类型
-- @return t_statistic, p_value, df
function hypothesis.welch_test(x, y, mu, alternative)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("samples must have at least 2 elements")
    end

    mu = mu or 0
    alternative = alternative or "two.sided"

    local n1, n2 = #x, #y
    local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
    local v1, v2 = descriptive.var(x), descriptive.var(y)

    -- Welch's t 统计量
    local se = math.sqrt(v1/n1 + v2/n2)
    local t_stat = ((mean1 - mean2) - mu) / se

    -- Welch-Satterthwaite 自由度
    local num = (v1/n1 + v2/n2)^2
    local den = (v1/n1)^2 / (n1 - 1) + (v2/n2)^2 / (n2 - 1)
    local df = num / den

    -- 计算 p 值
    local p_value
    if alternative == "two.sided" then
        p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
    elseif alternative == "less" then
        p_value = distributions.t.cdf(t_stat, df)
    elseif alternative == "greater" then
        p_value = 1 - distributions.t.cdf(t_stat, df)
    else
        utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
    end

    return t_stat, p_value, df
end

-----------------------------------------------------------------------------


-- 单样本 Z 检验（需要已知总体标准差）
-- @param x 样本数据
-- @param mu 假设的总体均值
-- @param sigma 已知的总体标准差
-- @param alternative 备择假设类型
-- @return z_statistic, p_value
function hypothesis.z_test_one_sample(x, mu, sigma, alternative)
    if type(x) ~= "table" or #x < 1 then
        utils.Error.invalid_input("x must be a non-empty table")
    end
    if not sigma or sigma <= 0 then
        utils.Error.invalid_input("sigma must be a positive number")
    end

    mu = mu or 0
    alternative = alternative or "two.sided"

    local n = #x
    local sample_mean = descriptive.mean(x)

    -- Z 统计量
    local se = sigma / math.sqrt(n)
    local z_stat = (sample_mean - mu) / se

    -- 计算 p 值（使用标准正态分布）
    local p_value
    if alternative == "two.sided" then
        p_value = 2 * (1 - distributions.normal.cdf(math.abs(z_stat)))
    elseif alternative == "less" then
        p_value = distributions.normal.cdf(z_stat)
    elseif alternative == "greater" then
        p_value = 1 - distributions.normal.cdf(z_stat)
    else
        utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
    end

    return z_stat, p_value
end

-----------------------------------------------------------------------------


-- F 检验（方差齐性检验）
-- 检验两个总体方差是否相等
-- @param x 第一个样本
-- @param y 第二个样本
-- @param alternative 备择假设类型
-- @return f_statistic, p_value, df1, df2
function hypothesis.var_test(x, y, alternative)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("samples must have at least 2 elements")
    end

    alternative = alternative or "two.sided"

    local n1, n2 = #x, #y
    local v1, v2 = descriptive.var(x), descriptive.var(y)

    -- F 统计量（较大的方差作为分子）
    local f_stat, df1, df2
    if alternative == "two.sided" then
        -- 双侧检验：总是把较大的方差放在分子
        if v1 >= v2 then
            f_stat = v1 / v2
            df1, df2 = n1 - 1, n2 - 1
        else
            f_stat = v2 / v1
            df1, df2 = n2 - 1, n1 - 1
        end
    else
        f_stat = v1 / v2
        df1, df2 = n1 - 1, n2 - 1
    end

    -- 计算 p 值
    local p_value
    if alternative == "two.sided" then
        p_value = 2 * (1 - distributions.f.cdf(f_stat, df1, df2))
        if p_value > 1 then p_value = 2 - p_value end  -- 确保不超过1
    elseif alternative == "less" then
        p_value = distributions.f.cdf(f_stat, df1, df2)
    elseif alternative == "greater" then
        p_value = 1 - distributions.f.cdf(f_stat, df1, df2)
    else
        utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
    end

    return f_stat, p_value, df1, df2
end

-----------------------------------------------------------------------------


-- 卡方拟合优度检验
-- 检验观测频数是否符合期望频数
-- @param observed 观测频数数组
-- @param expected 期望频数数组（可选，默认为等概率）
-- @param p 期望概率数组（可选）
-- @return chi2_statistic, p_value, df
function hypothesis.chisq_test_goodness(observed, expected, p)
    if type(observed) ~= "table" or #observed < 2 then
        utils.Error.invalid_input("observed must be a table with at least 2 elements")
    end

    local n = #observed
    local total = 0
    for i = 1, n do
        if observed[i] < 0 then
            utils.Error.invalid_input("observed frequencies must be non-negative")
        end
        total = total + observed[i]
    end

    if total == 0 then
        utils.Error.invalid_input("sum of observed frequencies must be positive")
    end

    -- 计算期望频数
    if not expected then
        if p then
            -- 使用给定的概率
            expected = {}
            for i = 1, n do
                expected[i] = total * p[i]
            end
        else
            -- 默认等概率
            expected = {}
            for i = 1, n do
                expected[i] = total / n
            end
        end
    end

    -- 计算卡方统计量
    local chi2_stat = 0
    for i = 1, n do
        if expected[i] > 0 then
            local diff = observed[i] - expected[i]
            chi2_stat = chi2_stat + (diff * diff) / expected[i]
        end
    end

    -- 自由度
    local df = n - 1
    if p then
        df = n - 1  -- 如果概率已知
    end

    -- 计算 p 值
    local p_value = 1 - distributions.chi2.cdf(chi2_stat, df)

    return chi2_stat, p_value, df
end

-- 卡方独立性检验（列联表）
-- @param observed 观测频数矩阵（二维数组）
-- @return chi2_statistic, p_value, df
function hypothesis.chisq_test_independence(observed)
    if type(observed) ~= "table" or #observed < 2 then
        utils.Error.invalid_input("observed must be a 2D table with at least 2 rows")
    end

    local rows = #observed
    local cols = #observed[1]

    if cols < 2 then
        utils.Error.invalid_input("observed must have at least 2 columns")
    end

    -- 计算行和、列和、总和
    local row_sums = {}
    local col_sums = {}
    local total = 0

    for i = 1, rows do
        row_sums[i] = 0
        for j = 1, cols do
            if observed[i][j] < 0 then
                utils.Error.invalid_input("observed frequencies must be non-negative")
            end
            row_sums[i] = row_sums[i] + observed[i][j]
            total = total + observed[i][j]
        end
    end

    for j = 1, cols do
        col_sums[j] = 0
        for i = 1, rows do
            col_sums[j] = col_sums[j] + observed[i][j]
        end
    end

    if total == 0 then
        utils.Error.invalid_input("sum of observed frequencies must be positive")
    end

    -- 计算期望频数和卡方统计量
    local chi2_stat = 0
    for i = 1, rows do
        for j = 1, cols do
            local expected = row_sums[i] * col_sums[j] / total
            if expected > 0 then
                local diff = observed[i][j] - expected
                chi2_stat = chi2_stat + (diff * diff) / expected
            end
        end
    end

    -- 自由度 = (r-1)(c-1)
    local df = (rows - 1) * (cols - 1)

    -- 计算 p 值
    local p_value = 1 - distributions.chi2.cdf(chi2_stat, df)

    return chi2_stat, p_value, df
end

-----------------------------------------------------------------------------


-- Wilcoxon 符号秩检验（单样本/配对样本）
-- @param x 样本数据（单样本）或差值（配对样本）
-- @param mu 假设的中位数/差值
-- @param alternative 备择假设类型
-- @return w_statistic, p_value
function hypothesis.wilcoxon_signed_rank(x, mu, alternative)
    if type(x) ~= "table" or #x < 2 then
        utils.Error.invalid_input("x must be a table with at least 2 elements")
    end

    mu = mu or 0
    alternative = alternative or "two.sided"

    local n = #x

    -- 计算差值
    local diff = {}
    for i = 1, n do
        diff[i] = x[i] - mu
    end

    -- 去除零值
    local non_zero = {}
    for i = 1, n do
        if diff[i] ~= 0 then
            table.insert(non_zero, {value = diff[i], abs_val = math.abs(diff[i])})
        end
    end

    local n1 = #non_zero
    if n1 == 0 then
        return 0, 1  -- 所有点都等于 mu
    end

    -- 按绝对值排序
    table.sort(non_zero, function(a, b) return a.abs_val < b.abs_val end)

    -- 分配秩
    local ranks = {}
    local i = 1
    while i <= n1 do
        local j = i
        while j < n1 and non_zero[j + 1].abs_val == non_zero[i].abs_val do
            j = j + 1
        end

        local avg_rank = (i + j) / 2
        for k = i, j do
            ranks[k] = avg_rank
        end
        i = j + 1
    end

    -- 计算正秩和与负秩和
    local w_plus = 0
    local w_minus = 0
    for k = 1, n1 do
        if non_zero[k].value > 0 then
            w_plus = w_plus + ranks[k]
        else
            w_minus = w_minus + ranks[k]
        end
    end

    -- W 统计量（取较小的）
    local w_stat
    if alternative == "two.sided" then
        w_stat = math.min(w_plus, w_minus)
    elseif alternative == "less" then
        w_stat = w_plus
    else
        w_stat = w_minus
    end

    -- 正态近似计算 p 值（n > 20 时更准确）
    local mean_w = n1 * (n1 + 1) / 4
    local var_w = n1 * (n1 + 1) * (2 * n1 + 1) / 24
    local se = math.sqrt(var_w)

    -- 连续性修正
    local z
    if alternative == "two.sided" then
        z = (w_stat + 0.5 - mean_w) / se
        if z < 0 then z = -z end
        -- 使用较小的 W，所以 p 值需要调整
        z = math.abs(w_plus - w_minus) / (2 * se)
    else
        z = (w_stat - mean_w) / se
    end

    local p_value
    if alternative == "two.sided" then
        p_value = 2 * (1 - distributions.normal.cdf(math.abs(z)))
    elseif alternative == "less" then
        p_value = distributions.normal.cdf(z)
    else
        p_value = 1 - distributions.normal.cdf(z)
    end

    return w_stat, p_value
end

-----------------------------------------------------------------------------


-- Mann-Whitney U 检验（Wilcoxon 秩和检验）
-- @param x 第一个样本
-- @param y 第二个样本
-- @param alternative 备择假设类型
-- @return u_statistic, p_value
function hypothesis.mann_whitney_u(x, y, alternative)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 1 or #y < 1 then
        utils.Error.invalid_input("samples must have at least 1 element")
    end

    alternative = alternative or "two.sided"

    local n1, n2 = #x, #y

    -- 合并并排序
    local combined = {}
    for i = 1, n1 do
        table.insert(combined, {value = x[i], group = 1})
    end
    for i = 1, n2 do
        table.insert(combined, {value = y[i], group = 2})
    end

    table.sort(combined, function(a, b) return a.value < b.value end)

    -- 分配秩（处理结值）
    local n = n1 + n2
    local i = 1
    while i <= n do
        local j = i
        while j < n and combined[j + 1].value == combined[i].value do
            j = j + 1
        end

        local avg_rank = (i + j) / 2
        for k = i, j do
            combined[k].rank = avg_rank
        end
        i = j + 1
    end

    -- 计算秩和
    local r1, r2 = 0, 0
    for k = 1, n do
        if combined[k].group == 1 then
            r1 = r1 + combined[k].rank
        else
            r2 = r2 + combined[k].rank
        end
    end

    -- 计算 U 统计量
    local u1 = r1 - n1 * (n1 + 1) / 2
    local u2 = r2 - n2 * (n2 + 1) / 2

    local u_stat
    if alternative == "two.sided" then
        u_stat = math.min(u1, u2)
    elseif alternative == "less" then
        u_stat = u1
    else
        u_stat = u2
    end

    -- 正态近似
    local mean_u = n1 * n2 / 2
    local var_u = n1 * n2 * (n1 + n2 + 1) / 12
    local se = math.sqrt(var_u)

    local z
    if alternative == "two.sided" then
        z = (u_stat + 0.5 - mean_u) / se
        if z > 0 then z = -z end
    else
        z = (u_stat - mean_u) / se
    end

    local p_value
    if alternative == "two.sided" then
        p_value = 2 * distributions.normal.cdf(z)
    elseif alternative == "less" then
        p_value = distributions.normal.cdf(z)
    else
        p_value = 1 - distributions.normal.cdf(z)
    end

    return u_stat, p_value
end

-----------------------------------------------------------------------------


-- 置信区间计算
-- 单样本均值的置信区间
function hypothesis.ci_mean(x, level)
    if type(x) ~= "table" or #x < 2 then
        utils.Error.invalid_input("x must be a table with at least 2 elements")
    end

    level = level or 0.95

    local n = #x
    local mean = descriptive.mean(x)
    local se = descriptive.std(x) / math.sqrt(n)
    local df = n - 1

    local alpha = 1 - level
    local t_crit = distributions.t.quantile(1 - alpha/2, df)

    local margin = t_crit * se
    return mean - margin, mean + margin
end

-- 两样本均值差的置信区间
function hypothesis.ci_mean_diff(x, y, level, pooled)
    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input("x and y must be tables")
    end
    if #x < 2 or #y < 2 then
        utils.Error.invalid_input("samples must have at least 2 elements")
    end

    level = level or 0.95
    pooled = pooled or true

    local n1, n2 = #x, #y
    local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
    local v1, v2 = descriptive.var(x), descriptive.var(y)

    local diff = mean1 - mean2
    local se, df

    if pooled then
        local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
        se = math.sqrt(pooled_var * (1/n1 + 1/n2))
        df = n1 + n2 - 2
    else
        -- Welch's
        se = math.sqrt(v1/n1 + v2/n2)
        local num = (v1/n1 + v2/n2)^2
        local den = (v1/n1)^2 / (n1 - 1) + (v2/n2)^2 / (n2 - 1)
        df = num / den
    end

    local alpha = 1 - level
    local t_crit = distributions.t.quantile(1 - alpha/2, df)

    local margin = t_crit * se
    return diff - margin, diff + margin
end

-- 比例的置信区间
function hypothesis.ci_proportion(count, n, level)
    if count < 0 or n <= 0 or count > n then
        utils.Error.invalid_input("invalid count and n values")
    end

    level = level or 0.95

    local p = count / n
    local alpha = 1 - level
    local z_crit = distributions.normal.quantile(1 - alpha/2)

    -- Wilson score interval
    local denominator = 1 + z_crit^2 / n
    local center = (p + z_crit^2 / (2*n)) / denominator
    local margin = z_crit * math.sqrt(p*(1-p)/n + z_crit^2/(4*n*n)) / denominator

    return math.max(0, center - margin), math.min(1, center + margin)
end

-----------------------------------------------------------------------------


-- 效应量计算

-- Cohen's d（单样本）
function hypothesis.cohens_d_one_sample(x, mu)
    mu = mu or 0
    local mean = descriptive.mean(x)
    local sd = descriptive.std(x)
    return (mean - mu) / sd
end

-- Cohen's d（双样本）
function hypothesis.cohens_d_two_sample(x, y, pooled)
    pooled = pooled or true

    local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
    local diff = mean1 - mean2

    if pooled then
        local n1, n2 = #x, #y
        local v1, v2 = descriptive.var(x), descriptive.var(y)
        local pooled_sd = math.sqrt(((n1-1)*v1 + (n2-1)*v2) / (n1+n2-2))
        return diff / pooled_sd
    else
        -- 使用对照组标准差
        return diff / descriptive.std(y)
    end
end

-- 点二列相关（作为效应量）
function hypothesis.point_biserial(x, y)
    -- x 是二分变量（0/1），y 是连续变量
    local n = #x
    local n1, n2 = 0, 0
    local sum1, sum2 = 0, 0

    for i = 1, n do
        if x[i] == 0 then
            n1 = n1 + 1
            sum1 = sum1 + y[i]
        else
            n2 = n2 + 1
            sum2 = sum2 + y[i]
        end
    end

    local mean1 = sum1 / n1
    local mean2 = sum2 / n2
    local mean_y = descriptive.mean(y)
    local sd_y = descriptive.std(y)

    return (mean2 - mean1) / sd_y * math.sqrt(n1 * n2 / n^2)
end

return hypothesis