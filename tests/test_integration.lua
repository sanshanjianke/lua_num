-- 数值积分模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local integration = require("integration.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-6
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

print("=== 测试数值积分模块 ===\n")

-- 测试 1: 梯形法 - 积分 x^2 从 0 到 1
print("测试 1: 梯形法 - ∫x²dx from 0 to 1")
local f1 = function(x) return x * x end
local result1 = integration.trapezoidal(f1, 0, 1, 1000)
print(string.format("trapezoidal result: %.6f", result1))
assert_equal(result1, 1.0/3.0, "trapezoidal ∫x²dx", 1e-4)
print("✓ 通过\n")

-- 测试 2: 辛普森法 - 积分 sin(x) 从 0 到 pi
print("测试 2: 辛普森法 - ∫sin(x)dx from 0 to π")
local f2 = function(x) return math.sin(x) end
local result2 = integration.simpson(f2, 0, math.pi, 100)
print(string.format("simpson result: %.6f", result2))
assert_equal(result2, 2.0, "simpson ∫sin(x)dx", 1e-6)
print("✓ 通过\n")

-- 测试 3: 中点法则 - 积分 e^x 从 0 到 1
print("测试 3: 中点法则 - ∫eˣdx from 0 to 1")
local f3 = function(x) return math.exp(x) end
local result3 = integration.midpoint(f3, 0, 1, 1000)
print(string.format("midpoint result: %.6f", result3))
assert_equal(result3, math.exp(1) - 1, "midpoint ∫eˣdx", 1e-4)
print("✓ 通过\n")

-- 测试 4: 左端点法则 - 积分 2x 从 0 到 2
print("测试 4: 左端点法则 - ∫2xdx from 0 to 2")
local f4 = function(x) return 2 * x end
local result4 = integration.left_endpoint(f4, 0, 2, 1000)
print(string.format("left_endpoint result: %.6f", result4))
assert_equal(result4, 4.0, "left_endpoint ∫2xdx", 1e-2)
print("✓ 通过\n")

-- 测试 5: 右端点法则 - 积分 x + 1 从 0 到 2
print("测试 5: 右端点法则 - ∫(x+1)dx from 0 to 2")
local f5 = function(x) return x + 1 end
local result5 = integration.right_endpoint(f5, 0, 2, 1000)
print(string.format("right_endpoint result: %.6f", result5))
assert_equal(result5, 4.0, "right_endpoint ∫(x+1)dx", 1e-2)
print("✓ 通过\n")

-- 测试 6: 自适应积分 - 积分 1/(1+x²) 从 0 到 1
print("测试 6: 自适应积分 - ∫1/(1+x²)dx from 0 to 1")
local f6 = function(x) return 1 / (1 + x * x) end
local result6 = integration.adaptive(f6, 0, 1, 1e-8)
print(string.format("adaptive result: %.6f", result6))
assert_equal(result6, math.pi / 4, "adaptive ∫1/(1+x²)dx", 1e-6)
print("✓ 通过\n")

-- 测试 7: 龙贝格积分 - 积分 cos(x) 从 0 到 pi/2
print("测试 7: 龙贝格积分 - ∫cos(x)dx from 0 to π/2")
local f7 = function(x) return math.cos(x) end
local result7 = integration.romberg(f7, 0, math.pi / 2, 10, 1e-10)
print(string.format("romberg result: %.6f", result7))
assert_equal(result7, 1.0, "romberg ∫cos(x)dx", 1e-6)
print("✓ 通过\n")

-- 测试 8: 高斯求积 - 积分 x³ 从 0 到 1
print("测试 8: 高斯求积 - ∫x³dx from 0 to 1")
local f8 = function(x) return x * x * x end
local result8 = integration.gauss(f8, 0, 1, 5)
print(string.format("gauss result: %.6f", result8))
assert_equal(result8, 0.25, "gauss ∫x³dx", 1e-6)
print("✓ 通过\n")

-- 测试 9: 复合高斯求积 - 积分 sin(x)cos(x) 从 0 到 pi/2
print("测试 9: 复合高斯求积 - ∫sin(x)cos(x)dx from 0 to π/2")
local f9 = function(x) return math.sin(x) * math.cos(x) end
local result9 = integration.composite_gauss(f9, 0, math.pi / 2, 5, 10)
print(string.format("composite_gauss result: %.6f", result9))
assert_equal(result9, 0.5, "composite_gauss ∫sin(x)cos(x)dx", 1e-6)
print("✓ 通过\n")

-- 测试 10: 不同节点数的高斯求积
print("测试 10: 不同节点数的高斯求积")
local f10 = function(x) return math.exp(-x * x) end
for n = 2, 6 do
    local result10 = integration.gauss(f10, -2, 2, n)
    print(string.format("  n=%d: %.6f", n, result10))
end
print("✓ 通过\n")

-- 测试 11: 奇异积分（左端点奇异）- ∫1/√x dx from 0 to 1
print("测试 11: 奇异积分（左端点） - ∫1/√xdx from 0 to 1")
local f11 = function(x) return 1 / math.sqrt(x) end
local result11 = integration.singular(f11, 0, 1, "left", "gauss")
print(string.format("singular (left) result: %.6f", result11))
assert_equal(result11, 2.0, "singular ∫1/√xdx", 1e-3)
print("✓ 通过\n")

-- 测试 12: 奇异积分（右端点奇异）
print("测试 12: 奇异积分（右端点）")
local f12 = function(x) return 1 / math.sqrt(1 - x) end
local result12 = integration.singular(f12, 0, 1, "right", "gauss")
print(string.format("singular (right) result: %.6f", result12))
assert_equal(result12, 2.0, "singular ∫1/√(1-x)dx", 1e-3)
print("✓ 通过\n")

-- 测试 13: integrate 函数 - 使用不同方法
print("测试 13: integrate 函数 - 使用不同方法")
local f13 = function(x) return math.sin(x) end
local methods = {"trapezoidal", "simpson", "midpoint", "adaptive", "romberg", "gauss"}
for _, method in ipairs(methods) do
    local opts = {method = method, n = 100}
    if method == "adaptive" then
        opts.tol = 1e-5  -- 放宽容差以加快计算
    end
    if method == "romberg" then
        opts.n = 5  -- 减少迭代次数
    end
    local result13 = integration.integrate(f13, 0, math.pi, opts)
    print(string.format("  %s: %.6f", method, result13))
end
print("✓ 通过\n")

-- 测试 14: 零长度区间
print("测试 14: 零长度区间")
local f14 = function(x) return x * x end
local result14 = integration.simpson(f14, 1, 1, 100)
print(string.format("result: %.6f", result14))
assert_equal(result14, 0, "zero-length interval")
print("✓ 通过\n")

-- 测试 15: 多项式积分 - 测试各种方法的一致性
print("测试 15: 多项式积分 - 测试各种方法的一致性")
local f15 = function(x) return x * x * x + 2 * x * x - 3 * x + 1 end
local expected = 1.0/4.0 + 2.0/3.0 - 3.0/2.0 + 1.0  -- 从0到1的积分
print(string.format("expected: %.6f", expected))

local methods_to_test = {
    trapezoidal = function() return integration.trapezoidal(f15, 0, 1, 1000) end,
    simpson = function() return integration.simpson(f15, 0, 1, 100) end,
    midpoint = function() return integration.midpoint(f15, 0, 1, 1000) end,
    gauss = function() return integration.gauss(f15, 0, 1, 5) end
}

for method, func in pairs(methods_to_test) do
    local result15 = func()
    print(string.format("  %s: %.6f (error: %.2e)", method, result15, math.abs(result15 - expected)))
    assert_equal(result15, expected, method .. " polynomial", 1e-4)
end
print("✓ 通过\n")

-- 测试 16: 复杂函数积分
print("测试 16: 复杂函数积分 - ∫ln(1+x)dx from 0 to 1")
local f16 = function(x) return math.log(1 + x) end
local result16 = integration.simpson(f16, 0, 1, 100)
print(string.format("simpson result: %.6f", result16))
-- 解析解: (x+1)ln(x+1) - x 从 0 到 1 = 2ln(2) - 1
local expected16 = 2 * math.log(2) - 1
assert_equal(result16, expected16, "simpson ∫ln(1+x)dx", 1e-4)
print("✓ 通过\n")

-- 测试 17: 三角函数积分 - ∫sin²(x)dx from 0 to pi
print("测试 17: 三角函数积分 - ∫sin²(x)dx from 0 to π")
local f17 = function(x) return math.sin(x) * math.sin(x) end
local result17 = integration.romberg(f17, 0, math.pi, 8, 1e-10)
print(string.format("romberg result: %.6f", result17))
assert_equal(result17, math.pi / 2, "romberg ∫sin²(x)dx", 1e-6)
print("✓ 通过\n")

-- 测试 18: 指数函数积分 - ∫e^(-x²)dx from -∞ to ∞ (截断到有限区间)
print("测试 18: 指数函数积分 - ∫e^(-x²)dx from -5 to 5")
local f18 = function(x) return math.exp(-x * x) end
local result18 = integration.composite_gauss(f18, -5, 5, 5, 20)
print(string.format("composite_gauss result: %.6f", result18))
-- √π ≈ 1.7724538509
assert_equal(result18, math.sqrt(math.pi), "composite_gauss ∫e^(-x²)dx", 1e-4)
print("✓ 通过\n")

-- 测试 19: 分式函数积分 - ∫1/(1+x⁴)dx from 0 to ∞ (截断)
print("测试 19: 分式函数积分 - ∫1/(1+x⁴)dx from 0 to 10")
local f19 = function(x) return 1 / (1 + x * x * x * x) end
local result19 = integration.adaptive(f19, 0, 10, 1e-8)
print(string.format("adaptive result: %.6f", result19))
-- 解析解: π/(2√2) ≈ 1.110720735
local expected19 = math.pi / (2 * math.sqrt(2))
assert_equal(result19, expected19, "adaptive ∫1/(1+x⁴)dx", 1e-3)
print("✓ 通过\n")

-- 测试 20: 使用 options 参数
print("测试 20: 使用 options 参数")
local f20 = function(x) return math.cos(x) end
local result20 = integration.integrate(f20, 0, math.pi/2, {
    method = "gauss",
    n = 7
})
print(string.format("integrate with options: %.6f", result20))
assert_equal(result20, 1.0, "integrate with options", 1e-6)
print("✓ 通过\n")

print("=== 所有测试通过! ===")
