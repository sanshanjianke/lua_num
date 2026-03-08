-- 统计学模块测试
package.path = "src/?.lua;" .. package.path
local statistics = require("statistics.init")

local function assert_approx(actual, expected, tol, msg)
    tol = tol or 1e-10
    if math.abs(actual - expected) > tol then
        error(string.format("%s: expected %.10f, got %.10f", msg or "Assertion failed", expected, actual))
    end
end

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local tests_passed = 0
local tests_failed = 0

local function test(name, func)
    local ok, err = pcall(func)
    if ok then
        tests_passed = tests_passed + 1
        print("  [PASS] " .. name)
    else
        tests_failed = tests_failed + 1
        print("  [FAIL] " .. name .. ": " .. tostring(err))
    end
end

print("Testing statistics module...")

-----------------------------------------------------------------------------
-- 集中趋势度量测试
-----------------------------------------------------------------------------
print("\n集中趋势度量:")

test("mean - basic", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.mean(x), 3, 1e-10, "mean")
end)

test("mean - with decimals", function()
    local x = {1.5, 2.5, 3.5}
    assert_approx(statistics.mean(x), 2.5, 1e-10, "mean")
end)

test("median - odd count", function()
    local x = {1, 3, 5, 7, 9}
    assert_approx(statistics.median(x), 5, 1e-10, "median")
end)

test("median - even count", function()
    local x = {1, 2, 3, 4}
    assert_approx(statistics.median(x), 2.5, 1e-10, "median")
end)

test("median - unsorted", function()
    local x = {5, 1, 3, 2, 4}
    assert_approx(statistics.median(x), 3, 1e-10, "median")
end)

test("mode - single mode", function()
    local x = {1, 2, 2, 3, 4}
    local m = statistics.mode(x)
    assert_eq(#m, 1, "mode count")
    assert_eq(m[1], 2, "mode value")
end)

test("mode - multiple modes", function()
    local x = {1, 1, 2, 2, 3}
    local m = statistics.mode(x)
    assert_eq(#m, 2, "mode count")
    assert_eq(m[1], 1, "mode value 1")
    assert_eq(m[2], 2, "mode value 2")
end)

test("mode - no mode", function()
    local x = {1, 2, 3, 4}
    local m = statistics.mode(x)
    assert_eq(#m, 0, "mode count")
end)

test("geomean - basic", function()
    local x = {2, 8}
    assert_approx(statistics.geomean(x), 4, 1e-10, "geomean")
end)

test("harmean - basic", function()
    local x = {1, 4}
    assert_approx(statistics.harmean(x), 1.6, 1e-10, "harmean")
end)

test("trimmean - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    -- 去掉两端各 10%（即各 1 个数），剩余 2-9 的均值
    assert_approx(statistics.trimmean(x, 0.1), 5.5, 1e-10, "trimmean")
end)

-----------------------------------------------------------------------------
-- 离散程度度量测试
-----------------------------------------------------------------------------
print("\n离散程度度量:")

test("var - sample variance", function()
    local x = {2, 4, 4, 4, 5, 5, 7, 9}
    -- 样本方差 = 4.571...
    assert_approx(statistics.var(x), 4.57142857142857, 1e-6, "var")
end)

test("std - sample std", function()
    local x = {2, 4, 4, 4, 5, 5, 7, 9}
    assert_approx(statistics.std(x), 2.1380899352994, 1e-6, "std")
end)

test("var_pop - population variance", function()
    local x = {2, 4, 4, 4, 5, 5, 7, 9}
    assert_approx(statistics.var_pop(x), 4, 1e-10, "var_pop")
end)

test("range - basic", function()
    local x = {4, 1, 7, 3, 9}
    assert_approx(statistics.range(x), 8, 1e-10, "range")
end)

test("iqr - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8}
    -- Q1 ≈ 2.75, Q3 ≈ 6.25, IQR = 3.5
    assert_approx(statistics.iqr(x), 3.5, 1e-10, "iqr")
end)

test("mad - mean absolute deviation", function()
    local x = {2, 4, 6, 8}
    -- mean = 5, deviations = |2-5|, |4-5|, |6-5|, |8-5| = 3, 1, 1, 3
    -- MAD = (3+1+1+3)/4 = 2
    assert_approx(statistics.mad(x), 2, 1e-10, "mad")
end)

test("sem - standard error of mean", function()
    local x = {1, 2, 3, 4, 5}
    -- std = sqrt(2.5), n = 5
    local expected = math.sqrt(2.5) / math.sqrt(5)
    assert_approx(statistics.sem(x), expected, 1e-10, "sem")
end)

-----------------------------------------------------------------------------
-- 分位数测试
-----------------------------------------------------------------------------
print("\n分位数:")

test("percentile - median", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.percentile(x, 50), 3, 1e-10, "percentile 50")
end)

test("percentile - q1", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.percentile(x, 25), 2, 1e-10, "percentile 25")
end)

test("percentile - q3", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.percentile(x, 75), 4, 1e-10, "percentile 75")
end)

test("quartile - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8}
    local q1, q3 = statistics.quartile(x)
    assert_approx(q1, 2.75, 0.01, "q1")
    assert_approx(q3, 6.25, 0.01, "q3")
end)

test("quantile - basic", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.quantile(x, 0.5), 3, 1e-10, "quantile 0.5")
end)

-----------------------------------------------------------------------------
-- 分布形状度量测试
-----------------------------------------------------------------------------
print("\n分布形状度量:")

test("skewness - symmetric", function()
    local x = {1, 2, 3, 4, 5}
    assert_approx(statistics.skewness(x), 0, 1e-6, "skewness symmetric")
end)

test("skewness - right skewed", function()
    local x = {1, 2, 2, 3, 10}
    assert(statistics.skewness(x) > 0, "right skew should be positive")
end)

test("skewness - left skewed", function()
    local x = {1, 8, 8, 9, 10}
    assert(statistics.skewness(x) < 0, "left skew should be negative")
end)

test("kurtosis - normal-like", function()
    local x = {-2, -1, 0, 1, 2}
    -- 小样本的超额峰度
    assert_approx(statistics.kurtosis(x), 2.625, 1e-6, "kurtosis")
end)

-----------------------------------------------------------------------------
-- 相关性分析测试
-----------------------------------------------------------------------------
print("\n相关性分析:")

test("cov - positive correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    assert(statistics.cov(x, y) > 0, "cov should be positive")
end)

test("cov - negative correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {10, 8, 6, 4, 2}
    assert(statistics.cov(x, y) < 0, "cov should be negative")
end)

test("corr - perfect positive", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    assert_approx(statistics.corr(x, y), 1, 1e-10, "corr perfect positive")
end)

test("corr - perfect negative", function()
    local x = {1, 2, 3, 4, 5}
    local y = {5, 4, 3, 2, 1}
    assert_approx(statistics.corr(x, y), -1, 1e-10, "corr perfect negative")
end)

test("corr - no correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {3, 3, 3, 3, 3}
    assert_approx(statistics.corr(x, y), 0, 1e-10, "corr no correlation")
end)

test("spearman - perfect correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {10, 20, 30, 40, 50}
    assert_approx(statistics.spearman(x, y), 1, 1e-10, "spearman perfect")
end)

test("spearman - with ties", function()
    local x = {1, 2, 2, 3, 4}
    local y = {1, 2, 2, 3, 4}
    assert_approx(statistics.spearman(x, y), 1, 1e-10, "spearman with ties")
end)

test("kendall - perfect correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {1, 2, 3, 4, 5}
    assert_approx(statistics.kendall(x, y), 1, 1e-10, "kendall perfect")
end)

test("kendall - inverse correlation", function()
    local x = {1, 2, 3, 4, 5}
    local y = {5, 4, 3, 2, 1}
    assert_approx(statistics.kendall(x, y), -1, 1e-10, "kendall inverse")
end)

-----------------------------------------------------------------------------
-- 频数统计测试
-----------------------------------------------------------------------------
print("\n频数统计:")

test("frequency - basic", function()
    local x = {1, 2, 2, 3, 3, 3}
    local freq = statistics.frequency(x)
    assert_eq(freq[1], 1, "freq 1")
    assert_eq(freq[2], 2, "freq 2")
    assert_eq(freq[3], 3, "freq 3")
end)

test("histogram - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local counts, edges = statistics.histogram(x, 5)
    assert_eq(#counts, 5, "histogram bins")
    local total = 0
    for i = 1, #counts do
        total = total + counts[i]
    end
    assert_eq(total, 10, "histogram total count")
end)

-----------------------------------------------------------------------------
-- 综合描述测试
-----------------------------------------------------------------------------
print("\n综合描述:")

test("describe - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local desc = statistics.describe(x)
    assert_eq(desc.n, 10, "n")
    assert_eq(desc.min, 1, "min")
    assert_eq(desc.max, 10, "max")
    assert_approx(desc.mean, 5.5, 1e-10, "mean")
end)

-----------------------------------------------------------------------------
-- 汇总
-----------------------------------------------------------------------------
print("\n" .. string.rep("=", 50))
print(string.format("Tests passed: %d", tests_passed))
print(string.format("Tests failed: %d", tests_failed))
print(string.rep("=", 50))

if tests_failed > 0 then
    os.exit(1)
end