-- 数值积分模块入口
local integration = {}

-- 加载子模块
local basic = require("integration.basic_integration")
local advanced = require("integration.advanced_integration")
local multi = require("integration.multi_integration")

-- 导出基本积分方法
integration.trapezoidal = basic.trapezoidal
integration.simpson = basic.simpson
integration.midpoint = basic.midpoint
integration.left_endpoint = basic.left_endpoint
integration.right_endpoint = basic.right_endpoint

-- 导出高级积分方法
integration.adaptive = advanced.adaptive
integration.romberg = advanced.romberg
integration.gauss = advanced.gauss
integration.composite_gauss = advanced.composite_gauss
integration.singular = advanced.singular

-- 导出多重积分方法
integration.double = multi.double
integration.double_integral = multi.double_integral
integration.triple = multi.triple
integration.triple_integral = multi.triple_integral
integration.monte_carlo = multi.monte_carlo
integration.monte_carlo_region = multi.monte_carlo_region

-- 别名
integration.trap = integration.trapezoidal
integration.adaptive_simpson = integration.adaptive
integration.gauss_legendre = integration.gauss
integration.romberg_extrapolation = integration.romberg

-- 便捷函数：自动选择积分方法
-- @param f 要积分的函数
-- @param a 积分下限
-- @param b 积分上限
-- @param options 选项表，可包含：
--   - method: 方法名（"trapezoidal", "simpson", "midpoint", "adaptive", "romberg", "gauss", "composite_gauss"）
--   - n: 子区间数或节点数
--   - tol: 容差
--   - max_iter: 最大迭代次数
-- @return 积分近似值
function integration.integrate(f, a, b, options)
    options = options or {}

    local method = options.method or "simpson"

    local method_map = {
        trapezoidal = function() return integration.trapezoidal(f, a, b, options.n) end,
        trap = function() return integration.trapezoidal(f, a, b, options.n) end,
        simpson = function() return integration.simpson(f, a, b, options.n) end,
        midpoint = function() return integration.midpoint(f, a, b, options.n) end,
        left = function() return integration.left_endpoint(f, a, b, options.n) end,
        right = function() return integration.right_endpoint(f, a, b, options.n) end,
        adaptive = function() return integration.adaptive(f, a, b, options.tol, options.max_iter) end,
        romberg = function() return integration.romberg(f, a, b, options.n, options.tol) end,
        gauss = function() return integration.gauss(f, a, b, options.n) end,
        composite_gauss = function() return integration.composite_gauss(f, a, b, options.n, options.m) end
    }

    local method_func = method_map[method]
    if not method_func then
        error("Unknown integration method: " .. method)
    end

    return method_func()
end

return integration
