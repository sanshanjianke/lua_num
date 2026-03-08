-- 插值模块入口
local interpolation = {}

-- 加载子模块
local basic = require("interpolation.basic_interpolation")
local advanced = require("interpolation.advanced_interpolation")
local multi = require("interpolation.multi_interpolation")

-- 导出基本插值方法
interpolation.linear = basic.linear
interpolation.lagrange = basic.lagrange
interpolation.newton = basic.newton
interpolation.piecewise_linear = basic.piecewise_linear

-- 导出高级插值方法
interpolation.spline = advanced.spline
interpolation.spline_clamped = advanced.spline_clamped
interpolation.spline_derivative = advanced.spline_derivative
interpolation.spline_derivative2 = advanced.spline_derivative2

-- 导出多维插值方法
interpolation.bilinear = multi.bilinear
interpolation.bilinear_batch = multi.bilinear_batch
interpolation.bicubic = multi.bicubic
interpolation.rbf = multi.rbf
interpolation.rbf_weights = multi.rbf_weights
interpolation.multivariate_lagrange = multi.multivariate_lagrange
interpolation.nearest_neighbor = multi.nearest_neighbor
interpolation.idw = multi.idw

-- 别名
interpolation.poly = interpolation.lagrange  -- 多项式插值
interpolation.natural_spline = interpolation.spline
interpolation.clamped_spline = interpolation.spline_clamped

-- 便捷函数：统一接口
-- @param x 要插值的点（单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @param options 选项表，可包含：
--   - method: 方法名（"linear", "lagrange", "newton", "spline", "spline_clamped"）
--   - boundary: 样条边界条件（"natural" 或 "clamped"）
--   - boundary_values: 样条边界值 [dy0, dyn]
-- @return 插值结果
function interpolation.interpolate(x, x_data, y_data, options)
    options = options or {}
    local method = options.method or "linear"

    local method_map = {
        linear = function()
            return interpolation.linear(x, x_data, y_data)
        end,
        lagrange = function()
            return interpolation.lagrange(x, x_data, y_data)
        end,
        newton = function()
            return interpolation.newton(x, x_data, y_data)
        end,
        spline = function()
            return interpolation.spline(x, x_data, y_data)
        end,
        spline_clamped = function()
            if not options.boundary_values then
                error("spline_clamped requires boundary_values = {dy0, dyn}")
            end
            return interpolation.spline_clamped(x, x_data, y_data,
                options.boundary_values[1], options.boundary_values[2])
        end,
    }

    local method_func = method_map[method]
    if not method_func then
        error(string.format("Unknown interpolation method: %s", method))
    end

    return method_func()
end

-- 导出内部函数（用于测试和高级用法）
interpolation._compute_spline_coefficients = advanced.compute_spline_coefficients
interpolation._tridiagonal_solver = advanced._tridiagonal_solver

return interpolation
