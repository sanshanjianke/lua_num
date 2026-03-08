(*提示，该项目原目的是为了测试clm5和claude code做的，完全AI完成，没有人工审查，实际使用请慎用。*)

# lua_num - Lua 数值计算库

一个纯 Lua 5.5 实现的数值计算库，提供矩阵运算、向量运算、数值积分、插值、优化和微分方程求解等功能。

## 特性

- **纯 Lua 实现** - 无需外部依赖，兼容 Lua 5.5
- **功能完整** - 涵盖数值计算的主要领域
- **易于使用** - 直观的 API 设计
- **充分测试** - 209 个测试用例，100% 通过率

## 模块概览

| 模块 | 功能 | 状态 |
|------|------|------|
| `matrix` | 矩阵运算、分解、线性方程组求解 | ✅ 完成 |
| `vector` | 向量运算、特殊向量生成 | ✅ 完成 |
| `integration` | 数值积分（辛普森、高斯等） | ✅ 完成 |
| `interpolation` | 插值方法（拉格朗日、样条等） | ✅ 完成 |
| `optimization` | 数值优化（梯度下降、BFGS等） | ✅ 完成 |
| `ode` | 常微分方程求解（欧拉、RK4等） | ✅ 完成 |
| `pde` | 偏微分方程求解（热传导、波动等） | ✅ 完成 |
| `root` | 非线性方程组求解（牛顿法、Broyden等） | ✅ 完成 |
| `statistics` | 统计分析（描述统计、相关性分析、概率分布） | ✅ 完成 |
| `hypothesis` | 假设检验（t检验、卡方检验、非参数检验） | ✅ 完成 |
| `regression` | 回归分析（线性、多项式、岭回归） | ✅ 完成 |
| `resampling` | Bootstrap、Jackknife、置换检验、交叉验证 | ✅ 完成 |

## 快速开始

### 安装

**方式一：单文件版本（推荐）**

使用 `dist/lua_num.lua` 单文件，无需其他依赖：

```lua
local num = dofile("lua_num.lua")
```

**方式二：模块版本**

将 `src` 目录复制到你的项目中，或设置 `package.path`:

```lua
package.path = "path/to/lua_num/src/?.lua;" .. package.path
local num = require("init")
```

### 构建单文件版本

```bash
lua build.lua
```

这将生成 `dist/lua_num.lua`，包含所有模块的完整功能。

### 基本使用

```lua
local num = require("init")

-- 矩阵运算
local A = num.matrix.rand(10, 10)
local det = A:det()
local inv = A:inverse()

-- 向量运算
local v = num.vector.linspace(0, 1, 100)
local n = v:norm()

-- 数值积分
local result = num.integration.simpson(math.sin, 0, math.pi, 1000)
-- result ≈ 2.0

-- 插值
local x = {0, 1, 2, 3}
local y = {0, 1, 4, 9}
local y_interp = num.interpolation.spline(1.5, x, y)

-- 优化
local f = function(x) return x[1]^2 + x[2]^2 end
local grad = function(x) return {2*x[1], 2*x[2]} end
local x_opt = num.optimization.bfgs(f, grad, {1, 1})

-- 微分方程
local f_ode = function(t, y) return -y end
local t, y = num.ode.rk4(f_ode, 0, 1, 1, 0.1)

-- 偏微分方程（一维热传导）
local ic = function(x) return math.sin(math.pi * x) end
local bc = {left = {type = "dirichlet", value = 0}, right = {type = "dirichlet", value = 0}}
local x, t, u = num.pde.heat1d(0.1, ic, bc, {0, 1}, {0, 0.5})
```

## 项目结构

```
lua_num/
├── README.md                      # 项目说明文档 「本文件」
├── PROGRESS.md                    # 开发进度记录
├── build.lua                      # 构建脚本，生成单文件版本
├── run_tests.lua                  # 运行所有测试
├── test_bundle.lua                # 单文件版本测试
│
├── src/                           # 源代码
│   ├── init.lua                   # 主入口，导出所有模块
│   │
│   ├── utils/                     # 工具函数
│   │   ├── init.lua               # 工具模块入口
│   │   ├── constants.lua          # 数学常数（π, e, φ等）
│   │   ├── error.lua              # 错误处理
│   │   ├── validators.lua         # 输入验证
│   │   └── typecheck.lua          # 类型检查
│   │
│   ├── matrix/                    # 矩阵模块
│   │   ├── init.lua               # 矩阵模块入口
│   │   ├── matrix.lua             # 矩阵类定义
│   │   ├── basic_ops.lua          # 基本运算（加减乘、转置）
│   │   ├── advanced_ops.lua       # 高级运算（行列式、求逆）
│   │   ├── decompositions.lua     # 矩阵分解（LU、QR、Cholesky）
│   │   ├── solvers.lua            # 线性方程组求解
│   │   └── special_matrices.lua   # 特殊矩阵（零矩阵、单位矩阵等）
│   │
│   ├── vector/                    # 向量模块
│   │   ├── init.lua               # 向量模块入口
│   │   ├── vector.lua             # 向量类定义
│   │   ├── basic_ops.lua          # 基本运算（加减、点积）
│   │   ├── advanced_ops.lua       # 高级运算（范数、归一化）
│   │   └── special_vectors.lua    # 特殊向量（linspace、logspace等）
│   │
│   ├── integration/               # 数值积分模块
│   │   ├── init.lua               # 积分模块入口
│   │   ├── basic_integration.lua  # 基本方法（梯形、辛普森）
│   │   ├── advanced_integration.lua # 高级方法（自适应、龙贝格、高斯）
│   │   └── multi_integration.lua  # 多重积分（二重、三重、蒙特卡洛）
│   │
│   ├── interpolation/             # 插值模块
│   │   ├── init.lua               # 插值模块入口
│   │   ├── basic_interpolation.lua # 基本方法（线性、拉格朗日、牛顿）
│   │   ├── advanced_interpolation.lua # 高级方法（三次样条）
│   │   └── multi_interpolation.lua # 多维插值（双线性、双三次、RBF）
│   │
│   ├── optimization/              # 优化模块
│   │   ├── init.lua               # 优化模块入口
│   │   ├── basic_optimization.lua # 一维优化（黄金分割、抛物线）
│   │   └── gradient_methods.lua   # 梯度方法（梯度下降、BFGS、共轭梯度）
│   │
│   ├── ode/                       # 常微分方程模块
│   │   ├── init.lua               # ODE模块入口
│   │   ├── basic_methods.lua      # 基本方法（欧拉、Heun、中点）
│   │   └── advanced_methods.lua   # 高级方法（RK4、RK45自适应）
│   │
│   ├── pde/                       # 偏微分方程模块
│   │   ├── init.lua               # PDE模块入口
│   │   ├── elliptic.lua           # 椭圆型方程（泊松、拉普拉斯）
│   │   ├── parabolic.lua          # 抛物型方程（热传导）
│   │   └── hyperbolic.lua         # 双曲型方程（波动、对流）
│   │
│   ├── root_finding/              # 根求解模块
│   │   ├── init.lua               # 根求解模块入口
│   │   └── multi_root.lua         # 多变量求根（牛顿、Broyden、信赖域）
│   │
│   └── statistics/                # 统计学模块
│       ├── init.lua               # 统计模块入口
│       ├── descriptive.lua        # 描述性统计（均值、方差、偏度、峰度）
│       ├── correlation.lua        # 相关性分析（Pearson、Spearman、Kendall）
│       ├── distributions.lua      # 概率分布（正态、t、χ²、F、Gamma等）
│       ├── hypothesis.lua         # 假设检验（t检验、卡方检验、非参数检验）
│       ├── regression.lua         # 回归分析（线性、多项式、岭回归）
│       └── resampling.lua         # Bootstrap、Jackknife、置换检验、交叉验证
│
├── tests/                         # 测试文件（15个测试文件，209个测试用例）
├── dist/                          # 发布版本
│   └── lua_num.lua               # 单文件版本（417KB）
├── examples/                      # 示例代码
├── benchmarks/                    # 性能测试
├── docs/                          # 文档
└── bin/                           # Lua 可执行文件
```

## API 文档

### 矩阵模块 (matrix)

```lua
local matrix = require("matrix")

-- 创建矩阵
local A = matrix.new({{1, 2}, {3, 4}})  -- 从二维数组
local B = matrix.zeros(3, 3)             -- 零矩阵
local I = matrix.eye(3)                  -- 单位矩阵
local R = matrix.rand(3, 3)              -- 随机矩阵

-- 基础运算
local C = A + B        -- 加法
local D = A * B        -- 矩阵乘法
local E = A:transpose() -- 转置

-- 高级运算
local det = A:det()        -- 行列式
local inv = A:inverse()    -- 求逆
local L, U, P = A:lu()     -- LU 分解
local Q, R = A:qr()        -- QR 分解

-- 线性方程组
local x = A:solve(b)       -- 求解 Ax = b
```

### 向量模块 (vector)

```lua
local vector = require("vector")

-- 创建向量
local v1 = vector.new({1, 2, 3})
local v2 = vector.linspace(0, 1, 100)  -- 线性空间
local v3 = vector.zeros(10)             -- 零向量

-- 运算
local v = v1 + v2          -- 加法
local dot = v1:dot(v2)     -- 点积
local n = v1:norm()        -- 范数
local u = v1:normalize()   -- 归一化
```

### 积分模块 (integration)

```lua
local integration = require("integration")

local f = function(x) return math.sin(x) end

-- 梯形法
local r1 = integration.trapezoidal(f, 0, math.pi, 100)

-- 辛普森法
local r2 = integration.simpson(f, 0, math.pi, 100)

-- 自适应辛普森
local r3 = integration.adaptive_simpson(f, 0, math.pi, 1e-8)

-- 高斯-勒让德积分
local r4 = integration.gauss_legendre(f, 0, math.pi, 5)
```

### 插值模块 (interpolation)

```lua
local interpolation = require("interpolation")

local x = {0, 1, 2, 3, 4}
local y = {0, 1, 4, 9, 16}

-- 线性插值
local y1 = interpolation.linear(2.5, x, y)

-- 拉格朗日插值
local y2 = interpolation.lagrange(2.5, x, y)

-- 牛顿插值
local y3 = interpolation.newton(2.5, x, y)

-- 三次样条插值
local y4 = interpolation.spline(2.5, x, y)
```

### 优化模块 (optimization)

```lua
local optimization = require("optimization")

-- 一维优化
local f1 = function(x) return (x-2)^2 end
local x_opt = optimization.golden_section(f1, 0, 4)

-- 多维优化
local f2 = function(x) return x[1]^2 + x[2]^2 end
local grad = function(x) return {2*x[1], 2*x[2]} end

-- 梯度下降
local x1 = optimization.gradient_descent(f2, grad, {1, 1})

-- BFGS
local x2 = optimization.bfgs(f2, grad, {1, 1})

-- 共轭梯度法
local x3 = optimization.conjugate_gradient(f2, grad, {1, 1})
```

### 微分方程模块 (ode)

```lua
local ode = require("ode")

-- 定义微分方程 y' = f(t, y)
local f = function(t, y) return -y end

-- 欧拉方法
local t1, y1 = ode.euler(f, 0, 1, 1, 0.01)

-- RK4 方法
local t2, y2 = ode.rk4(f, 0, 1, 1, 0.1)

-- 自适应 RK45
local t3, y3 = ode.rk45(f, 0, 1, 1, {tol = 1e-6})

-- 方程组（谐振子）
local f_sys = function(t, y) return {y[2], -y[1]} end
local t4, y4 = ode.rk4(f_sys, 0, {1, 0}, 10, 0.01)
```

### 偏微分方程模块 (pde)

```lua
local pde = require("pde")

-- 一维热传导方程
local ic = function(x) return math.sin(math.pi * x) end  -- 初始条件
local bc = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0}
}
local x, t, u = pde.heat1d(0.1, ic, bc, {0, 1}, {0, 0.5}, {nx = 50})

-- 一维波动方程
local ic_u = function(x) return math.sin(math.pi * x) end
local ic_v = function(x) return 0 end
local x2, t2, u2 = pde.wave1d(1.0, ic_u, ic_v, bc, {0, 1}, {0, 2}, {nx = 100})

-- 二维泊松方程
local bounds = {0, 1, 0, 1}
local bc_poisson = {
    left = {type = "dirichlet", value = 0},
    right = {type = "dirichlet", value = 0},
    bottom = {type = "dirichlet", value = 0},
    top = {type = "dirichlet", value = 1}
}
local u_poisson, info = pde.poisson(-2, bounds, bc_poisson, {nx = 50, ny = 50})

-- 对流方程
local x3, t3, u3 = pde.advection1d(1.0, ic, nil, {0, 1}, {0, 0.2}, {scheme = "lax_wendroff"})
```

### 根求解模块 (root)

```lua
local root = require("root")

-- 定义方程组 F(x) = 0
-- x^2 + y^2 = 1
-- x - y = 0
local F = function(x)
    return {x[1]^2 + x[2]^2 - 1, x[1] - x[2]}
end

-- 牛顿法
local x1, ok1 = root.newton(F, {0.5, 0.5})

-- Broyden方法（无需雅可比矩阵）
local x2, ok2 = root.broyden(F, {1, 1})

-- 统一接口
local x3, ok3 = root.find_root(F, {0.5, 0.5}, {method = "newton"})
```

### 统计学模块 (statistics)

```lua
local statistics = require("statistics")

local x = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

-- 描述性统计
local m = statistics.mean(x)           -- 均值
local med = statistics.median(x)       -- 中位数
local s = statistics.std(x)            -- 标准差
local v = statistics.var(x)            -- 方差
local q1, q3 = statistics.quartile(x)  -- 四分位数
local iqr = statistics.iqr(x)          -- 四分位距
local skew = statistics.skewness(x)    -- 偏度
local kurt = statistics.kurtosis(x)    -- 峰度

-- 百分位数
local p90 = statistics.percentile(x, 90)  -- 第90百分位数

-- 其他均值类型
local gm = statistics.geomean({2, 8})     -- 几何均值 = 4
local hm = statistics.harmean({1, 4})     -- 调和均值 = 1.6

-- 截尾均值（去除两端各10%）
local tm = statistics.trimmean(x, 0.1)

-- 综合描述
local desc = statistics.describe(x)    -- 返回完整统计摘要

-- 相关性分析
local y = {2, 4, 6, 8, 10}
local cov = statistics.cov(x, y)       -- 协方差
local r = statistics.corr(x, y)        -- 皮尔逊相关系数
local rho = statistics.spearman(x, y)  -- 斯皮尔曼等级相关
local tau = statistics.kendall(x, y)   -- 肯德尔相关系数

-- 直方图
local counts, edges = statistics.histogram(x, 5)

-- 概率分布
-- 正态分布
local pdf = statistics.normal.pdf(0)        -- PDF(0) ≈ 0.3989
local cdf = statistics.normal.cdf(1.96)     -- CDF(1.96) ≈ 0.975
local q = statistics.normal.quantile(0.975) -- quantile ≈ 1.96
local samples = statistics.normal.sample(100, 0, 1)  -- 生成100个样本

-- t分布
local t_q = statistics.t.quantile(0.975, 10)  -- t_{0.975, 10}

-- 卡方分布
local chi2_q = statistics.chi2.quantile(0.95, 5)  -- χ²_{0.95, 5}

-- F分布
local f_q = statistics.f.quantile(0.95, 5, 10)  -- F_{0.95, 5, 10}

-- 其他分布: uniform, exponential, gamma, beta, binomial, poisson, geometric

-- 假设检验
-- 单样本 t 检验
local t, p, df = statistics.t_test_one_sample(x, 5)  -- 检验均值是否为 5

-- 双样本 t 检验
local t2, p2, df2 = statistics.t_test_two_sample(x, y)

-- 配对 t 检验
local t3, p3, df3 = statistics.t_test_two_sample(before, after, 0, "two.sided", true)

-- Welch's t 检验（异方差）
local t4, p4, df4 = statistics.welch_test(x, y)

-- F 检验（方差齐性）
local f, p_f, df1, df2 = statistics.var_test(x, y)

-- 卡方拟合优度检验
local chi2, p_chi, df_chi = statistics.chisq_test_goodness({10, 15, 12, 8})

-- 卡方独立性检验
local chi2_2, p_chi2, df_chi2 = statistics.chisq_test_independence({
    {10, 20, 30},
    {15, 25, 35}
})

-- 非参数检验
local w, p_w = statistics.wilcoxon_signed_rank(x, 5)  -- 符号秩检验
local u, p_u = statistics.mann_whitney_u(x, y)        -- U 检验

-- 置信区间
local lower, upper = statistics.ci_mean(x, 0.95)           -- 均值置信区间
local lower2, upper2 = statistics.ci_mean_diff(x, y, 0.95) -- 均值差置信区间
local lower3, upper3 = statistics.ci_proportion(50, 100)   -- 比例置信区间

-- 效应量
local d1 = statistics.cohens_d_one_sample(x, 5)   -- 单样本 Cohen's d
local d2 = statistics.cohens_d_two_sample(x, y)   -- 双样本 Cohen's d

-- 回归分析
-- 简单线性回归
local model = statistics.linear_regression(x, y)
print("斜率:", model.slope)
print("截距:", model.intercept)
print("R²:", model.R2)
print("残差标准误:", model.s)

-- 多元线性回归
local X = {{1, 2}, {2, 3}, {3, 4}, {4, 5}}  -- 设计矩阵
local model2 = statistics.multiple_regression(X, y)

-- 多项式回归
local model3 = statistics.polynomial_regression(x, y, 2)  -- 二次多项式

-- 岭回归（带正则化）
local model4 = statistics.ridge(X, y, 0.1)  -- lambda = 0.1

-- 预测
local predictions = statistics.regression.predict(model, {6, 7, 8})

-- 模型诊断
local diag = statistics.regression.diagnostics(model, y)
print("Durbin-Watson:", diag.durbin_watson)

-- Bootstrap 和重抽样
-- Bootstrap 置信区间
local data = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local lower, upper = statistics.bootstrap_ci(data, "mean", 1000, 0.95)
-- 支持多种方法: "percentile", "basic", "normal", "bca"

-- Bootstrap 自定义统计量
local result = statistics.bootstrap(data, function(t)
    return statistics.median(t)
end, 1000)
print("Bootstrap SE:", result.se)
print("Bias:", result.bias)

-- Jackknife 分析
local jk = statistics.jackknife(data, "var")
print("Jackknife SE:", jk.se)
print("Bias-corrected:", jk.bias_corrected)

-- 置换检验（比较两组）
local group1 = {1, 2, 3, 4, 5}
local group2 = {6, 7, 8, 9, 10}
local stat, p = statistics.permutation_test(group1, group2, nil, 1000)

-- 配对样本置换检验
local before = {85, 78, 82, 88, 76}
local after = {90, 82, 86, 92, 80}
local stat2, p2 = statistics.permutation_test_paired(before, after)

-- K折交叉验证
local cv_data = {y = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}}
local mean_err, std_err = statistics.cross_validation(cv_data, 5,
    function(train_idx, test_idx)
        -- 返回预测函数
        local sum = 0
        for _, i in ipairs(train_idx) do sum = sum + cv_data.y[i] end
        local mean = sum / #train_idx
        return function(x) return mean end
    end)

-- 蒙特卡洛模拟
local mc_mean, mc_se = statistics.monte_carlo(10000, function()
    local x, y = math.random(), math.random()
    return (x*x + y*y <= 1) and 1 or 0
end)
print("π ≈", 4 * mc_mean)
```

## 运行测试

```bash
# 运行所有测试
./bin/lua55.exe run_tests.lua

# 运行单个测试
./bin/lua55.exe tests/test_matrix.lua
```

## 性能基准

| 操作 | 规模 | 耗时 |
|------|------|------|
| 矩阵乘法 | 100x100 | 35 ms |
| 矩阵求逆 | 30x30 | 0.3 ms |
| 线性求解 | 100x100 | 3.5 ms |
| 辛普森积分 | 1000 子区间 | 0.11 ms |
| RK4 求解 | 100 步 | 0.03 ms |

## 后续规划

- [ ] 性能优化（矩阵乘法循环展开、分块算法）
- [ ] 特征值分解
- [ ] SVD 分解
- [ ] LuaJIT FFI 调用 BLAS/LAPACK

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 参考

- [Numerical Recipes](https://numerical.recipes/)
- [LAPACK](https://www.netlib.org/lapack/)
- [NumPy](https://numpy.org/)
- [SciPy](https://scipy.org/)
