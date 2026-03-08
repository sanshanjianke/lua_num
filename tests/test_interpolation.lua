-- 插值模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local interpolation = require("interpolation.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-6
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

local function assert_array_equal(actual, expected, msg, tol)
    tol = tol or 1e-6
    if #actual ~= #expected then
        error(string.format("%s: array length mismatch (actual: %d, expected: %d)",
            msg or "", #actual, #expected))
    end
    for i = 1, #actual do
        local diff = math.abs(actual[i] - expected[i])
        if diff > tol then
            error(string.format("%s: at index %d expected %.6f, got %.6f (diff=%.2e)",
                msg or "", i, expected[i], actual[i], diff))
        end
    end
end

print("=== 测试插值模块 ===\n")

-- 测试数据：正弦函数
local x_data = {0, math.pi/6, math.pi/3, math.pi/2, 2*math.pi/3, 5*math.pi/6, math.pi}
local y_data = {}
for i, x in ipairs(x_data) do
    y_data[i] = math.sin(x)
end

-- 测试 1: 线性插值
print("测试 1: 线性插值")
local x_test = math.pi / 4  -- π/4 ≈ 0.785
local y_linear = interpolation.linear(x_test, x_data, y_data)
local y_expected = math.sin(x_test)
print(string.format("x = %.4f, linear: %.6f, expected: %.6f, error: %.2e",
    x_test, y_linear, y_expected, math.abs(y_linear - y_expected)))
assert_equal(y_linear, y_expected, "linear interpolation", 0.1)  -- 线性插值误差较大
print("✓ 通过\n")

-- 测试 2: 线性插值 - 数组输入
print("测试 2: 线性插值 - 数组输入")
local x_array = {0.1, 0.2, 0.3}
local y_array_linear = interpolation.linear(x_array, x_data, y_data)
print(string.format("Input: [%.1f, %.1f, %.1f]", x_array[1], x_array[2], x_array[3]))
for i, x in ipairs(x_array) do
    print(string.format("  x=%.1f, y=%.6f", x, y_array_linear[i]))
end
print("✓ 通过\n")

-- 测试 3: 拉格朗日插值
print("测试 3: 拉格朗日插值")
local y_lagrange = interpolation.lagrange(x_test, x_data, y_data)
print(string.format("x = %.4f, lagrange: %.6f, expected: %.6f, error: %.2e",
    x_test, y_lagrange, y_expected, math.abs(y_lagrange - y_expected)))
assert_equal(y_lagrange, y_expected, "lagrange interpolation", 1e-5)
print("✓ 通过\n")

-- 测试 4: 拉格朗日插值 - 数组输入
print("测试 4: 拉格朗日插值 - 数组输入")
local y_array_lagrange = interpolation.lagrange(x_array, x_data, y_data)
print(string.format("Input: [%.1f, %.1f, %.1f]", x_array[1], x_array[2], x_array[3]))
for i, x in ipairs(x_array) do
    print(string.format("  x=%.1f, y=%.6f", x, y_array_lagrange[i]))
end
print("✓ 通过\n")

-- 测试 5: 牛顿插值
print("测试 5: 牛顿插值")
local y_newton = interpolation.newton(x_test, x_data, y_data)
print(string.format("x = %.4f, newton: %.6f, expected: %.6f, error: %.2e",
    x_test, y_newton, y_expected, math.abs(y_newton - y_expected)))
assert_equal(y_newton, y_expected, "newton interpolation", 1e-5)
print("✓ 通过\n")

-- 测试 6: 牛顿插值 - 数组输入
print("测试 6: 牛顿插值 - 数组输入")
local y_array_newton = interpolation.newton(x_array, x_data, y_data)
print(string.format("Input: [%.1f, %.1f, %.1f]", x_array[1], x_array[2], x_array[3]))
for i, x in ipairs(x_array) do
    print(string.format("  x=%.1f, y=%.6f", x, y_array_newton[i]))
end
print("✓ 通过\n")

-- 测试 7: 三次样条插值（自然边界条件）
print("测试 7: 三次样条插值（自然边界条件）")
local y_spline = interpolation.spline(x_test, x_data, y_data)
print(string.format("x = %.4f, spline: %.6f, expected: %.6f, error: %.2e",
    x_test, y_spline, y_expected, math.abs(y_spline - y_expected)))
assert_equal(y_spline, y_expected, "spline interpolation", 1e-3)
print("✓ 通过\n")

-- 测试 8: 三次样条插值 - 数组输入
print("测试 8: 三次样条插值 - 数组输入")
local y_array_spline = interpolation.spline(x_array, x_data, y_data)
print(string.format("Input: [%.1f, %.1f, %.1f]", x_array[1], x_array[2], x_array[3]))
for i, x in ipairs(x_array) do
    print(string.format("  x=%.1f, y=%.6f", x, y_array_spline[i]))
end
print("✓ 通过\n")

-- 测试 9: 三次样条插值 - 固定边界条件
print("测试 9: 三次样条插值 - 固定边界条件")
local dy0 = math.cos(0)        -- sin'(0) = cos(0) = 1
local dyn = math.cos(math.pi)  -- sin'(π) = cos(π) = -1
local y_spline_clamped = interpolation.spline_clamped(x_test, x_data, y_data, dy0, dyn)
print(string.format("x = %.4f, spline_clamped: %.6f, expected: %.6f, error: %.2e",
    x_test, y_spline_clamped, y_expected, math.abs(y_spline_clamped - y_expected)))
assert_equal(y_spline_clamped, y_expected, "spline clamped", 1e-3)
print("✓ 通过\n")

-- 测试 10: 样条导数计算
print("测试 10: 样条导数计算")
local dy = interpolation.spline_derivative(x_test, x_data, y_data, "natural")
local dy_expected = math.cos(x_test)  -- sin'(x) = cos(x)
print(string.format("x = %.4f, spline': %.6f, expected: %.6f, error: %.2e",
    x_test, dy, dy_expected, math.abs(dy - dy_expected)))
assert_equal(dy, dy_expected, "spline derivative", 1e-3)
print("✓ 通过\n")

-- 测试 11: 样条二阶导数计算
print("测试 11: 样条二阶导数计算")
local ddy = interpolation.spline_derivative2(x_test, x_data, y_data, "natural")
local ddy_expected = -math.sin(x_test)  -- sin''(x) = -sin(x)
print(string.format("x = %.4f, spline'': %.6f, expected: %.6f, error: %.2e",
    x_test, ddy, ddy_expected, math.abs(ddy - ddy_expected)))
assert_equal(ddy, ddy_expected, "spline 2nd derivative", 1e-2)
print("✓ 通过\n")

-- 测试 12: 统一接口 - 各种方法
print("测试 12: 统一接口")
local methods = {"linear", "lagrange", "newton", "spline"}
for _, method in ipairs(methods) do
    local result = interpolation.interpolate(x_test, x_data, y_data, {method = method})
    print(string.format("%s: %.6f", method, result))
    assert_equal(result, y_expected, string.format("interpolate.%s", method), 0.1)
end
print("✓ 通过\n")

-- 测试 13: 多项式函数测试（验证拉格朗日和牛顿插值精度）
print("测试 13: 多项式函数测试")
-- 测试二次多项式 y = x^2
local poly_x = {0, 1, 2, 3, 4}
local poly_y = {0, 1, 4, 9, 16}
local poly_x_test = 2.5
local poly_y_expected = poly_x_test^2  -- 6.25

local poly_lagrange = interpolation.lagrange(poly_x_test, poly_x, poly_y)
local poly_newton = interpolation.newton(poly_x_test, poly_x, poly_y)

print(string.format("x = %.1f, y = x^2", poly_x_test))
print(string.format("  lagrange: %.6f, expected: %.6f, error: %.2e",
    poly_lagrange, poly_y_expected, math.abs(poly_lagrange - poly_y_expected)))
print(string.format("  newton: %.6f, expected: %.6f, error: %.2e",
    poly_newton, poly_y_expected, math.abs(poly_newton - poly_y_expected)))

-- 对于二次多项式，拉格朗日和牛顿插值应该精确
assert_equal(poly_lagrange, poly_y_expected, "lagrange polynomial", 1e-10)
assert_equal(poly_newton, poly_y_expected, "newton polynomial", 1e-10)
print("✓ 通过\n")

-- 测试 14: 端点测试
print("测试 14: 端点测试")
local y_start_linear = interpolation.linear(x_data[1], x_data, y_data)
local y_end_linear = interpolation.linear(x_data[#x_data], x_data, y_data)
print(string.format("Start: linear=%.6f, expected=%.6f", y_start_linear, y_data[1]))
print(string.format("End: linear=%.6f, expected=%.6f", y_end_linear, y_data[#y_data]))
assert_equal(y_start_linear, y_data[1], "linear start point")
assert_equal(y_end_linear, y_data[#y_data], "linear end point")
print("✓ 通过\n")

-- 测试 15: 等距节点测试
print("测试 15: 等距节点测试")
local equidistant_x = {0, 1, 2, 3, 4}
local equidistant_y = {1, 2, 3, 2, 1}
local equidistant_test = 2.5
local eq_linear = interpolation.linear(equidistant_test, equidistant_x, equidistant_y)
local eq_lagrange = interpolation.lagrange(equidistant_test, equidistant_x, equidistant_y)
print(string.format("x = %.1f", equidistant_test))
print(string.format("  linear: %.6f", eq_linear))
print(string.format("  lagrange: %.6f", eq_lagrange))
print("✓ 通过\n")

-- 测试 16: 少量点测试
print("测试 16: 少量点测试（2个点）")
local few_x = {0, 1}
local few_y = {0, 1}
local few_test = 0.5
local few_linear = interpolation.linear(few_test, few_x, few_y)
local few_spline = interpolation.spline(few_test, few_x, few_y)
print(string.format("x = %.1f", few_test))
print(string.format("  linear: %.6f", few_linear))
print(string.format("  spline: %.6f", few_spline))
assert_equal(few_linear, 0.5, "linear with 2 points")
assert_equal(few_spline, 0.5, "spline with 2 points")
print("✓ 通过\n")

-- 测试 17: 别名测试
print("测试 17: 别名测试")
local y_poly = interpolation.poly(x_test, x_data, y_data)
local y_nat = interpolation.natural_spline(x_test, x_data, y_data)
print(string.format("poly: %.6f", y_poly))
print(string.format("natural_spline: %.6f", y_nat))
assert_equal(y_poly, y_lagrange, "poly alias")
assert_equal(y_nat, y_spline, "natural_spline alias")
print("✓ 通过\n")

-- 测试 18: 分段线性插值
print("测试 18: 分段线性插值")
local y_pwl = interpolation.piecewise_linear(x_test, x_data, y_data)
print(string.format("piecewise_linear: %.6f", y_pwl))
assert_equal(y_pwl, y_linear, "piecewise_linear equals linear")
print("✓ 通过\n")

-- 测试 19: 指数函数测试
print("测试 19: 指数函数测试")
local exp_x = {0, 0.5, 1, 1.5, 2}
local exp_y = {}
for i, x in ipairs(exp_x) do
    exp_y[i] = math.exp(x)
end
local exp_test = 1.25
local exp_expected = math.exp(exp_test)
local exp_spline = interpolation.spline(exp_test, exp_x, exp_y)
print(string.format("x = %.2f, exp(x) = %.6f", exp_test, exp_expected))
print(string.format("  spline: %.6f, error: %.2e", exp_spline, math.abs(exp_spline - exp_expected)))
assert_equal(exp_spline, exp_expected, "exponential spline", 1e-1)
print("✓ 通过\n")

-- 测试 20: 错误处理 - 超出范围
print("测试 20: 错误处理 - 超出范围")
local ok, err = pcall(function()
    interpolation.linear(-1, x_data, y_data)
end)
if ok then
    error("Should have raised an error for x outside range")
end
print("✓ 通过（正确抛出错误）\n")

print("=== 所有测试通过! ===")
