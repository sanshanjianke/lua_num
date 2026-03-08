-- lua_num - Lua 数值计算库
-- 主入口模块
--
-- 使用方法:
--   local num = require("init")
--   local A = num.matrix.rand(10, 10)
--   local det = A:det()
--   local v = num.vector.linspace(0, 1, 100)
--   local result = num.integration.simpson(math.sin, 0, math.pi, 1000)

local lua_num = {}

-- 版本信息
lua_num._VERSION = "1.0.0"
lua_num._DESCRIPTION = "Lua Numerical Computing Library"
lua_num._AUTHOR = "lua_num contributors"

-- 加载子模块
utils = require("utils.init")
matrix = require("matrix.init")
vector = require("vector.init")
integration = require("integration.init")
interpolation = require("interpolation.init")
optimization = require("optimization.init")
ode = require("ode.init")
pde = require("pde.init")
statistics = require("statistics.init")

-- 快捷访问别名
lua_num.mat = matrix
lua_num.vec = vector
lua_num.integ = integration
lua_num.interp = interpolation
lua_num.opt = optimization
lua_num.pde = pde
lua_num.stats = statistics

-- 常用常量
lua_num.PI = math.pi
lua_num.E = math.exp(1)
lua_num.EPSILON = 1e-15
lua_num.INF = math.huge

-- 黄金比例
lua_num.PHI = (1 + math.sqrt(5)) / 2

-- 辅助函数：判断是否接近
function lua_num.isclose(a, b, rel_tol, abs_tol)
    rel_tol = rel_tol or 1e-9
    abs_tol = abs_tol or 0
    return math.abs(a - b) <= math.max(rel_tol * math.max(math.abs(a), math.abs(b)), abs_tol)
end

-- 辅助函数：符号函数
function lua_num.sign(x)
    if x > 0 then return 1
    elseif x < 0 then return -1
    else return 0 end
end

-- 辅助函数：线性空间
function lua_num.linspace(a, b, n)
    n = n or 100
    local result = {}
    if n == 1 then
        result[1] = a
    else
        local step = (b - a) / (n - 1)
        for i = 0, n - 1 do
            result[i + 1] = a + i * step
        end
    end
    return result
end

-- 辅助函数：对数空间
function lua_num.logspace(a, b, n, base)
    base = base or 10
    n = n or 100
    local result = {}
    local lin = lua_num.linspace(a, b, n)
    for i = 1, n do
        result[i] = base ^ lin[i]
    end
    return result
end

-- 辅助函数：求和
function lua_num.sum(t)
    local s = 0
    for i = 1, #t do
        s = s + t[i]
    end
    return s
end

-- 辅助函数：求积
function lua_num.prod(t)
    local p = 1
    for i = 1, #t do
        p = p * t[i]
    end
    return p
end

-- 辅助函数：最大值
function lua_num.max(t)
    if #t == 0 then return nil end
    local m = t[1]
    for i = 2, #t do
        if t[i] > m then m = t[i] end
    end
    return m
end

-- 辅助函数：最小值
function lua_num.min(t)
    if #t == 0 then return nil end
    local m = t[1]
    for i = 2, #t do
        if t[i] < m then m = t[i] end
    end
    return m
end

-- 辅助函数：平均值
function lua_num.mean(t)
    if #t == 0 then return nil end
    return lua_num.sum(t) / #t
end

-- 辅助函数：方差
function lua_num.var(t)
    if #t == 0 then return nil end
    local m = lua_num.mean(t)
    local s = 0
    for i = 1, #t do
        s = s + (t[i] - m) ^ 2
    end
    return s / #t
end

-- 辅助函数：标准差
function lua_num.std(t)
    return math.sqrt(lua_num.var(t))
end

-- 辅助函数：点积
function lua_num.dot(a, b)
    local s = 0
    for i = 1, math.min(#a, #b) do
        s = s + a[i] * b[i]
    end
    return s
end

-- 辅助函数：数组映射
function lua_num.map(t, f)
    local result = {}
    for i = 1, #t do
        result[i] = f(t[i])
    end
    return result
end

-- 辅助函数：数组过滤
function lua_num.filter(t, f)
    local result = {}
    for i = 1, #t do
        if f(t[i]) then
            result[#result + 1] = t[i]
        end
    end
    return result
end

return lua_num