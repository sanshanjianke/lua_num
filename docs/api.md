# lua_num API 参考

**版本**: 1.1.0

## 目录

1. [快速开始](#快速开始)
2. [矩阵模块 (matrix)](#矩阵模块-matrix)
3. [向量模块 (vector)](#向量模块-vector)
4. [数值积分模块 (integration)](#数值积分模块-integration)
5. [插值模块 (interpolation)](#插值模块-interpolation)
6. [优化模块 (optimization)](#优化模块-optimization)
7. [微分方程模块 (ode)](#微分方程模块-ode)
8. [偏微分方程模块 (pde)](#偏微分方程模块-pde)
9. [根求解模块 (root)](#根求解模块-root)
10. [工具函数](#工具函数)
11. [错误处理](#错误处理)

---

## 快速开始

### 加载库

**方式一：单文件版本（推荐）**

使用 `dist/lua_num.lua` 单文件，无需其他依赖：

```lua
local num = dofile("lua_num.lua")
-- 或使用完整路径
local num = dofile("path/to/lua_num.lua")
```

单文件版本包含所有模块的完整功能，适合嵌入到其他项目中。

**方式二：模块版本**

```lua
-- 加载整个库
local num = require("init")
local matrix = num.matrix
local vector = num.vector

-- 或按需加载模块
local matrix = require("matrix")
local vector = require("vector")
local integration = require("integration")
local interpolation = require("interpolation")
local optimization = require("optimization")
local ode = require("ode")
```

### 快捷别名

```lua
num.mat      -- 等同于 num.matrix
num.vec      -- 等同于 num.vector
num.integ    -- 等同于 num.integration
num.interp   -- 等同于 num.interpolation
num.opt      -- 等同于 num.optimization
num.pde      -- 等同于 num.pde
```

---

## 矩阵模块 (matrix)

### 加载模块

```lua
local matrix = require("matrix")
-- 或
local matrix = require("init").matrix
```

### 创建矩阵

#### matrix.new(data)
从二维数组创建矩阵。

**参数**:
- `data`: 二维数组 (table)

**返回**: Matrix 对象

```lua
local A = matrix.new({{1, 2, 3}, {4, 5, 6}})  -- 2x3 矩阵
-- 也可以直接调用模块
local B = matrix({{1, 2}, {3, 4}})
```

#### matrix.zeros(rows, cols)
创建零矩阵。

**参数**:
- `rows`: 行数 (number)
- `cols`: 列数 (number)

```lua
local Z = matrix.zeros(3, 3)
-- [[0, 0, 0],
--  [0, 0, 0],
--  [0, 0, 0]]
```

#### matrix.ones(rows, cols)
创建全1矩阵。

```lua
local O = matrix.ones(2, 3)
-- [[1, 1, 1],
--  [1, 1, 1]]
```

#### matrix.eye(n)
创建单位矩阵。别名: `matrix.identity`

```lua
local I = matrix.eye(3)
-- [[1, 0, 0],
--  [0, 1, 0],
--  [0, 0, 1]]
```

#### matrix.diag(d)
创建对角矩阵。

**参数**:
- `d`: 对角元素数组 (table)

```lua
local D = matrix.diag({1, 2, 3})
-- [[1, 0, 0],
--  [0, 2, 0],
--  [0, 0, 3]]
```

#### matrix.rand(rows, cols)
创建随机矩阵，元素在 [0, 1) 区间均匀分布。

```lua
local R = matrix.rand(3, 3)
```

#### matrix.rand_int(rows, cols, min, max)
创建随机整数矩阵。

**参数**:
- `rows`, `cols`: 矩阵维度
- `min`: 最小值 (包含)
- `max`: 最大值 (包含)

```lua
local R = matrix.rand_int(3, 3, 0, 10)
```

#### matrix.rand_spd(n)
创建随机对称正定矩阵。

```lua
local SPD = matrix.rand_spd(5)
```

#### matrix.hilbert(n)
创建 Hilbert 矩阵。Hij = 1/(i+j-1)

```lua
local H = matrix.hilbert(4)
```

#### matrix.vandermonde(v)
创建范德蒙矩阵。

**参数**:
- `v`: 生成向量 (table)

```lua
local V = matrix.vandermonde({1, 2, 3, 4})
```

#### matrix.toeplitz(c, r)
创建托普利茨矩阵。

**参数**:
- `c`: 第一列 (table)
- `r`: 第一行 (table，可选，默认为 c 的共轭)

```lua
local T = matrix.toeplitz({1, 2, 3}, {1, 4, 5})
```

#### matrix.circulant(c)
创建循环矩阵。

```lua
local C = matrix.circulant({1, 2, 3})
```

#### matrix.block_diagonal(matrices)
创建块对角矩阵。

**参数**:
- `matrices`: 矩阵数组 (table of Matrix)

```lua
local BD = matrix.block_diagonal({A, B, C})
```

### 矩阵属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `A.rows` | number | 行数 |
| `A.cols` | number | 列数 |
| `A.data` | table | 数据数组（二维数组） |

### 基础运算

矩阵支持 Lua 运算符重载：

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `A + B` | 矩阵加法 | `local C = A + B` |
| `A - B` | 矩阵减法 | `local C = A - B` |
| `A * B` | 矩阵乘法 | `local C = A * B` |
| `A * k` | 标量乘法 | `local C = A * 2` |
| `k * A` | 标量乘法 | `local C = 2 * A` |
| `A / k` | 标量除法 | `local C = A / 2` |
| `-A` | 取负 | `local C = -A` |
| `A == B` | 相等判断 | `if A == B then ...` |

### 矩阵方法

#### 元素访问

```lua
local val = A:get(i, j)    -- 获取第 i 行第 j 列元素（1-indexed）
A:set(i, j, val)           -- 设置元素
local row = A:row(i)       -- 获取第 i 行，返回 Vector
local col = A:col(j)       -- 获取第 j 列，返回 Vector
local diag = A:diag()      -- 获取对角线元素，返回 Vector
```

#### 矩阵操作

```lua
local T = A:transpose()      -- 转置
local C = A:clone()          -- 深拷贝
local R = A:reshape(m, n)    -- 重塑（元素总数必须相同）
local S = A:sub(i1, i2, j1, j2)  -- 提取子矩阵
local F = A:flatten()        -- 展平为向量
```

#### 高级运算

```lua
local d = A:det()            -- 行列式
local t = A:trace()          -- 迹（对角线元素之和）
local r = A:rank()           -- 秩
local n = A:norm("fro")      -- Frobenius 范数
local c = A:cond()           -- 条件数
```

#### 矩阵分解

```lua
-- LU 分解: PA = LU
local L, U, P = A:lu()
-- L: 下三角矩阵
-- U: 上三角矩阵
-- P: 置换矩阵

-- QR 分解: A = QR
local Q, R = A:qr()
-- Q: 正交矩阵
-- R: 上三角矩阵

-- Cholesky 分解: A = LL^T（仅对称正定矩阵）
local L = A:cholesky()
```

#### 线性方程组

```lua
-- 求解 Ax = b
local x = A:solve(b)         -- b 可以是 Matrix 或 table

-- 矩阵求逆
local inv = A:inverse()

-- 伪逆（最小范数解）
local pinv = A:pseudo_inverse()

-- 最小二乘解
local x = A:least_squares(b)
```

#### 判断方法

```lua
A:is_square()          -- 是否方阵
A:is_symmetric()       -- 是否对称
A:is_diagonal()        -- 是否对角矩阵
A:is_triangular()      -- 是否三角矩阵
A:is_upper_triangular() -- 是否上三角矩阵
A:is_lower_triangular() -- 是否下三角矩阵
A:is_positive_definite() -- 是否正定矩阵
```

---

## 向量模块 (vector)

### 加载模块

```lua
local vector = require("vector")
```

### 创建向量

```lua
-- 从数组创建
local v = vector.new({1, 2, 3})
-- 或直接调用
local v = vector({1, 2, 3})

-- 特殊向量
local z = vector.zeros(10)           -- 零向量
local o = vector.ones(10)            -- 全1向量
local e = vector.unit(3, 1)          -- 第1个单位向量 e1 = (1,0,0)
local u = vector.basis(3, 2)         -- 第2个基向量（等同于 unit）
local r = vector.rand(10)            -- 随机向量 [0, 1)
local ri = vector.rand_int(10, 0, 9) -- 随机整数向量
local ru = vector.rand_unit(3)       -- 随机单位向量
local rn = vector.randn(10)          -- 正态分布随机向量

-- 序列生成
local l = vector.linspace(0, 1, 10)  -- 线性空间：0, 0.111, ..., 1
local log = vector.logspace(0, 2, 10) -- 对数空间：10^0, ..., 10^2
local g = vector.geomspace(1, 100, 10) -- 几何序列

-- 其他构造
local rng = vector.range(1, 10, 2)   -- 等差序列：1, 3, 5, 7, 9
local c = vector.constant(5, 3.14)   -- 常数向量：(3.14, 3.14, ...)
local idx = vector.indices(5)        -- 索引向量：1, 2, 3, 4, 5

-- 从字符串解析
local vs = vector.from_string("1, 2, 3, 4")  -- {1, 2, 3, 4}
```

### 向量运算

```lua
-- 算术运算
local v3 = v1 + v2          -- 加法
local v3 = v1 - v2          -- 减法
local v3 = v1 * 2           -- 标量乘法
local v3 = 2 * v1           -- 标量乘法
local v3 = v1 / 2           -- 标量除法
local v3 = -v1              -- 取负

-- 点积与叉积
local d = v1:dot(v2)        -- 点积（内积）
local d = v1 * v2           -- 点积（运算符）
local c = v1:cross(v2)      -- 叉积（仅3D向量）

-- 范数与归一化
local n = v1:norm()         -- 2-范数（欧几里得范数）
local n = v1:norm(1)        -- 1-范数
local n = v1:norm("inf")    -- 无穷范数
local u = v1:normalize()    -- 归一化为单位向量

-- 向量属性
local s = v1:size()         -- 向量长度
local s = #v1               -- 向量长度（运算符）
local l = v1:length()       -- 向量长度（等同于 norm()）

-- 其他运算
local a = v1:angle(v2)      -- 两向量夹角（弧度）
local p = v1:project(v2)    -- v1在v2上的投影
local r = v1:reflect(v2)    -- v1关于v2的反射
```

### 静态方法

```lua
-- 三重积
local t = vector.triple_product(a, b, c)  -- a · (b × c)

-- 双重叉积
local d = vector.double_cross(a, b, c)    -- a × (b × c)

-- 网格
local X, Y = vector.meshgrid(x, y)        -- 生成网格坐标

-- 球面网格
local points = vector.sphere_grid(n, dim) -- 球面上均匀分布的点
```

---

## 数值积分模块 (integration)

### 加载模块

```lua
local integration = require("integration")
```

### 基本积分方法

#### integration.trapezoidal(f, a, b, n)
梯形法积分。别名: `integration.trap`

**参数**:
- `f`: 被积函数 `function(x) -> number`
- `a`: 积分下限 (number)
- `b`: 积分上限 (number)
- `n`: 子区间数 (number)

**返回**: 积分近似值 (number)

```lua
local result = integration.trapezoidal(math.sin, 0, math.pi, 1000)
-- result ≈ 2.0
```

#### integration.simpson(f, a, b, n)
辛普森法积分。精度 O(h^4)。

```lua
local result = integration.simpson(math.sin, 0, math.pi, 1000)
-- result ≈ 2.0 (比梯形法更精确)
```

#### integration.midpoint(f, a, b, n)
中点法积分。

```lua
local result = integration.midpoint(math.sin, 0, math.pi, 1000)
```

#### integration.left_endpoint(f, a, b, n)
左端点法积分。

#### integration.right_endpoint(f, a, b, n)
右端点法积分。

### 高级积分方法

#### integration.adaptive(f, a, b, tol, max_iter)
自适应辛普森积分。别名: `integration.adaptive_simpson`

**参数**:
- `f`: 被积函数
- `a`, `b`: 积分区间
- `tol`: 容差 (number, 默认 1e-8)
- `max_iter`: 最大递归深度 (number, 默认 50)

```lua
local result = integration.adaptive(math.sin, 0, math.pi, 1e-10)
```

#### integration.romberg(f, a, b, n, tol)
龙贝格积分。别名: `integration.romberg_extrapolation`

**参数**:
- `n`: 最大迭代次数 (number, 默认 10)
- `tol`: 收敛容差 (number, 默认 1e-10)

```lua
local result = integration.romberg(math.sin, 0, math.pi, 10, 1e-12)
```

#### integration.gauss(f, a, b, n)
高斯-勒让德积分。别名: `integration.gauss_legendre`

**参数**:
- `n`: 高斯点数 (number, 1-10)

```lua
local result = integration.gauss(math.sin, 0, math.pi, 5)
-- 仅需 5 个点即可达到高精度
```

#### integration.composite_gauss(f, a, b, m, n)
复合高斯积分。将区间分成 m 个子区间，每个用 n 点高斯积分。

**参数**:
- `m`: 子区间数 (number)
- `n`: 每个子区间的高斯点数 (number)

```lua
local result = integration.composite_gauss(math.sin, 0, math.pi, 10, 5)
```

#### integration.singular(f, a, b, singular_point, options)
奇异积分。处理积分区间内或端点处的奇点。

**参数**:
- `singular_point`: 奇点位置 (number)
- `options`: 选项表 (table)

```lua
-- 计算 ∫ 1/√x dx 在 [0, 1] 上的积分
local result = integration.singular(
    function(x) return 1/math.sqrt(x) end,
    0, 1, 0  -- 0 是奇点
)
```

### 统一接口

#### integration.integrate(f, a, b, options)
统一积分接口，自动选择方法。

**参数**:
- `options`: 选项表
  - `method`: 方法名 (string)
  - `n`: 子区间数或节点数 (number)
  - `tol`: 容差 (number)
  - `max_iter`: 最大迭代次数 (number)

```lua
-- 使用辛普森法
local r1 = integration.integrate(math.sin, 0, math.pi, {
    method = "simpson", n = 1000
})

-- 使用自适应方法
local r2 = integration.integrate(math.sin, 0, math.pi, {
    method = "adaptive", tol = 1e-10
})

-- 使用高斯积分
local r3 = integration.integrate(math.sin, 0, math.pi, {
    method = "gauss", n = 5
})
```

---

## 插值模块 (interpolation)

### 加载模块

```lua
local interpolation = require("interpolation")
```

### 插值方法

**注意**: 所有插值函数的第一个参数都是要插值的点 `x`，然后是数据点 `x_data` 和 `y_data`。

#### interpolation.linear(x, x_data, y_data)
线性插值（分段线性）。O(n) 复杂度。

**参数**:
- `x`: 要插值的点 (number)
- `x_data`: x 坐标数组 (table，必须严格递增)
- `y_data`: y 坐标数组 (table)

**返回**: 插值结果 (number)

```lua
local y = interpolation.linear(1.5, {0, 1, 2, 3}, {0, 1, 4, 9})
-- y ≈ 2.5
```

#### interpolation.lagrange(x, x_data, y_data)
拉格朗日插值。O(n^2) 复杂度。别名: `interpolation.poly`

```lua
local y = interpolation.lagrange(1.5, {0, 1, 2}, {0, 1, 4})
-- 对于二次函数 y = x^2，精确结果为 2.25
```

#### interpolation.newton(x, x_data, y_data)
牛顿插值。O(n^2) 预处理，O(n) 单点求值。

```lua
local y = interpolation.newton(1.5, {0, 1, 2, 3}, {0, 1, 8, 27})
```

#### interpolation.piecewise_linear(x, x_data, y_data)
分段线性插值（等同于 `linear`）。

#### interpolation.spline(x, x_data, y_data)
三次样条插值（自然边界条件）。别名: `interpolation.natural_spline`

**边界条件**: y''(x0) = y''(xn) = 0

```lua
local y = interpolation.spline(1.5, {0, 1, 2, 3}, {0, 1, 4, 9})
```

#### interpolation.spline_clamped(x, x_data, y_data, dy0, dyn)
固定边界条件的三次样条插值。别名: `interpolation.clamped_spline`

**参数**:
- `dy0`: 左端点导数值 (number)
- `dyn`: 右端点导数值 (number)

```lua
local y = interpolation.spline_clamped(1.5, {0, 1, 2}, {0, 1, 4}, 0, 4)
```

#### interpolation.spline_derivative(x, x_data, y_data)
样条插值的一阶导数。

```lua
local dy = interpolation.spline_derivative(1.5, {0, 1, 2}, {0, 1, 4})
```

#### interpolation.spline_derivative2(x, x_data, y_data)
样条插值的二阶导数。

### 统一接口

#### interpolation.interpolate(x, x_data, y_data, options)
统一插值接口。

**参数**:
- `options`: 选项表
  - `method`: 方法名 (string)
  - `boundary`: 边界条件类型 (string, "natural" 或 "clamped")
  - `boundary_values`: 边界值 (table, {dy0, dyn})

```lua
-- 线性插值
local y1 = interpolation.interpolate(1.5, x_data, y_data, {
    method = "linear"
})

-- 样条插值
local y2 = interpolation.interpolate(1.5, x_data, y_data, {
    method = "spline"
})

-- 固定边界样条
local y3 = interpolation.interpolate(1.5, x_data, y_data, {
    method = "spline_clamped",
    boundary_values = {1, 2}
})
```

---

## 优化模块 (optimization)

### 加载模块

```lua
local optimization = require("optimization")
```

### 一维优化

#### optimization.golden_section(f, a, b, tol)
黄金分割法。别名: `optimization.gs`

**参数**:
- `f`: 目标函数 `function(x) -> number`
- `a`, `b`: 搜索区间 (number)
- `tol`: 收敛容差 (number, 可选)

**返回**: `x_opt, f_opt, iter` (最优点, 最优值, 迭代次数)

```lua
local x_opt, f_opt, iter = optimization.golden_section(
    function(x) return (x-2)^2 end,
    0, 4
)
-- x_opt ≈ 2, f_opt ≈ 0
```

#### optimization.parabolic_interpolation(f, x1, x2, x3, tol)
抛物线插值法。别名: `optimization.poly_interpol`

**参数**:
- `x1, x2, x3`: 三个初始点 (number)，满足 f(x2) < f(x1) 且 f(x2) < f(x3)

```lua
local x_opt, f_opt, iter = optimization.parabolic_interpolation(
    function(x) return (x-2)^2 end,
    0, 1, 3
)
```

#### optimization.fibonacci_search(f, a, b, n)
斐波那契搜索。别名: `optimization.fib_search`

**参数**:
- `n`: 迭代次数 (number)

```lua
local x_opt, f_opt = optimization.fibonacci_search(
    function(x) return (x-2)^2 end,
    0, 4, 20
)
```

#### optimization.bisection(f, a, b, tol)
二分法（求根，非优化）。

### 多维优化

#### optimization.gradient_descent(f, grad, x0, options)
梯度下降法。别名: `optimization.gd`

**参数**:
- `f`: 目标函数 `function(x) -> number`
- `grad`: 梯度函数 `function(x) -> table`
- `x0`: 初始点 (table)
- `options`: 选项表
  - `max_iter`: 最大迭代次数 (number, 默认 1000)
  - `tol`: 收敛容差 (number, 默认 1e-8)
  - `learning_rate`: 学习率 (number, 默认 0.01)

**返回**: 最优解 (table)

```lua
local x_opt = optimization.gradient_descent(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {1, 1},
    {max_iter = 100, learning_rate = 0.1}
)
-- x_opt ≈ {0, 0}
```

#### optimization.newton(f, grad, hessian, x0, options)
牛顿法。

**参数**:
- `hessian`: 海森矩阵函数 `function(x) -> table (2D)`

```lua
local x_opt = optimization.newton(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    function(x) return {{2, 0}, {0, 2}} end,
    {1, 1}
)
-- 牛顿法对二次函数一次迭代即可达到最优
```

#### optimization.bfgs(f, grad, x0, options)
BFGS 拟牛顿法。推荐用于一般优化问题。

```lua
local x_opt = optimization.bfgs(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {1, 1}
)
```

#### optimization.conjugate_gradient(f, grad, x0, options)
共轭梯度法。别名: `optimization.cg`

**参数**:
- `options.method`: 共轭梯度方法 (string, "Polak-Ribiere" 或 "Fletcher-Reeves")

```lua
local x_opt = optimization.conjugate_gradient(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {1, 1},
    {method = "Polak-Ribiere"}
)
```

#### optimization.stochastic_gradient_descent(f, grad, x0, options)
随机梯度下降法。别名: `optimization.sgd`

用于大规模优化，需要数据分批。

### 便捷函数

#### optimization.optimize(f, x0, options)
统一优化接口。

**参数**:
- `x0`: 初始点（标量为一维优化，table为多维优化）
- `options`: 选项表
  - `method`: 方法名 (string)
  - `grad`: 梯度函数（多维优化必需）
  - `hessian`: 海森矩阵函数（牛顿法必需）

```lua
-- 一维优化
local x_opt = optimization.optimize(
    function(x) return (x-2)^2 end,
    1,  -- 初始点
    {method = "golden_section", a = 0, b = 4}
)

-- 多维优化
local x_opt = optimization.optimize(
    function(x) return x[1]^2 + x[2]^2 end,
    {1, 1},
    {
        method = "bfgs",
        grad = function(x) return {2*x[1], 2*x[2]} end
    }
)
```

#### optimization.minimize_1d(f, a, b, options)
一维函数最小化（使用黄金分割法）。

```lua
local x_min, f_min = optimization.minimize_1d(
    function(x) return (x-3)^2 end,
    0, 6
)
```

#### optimization.minimize(f, grad, x0, options)
多维函数最小化（使用 BFGS 方法）。

```lua
local x_min, f_min = optimization.minimize(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {5, 5}
)
```

#### optimization.penalty_method(f, grad, x0, constraints, options)
惩罚函数法（约束优化）。

**参数**:
- `constraints`: 约束函数数组，每个函数返回 0 表示满足约束

```lua
-- 约束优化: min x^2 + y^2, s.t. x + y = 1
local x_opt, f_opt = optimization.penalty_method(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {0, 0},
    {
        function(x) return x[1] + x[2] - 1 end  -- x + y - 1 = 0
    }
)
```

---

## 微分方程模块 (ode)

### 加载模块

```lua
local ode = require("ode")
```

### ODE 求解器

所有求解器的通用签名：

```lua
local t, y = solver(f, t0, y0, t_end, h, options)
```

**参数**:
- `f`: 微分函数 `function(t, y) -> dy/dt`
- `t0`: 初始时间 (number)
- `y0`: 初始值 (number 或 table)
- `t_end`: 终止时间 (number)
- `h`: 步长 (number，自适应方法可选)
- `options`: 选项表 (table)

**返回**:
- `t`: 时间数组 (table)
- `y`: 解数组 (table 或二维 table)

#### ode.euler(f, t0, y0, t_end, h, options)
欧拉方法。一阶精度，O(h)。

```lua
local f = function(t, y) return -y end  -- y' = -y
local t, y = ode.euler(f, 0, 1, 1, 0.01)
-- y(t) = e^(-t)
```

#### ode.heun(f, t0, y0, t_end, h, options)
改进欧拉方法（Heun方法）。二阶精度。别名: `ode.improved_euler`

```lua
local t, y = ode.heun(f, 0, 1, 1, 0.1)
```

#### ode.midpoint(f, t0, y0, t_end, h, options)
中点方法。二阶精度。

```lua
local t, y = ode.midpoint(f, 0, 1, 1, 0.1)
```

#### ode.runge_kutta4(f, t0, y0, t_end, h, options)
四阶龙格-库塔方法。四阶精度，O(h^4)。别名: `ode.rk4`

```lua
local t, y = ode.rk4(f, 0, 1, 1, 0.1)
-- 精度高，推荐使用
```

#### ode.rk45(f, t0, y0, t_end, options)
自适应步长 RK45 方法。别名: `ode.rkf45`

**参数**:
- `options`:
  - `tol`: 容差 (number, 默认 1e-6)
  - `h_init`: 初始步长 (number, 默认自动选择)
  - `h_min`: 最小步长 (number)
  - `h_max`: 最大步长 (number)

```lua
local t, y = ode.rk45(f, 0, 1, 1, {tol = 1e-8, h_init = 0.1})
```

#### ode.adaptive_rk(f, t0, y0, t_end, options)
自适应龙格-库塔方法。

### 方程组

对于方程组，`y0` 应为 table，`f` 返回 table：

```lua
-- 谐振子: y'' + y = 0
-- 转化为一阶方程组: y' = v, v' = -y
local f = function(t, y)
    return {y[2], -y[1]}
end
local t, y = ode.rk4(f, 0, {1, 0}, 10, 0.01)
-- y(t) = cos(t), v(t) = -sin(t)
```

### 统一接口

#### ode.solve(f, t_span, y0, options)
统一求解接口。

**参数**:
- `t_span`: 时间区间 {t0, t_end} (table)
- `options`:
  - `method`: 方法名 (string, 默认 "rk4")
  - `h`: 步长 (number)
  - `tol`: 容差 (自适应方法)

```lua
local t, y = ode.solve(
    function(t, y) return -y end,
    {0, 1},
    1,
    {method = "rk4", h = 0.1}
)

-- 自适应方法
local t, y = ode.solve(
    function(t, y) return -y end,
    {0, 1},
    1,
    {method = "rk45", tol = 1e-8}
)
```

#### ode.solve_system(f_vec, t_span, y0_vec, options)
求解方程组。

```lua
local t, y = ode.solve_system(
    {f1, f2},  -- 微分函数数组
    {0, 10},
    {y1_0, y2_0},
    {method = "rk4", h = 0.01}
)
```

---

## 偏微分方程模块 (pde)

### 加载模块

```lua
local pde = require("pde")
-- 或
local pde = require("init").pde
```

PDE 模块支持三大类偏微分方程的数值求解：椭圆型、抛物型和双曲型方程。

### 椭圆型方程

椭圆型方程描述稳态问题，如热平衡、静电场等。

#### pde.poisson(f, bounds, bc, options)
求解二维泊松方程：∇²u = f

**参数**:
- `f`: 源项函数 `function(i, j) -> number` 或常数 (number)
- `bounds`: 区域边界 `{ax, bx, ay, by}` (table)
- `bc`: 边界条件表 (table)
  - `left`, `right`, `top`, `bottom`: 各边界的条件
  - 每个条件: `{type = "dirichlet"|"neumann", value = ...}`
- `options`: 选项表
  - `nx`, `ny`: 网格点数 (number, 默认 50)
  - `method`: 迭代方法 `"jacobi"`|`"gauss_seidel"`|`"sor"` (string, 默认 "sor")
  - `max_iter`: 最大迭代次数 (number, 默认 10000)
  - `tol`: 收敛容差 (number, 默认 1e-6)
  - `omega`: SOR 松弛因子 (number, 可选，默认自动计算)

**返回**: `u, info` (解网格, 收敛信息)

```lua
-- 求解泊松方程 ∇²u = -2，边界 u = 0
local u, info = pde.poisson(-2, {0, 1, 0, 1}, {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 0}
}, {nx = 50, ny = 50})

-- 访问解：u[i][j] 是第 i 行第 j 列的值
print("中心点值:", u[25][25])
print("收敛:", info.converged, "迭代次数:", info.iterations)
```

#### pde.laplace(bounds, bc, options)
求解二维拉普拉斯方程：∇²u = 0

这是泊松方程 `f = 0` 的特例。

```lua
-- 求解拉普拉斯方程，边界条件决定解
local u, info = pde.laplace({0, 1, 0, 1}, {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 1}  -- 顶部为 1
})
```

#### pde.interpolate(u, bounds, x, y)
在解网格上进行双线性插值。

**参数**:
- `u`: 解网格 (table)
- `bounds`: 区域边界 (table)
- `x`, `y`: 查询点坐标 (number)

```lua
local val = pde.interpolate(u, {0, 1, 0, 1}, 0.5, 0.5)
```

### 抛物型方程

抛物型方程描述时间演化问题，如热传导、扩散等。

#### pde.heat1d(alpha, ic, bc, x_span, t_span, options)
求解一维热传导方程：∂u/∂t = α * ∂²u/∂x²

**参数**:
- `alpha`: 热扩散系数 (number)
- `ic`: 初始条件函数 `function(x) -> number`
- `bc`: 边界条件表 `{left = {...}, right = {...}}`
- `x_span`: 空间区间 `{x0, x_end}` (table)
- `t_span`: 时间区间 `{t0, t_end}` (table)
- `options`: 选项表
  - `method`: 方法 `"ftcs"`|`"cn"` (string, 默认 "ftcs")
  - `nx`: 空间网格点数 (number, 默认 50)
  - `nt`: 时间步数 (number, Crank-Nicolson 方法需要)
  - `r`: 稳定性参数 r = α*dt/dx² (number, FTCS 需 ≤ 0.5)

**返回**: `x, t, u` (空间网格, 时间网格, 解矩阵)

```lua
-- 一维热传导：初始正弦波逐渐衰减
local x, t, u = pde.heat1d(
    0.1,  -- 扩散系数
    function(x) return math.sin(math.pi * x) end,  -- 初始条件
    {
        left = {type = "dirichlet", value = 0},
        right = {type = "dirichlet", value = 0}
    },
    {0, 1},   -- 空间区间
    {0, 0.5}, -- 时间区间
    {nx = 50, method = "ftcs"}
)

-- 解的访问：u[n][i] 是第 n 个时间步、第 i 个空间点的值
print("初始值:", u[1][25])
print("最终值:", u[#t][25])
```

#### pde.heat2d(alpha, ic, bc, bounds, t_span, options)
求解二维热传导方程：∂u/∂t = α * (∂²u/∂x² + ∂²u/∂y²)

使用 ADI（交替方向隐式）方法，无条件稳定。

**参数**:
- `ic`: 初始条件函数 `function(x, y) -> number`
- `bc`: 边界条件表 `{left, right, bottom, top}`
- `bounds`: 区域边界 `{ax, bx, ay, by}`

**返回**: `x, y, t, u` (x网格, y网格, 时间网格, 解)

```lua
local x, y, t, u = pde.heat2d(
    0.1,
    function(x, y) return math.sin(math.pi*x) * math.sin(math.pi*y) end,
    {
        left = {type = "dirichlet", value = 0},
        right = {type = "dirichlet", value = 0},
        bottom = {type = "dirichlet", value = 0},
        top = {type = "dirichlet", value = 0}
    },
    {0, 1, 0, 1},
    {0, 0.1},
    {nx = 30, ny = 30, nt = 50}
)

-- 解的访问：u[n][i][j] 是时间步 n、空间点 (i,j) 的值
```

### 双曲型方程

双曲型方程描述波动传播问题，如声波、电磁波等。

#### pde.wave1d(c, ic_u, ic_v, bc, x_span, t_span, options)
求解一维波动方程：∂²u/∂t² = c² * ∂²u/∂x²

**参数**:
- `c`: 波速 (number)
- `ic_u`: 初始位移函数 `function(x) -> number`
- `ic_v`: 初始速度函数 `function(x) -> number` (可选)
- `bc`: 边界条件表
  - `type = "dirichlet"`: 固定边界
  - `type = "neumann"`: 反射边界
  - `type = "absorbing"`: 吸收边界
- `options`:
  - `nx`: 空间网格点数 (number, 默认 100)
  - `cfl`: CFL 数 (number, 默认 0.8，需 ≤ 1)

**返回**: `x, t, u` (空间网格, 时间网格, 解矩阵)

```lua
-- 一维波动：弦振动
local x, t, u = pde.wave1d(
    1.0,  -- 波速
    function(x) return math.sin(math.pi * x) end,  -- 初始位移
    function(x) return 0 end,  -- 初始速度（静止）
    {
        left = {type = "dirichlet", value = 0},
        right = {type = "dirichlet", value = 0}
    },
    {0, 1},   -- 空间区间
    {0, 2},   -- 时间区间（两个周期）
    {nx = 100, cfl = 0.9}
)

-- 解随时间演化
for n = 1, #t, 50 do
    print(string.format("t=%.2f: u(0.5)=%.4f", t[n], u[n][50]))
end
```

#### pde.wave2d(c, ic_u, ic_v, bc, bounds, t_span, options)
求解二维波动方程：∂²u/∂t² = c² * (∂²u/∂x² + ∂²u/∂y²)

```lua
local x, y, t, u = pde.wave2d(
    1.0,
    function(x, y) return math.exp(-50*((x-0.5)^2 + (y-0.5)^2)) end,
    nil,  -- 初始速度为 0
    {
        left = {type = "dirichlet", value = 0},
        right = {type = "dirichlet", value = 0},
        bottom = {type = "dirichlet", value = 0},
        top = {type = "dirichlet", value = 0}
    },
    {0, 1, 0, 1},
    {0, 0.5},
    {nx = 50, ny = 50, cfl = 0.5}
)
```

#### pde.advection1d(a, ic, bc, x_span, t_span, options)
求解一阶对流方程：∂u/∂t + a * ∂u/∂x = 0

**参数**:
- `a`: 对流速度 (number，正值向右传播，负值向左传播)
- `options`:
  - `scheme`: 差分格式 `"upwind"`|`"lax_friedrichs"`|`"lax_wendroff"`|`"beam_warming"` (string, 默认 "upwind")
  - `cfl`: CFL 数 (number, 默认 0.8)

```lua
-- 对流方程：波形平移
local x, t, u = pde.advection1d(
    1.0,  -- 对流速度
    function(x)  -- 初始条件：方波
        if x >= 0.2 and x <= 0.4 then return 1 else return 0 end
    end,
    nil,  -- 无边界条件（周期性）
    {0, 1},
    {0, 0.2},
    {scheme = "lax_wendroff", nx = 100}
)

-- 不同格式的数值耗散比较
for _, scheme in ipairs({"upwind", "lax_friedrichs", "lax_wendroff"}) do
    local x, t, u = pde.advection1d(1.0, ic, nil, {0, 1}, {0, 0.2}, {scheme = scheme})
    print(scheme, "max value:", math.max(table.unpack(u[#t])))
end
```

### 统一接口

#### pde.solve(equation_type, problem_type, ...)
统一求解接口。

**参数**:
- `equation_type`: 方程类型 `"elliptic"`|`"parabolic"`|`"hyperbolic"`
- `problem_type`: 问题类型 `"poisson"`|`"laplace"`|`"heat"`|`"wave"`|`"advection"`

```lua
-- 求解拉普拉斯方程
local u = pde.solve("elliptic", "laplace", bounds, bc, {nx = 30, ny = 30})

-- 求解热传导方程
local x, t, u = pde.solve("parabolic", "heat", 0.1, ic, bc, {0, 1}, {0, 0.1})

-- 求解波动方程
local x, t, u = pde.solve("hyperbolic", "wave", 1.0, ic_u, ic_v, bc, {0, 1}, {0, 1})
```

### 边界条件说明

支持的边界条件类型：

| 类型 | 说明 | 格式 |
|------|------|------|
| `dirichlet` | 固定值边界 | `{type = "dirichlet", value = 0}` |
| `neumann` | 固定导数边界 | `{type = "neumann", value = 0}` |
| `absorbing` | 吸收边界（波动方程） | `{type = "absorbing"}` |

### 稳定性条件

| 方法 | 稳定性条件 |
|------|-----------|
| FTCS 热传导 | r = α*dt/dx² ≤ 0.5 |
| Crank-Nicolson | 无条件稳定 |
| 显式波动方程 | CFL = c*dt/dx ≤ 1 |
| ADI 二维热传导 | 无条件稳定 |

---

## 根求解模块 (root)

### 加载模块

```lua
local root = require("root")
-- 或
local root = require("init").root
```

root 模块用于求解非线性方程组 F(x) = 0。

### 求解方法

#### root.newton(F, x0, options)
牛顿法求解非线性方程组。

**参数**:
- `F`: 函数向量 `function(x) -> table`，返回 `{f1, f2, ...}`
- `x0`: 初始猜测 (table)
- `options`: 选项表
  - `jacobian`: 雅可比矩阵函数 `function(x) -> table (2D)`（可选，默认数值计算）
  - `tol`: 收敛容差 (number, 默认 1e-10)
  - `max_iter`: 最大迭代次数 (number, 默认 100)
  - `verbose`: 是否打印迭代信息 (boolean, 默认 false)

**返回**: `x, converged, iter` (解向量, 是否收敛, 迭代次数)

```lua
-- 求解方程组:
-- x^2 + y^2 = 1
-- x - y = 0
local F = function(x)
    return {x[1]^2 + x[2]^2 - 1, x[1] - x[2]}
end
local x, ok, iter = root.newton(F, {0.5, 0.5})
-- x ≈ {0.707, 0.707}
```

#### root.broyden(F, x0, options)
Broyden 拟牛顿法。不需要显式计算雅可比矩阵，使用秩1更新近似。

```lua
local x, ok, iter = root.broyden(F, {1, 1})
```

#### root.fixed_point(G, x0, options)
不动点迭代求解 x = G(x)。

**参数**:
- `G`: 迭代函数 `function(x) -> table`
- `options.relaxation`: 松弛因子 (number, 默认 1.0，< 1 为低松弛)

```lua
-- 求解 x = cos(x)（一维情况）
local G = function(x) return {math.cos(x[1])} end
local x, ok, iter = root.fixed_point(G, {0.5})
```

#### root.trust_region(F, x0, options)
信赖域 Dogleg 方法。更稳定，适用于困难问题。

**参数**:
- `options.delta`: 初始信赖域半径 (number, 默认 1.0)
- `options.delta_max`: 最大信赖域半径 (number, 默认 10.0)
- `options.eta`: 接受阈值 (number, 默认 0.15)

```lua
local x, ok, iter = root.trust_region(F, {1, 1}, {delta = 0.5})
```

### 统一接口

#### root.find_root(F, x0, options)
统一求解接口。

**参数**:
- `options.method`: 方法名 `"newton"`|`"broyden"`|`"fixed_point"`|`"trust_region"` (string, 默认 "newton")

```lua
local x, ok, iter = root.find_root(F, {1, 1}, {
    method = "broyden",
    tol = 1e-12,
    max_iter = 200
})
```

#### root.solve(F, x0, options)
`root.find_root` 的别名。

#### root.nsolve(F, x0, options)
`root.find_root` 的别名（仿 MATLAB 命名）。

---

## 工具函数

### 常量

```lua
local num = require("init")

num.PI       -- π = 3.141592653589793
num.E        -- e = 2.718281828459045
num.PHI      -- 黄金比例 = 1.618033988749895
num.EPSILON  -- 机器精度 = 1e-15
num.INF      -- 无穷大 = math.huge
```

### 数学函数

```lua
num.sign(x)              -- 符号函数: 1, -1, 或 0
num.isclose(a, b, rel_tol, abs_tol)  -- 判断两数是否接近
```

### 数组统计

```lua
num.sum(t)               -- 求和
num.prod(t)              -- 求积
num.max(t)               -- 最大值
num.min(t)               -- 最小值
num.mean(t)              -- 平均值
num.var(t)               -- 方差
num.std(t)               -- 标准差
```

### 数组生成

```lua
num.linspace(a, b, n)    -- 线性空间: n 个均匀分布的点
num.logspace(a, b, n, base)  -- 对数空间: base^a 到 base^b
```

### 数组操作

```lua
num.dot(a, b)            -- 点积
num.map(t, f)            -- 映射: {f(t[1]), f(t[2]), ...}
num.filter(t, f)         -- 过滤: 保留满足 f(x) 为 true 的元素
```

---

## 错误处理

所有模块使用统一的错误处理机制。

### 错误类型

```lua
local utils = require("utils")

utils.Error.Type.INVALID_INPUT      -- 无效输入
utils.Error.Type.DIMENSION_MISMATCH -- 维度不匹配
utils.Error.Type.SINGULAR_MATRIX    -- 奇异矩阵
utils.Error.Type.NO_CONVERGENCE     -- 未收敛
utils.Error.Type.DIVISION_BY_ZERO   -- 除零
```

### 错误抛出

```lua
utils.Error.invalid_input("参数不能为空")
utils.Error.dimension_mismatch(expected, actual)
utils.Error.singular_matrix("矩阵行列式为零")
utils.Error.no_convergence("达到最大迭代次数")
```

### 示例

```lua
local matrix = require("matrix")

local ok, err = pcall(function()
    local A = matrix.zeros(2, 3)
    local det = A:det()  -- 错误：非方阵
end)

if not ok then
    print("错误: " .. err)
end
```

---

## 完整示例

### 线性方程组求解

```lua
local matrix = require("matrix")

-- 求解方程组:
-- 2x + y - z = 8
-- -3x - y + 2z = -11
-- -2x + y + 2z = -3

local A = matrix.new({
    {2, 1, -1},
    {-3, -1, 2},
    {-2, 1, 2}
})
local b = matrix.new({{8}, {-11}, {-3}})

local x = A:solve(b)
print("x =", x:get(1, 1))  -- x = 2
print("y =", x:get(2, 1))  -- y = 3
print("z =", x:get(3, 1))  -- z = -1
```

### 函数积分

```lua
local integration = require("integration")

-- 计算 ∫sin(x)dx 从 0 到 π
local result = integration.simpson(math.sin, 0, math.pi, 1000)
print("积分结果:", result)  -- ≈ 2.0

-- 使用高精度自适应方法
local result2 = integration.adaptive(math.sin, 0, math.pi, 1e-12)
print("高精度结果:", result2)
```

### 数据插值

```lua
local interpolation = require("interpolation")

-- 已知数据点
local x_data = {0, 1, 2, 3, 4}
local y_data = {0, 1, 4, 9, 16}  -- y = x^2

-- 在 x = 2.5 处插值
local y_linear = interpolation.linear(2.5, x_data, y_data)
local y_spline = interpolation.spline(2.5, x_data, y_data)

print("线性插值:", y_linear)  -- 6.5
print("样条插值:", y_spline)  -- 接近 6.25
```

### 函数优化

```lua
local optimization = require("optimization")

-- 一维优化: min (x-2)^2
local x_min, f_min = optimization.golden_section(
    function(x) return (x-2)^2 end,
    0, 4
)
print("最小值点:", x_min)  -- ≈ 2

-- 多维优化: min x^2 + y^2
local x_opt = optimization.bfgs(
    function(x) return x[1]^2 + x[2]^2 end,
    function(x) return {2*x[1], 2*x[2]} end,
    {5, 5}
)
print("最优解:", x_opt[1], x_opt[2])  -- ≈ 0, 0
```

### 微分方程求解

```lua
local ode = require("ode")

-- 求解 y' = -y, y(0) = 1
-- 解析解: y(t) = e^(-t)
local f = function(t, y) return -y end
local t, y = ode.rk4(f, 0, 1, 2, 0.1)

print("t=2时 y =", y[#y])  -- ≈ e^(-2) ≈ 0.135

-- 谐振子方程组
local f_harmonic = function(t, y)
    return {y[2], -y[1]}  -- y' = v, v' = -y
end
local t, y = ode.rk4(f_harmonic, 0, {1, 0}, 2*math.pi, 0.01)
print("一个周期后 y =", y[#y][1])  -- ≈ 1 (回到初始位置)
```