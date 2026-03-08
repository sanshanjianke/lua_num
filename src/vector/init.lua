-- Vector 模块入口
local vector = {}

-- 加载 Vector 类和运算
local Vector = require("vector.vector")
require("vector.basic_ops")  -- 加载基础运算
require("vector.advanced_ops")  -- 加载高级运算
require("vector.special_vectors")  -- 加载特殊向量

-- 导出 Vector 构造函数
vector.new = Vector.new
vector.Vector = Vector

-- 导出特殊向量函数
vector.zeros = Vector.zeros
vector.ones = Vector.ones
vector.unit = Vector.unit
vector.rand = Vector.rand
vector.rand_int = Vector.rand_int
vector.rand_unit = Vector.rand_unit
vector.randn = Vector.randn
vector.linspace = Vector.linspace
vector.logspace = Vector.logspace
vector.geomspace = Vector.geomspace
vector.from_table = Vector.from_table
vector.range = Vector.range
vector.basis = Vector.basis
vector.standard_basis = Vector.standard_basis
vector.constant = Vector.constant
vector.repeat_vec = Vector.repeat_vec
vector.concat_vectors = Vector.concat_vectors
vector.stack = Vector.stack
vector.indices = Vector.indices
vector.bool = Vector.bool
vector.from_string = Vector.from_string
vector.meshgrid = Vector.meshgrid
vector.sphere_grid = Vector.sphere_grid

-- 导出类方法（静态方法）
vector.triple_product = Vector.triple_product
vector.double_cross = Vector.double_cross

-- 别名
vector.zero = vector.zeros
vector.identity = vector.unit
vector.einsum = vector.zeros
vector.ones_like = vector.ones

-- 模块元表（允许直接调用 vector.new 作为向量构造函数）
setmetatable(vector, {
    __call = function(_, ...)
        return Vector.new(...)
    end
})

return vector
