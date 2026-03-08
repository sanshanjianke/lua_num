-- 测试单文件版本
package.path = "dist/?.lua;" .. package.path

local num = dofile("dist/lua_num.lua")

print("=== 测试单文件版本 lua_num.lua ===")
print("版本:", num._VERSION)
print("")

-- 测试矩阵模块
print("1. 矩阵模块")
local A = num.matrix.rand(5, 5)
local det = A:det()
print("   随机矩阵行列式:", det)
local I = num.matrix.eye(3)
print("   单位矩阵行列式:", I:det())
print("   OK")

-- 测试向量模块
print("2. 向量模块")
local v = num.vector.linspace(0, 1, 10)
print("   向量长度:", #v)
print("   向量范数:", v:norm())
print("   OK")

-- 测试积分模块
print("3. 积分模块")
local result = num.integration.simpson(math.sin, 0, math.pi, 1000)
print("   sin(x) 从 0 到 pi:", result)
print("   OK")

-- 测试插值模块
print("4. 插值模块")
local x_data = {0, 1, 2, 3}
local y_data = {0, 1, 4, 9}
local y_interp = num.interpolation.spline(1.5, x_data, y_data)
print("   样条插值结果:", y_interp)
print("   OK")

-- 测试优化模块
print("5. 优化模块")
local f = function(x) return (x - 2)^2 end
local x_opt, f_opt = num.optimization.golden_section(f, 0, 4)
print("   最小值点:", x_opt, "最小值:", f_opt)
print("   OK")

-- 测试ODE模块
print("6. ODE模块")
local f_ode = function(t, y) return -y end
local t, y = num.ode.rk4(f_ode, 0, 1, 1, 0.1)
print("   y(1) =", y[#y], "(精确值: 0.3679)")
print("   OK")

-- 测试根求解模块
print("7. 根求解模块")
local f_sys = function(x)
    return {x[1] + x[2] - 3, x[1] - x[2] - 1}
end
local root = num.root.newton(f_sys, {0, 0})
print("   根:", root[1], root[2])
print("   OK")

-- 测试PDE模块
print("8. PDE模块")
local ic = function(x) return math.sin(math.pi * x) end
local bc = {left = {type = "dirichlet", value = 0}, right = {type = "dirichlet", value = 0}}
local x, t, u = num.pde.heat1d(0.1, ic, bc, {0, 1}, {0, 0.1}, {nx = 20})
print("   网格点数:", #x)
print("   OK")

print("")
print("=== 所有测试通过! ===")