-- 基础插值方法模块
local basic_interpolation = {}
local Validator = require("utils.validators")

-- 辅助函数：验证插值点
-- @param x_data x坐标数组
-- @param y_data y坐标数组
local function validate_interpolation_points(x_data, y_data)
    if not Validator.is_vector(x_data) then
        error("x_data must be a vector (1D array of numbers)")
    end
    if not Validator.is_vector(y_data) then
        error("y_data must be a vector (1D array of numbers)")
    end
    if #x_data ~= #y_data then
        error(string.format("x_data and y_data must have the same length (x: %d, y: %d)",
            #x_data, #y_data))
    end
    if #x_data < 2 then
        error("At least 2 data points are required for interpolation")
    end

    -- 检查x点是否严格递增
    for i = 2, #x_data do
        if x_data[i] <= x_data[i-1] then
            error(string.format("x_data must be strictly increasing (x[%d]=%f <= x[%d]=%f)",
                i, x_data[i], i-1, x_data[i-1]))
        end
    end
end

-- 辅助函数：查找插值区间
-- @param x 要插值的点
-- @param x_data x坐标数组
-- @return i 插值区间左端点索引
local function find_interval(x, x_data)
    local n = #x_data
    if x < x_data[1] or x > x_data[n] then
        error(string.format("x is outside the interpolation range [%f, %f]",
            x_data[1], x_data[n]))
    end

    -- 二分查找
    local low, high = 1, n - 1
    while low <= high do
        local mid = math.floor((low + high) / 2)
        if x_data[mid] <= x and x <= x_data[mid + 1] then
            return mid
        elseif x < x_data[mid] then
            high = mid - 1
        else
            low = mid + 1
        end
    end

    return n - 1
end

-- 线性插值
-- 在给定的两个点之间进行线性插值
-- @param x 要插值的点（可以是单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @return 插值结果（单个值或数组）
function basic_interpolation.linear(x, x_data, y_data)
    validate_interpolation_points(x_data, y_data)

    -- 判断输入是单个值还是数组
    local is_array = type(x) == "table" and #x > 0

    if is_array then
        -- 对数组中的每个点进行插值
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = basic_interpolation.linear_single(xi, x_data, y_data)
        end
        return results
    else
        -- 单个点插值
        return basic_interpolation.linear_single(x, x_data, y_data)
    end
end

-- 线性插值的单个点计算（内部使用）
function basic_interpolation.linear_single(x, x_data, y_data)
    local i = find_interval(x, x_data)
    local x0, x1 = x_data[i], x_data[i + 1]
    local y0, y1 = y_data[i], y_data[i + 1]

    -- 线性插值公式
    local t = (x - x0) / (x1 - x0)
    return y0 + t * (y1 - y0)
end

-- 拉格朗日插值
-- 使用拉格朗日多项式进行插值
-- @param x 要插值的点（可以是单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @return 插值结果（单个值或数组）
function basic_interpolation.lagrange(x, x_data, y_data)
    validate_interpolation_points(x_data, y_data)

    local n = #x_data

    -- 判断输入是单个值还是数组
    local is_array = type(x) == "table" and #x > 0

    if is_array then
        -- 对数组中的每个点进行插值
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = basic_interpolation.lagrange_single(xi, x_data, y_data, n)
        end
        return results
    else
        -- 单个点插值
        return basic_interpolation.lagrange_single(x, x_data, y_data, n)
    end
end

-- 拉格朗日插值的单个点计算（内部使用）
function basic_interpolation.lagrange_single(x, x_data, y_data, n)
    local result = 0

    for i = 1, n do
        -- 计算拉格朗日基函数 L_i(x)
        local Li = 1
        for j = 1, n do
            if j ~= i then
                Li = Li * (x - x_data[j]) / (x_data[i] - x_data[j])
            end
        end
        result = result + y_data[i] * Li
    end

    return result
end

-- 牛顿插值
-- 使用牛顿均差形式进行插值
-- @param x 要插值的点（可以是单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @return 插值结果（单个值或数组）
function basic_interpolation.newton(x, x_data, y_data)
    validate_interpolation_points(x_data, y_data)

    -- 计算均差表（divided differences）
    local n = #x_data
    local dd = {}  -- 均差表
    for i = 1, n do
        dd[i] = y_data[i]
    end

    -- 计算均差
    for j = 2, n do
        for i = n, j, -1 do
            dd[i] = (dd[i] - dd[i-1]) / (x_data[i] - x_data[i-j+1])
        end
    end

    -- 判断输入是单个值还是数组
    local is_array = type(x) == "table" and #x > 0

    if is_array then
        -- 对数组中的每个点进行插值
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = basic_interpolation.newton_single(xi, x_data, dd, n)
        end
        return results
    else
        -- 单个点插值
        return basic_interpolation.newton_single(x, x_data, dd, n)
    end
end

-- 牛顿插值的单个点计算（内部使用）
function basic_interpolation.newton_single(x, x_data, dd, n)
    local result = dd[1]
    local product = 1

    for i = 1, n - 1 do
        product = product * (x - x_data[i])
        result = result + dd[i + 1] * product
    end

    return result
end

-- 分段线性插值
-- 对多个点进行分段线性插值
-- @param x 要插值的点（单个值或数组）
-- @param x_data x坐标数组（严格递增）
-- @param y_data y坐标数组
-- @return 插值结果
function basic_interpolation.piecewise_linear(x, x_data, y_data)
    validate_interpolation_points(x_data, y_data)

    local is_array = type(x) == "table" and #x > 0

    if is_array then
        local results = {}
        for _, xi in ipairs(x) do
            results[#results + 1] = basic_interpolation.linear(xi, x_data, y_data)
        end
        return results
    else
        return basic_interpolation.linear(x, x_data, y_data)
    end
end

return basic_interpolation
