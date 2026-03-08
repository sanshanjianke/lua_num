-- 插值模块示例
package.path = "src/?.lua;" .. package.path

local interpolation = require("interpolation.init")

print("=== 插值模块示例 ===\n")

-- 示例数据：正弦函数的几个点
local x_data = {0, math.pi/4, math.pi/2, 3*math.pi/4, math.pi}
local y_data = {}
for i, x in ipairs(x_data) do
    y_data[i] = math.sin(x)
end

print("插值点:")
for i, x in ipairs(x_data) do
    print(string.format("  (%.4f, %.6f)", x, y_data[i]))
end
print()

-- 测试点
local x_test = math.pi / 3  -- π/3 ≈ 1.047
local y_expected = math.sin(x_test)

print(string.format("在 x = %.4f 处插值:", x_test))
print(string.format("  真实值 sin(π/3) = %.6f", y_expected))
print()

-- 1. 线性插值
print("1. 线性插值:")
local y_linear = interpolation.linear(x_test, x_data, y_data)
print(string.format("  结果: %.6f", y_linear))
print(string.format("  误差: %.2e\n", math.abs(y_linear - y_expected)))

-- 2. 拉格朗日插值
print("2. 拉格朗日插值:")
local y_lagrange = interpolation.lagrange(x_test, x_data, y_data)
print(string.format("  结果: %.6f", y_lagrange))
print(string.format("  误差: %.2e\n", math.abs(y_lagrange - y_expected)))

-- 3. 牛顿插值
print("3. 牛顿插值:")
local y_newton = interpolation.newton(x_test, x_data, y_data)
print(string.format("  结果: %.6f", y_newton))
print(string.format("  误差: %.2e\n", math.abs(y_newton - y_expected)))

-- 4. 三次样条插值（自然边界条件）
print("4. 三次样条插值（自然边界条件）:")
local y_spline = interpolation.spline(x_test, x_data, y_data)
print(string.format("  结果: %.6f", y_spline))
print(string.format("  误差: %.2e\n", math.abs(y_spline - y_expected)))

-- 5. 三次样条插值（固定边界条件）
print("5. 三次样条插值（固定边界条件）:")
local dy0 = math.cos(0)        -- sin'(0) = cos(0) = 1
local dyn = math.cos(math.pi)  -- sin'(π) = cos(π) = -1
local y_spline_clamped = interpolation.spline_clamped(x_test, x_data, y_data, dy0, dyn)
print(string.format("  边界条件: y'(0) = %.0f, y'(π) = %.0f", dy0, dyn))
print(string.format("  结果: %.6f", y_spline_clamped))
print(string.format("  误差: %.2e\n", math.abs(y_spline_clamped - y_expected)))

-- 6. 使用统一接口
print("6. 使用统一接口:")
local methods = {"linear", "lagrange", "newton", "spline"}
for _, method in ipairs(methods) do
    local result = interpolation.interpolate(x_test, x_data, y_data, {method = method})
    print(string.format("  %s: %.6f", method, result))
end
print()

-- 7. 数组输入示例
print("7. 批量插值（数组输入）:")
local x_array = {0.5, 1.0, 1.5, 2.0}
print("  插值点: [0.5, 1.0, 1.5, 2.0]")
print()

print("  线性插值:")
local y_array_linear = interpolation.linear(x_array, x_data, y_data)
for i, x in ipairs(x_array) do
    print(string.format("    x=%.2f -> y=%.6f", x, y_array_linear[i]))
end
print()

print("  拉格朗日插值:")
local y_array_lagrange = interpolation.lagrange(x_array, x_data, y_data)
for i, x in ipairs(x_array) do
    print(string.format("    x=%.2f -> y=%.6f", x, y_array_lagrange[i]))
end
print()

-- 8. 样条导数计算
print("8. 样条导数计算:")
local x_deriv = math.pi / 2
local dy = interpolation.spline_derivative(x_deriv, x_data, y_data, "natural")
local ddy = interpolation.spline_derivative2(x_deriv, x_data, y_data, "natural")
local dy_expected = math.cos(x_deriv)     -- sin'(x) = cos(x)
local ddy_expected = -math.sin(x_deriv)   -- sin''(x) = -sin(x)
print(string.format("  x = %.4f", x_deriv))
print(string.format("  一阶导数: %.6f (期望: %.6f, 误差: %.2e)", dy, dy_expected, math.abs(dy - dy_expected)))
print(string.format("  二阶导数: %.6f (期望: %.6f, 误差: %.2e)", ddy, ddy_expected, math.abs(ddy - ddy_expected)))
print()

-- 9. 多项式函数插值示例
print("9. 多项式函数插值（验证精度）:")
print("  函数: y = x^3 - 2x^2 + x + 1")
local poly_x = {0, 0.5, 1, 1.5, 2}
local poly_y = {}
for i, x in ipairs(poly_x) do
    poly_y[i] = x^3 - 2*x^2 + x + 1
    print(string.format("  点 %d: (%.1f, %.3f)", i, poly_x[i], poly_y[i]))
end

local poly_test = 1.25
local poly_expected = poly_test^3 - 2*poly_test^2 + poly_test + 1
local poly_lagrange = interpolation.lagrange(poly_test, poly_x, poly_y)
print(string.format("  在 x = %.2f 处:", poly_test))
print(string.format("    真实值: %.6f", poly_expected))
print(string.format("    拉格朗日: %.6f", poly_lagrange))
print(string.format("    误差: %.2e", math.abs(poly_lagrange - poly_expected)))
print("  注意：对于多项式函数，拉格朗日插值应该是精确的！")

print("\n=== 示例完成 ===")
