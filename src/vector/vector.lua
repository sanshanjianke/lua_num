-- Vector 类定义
local Vector = {}
Vector.__index = Vector

local utils = require("utils.init")
local Typecheck = utils.typecheck

-- 深度复制数组
local function deepcopy(src)
    local dest = {}
    for i = 1, #src do
        dest[i] = src[i]
    end
    return dest
end

-- 构造函数
function Vector.new(data, size)
    -- 参数可以是：数组，或者数组 + 大小
    if type(data) == "table" and size == nil then
        -- 数组形式
        Typecheck.check_table(data, "data")

        size = #data

        local self = {
            size = size,
            data = deepcopy(data),
            _metadata = {
                is_normalized = nil,
                is_unit = nil,
                is_zero = nil,
                norm = nil,
            },
            _cache = {
                norm = nil,
            },
        }

        return setmetatable(self, Vector)
    else
        -- 一维数组形式 + 大小
        Typecheck.check_table(data, "data")
        Typecheck.check_positive_integer(size, "size")

        if #data ~= size then
            utils.Error.invalid_input(
                string.format("Data length (%d) does not match size (%d)",
                    #data, size)
            )
        end

        local self = {
            size = size,
            data = deepcopy(data),
            _metadata = {
                is_normalized = nil,
                is_unit = nil,
                is_zero = nil,
                norm = nil,
            },
            _cache = {
                norm = nil,
            },
        }

        return setmetatable(self, Vector)
    end
end

-- 缓存失效
function Vector:_invalidate_cache()
    self._cache = {
        norm = nil,
    }
    self._metadata = {
        is_normalized = nil,
        is_unit = nil,
        is_zero = nil,
        norm = nil,
    }
end

-- 元素访问
function Vector:get(index)
    Typecheck.check_positive_integer(index, "index")

    if index > self.size then
        utils.Error.out_of_bounds(index, self.size)
    end

    return self.data[index]
end

function Vector:set(index, value)
    Typecheck.check_positive_integer(index, "index")
    Typecheck.check_number(value, "value")

    if index > self.size then
        utils.Error.out_of_bounds(index, self.size)
    end

    self.data[index] = value
    self:_invalidate_cache()
end

-- 获取切片
function Vector:slice(start_idx, end_idx)
    Typecheck.check_positive_integer(start_idx, "start_idx")

    if end_idx then
        Typecheck.check_positive_integer(end_idx, "end_idx")
        if start_idx > end_idx then
            utils.Error.invalid_input("start_idx must be <= end_idx")
        end
    else
        end_idx = self.size
    end

    if end_idx > self.size then
        utils.Error.out_of_bounds(end_idx, self.size)
    end

    local slice_data = {}
    for i = start_idx, end_idx do
        slice_data[#slice_data + 1] = self.data[i]
    end
    return Vector.new(slice_data)
end

-- 克隆
function Vector:clone()
    local self_mt = getmetatable(self)
    local clone = {
        size = self.size,
        data = deepcopy(self.data),
        _metadata = {
            is_normalized = self._metadata.is_normalized,
            is_unit = self._metadata.is_unit,
            is_zero = self._metadata.is_zero,
            norm = self._metadata.norm,
        },
        _cache = {
            norm = nil,
        },
    }
    return setmetatable(clone, self_mt)
end

-- 转换为表
function Vector:to_table()
    return deepcopy(self.data)
end

-- 格式化为字符串
function Vector:__tostring()
    local elements = {}
    for i = 1, self.size do
        local val = self.data[i]
        local fmt = val >= 0 and " %10.6f" or "%10.6f"
        elements[i] = string.format(fmt, val)
    end
    return "| " .. table.concat(elements, " ") .. " |"
end

-- 返回类型
function Vector:type()
    return "Vector"
end

-- 迭代器
function Vector:iter()
    local i = 0
    return function()
        i = i + 1
        if i <= self.size then
            return i, self.data[i]
        end
    end
end

-- 映射函数
function Vector:map(func)
    Typecheck.check_function(func, "func")

    local result = {}
    for i, val in self:iter() do
        result[i] = func(val, i)
    end
    return Vector.new(result)
end

-- 过滤函数
function Vector:filter(func)
    Typecheck.check_function(func, "func")

    local result = {}
    for i, val in self:iter() do
        if func(val, i) then
            result[#result + 1] = val
        end
    end
    return Vector.new(result)
end

-- 折叠函数
function Vector:reduce(func, init)
    Typecheck.check_function(func, "func")

    local result = init
    for i, val in self:iter() do
        if i == 1 and result == nil then
            result = val
        else
            result = func(result, val, i)
        end
    end
    return result
end

-- 获取最大值及其索引
function Vector:max()
    local max_val = self.data[1]
    local max_idx = 1
    for i = 2, self.size do
        if self.data[i] > max_val then
            max_val = self.data[i]
            max_idx = i
        end
    end
    return max_val, max_idx
end

-- 获取最小值及其索引
function Vector:min()
    local min_val = self.data[1]
    local min_idx = 1
    for i = 2, self.size do
        if self.data[i] < min_val then
            min_val = self.data[i]
            min_idx = i
        end
    end
    return min_val, min_idx
end

-- 求和
function Vector:sum()
    local sum = 0
    for _, val in self:iter() do
        sum = sum + val
    end
    return sum
end

-- 平均值
function Vector:mean()
    return self:sum() / self.size
end

-- 标准差
function Vector:std()
    local mu = self:mean()
    local sum_sq = 0
    for _, val in self:iter() do
        sum_sq = sum_sq + (val - mu) ^ 2
    end
    return math.sqrt(sum_sq / self.size)
end

-- 方差
function Vector:var()
    return self:std() ^ 2
end

return Vector
