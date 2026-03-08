-- Vector 高级运算
local Vector = require("vector.vector")
local utils = require("utils.init")
local Typecheck = utils.typecheck

-- 向量范数
function Vector:norm(norm_type)
    norm_type = norm_type or 2

    if norm_type == 2 or norm_type == "fro" or norm_type == nil then
        -- L2 范数（欧几里得范数）
        local sum_sq = 0
        for _, val in self:iter() do
            sum_sq = sum_sq + val * val
        end
        return math.sqrt(sum_sq)
    elseif norm_type == 1 then
        -- L1 范数（曼哈顿范数）
        local sum = 0
        for _, val in self:iter() do
            sum = sum + math.abs(val)
        end
        return sum
    elseif norm_type == "inf" or norm_type == math.huge then
        -- L∞ 范数（最大绝对值）
        local max_val = 0
        for _, val in self:iter() do
            local abs_val = math.abs(val)
            if abs_val > max_val then
                max_val = abs_val
            end
        end
        return max_val
    elseif type(norm_type) == "number" then
        -- Lp 范数
        local sum = 0
        for _, val in self:iter() do
            sum = sum + (math.abs(val) ^ norm_type)
        end
        return sum ^ (1 / norm_type)
    else
        utils.Error.invalid_input("Invalid norm type: " .. tostring(norm_type))
    end
end

-- 归一化（单位化）
function Vector:normalize()
    local n = self:norm()
    if n == 0 then
        utils.Error.invalid_input("Cannot normalize zero vector")
    end
    return self / n
end

-- 原地归一化
function Vector:normalize_inplace()
    local n = self:norm()
    if n == 0 then
        utils.Error.invalid_input("Cannot normalize zero vector")
    end
    self:div_inplace(n)
end

-- 叉积（仅 3D 向量）
function Vector:cross(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= 3 or other.size ~= 3 then
        utils.Error.invalid_input("Cross product only defined for 3D vectors")
    end

    local x = self.data[2] * other.data[3] - self.data[3] * other.data[2]
    local y = self.data[3] * other.data[1] - self.data[1] * other.data[3]
    local z = self.data[1] * other.data[2] - self.data[2] * other.data[1]

    return Vector.new({x, y, z})
end

-- 角度（弧度）
function Vector:angle(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local n1 = self:norm()
    local n2 = other:norm()

    if n1 == 0 or n2 == 0 then
        utils.Error.invalid_input("Cannot compute angle with zero vector")
    end

    local cos_angle = self:dot(other) / (n1 * n2)
    -- 限制在 [-1, 1] 范围内以避免数值误差
    cos_angle = math.max(-1, math.min(1, cos_angle))

    return math.acos(cos_angle)
end

-- 角度（度）
function Vector:angle_deg(other)
    return self:angle(other) * utils.rad2deg
end

-- 投影到另一个向量
function Vector:project(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local n2_sq = other:dot(other)
    if n2_sq == 0 then
        utils.Error.invalid_input("Cannot project onto zero vector")
    end

    local scalar = self:dot(other) / n2_sq
    return other * scalar
end

-- 正交分量（垂直于另一个向量的分量）
function Vector:orthogonal(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    return self - self:project(other)
end

-- 反射
function Vector:reflect(normal)
    Typecheck.check_type(normal, Vector, "normal")

    if self.size ~= normal.size then
        utils.Error.dimension_mismatch(self.size, normal.size)
    end

    local normalized_normal = normal:normalize()
    return self - normalized_normal * (2 * self:dot(normalized_normal))
end

-- 旋转（仅 2D）
function Vector:rotate2d(angle_rad)
    if self.size ~= 2 then
        utils.Error.invalid_input("2D rotation only works with 2D vectors")
    end

    local cos_a = math.cos(angle_rad)
    local sin_a = math.sin(angle_rad)

    local x = self.data[1] * cos_a - self.data[2] * sin_a
    local y = self.data[1] * sin_a + self.data[2] * cos_a

    return Vector.new({x, y})
end

-- 绕轴旋转（仅 3D）
function Vector:rotate3d(axis, angle_rad)
    if self.size ~= 3 or axis.size ~= 3 then
        utils.Error.invalid_input("3D rotation only works with 3D vectors")
    end

    -- 使用 Rodrigues 旋转公式
    local k = axis:normalize()
    local cos_a = math.cos(angle_rad)
    local sin_a = math.sin(angle_rad)

    -- v_rot = v*cos(a) + (k×v)*sin(a) + k*(k·v)*(1-cos(a))
    local term1 = self * cos_a
    local term2 = k:cross(self) * sin_a
    local term3 = k * (k:dot(self) * (1 - cos_a))

    return term1 + term2 + term3
end

-- 外积（张量积）
function Vector:outer(other)
    Typecheck.check_type(other, Vector, "other")

    local matrix = require("matrix.init")

    local result = {}
    for i = 1, self.size do
        result[i] = {}
        for j = 1, other.size do
            result[i][j] = self.data[i] * other.data[j]
        end
    end

    return matrix.new(result)
end

-- 按比例缩放
function Vector:scale(scales)
    Typecheck.check_table(scales, "scales")

    if #scales ~= self.size then
        utils.Error.dimension_mismatch(#scales, self.size)
    end

    local result = {}
    for i = 1, self.size do
        result[i] = self.data[i] * scales[i]
    end
    return Vector.new(result)
end

-- 克拉默-施密特正交化
function Vector:orthogonalize_with(others)
    Typecheck.check_table(others, "others")

    local result = self:clone()

    for _, other in ipairs(others) do
        Typecheck.check_type(other, Vector, "other")
        result = result - result:project(other)
    end

    return result
end

-- 检查是否为零向量
function Vector:is_zero(eps)
    eps = eps or utils.epsilon

    for _, val in self:iter() do
        if math.abs(val) > eps then
            return false
        end
    end
    return true
end

-- 检查是否为单位向量
function Vector:is_unit(eps)
    eps = eps or utils.epsilon

    local n = self:norm()
    return math.abs(n - 1) < eps
end

-- 检查是否正交
function Vector:is_orthogonal_to(other, eps)
    Typecheck.check_type(other, Vector, "other")

    eps = eps or utils.epsilon

    if self.size ~= other.size then
        return false
    end

    return math.abs(self:dot(other)) < eps
end

-- 检查是否平行
function Vector:is_parallel_to(other, eps)
    Typecheck.check_type(other, Vector, "other")

    eps = eps or utils.epsilon

    if self.size ~= other.size then
        return false
    end

    -- 计算叉积的范数
    local cross_norm
    if self.size == 3 then
        cross_norm = self:cross(other):norm()
    else
        -- 对于非 3D 向量，使用另一种方法
        -- 检查是否成比例
        local ratio = nil
        for i = 1, self.size do
            if math.abs(other.data[i]) > eps then
                if ratio == nil then
                    ratio = self.data[i] / other.data[i]
                elseif math.abs(self.data[i] / other.data[i] - ratio) > eps then
                    return false
                end
            elseif math.abs(self.data[i]) > eps then
                return false
            end
        end
        return true
    end

    return cross_norm < eps
end

-- 距离
function Vector:distance(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local sum_sq = 0
    for i = 1, self.size do
        local diff = self.data[i] - other.data[i]
        sum_sq = sum_sq + diff * diff
    end

    return math.sqrt(sum_sq)
end

-- 曼哈顿距离
function Vector:manhattan_distance(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local sum = 0
    for i = 1, self.size do
        sum = sum + math.abs(self.data[i] - other.data[i])
    end

    return sum
end

-- 夹角余弦
function Vector:cosine_similarity(other)
    Typecheck.check_type(other, Vector, "other")

    if self.size ~= other.size then
        utils.Error.dimension_mismatch(self.size, other.size)
    end

    local n1 = self:norm()
    local n2 = other:norm()

    if n1 == 0 or n2 == 0 then
        utils.Error.invalid_input("Cannot compute cosine similarity with zero vector")
    end

    return self:dot(other) / (n1 * n2)
end

-- 混合积（仅 3D）
function Vector.triple_product(a, b, c)
    Typecheck.check_type(a, Vector, "a")
    Typecheck.check_type(b, Vector, "b")
    Typecheck.check_type(c, Vector, "c")

    if a.size ~= 3 or b.size ~= 3 or c.size ~= 3 then
        utils.Error.invalid_input("Triple product only defined for 3D vectors")
    end

    return a:dot(b:cross(c))
end

-- 双重叉积（仅 3D）
function Vector.double_cross(a, b)
    Typecheck.check_type(a, Vector, "a")
    Typecheck.check_type(b, Vector, "b")

    if a.size ~= 3 or b.size ~= 3 then
        utils.Error.invalid_input("Double cross product only defined for 3D vectors")
    end

    return a:cross(a:cross(b))
end

return Vector
