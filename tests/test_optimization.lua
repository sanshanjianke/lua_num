-- 数值优化模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local optimization = require("optimization.init")
local matrix = require("matrix.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-6
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

local function assert_vec_equal(v1, v2, msg, tol)
    tol = tol or 1e-6
    if #v1 ~= #v2 then
        error(string.format("%s: vector dimensions mismatch (%d vs %d)",
            msg or "", #v1, #v2))
    end
    for i = 1, #v1 do
        if math.abs(v1[i] - v2[i]) > tol then
            error(string.format("%s: element %d mismatch (%.6f vs %.6f)",
                msg or "", i, v1[i], v2[i]))
        end
    end
end

print("=== 测试数值优化模块 ===\n")

-- 测试 1: 黄金分割法 - x^2 最小化
print("测试 1: 黄金分割法 - x² 最小化")
local f1 = function(x) return x * x end
local x_opt1, f_opt1, iter1 = optimization.golden_section(f1, -2, 2)
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt1, f_opt1, iter1))
assert_equal(x_opt1, 0.0, "golden_section x_opt", 1e-4)
assert_equal(f_opt1, 0.0, "golden_section f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 2: 黄金分割法 - (x-1)^2 + 1 最小化
print("测试 2: 黄金分割法 - (x-1)²+1 最小化")
local f2 = function(x) return (x - 1) * (x - 1) + 1 end
local x_opt2, f_opt2, iter2 = optimization.golden_section(f2, -1, 3)
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt2, f_opt2, iter2))
assert_equal(x_opt2, 1.0, "golden_section x_opt", 1e-4)
assert_equal(f_opt2, 1.0, "golden_section f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 3: 抛物线插值法 - (x-1)² 最小化
print("测试 3: 抛物线插值法 - (x-1)² 最小化")
local f3 = function(x) return (x - 1) * (x - 1) end
local x_opt3, f_opt3, iter3 = optimization.parabolic_interpolation(f3, 0, 1, 2)
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt3, f_opt3, iter3))
assert_equal(x_opt3, 1.0, "parabolic_interpolation x_opt", 1e-2)
assert_equal(f_opt3, 0.0, "parabolic_interpolation f_opt", 1e-2)
print("✓ 通过\n")

-- 测试 4: 抛物线插值法 - x^3 - 2x + 1 最小化
print("测试 4: 抛物线插值法 - x³-2x+1 最小化")
local f4 = function(x) return x * x * x - 2 * x + 1 end
-- 使用更好的初始点，包围极小值点 sqrt(2/3) ≈ 0.8165
local x_opt4, f_opt4, iter4 = optimization.parabolic_interpolation(f4, 0.5, 0.8, 1.2)
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt4, f_opt4, iter4))
-- 在 x = sqrt(2/3) ≈ 0.8165 处有极小值
local expected_x4 = math.sqrt(2/3)
assert_equal(x_opt4, expected_x4, "parabolic_interpolation x_opt", 5e-2)
print("✓ 通过\n")

-- 测试 5: 斐波那契搜索 - x^2 最小化
print("测试 5: 斐波那契搜索 - x² 最小化")
local f5 = function(x) return x * x end
local x_opt5, f_opt5 = optimization.fibonacci_search(f5, -1, 1, 20)
print(string.format("x_opt: %.6f, f_opt: %.6f", x_opt5, f_opt5))
assert_equal(x_opt5, 0.0, "fibonacci_search x_opt", 1e-3)
assert_equal(f_opt5, 0.0, "fibonacci_search f_opt", 1e-3)
print("✓ 通过\n")

-- 测试 6: 斐波那契搜索 - sin(x) 在 [0, 2pi] 最小化
print("测试 6: 斐波那契搜索 - sin(x) 在 [0,2π] 最小化")
local f6 = function(x) return math.sin(x) end
local x_opt6, f_opt6 = optimization.fibonacci_search(f6, 0, 2 * math.pi, 20)
print(string.format("x_opt: %.6f, f_opt: %.6f", x_opt6, f_opt6))
-- sin(x) 在 3π/2 ≈ 4.71 处取最小值 -1
assert_equal(x_opt6, 3 * math.pi / 2, "fibonacci_search x_opt", 1e-1)
assert_equal(f_opt6, -1.0, "fibonacci_search f_opt", 1e-1)
print("✓ 通过\n")

-- 测试 7: 二分法 - cos(x) = 0 的根
print("测试 7: 二分法 - cos(x)=0 的根")
local f7 = function(x) return math.cos(x) end
local root7, val7, iter7 = optimization.bisection(f7, 0, 2)
print(string.format("root: %.6f, f(root): %.6f, iter: %d", root7, val7, iter7))
-- cos(x) 在 π/2 ≈ 1.57 处为 0
assert_equal(root7, math.pi / 2, "bisection root", 1e-4)
assert_equal(val7, 0.0, "bisection f(root)", 1e-4)
print("✓ 通过\n")

-- 测试 8: 二分法 - x^3 - x - 1 = 0 的根
print("测试 8: 二分法 - x³-x-1=0 的根")
local f8 = function(x) return x * x * x - x - 1 end
local root8, val8, iter8 = optimization.bisection(f8, 1, 2)
print(string.format("root: %.6f, f(root): %.6f, iter: %d", root8, val8, iter8))
-- x³-x-1=0 在约1.32处有根
assert_equal(root8, 1.3247, "bisection root", 1e-3)
assert_equal(val8, 0.0, "bisection f(root)", 1e-3)
print("✓ 通过\n")

-- 测试 9: 梯度下降法 - 二次函数
print("测试 9: 梯度下降法 - x²+y² 最小化")
local f9 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad9 = function(x) return {2 * x[1], 2 * x[2]} end
local x0_9 = {1, 1}
local x_opt9, f_opt9, iter9, info9 = optimization.gradient_descent(f9, grad9, x0_9, {
    learning_rate = 0.1,
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt9[1], x_opt9[2], f_opt9, iter9))
assert_equal(x_opt9[1], 0.0, "gradient_descent x[1]", 1e-4)
assert_equal(x_opt9[2], 0.0, "gradient_descent x[2]", 1e-4)
assert_equal(f_opt9, 0.0, "gradient_descent f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 10: 梯度下降法 - 非二次函数
print("测试 10: 梯度下降法 - (x-1)²+(y-2)²+1 最小化")
local f10 = function(x)
    return (x[1] - 1) * (x[1] - 1) + (x[2] - 2) * (x[2] - 2) + 1
end
local grad10 = function(x)
    return {2 * (x[1] - 1), 2 * (x[2] - 2)}
end
local x0_10 = {0, 0}
local x_opt10, f_opt10, iter10, info10 = optimization.gradient_descent(f10, grad10, x0_10, {
    learning_rate = 0.1,
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt10[1], x_opt10[2], f_opt10, iter10))
assert_equal(x_opt10[1], 1.0, "gradient_descent x[1]", 1e-4)
assert_equal(x_opt10[2], 2.0, "gradient_descent x[2]", 1e-4)
assert_equal(f_opt10, 1.0, "gradient_descent f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 11: 牛顿法 - 二次函数
print("测试 11: 牛顿法 - x²+y² 最小化")
local f11 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad11 = function(x) return {2 * x[1], 2 * x[2]} end
local hess11 = function(x)
    return {{2, 0}, {0, 2}}
end
local x0_11 = {2, 2}
local x_opt11, f_opt11, iter11, info11 = optimization.newton(f11, grad11, hess11, x0_11, {
    max_iter = 100,
    tol = 1e-10
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt11[1], x_opt11[2], f_opt11, iter11))
assert_equal(x_opt11[1], 0.0, "newton x[1]", 1e-6)
assert_equal(x_opt11[2], 0.0, "newton x[2]", 1e-6)
assert_equal(f_opt11, 0.0, "newton f_opt", 1e-6)
print("✓ 通过\n")

-- 测试 12: BFGS 拟牛顿法 - 二次函数
print("测试 12: BFGS 拟牛顿法 - x²+y² 最小化")
local f12 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad12 = function(x) return {2 * x[1], 2 * x[2]} end
local x0_12 = {1, 1}
local x_opt12, f_opt12, iter12, info12 = optimization.bfgs(f12, grad12, x0_12, {
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt12[1], x_opt12[2], f_opt12, iter12))
assert_equal(x_opt12[1], 0.0, "bfgs x[1]", 1e-4)
assert_equal(x_opt12[2], 0.0, "bfgs x[2]", 1e-4)
assert_equal(f_opt12, 0.0, "bfgs f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 13: BFGS - 非二次函数
print("测试 13: BFGS - 非二次函数")
local f13 = function(x)
    return (x[1] - 1) * (x[1] - 1) + (x[2] - 2) * (x[2] - 2) + 1
end
local grad13 = function(x)
    return {2 * (x[1] - 1), 2 * (x[2] - 2)}
end
local x0_13 = {0, 0}
local x_opt13, f_opt13, iter13, info13 = optimization.bfgs(f13, grad13, x0_13, {
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt13[1], x_opt13[2], f_opt13, iter13))
assert_equal(x_opt13[1], 1.0, "bfgs x[1]", 1e-4)
assert_equal(x_opt13[2], 2.0, "bfgs x[2]", 1e-4)
assert_equal(f_opt13, 1.0, "bfgs f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 14: 共轭梯度法 (Fletcher-Reeves) - 二次函数
print("测试 14: 共轭梯度法 (Fletcher-Reeves) - x²+y² 最小化")
local f14 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad14 = function(x) return {2 * x[1], 2 * x[2]} end
local x0_14 = {1, 1}
local x_opt14, f_opt14, iter14, info14 = optimization.fr_cg(f14, grad14, x0_14, {
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt14[1], x_opt14[2], f_opt14, iter14))
assert_equal(x_opt14[1], 0.0, "cg x[1]", 1e-3)
assert_equal(x_opt14[2], 0.0, "cg x[2]", 1e-3)
assert_equal(f_opt14, 0.0, "cg f_opt", 1e-3)
print("✓ 通过\n")

-- 测试 15: 共轭梯度法 (Polak-Ribiere) - 二次函数
print("测试 15: 共轭梯度法 (Polak-Ribiere) - x²+y² 最小化")
local f15 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad15 = function(x) return {2 * x[1], 2 * x[2]} end
local x0_15 = {1, 1}
local x_opt15, f_opt15, iter15, info15 = optimization.pr_cg(f15, grad15, x0_15, {
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt15[1], x_opt15[2], f_opt15, iter15))
assert_equal(x_opt15[1], 0.0, "cg x[1]", 1e-3)
assert_equal(x_opt15[2], 0.0, "cg x[2]", 1e-3)
assert_equal(f_opt15, 0.0, "cg f_opt", 1e-3)
print("✓ 通过\n")

-- 测试 16: 随机梯度下降
print("测试 16: 随机梯度下降 - 线性回归")
-- 生成模拟数据
local data16 = {}
for i = 1, 100 do
    local x = i / 100.0 * 10  -- 0.1 到 10
    local y = 2 * x + 3 + (math.random() - 0.5) * 0.5  -- 添加噪声
    table.insert(data16, {x = x, y = y})
end

-- 损失函数：均方误差
local f16 = function(data, w)
    local loss = 0
    for _, sample in ipairs(data) do
        local pred = w[1] * sample.x + w[2]
        loss = loss + (pred - sample.y) * (pred - sample.y)
    end
    return loss / #data
end

-- 单样本梯度
local grad16 = function(sample, w)
    local pred = w[1] * sample.x + w[2]
    local error = pred - sample.y
    return {2 * error * sample.x, 2 * error}
end

local w0_16 = {0, 0}
local w_opt16, loss16 = optimization.stochastic_gradient_descent(f16, grad16, data16, w0_16, {
    epochs = 100,
    batch_size = 10,
    learning_rate = 0.01,
    shuffle = true
})
print(string.format("w_opt: [%.6f, %.6f], loss: %.6f", w_opt16[1], w_opt16[2], loss16))
-- 预期 w[1] ≈ 2, w[2] ≈ 3
assert_equal(w_opt16[1], 2.0, "sgd w[1]", 0.2)
assert_equal(w_opt16[2], 3.0, "sgd w[2]", 0.2)
print("✓ 通过\n")

-- 测试 17: minimize_1d 函数
print("测试 17: minimize_1d 函数")
local f17 = function(x) return x * x - 4 * x + 5 end
local x_opt17, f_opt17, iter17 = optimization.minimize_1d(f17, -5, 5)
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt17, f_opt17, iter17))
-- 最小值在 x=2 处
assert_equal(x_opt17, 2.0, "minimize_1d x_opt", 1e-4)
assert_equal(f_opt17, 1.0, "minimize_1d f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 18: minimize 函数
print("测试 18: minimize 函数")
local f18 = function(x) return x[1] * x[1] + 2 * x[2] * x[2] + x[3] * x[3] end
local grad18 = function(x)
    return {2 * x[1], 4 * x[2], 2 * x[3]}
end
local x0_18 = {1, 2, 3}
local x_opt18, f_opt18, iter18, info18 = optimization.minimize(f18, grad18, x0_18, {
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt18[1], x_opt18[2], x_opt18[3], f_opt18, iter18))
assert_equal(x_opt18[1], 0.0, "minimize x[1]", 1e-4)
assert_equal(x_opt18[2], 0.0, "minimize x[2]", 1e-4)
assert_equal(x_opt18[3], 0.0, "minimize x[3]", 1e-4)
assert_equal(f_opt18, 0.0, "minimize f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 19: optimize 函数（一维）
print("测试 19: optimize 函数（一维）")
local f19 = function(x) return x * x end
local x_opt19, f_opt19, iter19 = optimization.optimize(f19, 0, {
    method = "golden_section",
    a = -1,
    b = 1,
    tol = 1e-6
})
print(string.format("x_opt: %.6f, f_opt: %.6f, iter: %d", x_opt19, f_opt19, iter19))
assert_equal(x_opt19, 0.0, "optimize 1D x_opt", 1e-4)
assert_equal(f_opt19, 0.0, "optimize 1D f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 20: optimize 函数（多维）
print("测试 20: optimize 函数（多维）")
local f20 = function(x) return x[1] * x[1] + x[2] * x[2] end
local grad20 = function(x) return {2 * x[1], 2 * x[2]} end
local x0_20 = {1, 1}
local x_opt20, f_opt20, iter20, info20 = optimization.optimize(f20, x0_20, {
    method = "bfgs",
    grad = grad20,
    max_iter = 1000,
    tol = 1e-6
})
print(string.format("x_opt: [%.6f, %.6f], f_opt: %.6f, iter: %d",
    x_opt20[1], x_opt20[2], f_opt20, iter20))
assert_equal(x_opt20[1], 0.0, "optimize multiD x[1]", 1e-4)
assert_equal(x_opt20[2], 0.0, "optimize multiD x[2]", 1e-4)
assert_equal(f_opt20, 0.0, "optimize multiD f_opt", 1e-4)
print("✓ 通过\n")

-- 测试 21: 别名测试
print("测试 21: 别名测试")
local f21 = function(x) return x * x end
local x_opt_gs, _, _ = optimization.gs(f21, -2, 2)  -- golden_section 别名
local x_opt_gd = optimization.gd(function(x) return x[1] * x[1] + x[2] * x[2] end,
                                  function(x) return {2 * x[1], 2 * x[2]} end,
                                  {1, 1},
                                  {learning_rate = 0.1, max_iter = 1000})
print(string.format("gs x_opt: %.6f, gd x_opt: [%.6f, %.6f]", x_opt_gs, x_opt_gd[1], x_opt_gd[2]))
assert_equal(x_opt_gs, 0.0, "gs alias", 1e-4)
assert_equal(x_opt_gd[1], 0.0, "gd alias", 1e-2)
assert_equal(x_opt_gd[2], 0.0, "gd alias", 1e-2)
print("✓ 通过\n")

print("=== 所有测试通过! ===")
