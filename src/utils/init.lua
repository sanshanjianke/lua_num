-- Utils 模块入口
local utils = {}

-- 导出子模块
utils.constants = require("utils.constants")
utils.Error = require("utils.error")
utils.validators = require("utils.validators")
utils.typecheck = require("utils.typecheck")

-- 导出常量（直接访问）
utils.pi = utils.constants.pi
utils.e = utils.constants.e
utils.phi = utils.constants.phi
utils.gamma = utils.constants.gamma
utils.epsilon = utils.constants.epsilon
utils.tiny = utils.constants.tiny
utils.huge = utils.constants.huge
utils.deg2rad = utils.constants.deg2rad
utils.rad2deg = utils.constants.rad2deg

-- 导出便捷函数
utils.assert_matrix = utils.validators.assert_matrix
utils.assert_square_matrix = utils.validators.assert_square_matrix
utils.assert_same_dimensions = utils.validators.assert_same_dimensions
utils.assert_can_multiply = utils.validators.assert_can_multiply

-- 基础工具函数
function utils.abs(x)
    return math.abs(x)
end

function utils.sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

function utils.max(...)
    local values = {...}
    local max_val = values[1]
    for i = 2, #values do
        if values[i] > max_val then
            max_val = values[i]
        end
    end
    return max_val
end

function utils.min(...)
    local values = {...}
    local min_val = values[1]
    for i = 2, #values do
        if values[i] < min_val then
            min_val = values[i]
        end
    end
    return min_val
end

-- 向量工具函数
function utils.dot(v1, v2)
    if #v1 ~= #v2 then
        utils.Error.dimension_mismatch(#v1, #v2)
    end
    local sum = 0
    for i = 1, #v1 do
        sum = sum + v1[i] * v2[i]
    end
    return sum
end

function utils.norm(v)
    local sum = 0
    for i = 1, #v do
        sum = sum + v[i] * v[i]
    end
    return math.sqrt(sum)
end

return utils
