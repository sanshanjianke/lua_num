-- 回归分析模块测试
package.path = "src/?.lua;" .. package.path
local statistics = require("statistics.init")

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

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

print("Testing regression module...")

-----------------------------------------------------------------------------
-- 简单线性回归测试
-----------------------------------------------------------------------------
print("\n简单线性回归:")

test("linear regression - perfect fit", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}  -- y = 2x
    local model = statistics.linear_regression(x, y)
    assert_approx(model.slope, 2, 1e-6, "slope should be 2")
    assert_approx(model.intercept, 0, 1e-6, "intercept should be 0")
    assert_approx(model.R2, 1, 1e-6, "R² should be 1 for perfect fit")
end)

test("linear regression - with intercept", function()
    local x = {1, 2, 3, 4, 5}
    local y = {3, 5, 7, 9, 11}  -- y = 2x + 1
    local model = statistics.linear_regression(x, y)
    assert_approx(model.slope, 2, 1e-6, "slope should be 2")
    assert_approx(model.intercept, 1, 1e-6, "intercept should be 1")
    assert_approx(model.R2, 1, 1e-6, "R² should be 1")
end)

test("linear regression - noisy data", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local y = {2.1, 4.2, 5.8, 8.1, 10.2, 11.9, 14.1, 16.0, 18.2, 19.9}
    local model = statistics.linear_regression(x, y)
    -- 斜率应该接近 2，截距接近 0
    assert_approx(model.slope, 2, 0.1, "slope should be about 2")
    assert_approx(model.intercept, 0, 0.2, "intercept should be about 0")
    assert_true(model.R2 > 0.99, "R² should be high")
end)

test("linear regression - residuals", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.linear_regression(x, y)
    -- 残差应该接近 0
    for i = 1, #model.residuals do
        assert_approx(model.residuals[i], 0, 1e-6, "residual should be 0")
    end
end)

test("linear regression - F test", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.linear_regression(x, y)
    -- 完全拟合时 F 值应该很大
    assert_true(model.F > 1000, "F should be large for perfect fit")
end)

-----------------------------------------------------------------------------
-- 多元线性回归测试
-----------------------------------------------------------------------------
print("\n多元线性回归:")

test("multiple regression - two predictors", function()
    -- y = 1 + 2*x1 + 3*x2
    local X = {{1, 0}, {2, 1}, {3, 1}, {4, 2}}
    local y = {3, 8, 10, 15}
    local model = statistics.multiple_regression(X, y)
    -- 系数应该接近 [1, 2, 3]
    assert_approx(model.coefficients[1], 1, 0.5, "intercept")
    assert_approx(model.coefficients[2], 2, 0.5, "coef for x1")
    assert_approx(model.coefficients[3], 3, 0.5, "coef for x2")
end)

test("multiple regression - R²", function()
    -- 完美线性关系，使用岭回归避免奇异矩阵
    local X = {{1, 2}, {2, 3}, {3, 4}, {4, 5}}
    local y = {3, 5, 7, 9}  -- y ≈ x1 + x2
    local model = statistics.ridge(X, y, 0.001)
    assert_true(model.R2 > 0.99, "R² should be close to 1")
end)

test("multiple regression - no intercept", function()
    local X = {{1}, {2}, {3}, {4}, {5}}
    local y = {2, 4, 6, 8, 10}  -- y = 2*x
    local model = statistics.ridge(X, y, 0.001, false)
    assert_approx(model.coefficients[1], 2, 0.1, "coef should be 2")
end)

-----------------------------------------------------------------------------
-- 多项式回归测试
-----------------------------------------------------------------------------
print("\n多项式回归:")

test("polynomial regression - quadratic", function()
    -- y = 1 + 2x + 3x²
    local x = {0, 1, 2, 3}
    local y = {1, 6, 17, 34}
    local model = statistics.polynomial_regression(x, y, 2)
    assert_approx(model.coefficients[1], 1, 0.1, "constant term")
    assert_approx(model.coefficients[2], 2, 0.1, "linear term")
    assert_approx(model.coefficients[3], 3, 0.1, "quadratic term")
    assert_approx(model.R2, 1, 1e-6, "R² should be 1")
end)

test("polynomial regression - cubic", function()
    -- y = x³ (需要足够的数据点)
    local x = {1, 2, 3, 4, 5}
    local y = {1, 8, 27, 64, 125}
    local model = statistics.polynomial_regression(x, y, 3)
    assert_approx(model.coefficients[4], 1, 0.1, "cubic coefficient")
    assert_true(model.R2 > 0.99, "R² should be close to 1")
end)

-----------------------------------------------------------------------------
-- 预测测试
-----------------------------------------------------------------------------
print("\n预测:")

test("predict - linear", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.linear_regression(x, y)
    local pred = statistics.regression.predict(model, {6, 7, 8})
    assert_approx(pred[1], 12, 1e-6, "predict x=6")
    assert_approx(pred[2], 14, 1e-6, "predict x=7")
    assert_approx(pred[3], 16, 1e-6, "predict x=8")
end)

test("predict - polynomial", function()
    local x = {1, 2, 3, 4, 5}
    local y = {1, 8, 27, 64, 125}  -- y = x³
    local model = statistics.polynomial_regression(x, y, 3)
    local pred = statistics.regression.predict(model, {6})
    assert_approx(pred[1], 216, 1, "predict x=6")
end)

test("predict_interval", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local y = {2.1, 4.2, 5.8, 8.1, 10.2, 11.9, 14.1, 16.0, 18.2, 19.9}
    local model = statistics.linear_regression(x, y)
    local lower, upper = statistics.regression.predict_interval(model, 6, 0.95)
    -- 检查区间是否合理
    assert_true(lower < upper, "lower should be less than upper")
    -- 预测值约为 12，区间应该包含合理的范围
    assert_true(lower > 10 and upper < 14, "interval should be reasonable")
end)

-----------------------------------------------------------------------------
-- 加权最小二乘测试
-----------------------------------------------------------------------------
print("\n加权最小二乘:")

test("WLS - basic", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local weights = {1, 1, 1, 1, 1}  -- 等权重
    local model = statistics.wls(x, y, weights)
    assert_approx(model.slope, 2, 1e-6, "slope")
    assert_approx(model.intercept, 0, 1e-6, "intercept")
end)

test("WLS - weighted", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2.5, 3.8, 6.2, 7.9, 10.3}  -- 带噪声
    local weights = {0.5, 1, 2, 1, 0.5}  -- 中间权重更大
    local model = statistics.wls(x, y, weights)
    -- 应该仍然接近 y = 2x
    assert_approx(model.slope, 2, 0.2, "slope")
end)

-----------------------------------------------------------------------------
-- 岭回归测试
-----------------------------------------------------------------------------
print("\n岭回归:")

test("ridge - basic", function()
    local X = {{1}, {2}, {3}, {4}, {5}}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.ridge(X, y, 0.1)
    -- 岭回归系数应该接近普通最小二乘
    assert_approx(model.coefficients[2], 2, 0.1, "slope")
end)

test("ridge - regularization effect", function()
    local X = {{1}, {2}, {3}}
    local y = {2, 4, 6}
    local model1 = statistics.ridge(X, y, 0.01)  -- 小 lambda
    local model2 = statistics.ridge(X, y, 10)    -- 大 lambda
    -- 大 lambda 应该使系数更小
    assert_true(math.abs(model2.coefficients[2]) < math.abs(model1.coefficients[2]),
        "larger lambda should shrink coefficients")
end)

-----------------------------------------------------------------------------
-- 诊断测试
-----------------------------------------------------------------------------
print("\n模型诊断:")

test("diagnostics - Durbin-Watson", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.linear_regression(x, y)
    local diag = statistics.regression.diagnostics(model, y)
    -- 完全拟合时残差接近0，DW可能是NaN或0
    assert_true(diag.durbin_watson ~= nil, "DW should exist")
end)

test("diagnostics - residual statistics", function()
    local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    local y = {2.1, 4.2, 5.8, 8.1, 10.2, 11.9, 14.1, 16.0, 18.2, 19.9}
    local model = statistics.linear_regression(x, y)
    local diag = statistics.regression.diagnostics(model, y)
    -- 残差均值应该接近 0
    assert_approx(diag.residual_mean, 0, 0.1, "residual mean")
end)

test("anova table", function()
    local x = {1, 2, 3, 4, 5}
    local y = {2, 4, 6, 8, 10}
    local model = statistics.linear_regression(x, y)
    local anova = statistics.regression.anova(model)
    assert_eq(#anova, 3, "anova should have 3 rows")
    assert_approx(anova[1].SS + anova[2].SS, anova[3].SS, 1e-6, "SS should add up")
end)

-----------------------------------------------------------------------------
-- 边界情况测试
-----------------------------------------------------------------------------
print("\n边界情况:")

test("minimal data", function()
    local x = {1, 2, 3}
    local y = {1, 2, 3}
    local model = statistics.linear_regression(x, y)
    assert_approx(model.slope, 1, 1e-6, "slope")
    assert_approx(model.intercept, 0, 1e-6, "intercept")
end)

test("single predictor multiple regression", function()
    local X = {{1}, {2}, {3}, {4}}
    local y = {2, 4, 6, 8}
    local model = statistics.multiple_regression(X, y)
    assert_approx(model.coefficients[2], 2, 0.1, "slope")
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