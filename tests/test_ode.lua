-- 常微分方程模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local ode = require("ode.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-4
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

local function assert_vec_equal(v1, v2, msg, tol)
    tol = tol or 1e-4
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

print("=== 测试常微分方程模块 ===\n")

-- 测试 1: 欧拉方法 - y' = y, y(0) = 1
print("测试 1: 欧拉方法 - y' = y, y(0) = 1")
local f1 = function(t, y) return y end
local t1, y1 = ode.euler(f1, 0, 1, 1, 0.01)
local exact1 = math.exp(1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y1[#y1], exact1, math.abs(y1[#y1] - exact1)))
assert_equal(y1[#y1], exact1, "euler y' = y", 0.05)
print("✓ 通过\n")

-- 测试 2: 欧拉方法 - y' = -y, y(0) = 1
print("测试 2: 欧拉方法 - y' = -y, y(0) = 1")
local f2 = function(t, y) return -y end
local t2, y2 = ode.euler(f2, 0, 1, 1, 0.01)
local exact2 = math.exp(-1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y2[#y2], exact2, math.abs(y2[#y2] - exact2)))
assert_equal(y2[#y2], exact2, "euler y' = -y", 0.05)
print("✓ 通过\n")

-- 测试 3: 改进欧拉方法 (Heun) - y' = y
print("测试 3: 改进欧拉方法 - y' = y, y(0) = 1")
local f3 = function(t, y) return y end
local t3, y3 = ode.heun(f3, 0, 1, 1, 0.1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y3[#y3], exact1, math.abs(y3[#y3] - exact1)))
assert_equal(y3[#y3], exact1, "heun y' = y", 0.01)
print("✓ 通过\n")

-- 测试 4: 中点方法 - y' = y
print("测试 4: 中点方法 - y' = y, y(0) = 1")
local f4 = function(t, y) return y end
local t4, y4 = ode.midpoint(f4, 0, 1, 1, 0.1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y4[#y4], exact1, math.abs(y4[#y4] - exact1)))
assert_equal(y4[#y4], exact1, "midpoint y' = y", 0.01)
print("✓ 通过\n")

-- 测试 5: RK4 方法 - y' = y
print("测试 5: RK4 方法 - y' = y, y(0) = 1")
local f5 = function(t, y) return y end
local t5, y5 = ode.rk4(f5, 0, 1, 1, 0.1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y5[#y5], exact1, math.abs(y5[#y5] - exact1)))
assert_equal(y5[#y5], exact1, "rk4 y' = y", 1e-4)
print("✓ 通过\n")

-- 测试 6: RK4 方法 - y' = -y
print("测试 6: RK4 方法 - y' = -y, y(0) = 1")
local f6 = function(t, y) return -y end
local t6, y6 = ode.rk4(f6, 0, 1, 1, 0.1)
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y6[#y6], exact2, math.abs(y6[#y6] - exact2)))
assert_equal(y6[#y6], exact2, "rk4 y' = -y", 1e-4)
print("✓ 通过\n")

-- 测试 7: RK4 方法 - y'' + y = 0 (谐振子)
print("测试 7: RK4 方法 - 谐振子 y'' + y = 0")
-- 转化为一阶系统: y' = v, v' = -y
-- 初始条件: y(0) = 1, v(0) = 0
-- 解: y = cos(t), v = -sin(t)
local f7 = function(t, y)
    return {y[2], -y[1]}
end
local y0_7 = {1, 0}
local t7, y7 = ode.rk4(f7, 0, y0_7, math.pi / 2, 0.01)
-- 在 t = pi/2: y = cos(pi/2) = 0, v = -sin(pi/2) = -1
print(string.format("y(pi/2) = %.6f, v(pi/2) = %.6f", y7[#y7][1], y7[#y7][2]))
assert_equal(y7[#y7][1], 0, "harmonic oscillator y", 1e-3)
assert_equal(y7[#y7][2], -1, "harmonic oscillator v", 1e-3)
print("✓ 通过\n")

-- 测试 8: RK4 方法 - y' = t^2
print("测试 8: RK4 方法 - y' = t^2, y(0) = 0")
local f8 = function(t, y) return t * t end
local t8, y8 = ode.rk4(f8, 0, 0, 1, 0.1)
local exact8 = 1 / 3  -- integral of t^2 from 0 to 1
print(string.format("y(1) = %.6f, exact = %.6f, error = %.2e", y8[#y8], exact8, math.abs(y8[#y8] - exact8)))
assert_equal(y8[#y8], exact8, "rk4 y' = t^2", 1e-6)
print("✓ 通过\n")

-- 测试 9: RK4 方法 - y' = sin(t)
print("测试 9: RK4 方法 - y' = sin(t), y(0) = 0")
local f9 = function(t, y) return math.sin(t) end
local t9, y9 = ode.rk4(f9, 0, 0, math.pi, 0.1)
local exact9 = 2  -- integral of sin(t) from 0 to pi
print(string.format("y(pi) = %.6f, exact = %.6f, error = %.2e", y9[#y9], exact9, math.abs(y9[#y9] - exact9)))
assert_equal(y9[#y9], exact9, "rk4 y' = sin(t)", 1e-3)
print("✓ 通过\n")

-- 测试 10: 自适应RK45 - y' = y
print("测试 10: 自适应RK45 - y' = y, y(0) = 1")
local f10 = function(t, y) return y end
local t10, y10 = ode.rk45(f10, 0, 1, 1, {tol = 1e-6})
print(string.format("y(1) = %.6f, exact = %.6f, steps = %d", y10[#y10], exact1, #t10))
assert_equal(y10[#y10], exact1, "rk45 y' = y", 1e-4)
print("✓ 通过\n")

-- 测试 11: 自适应RK45 - 谐振子
print("测试 11: 自适应RK45 - 谐振子")
local f11 = function(t, y) return {y[2], -y[1]} end
local t11, y11 = ode.rk45(f11, 0, {1, 0}, 2 * math.pi, {tol = 1e-8})
-- 一个周期后应回到初始状态
print(string.format("y(2pi) = %.6f, v(2pi) = %.6f, steps = %d", y11[#y11][1], y11[#y11][2], #t11))
assert_equal(y11[#y11][1], 1, "rk45 harmonic oscillator y", 1e-4)
assert_equal(y11[#y11][2], 0, "rk45 harmonic oscillator v", 1e-4)
print("✓ 通过\n")

-- 测试 12: solve 函数 - 使用不同方法
print("测试 12: solve 函数 - 不同方法")
local f12 = function(t, y) return -2 * y end
local exact12 = math.exp(-2)
local methods = {"euler", "heun", "midpoint", "rk4"}
for _, method in ipairs(methods) do
    local t, y = ode.solve(f12, {0, 1}, 1, {method = method, h = 0.01})
    print(string.format("  %s: y(1) = %.6f", method, y[#y]))
end
local t_rk45, y_rk45 = ode.solve(f12, {0, 1}, 1, {method = "rk45", tol = 1e-6})
print(string.format("  rk45: y(1) = %.6f", y_rk45[#y_rk45]))
assert_equal(y_rk45[#y_rk45], exact12, "solve function", 1e-4)
print("✓ 通过\n")

-- 测试 13: 刚性问题测试（温和版本）
print("测试 13: 刚性问题 - y' = -100(y - 1), y(0) = 2")
-- 解趋近于 1，时间常数 = 0.01
local f13 = function(t, y) return -100 * (y - 1) end
local t13, y13 = ode.rk45(f13, 0, 2, 0.5, {tol = 1e-4, h_init = 0.0001})
print(string.format("y(0.5) = %.6f (should be close to 1), steps = %d", y13[#y13], #t13))
assert_equal(y13[#y13], 1, "stiff problem", 0.01)
print("✓ 通过\n")

-- 测试 14: Van der Pol 振荡器（非刚性版本）
print("测试 14: Van der Pol 振荡器")
-- y'' - mu*(1-y^2)*y' + y = 0
-- 转化: y' = v, v' = mu*(1-y^2)*v - y
local mu = 1
local f14 = function(t, y)
    return {y[2], mu * (1 - y[1] * y[1]) * y[2] - y[1]}
end
local t14, y14 = ode.rk4(f14, 0, {2, 0}, 10, 0.01)
print(string.format("y(10) = %.4f, v(10) = %.4f", y14[#y14][1], y14[#y14][2]))
-- Van der Pol 振荡器有极限环，解应保持有界
assert(math.abs(y14[#y14][1]) < 5, "Van der Pol y bounded")
assert(math.abs(y14[#y14][2]) < 5, "Van der Pol v bounded")
print("✓ 通过\n")

-- 测试 15: 边界值检查
print("测试 15: 边界值检查")
local f15 = function(t, y) return y end
local t15, y15 = ode.rk4(f15, 0, 1, 0, 0.1)
assert_equal(#t15, 1, "zero interval length", 0)
assert_equal(y15[1], 1, "initial value", 0)
print("✓ 通过\n")

-- 测试 16: 别名测试
print("测试 16: 别名测试")
local f16 = function(t, y) return -y end
local t_euler, y_euler = ode.euler(f16, 0, 1, 1, 0.01)
local t_rk4, y_rk4 = ode.rk4(f16, 0, 1, 1, 0.1)
local t_improved, y_improved = ode.improved_euler(f16, 0, 1, 1, 0.1)
print(string.format("euler: %.4f, rk4: %.6f, improved_euler: %.6f",
    y_euler[#y_euler], y_rk4[#y_rk4], y_improved[#y_improved]))
print("✓ 通过\n")

-- 测试 17: Lotka-Volterra 捕食者-猎物模型
print("测试 17: Lotka-Volterra 模型")
-- dx/dt = alpha*x - beta*x*y
-- dy/dt = delta*x*y - gamma*y
local alpha, beta, delta, gamma = 1.5, 1, 1, 3
local f17 = function(t, state)
    local x, y = state[1], state[2]
    return {alpha * x - beta * x * y, delta * x * y - gamma * y}
end
local t17, y17 = ode.rk4(f17, 0, {10, 5}, 15, 0.01)
print(string.format("x(15) = %.4f, y(15) = %.4f", y17[#y17][1], y17[#y17][2]))
-- 检查解保持为正
assert(y17[#y17][1] > 0, "prey population positive")
assert(y17[#y17][2] > 0, "predator population positive")
print("✓ 通过\n")

-- 测试 18: 数值稳定性 - 长时间积分
print("测试 18: 数值稳定性 - 长时间积分")
local f18 = function(t, y) return {y[2], -y[1]} end
local t18, y18 = ode.rk4(f18, 0, {1, 0}, 10 * math.pi, 0.01)
-- 10个周期后，振幅应保持接近1
local amplitude = math.sqrt(y18[#y18][1]^2 + y18[#y18][2]^2)
print(string.format("经过10个周期，振幅 = %.6f", amplitude))
assert_equal(amplitude, 1, "long time stability", 0.01)
print("✓ 通过\n")

-- 测试 19: n_steps 选项
print("测试 19: n_steps 选项")
local f19 = function(t, y) return y end
local t19, y19 = ode.rk4(f19, 0, 1, 1, nil, {n_steps = 100})
assert_equal(#t19, 101, "n_steps produces correct number of points", 0)
print(string.format("步数 = %d, y(1) = %.6f", #t19 - 1, y19[#y19]))
print("✓ 通过\n")

-- 测试 20: solve_system 函数
print("测试 20: solve_system 函数")
local f_vec = {
    function(t, y) return y[2] end,   -- y1' = y2
    function(t, y) return -y[1] end   -- y2' = -y1
}
local t20, y20 = ode.solve_system(f_vec, {0, math.pi / 2}, {1, 0}, {method = "rk4", h = 0.01})
print(string.format("y(pi/2) = %.6f, v(pi/2) = %.6f", y20[#y20][1], y20[#y20][2]))
assert_equal(y20[#y20][1], 0, "solve_system y", 1e-3)
print("✓ 通过\n")

print("=== 所有测试通过! ===")