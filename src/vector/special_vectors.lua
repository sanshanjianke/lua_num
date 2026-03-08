-- 特殊向量生成
local Vector = require("vector.vector")
local utils = require("utils.init")
local Typecheck = utils.typecheck

-- 零向量
function Vector.zeros(size)
    Typecheck.check_positive_integer(size, "size")

    local data = {}
    for i = 1, size do
        data[i] = 0
    end
    return Vector.new(data)
end

-- 全1向量
function Vector.ones(size)
    Typecheck.check_positive_integer(size, "size")

    local data = {}
    for i = 1, size do
        data[i] = 1
    end
    return Vector.new(data)
end

-- 单位向量（第 i 个元素为 1，其余为 0）
function Vector.unit(size, index)
    Typecheck.check_positive_integer(size, "size")
    Typecheck.check_positive_integer(index, "index")

    if index > size then
        utils.Error.out_of_bounds(index, size)
    end

    local data = {}
    for i = 1, size do
        data[i] = (i == index) and 1 or 0
    end
    return Vector.new(data)
end

-- 随机向量（均匀分布 [0, 1)）
function Vector.rand(size)
    Typecheck.check_positive_integer(size, "size")

    local data = {}
    for i = 1, size do
        data[i] = math.random()
    end
    return Vector.new(data)
end

-- 随机整数向量
function Vector.rand_int(size, min_val, max_val)
    Typecheck.check_positive_integer(size, "size")

    min_val = min_val or 0
    max_val = max_val or 100

    local data = {}
    for i = 1, size do
        data[i] = math.random(min_val, max_val)
    end
    return Vector.new(data)
end

-- 随机单位向量（归一化的随机向量）
function Vector.rand_unit(size)
    Typecheck.check_positive_integer(size, "size")

    local v = Vector.rand(size)
    return v:normalize()
end

-- 高斯随机向量（正态分布）
function Vector.randn(size, mean, std)
    Typecheck.check_positive_integer(size, "size")

    mean = mean or 0
    std = std or 1

    local data = {}
    for i = 1, size do
        -- Box-Muller 变换生成正态分布
        local u1 = math.random()
        local u2 = math.random()
        local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
        data[i] = z0 * std + mean
    end
    return Vector.new(data)
end

-- 线性空间向量
function Vector.linspace(start, stop, num)
    num = num or 50

    Typecheck.check_number(start, "start")
    Typecheck.check_number(stop, "stop")
    Typecheck.check_positive_integer(num, "num")

    local data = {}
    if num == 1 then
        data[1] = stop
    else
        local step = (stop - start) / (num - 1)
        for i = 1, num do
            data[i] = start + (i - 1) * step
        end
    end
    return Vector.new(data)
end

-- 对数空间向量
function Vector.logspace(start, stop, num, base)
    num = num or 50
    base = base or 10

    Typecheck.check_number(start, "start")
    Typecheck.check_number(stop, "stop")
    Typecheck.check_positive_integer(num, "num")
    Typecheck.check_positive_number(base, "base")

    -- 转换为对数空间
    local log_start = math.log(start, base)
    local log_stop = math.log(stop, base)

    -- 生成线性空间
    local linear = Vector.linspace(log_start, log_stop, num)

    -- 转回原空间
    return linear:map(function(x) return base ^ x end)
end

-- 几何空间向量
function Vector.geomspace(start, stop, num)
    num = num or 50

    Typecheck.check_positive_number(start, "start")
    Typecheck.check_positive_number(stop, "stop")
    Typecheck.check_positive_integer(num, "num")

    local ratio = (stop / start) ^ (1 / (num - 1))
    local data = {}
    for i = 1, num do
        data[i] = start * (ratio ^ (i - 1))
    end
    return Vector.new(data)
end

-- 从表创建向量
function Vector.from_table(data)
    Typecheck.check_table(data, "data")

    return Vector.new(data)
end

-- 从范围创建向量
function Vector.range(start, stop, step)
    start = start or 1
    stop = stop or start
    step = step or 1

    Typecheck.check_number(start, "start")
    Typecheck.check_number(stop, "stop")
    Typecheck.check_non_zero_number(step, "step")

    local data = {}
    local i = 1

    if step > 0 then
        for val = start, stop, step do
            data[i] = val
            i = i + 1
        end
    else
        for val = start, stop, step do
            data[i] = val
            i = i + 1
        end
    end

    return Vector.new(data)
end

-- 基向量（第 k 个基向量）
function Vector.basis(dim, k)
    return Vector.unit(dim, k)
end

-- 标准基向量组
function Vector.standard_basis(dim)
    Typecheck.check_positive_integer(dim, "dim")

    local basis = {}
    for k = 1, dim do
        basis[k] = Vector.unit(dim, k)
    end
    return basis
end

-- 常数向量
function Vector.constant(size, value)
    Typecheck.check_positive_integer(size, "size")
    Typecheck.check_number(value, "value")

    local data = {}
    for i = 1, size do
        data[i] = value
    end
    return Vector.new(data)
end

-- 重复向量
function Vector.repeat_vec(elem, times)
    Typecheck.check_number(elem, "elem")
    Typecheck.check_positive_integer(times, "times")

    local data = {}
    for i = 1, times do
        data[i] = elem
    end
    return Vector.new(data)
end

-- 将向量拼接为长向量
function Vector.concat_vectors(...)
    local vectors = {...}

    if #vectors == 0 then
        utils.Error.invalid_input("At least one vector required")
    end

    for i, v in ipairs(vectors) do
        Typecheck.check_type(v, Vector, "vector " .. i)
    end

    -- 计算总长度
    local total_size = 0
    for _, v in ipairs(vectors) do
        total_size = total_size + v.size
    end

    local data = {}
    local idx = 1
    for _, v in ipairs(vectors) do
        for i = 1, v.size do
            data[idx] = v.data[i]
            idx = idx + 1
        end
    end

    return Vector.new(data)
end

-- 栈式拼接（垂直堆叠）
function Vector.stack(...)
    return Vector.concat_vectors(...)
end

-- 创建索引向量
function Vector.indices(start, stop)
    start = start or 1

    Typecheck.check_positive_integer(start, "start")

    if stop then
        Typecheck.check_positive_integer(stop, "stop")
    else
        stop = start
    end

    local data = {}
    for i = start, stop do
        data[i - start + 1] = i
    end

    return Vector.new(data)
end

-- 创建布尔向量
function Vector.bool(size, ...)
    Typecheck.check_positive_integer(size, "size")

    local values = {...}
    local data = {}

    if #values == 0 then
        -- 全 false
        for i = 1, size do
            data[i] = false
        end
    elseif #values == 1 then
        -- 全为指定值
        for i = 1, size do
            data[i] = values[1]
        end
    else
        -- 重复模式
        for i = 1, size do
            data[i] = values[((i - 1) % #values) + 1]
        end
    end

    return Vector.new(data)
end

-- 从字符串创建向量
function Vector.from_string(str, sep)
    sep = sep or "[,%s]+"

    Typecheck.check_string(str, "str")

    local data = {}
    for num in string.gmatch(str, sep) do
        local val = tonumber(num)
        if val then
            data[#data + 1] = val
        end
    end

    if #data == 0 then
        utils.Error.invalid_input("No valid numbers found in string")
    end

    return Vector.new(data)
end

-- 网格向量（用于 2D/3D 网格）
function Vector.meshgrid(x_vec, y_vec)
    Typecheck.check_type(x_vec, Vector, "x_vec")
    Typecheck.check_type(y_vec, Vector, "y_vec")

    local matrix = require("matrix.init")

    -- 创建 X 网格（每行重复 x_vec）
    local X_data = {}
    for i = 1, y_vec.size do
        for j = 1, x_vec.size do
            if X_data[i] == nil then
                X_data[i] = {}
            end
            X_data[i][j] = x_vec.data[j]
        end
    end

    -- 创建 Y 网格（每列重复 y_vec）
    local Y_data = {}
    for i = 1, y_vec.size do
        Y_data[i] = {}
        for j = 1, x_vec.size do
            Y_data[i][j] = y_vec.data[i]
        end
    end

    return matrix.new(X_data), matrix.new(Y_data)
end

-- 球坐标网格
function Vector.sphere_grid(phi_num, theta_num)
    Typecheck.check_positive_integer(phi_num, "phi_num")
    Typecheck.check_positive_integer(theta_num, "theta_num")

    local phi = Vector.linspace(0, math.pi, phi_num)
    local theta = Vector.linspace(0, 2 * math.pi, theta_num)

    return phi, theta
end

return Vector
