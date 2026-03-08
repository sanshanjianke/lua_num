-- 矩阵模块入口
local matrix = {}

-- 加载 Matrix 类
local Matrix = require("matrix.matrix")
require("matrix.basic_ops")  -- 加载基础运算
require("matrix.advanced_ops")  -- 加载高级运算
require("matrix.decompositions")  -- 加载矩阵分解
require("matrix.solvers")  -- 加载线性方程组求解

-- 导出 Matrix 构造函数
matrix.new = Matrix.new
matrix.Matrix = Matrix

-- 导出特殊矩阵函数
local special_matrices = require("matrix.special_matrices")
matrix.zeros = special_matrices.zeros
matrix.ones = special_matrices.ones
matrix.eye = special_matrices.eye
matrix.diag = special_matrices.diag
matrix.rand = special_matrices.rand
matrix.rand_int = special_matrices.rand_int
matrix.rand_spd = special_matrices.rand_spd
matrix.hilbert = special_matrices.hilbert
matrix.vandermonde = special_matrices.vandermonde
matrix.toeplitz = special_matrices.toeplitz
matrix.circulant = special_matrices.circulant
matrix.block_diagonal = special_matrices.block_diagonal

-- 别名
matrix.identity = matrix.eye
matrix.zeros_matrix = matrix.zeros
matrix.ones_matrix = matrix.ones

-- 模块元表（允许直接调用 matrix.new 作为矩阵构造函数）
setmetatable(matrix, {
    __call = function(_, ...)
        return Matrix.new(...)
    end
})

return matrix
