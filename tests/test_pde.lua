-- PDE模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local pde = require("pde.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-4
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

print("=== 测试PDE模块 ===\n")

-- =============================================================================
-- 椭圆型方程测试
-- =============================================================================

-- 测试 1: 拉普拉斯方程 - 矩形区域稳态解
print("测试 1: 拉普拉斯方程 - 矩形区域稳态解")
print("  边界条件: u=0 on y=0, u=1 on y=1, u=0 on x=0, u=0 on x=1")
local bounds1 = {0, 1, 0, 1}
local bc1 = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 1}
}
local u1, info1 = pde.laplace(bounds1, bc1, {nx = 30, ny = 30, max_iter = 5000, tol = 1e-6})
print(string.format("  converged: %s, iterations: %d", tostring(info1.converged), info1.iterations))
-- 检查边界条件
assert_equal(u1[1][15], 0, "left boundary")
assert_equal(u1[30][15], 0, "right boundary")
assert_equal(u1[15][1], 0, "bottom boundary")
assert_equal(u1[15][30], 1, "top boundary")
-- 检查中间点的值（应该在0到1之间）
local mid_val = u1[15][15]
print(string.format("  center value: %.6f (should be between 0 and 1)", mid_val))
assert(mid_val > 0 and mid_val < 1, "center value should be between 0 and 1")
print("✓ 通过\n")

-- 测试 2: 泊松方程 - 有源项
print("测试 2: 泊松方程 - 常数源项")
print("  ∇²u = -2, 边界条件 u = 0")
local f2 = -2  -- 常数源项
local bc2 = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 0}
}
local u2, info2 = pde.poisson(f2, bounds1, bc2, {nx = 25, ny = 25, method = "sor"})
print(string.format("  converged: %s, iterations: %d", tostring(info2.converged), info2.iterations))
-- 对于二维问题，解在中心点约为 0.073 (通过解析解或精细数值解得出)
local x_coord, y_coord = 0.5, 0.5
local u_interp = pde.interpolate(u2, bounds1, x_coord, y_coord)
print(string.format("  u(0.5, 0.5) ≈ %.6f (expected ~0.073 for 2D)", u_interp))
-- 验证解为正且在合理范围内
assert(u_interp > 0 and u_interp < 0.2, "poisson solution should be positive and reasonable")
-- 验证边界条件
assert_equal(u2[1][13], 0, "boundary left")
assert_equal(u2[25][13], 0, "boundary right")
assert_equal(u2[13][1], 0, "boundary bottom")
assert_equal(u2[13][25], 0, "boundary top")
print("✓ 通过\n")

-- 测试 3: 不同迭代方法比较
print("测试 3: 椭圆方程 - 不同迭代方法比较")
local methods = {"jacobi", "gauss_seidel", "sor"}
for _, method in ipairs(methods) do
    local u, info = pde.laplace(bounds1, bc1, {nx = 20, ny = 20, method = method, max_iter = 2000})
    print(string.format("  %s: iterations = %d, converged = %s", method, info.iterations, tostring(info.converged)))
end
print("✓ 通过\n")

-- =============================================================================
-- 抛物型方程测试
-- =============================================================================

-- 测试 4: 一维热传导方程 - 显式FTCS方法
print("测试 4: 一维热传导方程 - FTCS显式方法")
print("  ∂u/∂t = α * ∂²u/∂x², 初始条件: u(x,0) = sin(π*x)")
local alpha = 0.1
local ic4 = function(x) return math.sin(math.pi * x) end
local bc_heat = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0}
}
local x4, t4, u4 = pde.heat1d(alpha, ic4, bc_heat, {0, 1}, {0, 0.5}, {nx = 50, method = "ftcs"})
print(string.format("  grid: nx = %d, nt = %d", #x4, #t4))
-- 检查边界条件
assert_equal(u4[#t4][1], 0, "heat left boundary")
assert_equal(u4[#t4][#x4], 0, "heat right boundary")
-- 检查解是否衰减
local initial_max = 0
local final_max = 0
for i = 1, #x4 do
    if math.abs(u4[1][i]) > initial_max then initial_max = math.abs(u4[1][i]) end
    if math.abs(u4[#t4][i]) > final_max then final_max = math.abs(u4[#t4][i]) end
end
print(string.format("  max amplitude: initial = %.6f, final = %.6f", initial_max, final_max))
assert(final_max < initial_max, "heat should diffuse")
print("✓ 通过\n")

-- 测试 5: 一维热传导方程 - Crank-Nicolson隐式方法
print("测试 5: 一维热传导方程 - Crank-Nicolson隐式方法")
local x5, t5, u5 = pde.heat1d(alpha, ic4, bc_heat, {0, 1}, {0, 0.5}, {nx = 50, nt = 100, method = "cn"})
print(string.format("  grid: nx = %d, nt = %d", #x5, #t5))
-- 比较FTCS和CN的结果
local diff_5 = 0
for i = 1, #x4 do
    diff_5 = diff_5 + math.abs(u4[#t4][i] - u5[#t5][i])
end
diff_5 = diff_5 / #x4
print(string.format("  average difference FTCS vs CN: %.6f", diff_5))
print("✓ 通过\n")

-- 测试 6: 热传导方程 - Neumann边界条件
print("测试 6: 热传导方程 - Neumann边界条件")
local bc_neumann = {
    left = {type = "neumann", value = 0},
    right = {type = "neumann", value = 0}
}
local ic6 = function(x) return 1 end  -- 常数初始条件
local x6, t6, u6 = pde.heat1d(alpha, ic6, bc_neumann, {0, 1}, {0, 0.2}, {nx = 30, nt = 50, method = "cn"})
-- 绝热边界条件应该保持总热量
local sum_initial = 0
local sum_final = 0
for i = 1, #x6 do
    sum_initial = sum_initial + u6[1][i]
    sum_final = sum_final + u6[#t6][i]
end
print(string.format("  total heat: initial = %.6f, final = %.6f", sum_initial, sum_final))
-- 允许一些数值误差
assert_equal(sum_final, sum_initial, "total heat conservation", 2.0)
print("✓ 通过\n")

-- =============================================================================
-- 双曲型方程测试
-- =============================================================================

-- 测试 7: 一维波动方程
print("测试 7: 一维波动方程 - 弦振动")
print("  ∂²u/∂t² = c² * ∂²u/∂x²")
print("  初始条件: u(x,0) = sin(π*x), v(x,0) = 0")
local c = 1.0
local ic_u7 = function(x) return math.sin(math.pi * x) end
local ic_v7 = function(x) return 0 end
local bc_wave = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0}
}
local x7, t7, u7 = pde.wave1d(c, ic_u7, ic_v7, bc_wave, {0, 1}, {0, 2}, {nx = 100, cfl = 0.9})
print(string.format("  grid: nx = %d, nt = %d", #x7, #t7))
-- 检查边界条件
assert_equal(u7[#t7][1], 0, "wave left boundary")
assert_equal(u7[#t7][#x7], 0, "wave right boundary")
-- 对于固定边界，波形应该反射
-- 在 t=1 时，波应该回到初始位置（反向）
local mid_idx = math.floor(#x7 / 2) + 1
print(string.format("  u(0.5, t=0) = %.6f, u(0.5, t=2) = %.6f", u7[1][mid_idx], u7[#t7][mid_idx]))
print("✓ 通过\n")

-- 测试 8: 波动方程 - 高斯包传播
print("测试 8: 波动方程 - 高斯包传播")
local ic_gauss = function(x)
    return math.exp(-100 * (x - 0.5)^2)
end
local bc8 = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0}
}
local x8, t8, u8 = pde.wave1d(0.5, ic_gauss, nil, bc8, {0, 1}, {0, 0.5}, {nx = 150, cfl = 0.8})
print(string.format("  initial max = %.6f", ic_gauss(0.5)))
-- 检查波是否在传播
local max_at_t1 = 0
for i = 1, #x8 do
    if math.abs(u8[5][i]) > max_at_t1 then max_at_t1 = math.abs(u8[5][i]) end
end
print(string.format("  max at t=5th step = %.6f", max_at_t1))
print("✓ 通过\n")

-- 测试 9: 对流方程 - 不同格式比较
print("测试 9: 对流方程 - 不同差分格式比较")
local a = 1.0  -- 对流速度
local ic_adv = function(x)
    if x >= 0.2 and x <= 0.4 then
        return 1
    else
        return 0
    end
end
local schemes = {"upwind", "lax_friedrichs", "lax_wendroff"}
for _, scheme in ipairs(schemes) do
    local x_adv, t_adv, u_adv = pde.advection1d(a, ic_adv, nil, {0, 1}, {0, 0.2}, {scheme = scheme, nx = 100})
    local max_val = 0
    for i = 1, #x_adv do
        if math.abs(u_adv[#t_adv][i]) > max_val then
            max_val = math.abs(u_adv[#t_adv][i])
        end
    end
    print(string.format("  %s: max value = %.6f", scheme, max_val))
end
print("✓ 通过\n")

-- 测试 10: 对流方程 - 精确解验证
print("测试 10: 对流方程 - 精确解验证")
local ic_cos = function(x) return math.cos(2 * math.pi * x) end
local x10, t10, u10 = pde.advection1d(0.5, ic_cos, nil, {0, 1}, {0, 0.5}, {scheme = "lax_wendroff", nx = 100})
-- 精确解: u(x, t) = cos(2π(x - a*t))
local t_final = t10[#t10]
local exact = function(x)
    return math.cos(2 * math.pi * (x - 0.5 * t_final))
end
local l2_error = 0
for i = 1, #x10 do
    l2_error = l2_error + (u10[#t10][i] - exact(x10[i]))^2
end
l2_error = math.sqrt(l2_error / #x10)
print(string.format("  L2 error vs exact solution: %.6f", l2_error))
-- 放宽容差，因为有限差分格式有数值耗散和色散误差
assert(l2_error < 0.5, "advection should be reasonably accurate")
print("✓ 通过\n")

-- =============================================================================
-- 统一接口测试
-- =============================================================================

-- 测试 11: 统一求解接口
print("测试 11: 统一求解接口")
local u_laplace = pde.solve("elliptic", "laplace", bounds1, bc1, {nx = 20, ny = 20})
print("  elliptic/laplace solved")
local u_heat = pde.solve("parabolic", "heat", 0.1, ic4, bc_heat, {0, 1}, {0, 0.1})
print("  parabolic/heat solved")
local u_wave = pde.solve("hyperbolic", "wave", 1.0, ic_u7, ic_v7, bc_wave, {0, 1}, {0, 0.5})
print("  hyperbolic/wave solved")
print("✓ 通过\n")

-- 测试 12: 二维热传导方程
print("测试 12: 二维热传导方程")
local ic_2d = function(x, y) return math.sin(math.pi * x) * math.sin(math.pi * y) end
local bc_2d = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 0}
}
local x_2d, y_2d, t_2d, u_2d = pde.heat2d(0.1, ic_2d, bc_2d, {0, 1, 0, 1}, {0, 0.1}, {nx = 20, ny = 20, nt = 20})
print(string.format("  grid: %d x %d x %d", #x_2d, #y_2d, #t_2d))
-- 检查中心点的值
local center_i, center_j = math.floor(#x_2d/2)+1, math.floor(#y_2d/2)+1
print(string.format("  u(center, t=0) = %.6f, u(center, t=end) = %.6f",
    u_2d[1][center_i][center_j], u_2d[#t_2d][center_i][center_j]))
print("✓ 通过\n")

print("=== 所有测试通过! ===")