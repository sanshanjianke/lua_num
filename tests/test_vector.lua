-- Vector 模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local vector = require("vector.init")
local utils = require("utils.init")

-- 断言函数
local function assert_equal(actual, expected, message)
    local tolerance = 1e-5
    local diff = math.abs(actual - expected)
    if diff > tolerance then
        error(string.format("%s: Expected %.6f, got %.6f (diff: %.6f)",
            message or "Assertion failed", expected, actual, diff))
    end
end

local function assert_vec_equal(v1, v2, message)
    if v1.size ~= v2.size then
        error(string.format("%s: Size mismatch - %d vs %d",
            message or "Assertion failed", v1.size, v2.size))
    end

    for i = 1, v1.size do
        assert_equal(v1:get(i), v2:get(i), message or "Element " .. i)
    end
end

local function assert_bool_equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: Expected %s, got %s",
            message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

-- 测试计数
local tests_passed = 0
local tests_total = 0

-- 测试函数
local function test(name, func)
    tests_total = tests_total + 1
    print(string.format("Testing %s...", name))
    local ok, err = pcall(func)
    if ok then
        tests_passed = tests_passed + 1
        print(string.format("  ✓ %s passed", name))
    else
        print(string.format("  ✗ %s failed: %s", name, err))
    end
end

-- ==================== 测试用例 ====================

-- 测试 1: 向量创建
test("Vector creation from array", function()
    local v = vector.new({1, 2, 3, 4, 5})
    assert_bool_equal(v.size, 5, "Vector size")
    assert_equal(v:get(1), 1, "First element")
    assert_equal(v:get(3), 3, "Third element")
    assert_equal(v:get(5), 5, "Last element")
end)

-- 测试 2: 特殊向量
test("Special vectors", function()
    local zeros = vector.zeros(3)
    assert_vec_equal(zeros, vector.new({0, 0, 0}), "Zero vector")

    local ones = vector.ones(4)
    assert_vec_equal(ones, vector.new({1, 1, 1, 1}), "Ones vector")

    local unit = vector.unit(5, 3)
    local expected = vector.new({0, 0, 1, 0, 0})
    assert_vec_equal(unit, expected, "Unit vector")

    local basis = vector.basis(4, 2)
    local basis_expected = vector.new({0, 1, 0, 0})
    assert_vec_equal(basis, basis_expected, "Basis vector")
end)

-- 测试 3: 向量运算
test("Vector arithmetic operations", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({4, 5, 6})

    -- 加法
    local sum = v1 + v2
    assert_vec_equal(sum, vector.new({5, 7, 9}), "Vector addition")

    -- 减法
    local diff = v2 - v1
    assert_vec_equal(diff, vector.new({3, 3, 3}), "Vector subtraction")

    -- 标量乘法
    local scaled = v1 * 2
    assert_vec_equal(scaled, vector.new({2, 4, 6}), "Scalar multiplication")

    -- 标量除法
    local divided = v2 / 2
    assert_vec_equal(divided, vector.new({2, 2.5, 3}), "Scalar division")

    -- 负号
    local negated = -v1
    assert_vec_equal(negated, vector.new({-1, -2, -3}), "Vector negation")

    -- 标量加法
    local added_scalar = v1 + 10
    assert_vec_equal(added_scalar, vector.new({11, 12, 13}), "Scalar addition")

    -- 标量减法
    local sub_scalar = v2 - 3
    assert_vec_equal(sub_scalar, vector.new({1, 2, 3}), "Scalar subtraction")
end)

-- 测试 4: 点积
test("Dot product", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({4, 5, 6})

    local dot = v1:dot(v2)
    assert_equal(dot, 32, "Dot product")

    local dot2 = v1:scalar_product(v2)
    assert_equal(dot2, 32, "Scalar product alias")
end)

-- 测试 5: 向量范数
test("Vector norms", function()
    local v = vector.new({3, 4})

    -- L2 范数
    local norm2 = v:norm(2)
    assert_equal(norm2, 5, "L2 norm")

    local norm_default = v:norm()
    assert_equal(norm_default, 5, "Default norm")

    -- L1 范数
    local norm1 = v:norm(1)
    assert_equal(norm1, 7, "L1 norm")

    -- L∞ 范数
    local norm_inf = v:norm("inf")
    assert_equal(norm_inf, 4, "L∞ norm")

    -- Frobenius 范数
    local norm_fro = v:norm("fro")
    assert_equal(norm_fro, 5, "Frobenius norm")
end)

-- 测试 6: 叉积（仅 3D）
test("Cross product (3D)", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({4, 5, 6})

    local cross = v1:cross(v2)
    -- (2*6 - 3*5, 3*4 - 1*6, 1*5 - 2*4) = (-3, 6, -3)
    assert_vec_equal(cross, vector.new({-3, 6, -3}), "Cross product")

    -- 双重叉积
    local double = vector.double_cross(v1, v2)
    assert_equal(double.size, 3, "Double cross size")
end)

-- 测试 7: 归一化
test("Vector normalization", function()
    local v = vector.new({3, 4})

    local normalized = v:normalize()
    local expected = vector.new({0.6, 0.8})
    assert_vec_equal(normalized, expected, "Normalized vector")

    assert_bool_equal(normalized:is_unit(), true, "Is unit vector")

    -- 测试原地归一化
    local v2 = vector.new({6, 8})
    v2:normalize_inplace()
    assert_vec_equal(v2, vector.new({0.6, 0.8}), "In-place normalization")
end)

-- 测试 8: 角度计算
test("Vector angle", function()
    local v1 = vector.new({1, 0})
    local v2 = vector.new({0, 1})

    local angle = v1:angle(v2)
    assert_equal(angle, math.pi / 2, "90-degree angle in radians")

    local angle_deg = v1:angle_deg(v2)
    assert_equal(angle_deg, 90, "90-degree angle in degrees")

    -- 相同向量的角度
    local v3 = vector.new({1, 1})
    local angle_same = v3:angle(v3)
    assert_equal(angle_same, 0, "Same vector angle")
end)

-- 测试 9: 投影
test("Vector projection", function()
    local v = vector.new({2, 3})
    local onto = vector.new({1, 0})

    local proj = v:project(onto)
    assert_vec_equal(proj, vector.new({2, 0}), "Projection onto x-axis")

    local ortho = v:orthogonal(onto)
    assert_vec_equal(ortho, vector.new({0, 3}), "Orthogonal component")
end)

-- 测试 10: 逐元素运算
test("Element-wise operations", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({2, 3, 4})

    local elem_mul = v1:elementwise_mul(v2)
    assert_vec_equal(elem_mul, vector.new({2, 6, 12}), "Element-wise multiplication")

    local elem_div = v2:elementwise_div(v1)
    assert_vec_equal(elem_div, vector.new({2, 1.5, 1.33333}), "Element-wise division")

    local elem_pow = v1:elementwise_pow(2)
    assert_vec_equal(elem_pow, vector.new({1, 4, 9}), "Element-wise power")
end)

-- 测试 11: 距离计算
test("Distance calculations", function()
    local v1 = vector.new({0, 0})
    local v2 = vector.new({3, 4})

    local dist = v1:distance(v2)
    assert_equal(dist, 5, "Euclidean distance")

    local manhattan = v1:manhattan_distance(v2)
    assert_equal(manhattan, 7, "Manhattan distance")
end)

-- 测试 12: 余弦相似度
test("Cosine similarity", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({4, 5, 6})

    local sim = v1:cosine_similarity(v2)
    assert_bool_equal(sim > 0.97 and sim < 0.98, true, "Cosine similarity")

    -- 正交向量
    local v3 = vector.new({1, 0})
    local v4 = vector.new({0, 1})
    local ortho_sim = v3:cosine_similarity(v4)
    assert_equal(ortho_sim, 0, "Orthogonal cosine similarity")
end)

-- 测试 13: 向量属性检查
test("Vector properties", function()
    local zero = vector.zeros(3)
    assert_bool_equal(zero:is_zero(), true, "Zero vector check")

    local unit_vec = vector.new({1, 0, 0})
    assert_bool_equal(unit_vec:is_unit(), true, "Unit vector check")

    assert_bool_equal(zero:is_orthogonal_to(unit_vec), true, "Orthogonality")

    local parallel1 = vector.new({1, 2, 3})
    local parallel2 = vector.new({2, 4, 6})
    assert_bool_equal(parallel1:is_parallel_to(parallel2), true, "Parallel vectors")
end)

-- 测试 14: 统计函数
test("Statistics functions", function()
    local v = vector.new({1, 2, 3, 4, 5})

    assert_equal(v:sum(), 15, "Sum")
    assert_equal(v:mean(), 3, "Mean")

    local std = v:std()
    local expected_std = math.sqrt(2)  -- sqrt((4+1+0+1+4)/5) = sqrt(2)
    assert_equal(std, expected_std, "Standard deviation")

    local var = v:var()
    assert_equal(var, 2, "Variance")

    local max_val, max_idx = v:max()
    assert_equal(max_val, 5, "Max value")
    assert_equal(max_idx, 5, "Max index")

    local min_val, min_idx = v:min()
    assert_equal(min_val, 1, "Min value")
    assert_equal(min_idx, 1, "Min index")
end)

-- 测试 15: 线性空间
test("Linear space generation", function()
    local lin = vector.linspace(0, 10, 6)
    assert_vec_equal(lin, vector.new({0, 2, 4, 6, 8, 10}), "Linear space")

    local range_vec = vector.range(1, 10, 2)
    assert_vec_equal(range_vec, vector.new({1, 3, 5, 7, 9}), "Range vector")

    local indices = vector.indices(1, 5)
    assert_vec_equal(indices, vector.new({1, 2, 3, 4, 5}), "Indices vector")
end)

-- 测试 16: 随机向量
test("Random vectors", function()
    local rand = vector.rand(3)
    assert_bool_equal(rand.size, 3, "Random vector size")

    local rand_int = vector.rand_int(5, 0, 10)
    assert_bool_equal(rand_int.size, 5, "Random int vector size")

    local rand_unit = vector.rand_unit(4)
    assert_bool_equal(rand_unit:is_unit(), true, "Random unit vector")
end)

-- 测试 17: 常数向量
test("Constant vector", function()
    const = vector.constant(4, 3.14)
    assert_vec_equal(const, vector.new({3.14, 3.14, 3.14, 3.14}), "Constant vector")
end)

-- 测试 18: 反射
test("Vector reflection", function()
    local v = vector.new({1, 1})
    local normal = vector.new({0, 1})

    local reflected = v:reflect(normal)
    -- 反射结果应该约为 {1, -1}
    assert_bool_equal(reflected:get(1) > 0.99 and reflected:get(2) < -0.99, true, "Reflection")
end)

-- 测试 19: 旋转（2D）
test("2D rotation", function()
    local v = vector.new({1, 0})

    -- 旋转 90 度
    local rotated = v:rotate2d(math.pi / 2)
    assert_bool_equal(math.abs(rotated:get(1)) < 1e-6 and math.abs(rotated:get(2) - 1) < 1e-6, true, "2D rotation 90°")

    -- 旋转 180 度
    local rotated_180 = v:rotate2d(math.pi)
    assert_vec_equal(rotated_180, vector.new({-1, 0}), "2D rotation 180°")
end)

-- 测试 20: 向量拼接
test("Vector concatenation", function()
    local v1 = vector.new({1, 2})
    local v2 = vector.new({3, 4, 5})

    local concat = v1:concat(v2)
    assert_vec_equal(concat, vector.new({1, 2, 3, 4, 5}), "Vector concat")

    local stacked = vector.stack(v1, v2)
    assert_vec_equal(stacked, vector.new({1, 2, 3, 4, 5}), "Vector stack")
end)

-- 测试 21: 向量切片
test("Vector slice", function()
    local v = vector.new({1, 2, 3, 4, 5, 6, 7, 8, 9, 10})

    local slice1 = v:slice(3, 7)
    assert_vec_equal(slice1, vector.new({3, 4, 5, 6, 7}), "Slice with bounds")

    local slice2 = v:slice(5)
    assert_vec_equal(slice2, vector.new({5, 6, 7, 8, 9, 10}), "Slice without end")
end)

-- 测试 22: 向量排序
test("Vector sorting", function()
    local v = vector.new({5, 2, 8, 1, 9, 3})

    local sorted = v:sort()
    assert_vec_equal(sorted, vector.new({1, 2, 3, 5, 8, 9}), "Sorted vector")

    local sorted_desc = v:sort(true)
    assert_vec_equal(sorted_desc, vector.new({9, 8, 5, 3, 2, 1}), "Reverse sorted vector")

    local v2 = vector.new({9, 7, 3, 1})
    v2:sort_inplace()
    assert_vec_equal(v2, vector.new({1, 3, 7, 9}), "In-place sort")
end)

-- 测试 23: 向量反转
test("Vector reverse", function()
    local v = vector.new({1, 2, 3, 4, 5})

    local reversed = v:reverse()
    assert_vec_equal(reversed, vector.new({5, 4, 3, 2, 1}), "Reversed vector")
end)

-- 测试 24: 标准基向量组
test("Standard basis", function()
    local basis = vector.standard_basis(3)

    assert_bool_equal(#basis, 3, "Basis count")

    assert_vec_equal(basis[1], vector.new({1, 0, 0}), "First basis vector")
    assert_vec_equal(basis[2], vector.new({0, 1, 0}), "Second basis vector")
    assert_vec_equal(basis[3], vector.new({0, 0, 1}), "Third basis vector")
end)

-- 测试 25: 三重积
test("Triple product", function()
    local a = vector.new({1, 2, 3})
    local b = vector.new({4, 5, 6})
    local c = vector.new({7, 8, 9})

    local triple = vector.triple_product(a, b, c)
    assert_equal(triple, 0, "Triple product (coplanar vectors)")
end)

-- 测试 26: 外积
test("Outer product", function()
    local v1 = vector.new({1, 2})
    local v2 = vector.new({3, 4, 5})

    local outer = v1:outer(v2)
    assert_equal(outer.rows, 2, "Outer product rows")
    assert_equal(outer.cols, 3, "Outer product cols")
    assert_equal(outer:get(1, 1), 3, "Outer product (1,1)")
    assert_equal(outer:get(2, 3), 10, "Outer product (2,3)")
end)

-- 测试 27: 原地运算
test("In-place operations", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({4, 5, 6})

    v1:add_inplace(v2)
    assert_vec_equal(v1, vector.new({5, 7, 9}), "In-place add")

    local v3 = vector.new({10, 20, 30})
    v3:sub_inplace(5)
    assert_vec_equal(v3, vector.new({5, 15, 25}), "In-place subtract scalar")

    local v4 = vector.new({2, 4, 6})
    v4:mul_inplace(3)
    assert_vec_equal(v4, vector.new({6, 12, 18}), "In-place multiply")

    local v5 = vector.new({6, 9, 12})
    v5:div_inplace(3)
    assert_vec_equal(v5, vector.new({2, 3, 4}), "In-place divide")
end)

-- 测试 28: 向量相等
test("Vector equality", function()
    local v1 = vector.new({1, 2, 3})
    local v2 = vector.new({1, 2, 3})
    local v3 = vector.new({1, 2, 4})

    assert_bool_equal(v1 == v2, true, "Equal vectors")
    assert_bool_equal(v1 == v3, false, "Unequal vectors")
    assert_bool_equal(v1 == 5, false, "Vector vs number")
end)

-- 测试 29: 几何空间
test("Geometric space", function()
    local geo = vector.geomspace(1, 100, 5)

    assert_equal(geo:get(1), 1, "Geomspace start")
    assert_equal(geo:get(5), 100, "Geomspace end")

    -- 验证等比数列
    local ratio = geo:get(2) / geo:get(1)
    assert_equal(ratio, geo:get(3) / geo:get(2), "Geometric ratio")
end)

-- 测试 30: 高斯分布
test("Gaussian random vector", function()
    local gauss = vector.randn(1000, 0, 1)

    -- 检查均值接近 0
    local mean = gauss:mean()
    assert_bool_equal(math.abs(mean) < 0.1, true, "Gaussian mean ~ 0")

    -- 检查标准差接近 1
    local std = gauss:std()
    assert_bool_equal(math.abs(std - 1) < 0.1, true, "Gaussian std ~ 1")
end)

-- ==================== 测试结果 ====================

print("\n" .. string.rep("=", 60))
print("Vector Module Test Results")
print(string.rep("=", 60))
print(string.format("Tests passed: %d / %d", tests_passed, tests_total))
print(string.format("Success rate: %.1f%%", (tests_passed / tests_total) * 100))
print(string.rep("=", 60))

if tests_passed == tests_total then
    print("✓ All tests passed!")
else
    print("✗ Some tests failed")
end

print()
