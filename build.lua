-- lua_num 构建脚本
-- 将所有模块合并成单个文件
-- 用法: lua build.lua

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Cannot open file: " .. path)
    end
    local content = file:read("*all")
    file:close()
    return content
end

local function strip_return(content)
    -- 保留 return 语句，不做处理
    return content
end

-- 定义模块加载顺序（按依赖关系，叶子节点优先）
local modules = {
    -- Utils (无依赖)
    "utils.constants",
    "utils.error",
    "utils.validators",
    "utils.typecheck",

    -- Matrix (依赖 utils)
    "matrix.matrix",
    "matrix.basic_ops",
    "matrix.advanced_ops",
    "matrix.decompositions",
    "matrix.solvers",
    "matrix.special_matrices",

    -- Vector (依赖 utils)
    "vector.vector",
    "vector.basic_ops",
    "vector.advanced_ops",
    "vector.special_vectors",

    -- Integration (依赖 utils)
    "integration.basic_integration",
    "integration.advanced_integration",
    "integration.multi_integration",

    -- Interpolation (依赖 utils)
    "interpolation.basic_interpolation",
    "interpolation.advanced_interpolation",
    "interpolation.multi_interpolation",

    -- Optimization (依赖 utils, matrix)
    "optimization.basic_optimization",
    "optimization.gradient_methods",

    -- ODE (依赖 utils, matrix)
    "ode.basic_methods",
    "ode.advanced_methods",

    -- Root finding (依赖 utils, matrix)
    "root_finding.multi_root",

    -- PDE (依赖 utils, matrix)
    "pde.elliptic",
    "pde.parabolic",
    "pde.hyperbolic",

    -- Statistics (依赖 utils)
    "statistics.descriptive",
    "statistics.correlation",
    "statistics.distributions",
    "statistics.hypothesis",
    "statistics.regression",
    "statistics.resampling",
}

-- 定义 utils.init 的内容（需要在其他模块之前加载）
local utils_init_content = [[
local utils = {}
utils.constants = require("utils.constants")
utils.Error = require("utils.error")
utils.validators = require("utils.validators")
utils.typecheck = require("utils.typecheck")
utils.pi = utils.constants.pi
utils.e = utils.constants.e
utils.phi = utils.constants.phi
utils.gamma = utils.constants.gamma
utils.epsilon = utils.constants.epsilon
utils.tiny = utils.constants.tiny
utils.huge = utils.constants.huge
utils.deg2rad = utils.constants.deg2rad
utils.rad2deg = utils.constants.rad2deg
utils.assert_matrix = utils.validators.assert_matrix
utils.assert_square_matrix = utils.validators.assert_square_matrix
utils.assert_same_dimensions = utils.validators.assert_same_dimensions
utils.assert_can_multiply = utils.validators.assert_can_multiply
function utils.abs(x) return math.abs(x) end
function utils.sign(x) if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end end
function utils.max(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] > m then m = v[i] end end return m end
function utils.min(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] < m then m = v[i] end end return m end
function utils.dot(v1, v2) if #v1 ~= #v2 then utils.Error.dimension_mismatch(#v1, #v2) end local s = 0 for i = 1, #v1 do s = s + v1[i] * v2[i] end return s end
function utils.norm(v) local s = 0 for i = 1, #v do s = s + v[i] * v[i] end return math.sqrt(s) end
return utils
]]

-- 收集所有模块内容
local module_contents = {}

print("收集模块文件...")

for _, mod_name in ipairs(modules) do
    local path = "src/" .. mod_name:gsub("%.", "/") .. ".lua"
    print("  读取: " .. path)
    local content = read_file(path)
    content = strip_return(content)
    module_contents[mod_name] = content
end

print("\n生成合并文件...")

-- 创建 dist 目录
os.execute("mkdir dist 2>nul || mkdir -p dist")

-- 打开输出文件
local out = io.open("dist/lua_num.lua", "w")
if not out then
    error("Cannot create output file")
end

-- 写入文件头
out:write([[
-- lua_num - Lua 数值计算库
-- 单文件版本
-- 版本: 1.0.0
-- 生成时间: ]] .. os.date("%Y-%m-%d %H:%M:%S") .. [[
--
-- 用法:
--   local num = dofile("lua_num.lua")
--   local A = num.matrix.rand(10, 10)
--   local det = A:det()
--
-- 许可证: MIT License

local lua_num = {}

-- 模块缓存
local _loaded = {}

-- 自定义 require 函数（延迟加载）
local _module_loaders = {}
local function _require(name)
    if _loaded[name] then
        return _loaded[name]
    end
    local loader = _module_loaders[name]
    if loader then
        _loaded[name] = loader()
        return _loaded[name]
    end
    error("Module not found: " .. name)
end

-- 替换全局 require
local _original_require = require
require = _require

]])

-- 写入所有模块加载器
out:write("-- ===========================================================================\n")
out:write("-- 模块定义\n")
out:write("-- ===========================================================================\n\n")

-- 先写入 utils.init 加载器
out:write("-- 模块: utils.init\n")
out:write("_module_loaders[\"utils.init\"] = function()\n")
for line in utils_init_content:gmatch("[^\n]*") do
    out:write("    " .. line .. "\n")
end
out:write("end\n\n")

for _, mod_name in ipairs(modules) do
    local var_name = mod_name:gsub("%.", "_")
    out:write("-- 模块: " .. mod_name .. "\n")
    out:write("_module_loaders[\"" .. mod_name .. "\"] = function()\n")

    -- 写入模块内容（缩进）
    local content = module_contents[mod_name]
    for line in content:gmatch("[^\n]*") do
        out:write("    " .. line .. "\n")
    end

    out:write("end\n\n")
end

-- 写入模块初始化
out:write([[
-- ===========================================================================
-- 模块初始化
-- ===========================================================================

-- 预加载所有模块
local function preload_modules()
]])

for _, mod_name in ipairs(modules) do
    out:write("    _require(\"" .. mod_name .. "\")\n")
end

out:write([[
end

preload_modules()

-- 恢复原始 require
require = _original_require

-- Utils 模块封装
local utils = {}
utils.constants = _loaded["utils.constants"]
utils.Error = _loaded["utils.error"]
utils.validators = _loaded["utils.validators"]
utils.typecheck = _loaded["utils.typecheck"]
utils.pi = utils.constants.pi
utils.e = utils.constants.e
utils.phi = utils.constants.phi
utils.gamma = utils.constants.gamma
utils.epsilon = utils.constants.epsilon
utils.tiny = utils.constants.tiny
utils.huge = utils.constants.huge
utils.deg2rad = utils.constants.deg2rad
utils.rad2deg = utils.constants.rad2deg
utils.assert_matrix = utils.validators.assert_matrix
utils.assert_square_matrix = utils.validators.assert_square_matrix
utils.assert_same_dimensions = utils.validators.assert_same_dimensions
utils.assert_can_multiply = utils.validators.assert_can_multiply
function utils.abs(x) return math.abs(x) end
function utils.sign(x) if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end end
function utils.max(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] > m then m = v[i] end end return m end
function utils.min(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] < m then m = v[i] end end return m end
function utils.dot(v1, v2) if #v1 ~= #v2 then utils.Error.dimension_mismatch(#v1, #v2) end local s = 0 for i = 1, #v1 do s = s + v1[i] * v2[i] end return s end
function utils.norm(v) local s = 0 for i = 1, #v do s = s + v[i] * v[i] end return math.sqrt(s) end
_loaded["utils.init"] = utils

-- Matrix 模块封装
local matrix = {}
local Matrix = _loaded["matrix.matrix"]
local special_matrices = _loaded["matrix.special_matrices"]
matrix.new = Matrix.new
matrix.Matrix = Matrix
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
matrix.identity = matrix.eye
setmetatable(matrix, { __call = function(_, ...) return Matrix.new(...) end })
_loaded["matrix.init"] = matrix

-- Vector 模块封装
local vector = {}
local Vector = _loaded["vector.vector"]
vector.new = Vector.new
vector.Vector = Vector
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
vector.triple_product = Vector.triple_product
vector.double_cross = Vector.double_cross
vector.zero = vector.zeros
vector.identity = vector.unit
setmetatable(vector, { __call = function(_, ...) return Vector.new(...) end })
_loaded["vector.init"] = vector

-- Integration 模块封装
local integration = {}
local basic_int = _loaded["integration.basic_integration"]
local advanced_int = _loaded["integration.advanced_integration"]
local multi_int = _loaded["integration.multi_integration"]
integration.trapezoidal = basic_int.trapezoidal
integration.simpson = basic_int.simpson
integration.midpoint = basic_int.midpoint
integration.left_endpoint = basic_int.left_endpoint
integration.right_endpoint = basic_int.right_endpoint
integration.adaptive = advanced_int.adaptive
integration.romberg = advanced_int.romberg
integration.gauss = advanced_int.gauss
integration.composite_gauss = advanced_int.composite_gauss
integration.singular = advanced_int.singular
integration.double = multi_int.double
integration.double_integral = multi_int.double_integral
integration.triple = multi_int.triple
integration.triple_integral = multi_int.triple_integral
integration.monte_carlo = multi_int.monte_carlo
integration.monte_carlo_region = multi_int.monte_carlo_region
integration.trap = integration.trapezoidal
integration.adaptive_simpson = integration.adaptive
integration.gauss_legendre = integration.gauss
function integration.integrate(f, a, b, options)
    options = options or {}
    local method = options.method or "simpson"
    local methods = {
        trapezoidal = function() return integration.trapezoidal(f, a, b, options.n) end,
        trap = function() return integration.trapezoidal(f, a, b, options.n) end,
        simpson = function() return integration.simpson(f, a, b, options.n) end,
        midpoint = function() return integration.midpoint(f, a, b, options.n) end,
        adaptive = function() return integration.adaptive(f, a, b, options.tol, options.max_iter) end,
        romberg = function() return integration.romberg(f, a, b, options.n, options.tol) end,
        gauss = function() return integration.gauss(f, a, b, options.n) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["integration.init"] = integration

-- Interpolation 模块封装
local interpolation = {}
local basic_interp = _loaded["interpolation.basic_interpolation"]
local advanced_interp = _loaded["interpolation.advanced_interpolation"]
local multi_interp = _loaded["interpolation.multi_interpolation"]
interpolation.linear = basic_interp.linear
interpolation.lagrange = basic_interp.lagrange
interpolation.newton = basic_interp.newton
interpolation.piecewise_linear = basic_interp.piecewise_linear
interpolation.spline = advanced_interp.spline
interpolation.spline_clamped = advanced_interp.spline_clamped
interpolation.spline_derivative = advanced_interp.spline_derivative
interpolation.spline_derivative2 = advanced_interp.spline_derivative2
interpolation.bilinear = multi_interp.bilinear
interpolation.bicubic = multi_interp.bicubic
interpolation.rbf = multi_interp.rbf
interpolation.idw = multi_interp.idw
interpolation.nearest_neighbor = multi_interp.nearest_neighbor
interpolation.poly = interpolation.lagrange
interpolation.natural_spline = interpolation.spline
function interpolation.interpolate(x, x_data, y_data, options)
    options = options or {}
    local method = options.method or "linear"
    local methods = {
        linear = function() return interpolation.linear(x, x_data, y_data) end,
        lagrange = function() return interpolation.lagrange(x, x_data, y_data) end,
        newton = function() return interpolation.newton(x, x_data, y_data) end,
        spline = function() return interpolation.spline(x, x_data, y_data) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["interpolation.init"] = interpolation

-- Optimization 模块封装
local optimization = {}
local basic_opt = _loaded["optimization.basic_optimization"]
local gradient_opt = _loaded["optimization.gradient_methods"]
optimization.golden_section = basic_opt.golden_section
optimization.parabolic_interpolation = basic_opt.parabolic_interpolation
optimization.fibonacci_search = basic_opt.fibonacci_search
optimization.bisection = basic_opt.bisection
optimization.gradient_descent = gradient_opt.gradient_descent
optimization.newton = gradient_opt.newton
optimization.bfgs = gradient_opt.bfgs
optimization.conjugate_gradient = gradient_opt.conjugate_gradient
optimization.stochastic_gradient_descent = gradient_opt.stochastic_gradient_descent
optimization.gs = optimization.golden_section
optimization.gd = optimization.gradient_descent
optimization.sgd = optimization.stochastic_gradient_descent
optimization.cg = optimization.conjugate_gradient
function optimization.optimize(f, x0, options)
    options = options or {}
    if type(x0) == "number" then
        local a = options.a or x0 - 1
        local b = options.b or x0 + 1
        return optimization.golden_section(f, a, b, options.tol)
    else
        if not options.grad then error("Gradient required") end
        return optimization.bfgs(f, options.grad, x0, options)
    end
end
function optimization.minimize_1d(f, a, b, options) return optimization.golden_section(f, a, b, options and options.tol) end
function optimization.minimize(f, grad, x0, options) return optimization.bfgs(f, grad, x0, options) end
_loaded["optimization.init"] = optimization

-- ODE 模块封装
local ode = {}
local basic_ode = _loaded["ode.basic_methods"]
local advanced_ode = _loaded["ode.advanced_methods"]
ode.euler = basic_ode.euler
ode.heun = basic_ode.heun
ode.midpoint = basic_ode.midpoint
ode.runge_kutta4 = advanced_ode.runge_kutta4
ode.rk4 = advanced_ode.runge_kutta4
ode.rk45 = advanced_ode.rk45
ode.improved_euler = ode.heun
function ode.solve(f, t_span, y0, options)
    options = options or {}
    local method = options.method or "rk4"
    local t0, t_end = t_span[1], t_span[2]
    local h = options.h
    local methods = {
        euler = function() return ode.euler(f, t0, y0, t_end, h, options) end,
        heun = function() return ode.heun(f, t0, y0, t_end, h, options) end,
        rk4 = function() return ode.rk4(f, t0, y0, t_end, h, options) end,
        rk45 = function() return ode.rk45(f, t0, y0, t_end, options) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["ode.init"] = ode

-- Root finding 模块封装
local root = {}
local multi_root = _loaded["root_finding.multi_root"]
root.newton = multi_root.newton
root.broyden = multi_root.broyden
root.fixed_point = multi_root.fixed_point
root.trust_region = multi_root.trust_region
root.find_root = multi_root.find_root
root.solve = multi_root.solve
root.nsolve = multi_root.nsolve
_loaded["root_finding.init"] = root

-- PDE 模块封装
local pde = {}
local elliptic = _loaded["pde.elliptic"]
local parabolic = _loaded["pde.parabolic"]
local hyperbolic = _loaded["pde.hyperbolic"]
pde.poisson = elliptic.poisson
pde.laplace = elliptic.laplace
pde.interpolate = elliptic.interpolate
pde.heat1d = parabolic.heat1d
pde.heat2d = parabolic.heat2d
pde.wave1d = hyperbolic.wave1d
pde.wave2d = hyperbolic.wave2d
pde.advection1d = hyperbolic.advection1d
function pde.solve(eq_type, prob_type, ...)
    if eq_type == "elliptic" then
        if prob_type == "poisson" then return elliptic.poisson(...)
        elseif prob_type == "laplace" then return elliptic.laplace(...) end
    elseif eq_type == "parabolic" then
        return parabolic.heat1d(...)
    elseif eq_type == "hyperbolic" then
        if prob_type == "wave" then return hyperbolic.wave1d(...)
        else return hyperbolic.advection1d(...) end
    end
    error("Unknown type: " .. eq_type .. "/" .. prob_type)
end
_loaded["pde.init"] = pde

-- Statistics 模块封装
local statistics = {}
local descriptive = _loaded["statistics.descriptive"]
local correlation = _loaded["statistics.correlation"]
local distributions = _loaded["statistics.distributions"]
local hypothesis = _loaded["statistics.hypothesis"]
local regression = _loaded["statistics.regression"]
local resampling = _loaded["statistics.resampling"]

-- 描述性统计
statistics.mean = descriptive.mean
statistics.median = descriptive.median
statistics.mode = descriptive.mode
statistics.var = descriptive.var
statistics.std = descriptive.std
statistics.percentile = descriptive.percentile
statistics.quartile = descriptive.quartile
statistics.quantile = descriptive.quantile
statistics.range = descriptive.range
statistics.iqr = descriptive.iqr
statistics.skewness = descriptive.skewness
statistics.kurtosis = descriptive.kurtosis
statistics.moment = descriptive.moment
statistics.geomean = descriptive.geomean
statistics.harmean = descriptive.harmean
statistics.trimmean = descriptive.trimmean
statistics.mad = descriptive.mad
statistics.sem = descriptive.sem
statistics.var_pop = descriptive.var_pop
statistics.std_pop = descriptive.std_pop
statistics.describe = descriptive.describe
statistics.histogram = descriptive.histogram
statistics.frequency = descriptive.frequency

-- 相关性分析
statistics.cov = correlation.cov
statistics.cov_pop = correlation.cov_pop
statistics.corr = correlation.corr
statistics.corrcoef = correlation.corrcoef
statistics.spearman = correlation.spearman
statistics.kendall = correlation.kendall

-- 概率分布
statistics.dist = distributions
statistics.normal = distributions.normal
statistics.uniform = distributions.uniform
statistics.exponential = distributions.exponential
statistics.t = distributions.t
statistics.chi2 = distributions.chi2
statistics.f = distributions.f
statistics.gamma = distributions.gamma
statistics.beta = distributions.beta
statistics.bernoulli = distributions.bernoulli
statistics.binomial = distributions.binomial
statistics.poisson = distributions.poisson
statistics.geometric = distributions.geometric
statistics.seed = distributions.seed

-- 假设检验
statistics.t_test_one_sample = hypothesis.t_test_one_sample
statistics.t_test_two_sample = hypothesis.t_test_two_sample
statistics.welch_test = hypothesis.welch_test
statistics.z_test_one_sample = hypothesis.z_test_one_sample
statistics.var_test = hypothesis.var_test
statistics.chisq_test_goodness = hypothesis.chisq_test_goodness
statistics.chisq_test_independence = hypothesis.chisq_test_independence
statistics.wilcoxon_signed_rank = hypothesis.wilcoxon_signed_rank
statistics.mann_whitney_u = hypothesis.mann_whitney_u
statistics.ci_mean = hypothesis.ci_mean
statistics.ci_mean_diff = hypothesis.ci_mean_diff
statistics.ci_proportion = hypothesis.ci_proportion
statistics.cohens_d_one_sample = hypothesis.cohens_d_one_sample
statistics.cohens_d_two_sample = hypothesis.cohens_d_two_sample

-- 回归分析
statistics.lm = regression.linear
statistics.linear_regression = regression.linear
statistics.multiple_regression = regression.multiple
statistics.polynomial_regression = regression.polynomial
statistics.wls = regression.wls
statistics.ridge = regression.ridge
statistics.regression = regression

-- Bootstrap 和重抽样
statistics.bootstrap = resampling.bootstrap
statistics.bootstrap_ci = resampling.bootstrap_ci
statistics.bootstrap_two_sample = resampling.bootstrap_two_sample
statistics.jackknife = resampling.jackknife
statistics.jackknife_ci = resampling.jackknife_ci
statistics.permutation_test = resampling.permutation_test
statistics.permutation_test_paired = resampling.permutation_test_paired
statistics.bootstrap_t_test = resampling.bootstrap_t_test
statistics.bootstrap_var_test = resampling.bootstrap_var_test
statistics.cross_validation = resampling.cross_validation
statistics.monte_carlo = resampling.monte_carlo
statistics.resampling = resampling

_loaded["statistics.init"] = statistics

-- 主模块导出
lua_num._VERSION = "1.0.0"
lua_num._DESCRIPTION = "Lua Numerical Computing Library (Single File)"
lua_num._AUTHOR = "lua_num contributors"

lua_num.utils = utils
lua_num.matrix = matrix
lua_num.vector = vector
lua_num.integration = integration
lua_num.interpolation = interpolation
lua_num.optimization = optimization
lua_num.ode = ode
lua_num.root = root
lua_num.pde = pde
lua_num.statistics = statistics

lua_num.mat = matrix
lua_num.vec = vector
lua_num.integ = integration
lua_num.interp = interpolation
lua_num.opt = optimization

lua_num.PI = math.pi
lua_num.E = math.exp(1)
lua_num.EPSILON = 1e-15
lua_num.INF = math.huge
lua_num.PHI = (1 + math.sqrt(5)) / 2

function lua_num.isclose(a, b, rel_tol, abs_tol)
    rel_tol = rel_tol or 1e-9
    abs_tol = abs_tol or 0
    return math.abs(a - b) <= math.max(rel_tol * math.max(math.abs(a), math.abs(b)), abs_tol)
end

function lua_num.sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

function lua_num.linspace(a, b, n)
    n = n or 100
    local result = {}
    if n == 1 then result[1] = a
    else
        local step = (b - a) / (n - 1)
        for i = 0, n - 1 do result[i + 1] = a + i * step end
    end
    return result
end

function lua_num.sum(t) local s = 0 for i = 1, #t do s = s + t[i] end return s end
function lua_num.prod(t) local p = 1 for i = 1, #t do p = p * t[i] end return p end
function lua_num.max(t) if #t == 0 then return nil end local m = t[1] for i = 2, #t do if t[i] > m then m = t[i] end end return m end
function lua_num.min(t) if #t == 0 then return nil end local m = t[1] for i = 2, #t do if t[i] < m then m = t[i] end end return m end
function lua_num.mean(t) if #t == 0 then return nil end return lua_num.sum(t) / #t end
function lua_num.var(t) if #t == 0 then return nil end local m = lua_num.mean(t) local s = 0 for i = 1, #t do s = s + (t[i] - m) ^ 2 end return s / #t end
function lua_num.std(t) return math.sqrt(lua_num.var(t)) end
function lua_num.dot(a, b) local s = 0 for i = 1, math.min(#a, #b) do s = s + a[i] * b[i] end return s end
function lua_num.map(t, f) local r = {} for i = 1, #t do r[i] = f(t[i]) end return r end
function lua_num.filter(t, f) local r = {} for i = 1, #t do if f(t[i]) then r[#r + 1] = t[i] end end return r end

return lua_num
]])

out:close()

-- 获取文件大小
local file = io.open("dist/lua_num.lua", "r")
local size = file:seek("end")
file:close()

print("\nDone! Output: dist/lua_num.lua")
print("Size: " .. size .. " bytes (" .. string.format("%.1f", size / 1024) .. " KB)")