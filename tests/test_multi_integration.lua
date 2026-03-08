-- 多重积分模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local integration = require("integration.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-4
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

print("=== 测试多重积分模块 ===\n")

-- =============================================================================
-- 二重积分测试
-- =============================================================================

-- 测试 1: 二重积分 - 常数函数
print("测试 1: 二重积分 - ∬1 dxdy from 0 to 1, 0 to 1")
local f1 = function(x, y) return 1 end
local result1 = integration.double(f1, 0, 1, 0, 1, {method = "simpson", n = 20})
print(string.format("simpson result: %.6f", result1))
assert_equal(result1, 1.0, "double integral of 1")
print("✓ 通过\n")

-- 测试 2: 二重积分 - x*y
print("测试 2: 二重积分 - ∬x*y dxdy from 0 to 1, 0 to 1")
local f2 = function(x, y) return x * y end
local result2 = integration.double(f2, 0, 1, 0, 1, {method = "simpson", n = 20})
print(string.format("simpson result: %.6f", result2))
-- 解析解: 1/4
assert_equal(result2, 0.25, "double integral of x*y")
print("✓ 通过\n")

-- 测试 3: 二重积分 - sin(x)*cos(y)
print("测试 3: 二重积分 - ∬sin(x)cos(y) dxdy from 0 to π/2, 0 to π/2")
local f3 = function(x, y) return math.sin(x) * math.cos(y) end
local result3 = integration.double(f3, 0, math.pi/2, 0, math.pi/2, {method = "gauss", n = 8})
print(string.format("gauss result: %.6f", result3))
assert_equal(result3, 1.0, "double integral of sin(x)*cos(y)", 1e-6)
print("✓ 通过\n")

-- 测试 4: 二重积分 - x² + y²
print("测试 4: 二重积分 - ∬(x² + y²) dxdy from 0 to 1, 0 to 1")
local f4 = function(x, y) return x*x + y*y end
local result4 = integration.double(f4, 0, 1, 0, 1, {method = "simpson", n = 50})
print(string.format("simpson result: %.6f", result4))
assert_equal(result4, 2.0/3.0, "double integral of x² + y²")
print("✓ 通过\n")

-- 测试 5: 二重积分 - 不同方法比较
print("测试 5: 二重积分 - 不同方法比较 ∬e^(x+y) dxdy from 0 to 1, 0 to 1")
local f5 = function(x, y) return math.exp(x + y) end
local expected5 = (math.exp(1) - 1) * (math.exp(1) - 1)
print(string.format("expected: %.6f", expected5))

local methods = {"trapezoidal", "simpson", "gauss"}
for _, method in ipairs(methods) do
    local result = integration.double(f5, 0, 1, 0, 1, {method = method, n = 20})
    local err = math.abs(result - expected5)
    print(string.format("  %s: %.6f (error: %.2e)", method, result, err))
end
print("✓ 通过\n")

-- =============================================================================
-- 三重积分测试
-- =============================================================================

-- 测试 6: 三重积分 - 常数函数
print("测试 6: 三重积分 - ∭1 dxdydz from 0 to 1, 0 to 1, 0 to 1")
local f6 = function(x, y, z) return 1 end
local result6 = integration.triple(f6, 0, 1, 0, 1, 0, 1, {method = "simpson", n = 10})
print(string.format("simpson result: %.6f", result6))
assert_equal(result6, 1.0, "triple integral of 1")
print("✓ 通过\n")

-- 测试 7: 三重积分 - x*y*z
print("测试 7: 三重积分 - ∭x*y*z dxdydz from 0 to 1, 0 to 1, 0 to 1")
local f7 = function(x, y, z) return x * y * z end
local result7 = integration.triple(f7, 0, 1, 0, 1, 0, 1, {method = "gauss", n = 5})
print(string.format("gauss result: %.6f", result7))
assert_equal(result7, 0.125, "triple integral of x*y*z", 1e-6)
print("✓ 通过\n")

-- 测试 8: 三重积分 - x² + y² + z²
print("测试 8: 三重积分 - ∭(x² + y² + z²) dxdydz from 0 to 1, 0 to 1, 0 to 1")
local f8 = function(x, y, z) return x*x + y*y + z*z end
local result8 = integration.triple(f8, 0, 1, 0, 1, 0, 1, {method = "simpson", n = 20})
print(string.format("simpson result: %.6f", result8))
assert_equal(result8, 1.0, "triple integral of x² + y² + z²", 1e-4)
print("✓ 通过\n")

-- =============================================================================
-- 蒙特卡罗积分测试
-- =============================================================================

-- 测试 9: 蒙特卡罗积分 - 单位正方形面积
print("测试 9: 蒙特卡罗积分 - ∬1 dxdy from 0 to 1, 0 to 1")
local f9 = function(p) return 1 end
local bounds9 = {{0, 1}, {0, 1}}
local result9, err9 = integration.monte_carlo(f9, bounds9, {n_samples = 100000, seed = 42})
print(string.format("monte_carlo result: %.6f ± %.6f", result9, err9))
assert_equal(result9, 1.0, "monte carlo unit square", 0.01)
print("✓ 通过\n")

-- 测试 10: 蒙特卡罗积分 - ∬x*y dxdy
print("测试 10: 蒙特卡罗积分 - ∬x*y dxdy from 0 to 1, 0 to 1")
local f10 = function(p) return p[1] * p[2] end
local bounds10 = {{0, 1}, {0, 1}}
local result10, err10 = integration.monte_carlo(f10, bounds10, {n_samples = 100000, seed = 42})
print(string.format("monte_carlo result: %.6f ± %.6f", result10, err10))
assert_equal(result10, 0.25, "monte carlo x*y", 0.01)
print("✓ 通过\n")

-- 测试 11: 蒙特卡罗积分 - 高维积分（4维）
print("测试 11: 蒙特卡罗积分 - 4维积分 ∜x1*x2*x3*x4")
local f11 = function(p) return p[1] * p[2] * p[3] * p[4] end
local bounds11 = {{0, 1}, {0, 1}, {0, 1}, {0, 1}}
local result11, err11 = integration.monte_carlo(f11, bounds11, {n_samples = 100000, seed = 42})
print(string.format("monte_carlo result: %.6f ± %.6f", result11, err11))
assert_equal(result11, 0.0625, "monte carlo 4D", 0.01)
print("✓ 通过\n")

-- 测试 12: 蒙特卡罗积分 - 单位圆面积
print("测试 12: 蒙特卡罗积分 - 单位圆面积")
local f12 = function(p) return 1 end
local bounds12 = {{-1, 1}, {-1, 1}}
local function in_circle(p)
    return p[1]*p[1] + p[2]*p[2] <= 1
end
local result12, err12, ratio12 = integration.monte_carlo_region(f12, bounds12, in_circle, {n_samples = 100000, seed = 42})
print(string.format("monte_carlo result: %.6f ± %.6f (ratio: %.4f)", result12, err12, ratio12))
assert_equal(result12, math.pi, "monte carlo unit circle", 0.05)
print("✓ 通过\n")

-- 测试 13: 蒙特卡罗积分 - 球体积
print("测试 13: 蒙特卡罗积分 - 单位球体积")
local f13 = function(p) return 1 end
local bounds13 = {{-1, 1}, {-1, 1}, {-1, 1}}
local function in_sphere(p)
    return p[1]*p[1] + p[2]*p[2] + p[3]*p[3] <= 1
end
local result13, err13, ratio13 = integration.monte_carlo_region(f13, bounds13, in_sphere, {n_samples = 100000, seed = 42})
print(string.format("monte_carlo result: %.6f ± %.6f (ratio: %.4f)", result13, err13, ratio13))
assert_equal(result13, 4*math.pi/3, "monte carlo unit sphere", 0.1)
print("✓ 通过\n")

-- =============================================================================
-- 别名测试
-- =============================================================================

-- 测试 14: 别名测试
print("测试 14: 别名测试")
local f14 = function(x, y) return x + y end
local result14a = integration.double(f14, 0, 1, 0, 1, {n = 20})
local result14b = integration.double_integral(f14, 0, 1, 0, 1, {n = 20})
assert_equal(result14a, result14b, "double alias", 1e-10)
print("  double = double_integral ✓")

local f14_3 = function(x, y, z) return 1 end
local result14c = integration.triple(f14_3, 0, 1, 0, 1, 0, 1, {n = 10})
local result14d = integration.triple_integral(f14_3, 0, 1, 0, 1, 0, 1, {n = 10})
assert_equal(result14c, result14d, "triple alias", 1e-10)
print("  triple = triple_integral ✓")
print("✓ 通过\n")

print("=== 所有测试通过! ===")