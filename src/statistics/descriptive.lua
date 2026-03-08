-- 描述性统计函数
local descriptive = {}

local utils = require("utils.init")

-----------------------------------------------------------------------------
-- 辅助函数
-----------------------------------------------------------------------------

-- 检查输入是否为非空数组
local function validate_array(x, name)
    name = name or "data"
    if type(x) ~= "table" then
        utils.Error.invalid_input(name .. " must be a table")
    end
    if #x == 0 then
        utils.Error.invalid_input(name .. " must not be empty")
    end
end

-- 复制并排序数组
local function sorted_copy(x)
    local sorted = {}
    for i = 1, #x do
        sorted[i] = x[i]
    end
    table.sort(sorted)
    return sorted
end

-----------------------------------------------------------------------------
-- 集中趋势度量
-----------------------------------------------------------------------------

-- 算术平均值
function descriptive.mean(x)
    validate_array(x)
    local sum = 0
    for i = 1, #x do
        sum = sum + x[i]
    end
    return sum / #x
end

-- 中位数
function descriptive.median(x)
    validate_array(x)
    local sorted = sorted_copy(x)
    local n = #sorted
    local mid = math.floor(n / 2)

    if n % 2 == 1 then
        return sorted[mid + 1]
    else
        return (sorted[mid] + sorted[mid + 1]) / 2
    end
end

-- 众数（返回出现次数最多的值，可能有多个）
function descriptive.mode(x)
    validate_array(x)

    local counts = {}
    for i = 1, #x do
        local v = x[i]
        counts[v] = (counts[v] or 0) + 1
    end

    local max_count = 0
    local modes = {}
    for v, c in pairs(counts) do
        if c > max_count then
            max_count = c
            modes = {v}
        elseif c == max_count then
            modes[#modes + 1] = v
        end
    end

    -- 如果所有值出现次数相同，返回空（无众数）
    if max_count == 1 then
        return {}
    end

    table.sort(modes)
    return modes
end

-- 几何平均值
function descriptive.geomean(x)
    validate_array(x)

    local log_sum = 0
    for i = 1, #x do
        if x[i] <= 0 then
            utils.Error.invalid_input("geometric mean requires positive values")
        end
        log_sum = log_sum + math.log(x[i])
    end
    return math.exp(log_sum / #x)
end

-- 调和平均值
function descriptive.harmean(x)
    validate_array(x)

    local sum = 0
    for i = 1, #x do
        if x[i] == 0 then
            utils.Error.invalid_input("harmonic mean requires non-zero values")
        end
        sum = sum + 1 / x[i]
    end
    return #x / sum
end

-- 截尾均值（去除两端各 p 比例的数据后求均值）
function descriptive.trimmean(x, p)
    validate_array(x)
    p = p or 0.1
    if p < 0 or p >= 0.5 then
        utils.Error.invalid_input("p must be in [0, 0.5)")
    end

    local sorted = sorted_copy(x)
    local n = #sorted
    local k = math.floor(n * p)

    if k * 2 >= n then
        return descriptive.mean(sorted)
    end

    local sum = 0
    for i = k + 1, n - k do
        sum = sum + sorted[i]
    end
    return sum / (n - 2 * k)
end

-----------------------------------------------------------------------------
-- 离散程度度量
-----------------------------------------------------------------------------

-- 方差（样本方差，无偏估计，自由度 n-1）
function descriptive.var(x)
    validate_array(x)
    if #x < 2 then
        return 0
    end

    local m = descriptive.mean(x)
    local sum = 0
    for i = 1, #x do
        sum = sum + (x[i] - m) ^ 2
    end
    return sum / (#x - 1)
end

-- 标准差（样本标准差）
function descriptive.std(x)
    return math.sqrt(descriptive.var(x))
end

-- 总体方差（自由度 n）
function descriptive.var_pop(x)
    validate_array(x)

    local m = descriptive.mean(x)
    local sum = 0
    for i = 1, #x do
        sum = sum + (x[i] - m) ^ 2
    end
    return sum / #x
end

-- 总体标准差
function descriptive.std_pop(x)
    return math.sqrt(descriptive.var_pop(x))
end

-- 极差
function descriptive.range(x)
    validate_array(x)

    local min_val, max_val = x[1], x[1]
    for i = 2, #x do
        if x[i] < min_val then min_val = x[i] end
        if x[i] > max_val then max_val = x[i] end
    end
    return max_val - min_val
end

-- 四分位距 (IQR = Q3 - Q1)
function descriptive.iqr(x)
    local q1, q3 = descriptive.quartile(x)
    return q3 - q1
end

-- 平均绝对偏差 (MAD)
function descriptive.mad(x)
    validate_array(x)

    local m = descriptive.mean(x)
    local sum = 0
    for i = 1, #x do
        sum = sum + math.abs(x[i] - m)
    end
    return sum / #x
end

-- 标准误 (SEM)
function descriptive.sem(x)
    validate_array(x)
    if #x < 2 then
        return 0
    end
    return descriptive.std(x) / math.sqrt(#x)
end

-----------------------------------------------------------------------------
-- 分位数
-----------------------------------------------------------------------------

-- 百分位数 (p: 0-100)
function descriptive.percentile(x, p)
    validate_array(x)
    if p < 0 or p > 100 then
        utils.Error.invalid_input("percentile must be in [0, 100]")
    end

    local sorted = sorted_copy(x)
    local n = #sorted

    -- 使用线性插值方法
    local rank = (p / 100) * (n - 1) + 1
    local lower = math.floor(rank)
    local upper = math.ceil(rank)

    if lower == upper then
        return sorted[lower]
    end

    local frac = rank - lower
    return sorted[lower] + frac * (sorted[upper] - sorted[lower])
end

-- 四分位数，返回 Q1, Q3
function descriptive.quartile(x)
    local q1 = descriptive.percentile(x, 25)
    local q3 = descriptive.percentile(x, 75)
    return q1, q3
end

-- 分位数（通用版本，p 为 0-1 的比例）
function descriptive.quantile(x, p)
    return descriptive.percentile(x, p * 100)
end

-----------------------------------------------------------------------------
-- 分布形状度量
-----------------------------------------------------------------------------

-- n 阶中心矩
function descriptive.moment(x, n, center)
    validate_array(x)
    n = n or 2
    center = center or descriptive.mean(x)

    local sum = 0
    for i = 1, #x do
        sum = sum + (x[i] - center) ^ n
    end
    return sum / #x
end

-- 偏度（skewness）
-- 正偏：右尾较长；负偏：左尾较长
function descriptive.skewness(x)
    validate_array(x)
    if #x < 3 then
        return 0
    end

    local n = #x
    local m = descriptive.mean(x)
    local s = descriptive.std_pop(x)

    if s == 0 then return 0 end

    local sum3 = 0
    for i = 1, n do
        sum3 = sum3 + ((x[i] - m) / s) ^ 3
    end

    -- 样本偏度校正
    return sum3 * n / ((n - 1) * (n - 2))
end

-- 峰度（kurtosis）
-- 正态分布峰度为 0（超额峰度）
function descriptive.kurtosis(x)
    validate_array(x)
    if #x < 4 then
        return 0
    end

    local n = #x
    local m = descriptive.mean(x)
    local s = descriptive.std_pop(x)

    if s == 0 then return 0 end

    local sum4 = 0
    for i = 1, n do
        sum4 = sum4 + ((x[i] - m) / s) ^ 4
    end

    -- 样本超额峰度校正
    local g2 = (sum4 * n * (n + 1) / ((n - 1) * (n - 2) * (n - 3)))
             - (3 * (n - 1) ^ 2 / ((n - 2) * (n - 3)))
    return g2
end

-----------------------------------------------------------------------------
-- 频数统计
-----------------------------------------------------------------------------

-- 直方图
-- 返回各区间计数和区间边界
function descriptive.histogram(x, bins)
    validate_array(x)
    bins = bins or 10

    local min_val, max_val = x[1], x[1]
    for i = 2, #x do
        if x[i] < min_val then min_val = x[i] end
        if x[i] > max_val then max_val = x[i] end
    end

    -- 处理所有值相同的情况
    if min_val == max_val then
        local counts = {}
        for i = 1, bins do
            counts[i] = 0
        end
        counts[1] = #x
        local edges = {}
        for i = 0, bins do
            edges[i + 1] = min_val + (i / bins)
        end
        return counts, edges
    end

    local width = (max_val - min_val) / bins
    local counts = {}
    local edges = {}

    for i = 0, bins do
        edges[i + 1] = min_val + i * width
    end

    for i = 1, bins do
        counts[i] = 0
    end

    for i = 1, #x do
        local idx = math.floor((x[i] - min_val) / width) + 1
        if idx > bins then idx = bins end
        if idx < 1 then idx = 1 end
        counts[idx] = counts[idx] + 1
    end

    return counts, edges
end

-- 频数统计
function descriptive.frequency(x)
    validate_array(x)

    local freq = {}
    for i = 1, #x do
        local v = x[i]
        freq[v] = (freq[v] or 0) + 1
    end
    return freq
end

-----------------------------------------------------------------------------
-- 综合描述
-----------------------------------------------------------------------------

-- 生成描述性统计摘要
function descriptive.describe(x)
    validate_array(x)

    local sorted = sorted_copy(x)
    local q1, q3 = descriptive.quartile(x)

    return {
        n = #x,
        min = sorted[1],
        max = sorted[#sorted],
        range = descriptive.range(x),
        mean = descriptive.mean(x),
        std = descriptive.std(x),
        var = descriptive.var(x),
        median = descriptive.median(x),
        q1 = q1,
        q3 = q3,
        iqr = q3 - q1,
        skewness = descriptive.skewness(x),
        kurtosis = descriptive.kurtosis(x),
        sem = descriptive.sem(x)
    }
end

return descriptive