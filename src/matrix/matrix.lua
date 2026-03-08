-- Matrix 类定义
local Matrix = {}
Matrix.__index = Matrix

local utils = require("utils.init")
local Validator = utils.validators
local Typecheck = utils.typecheck

-- 深度复制二维数组
local function deepcopy_2d(src)
    local dest = {}
    for i = 1, #src do
        dest[i] = {}
        for j = 1, #src[i] do
            dest[i][j] = src[i][j]
        end
    end
    return dest
end

-- 构造函数
function Matrix.new(data, rows, cols)
    -- 参数可以是：二维数组，或者一维数组 + 维度
    if type(data) == "table" and type(data[1]) == "table" then
        -- 二维数组形式
        Validator.assert_matrix(data)

        rows = rows or #data
        cols = cols or (#data[1] > 0 and #data[1] or 0)

        local self = {
            rows = rows,
            cols = cols,
            data = deepcopy_2d(data),
            _metadata = {
                is_square = rows == cols,
                is_symmetric = nil,
                is_positive_definite = nil,
                is_diagonal = nil,
                is_triangular = nil,
                rank = nil,
                condition = nil,
            },
            _cache = {
                det = nil,
                inv = nil,
                rank = nil,
                lu = nil,
                eig = nil,
            },
        }

        return setmetatable(self, Matrix)
    else
        -- 一维数组形式（按行优先顺序展开）
        Typecheck.check_table(data, "data")
        Typecheck.check_positive_integer(rows, "rows")
        Typecheck.check_positive_integer(cols, "cols")

        if #data ~= rows * cols then
            utils.Error.invalid_input(
                string.format("Data length (%d) does not match dimensions (%dx%d = %d)",
                    #data, rows, cols, rows * cols)
            )
        end

        local matrix_data = {}
        for i = 1, rows do
            matrix_data[i] = {}
            for j = 1, cols do
                matrix_data[i][j] = data[(i - 1) * cols + j]
            end
        end

        local self = {
            rows = rows,
            cols = cols,
            data = matrix_data,
            _metadata = {
                is_square = rows == cols,
                is_symmetric = nil,
                is_positive_definite = nil,
                is_diagonal = nil,
                is_triangular = nil,
                rank = nil,
                condition = nil,
            },
            _cache = {
                det = nil,
                inv = nil,
                rank = nil,
                lu = nil,
                eig = nil,
            },
        }

        return setmetatable(self, Matrix)
    end
end

-- 缓存失效
function Matrix:_invalidate_cache()
    self._cache = {
        det = nil,
        inv = nil,
        rank = nil,
        lu = nil,
        eig = nil,
    }
end

-- 元数据失效
function Matrix:_invalidate_metadata()
    self._metadata.is_symmetric = nil
    self._metadata.is_positive_definite = nil
    self._metadata.is_diagonal = nil
    self._metadata.is_triangular = nil
    self._metadata.rank = nil
    self._metadata.condition = nil
end

-- 元素访问
function Matrix:get(row, col)
    Typecheck.check_positive_integer(row, "row")
    Typecheck.check_positive_integer(col, "col")

    if row > self.rows or col > self.cols then
        utils.Error.out_of_bounds(row .. "," .. col, self.rows .. "x" .. self.cols)
    end

    return self.data[row][col]
end

function Matrix:set(row, col, value)
    Typecheck.check_positive_integer(row, "row")
    Typecheck.check_positive_integer(col, "col")
    Typecheck.check_number(value, "value")

    if row > self.rows or col > self.cols then
        utils.Error.out_of_bounds(row .. "," .. col, self.rows .. "x" .. self.cols)
    end

    self.data[row][col] = value
    self:_invalidate_cache()
    self:_invalidate_metadata()
end

-- 获取行
function Matrix:row(index)
    Typecheck.check_positive_integer(index, "index")

    if index > self.rows then
        utils.Error.out_of_bounds(index, self.rows)
    end

    local row_data = {}
    for j = 1, self.cols do
        row_data[j] = self.data[index][j]
    end
    return row_data
end

-- 获取列
function Matrix:col(index)
    Typecheck.check_positive_integer(index, "index")

    if index > self.cols then
        utils.Error.out_of_bounds(index, self.cols)
    end

    local col_data = {}
    for i = 1, self.rows do
        col_data[i] = self.data[i][index]
    end
    return col_data
end

-- 转置
function Matrix:transpose()
    local data = {}
    for i = 1, self.cols do
        data[i] = {}
        for j = 1, self.rows do
            data[i][j] = self.data[j][i]
        end
    end
    return Matrix.new(data)
end

-- 克隆
function Matrix:clone()
    local self_mt = getmetatable(self)
    local clone = {
        rows = self.rows,
        cols = self.cols,
        data = deepcopy_2d(self.data),
        _metadata = {
            is_square = self._metadata.is_square,
            is_symmetric = self._metadata.is_symmetric,
            is_positive_definite = self._metadata.is_positive_definite,
            is_diagonal = self._metadata.is_diagonal,
            is_triangular = self._metadata.is_triangular,
            rank = self._metadata.rank,
            condition = self._metadata.condition,
        },
        _cache = {
            det = self._cache.det,
            inv = nil,  -- 不克隆逆矩阵
            rank = self._cache.rank,
            lu = nil,   -- 不克隆 LU 分解
            eig = nil,  -- 不克隆特征值
        },
    }
    return setmetatable(clone, self_mt)
end

-- 格式化为字符串
function Matrix:__tostring()
    local rows = {}
    for i = 1, self.rows do
        local row_str = {}
        for j = 1, self.cols do
            local val = self.data[i][j]
            local fmt = val >= 0 and " %10.6f" or "%10.6f"
            row_str[j] = string.format(fmt, val)
        end
        rows[i] = "| " .. table.concat(row_str, " ") .. " |"
    end
    return table.concat(rows, "\n")
end

-- 返回类型
function Matrix:type()
    return "Matrix"
end

return Matrix
