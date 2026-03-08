-- 假设检验模块测试
package.path = "src/?.lua;" .. package.path
local statistics = require("statistics.init")

local function assert_approx(actual, expected, tol, msg)
    tol = tol or 1e-6
    if math.abs(actual - expected) > tol then
        error(string.format("%s: expected %.10f, got %.10f", msg or "Assertion failed", expected, actual))
    end
end

local function assert_true(condition, msg)
    if not condition then
        error(msg or "Assertion failed: expected true")
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

print("Testing hypothesis testing module...")

-----------------------------------------------------------------------------
-- t 检验测试
-----------------------------------------------------------------------------
print("\nt检验:")

test("t_test_one_sample - basic", function()
    local x = {102, 104, 101, 103, 100, 105, 102, 104, 101, 103}
    local t, p, df = statistics.t_test_one_sample(x, 100)
    -- 均值约为 102.5，应该显著大于 100
    assert_true(t > 0, "t should be positive")
    assert_true(p < 0.05, "p should be significant")
    assert_approx(df, 9, 1e-10, "df should be 9")
end)

test("t_test_one_sample - not significant", function()
    local x = {100, 101, 99, 100, 101, 99, 100, 101, 99, 100}
    local t, p, df = statistics.t_test_one_sample(x, 100)
    -- 均值约为 100，不应该显著
    assert_true(p > 0.05, "p should not be significant")
end)

test("t_test_one_sample - alternative less", function()
    local x = {98, 99, 97, 98, 99, 97, 98, 99}
    local t, p, df = statistics.t_test_one_sample(x, 100, "less")
    assert_true(t < 0, "t should be negative")
    assert_true(p < 0.05, "p should be significant")
end)

test("t_test_one_sample - alternative greater", function()
    local x = {102, 103, 101, 102, 103, 101, 102, 103}
    local t, p, df = statistics.t_test_one_sample(x, 100, "greater")
    assert_true(t > 0, "t should be positive")
    assert_true(p < 0.05, "p should be significant")
end)

test("t_test_two_sample - equal means", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 3, 4, 5, 6}
    local t, p, df = statistics.t_test_two_sample(x, y)
    -- 均值差为 1，可能不显著（小样本）
    assert_true(p > 0.01, "p should be > 0.01 for similar means")
end)

test("t_test_two_sample - different means", function()
    local x = {10, 11, 12, 13, 14, 15, 16, 17, 18, 19}
    local y = {20, 21, 22, 23, 24, 25, 26, 27, 28, 29}
    local t, p, df = statistics.t_test_two_sample(x, y)
    assert_true(p < 0.001, "p should be very significant")
end)

test("t_test_two_sample - paired", function()
    local before = {85, 78, 82, 88, 76}
    local after = {90, 82, 86, 92, 80}
    local t, p, df = statistics.t_test_two_sample(before, after, 0, "two.sided", true)
    -- 配对检验应该检测到显著改进
    assert_true(p < 0.05, "paired test should detect improvement")
end)

test("welch_test - unequal variance", function()
    local x = {1, 2, 3, 4, 5}
    local y = {10, 20, 30, 40, 50}
    local t, p, df = statistics.welch_test(x, y)
    assert_true(p < 0.05, "p should be significant")
end)

-----------------------------------------------------------------------------
-- Z 检验测试
-----------------------------------------------------------------------------
print("\nZ检验:")

test("z_test_one_sample - basic", function()
    -- 已知总体标准差为 2
    local x = {102, 104, 101, 103, 100, 105, 102, 104, 101, 103}
    local z, p = statistics.z_test_one_sample(x, 100, 2)
    assert_true(z > 0, "z should be positive")
    assert_true(p < 0.05, "p should be significant")
end)

test("z_test_one_sample - large sample", function()
    -- 大样本，均值接近 100
    local x = {}
    for i = 1, 100 do
        x[i] = 100 + (math.random() - 0.5) * 2
    end
    local z, p = statistics.z_test_one_sample(x, 100, 1)
    -- 随机数据，p 值应该变化较大
    assert_true(z > -5 and z < 5, "z should be reasonable")
end)

-----------------------------------------------------------------------------
-- F 检验（方差齐性）测试
-----------------------------------------------------------------------------
print("\nF检验:")

test("var_test - equal variance", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local y = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11}
    local f, p, df1, df2 = statistics.var_test(x, y)
    -- 方差相似，p 值应该较大
    assert_true(p > 0.05, "p should not be significant for equal variance")
end)

test("var_test - unequal variance", function()
    local x = {1, 2, 3, 4, 5}
    local y = {1, 10, 2, 20, 3, 30, 4, 40}
    local f, p, df1, df2 = statistics.var_test(x, y)
    -- 方差不同，p 值应该较小
    assert_true(p < 0.05, "p should be significant for unequal variance")
end)

-----------------------------------------------------------------------------
-- 卡方检验测试
-----------------------------------------------------------------------------
print("\n卡方检验:")

test("chisq_test_goodness - uniform distribution", function()
    -- 掷骰子 60 次，每个面应该出现约 10 次
    local observed = {10, 11, 9, 10, 11, 9}
    local chi2, p, df = statistics.chisq_test_goodness(observed)
    -- 接近均匀分布，p 值应该较大
    assert_true(p > 0.5, "p should be large for uniform distribution")
end)

test("chisq_test_goodness - biased distribution", function()
    -- 明显不均匀的分布
    local observed = {30, 5, 5, 5, 5, 10}
    local chi2, p, df = statistics.chisq_test_goodness(observed)
    -- 不均匀，p 值应该较小
    assert_true(p < 0.05, "p should be small for biased distribution")
end)

test("chisq_test_goodness - with expected", function()
    local observed = {20, 30}
    local expected = {25, 25}
    local chi2, p, df = statistics.chisq_test_goodness(observed, expected)
    -- chi2 = 2.0，p 值依赖于 chi2.cdf 的实现精度
    assert_approx(chi2, 2.0, 0.1, "chi2 should be about 2")
    assert_approx(df, 1, 1e-10, "df should be 1")
end)

test("chisq_test_independence - independent", function()
    -- 独立的列联表
    local observed = {
        {10, 10, 10},
        {10, 10, 10},
        {10, 10, 10}
    }
    local chi2, p, df = statistics.chisq_test_independence(observed)
    -- 独立，p 值应该较大
    assert_true(p > 0.5, "p should be large for independence")
end)

test("chisq_test_independence - dependent", function()
    -- 有依赖关系的列联表
    local observed = {
        {50, 10, 5},
        {10, 50, 10},
        {5, 10, 50}
    }
    local chi2, p, df = statistics.chisq_test_independence(observed)
    -- 有依赖，p 值应该较小
    assert_true(p < 0.001, "p should be small for dependence")
end)

-----------------------------------------------------------------------------
-- 非参数检验测试
-----------------------------------------------------------------------------
print("\n非参数检验:")

test("wilcoxon_signed_rank - positive shift", function()
    local x = {105, 110, 115, 108, 112, 118, 103, 109}
    local w, p = statistics.wilcoxon_signed_rank(x, 100)
    -- 大部分值大于 100，应该显著
    assert_true(p < 0.05, "p should be significant")
end)

test("wilcoxon_signed_rank - no shift", function()
    local x = {98, 102, 99, 101, 100, 103, 97, 104}
    local w, p = statistics.wilcoxon_signed_rank(x, 100)
    -- 接近 100，应该不显著
    assert_true(p > 0.05, "p should not be significant")
end)

test("mann_whitney_u - different distributions", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8}
    local y = {10, 11, 12, 13, 14, 15, 16, 17}
    local u, p = statistics.mann_whitney_u(x, y)
    -- 明显不同的分布
    assert_true(p < 0.05, "p should be significant")
end)

test("mann_whitney_u - similar distributions", function()
    local x = {1, 2, 3, 4, 5, 6}
    local y = {2, 3, 4, 5, 6, 7}
    local u, p = statistics.mann_whitney_u(x, y)
    -- 相似的分布
    assert_true(p > 0.05, "p should not be significant")
end)

-----------------------------------------------------------------------------
-- 置信区间测试
-----------------------------------------------------------------------------
print("\n置信区间:")

test("ci_mean - basic", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local lower, upper = statistics.ci_mean(x, 0.95)
    local mean = statistics.mean(x)
    -- 均值应该在置信区间内
    assert_true(lower < mean and mean < upper, "mean should be in CI")
    assert_true(lower < upper, "lower should be less than upper")
end)

test("ci_mean - different levels", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local lower95, upper95 = statistics.ci_mean(x, 0.95)
    local lower99, upper99 = statistics.ci_mean(x, 0.99)
    -- 99% CI 应该比 95% CI 更宽
    assert_true(upper99 - lower99 > upper95 - lower95, "99% CI should be wider")
end)

test("ci_mean_diff - basic", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 3, 4, 5, 6}
    local lower, upper = statistics.ci_mean_diff(x, y, 0.95)
    -- 差值约为 -1
    assert_true(lower < -1 and -1 < upper, "diff should be in CI")
end)

test("ci_proportion - basic", function()
    local lower, upper = statistics.ci_proportion(50, 100, 0.95)
    -- 比例为 0.5
    assert_true(lower < 0.5 and 0.5 < upper, "0.5 should be in CI")
end)

test("ci_proportion - extreme", function()
    local lower, upper = statistics.ci_proportion(0, 100, 0.95)
    assert_true(lower >= 0 and upper <= 1, "CI should be in [0, 1]")
    assert_true(upper > 0, "upper should be positive")
end)

-----------------------------------------------------------------------------
-- 效应量测试
-----------------------------------------------------------------------------
print("\n效应量:")

test("cohens_d_one_sample - small", function()
    local x = {100, 101, 99, 100, 101, 99, 100, 101}
    local d = statistics.cohens_d_one_sample(x, 100)
    -- 均值接近 100，效应量应该很小
    assert_true(math.abs(d) < 0.5, "d should be small")
end)

test("cohens_d_one_sample - large", function()
    local x = {110, 112, 108, 115, 120, 118, 105, 112}
    local d = statistics.cohens_d_one_sample(x, 100)
    -- 均值远大于 100，效应量应该大
    assert_true(d > 1.5, "d should be large")
end)

test("cohens_d_two_sample - equal means", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 3, 4, 5, 6}
    local d = statistics.cohens_d_two_sample(x, y)
    -- 均值差为 1，效应量应该适中
    assert_true(math.abs(d) < 2, "d should be moderate")
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