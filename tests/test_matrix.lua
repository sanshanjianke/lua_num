-- 矩阵模块测试
package.path = "src/?.lua;src/lua_num/?.lua;" .. package.path

local matrix = require("matrix.init")

local function assert_equal(actual, expected, msg, tol)
    tol = tol or 1e-6
    local diff = math.abs(actual - expected)
    if diff > tol then
        error(string.format("%s: expected %.6f, got %.6f (diff=%.2e)",
            msg or "", expected, actual, diff))
    end
end

local function assert_matrix_equal(m1, m2, msg, tol)
    tol = tol or 1e-6
    if m1.rows ~= m2.rows or m1.cols ~= m2.cols then
        error(string.format("%s: dimensions mismatch", msg or ""))
    end
    for i = 1, m1.rows do
        for j = 1, m1.cols do
            local diff = math.abs(m1.data[i][j] - m2.data[i][j])
            if diff > tol then
                error(string.format("%s: at (%d,%d) expected %.6f, got %.6f",
                    msg or "", i, j, m2.data[i][j], m1.data[i][j]))
            end
        end
    end
end

local function assert_bool_equal(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s",
            msg or "", tostring(expected), tostring(actual)))
    end
end

print("=== 测试矩阵模块 ===\n")

-- 测试 1: 创建矩阵
print("测试 1: 创建矩阵")
local m1 = matrix.new({{1, 2}, {3, 4}})
print("m1 =")
print(m1)
assert_equal(m1:get(1, 1), 1, "m1[1,1]")
assert_equal(m1:get(2, 2), 4, "m1[2,2]")
print("✓ 通过\n")

-- 测试 2: 特殊矩阵
print("测试 2: 特殊矩阵")
local zeros = matrix.zeros(3, 3)
print("zeros(3,3) =")
print(zeros)

local ones = matrix.ones(2, 3)
print("ones(2,3) =")
print(ones)

local I = matrix.eye(3)
print("eye(3) =")
print(I)

local D = matrix.diag({1, 2, 3})
print("diag({1,2,3}) =")
print(D)
print("✓ 通过\n")

-- 测试 3: 矩阵运算
print("测试 3: 矩阵运算")
local A = matrix.new({{1, 2}, {3, 4}})
local B = matrix.new({{5, 6}, {7, 8}})

print("A =")
print(A)
print("B =")
print(B)

local C = A + B
print("A + B =")
print(C)
assert_equal(C:get(1, 1), 6, "C[1,1]")
assert_equal(C:get(2, 2), 12, "C[2,2]")

local D2 = A * B
print("A * B =")
print(D2)
assert_equal(D2:get(1, 1), 19, "A*B[1,1]")
assert_equal(D2:get(2, 2), 50, "A*B[2,2]")

local A_T = A:transpose()
print("A^T =")
print(A_T)
assert_equal(A_T:get(1, 2), 3, "A^T[1,2]")
print("✓ 通过\n")

-- 测试 4: 标量运算
print("测试 4: 标量运算")
local m = matrix.new({{1, 2}, {3, 4}})
local m2 = m * 2
print("m * 2 =")
print(m2)
assert_equal(m2:get(1, 1), 2, "m*2[1,1]")

local m3 = m + 10
print("m + 10 =")
print(m3)
assert_equal(m3:get(1, 1), 11, "m+10[1,1]")
print("✓ 通过\n")

-- 测试 5: 行列式
print("测试 5: 行列式")
local det_m1 = m1:det()
print(string.format("det(m1) = %.6f", det_m1))
assert_equal(det_m1, -2, "det(m1)")

local det_I = I:det()
print(string.format("det(I) = %.6f", det_I))
assert_equal(det_I, 1, "det(I)")
print("✓ 通过\n")

-- 测试 6: 矩阵求逆
print("测试 6: 矩阵求逆")
local inv_m1 = m1:inverse()
print("m1^-1 =")
print(inv_m1)

-- 验证 A * A^(-1) = I
local identity = m1 * inv_m1
print("m1 * m1^-1 =")
print(identity)
print("✓ 通过\n")

-- 测试 7: 线性方程组求解
print("测试 7: 线性方程组求解")
local A_eq = matrix.new({{2, 1}, {1, 3}})
local b_eq = matrix.new({{5}, {7}})
local x_eq = A_eq:solve(b_eq)
print("A =")
print(A_eq)
print("b =")
print(b_eq)
print("x = A \\ b =")
print(x_eq)

-- 验证 Ax = b
local check = A_eq * x_eq
print("A * x =")
print(check)
assert_equal(check:get(1, 1), 5, "A*x[1,1]")
assert_equal(check:get(2, 1), 7, "A*x[2,1]")
print("✓ 通过\n")

-- 测试 8: LU 分解
print("测试 8: LU 分解")
local L, U, P = m1:lu()
print("L =")
print(L)
print("U =")
print(U)
print("P =")
print(P)

-- 验证 A = P^T * L * U
local PT = P:transpose()
local LU_check = PT * L * U
print("P^T * L * U =")
print(LU_check)
assert_matrix_equal(LU_check, m1, "LU decomposition")
print("✓ 通过\n")

-- 测试 9: 矩阵范数
print("测试 9: 矩阵范数")
local frobenius = m1:norm("fro")
print(string.format("||m1||_F = %.6f", frobenius))
assert_equal(frobenius, math.sqrt(30), "Frobenius norm")

local one_norm = m1:norm(1)
print(string.format("||m1||_1 = %.6f", one_norm))
assert_equal(one_norm, 6, "1-norm")

local inf_norm = m1:norm("inf")
print(string.format("||m1||_inf = %.6f", inf_norm))
assert_equal(inf_norm, 7, "inf-norm")
print("✓ 通过\n")

-- 测试 10: 矩阵属性
print("测试 10: 矩阵属性")
local sym = matrix.new({{1, 2}, {2, 3}})
print(string.format("sym is symmetric: %s", tostring(sym:is_symmetric())))
assert_bool_equal(sym:is_symmetric(), true, "sym is symmetric")

local diag_mat = matrix.diag({1, 2, 3})
print(string.format("diag_mat is diagonal: %s", tostring(diag_mat:is_diagonal())))
assert_bool_equal(diag_mat:is_diagonal(), true, "diag_mat is diagonal")

local tri_mat = matrix.new({{1, 2, 3}, {0, 4, 5}, {0, 0, 6}})
print(string.format("tri_mat is triangular: %s", tostring(tri_mat:is_triangular())))
assert_bool_equal(tri_mat:is_triangular(), true, "tri_mat is triangular")
print("✓ 通过\n")

-- 测试 11: QR 分解
print("测试 11: QR 分解")
local Q, R = m1:qr()
print("Q =")
print(Q)
print("R =")
print(R)

-- 验证 A = Q * R
local QR_check = Q * R
print("Q * R =")
print(QR_check)
assert_matrix_equal(QR_check, m1, "QR decomposition")
print("✓ 通过\n")

-- 测试 12: Cholesky 分解
print("测试 12: Cholesky 分解")
local spd = matrix.rand_spd(3)
print("SPD matrix =")
print(spd)

local L_cho = spd:cholesky()
print("L (Cholesky) =")
print(L_cho)

-- 验证 A = L * L^T
local L_T = L_cho:transpose()
local cho_check = L_cho * L_T
print("L * L^T =")
print(cho_check)
assert_matrix_equal(cho_check, spd, "Cholesky decomposition", 1e-4)
print("✓ 通过\n")

-- 测试 13: 矩阵克隆
print("测试 13: 矩阵克隆")
local cloned = m1:clone()
print("cloned =")
print(cloned)
assert_matrix_equal(cloned, m1, "clone")
cloned:set(1, 1, 100)
print("After setting cloned[1,1] = 100:")
print("m1[1,1] =", m1:get(1, 1))
print("cloned[1,1] =", cloned:get(1, 1))
assert_equal(m1:get(1, 1), 1, "original unchanged")
assert_equal(cloned:get(1, 1), 100, "clone modified")
print("✓ 通过\n")

-- 测试 14: 矩阵重塑
print("测试 14: 矩阵重塑")
local m = matrix.new({{1, 2, 3}, {4, 5, 6}})
print("m (2x3) =")
print(m)

local reshaped = m:reshape(3, 2)
print("reshaped (3x2) =")
print(reshaped)
print("✓ 通过\n")

-- 测试 15: 逐元素运算
print("测试 15: 逐元素运算")
local A_elem = matrix.new({{1, 2}, {3, 4}})
local B_elem = matrix.new({{2, 3}, {4, 5}})

local hadamard = A_elem:elementwise_mul(B_elem)
print("A ⊙ B =")
print(hadamard)

local elem_div = B_elem:elementwise_div(A_elem)
print("B ⊘ A =")
print(elem_div)

local elem_pow = A_elem:elementwise_pow(2)
print("A .^ 2 =")
print(elem_pow)
print("✓ 通过\n")

print("=== 所有测试通过! ===")
