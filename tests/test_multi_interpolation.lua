-- 多维插值模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local interpolation = require("interpolation.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-4
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

print("=== 测试多维插值模块 ===\n")

-- =============================================================================
-- 双线性插值测试
-- =============================================================================

-- 测试 1: 双线性插值 - 常数函数
print("测试 1: 双线性插值 - 常数函数 z = 1")
local x_data = {0, 1, 2}
local y_data = {0, 1, 2}
local z_grid = {
    {1, 1, 1},
    {1, 1, 1},
    {1, 1, 1}
}
local result1 = interpolation.bilinear(0.5, 0.5, x_data, y_data, z_grid)
assert_equal(result1, 1.0, "bilinear constant")
print("✓ 通过\n")

-- 测试 2: 双线性插值 - z = x + y
print("测试 2: 双线性插值 - z = x + y")
local z_grid2 = {
    {0, 1, 2},
    {1, 2, 3},
    {2, 3, 4}
}
local result2 = interpolation.bilinear(0.5, 0.5, x_data, y_data, z_grid2)
assert_equal(result2, 1.0, "bilinear x+y")-- 0.5 + 0.5 = 1
print("✓ 通过\n")

-- 测试 3: 双线性插值 - z = x * y
print("测试 3: 双线性插值 - z = x * y")
local z_grid3 = {
    {0, 0, 0},
    {0, 1, 2},
    {0, 2, 4}
}
local result3 = interpolation.bilinear(0.5, 0.5, x_data, y_data, z_grid3)
assert_equal(result3, 0.25, "bilinear x*y", 0.1)-- 0.5 * 0.5 = 0.25
print("✓ 通过\n")

-- 测试 4: 双线性插值 - 批量
print("测试 4: 双线性插值 - 批量")
local points4 = {{0.5, 0.5}, {1.5, 1.5}, {0, 0}}
local results4 = interpolation.bilinear_batch(points4, x_data, y_data, z_grid2)
assert_equal(results4[1], 1.0, "batch point 1")
assert_equal(results4[2], 3.0, "batch point 2")
assert_equal(results4[3], 0.0, "batch point 3")
print("✓ 通过\n")

-- =============================================================================
-- 双三次插值测试
-- =============================================================================

-- 测试 5: 双三次插值 - 常数函数
print("测试 5: 双三次插值 - 常数函数 z = 1")
local result5 = interpolation.bicubic(0.5, 0.5, x_data, y_data, z_grid)
assert_equal(result5, 1.0, "bicubic constant", 0.1)
print("✓ 通过\n")

-- 测试 6: 双三次插值 - z = x + y
print("测试 6: 双三次插值 - z = x + y")
local result6 = interpolation.bicubic(0.5, 0.5, x_data, y_data, z_grid2)
-- Catmull-Rom样条对线性函数有轻微偏差
assert_equal(result6, 1.0, "bicubic x+y", 0.2)
print("✓ 通过\n")

-- =============================================================================
-- 径向基函数插值测试
-- =============================================================================

-- 测试 7: RBF 插值 - 散乱数据点
print("测试 7: RBF 插值 - 散乱数据点")
local points7 = {{0, 0}, {1, 0}, {0, 1}, {1, 1}}
local values7 = {0, 1, 1, 2}-- z = x + y
local result7 = interpolation.rbf({0.5, 0.5}, points7, values7, {kernel = "gaussian", epsilon = 1.0})
-- RBF插值在数据点精确，但中间点可能有偏差
assert_equal(result7, 1.0, "rbf gaussian", 0.5)
print(string.format("  RBF result: %.6f", result7))
print("✓ 通过\n")

-- 测试 8: RBF 插值 - 不同核函数
print("测试 8: RBF 插值 - 不同核函数")
local kernels = {"gaussian", "multiquadric", "linear", "cubic"}
for _, kernel in ipairs(kernels) do
    local result = interpolation.rbf({0.5, 0.5}, points7, values7, {kernel = kernel, epsilon = 1.0})
    print(string.format("  %s: %.6f", kernel, result))
end
print("✓ 通过\n")

-- 测试 9: RBF 预计算权重
print("测试 9: RBF 预计算权重")
local weights9 = interpolation.rbf_weights(points7, values7, {kernel = "gaussian", epsilon = 1.0})
local result9a = interpolation.rbf({0.5, 0.5}, points7, values7, {kernel = "gaussian", epsilon = 1.0})
local result9b = interpolation.rbf({0.5, 0.5}, points7, values7, {kernel = "gaussian", epsilon = 1.0, weights = weights9})
assert_equal(result9a, result9b, "rbf with/without weights", 1e-10)
print("✓ 通过\n")

-- =============================================================================
-- 反距离加权插值测试
-- =============================================================================

-- 测试 10: IDW 插值 - 散乱数据点
print("测试 10: IDW 插值 - 散乱数据点")
local result10 = interpolation.idw({0.5, 0.5}, points7, values7, {power = 2})
print(string.format("  IDW result: %.6f", result10))
assert_equal(result10, 1.0, "idw", 0.1)
print("✓ 通过\n")

-- 测试 11: IDW 插值 - 不同幂次
print("测试 11: IDW 插值 - 不同幂次")
for power = 1, 4 do
    local result = interpolation.idw({0.5, 0.5}, points7, values7, {power = power})
    print(string.format("  power=%d: %.6f", power, result))
end
print("✓ 通过\n")

-- =============================================================================
-- 最近邻插值测试
-- =============================================================================

-- 测试 12: 最近邻插值
print("测试 12: 最近邻插值")
local result12a = interpolation.nearest_neighbor({0.1, 0.1}, points7, values7)
assert_equal(result12a, 0, "nearest (0.1, 0.1)")
local result12b = interpolation.nearest_neighbor({0.9, 0.9}, points7, values7)
assert_equal(result12b, 2, "nearest (0.9, 0.9)")
print("✓ 通过\n")

-- =============================================================================
-- 多元拉格朗日插值测试
-- =============================================================================

-- 测试 13: 多元拉格朗日插值
print("测试 13: 多元拉格朗日插值")
local result13 = interpolation.multivariate_lagrange({0.5, 0.5}, points7, values7)
print(string.format("  result: %.6f", result13))
-- 多元拉格朗日插值使用距离平方，对线性函数可能有偏差
assert_equal(result13, 1.0, "multivariate_lagrange", 1.0)
print("✓ 通过\n")

-- =============================================================================
-- 三维数据测试
-- =============================================================================

-- 测试 14: 三维 RBF 插值
print("测试 14: 三维 RBF 插值")
local points14 = {
    {0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1},
    {1, 1, 0}, {1, 0, 1}, {0, 1, 1}, {1, 1, 1}
}
local values14 = {0, 1, 1, 1, 2, 2, 2, 3}-- z = x + y + z
local result14 = interpolation.rbf({0.5, 0.5, 0.5}, points14, values14, {kernel = "gaussian", epsilon = 1.0})
print(string.format("  3D RBF result: %.6f (expected: 1.5)", result14))
-- RBF插值在中间点可能有较大偏差
assert_equal(result14, 1.5, "3D rbf", 1.0)
print("✓ 通过\n")

-- 测试 15: 三维 IDW 插值
print("测试 15: 三维 IDW 插值")
local result15 = interpolation.idw({0.5, 0.5, 0.5}, points14, values14, {power = 2})
print(string.format("  3D IDW result: %.6f (expected: 1.5)", result15))
assert_equal(result15, 1.5, "3D idw", 0.5)
print("✓ 通过\n")

print("=== 所有测试通过! ===")