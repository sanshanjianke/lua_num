-- 性能基准测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local matrix = require("matrix.init")
local integration = require("integration.init")
local interpolation = require("interpolation.init")
local optimization = require("optimization.init")
local ode = require("ode.init")

-- 计时辅助函数
local function benchmark(name, func, iterations)
    iterations = iterations or 1
    local start = os.clock()
    for _ = 1, iterations do
        func()
    end
    local elapsed = os.clock() - start
    local avg = elapsed / iterations
    print(string.format("  %-40s: %8.4f ms (avg, %d iter)", name, avg * 1000, iterations))
    return avg
end

print("==================================================")
print("       lua_num 性能基准测试")
print("==================================================\n")

-- ============================================
-- 1. 矩阵运算测试
-- ============================================
print("【1. 矩阵运算】")

-- 矩阵创建
benchmark("矩阵创建 (100x100)", function()
    local m = matrix.zeros(100, 100)
end, 100)

-- 矩阵乘法
local A = matrix.rand(100, 100)
local B = matrix.rand(100, 100)
benchmark("矩阵乘法 (100x100) * (100x100)", function()
    local C = A * B
end, 10)

-- 矩阵加法
benchmark("矩阵加法 (100x100) + (100x100)", function()
    local C = A + B
end, 100)

-- 矩阵转置
benchmark("矩阵转置 (100x100)", function()
    local C = A:transpose()
end, 100)

-- 矩阵行列式
local D = matrix.rand(50, 50)
benchmark("矩阵行列式 (50x50)", function()
    local det = D:det()
end, 10)

-- 矩阵求逆
local E = matrix.rand(30, 30)
benchmark("矩阵求逆 (30x30)", function()
    local inv = E:inverse()
end, 10)

-- LU 分解
benchmark("LU 分解 (50x50)", function()
    local L, U = D:lu()
end, 10)

-- 线性方程组求解
local F = matrix.rand(100, 100)
local b_vec = matrix.rand(100, 1)
benchmark("线性求解 (100x100)", function()
    local x = F:solve(b_vec)
end, 10)

print("")

-- ============================================
-- 2. 数值积分测试
-- ============================================
print("【2. 数值积分】")

-- 辛普森积分
local f1 = function(x) return math.sin(x) end
benchmark("辛普森积分 sin(x) [0, pi]", function()
    local result = integration.simpson(f1, 0, math.pi, 1000)
end, 100)

-- 自适应辛普森
benchmark("自适应辛普森 sin(x) [0, pi]", function()
    local result = integration.adaptive_simpson(f1, 0, math.pi, 1e-8)
end, 100)

-- 高斯积分
benchmark("高斯积分 sin(x) [0, pi] (n=5)", function()
    local result = integration.gauss_legendre(f1, 0, math.pi, 5)
end, 1000)

-- 复合高斯积分
benchmark("复合高斯积分 sin(x) [0, pi]", function()
    local result = integration.composite_gauss(f1, 0, math.pi, 10, 5)
end, 100)

print("")

-- ============================================
-- 3. 插值测试
-- ============================================
print("【3. 插值方法】")

-- 创建测试数据
local n_points = 100
local x_data = {}
local y_data = {}
for i = 1, n_points do
    x_data[i] = (i - 1) / (n_points - 1) * 2 * math.pi
    y_data[i] = math.sin(x_data[i])
end

-- 拉格朗日插值（小规模）
local x_small = {0, 1, 2, 3, 4}
local y_small = {0, 1, 4, 9, 16}
benchmark("拉格朗日插值 (5点)", function()
    local y = interpolation.lagrange(2.5, x_small, y_small)
end, 1000)

-- 牛顿插值
benchmark("牛顿插值 (5点)", function()
    local y = interpolation.newton(2.5, x_small, y_small)
end, 1000)

-- 线性插值
benchmark("线性插值 (100点)", function()
    local y = interpolation.linear(1.5, x_data, y_data)
end, 1000)

-- 三次样条插值
benchmark("三次样条插值 (100点)", function()
    local y = interpolation.spline(1.5, x_data, y_data)
end, 100)

print("")

-- ============================================
-- 4. 数值优化测试
-- ============================================
print("【4. 数值优化】")

-- 黄金分割法
local f_opt = function(x) return (x - 2) * (x - 2) + 1 end
benchmark("黄金分割法 (一维)", function()
    local x_opt = optimization.golden_section(f_opt, -5, 5)
end, 100)

-- 梯度下降
local f_gd = function(x) return x[1]^2 + x[2]^2 end
local grad_gd = function(x) return {2*x[1], 2*x[2]} end
benchmark("梯度下降法 (二维, 100迭代)", function()
    local x_opt = optimization.gradient_descent(f_gd, grad_gd, {5, 5}, {max_iter = 100})
end, 100)

-- BFGS
benchmark("BFGS (二维)", function()
    local x_opt = optimization.bfgs(f_gd, grad_gd, {5, 5})
end, 100)

-- 共轭梯度法
benchmark("共轭梯度法 (二维)", function()
    local x_opt = optimization.conjugate_gradient(f_gd, grad_gd, {5, 5})
end, 100)

-- 高维优化
local dim = 50
local f_high = function(x)
    local sum = 0
    for i = 1, #x do sum = sum + x[i]^2 end
    return sum
end
local grad_high = function(x)
    local g = {}
    for i = 1, #x do g[i] = 2*x[i] end
    return g
end
local x0_high = {}
for i = 1, dim do x0_high[i] = 10 end

benchmark("BFGS (50维)", function()
    local x_opt = optimization.bfgs(f_high, grad_high, x0_high, {max_iter = 100})
end, 10)

print("")

-- ============================================
-- 5. 微分方程测试
-- ============================================
print("【5. 微分方程】")

-- 欧拉方法
local f_ode = function(t, y) return -y end
benchmark("欧拉方法 (1000步)", function()
    local t, y = ode.euler(f_ode, 0, 1, 10, 0.01)
end, 100)

-- RK4
benchmark("RK4 方法 (100步)", function()
    local t, y = ode.rk4(f_ode, 0, 1, 10, 0.1)
end, 100)

-- 自适应RK45
benchmark("RK45 自适应 (tol=1e-6)", function()
    local t, y = ode.rk45(f_ode, 0, 1, 10, {tol = 1e-6})
end, 100)

-- 方程组（谐振子）
local f_harmonic = function(t, y) return {y[2], -y[1]} end
benchmark("RK4 谐振子 (1000步)", function()
    local t, y = ode.rk4(f_harmonic, 0, {1, 0}, 10*math.pi, 0.01)
end, 10)

print("")

-- ============================================
-- 6. 综合测试
-- ============================================
print("【6. 综合测试】")

-- 大矩阵运算
local large_A = matrix.rand(200, 200)
local large_B = matrix.rand(200, 200)
benchmark("大矩阵乘法 (200x200)", function()
    local C = large_A * large_B
end, 5)

-- 大规模积分
benchmark("大规模积分 (10000子区间)", function()
    local result = integration.simpson(f1, 0, math.pi, 10000)
end, 10)

-- 长时间ODE积分
benchmark("长时间ODE积分 (10000步)", function()
    local t, y = ode.rk4(f_ode, 0, 1, 100, 0.01)
end, 10)

print("")
print("==================================================")
print("       基准测试完成!")
print("==================================================")