-- 矩阵基础示例
-- 从项目根目录运行: lua examples/matrix_basic.lua
package.path = "src/?.lua;" .. package.path

local matrix = require("matrix.init")

print("=== Lua 矩阵计算示例 ===\n")

-- 示例 1: 创建矩阵
print("示例 1: 创建矩阵")
print("-" .. string.rep("-", 40))

local A = matrix.new({{1, 2}, {3, 4}})
print("A =")
print(A)

local B = matrix.new({{5, 6}, {7, 8}})
print("B =")
print(B)

-- 示例 2: 矩阵运算
print("\n示例 2: 矩阵运算")
print("-" .. string.rep("-", 40))

local C = A + B
print("A + B =")
print(C)

local D = A * B
print("A * B =")
print(D)

local E = A * 2
print("A * 2 =")
print(E)

-- 示例 3: 转置
print("\n示例 3: 转置")
print("-" .. string.rep("-", 40))

local A_T = A:transpose()
print("A^T =")
print(A_T)

-- 示例 4: 单位矩阵
print("\n示例 4: 单位矩阵")
print("-" .. string.rep("-", 40))

local I = matrix.eye(3)
print("I_3 =")
print(I)

-- 示例 5: 行列式
print("\n示例 5: 行列式")
print("-" .. string.rep("-", 40))

local det_A = A:det()
print(string.format("det(A) = %.6f", det_A))

-- 示例 6: 矩阵求逆
print("\n示例 6: 矩阵求逆")
print("-" .. string.rep("-", 40))

local inv_A = A:inverse()
print("A^-1 =")
print(inv_A)

-- 验证 A * A^(-1) = I
print("\nA * A^-1 =")
print(A * inv_A)

-- 示例 7: 线性方程组求解
print("\n示例 7: 线性方程组求解")
print("-" .. string.rep("-", 40))

local M = matrix.new({{2, 1}, {1, 3}})
local b = matrix.new({{5}, {7}})

print("求解 Mx = b")
print("M =")
print(M)
print("b =")
print(b)

local x = M:solve(b)
print("x =")
print(x)

print("验证: M * x =")
print(M * x)

-- 示例 8: LU 分解
print("\n示例 8: LU 分解")
print("-" .. string.rep("-", 40))

local L, U, P = A:lu()
print("L =")
print(L)
print("U =")
print(U)
print("P =")
print(P)

print("验证: P^T * L * U =")
print(P:transpose() * L * U)

-- 示例 9: 矩阵范数
print("\n示例 9: 矩阵范数")
print("-" .. string.rep("-", 40))

print(string.format("||A||_F (Frobenius) = %.6f", A:norm("fro")))
print(string.format("||A||_1 (1-范数) = %.6f", A:norm(1)))
print(string.format("||A||_∞ (无穷范数) = %.6f", A:norm("inf")))

-- 示例 10: 特殊矩阵
print("\n示例 10: 特殊矩阵")
print("-" .. string.rep("-", 40))

local zeros = matrix.zeros(2, 3)
print("zeros(2,3) =")
print(zeros)

local ones = matrix.ones(2, 3)
print("ones(2,3) =")
print(ones)

local D = matrix.diag({1, 2, 3})
print("diag({1,2,3}) =")
print(D)

local rand = matrix.rand(2, 3)
print("rand(2,3) =")
print(rand)

-- 示例 11: 对称矩阵
print("\n示例 11: 对称矩阵")
print("-" .. string.rep("-", 40))

local sym = matrix.new({{1, 2, 3}, {2, 4, 5}, {3, 5, 6}})
print("sym =")
print(sym)
print(string.format("sym is symmetric: %s", tostring(sym:is_symmetric())))

-- 示例 12: 逐元素运算
print("\n示例 12: 逐元素运算")
print("-" .. string.rep("-", 40))

local E1 = matrix.new({{1, 2}, {3, 4}})
local E2 = matrix.new({{2, 3}, {4, 5}})

print("E1 =")
print(E1)
print("E2 =")
print(E2)

local hadamard = E1:elementwise_mul(E2)
print("E1 ⊙ E2 =")
print(hadamard)

local elem_pow = E1:elementwise_pow(2)
print("E1 .^ 2 =")
print(elem_pow)

print("\n=== 示例完成 ===")
