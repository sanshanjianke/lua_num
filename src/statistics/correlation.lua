-- 相关性分析函数
local correlation = {}

local utils = require("utils.init")
local descriptive = require("statistics.descriptive")

-----------------------------------------------------------------------------
-- 辅助函数
-----------------------------------------------------------------------------

-- 检查输入是否为等长非空数组
local function validate_arrays(x, y, name_x, name_y)
    name_x = name_x or "x"
    name_y = name_y or "y"

    if type(x) ~= "table" or type(y) ~= "table" then
        utils.Error.invalid_input(name_x .. " and " .. name_y .. " must be tables")
    end
    if #x == 0 or #y == 0 then
        utils.Error.invalid_input("arrays must not be empty")
    end
    if #x ~= #y then
        utils.Error.dimension_mismatch(#x, #y)
    end
    if #x < 2 then
        utils.Error.invalid_input("arrays must have at least 2 elements")
    end
end

-----------------------------------------------------------------------------
-- 协方差
-----------------------------------------------------------------------------

-- 样本协方差（无偏估计，自由度 n-1）
function correlation.cov(x, y)
    validate_arrays(x, y)

    local n = #x
    local mean_x = descriptive.mean(x)
    local mean_y = descriptive.mean(y)

    local sum = 0
    for i = 1, n do
        sum = sum + (x[i] - mean_x) * (y[i] - mean_y)
    end

    return sum / (n - 1)
end

-- 总体协方差（自由度 n）
function correlation.cov_pop(x, y)
    validate_arrays(x, y)

    local n = #x
    local mean_x = descriptive.mean(x)
    local mean_y = descriptive.mean(y)

    local sum = 0
    for i = 1, n do
        sum = sum + (x[i] - mean_x) * (y[i] - mean_y)
    end

    return sum / n
end

-----------------------------------------------------------------------------
-- 相关系数
-----------------------------------------------------------------------------

-- 皮尔逊相关系数
function correlation.corr(x, y)
    validate_arrays(x, y)

    local n = #x
    local mean_x = descriptive.mean(x)
    local mean_y = descriptive.mean(y)

    local sum_xy = 0
    local sum_xx = 0
    local sum_yy = 0

    for i = 1, n do
        local dx = x[i] - mean_x
        local dy = y[i] - mean_y
        sum_xy = sum_xy + dx * dy
        sum_xx = sum_xx + dx * dx
        sum_yy = sum_yy + dy * dy
    end

    if sum_xx == 0 or sum_yy == 0 then
        return 0  -- 方差为0时，相关系数无定义，返回0
    end

    return sum_xy / math.sqrt(sum_xx * sum_yy)
end

-- 相关系数别名
correlation.corrcoef = correlation.corr

-- 斯皮尔曼等级相关系数
function correlation.spearman(x, y)
    validate_arrays(x, y)

    local n = #x

    -- 计算等级（处理重复值使用平均等级）
    local function compute_ranks(data)
        local indexed = {}
        for i = 1, #data do
            indexed[i] = {value = data[i], index = i}
        end

        -- 按值排序
        table.sort(indexed, function(a, b) return a.value < b.value end)

        -- 分配等级
        local ranks = {}
        local i = 1
        while i <= n do
            local j = i
            -- 找到所有相同的值
            while j < n and indexed[j + 1].value == indexed[i].value do
                j = j + 1
            end

            -- 计算平均等级
            local avg_rank = (i + j) / 2
            for k = i, j do
                ranks[indexed[k].index] = avg_rank
            end

            i = j + 1
        end

        return ranks
    end

    local rank_x = compute_ranks(x)
    local rank_y = compute_ranks(y)

    -- 计算等级差的平方和
    local sum_d2 = 0
    for i = 1, n do
        local d = rank_x[i] - rank_y[i]
        sum_d2 = sum_d2 + d * d
    end

    -- 斯皮尔曼公式
    return 1 - (6 * sum_d2) / (n * (n * n - 1))
end

-- 肯德尔等级相关系数 (tau-b)
function correlation.kendall(x, y)
    validate_arrays(x, y)

    local n = #x

    local concordant = 0
    local discordant = 0
    local ties_x = 0
    local ties_y = 0
    local ties_xy = 0

    for i = 1, n - 1 do
        for j = i + 1, n do
            local dx = x[i] - x[j]
            local dy = y[i] - y[j]

            if dx == 0 and dy == 0 then
                ties_xy = ties_xy + 1
            elseif dx == 0 then
                ties_x = ties_x + 1
            elseif dy == 0 then
                ties_y = ties_y + 1
            elseif dx * dy > 0 then
                concordant = concordant + 1
            else
                discordant = discordant + 1
            end
        end
    end

    -- Kendall's tau-b (处理重复值)
    local n_pairs = n * (n - 1) / 2
    local n1 = ties_x + concordant + discordant
    local n2 = ties_y + concordant + discordant

    if n1 == 0 or n2 == 0 then
        return 0
    end

    local tau = (concordant - discordant) / math.sqrt(n1 * n2)
    return tau
end

-----------------------------------------------------------------------------
-- 协方差矩阵和相关系数矩阵
-----------------------------------------------------------------------------

-- 计算协方差矩阵
-- data: 包含多个变量的表，每个变量是一个数组
function correlation.cov_matrix(data)
    if type(data) ~= "table" or #data == 0 then
        utils.Error.invalid_input("data must be a non-empty table")
    end

    local p = #data  -- 变量数
    local n = #data[1]  -- 样本数

    -- 验证所有变量长度相同
    for i = 2, p do
        if #data[i] ~= n then
            utils.Error.dimension_mismatch(#data[1], #data[i])
        end
    end

    -- 构建协方差矩阵
    local cov_mat = {}
    for i = 1, p do
        cov_mat[i] = {}
        for j = 1, p do
            cov_mat[i][j] = correlation.cov(data[i], data[j])
        end
    end

    return cov_mat
end

-- 计算相关系数矩阵
function correlation.corr_matrix(data)
    if type(data) ~= "table" or #data == 0 then
        utils.Error.invalid_input("data must be a non-empty table")
    end

    local p = #data
    local n = #data[1]

    for i = 2, p do
        if #data[i] ~= n then
            utils.Error.dimension_mismatch(#data[1], #data[i])
        end
    end

    local corr_mat = {}
    for i = 1, p do
        corr_mat[i] = {}
        for j = 1, p do
            if i == j then
                corr_mat[i][j] = 1
            else
                corr_mat[i][j] = correlation.corr(data[i], data[j])
            end
        end
    end

    return corr_mat
end

return correlation