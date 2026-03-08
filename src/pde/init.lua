-- PDE（偏微分方程）模块入口
local pde = {}

-- 加载子模块
local elliptic = require("pde.elliptic")
local parabolic = require("pde.parabolic")
local hyperbolic = require("pde.hyperbolic")

-- =============================================================================
-- 椭圆型方程
-- =============================================================================

pde.poisson = elliptic.poisson
pde.laplace = elliptic.laplace
pde.poisson_simple = elliptic.poisson_simple
pde.grid_coords = elliptic.grid_coords
pde.interpolate = elliptic.interpolate

-- =============================================================================
-- 抛物型方程
-- =============================================================================

pde.heat1d = parabolic.heat1d
pde.heat2d = parabolic.heat2d
pde.diffusion1d = parabolic.diffusion1d
pde.diffusion2d = parabolic.diffusion2d

-- =============================================================================
-- 双曲型方程
-- =============================================================================

pde.wave1d = hyperbolic.wave1d
pde.wave2d = hyperbolic.wave2d
pde.advection1d = hyperbolic.advection1d
pde.transport1d = hyperbolic.transport1d

-- =============================================================================
-- 便捷函数
-- =============================================================================

-- 统一求解接口
-- @param equation_type 方程类型 "elliptic"|"parabolic"|"hyperbolic"
-- @param problem_type 问题类型 "poisson"|"laplace"|"heat"|"wave"|"advection"
-- @param ... 其他参数
function pde.solve(equation_type, problem_type, ...)
    if equation_type == "elliptic" then
        if problem_type == "poisson" then
            return elliptic.poisson(...)
        elseif problem_type == "laplace" then
            return elliptic.laplace(...)
        end
    elseif equation_type == "parabolic" then
        if problem_type == "heat" or problem_type == "diffusion" then
            return parabolic.heat1d(...)
        end
    elseif equation_type == "hyperbolic" then
        if problem_type == "wave" then
            return hyperbolic.wave1d(...)
        elseif problem_type == "advection" or problem_type == "transport" then
            return hyperbolic.advection1d(...)
        end
    end

    error(string.format("Unknown equation/problem type: %s/%s", equation_type, problem_type))
end

-- =============================================================================
-- 别名
-- =============================================================================

pde.elliptic = elliptic
pde.parabolic = parabolic
pde.hyperbolic = hyperbolic

return pde