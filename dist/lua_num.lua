-- lua_num - Lua 数值计算库
-- 单文件版本
-- 版本: 1.0.0
-- 生成时间: 2026-03-09 05:32:34--
-- 用法:
--   local num = dofile("lua_num.lua")
--   local A = num.matrix.rand(10, 10)
--   local det = A:det()
--
-- 许可证: MIT License

local lua_num = {}

-- 模块缓存
local _loaded = {}

-- 自定义 require 函数（延迟加载）
local _module_loaders = {}
local function _require(name)
    if _loaded[name] then
        return _loaded[name]
    end
    local loader = _module_loaders[name]
    if loader then
        _loaded[name] = loader()
        return _loaded[name]
    end
    error("Module not found: " .. name)
end

-- 替换全局 require
local _original_require = require
require = _require

-- ===========================================================================
-- 模块定义
-- ===========================================================================

-- 模块: utils.init
_module_loaders["utils.init"] = function()
    local utils = {}
    utils.constants = require("utils.constants")
    utils.Error = require("utils.error")
    utils.validators = require("utils.validators")
    utils.typecheck = require("utils.typecheck")
    utils.pi = utils.constants.pi
    utils.e = utils.constants.e
    utils.phi = utils.constants.phi
    utils.gamma = utils.constants.gamma
    utils.epsilon = utils.constants.epsilon
    utils.tiny = utils.constants.tiny
    utils.huge = utils.constants.huge
    utils.deg2rad = utils.constants.deg2rad
    utils.rad2deg = utils.constants.rad2deg
    utils.assert_matrix = utils.validators.assert_matrix
    utils.assert_square_matrix = utils.validators.assert_square_matrix
    utils.assert_same_dimensions = utils.validators.assert_same_dimensions
    utils.assert_can_multiply = utils.validators.assert_can_multiply
    function utils.abs(x) return math.abs(x) end
    function utils.sign(x) if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end end
    function utils.max(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] > m then m = v[i] end end return m end
    function utils.min(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] < m then m = v[i] end end return m end
    function utils.dot(v1, v2) if #v1 ~= #v2 then utils.Error.dimension_mismatch(#v1, #v2) end local s = 0 for i = 1, #v1 do s = s + v1[i] * v2[i] end return s end
    function utils.norm(v) local s = 0 for i = 1, #v do s = s + v[i] * v[i] end return math.sqrt(s) end
    return utils
    
end

-- 模块: utils.constants
_module_loaders["utils.constants"] = function()
    -- 数学常量模块
    local constants = {}
    
    -- 基础常量
    constants.pi = math.pi
    constants.e = math.exp(1)
    constants.phi = (1 + math.sqrt(5)) / 2  -- 黄金比例
    constants.gamma = 0.57721566490153286060651209008240243104215933593992  -- 欧拉-马歇罗尼常数
    
    -- 精度常量
    constants.epsilon = 2.220446049250313e-16  -- 机器精度 (double)
    constants.tiny = 1e-30  -- 最小正数
    constants.huge = math.huge  -- 无穷大
    
    -- 角度转换
    constants.deg2rad = math.pi / 180  -- 度转弧度
    constants.rad2deg = 180 / math.pi  -- 弧度转度
    
    return constants
    
end

-- 模块: utils.error
_module_loaders["utils.error"] = function()
    -- 错误处理模块
    local Error = {}
    
    -- 错误类型
    Error.Type = {
        INVALID_INPUT = "INVALID_INPUT",
        DIMENSION_MISMATCH = "DIMENSION_MISMATCH",
        SINGULAR_MATRIX = "SINGULAR_MATRIX",
        NO_CONVERGENCE = "NO_CONVERGENCE",
        OUT_OF_BOUNDS = "OUT_OF_BOUNDS",
        NOT_IMPLEMENTED = "NOT_IMPLEMENTED",
        NOT_POSITIVE_DEFINITE = "NOT_POSITIVE_DEFINITE",
    }
    
    -- 错误构造函数
    function Error.new(error_type, message, context)
        local err = {
            type = error_type,
            message = message or "An error occurred",
            context = context or {},
        }
    
        -- 为错误对象添加 tostring 方法
        setmetatable(err, {
            __tostring = function(self)
                local msg = string.format("[%s] %s", self.type, self.message)
                if next(self.context) ~= nil then
                    local ctx = {}
                    for k, v in pairs(self.context) do
                        table.insert(ctx, string.format("%s=%s", k, tostring(v)))
                    end
                    msg = msg .. " (" .. table.concat(ctx, ", ") .. ")"
                end
                return msg
            end,
        })
    
        return err
    end
    
    -- 快捷错误函数
    function Error.invalid_input(message)
        error(Error.new(Error.Type.INVALID_INPUT, message))
    end
    
    function Error.dimension_mismatch(expected, actual)
        error(Error.new(Error.Type.DIMENSION_MISMATCH,
            "Dimension mismatch",
            { expected = expected, actual = actual }))
    end
    
    function Error.singular_matrix(det_value)
        error(Error.new(Error.Type.SINGULAR_MATRIX,
            "Matrix is singular or nearly singular",
            { determinant = det_value }))
    end
    
    function Error.no_convergence(iterations, residual)
        error(Error.new(Error.Type.NO_CONVERGENCE,
            "Algorithm did not converge",
            { iterations = iterations, residual = residual }))
    end
    
    function Error.out_of_bounds(index, size)
        error(Error.new(Error.Type.OUT_OF_BOUNDS,
            "Index out of bounds",
            { index = index, size = size }))
    end
    
    function Error.not_implemented(feature)
        error(Error.new(Error.Type.NOT_IMPLEMENTED,
            "Feature not implemented",
            { feature = feature }))
    end
    
    function Error.not_positive_definite()
        error(Error.new(Error.Type.NOT_POSITIVE_DEFINITE,
            "Matrix is not positive definite"))
    end
    
    return Error
    
end

-- 模块: utils.validators
_module_loaders["utils.validators"] = function()
    -- 输入验证模块
    local Validator = {}
    local Error = require("utils.error")
    
    -- 矩阵验证
    function Validator.is_matrix(data)
        if type(data) ~= "table" then
            return false
        end
        if #data == 0 then
            return true  -- 空矩阵
        end
        local cols = #data[1]
        for i, row in ipairs(data) do
            if type(row) ~= "table" or #row ~= cols then
                return false
            end
            for j, val in ipairs(row) do
                if type(val) ~= "number" then
                    return false
                end
            end
        end
        return true
    end
    
    function Validator.is_square_matrix(matrix)
        return matrix.rows == matrix.cols
    end
    
    function Validator.same_dimensions(m1, m2)
        return m1.rows == m2.rows and m1.cols == m2.cols
    end
    
    function Validator.can_multiply(m1, m2)
        return m1.cols == m2.rows
    end
    
    -- 函数验证
    function Validator.is_callable(fn)
        if type(fn) == "function" then
            return true
        end
        -- 检查是否有 __call 元方法
        local mt = getmetatable(fn)
        return mt and mt.__call ~= nil
    end
    
    -- 区间验证
    function Validator.valid_interval(a, b)
        return type(a) == "number" and type(b) == "number" and a < b
    end
    
    function Validator.contains_root(f, a, b)
        local fa = f(a)
        local fb = f(b)
        return fa * fb <= 0
    end
    
    -- 数值验证
    function Validator.is_finite(x)
        return type(x) == "number" and x == x and math.abs(x) < math.huge
    end
    
    function Validator.is_positive(x)
        return type(x) == "number" and x > 0
    end
    
    function Validator.is_integer(x)
        return type(x) == "number" and x == math.floor(x)
    end
    
    -- 向量验证
    function Validator.is_vector(data)
        if type(data) ~= "table" then
            return false
        end
        for i, val in ipairs(data) do
            if type(val) ~= "number" then
                return false
            end
        end
        return true
    end
    
    -- 断言函数（抛出错误）
    function Validator.assert_matrix(data)
        if not Validator.is_matrix(data) then
            Error.invalid_input("Input must be a valid matrix (2D array of numbers)")
        end
    end
    
    function Validator.assert_square_matrix(matrix)
        if not Validator.is_square_matrix(matrix) then
            Error.invalid_input("Matrix must be square")
        end
    end
    
    function Validator.assert_same_dimensions(m1, m2)
        if not Validator.same_dimensions(m1, m2) then
            Error.dimension_mismatch(
                string.format("%dx%d", m1.rows, m1.cols),
                string.format("%dx%d", m2.rows, m2.cols)
            )
        end
    end
    
    function Validator.assert_can_multiply(m1, m2)
        if not Validator.can_multiply(m1, m2) then
            Error.dimension_mismatch(
                string.format("%dx%d", m1.rows, m1.cols),
                string.format("%dx%d", m2.rows, m2.cols)
            )
        end
    end
    
    function Validator.assert_callable(fn, name)
        name = name or "function"
        if not Validator.is_callable(fn) then
            Error.invalid_input(string.format("%s must be callable", name))
        end
    end
    
    function Validator.assert_valid_interval(a, b)
        if not Validator.valid_interval(a, b) then
            Error.invalid_input(string.format("Invalid interval: [%f, %f]", a, b))
        end
    end
    
    return Validator
    
end

-- 模块: utils.typecheck
_module_loaders["utils.typecheck"] = function()
    -- 类型检查模块
    local Typecheck = {}
    
    function Typecheck.check_number(value, name)
        name = name or "value"
        if type(value) ~= "number" then
            error(string.format("%s must be a number, got %s", name, type(value)))
        end
    end
    
    function Typecheck.check_positive_number(value, name)
        name = name or "value"
        Typecheck.check_number(value, name)
        if value <= 0 then
            error(string.format("%s must be positive, got %f", name, value))
        end
    end
    
    function Typecheck.check_integer(value, name)
        name = name or "value"
        Typecheck.check_number(value, name)
        if value ~= math.floor(value) then
            error(string.format("%s must be an integer, got %f", name, value))
        end
    end
    
    function Typecheck.check_positive_integer(value, name)
        name = name or "value"
        Typecheck.check_integer(value, name)
        if value < 1 then
            error(string.format("%s must be a positive integer, got %f", name, value))
        end
    end
    
    function Typecheck.check_table(value, name)
        name = name or "value"
        if type(value) ~= "table" then
            error(string.format("%s must be a table, got %s", name, type(value)))
        end
    end
    
    function Typecheck.check_function(value, name)
        name = name or "value"
        if type(value) ~= "function" then
            error(string.format("%s must be a function, got %s", name, type(value)))
        end
    end
    
    function Typecheck.check_boolean(value, name)
        name = name or "value"
        if type(value) ~= "boolean" then
            error(string.format("%s must be a boolean, got %s", name, type(value)))
        end
    end
    
    function Typecheck.check_string(value, name)
        name = name or "value"
        if type(value) ~= "string" then
            error(string.format("%s must be a string, got %s", name, type(value)))
        end
    end
    
    function Typecheck.check_non_zero_number(value, name)
        name = name or "value"
        Typecheck.check_number(value, name)
        if value == 0 then
            error(string.format("%s must be non-zero, got %f", name, value))
        end
    end
    
    -- 检查类型，支持两种调用方式：
    -- 1. check_type(value, expected_class, param_name) - 检查类实例
    -- 2. check_type(func_name, param_name, value, expected_type, expected_type2) - 检查基础类型（旧签名）
    function Typecheck.check_type(arg1, arg2, arg3, arg4, arg5)
        -- 检测调用方式：如果第一个参数是字符串且第二个也是字符串，则为旧签名
        if type(arg1) == "string" and type(arg2) == "string" then
            -- 旧签名：check_type(func_name, param_name, value, expected_type, expected_type2)
            local func_name, param_name, value, expected_type, expected_type2 = arg1, arg2, arg3, arg4, arg5
            if expected_type2 and value ~= nil and type(value) ~= expected_type2 and type(value) ~= expected_type then
                error(string.format("%s: %s must be a %s or %s, got %s",
                    func_name, param_name, expected_type, expected_type2, type(value)))
            elseif value ~= nil and type(value) ~= expected_type then
                error(string.format("%s: %s must be a %s, got %s",
                    func_name, param_name, expected_type, type(value)))
            end
        else
            -- 新签名：check_type(value, expected_class, param_name)
            local value, expected_class, param_name = arg1, arg2, arg3
            param_name = param_name or "value"
            if type(expected_class) == "string" then
                -- 检查基础类型
                if value ~= nil and type(value) ~= expected_class then
                    error(string.format("%s must be a %s, got %s",
                        param_name, expected_class, type(value)))
                end
            else
                -- 检查类实例（通过 metatable）
                if value == nil or type(value) ~= "table" or getmetatable(value) ~= expected_class then
                    error(string.format("%s must be a %s, got %s",
                        param_name, "expected type", value == nil and "nil" or type(value)))
                end
            end
        end
    end
    
    return Typecheck
    
end

-- 模块: matrix.matrix
_module_loaders["matrix.matrix"] = function()
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
    
end

-- 模块: matrix.basic_ops
_module_loaders["matrix.basic_ops"] = function()
    -- 矩阵基础运算模块
    local Matrix = require("matrix.matrix")
    local utils = require("utils.init")
    local Validator = utils.validators
    local Typecheck = utils.typecheck
    
    -- 加法
    function Matrix:add(other)
        if type(other) == "number" then
            -- 标量加法
            local result = self:clone()
            for i = 1, self.rows do
                for j = 1, self.cols do
                    result.data[i][j] = result.data[i][j] + other
                end
            end
            return result
        else
            -- 矩阵加法
            Validator.assert_same_dimensions(self, other)
    
            local result = Matrix.new({{}})
            result.rows = self.rows
            result.cols = self.cols
            result.data = {}
    
            for i = 1, self.rows do
                result.data[i] = {}
                for j = 1, self.cols do
                    result.data[i][j] = self.data[i][j] + other.data[i][j]
                end
            end
    
            return result
        end
    end
    
    -- 减法
    function Matrix:sub(other)
        if type(other) == "number" then
            -- 标量减法
            local result = self:clone()
            for i = 1, self.rows do
                for j = 1, self.cols do
                    result.data[i][j] = result.data[i][j] - other
                end
            end
            return result
        else
            -- 矩阵减法
            Validator.assert_same_dimensions(self, other)
    
            local result = Matrix.new({{}})
            result.rows = self.rows
            result.cols = self.cols
            result.data = {}
    
            for i = 1, self.rows do
                result.data[i] = {}
                for j = 1, self.cols do
                    result.data[i][j] = self.data[i][j] - other.data[i][j]
                end
            end
    
            return result
        end
    end
    
    -- 乘法
    function Matrix:mul(other)
        if type(other) == "number" then
            -- 标量乘法
            local result = self:clone()
            for i = 1, self.rows do
                for j = 1, self.cols do
                    result.data[i][j] = result.data[i][j] * other
                end
            end
            return result
        else
            -- 矩阵乘法
            Validator.assert_can_multiply(self, other)
    
            local result = Matrix.new({{}})
            result.rows = self.rows
            result.cols = other.cols
            result.data = {}
    
            for i = 1, self.rows do
                result.data[i] = {}
                for j = 1, other.cols do
                    local sum = 0
                    for k = 1, self.cols do
                        sum = sum + self.data[i][k] * other.data[k][j]
                    end
                    result.data[i][j] = sum
                end
            end
    
            return result
        end
    end
    
    -- 除法（标量）
    function Matrix:div(scalar)
        Typecheck.check_number(scalar, "scalar")
    
        if math.abs(scalar) < utils.tiny then
            utils.Error.invalid_input("Division by zero or near-zero value")
        end
    
        return self:mul(1 / scalar)
    end
    
    -- 逐元素乘法（Hadamard 乘积）
    function Matrix:elementwise_mul(other)
        Validator.assert_same_dimensions(self, other)
    
        local result = Matrix.new({{}})
        result.rows = self.rows
        result.cols = self.cols
        result.data = {}
    
        for i = 1, self.rows do
            result.data[i] = {}
            for j = 1, self.cols do
                result.data[i][j] = self.data[i][j] * other.data[i][j]
            end
        end
    
        return result
    end
    
    -- 逐元素除法
    function Matrix:elementwise_div(other)
        Validator.assert_same_dimensions(self, other)
    
        local result = Matrix.new({{}})
        result.rows = self.rows
        result.cols = self.cols
        result.data = {}
    
        for i = 1, self.rows do
            result.data[i] = {}
            for j = 1, self.cols do
                if math.abs(other.data[i][j]) < utils.tiny then
                    utils.Error.invalid_input("Division by zero in elementwise division")
                end
                result.data[i][j] = self.data[i][j] / other.data[i][j]
            end
        end
    
        return result
    end
    
    -- 逐元素幂
    function Matrix:elementwise_pow(power)
        Typecheck.check_number(power, "power")
    
        local result = self:clone()
        for i = 1, self.rows do
            for j = 1, self.cols do
                result.data[i][j] = result.data[i][j] ^ power
            end
        end
        return result
    end
    
    -- 原地加法
    function Matrix:add_inplace(other)
        if type(other) == "number" then
            for i = 1, self.rows do
                for j = 1, self.cols do
                    self.data[i][j] = self.data[i][j] + other
                end
            end
        else
            Validator.assert_same_dimensions(self, other)
            for i = 1, self.rows do
                for j = 1, self.cols do
                    self.data[i][j] = self.data[i][j] + other.data[i][j]
                end
            end
        end
        self:_invalidate_cache()
        return self
    end
    
    -- 原地减法
    function Matrix:sub_inplace(other)
        if type(other) == "number" then
            for i = 1, self.rows do
                for j = 1, self.cols do
                    self.data[i][j] = self.data[i][j] - other
                end
            end
        else
            Validator.assert_same_dimensions(self, other)
            for i = 1, self.rows do
                for j = 1, self.cols do
                    self.data[i][j] = self.data[i][j] - other.data[i][j]
                end
            end
        end
        self:_invalidate_cache()
        return self
    end
    
    -- 原地标量乘法
    function Matrix:mul_inplace(scalar)
        Typecheck.check_number(scalar, "scalar")
        for i = 1, self.rows do
            for j = 1, self.cols do
                self.data[i][j] = self.data[i][j] * scalar
            end
        end
        self:_invalidate_cache()
        return self
    end
    
    -- 运算符重载
    Matrix.__add = Matrix.add
    Matrix.__sub = Matrix.sub
    Matrix.__mul = Matrix.mul
    Matrix.__div = Matrix.div
    Matrix.__unm = function(self)
        return self:mul(-1)
    end
    Matrix.__pow = function(self, power)
        return self:elementwise_pow(power)
    end
    
    -- 等价比较
    function Matrix:__eq(other)
        if getmetatable(other) ~= Matrix then
            return false
        end
        if self.rows ~= other.rows or self.cols ~= other.cols then
            return false
        end
        for i = 1, self.rows do
            for j = 1, self.cols do
                if math.abs(self.data[i][j] - other.data[i][j]) > utils.epsilon * 10 then
                    return false
                end
            end
        end
        return true
    end
    
    return Matrix
    
end

-- 模块: matrix.advanced_ops
_module_loaders["matrix.advanced_ops"] = function()
    -- 矩阵高级运算模块
    local Matrix = require("matrix.matrix")
    require("matrix.basic_ops")  -- 加载基础运算
    local utils = require("utils.init")
    local Validator = utils.validators
    local Typecheck = utils.typecheck
    
    -- 行列式（使用 LU 分解）
    function Matrix:det()
        -- 检查缓存
        if self._cache.det ~= nil then
            return self._cache.det
        end
    
        Validator.assert_square_matrix(self)
    
        -- 特殊情况优化
        if self._metadata.is_diagonal then
            local det = 1
            for i = 1, self.rows do
                det = det * self.data[i][i]
            end
            self._cache.det = det
            return det
        end
    
        if self._metadata.is_triangular then
            local det = 1
            for i = 1, self.rows do
                det = det * self.data[i][i]
            end
            self._cache.det = det
            return det
        end
    
        -- 对于小矩阵，直接计算
        if self.rows <= 3 then
            local det = self:_det_small()
            self._cache.det = det
            return det
        end
    
        -- 使用 LU 分解计算行列式
        local L, U, P = self:lu()
        local det = 1
        for i = 1, #U.data do
            det = det * U.data[i][i]
        end
        -- 考虑置换矩阵的奇偶性
        local sign = P:_permutation_sign()
        self._cache.det = sign * det
        return self._cache.det
    end
    
    -- 小矩阵行列式计算（直接展开）
    function Matrix:_det_small()
        local n = self.rows
    
        if n == 1 then
            return self.data[1][1]
        elseif n == 2 then
            return self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]
        elseif n == 3 then
            return self.data[1][1] * (self.data[2][2] * self.data[3][3] - self.data[2][3] * self.data[3][2])
                 - self.data[1][2] * (self.data[2][1] * self.data[3][3] - self.data[2][3] * self.data[3][1])
                 + self.data[1][3] * (self.data[2][1] * self.data[3][2] - self.data[2][2] * self.data[3][1])
        end
    
        return 0
    end
    
    -- 矩阵范数
    function Matrix:norm(norm_type)
        norm_type = norm_type or "fro"
    
        if norm_type == "fro" then
            -- Frobenius 范数
            local sum = 0
            for i = 1, self.rows do
                for j = 1, self.cols do
                    sum = sum + self.data[i][j] ^ 2
                end
            end
            return math.sqrt(sum)
    
        elseif norm_type == 1 or norm_type == "1" then
            -- 1-范数（最大列和）
            local max_sum = 0
            for j = 1, self.cols do
                local col_sum = 0
                for i = 1, self.rows do
                    col_sum = col_sum + math.abs(self.data[i][j])
                end
                if col_sum > max_sum then
                    max_sum = col_sum
                end
            end
            return max_sum
    
        elseif norm_type == "inf" or norm_type == "infinity" then
            -- 无穷范数（最大行和）
            local max_sum = 0
            for i = 1, self.rows do
                local row_sum = 0
                for j = 1, self.cols do
                    row_sum = row_sum + math.abs(self.data[i][j])
                end
                if row_sum > max_sum then
                    max_sum = row_sum
                end
            end
            return max_sum
    
        else
            utils.Error.invalid_input("Unknown norm type: " .. tostring(norm_type))
        end
    end
    
    -- 矩阵的迹（对角线元素之和）
    function Matrix:trace()
        Validator.assert_square_matrix(self)
    
        local sum = 0
        for i = 1, self.rows do
            sum = sum + self.data[i][i]
        end
        return sum
    end
    
    -- 矩阵的秩（使用高斯消元）
    function Matrix:rank()
        if self._cache.rank ~= nil then
            return self._cache.rank
        end
    
        local A = self:clone()
        local rows, cols = A.rows, A.cols
        local rank = 0
        local lead = 1
    
        for r = 1, rows do
            if cols < lead then
                break
            end
    
            local i = r
            while A.data[i][lead] == 0 do
                i = i + 1
                if rows == i then
                    i = r
                    lead = lead + 1
                    if cols == lead then
                        A._cache.rank = rank
                        return rank
                    end
                end
            end
    
            -- 交换行
            if i ~= r then
                A.data[i], A.data[r] = A.data[r], A.data[i]
            end
    
            local val = A.data[r][lead]
            for j = 1, cols do
                A.data[r][j] = A.data[r][j] / val
            end
    
            for i = 1, rows do
                if i ~= r then
                    val = A.data[i][lead]
                    for j = 1, cols do
                        A.data[i][j] = A.data[i][j] - val * A.data[r][j]
                    end
                end
            end
    
            lead = lead + 1
            rank = rank + 1
        end
    
        self._cache.rank = rank
        return rank
    end
    
    -- 检查是否为对称矩阵
    function Matrix:is_symmetric()
        if not self._metadata.is_square then
            return false
        end
    
        if self._metadata.is_symmetric ~= nil then
            return self._metadata.is_symmetric
        end
    
        for i = 1, self.rows do
            for j = i + 1, self.cols do
                if math.abs(self.data[i][j] - self.data[j][i]) > utils.epsilon * 10 then
                    self._metadata.is_symmetric = false
                    return false
                end
            end
        end
    
        self._metadata.is_symmetric = true
        return true
    end
    
    -- 检查是否为对角矩阵
    function Matrix:is_diagonal()
        if not self._metadata.is_square then
            return false
        end
    
        if self._metadata.is_diagonal ~= nil then
            return self._metadata.is_diagonal
        end
    
        for i = 1, self.rows do
            for j = 1, self.cols do
                if i ~= j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                    self._metadata.is_diagonal = false
                    return false
                end
            end
        end
    
        self._metadata.is_diagonal = true
        return true
    end
    
    -- 检查是否为三角矩阵（上三角或下三角）
    function Matrix:is_triangular()
        if not self._metadata.is_square then
            return false
        end
    
        if self._metadata.is_triangular ~= nil then
            return self._metadata.is_triangular
        end
    
        local is_upper = true
        local is_lower = true
    
        for i = 1, self.rows do
            for j = 1, self.cols do
                if i > j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                    is_upper = false
                end
                if i < j and math.abs(self.data[i][j]) > utils.epsilon * 10 then
                    is_lower = false
                end
            end
        end
    
        self._metadata.is_triangular = is_upper or is_lower
        return self._metadata.is_triangular
    end
    
    -- 返回矩阵的形状
    function Matrix:shape()
        return self.rows, self.cols
    end
    
    -- 重塑矩阵（元素数量必须相同）
    function Matrix:reshape(new_rows, new_cols)
        Typecheck.check_positive_integer(new_rows, "new_rows")
        Typecheck.check_positive_integer(new_cols, "new_cols")
    
        if new_rows * new_cols ~= self.rows * self.cols then
            utils.Error.invalid_input(
                string.format("Cannot reshape %dx%d to %dx%d: element count mismatch",
                    self.rows, self.cols, new_rows, new_cols)
            )
        end
    
        -- 展平当前矩阵
        local flat = {}
        for i = 1, self.rows do
            for j = 1, self.cols do
                table.insert(flat, self.data[i][j])
            end
        end
    
        -- 重塑为新矩阵
        local new_data = {}
        local idx = 1
        for i = 1, new_rows do
            new_data[i] = {}
            for j = 1, new_cols do
                new_data[i][j] = flat[idx]
                idx = idx + 1
            end
        end
    
        return Matrix.new(new_data)
    end
    
    return Matrix
    
end

-- 模块: matrix.decompositions
_module_loaders["matrix.decompositions"] = function()
    -- 矩阵分解模块
    local Matrix = require("matrix.matrix")
    require("matrix.basic_ops")  -- 加载基础运算
    require("matrix.advanced_ops")  -- 加载高级运算
    local utils = require("utils.init")
    local Validator = utils.validators
    local Typecheck = utils.typecheck
    
    -- LU 分解（带部分主元选择）
    -- A = P^T * L * U
    -- L 是单位下三角矩阵，U 是上三角矩阵，P 是置换矩阵
    function Matrix:lu()
        if self._cache.lu ~= nil then
            return table.unpack(self._cache.lu)
        end
    
        Validator.assert_square_matrix(self)
    
        local n = self.rows
    
        -- 初始化 L 为单位矩阵，U 为 A 的副本
        local L = Matrix.new({{}})
        local U = self:clone()
        L.rows = n
        L.cols = n
        L.data = {}
        for i = 1, n do
            L.data[i] = {}
            for j = 1, n do
                if i == j then
                    L.data[i][j] = 1
                else
                    L.data[i][j] = 0
                end
            end
        end
    
        -- 初始化置换矩阵 P 为单位矩阵
        local P = Matrix.new({{}})
        P.rows = n
        P.cols = n
        P.data = {}
        for i = 1, n do
            P.data[i] = {}
            for j = 1, n do
                if i == j then
                    P.data[i][j] = 1
                else
                    P.data[i][j] = 0
                end
            end
        end
    
        -- 高斯消元
        for k = 1, n - 1 do
            -- 部分主元选择
            local max_row = k
            local max_val = math.abs(U.data[k][k])
            for i = k + 1, n do
                if math.abs(U.data[i][k]) > max_val then
                    max_row = i
                    max_val = math.abs(U.data[i][k])
                end
            end
    
            -- 如果需要，交换行
            if max_row ~= k then
                U.data[k], U.data[max_row] = U.data[max_row], U.data[k]
                P.data[k], P.data[max_row] = P.data[max_row], P.data[k]
            end
    
            -- 检查是否奇异
            if math.abs(U.data[k][k]) < utils.tiny then
                utils.Error.singular_matrix(U.data[k][k])
            end
    
            -- 消元
            for i = k + 1, n do
                L.data[i][k] = U.data[i][k] / U.data[k][k]
                for j = k, n do
                    U.data[i][j] = U.data[i][j] - L.data[i][k] * U.data[k][j]
                end
            end
        end
    
        self._cache.lu = { L, U, P }
        return L, U, P
    end
    
    -- QR 分解（Gram-Schmidt 正交化）
    -- A = Q * R
    -- Q 是正交矩阵，R 是上三角矩阵
    function Matrix:qr()
        local m = self.rows
        local n = self.cols
    
        -- 初始化 Q 为 A 的副本，R 为零矩阵
        local Q = self:clone()
        local R = Matrix.new({{}})
        R.rows = n
        R.cols = n
        R.data = {}
        for i = 1, n do
            R.data[i] = {}
            for j = 1, n do
                R.data[i][j] = 0
            end
        end
    
        -- Gram-Schmidt 正交化
        for k = 1, n do
            -- R[k,k] = norm(Q[k])
            local norm_sq = 0
            for i = 1, m do
                norm_sq = norm_sq + Q.data[i][k] ^ 2
            end
            R.data[k][k] = math.sqrt(norm_sq)
    
            -- Q[k] = Q[k] / R[k,k]
            if R.data[k][k] > utils.tiny then
                for i = 1, m do
                    Q.data[i][k] = Q.data[i][k] / R.data[k][k]
                end
            end
    
            -- 对后续列进行正交化
            for j = k + 1, n do
                -- R[k,j] = Q[k]' * Q[j]
                local dot = 0
                for i = 1, m do
                    dot = dot + Q.data[i][k] * Q.data[i][j]
                end
                R.data[k][j] = dot
    
                -- Q[j] = Q[j] - R[k,j] * Q[k]
                for i = 1, m do
                    Q.data[i][j] = Q.data[i][j] - R.data[k][j] * Q.data[i][k]
                end
            end
        end
    
        return Q, R
    end
    
    -- Cholesky 分解（仅适用于对称正定矩阵）
    -- A = L * L^T
    -- L 是下三角矩阵
    function Matrix:cholesky()
        Validator.assert_square_matrix(self)
    
        local n = self.rows
    
        -- 检查对称性
        if not self:is_symmetric() then
            utils.Error.not_positive_definite()
        end
    
        -- 初始化 L 为零矩阵
        local L = Matrix.new({{}})
        L.rows = n
        L.cols = n
        L.data = {}
        for i = 1, n do
            L.data[i] = {}
            for j = 1, n do
                L.data[i][j] = 0
            end
        end
    
        -- Cholesky 分解
        for i = 1, n do
            for j = 1, i do
                local sum = 0
    
                if j == i then
                    -- 对角线元素
                    for k = 1, j - 1 do
                        sum = sum + L.data[j][k] ^ 2
                    end
                    local val = self.data[j][j] - sum
                    if val < -utils.tiny then
                        utils.Error.not_positive_definite()
                    end
                    if val < 0 then
                        val = 0
                    end
                    L.data[j][j] = math.sqrt(val)
    
                    if L.data[j][j] < utils.tiny then
                        utils.Error.not_positive_definite()
                    end
                else
                    -- 非对角线元素
                    for k = 1, j - 1 do
                        sum = sum + L.data[i][k] * L.data[j][k]
                    end
                    L.data[i][j] = (self.data[i][j] - sum) / L.data[j][j]
                end
            end
        end
    
        return L
    end
    
    -- 计算置换矩阵的符号（奇偶性）
    function Matrix:_permutation_sign()
        local n = self.rows
    
        -- 检查是否为置换矩阵
        for i = 1, n do
            local has_one = false
            for j = 1, n do
                if math.abs(self.data[i][j] - 1) < utils.epsilon then
                    if has_one then
                        return 1  -- 不是置换矩阵
                    end
                    has_one = true
                elseif math.abs(self.data[i][j]) > utils.epsilon then
                    return 1  -- 不是置换矩阵
                end
            end
            if not has_one then
                return 1  -- 不是置换矩阵
            end
        end
    
        -- 计算符号（通过跟踪交换次数）
        local visited = {}
        local sign = 1
    
        for i = 1, n do
            if not visited[i] then
                local cycle_length = 0
                local j = i
                while not visited[j] do
                    visited[j] = true
                    cycle_length = cycle_length + 1
                    -- 找到 j 列中 1 的位置
                    for k = 1, n do
                        if math.abs(self.data[k][j] - 1) < utils.epsilon then
                            j = k
                            break
                        end
                    end
                end
                if cycle_length > 1 and cycle_length % 2 == 0 then
                    sign = -sign
                end
            end
        end
    
        return sign
    end
    
    return Matrix
    
end

-- 模块: matrix.solvers
_module_loaders["matrix.solvers"] = function()
    -- 线性方程组求解模块
    local Matrix = require("matrix.matrix")
    require("matrix.basic_ops")  -- 加载基础运算
    require("matrix.advanced_ops")  -- 加载高级运算
    require("matrix.decompositions")  -- 加载矩阵分解
    local utils = require("utils.init")
    local Validator = utils.validators
    local Typecheck = utils.typecheck
    
    -- 求解线性方程组 Ax = b
    -- 使用 LU 分解
    function Matrix:solve(b)
        Validator.assert_square_matrix(self)
    
        if self.rows ~= b.rows then
            utils.Error.dimension_mismatch(
                string.format("A has %d rows, b has %d rows", self.rows, b.rows)
            )
        end
    
        -- 使用 LU 分解求解
        local L, U, P = self:lu()
    
        -- 应用置换矩阵: Pb
        local Pb = P:mul(b)
    
        -- 前向代入: Ly = Pb
        local y = Matrix.new({{}})
        y.rows = self.rows
        y.cols = b.cols
        y.data = {}
    
        for j = 1, b.cols do
            for i = 1, self.rows do
                local sum = 0
                for k = 1, i - 1 do
                    sum = sum + L.data[i][k] * y.data[k][j]
                end
                y.data[i] = y.data[i] or {}
                y.data[i][j] = Pb.data[i][j] - sum
            end
        end
    
        -- 回代: Ux = y
        local x = Matrix.new({{}})
        x.rows = self.rows
        x.cols = b.cols
        x.data = {}
    
        for j = 1, b.cols do
            for i = self.rows, 1, -1 do
                local sum = 0
                for k = i + 1, self.rows do
                    sum = sum + U.data[i][k] * x.data[k][j]
                end
                x.data[i] = x.data[i] or {}
                x.data[i][j] = (y.data[i][j] - sum) / U.data[i][i]
            end
        end
    
        return x
    end
    
    -- 矩阵求逆（使用 LU 分解）
    function Matrix:inverse()
        if self._cache.inv ~= nil then
            return self._cache.inv
        end
    
        Validator.assert_square_matrix(self)
    
        -- 创建单位矩阵
        local I = Matrix.new({{}})
        I.rows = self.rows
        I.cols = self.cols
        I.data = {}
    
        for i = 1, self.rows do
            I.data[i] = {}
            for j = 1, self.cols do
                if i == j then
                    I.data[i][j] = 1
                else
                    I.data[i][j] = 0
                end
            end
        end
    
        -- 求解 AI = I 的列
        local inv = self:solve(I)
        self._cache.inv = inv
        return inv
    end
    
    -- 伪逆（Moore-Penrose 伪逆）
    -- 使用 SVD 近似实现（这里使用 QR 分解简化）
    function Matrix:pseudo_inverse()
        local m = self.rows
        local n = self.cols
    
        if m == n then
            -- 方阵，尝试求逆
            local det = self:det()
            if math.abs(det) > utils.tiny then
                return self:inverse()
            end
        end
    
        if m > n then
            -- 高矩阵：使用 QR 分解
            local Q, R = self:qr()
            local R_inv = R:inverse()
            local Q_T = Q:transpose()
            return R_inv:mul(Q_T)
        else
            -- 宽矩阵：使用转置的伪逆
            return self:transpose():pseudo_inverse():transpose()
        end
    end
    
    -- 最小二乘解
    -- 求解 min ||Ax - b||²
    function Matrix:least_squares(b)
        local m = self.rows
        local n = self.cols
    
        if m >= n then
            -- 使用正规方程: (A'A)x = A'b
            local A_T = self:transpose()
            local A_T_A = A_T:mul(self)
            local A_T_b = A_T:mul(b)
    
            return A_T_A:solve(A_T_b)
        else
            -- 欠定系统，返回最小范数解
            return self:pseudo_inverse():mul(b)
        end
    end
    
    return Matrix
    
end

-- 模块: matrix.special_matrices
_module_loaders["matrix.special_matrices"] = function()
    -- 特殊矩阵生成模块
    local Matrix = require("matrix.matrix")
    local Typecheck = require("utils.init").typecheck
    
    local M = {}
    
    -- 零矩阵
    function M.zeros(rows, cols)
        Typecheck.check_positive_integer(rows, "rows")
        Typecheck.check_positive_integer(cols, "cols")
    
        local data = {}
        for i = 1, rows do
            data[i] = {}
            for j = 1, cols do
                data[i][j] = 0
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 全1矩阵
    function M.ones(rows, cols)
        Typecheck.check_positive_integer(rows, "rows")
        Typecheck.check_positive_integer(cols, "cols")
    
        local data = {}
        for i = 1, rows do
            data[i] = {}
            for j = 1, cols do
                data[i][j] = 1
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 单位矩阵（方阵）
    function M.eye(n)
        Typecheck.check_positive_integer(n, "n")
    
        local data = {}
        for i = 1, n do
            data[i] = {}
            for j = 1, n do
                if i == j then
                    data[i][j] = 1
                else
                    data[i][j] = 0
                end
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 对角矩阵
    function M.diag(diagonal_values)
        Typecheck.check_table(diagonal_values, "diagonal_values")
    
        local n = #diagonal_values
        local data = {}
        for i = 1, n do
            data[i] = {}
            for j = 1, n do
                if i == j then
                    data[i][j] = diagonal_values[i]
                else
                    data[i][j] = 0
                end
            end
        end
    
        local m = Matrix.new(data)
        m._metadata.is_diagonal = true
        m._metadata.is_square = true
        return m
    end
    
    -- 随机矩阵（均匀分布 [0, 1)）
    function M.rand(rows, cols)
        Typecheck.check_positive_integer(rows, "rows")
        Typecheck.check_positive_integer(cols, "cols")
    
        local data = {}
        for i = 1, rows do
            data[i] = {}
            for j = 1, cols do
                data[i][j] = math.random()
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 随机整数矩阵
    function M.rand_int(rows, cols, min, max)
        Typecheck.check_positive_integer(rows, "rows")
        Typecheck.check_positive_integer(cols, "cols")
        Typecheck.check_integer(min, "min")
        Typecheck.check_integer(max, "max")
    
        if min > max then
            error("min must be less than or equal to max")
        end
    
        local data = {}
        for i = 1, rows do
            data[i] = {}
            for j = 1, cols do
                data[i][j] = math.random(min, max)
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 随机正定矩阵（对称）
    function M.rand_spd(n)
        Typecheck.check_positive_integer(n, "n")
    
        -- 生成随机矩阵 A
        local A = M.rand(n, n)
    
        -- 计算 A * A^T，保证对称正定
        local A_T = A:transpose()
        local spd = A:mul(A_T)
    
        -- 添加对角线元素以保证正定性
        for i = 1, n do
            spd.data[i][i] = spd.data[i][i] + n
        end
    
        spd._metadata.is_symmetric = true
        spd._metadata.is_square = true
        return spd
    end
    
    -- Hilbert 矩阵（著名的病态矩阵）
    function M.hilbert(n)
        Typecheck.check_positive_integer(n, "n")
    
        local data = {}
        for i = 1, n do
            data[i] = {}
            for j = 1, n do
                data[i][j] = 1 / (i + j - 1)
            end
        end
    
        local m = Matrix.new(data)
        m._metadata.is_symmetric = true
        m._metadata.is_square = true
        return m
    end
    
    -- Vandermonde 矩阵
    function M.vandermonde(x, n)
        Typecheck.check_table(x, "x")
        Typecheck.check_positive_integer(n, "n")
    
        local m = #x
        local data = {}
        for i = 1, m do
            data[i] = {}
            for j = 1, n do
                data[i][j] = x[i] ^ (n - j)
            end
        end
    
        return Matrix.new(data)
    end
    
    -- Toeplitz 矩阵（每条对角线上的元素相同）
    function M.toeplitz(first_row, first_col)
        Typecheck.check_table(first_row, "first_row")
    
        -- 如果只提供 first_row，假设对称
        if first_col == nil then
            first_col = {}
            for i, val in ipairs(first_row) do
                first_col[i] = val
            end
        end
    
        local rows = #first_col
        local cols = #first_row
    
        local data = {}
        for i = 1, rows do
            data[i] = {}
            for j = 1, cols do
                local diff = j - i
                if diff == 0 then
                    data[i][j] = first_col[1]
                elseif diff > 0 then
                    if diff <= #first_row then
                        data[i][j] = first_row[diff + 1]
                    else
                        data[i][j] = 0
                    end
                else
                    if -diff <= #first_col then
                        data[i][j] = first_col[-diff + 1]
                    else
                        data[i][j] = 0
                    end
                end
            end
        end
    
        return Matrix.new(data)
    end
    
    -- 循环矩阵（每行是前一行的循环移位）
    function M.circulant(first_row)
        Typecheck.check_table(first_row, "first_row")
    
        local n = #first_row
        local data = {}
        for i = 1, n do
            data[i] = {}
            for j = 1, n do
                local idx = (j - i) % n
                if idx < 0 then
                    idx = idx + n
                end
                data[i][j] = first_row[idx + 1]
            end
        end
    
        local m = Matrix.new(data)
        m._metadata.is_square = true
        return m
    end
    
    -- 块对角矩阵
    function M.block_diagonal(blocks)
        Typecheck.check_table(blocks, "blocks")
    
        if #blocks == 0 then
            return Matrix.new({{}})
        end
    
        -- 计算总维度
        local total_rows = 0
        local total_cols = 0
        for _, block in ipairs(blocks) do
            total_rows = total_rows + block.rows
            total_cols = total_cols + block.cols
        end
    
        -- 创建块对角矩阵
        local data = {}
        for i = 1, total_rows do
            data[i] = {}
            for j = 1, total_cols do
                data[i][j] = 0
            end
        end
    
        -- 填入块
        local row_offset = 0
        local col_offset = 0
        for _, block in ipairs(blocks) do
            for i = 1, block.rows do
                for j = 1, block.cols do
                    data[row_offset + i][col_offset + j] = block.data[i][j]
                end
            end
            row_offset = row_offset + block.rows
            col_offset = col_offset + block.cols
        end
    
        return Matrix.new(data)
    end
    
    return M
    
end

-- 模块: vector.vector
_module_loaders["vector.vector"] = function()
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
    
end

-- 模块: vector.basic_ops
_module_loaders["vector.basic_ops"] = function()
    -- Vector 基础运算
    local Vector = require("vector.vector")
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
    
    -- 加法（Vector + Vector 或 Vector + 标量）
    function Vector.__add(a, b)
        local result
    
        if type(b) == "table" and getmetatable(b) == Vector then
            -- Vector + Vector
            if a.size ~= b.size then
                utils.Error.dimension_mismatch(a.size, b.size)
            end
    
            result = {}
            for i = 1, a.size do
                result[i] = a.data[i] + b.data[i]
            end
            return Vector.new(result)
        elseif type(b) == "number" then
            -- Vector + 标量
            result = {}
            for i = 1, a.size do
                result[i] = a.data[i] + b
            end
            return Vector.new(result)
        else
            utils.Error.invalid_input("Invalid operand for Vector addition")
        end
    end
    
    -- 减法（Vector - Vector 或 Vector - 标量）
    function Vector.__sub(a, b)
        local result
    
        if type(b) == "table" and getmetatable(b) == Vector then
            -- Vector - Vector
            if a.size ~= b.size then
                utils.Error.dimension_mismatch(a.size, b.size)
            end
    
            result = {}
            for i = 1, a.size do
                result[i] = a.data[i] - b.data[i]
            end
            return Vector.new(result)
        elseif type(b) == "number" then
            -- Vector - 标量
            result = {}
            for i = 1, a.size do
                result[i] = a.data[i] - b
            end
            return Vector.new(result)
        else
            utils.Error.invalid_input("Invalid operand for Vector subtraction")
        end
    end
    
    -- 乘法（Vector * 标量）
    function Vector.__mul(a, b)
        local result
    
        if type(a) == "number" and type(b) == "table" and getmetatable(b) == Vector then
            -- 标量 * Vector
            result = {}
            for i = 1, b.size do
                result[i] = a * b.data[i]
            end
            return Vector.new(result)
        elseif type(b) == "number" then
            -- Vector * 标量
            result = {}
            for i = 1, a.size do
                result[i] = a.data[i] * b
            end
            return Vector.new(result)
        else
            utils.Error.invalid_input("Invalid operand for Vector multiplication")
        end
    end
    
    -- 除法（Vector / 标量）
    function Vector.__div(a, b)
        if type(b) ~= "number" or b == 0 then
            utils.Error.invalid_input("Vector can only be divided by a non-zero scalar")
        end
    
        local result = {}
        for i = 1, a.size do
            result[i] = a.data[i] / b
        end
        return Vector.new(result)
    end
    
    -- 负号（-Vector）
    function Vector.__unm(a)
        local result = {}
        for i = 1, a.size do
            result[i] = -a.data[i]
        end
        return Vector.new(result)
    end
    
    -- 相等比较
    function Vector.__eq(a, b)
        if type(b) ~= "table" or getmetatable(b) ~= Vector then
            return false
        end
    
        if a.size ~= b.size then
            return false
        end
    
        for i = 1, a.size do
            if math.abs(a.data[i] - b.data[i]) > utils.epsilon then
                return false
            end
        end
    
        return true
    end
    
    -- 点积
    function Vector:dot(other)
        Typecheck.check_type(other, Vector, "other")
    
        if self.size ~= other.size then
            utils.Error.dimension_mismatch(self.size, other.size)
        end
    
        local sum = 0
        for i = 1, self.size do
            sum = sum + self.data[i] * other.data[i]
        end
        return sum
    end
    
    -- 标量积（点积别名）
    function Vector:scalar_product(other)
        return self:dot(other)
    end
    
    -- 原地加法
    function Vector:add_inplace(other)
        if type(other) == "number" then
            for i = 1, self.size do
                self.data[i] = self.data[i] + other
            end
        elseif type(other) == "table" and getmetatable(other) == Vector then
            if self.size ~= other.size then
                utils.Error.dimension_mismatch(self.size, other.size)
            end
            for i = 1, self.size do
                self.data[i] = self.data[i] + other.data[i]
            end
        else
            utils.Error.invalid_input("Invalid operand for in-place addition")
        end
    
        self:_invalidate_cache()
    end
    
    -- 原地减法
    function Vector:sub_inplace(other)
        if type(other) == "number" then
            for i = 1, self.size do
                self.data[i] = self.data[i] - other
            end
        elseif type(other) == "table" and getmetatable(other) == Vector then
            if self.size ~= other.size then
                utils.Error.dimension_mismatch(self.size, other.size)
            end
            for i = 1, self.size do
                self.data[i] = self.data[i] - other.data[i]
            end
        else
            utils.Error.invalid_input("Invalid operand for in-place subtraction")
        end
    
        self:_invalidate_cache()
    end
    
    -- 原地乘法
    function Vector:mul_inplace(scalar)
        Typecheck.check_number(scalar, "scalar")
    
        for i = 1, self.size do
            self.data[i] = self.data[i] * scalar
        end
    
        self:_invalidate_cache()
    end
    
    -- 原地除法
    function Vector:div_inplace(scalar)
        Typecheck.check_number(scalar, "scalar")
    
        if scalar == 0 then
            utils.Error.invalid_input("Division by zero")
        end
    
        for i = 1, self.size do
            self.data[i] = self.data[i] / scalar
        end
    
        self:_invalidate_cache()
    end
    
    -- 逐元素乘法（Hadamard 乘积）
    function Vector:elementwise_mul(other)
        Typecheck.check_type(other, Vector, "other")
    
        if self.size ~= other.size then
            utils.Error.dimension_mismatch(self.size, other.size)
        end
    
        local result = {}
        for i = 1, self.size do
            result[i] = self.data[i] * other.data[i]
        end
        return Vector.new(result)
    end
    
    -- 逐元素除法
    function Vector:elementwise_div(other)
        Typecheck.check_type(other, Vector, "other")
    
        if self.size ~= other.size then
            utils.Error.dimension_mismatch(self.size, other.size)
        end
    
        local result = {}
        for i = 1, self.size do
            if other.data[i] == 0 then
                utils.Error.invalid_input("Division by zero at index " .. i)
            end
            result[i] = self.data[i] / other.data[i]
        end
        return Vector.new(result)
    end
    
    -- 逐元素幂
    function Vector:elementwise_pow(power)
        Typecheck.check_number(power, "power")
    
        local result = {}
        for i = 1, self.size do
            result[i] = self.data[i] ^ power
        end
        return Vector.new(result)
    end
    
    -- 拼接向量
    function Vector:concat(other)
        Typecheck.check_type(other, Vector, "other")
    
        local result = {}
        for i = 1, self.size do
            result[i] = self.data[i]
        end
        for i = 1, other.size do
            result[self.size + i] = other.data[i]
        end
        return Vector.new(result)
    end
    
    -- 填充向量
    function Vector:fill(value)
        Typecheck.check_number(value, "value")
    
        for i = 1, self.size do
            self.data[i] = value
        end
    
        self:_invalidate_cache()
    end
    
    -- 重置向量
    function Vector:reset()
        self:fill(0)
    end
    
    -- 交换元素
    function Vector:swap(i, j)
        Typecheck.check_positive_integer(i, "i")
        Typecheck.check_positive_integer(j, "j")
    
        if i > self.size or j > self.size then
            utils.Error.out_of_bounds("index", self.size)
        end
    
        self.data[i], self.data[j] = self.data[j], self.data[i]
        self:_invalidate_cache()
    end
    
    -- 反转向量
    function Vector:reverse()
        local result = {}
        for i = 1, self.size do
            result[i] = self.data[self.size - i + 1]
        end
        return Vector.new(result)
    end
    
    -- 排序
    function Vector:sort(reverse)
        local result = deepcopy(self.data)
        if reverse then
            table.sort(result, function(a, b) return a > b end)
        else
            table.sort(result)
        end
        return Vector.new(result)
    end
    
    -- 原地排序
    function Vector:sort_inplace(reverse)
        if reverse then
            table.sort(self.data, function(a, b) return a > b end)
        else
            table.sort(self.data)
        end
    end
    
    return Vector
    
end

-- 模块: vector.advanced_ops
_module_loaders["vector.advanced_ops"] = function()
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
    
end

-- 模块: vector.special_vectors
_module_loaders["vector.special_vectors"] = function()
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
    
end

-- 模块: integration.basic_integration
_module_loaders["integration.basic_integration"] = function()
    -- 基本数值积分方法
    -- 包括梯形法和辛普森法
    
    local math = math
    local utils = require("utils.init")
    
    -- 基本积分方法模块
    local basic_integration = {}
    
    -- 梯形法
    -- @param f 要积分的函数，接受一个数值参数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 子区间数（可选，默认为100）
    -- @return 积分近似值
    function basic_integration.trapezoidal(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 100
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / n
        local sum = (f(a) + f(b)) / 2
    
        for i = 1, n - 1 do
            sum = sum + f(a + i * h)
        end
    
        return sum * h
    end
    
    -- 辛普森法（需要偶数个子区间）
    -- @param f 要积分的函数，接受一个数值参数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 子区间数（可选，默认为100，必须是偶数）
    -- @return 积分近似值
    function basic_integration.simpson(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 100
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        -- 辛普森法需要偶数个子区间
        if n % 2 ~= 0 then
            n = n + 1  -- 调整为偶数
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / n
        local sum = f(a) + f(b)
    
        -- 奇数索引点（系数为4）
        for i = 1, n - 1, 2 do
            sum = sum + 4 * f(a + i * h)
        end
    
        -- 偶数索引点（系数为2）
        for i = 2, n - 2, 2 do
            sum = sum + 2 * f(a + i * h)
        end
    
        return sum * h / 3
    end
    
    -- 中点法则
    -- @param f 要积分的函数，接受一个数值参数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 子区间数（可选，默认为100）
    -- @return 积分近似值
    function basic_integration.midpoint(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 100
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / n
        local sum = 0
    
        for i = 0, n - 1 do
            sum = sum + f(a + (i + 0.5) * h)
        end
    
        return sum * h
    end
    
    -- 左端点法则
    -- @param f 要积分的函数，接受一个数值参数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 子区间数（可选，默认为100）
    -- @return 积分近似值
    function basic_integration.left_endpoint(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 100
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / n
        local sum = 0
    
        for i = 0, n - 1 do
            sum = sum + f(a + i * h)
        end
    
        return sum * h
    end
    
    -- 右端点法则
    -- @param f 要积分的函数，接受一个数值参数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 子区间数（可选，默认为100）
    -- @return 积分近似值
    function basic_integration.right_endpoint(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 100
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / n
        local sum = 0
    
        for i = 1, n do
            sum = sum + f(a + i * h)
        end
    
        return sum * h
    end
    
    return basic_integration
    
end

-- 模块: integration.advanced_integration
_module_loaders["integration.advanced_integration"] = function()
    -- 高级数值积分方法
    -- 包括自适应积分、龙贝格积分和高斯求积
    
    local math = math
    local utils = require("utils.init")
    local basic = require("integration.basic_integration")
    
    -- 高级积分方法模块
    local advanced_integration = {}
    
    -- 自适应积分（基于辛普森法）
    -- @param f 要积分的函数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param tol 容差（可选，默认为1e-8）
    -- @param max_iter 最大迭代次数（可选，默认为50）
    -- @return 积分近似值
    function advanced_integration.adaptive(f, a, b, tol, max_iter)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        tol = tol or 1e-8
        max_iter = max_iter or 50
    
        if type(tol) ~= "number" or tol <= 0 then
            utils.Error.invalid_argument("tol", "positive number", type(tol))
        end
        if type(max_iter) ~= "number" or max_iter <= 0 then
            utils.Error.invalid_argument("max_iter", "positive integer", type(max_iter))
        end
    
        if a == b then
            return 0
        end
    
        -- 递归函数
        local function adaptive_recursive(a, b, tol)
            local c = (a + b) / 2
            local whole = basic.simpson(f, a, b, 2)
            local left = basic.simpson(f, a, c, 2)
            local right = basic.simpson(f, c, b, 2)
    
            if math.abs(left + right - whole) < 15 * tol then
                return left + right + (left + right - whole) / 15
            else
                return adaptive_recursive(a, c, tol/2) + adaptive_recursive(c, b, tol/2)
            end
        end
    
        return adaptive_recursive(a, b, tol)
    end
    
    -- 龙贝格积分
    -- @param f 要积分的函数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 最大迭代次数（可选，默认为20）
    -- @param tol 容差（可选，默认为1e-10）
    -- @return 积分近似值
    function advanced_integration.romberg(f, a, b, n, tol)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 20
        tol = tol or 1e-10
    
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
        if type(tol) ~= "number" or tol <= 0 then
            utils.Error.invalid_argument("tol", "positive number", type(tol))
        end
    
        if a == b then
            return 0
        end
    
        -- 初始化龙贝格表
        local R = {}
        for i = 0, n do
            R[i] = {}
        end
    
        -- 梯形法则的递归关系
        local function trapezoid(n)
            local h = (b - a) / n
            local sum = f(a) + f(b)
            for i = 1, n - 1 do
                sum = sum + 2 * f(a + i * h)
            end
            return sum * h / 2
        end
    
        -- 计算第一列
        for k = 0, n do
            local points = 2^k
            R[k][0] = trapezoid(points)
        end
    
        -- 龙贝格外推
        for j = 1, n do
            for k = j, n do
                R[k][j] = R[k][j-1] + (R[k][j-1] - R[k-1][j-1]) / (4^j - 1)
            end
        end
    
        -- 检查收敛性
        for j = n, 2, -1 do
            if math.abs(R[n][j] - R[n][j-1]) < tol then
                return R[n][j]
            end
        end
    
        return R[n][n]
    end
    
    -- 高斯-勒让德求积（使用预计算的节点和权重）
    -- @param f 要积分的函数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 节点数（可选，默认为5，支持2,3,4,5）
    -- @return 积分近似值
    function advanced_integration.gauss(f, a, b, n)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 5
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
    
        if a == b then
            return 0
        end
    
        -- 高斯-勒让德节点和权重（标准化区间[-1, 1]）
        local nodes_weights = {
            [2] = {
                nodes = {-0.5773502691896257, 0.5773502691896257},
                weights = {1, 1}
            },
            [3] = {
                nodes = {-0.7745966692414834, 0, 0.7745966692414834},
                weights = {0.5555555555555556, 0.8888888888888888, 0.5555555555555556}
            },
            [4] = {
                nodes = {-0.8611363115940526, -0.3399810435848563, 0.3399810435848563, 0.8611363115940526},
                weights = {0.3478548451374538, 0.6521451548625461, 0.6521451548625461, 0.3478548451374538}
            },
            [5] = {
                nodes = {-0.9061798459386640, -0.5384693101056831, 0, 0.5384693101056831, 0.9061798459386640},
                weights = {0.2369268850561891, 0.4786286704993665, 0.5688888888888889, 0.4786286704993665, 0.2369268850561891}
            },
            [6] = {
                nodes = {-0.9324695142031521, -0.6612093864662645, -0.2386191860831969, 0.2386191860831969, 0.6612093864662645, 0.9324695142031521},
                weights = {0.1713244923791704, 0.3607615730481386, 0.4679139345726910, 0.4679139345726910, 0.3607615730481386, 0.1713244923791704}
            },
            [7] = {
                nodes = {-0.9491079123427585, -0.7415311855993945, -0.4058451513773972, 0, 0.4058451513773972, 0.7415311855993945, 0.9491079123427585},
                weights = {0.1294849661688697, 0.2797053914892766, 0.3818300505051189, 0.4179591836734694, 0.3818300505051189, 0.2797053914892766, 0.1294849661688697}
            },
            [8] = {
                nodes = {-0.9602898564975363, -0.7966664774136267, -0.5255324099163290, -0.1834346424956498, 0.1834346424956498, 0.5255324099163290, 0.7966664774136267, 0.9602898564975363},
                weights = {0.1012285362903763, 0.2223810344533745, 0.3137066458778873, 0.3626837833783620, 0.3626837833783620, 0.3137066458778873, 0.2223810344533745, 0.1012285362903763}
            }
        }
    
        -- 如果没有预计算的节点权重，使用梯形法
        local nw = nodes_weights[n]
        if not nw then
            return basic.trapezoidal(f, a, b, 100)
        end
    
        -- 坐标变换：从[a, b]到[-1, 1]
        local half_length = (b - a) / 2
        local center = (a + b) / 2
    
        local sum = 0
        for i = 1, n do
            local x_transformed = center + half_length * nw.nodes[i]
            sum = sum + nw.weights[i] * f(x_transformed)
        end
    
        return sum * half_length
    end
    
    -- 复合高斯求积
    -- 将积分区间分成若干子区间，在每个子区间上应用高斯求积
    -- @param f 要积分的函数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param n 每个子区间的节点数（可选，默认为5）
    -- @param m 子区间数（可选，默认为10）
    -- @return 积分近似值
    function advanced_integration.composite_gauss(f, a, b, n, m)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        n = n or 5
        m = m or 10
    
        if type(n) ~= "number" or n <= 0 then
            utils.Error.invalid_argument("n", "positive integer", type(n))
        end
        if type(m) ~= "number" or m <= 0 then
            utils.Error.invalid_argument("m", "positive integer", type(m))
        end
    
        if a == b then
            return 0
        end
    
        local h = (b - a) / m
        local sum = 0
    
        for i = 0, m - 1 do
            local left = a + i * h
            local right = a + (i + 1) * h
            sum = sum + advanced_integration.gauss(f, left, right, n)
        end
    
        return sum
    end
    
    -- 奇异积分处理（使用变量替换）
    -- @param f 要积分的函数
    -- @param a 积分下限
    -- @param b 积分上限
    -- @param type 奇异类型："left"（左端点）、"right"（右端点）、"both"（两端）
    -- @param method 积分方法（可选，默认为"gauss"）
    -- @return 积分近似值
    function advanced_integration.singular(f, a, b, singular_type, method)
        -- 参数验证
        if type(f) ~= "function" then
            utils.Error.invalid_argument("f", "function", type(f))
        end
        if type(a) ~= "number" then
            utils.Error.invalid_argument("a", "number", type(a))
        end
        if type(b) ~= "number" then
            utils.Error.invalid_argument("b", "number", type(b))
        end
    
        singular_type = singular_type or "both"
        method = method or "gauss"
    
        if singular_type ~= "left" and singular_type ~= "right" and singular_type ~= "both" then
            utils.Error.invalid_argument("type", "'left', 'right', or 'both'", type(singular_type))
        end
    
        if a == b then
            return 0
        end
    
        -- 定义被积函数（直接计算，避免中间变量的数值问题）
        local function transformed_f(t)
            if singular_type == "left" then
                -- 左端点奇异：x = a + (b-a)*t^2, t∈[0,1]
                local x = a + (b - a) * t * t
                return f(x) * 2 * (b - a) * t
            elseif singular_type == "right" then
                -- 右端点奇异：x = b - (b-a)*t^2, t∈[0,1]
                local x = b - (b - a) * t * t
                return f(x) * 2 * (b - a) * t
            else
                -- 两端奇异：x = a + (b-a)*(t+1)/2, t∈[-1,1]
                local x = a + (b - a) * (t + 1) / 2
                return f(x) * (b - a) / 2
            end
        end
    
        if method == "gauss" then
            if singular_type == "left" or singular_type == "right" then
                -- 积分区间为[0, 1]
                return advanced_integration.gauss(transformed_f, 0, 1, 5)
            else
                -- 积分区间为[-1, 1]
                return advanced_integration.gauss(transformed_f, -1, 1, 5)
            end
        else
            if singular_type == "left" or singular_type == "right" then
                return basic.simpson(transformed_f, 0, 1, 100)
            else
                return basic.simpson(transformed_f, -1, 1, 100)
            end
        end
    end
    
    return advanced_integration
    
end

-- 模块: integration.multi_integration
_module_loaders["integration.multi_integration"] = function()
    -- 多重积分方法模块
    -- 支持二重积分、三重积分和蒙特卡罗积分
    
    local math = math
    local utils = require("utils.init")
    
    local multi_integration = {}
    
    -- 高斯-勒让德节点和权重（标准化区间[-1, 1]）
    local gauss_nodes_weights = {
        [2] = {
            nodes = {-0.5773502691896257, 0.5773502691896257},
            weights = {1, 1}
        },
        [3] = {
            nodes = {-0.7745966692414834, 0, 0.7745966692414834},
            weights = {0.5555555555555556, 0.8888888888888888, 0.5555555555555556}
        },
        [4] = {
            nodes = {-0.8611363115940526, -0.3399810435848563, 0.3399810435848563, 0.8611363115940526},
            weights = {0.3478548451374538, 0.6521451548625461, 0.6521451548625461, 0.3478548451374538}
        },
        [5] = {
            nodes = {-0.9061798459386640, -0.5384693101056831, 0, 0.5384693101056831, 0.9061798459386640},
            weights = {0.2369268850561891, 0.4786286704993665, 0.5688888888888889, 0.4786286704993665, 0.2369268850561891}
        },
        [6] = {
            nodes = {-0.9324695142031521, -0.6612093864662645, -0.2386191860831969, 0.2386191860831969, 0.6612093864662645, 0.9324695142031521},
            weights = {0.1713244923791704, 0.3607615730481386, 0.4679139345726910, 0.4679139345726910, 0.3607615730481386, 0.1713244923791704}
        },
        [7] = {
            nodes = {-0.9491079123427585, -0.7415311855993945, -0.4058451513773972, 0, 0.4058451513773972, 0.7415311855993945, 0.9491079123427585},
            weights = {0.1294849661688697, 0.2797053914892766, 0.3818300505051189, 0.4179591836734694, 0.3818300505051189, 0.2797053914892766, 0.1294849661688697}
        },
        [8] = {
            nodes = {-0.9602898564975363, -0.7966664774136267, -0.5255324099163290, -0.1834346424956498, 0.1834346424956498, 0.5255324099163290, 0.7966664774136267, 0.9602898564975363},
            weights = {0.1012285362903763, 0.2223810344533745, 0.3137066458778873, 0.3626837833783620, 0.3626837833783620, 0.3137066458778873, 0.2223810344533745, 0.1012285362903763}
        }
    }
    
    -- =============================================================================
    -- 二重积分
    -- =============================================================================
    
    -- 二重积分 - 迭代梯形法
    -- @param f 二元函数 f(x, y)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param nx, ny 各方向的分割数（可选，默认50）
    -- @return 积分近似值
    local function double_trapezoidal(f, ax, bx, ay, by, nx, ny)
        nx = nx or 50
        ny = ny or 50
    
        local hx = (bx - ax) / nx
        local hy = (by - ay) / ny
        local sum = 0
    
        for i = 0, nx do
            local x = ax + i * hx
            local wx = 1
            if i == 0 or i == nx then wx = 0.5 end
    
            for j = 0, ny do
                local y = ay + j * hy
                local wy = 1
                if j == 0 or j == ny then wy = 0.5 end
    
                sum = sum + wx * wy * f(x, y)
            end
        end
    
        return sum * hx * hy
    end
    
    -- 二重积分 - 迭代辛普森法
    -- @param f 二元函数 f(x, y)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param nx, ny 各方向的分割数（可选，必须是偶数）
    -- @return 积分近似值
    local function double_simpson(f, ax, bx, ay, by, nx, ny)
        nx = nx or 50
        ny = ny or 50
    
        -- 确保是偶数
        if nx % 2 ~= 0 then nx = nx + 1 end
        if ny % 2 ~= 0 then ny = ny + 1 end
    
        local hx = (bx - ax) / nx
        local hy = (by - ay) / ny
        local sum = 0
    
        for i = 0, nx do
            local x = ax + i * hx
            local wx = 1
            if i == 0 or i == nx then
                wx = 1
            elseif i % 2 == 1 then
                wx = 4
            else
                wx = 2
            end
    
            for j = 0, ny do
                local y = ay + j * hy
                local wy = 1
                if j == 0 or j == ny then
                    wy = 1
                elseif j % 2 == 1 then
                    wy = 4
                else
                    wy = 2
                end
    
                sum = sum + wx * wy * f(x, y)
            end
        end
    
        return sum * hx * hy / 9
    end
    
    -- 二重积分 - 高斯求积法
    -- @param f 二元函数 f(x, y)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param n 每个方向的高斯节点数（可选，默认5，最大8）
    -- @return 积分近似值
    local function double_gauss(f, ax, bx, ay, by, n)
        n = n or 5
        -- 限制节点数最大为8
        if n > 8 then n = 8 end
        local nw = gauss_nodes_weights[n]
        if not nw then
            n = 5
            nw = gauss_nodes_weights[n]
        end
    
        -- 坐标变换
        local half_x = (bx - ax) / 2
        local center_x = (ax + bx) / 2
        local half_y = (by - ay) / 2
        local center_y = (ay + by) / 2
    
        local sum = 0
        for i = 1, n do
            local x = center_x + half_x * nw.nodes[i]
            local wx = nw.weights[i]
    
            for j = 1, n do
                local y = center_y + half_y * nw.nodes[j]
                local wy = nw.weights[j]
    
                sum = sum + wx * wy * f(x, y)
            end
        end
    
        return sum * half_x * half_y
    end
    
    -- 二重积分 - 统一接口
    -- @param f 二元函数 f(x, y)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param options 选项表：
    --   - method: 方法名（"trapezoidal", "simpson", "gauss"）
    --   - nx, ny: 各方向的分割数
    --   - n: 高斯节点数（用于gauss方法）
    -- @return 积分近似值
    function multi_integration.double(f, ax, bx, ay, by, options)
        -- 参数验证
        utils.typecheck.check_type("double", "f", f, "function")
        utils.typecheck.check_type("double", "ax", ax, "number")
        utils.typecheck.check_type("double", "bx", bx, "number")
        utils.typecheck.check_type("double", "ay", ay, "number")
        utils.typecheck.check_type("double", "by", by, "number")
        utils.typecheck.check_type("double", "options", options, "table", "nil")
    
        options = options or {}
        local method = options.method or "simpson"
        local nx = options.nx or options.n or 50
        local ny = options.ny or options.n or 50
    
        if method == "trapezoidal" then
            return double_trapezoidal(f, ax, bx, ay, by, nx, ny)
        elseif method == "simpson" then
            return double_simpson(f, ax, bx, ay, by, nx, ny)
        elseif method == "gauss" then
            return double_gauss(f, ax, bx, ay, by, options.n or 5)
        else
            utils.Error.invalid_argument("method", "'trapezoidal', 'simpson', or 'gauss'", method)
        end
    end
    
    -- 别名
    multi_integration.double_integral = multi_integration.double
    
    -- =============================================================================
    -- 三重积分
    -- =============================================================================
    
    -- 三重积分 - 迭代辛普森法
    -- @param f 三元函数 f(x, y, z)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param az, bz z 的积分区间
    -- @param nx, ny, nz 各方向的分割数
    -- @return 积分近似值
    local function triple_simpson(f, ax, bx, ay, by, az, bz, nx, ny, nz)
        nx = nx or 20
        ny = ny or 20
        nz = nz or 20
    
        -- 确保是偶数
        if nx % 2 ~= 0 then nx = nx + 1 end
        if ny % 2 ~= 0 then ny = ny + 1 end
        if nz % 2 ~= 0 then nz = nz + 1 end
    
        local hx = (bx - ax) / nx
        local hy = (by - ay) / ny
        local hz = (bz - az) / nz
        local sum = 0
    
        for i = 0, nx do
            local x = ax + i * hx
            local wx = 1
            if i == 0 or i == nx then
                wx = 1
            elseif i % 2 == 1 then
                wx = 4
            else
                wx = 2
            end
    
            for j = 0, ny do
                local y = ay + j * hy
                local wy = 1
                if j == 0 or j == ny then
                    wy = 1
                elseif j % 2 == 1 then
                    wy = 4
                else
                    wy = 2
                end
    
                for k = 0, nz do
                    local z = az + k * hz
                    local wz = 1
                    if k == 0 or k == nz then
                        wz = 1
                    elseif k % 2 == 1 then
                        wz = 4
                    else
                        wz = 2
                    end
    
                    sum = sum + wx * wy * wz * f(x, y, z)
                end
            end
        end
    
        return sum * hx * hy * hz / 27
    end
    
    -- 三重积分 - 高斯求积法
    -- @param f 三元函数 f(x, y, z)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param az, bz z 的积分区间
    -- @param n 每个方向的高斯节点数（默认5，最大8）
    -- @return 积分近似值
    local function triple_gauss(f, ax, bx, ay, by, az, bz, n)
        n = n or 5
        -- 限制节点数最大为8
        if n > 8 then n = 8 end
        local nw = gauss_nodes_weights[n]
        if not nw then
            n = 5
            nw = gauss_nodes_weights[n]
        end
    
        -- 坐标变换
        local half_x = (bx - ax) / 2
        local center_x = (ax + bx) / 2
        local half_y = (by - ay) / 2
        local center_y = (ay + by) / 2
        local half_z = (bz - az) / 2
        local center_z = (az + bz) / 2
    
        local sum = 0
        for i = 1, n do
            local x = center_x + half_x * nw.nodes[i]
            local wx = nw.weights[i]
    
            for j = 1, n do
                local y = center_y + half_y * nw.nodes[j]
                local wy = nw.weights[j]
    
                for k = 1, n do
                    local z = center_z + half_z * nw.nodes[k]
                    local wz = nw.weights[k]
    
                    sum = sum + wx * wy * wz * f(x, y, z)
                end
            end
        end
    
        return sum * half_x * half_y * half_z
    end
    
    -- 三重积分 - 统一接口
    -- @param f 三元函数 f(x, y, z)
    -- @param ax, bx x 的积分区间
    -- @param ay, by y 的积分区间
    -- @param az, bz z 的积分区间
    -- @param options 选项表
    -- @return 积分近似值
    function multi_integration.triple(f, ax, bx, ay, by, az, bz, options)
        -- 参数验证
        utils.typecheck.check_type("triple", "f", f, "function")
        utils.typecheck.check_type("triple", "ax", ax, "number")
        utils.typecheck.check_type("triple", "bx", bx, "number")
        utils.typecheck.check_type("triple", "ay", ay, "number")
        utils.typecheck.check_type("triple", "by", by, "number")
        utils.typecheck.check_type("triple", "az", az, "number")
        utils.typecheck.check_type("triple", "bz", bz, "number")
        utils.typecheck.check_type("triple", "options", options, "table", "nil")
    
        options = options or {}
        local method = options.method or "simpson"
        local nx = options.nx or options.n or 20
        local ny = options.ny or options.n or 20
        local nz = options.nz or options.n or 20
    
        if method == "simpson" then
            return triple_simpson(f, ax, bx, ay, by, az, bz, nx, ny, nz)
        elseif method == "gauss" then
            return triple_gauss(f, ax, bx, ay, by, az, bz, options.n or 5)
        else
            utils.Error.invalid_argument("method", "'simpson' or 'gauss'", method)
        end
    end
    
    -- 别名
    multi_integration.triple_integral = multi_integration.triple
    
    -- =============================================================================
    -- 蒙特卡罗积分
    -- =============================================================================
    
    -- 蒙特卡罗积分（适用于高维积分）
    -- @param f n元函数，接受一个表参数 {x1, x2, ..., xn}
    -- @param bounds 积分区域边界，形式为 {{a1, b1}, {a2, b2}, ..., {an, bn}}
    -- @param options 选项表：
    --   - n_samples: 采样点数（默认10000）
    --   - seed: 随机种子（可选）
    -- @return 积分近似值，估计误差
    function multi_integration.monte_carlo(f, bounds, options)
        -- 参数验证
        utils.typecheck.check_type("monte_carlo", "f", f, "function")
        utils.typecheck.check_type("monte_carlo", "bounds", bounds, "table")
        utils.typecheck.check_type("monte_carlo", "options", options, "table", "nil")
    
        options = options or {}
        local n_samples = options.n_samples or 10000
        local dim = #bounds
    
        -- 设置随机种子
        if options.seed then
            math.randomseed(options.seed)
        end
    
        -- 计算区域体积
        local volume = 1
        for i = 1, dim do
            volume = volume * (bounds[i][2] - bounds[i][1])
        end
    
        -- 采样
        local sum = 0
        local sum_sq = 0
    
        for s = 1, n_samples do
            -- 生成随机点
            local point = {}
            for i = 1, dim do
                local a, b = bounds[i][1], bounds[i][2]
                point[i] = a + math.random() * (b - a)
            end
    
            -- 计算函数值
            local fx = f(point)
            sum = sum + fx
            sum_sq = sum_sq + fx * fx
        end
    
        -- 计算均值和标准差
        local mean = sum / n_samples
        local variance = (sum_sq / n_samples - mean * mean) / n_samples
        local std_error = math.sqrt(variance)
    
        -- 返回积分值和估计误差
        return mean * volume, std_error * volume
    end
    
    -- =============================================================================
    -- 一般区域积分（通过指示函数）
    -- =============================================================================
    
    -- 一般区域上的蒙特卡罗积分
    -- @param f 被积函数
    -- @param bounds 包围盒边界 {{a1,b1}, {a2,b2}, ...}
    -- @param region 判断点是否在积分区域的函数，返回 true/false
    -- @param options 选项
    -- @return 积分近似值，估计误差
    function multi_integration.monte_carlo_region(f, bounds, region, options)
        -- 参数验证
        utils.typecheck.check_type("monte_carlo_region", "f", f, "function")
        utils.typecheck.check_type("monte_carlo_region", "bounds", bounds, "table")
        utils.typecheck.check_type("monte_carlo_region", "region", region, "function")
        utils.typecheck.check_type("monte_carlo_region", "options", options, "table", "nil")
    
        options = options or {}
        local n_samples = options.n_samples or 10000
        local dim = #bounds
    
        -- 设置随机种子
        if options.seed then
            math.randomseed(options.seed)
        end
    
        -- 计算包围盒体积
        local volume = 1
        for i = 1, dim do
            volume = volume * (bounds[i][2] - bounds[i][1])
        end
    
        -- 采样
        local sum = 0
        local sum_sq = 0
        local count_in_region = 0
    
        for s = 1, n_samples do
            -- 生成随机点
            local point = {}
            for i = 1, dim do
                local a, b = bounds[i][1], bounds[i][2]
                point[i] = a + math.random() * (b - a)
            end
    
            -- 检查是否在区域内
            if region(point) then
                local fx = f(point)
                sum = sum + fx
                sum_sq = sum_sq + fx * fx
                count_in_region = count_in_region + 1
            end
        end
    
        -- 计算积分
        local mean = sum / n_samples
        local variance = (sum_sq / n_samples - mean * mean) / n_samples
        local std_error = math.sqrt(math.abs(variance))
    
        return mean * volume, std_error * volume, count_in_region / n_samples
    end
    
    return multi_integration
end

-- 模块: interpolation.basic_interpolation
_module_loaders["interpolation.basic_interpolation"] = function()
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
    
end

-- 模块: interpolation.advanced_interpolation
_module_loaders["interpolation.advanced_interpolation"] = function()
    -- 高级插值方法模块
    local advanced_interpolation = {}
    local Validator = require("utils.validators")
    
    -- 辅助函数：验证插值点
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
    
    -- 辅助函数：三对角矩阵求解器（追赶法）
    -- 用于求解样条插值的线性方程组
    -- @param a 下对角线元素
    -- @param b 主对角线元素
    -- @param c 上对角线元素
    -- @param d 右端向量
    -- @return 解向量
    local function tridiagonal_solver(a, b, c, d)
        local n = #b
    
        -- 前向消元
        local c_prime = {}
        local d_prime = {}
    
        c_prime[1] = c[1] / b[1]
        d_prime[1] = d[1] / b[1]
    
        for i = 2, n do
            local denom = b[i] - a[i] * c_prime[i-1]
            c_prime[i] = (i < n) and (c[i] / denom) or 0
            d_prime[i] = (d[i] - a[i] * d_prime[i-1]) / denom
        end
    
        -- 回代
        local x = {}
        x[n] = d_prime[n]
    
        for i = n - 1, 1, -1 do
            x[i] = d_prime[i] - c_prime[i] * x[i + 1]
        end
    
        return x
    end
    
    -- 辅助函数：查找插值区间
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
    
    -- 三次样条插值 - 自然样条（自然边界条件）
    -- 使用三次样条函数进行插值，两端二阶导数为0
    -- @param x 要插值的点（单个值或数组）
    -- @param x_data x坐标数组（严格递增）
    -- @param y_data y坐标数组
    -- @return 插值结果
    function advanced_interpolation.spline(x, x_data, y_data)
        validate_interpolation_points(x_data, y_data)
    
        local n = #x_data
    
        if n == 2 then
            -- 只有两个点，退化为线性插值
            local basic = require("interpolation.basic_interpolation")
            return basic.linear(x, x_data, y_data)
        end
    
        -- 计算三次样条系数
        local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, "natural")
    
        -- 判断输入是单个值还是数组
        local is_array = type(x) == "table" and #x > 0
    
        if is_array then
            local results = {}
            for _, xi in ipairs(x) do
                results[#results + 1] = advanced_interpolation.spline_single(xi, x_data, coeffs)
            end
            return results
        else
            return advanced_interpolation.spline_single(x, x_data, coeffs)
        end
    end
    
    -- 计算三次样条系数（内部使用）
    -- @param x_data x坐标数组
    -- @param y_data y坐标数组
    -- @param bc 边界条件类型： "natural" 或 "clamped"
    -- @param bc_values 边界值（仅用于clamped条件）[dy0, dyn]
    -- @return 样条系数表 {a, b, c, d}
    function advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)
        local n = #x_data
        bc = bc or "natural"
    
        -- 计算区间长度和斜率
        local h = {}  -- 区间长度
        local mu = {} -- 比值 h[i]/(h[i] + h[i+1])
        local lam = {} -- 比值 h[i+1]/(h[i] + h[i+1])
        local delta = {} -- 斜率
    
        for i = 1, n - 1 do
            h[i] = x_data[i + 1] - x_data[i]
            if h[i] <= 0 then
                error("x_data must be strictly increasing")
            end
            delta[i] = (y_data[i + 1] - y_data[i]) / h[i]
        end
    
        for i = 2, n - 1 do
            mu[i] = h[i - 1] / (h[i - 1] + h[i])
            lam[i] = h[i] / (h[i - 1] + h[i])
        end
    
        -- 建立三对角矩阵，求解二阶导数 M[i]
        local a = {}
        local b = {}
        local c = {}
        local d = {}
    
        -- 自然边界条件：M[1] = M[n] = 0
        if bc == "natural" then
            b[1] = 1
            a[1] = 0
            c[1] = 0
            d[1] = 0
    
            b[n] = 1
            a[n] = 0
            c[n] = 0
            d[n] = 0
    
            for i = 2, n - 1 do
                a[i] = mu[i]
                b[i] = 2
                c[i] = lam[i]
                d[i] = 6 * (delta[i] - delta[i - 1]) / (h[i - 1] + h[i])
            end
        elseif bc == "clamped" then
            -- 固定边界条件：指定端点的一阶导数
            if not bc_values or #bc_values ~= 2 then
                error("clamped boundary condition requires bc_values = {dy0, dyn}")
            end
    
            local dy0, dyn = bc_values[1], bc_values[2]
    
            b[1] = 2 * h[1]
            a[1] = 0
            c[1] = h[1]
            d[1] = 6 * (delta[1] - dy0)
    
            a[n] = h[n - 1]
            b[n] = 2 * h[n - 1]
            c[n] = 0
            d[n] = 6 * (dyn - delta[n - 1])
    
            for i = 2, n - 1 do
                a[i] = mu[i]
                b[i] = 2
                c[i] = lam[i]
                d[i] = 6 * (delta[i] - delta[i - 1]) / (h[i - 1] + h[i])
            end
        else
            error(string.format("Unknown boundary condition: %s", bc))
        end
    
        -- 求解三对角方程组
        local M = tridiagonal_solver(a, b, c, d)
    
        -- 计算样条系数
        local coeffs = {
            a = {},  -- y[i]
            b = {},  -- (y[i+1] - y[i])/h[i] - h[i]*M[i]/2 - h[i]*(M[i+1] - M[i])/6
            c = {},  -- M[i]/2
            d = {}   -- (M[i+1] - M[i])/(6*h[i])
        }
    
        for i = 1, n - 1 do
            coeffs.a[i] = y_data[i]
            coeffs.b[i] = delta[i] - h[i] * (2 * M[i] + M[i + 1]) / 6
            coeffs.c[i] = M[i] / 2
            coeffs.d[i] = (M[i + 1] - M[i]) / (6 * h[i])
        end
    
        coeffs.M = M  -- 存储二阶导数，用于边界条件检查
        coeffs.h = h  -- 存储区间长度
    
        return coeffs
    end
    
    -- 三次样条插值的单个点计算（内部使用）
    -- @param x 要插值的点
    -- @param x_data x坐标数组
    -- @param coeffs 样条系数表
    -- @return 插值结果
    function advanced_interpolation.spline_single(x, x_data, coeffs)
        local n = #x_data
    
        -- 处理端点
        if x == x_data[1] then
            return coeffs.a[1]
        elseif x == x_data[n] then
            return coeffs.a[n - 1] +
                   coeffs.b[n - 1] * coeffs.h[n - 1] +
                   coeffs.c[n - 1] * coeffs.h[n - 1]^2 +
                   coeffs.d[n - 1] * coeffs.h[n - 1]^3
        end
    
        -- 查找区间
        local i = find_interval(x, x_data)
        local dx = x - x_data[i]
    
        -- 三次样条公式
        return coeffs.a[i] +
               coeffs.b[i] * dx +
               coeffs.c[i] * dx^2 +
               coeffs.d[i] * dx^3
    end
    
    -- 三次样条插值 - 固定边界条件
    -- 在端点处指定一阶导数值
    -- @param x 要插值的点
    -- @param x_data x坐标数组
    -- @param y_data y坐标数组
    -- @param dy0 起点的一阶导数
    -- @param dyn 终点的一阶导数
    -- @return 插值结果
    function advanced_interpolation.spline_clamped(x, x_data, y_data, dy0, dyn)
        validate_interpolation_points(x_data, y_data)
    
        local n = #x_data
        if n < 3 then
            local basic = require("interpolation.basic_interpolation")
            return basic.linear(x, x_data, y_data)
        end
    
        -- 计算固定边界条件的样条系数
        local coeffs = advanced_interpolation.compute_spline_coefficients(
            x_data, y_data, "clamped", {dy0, dyn}
        )
    
        -- 判断输入是单个值还是数组
        local is_array = type(x) == "table" and #x > 0
    
        if is_array then
            local results = {}
            for _, xi in ipairs(x) do
                results[#results + 1] = advanced_interpolation.spline_single(xi, x_data, coeffs)
            end
            return results
        else
            return advanced_interpolation.spline_single(x, x_data, coeffs)
        end
    end
    
    -- 样条插值的导数计算
    -- 计算样条函数在给定点的一阶导数
    -- @param x 要计算导数的点
    -- @param x_data x坐标数组
    -- @param y_data y坐标数组
    -- @param bc 边界条件类型（可选，默认"natural"）
    -- @param bc_values 边界值（可选）
    -- @return 导数值
    function advanced_interpolation.spline_derivative(x, x_data, y_data, bc, bc_values)
        local n = #x_data
        if n < 3 then
            -- 退化为线性插值，导数为常数
            local basic = require("interpolation.basic_interpolation")
            local h = x_data[2] - x_data[1]
            return (y_data[2] - y_data[1]) / h
        end
    
        bc = bc or "natural"
        local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)
    
        -- 计算导数
        local i = find_interval(x, x_data)
        local dx = x - x_data[i]
    
        -- 样条一阶导数: S'(x) = b + 2*c*dx + 3*d*dx^2
        return coeffs.b[i] + 2 * coeffs.c[i] * dx + 3 * coeffs.d[i] * dx^2
    end
    
    -- 样条插值的二阶导数计算
    -- @param x 要计算导数的点
    -- @param x_data x坐标数组
    -- @param y_data y坐标数组
    -- @param bc 边界条件类型（可选，默认"natural"）
    -- @param bc_values 边界值（可选）
    -- @return 二阶导数值
    function advanced_interpolation.spline_derivative2(x, x_data, y_data, bc, bc_values)
        local n = #x_data
        if n < 3 then
            -- 退化为线性插值，二阶导数为0
            return 0
        end
    
        bc = bc or "natural"
        local coeffs = advanced_interpolation.compute_spline_coefficients(x_data, y_data, bc, bc_values)
    
        -- 计算二阶导数
        local i = find_interval(x, x_data)
        local dx = x - x_data[i]
    
        -- 样条二阶导数: S''(x) = 2*c + 6*d*dx
        return 2 * coeffs.c[i] + 6 * coeffs.d[i] * dx
    end
    
    return advanced_interpolation
    
end

-- 模块: interpolation.multi_interpolation
_module_loaders["interpolation.multi_interpolation"] = function()
    -- 多维插值方法模块
    -- 支持双线性插值、双三次插值、径向基函数插值等
    
    local math = math
    local utils = require("utils.init")
    
    local multi_interpolation = {}
    
    -- =============================================================================
    -- 双线性插值
    -- =============================================================================
    
    -- 在二维网格上进行双线性插值
    -- @param x, y 要插值的点坐标
    -- @param x_data x坐标数组（严格递增）
    -- @param y_data y坐标数组（严格递增）
    -- @param z_grid 二维值网格，z_grid[i][j] 对应 (x_data[i], y_data[j])
    -- @return 插值结果
    function multi_interpolation.bilinear(x, y, x_data, y_data, z_grid)
        -- 参数验证
        utils.typecheck.check_type("bilinear", "x", x, "number")
        utils.typecheck.check_type("bilinear", "y", y, "number")
        utils.typecheck.check_type("bilinear", "x_data", x_data, "table")
        utils.typecheck.check_type("bilinear", "y_data", y_data, "table")
        utils.typecheck.check_type("bilinear", "z_grid", z_grid, "table")
    
        local nx, ny = #x_data, #y_data
    
        -- 检查范围
        if x < x_data[1] or x > x_data[nx] then
            error(string.format("x=%f is outside the interpolation range [%f, %f]",
                x, x_data[1], x_data[nx]))
        end
        if y < y_data[1] or y > y_data[ny] then
            error(string.format("y=%f is outside the interpolation range [%f, %f]",
                y, y_data[1], y_data[ny]))
        end
    
        -- 查找x区间
        local ix = 1
        for i = 1, nx - 1 do
            if x_data[i] <= x and x <= x_data[i + 1] then
                ix = i
                break
            end
        end
    
        -- 查找y区间
        local iy = 1
        for j = 1, ny - 1 do
            if y_data[j] <= y and y <= y_data[j + 1] then
                iy = j
                break
            end
        end
    
        -- 四个角点的值
        local z11 = z_grid[ix][iy]
        local z21 = z_grid[ix + 1][iy]
        local z12 = z_grid[ix][iy + 1]
        local z22 = z_grid[ix + 1][iy + 1]
    
        -- 双线性插值
        local x1, x2 = x_data[ix], x_data[ix + 1]
        local y1, y2 = y_data[iy], y_data[iy + 1]
    
        local tx = (x - x1) / (x2 - x1)
        local ty = (y - y1) / (y2 - y1)
    
        -- 双线性插值公式
        local z = (1 - tx) * (1 - ty) * z11 +
                  tx * (1 - ty) * z21 +
                  (1 - tx) * ty * z12 +
                  tx * ty * z22
    
        return z
    end
    
    -- 批量双线性插值
    -- @param points 点数组 {{x1,y1}, {x2,y2}, ...}
    -- @param x_data, y_data, z_grid 同上
    -- @return 插值结果数组
    function multi_interpolation.bilinear_batch(points, x_data, y_data, z_grid)
        utils.typecheck.check_type("bilinear_batch", "points", points, "table")
    
        local results = {}
        for i, pt in ipairs(points) do
            results[i] = multi_interpolation.bilinear(pt[1], pt[2], x_data, y_data, z_grid)
        end
        return results
    end
    
    -- =============================================================================
    -- 双三次插值
    -- =============================================================================
    
    -- 三次Hermite基函数
    local function cubic_hermite(t)
        local t2 = t * t
        local t3 = t2 * t
        -- 使用Catmull-Rom样条的导数近似
        return {
            1 - 3*t2 + 2*t3,   -- H0
            t - 2*t2 + t3,     -- H1 (导数基)
            3*t2 - 2*t3,       -- H2
            -t2 + t3           -- H3 (导数基)
        }
    end
    
    -- 一维三次插值（用于双三次插值）
    local function cubic_interp_1d(t, f0, f1, f2, f3)
        -- Catmull-Rom样条
        local t2 = t * t
        local t3 = t2 * t
    
        return 0.5 * (
            (2*f1) +
            (-f0 + f2) * t +
            (2*f0 - 5*f1 + 4*f2 - f3) * t2 +
            (-f0 + 3*f1 - 3*f2 + f3) * t3
        )
    end
    
    -- 双三次插值（使用Catmull-Rom样条）
    -- @param x, y 要插值的点坐标
    -- @param x_data x坐标数组
    -- @param y_data y坐标数组
    -- @param z_grid 二维值网格
    -- @return 插值结果
    function multi_interpolation.bicubic(x, y, x_data, y_data, z_grid)
        -- 参数验证
        utils.typecheck.check_type("bicubic", "x", x, "number")
        utils.typecheck.check_type("bicubic", "y", y, "number")
        utils.typecheck.check_type("bicubic", "x_data", x_data, "table")
        utils.typecheck.check_type("bicubic", "y_data", y_data, "table")
        utils.typecheck.check_type("bicubic", "z_grid", z_grid, "table")
    
        local nx, ny = #x_data, #y_data
    
        -- 检查范围（边界处理）
        if x < x_data[1] or x > x_data[nx] then
            error(string.format("x=%f is outside the interpolation range [%f, %f]",
                x, x_data[1], x_data[nx]))
        end
        if y < y_data[1] or y > y_data[ny] then
            error(string.format("y=%f is outside the interpolation range [%f, %f]",
                y, y_data[1], y_data[ny]))
        end
    
        -- 查找中心区间
        local ix = math.max(2, math.min(nx - 2, 1))
        for i = 1, nx - 1 do
            if x_data[i] <= x and x <= x_data[i + 1] then
                ix = i
                break
            end
        end
    
        local iy = math.max(2, math.min(ny - 2, 1))
        for j = 1, ny - 1 do
            if y_data[j] <= y and y <= y_data[j + 1] then
                iy = j
                break
            end
        end
    
        -- 获取4x4邻域
        local x_idx = {}
        for i = -1, 2 do
            local idx = ix + i
            if idx < 1 then idx = 1
            elseif idx > nx then idx = nx end
            x_idx[i + 2] = idx
        end
    
        local y_idx = {}
        for j = -1, 2 do
            local idx = iy + j
            if idx < 1 then idx = 1
            elseif idx > ny then idx = ny end
            y_idx[j + 2] = idx
        end
    
        -- 计算插值
        local x1, x2 = x_data[ix], x_data[ix + 1]
        local y1, y2 = y_data[iy], y_data[iy + 1]
        local tx = (x - x1) / (x2 - x1)
        local ty = (y - y1) / (y2 - y1)
    
        -- 沿y方向插值4次
        local col_values = {}
        for i = 1, 4 do
            local f0 = z_grid[x_idx[1]][y_idx[i]]
            local f1 = z_grid[x_idx[2]][y_idx[i]]
            local f2 = z_grid[x_idx[3]][y_idx[i]]
            local f3 = z_grid[x_idx[4]][y_idx[i]]
            col_values[i] = cubic_interp_1d(tx, f0, f1, f2, f3)
        end
    
        -- 沿x方向插值
        local result = cubic_interp_1d(ty, col_values[1], col_values[2], col_values[3], col_values[4])
    
        return result
    end
    
    -- =============================================================================
    -- 径向基函数插值
    -- =============================================================================
    
    -- 常用径向基函数
    local rbf_kernels = {
        -- 高斯RBF: phi(r) = exp(-(r/epsilon)^2)
        gaussian = function(r, epsilon)
            epsilon = epsilon or 1.0
            return math.exp(-(r / epsilon) ^ 2)
        end,
    
        -- 多二次RBF: phi(r) = sqrt(1 + (r/epsilon)^2)
        multiquadric = function(r, epsilon)
            epsilon = epsilon or 1.0
            return math.sqrt(1 + (r / epsilon) ^ 2)
        end,
    
        -- 逆多二次RBF: phi(r) = 1 / sqrt(1 + (r/epsilon)^2)
        inverse_multiquadric = function(r, epsilon)
            epsilon = epsilon or 1.0
            return 1 / math.sqrt(1 + (r / epsilon) ^ 2)
        end,
    
        -- 薄板样条RBF: phi(r) = r^2 * log(r)
        thin_plate = function(r, epsilon)
            if r < 1e-10 then return 0 end
            return r * r * math.log(r)
        end,
    
        -- 线性RBF: phi(r) = r
        linear = function(r, epsilon)
            return r
        end,
    
        -- 三次RBF: phi(r) = r^3
        cubic = function(r, epsilon)
            return r * r * r
        end
    }
    
    -- 计算两点间的欧氏距离
    local function euclidean_distance(p1, p2)
        local sum = 0
        for i = 1, #p1 do
            local diff = p1[i] - p2[i]
            sum = sum + diff * diff
        end
        return math.sqrt(sum)
    end
    
    -- RBF插值求解器（内部使用）
    -- @param points 已知点集合 {{x1, y1, ...}, {x2, y2, ...}, ...}
    -- @param values 已知点的值
    -- @param kernel RBF核函数名
    -- @param epsilon RBF参数
    -- @return 插值权重
    local function rbf_solve(points, values, kernel, epsilon)
        local n = #points
        local kernel_func = rbf_kernels[kernel] or rbf_kernels.gaussian
    
        -- 构建矩阵 A[i][j] = phi(||pi - pj||)
        local A = {}
        for i = 1, n do
            A[i] = {}
            for j = 1, n do
                local r = euclidean_distance(points[i], points[j])
                A[i][j] = kernel_func(r, epsilon)
            end
        end
    
        -- 使用高斯消元法求解 A * w = values
        -- 创建增广矩阵
        local aug = {}
        for i = 1, n do
            aug[i] = {}
            for j = 1, n do
                aug[i][j] = A[i][j]
            end
            aug[i][n + 1] = values[i]
        end
    
        -- 前向消元
        for k = 1, n do
            -- 选主元
            local max_val = math.abs(aug[k][k])
            local max_row = k
            for i = k + 1, n do
                if math.abs(aug[i][k]) > max_val then
                    max_val = math.abs(aug[i][k])
                    max_row = i
                end
            end
            -- 交换行
            aug[k], aug[max_row] = aug[max_row], aug[k]
    
            if math.abs(aug[k][k]) < 1e-12 then
                error("RBF matrix is singular")
            end
    
            for i = k + 1, n do
                local factor = aug[i][k] / aug[k][k]
                for j = k, n + 1 do
                    aug[i][j] = aug[i][j] - factor * aug[k][j]
                end
            end
        end
    
        -- 回代
        local weights = {}
        for i = n, 1, -1 do
            local sum = aug[i][n + 1]
            for j = i + 1, n do
                sum = sum - aug[i][j] * weights[j]
            end
            weights[i] = sum / aug[i][i]
        end
    
        return weights
    end
    
    -- 径向基函数插值
    -- @param point 要插值的点 {x, y, ...}
    -- @param points 已知点集合 {{x1, y1, ...}, ...}
    -- @param values 已知点的值
    -- @param options 选项表：
    --   - kernel: RBF核函数名（"gaussian", "multiquadric", "inverse_multiquadric", "thin_plate", "linear", "cubic"）
    --   - epsilon: RBF参数
    --   - weights: 预计算的权重（可选，避免重复计算）
    -- @return 插值结果
    function multi_interpolation.rbf(point, points, values, options)
        -- 参数验证
        utils.typecheck.check_type("rbf", "point", point, "table")
        utils.typecheck.check_type("rbf", "points", points, "table")
        utils.typecheck.check_type("rbf", "values", values, "table")
    
        if #points ~= #values then
            error("points and values must have the same length")
        end
    
        options = options or {}
        local kernel = options.kernel or "gaussian"
        local epsilon = options.epsilon or 1.0
        local kernel_func = rbf_kernels[kernel]
    
        if not kernel_func then
            error("Unknown RBF kernel: " .. kernel)
        end
    
        -- 获取或计算权重
        local weights = options.weights
        if not weights then
            weights = rbf_solve(points, values, kernel, epsilon)
        end
    
        -- 计算插值
        local result = 0
        for i = 1, #points do
            local r = euclidean_distance(point, points[i])
            result = result + weights[i] * kernel_func(r, epsilon)
        end
    
        return result
    end
    
    -- 预计算RBF权重
    -- @param points 已知点集合
    -- @param values 已知点的值
    -- @param options RBF选项
    -- @return 权重数组
    function multi_interpolation.rbf_weights(points, values, options)
        utils.typecheck.check_type("rbf_weights", "points", points, "table")
        utils.typecheck.check_type("rbf_weights", "values", values, "table")
    
        options = options or {}
        local kernel = options.kernel or "gaussian"
        local epsilon = options.epsilon or 1.0
    
        return rbf_solve(points, values, kernel, epsilon)
    end
    
    -- =============================================================================
    -- 多元拉格朗日插值
    -- =============================================================================
    
    -- 多元拉格朗日插值（适用于散乱数据点）
    -- 注意：当点数较多时，计算量会很大
    -- @param point 要插值的点 {x, y, ...}
    -- @param points 已知点集合
    -- @param values 已知点的值
    -- @return 插值结果
    function multi_interpolation.multivariate_lagrange(point, points, values)
        -- 参数验证
        utils.typecheck.check_type("multivariate_lagrange", "point", point, "table")
        utils.typecheck.check_type("multivariate_lagrange", "points", points, "table")
        utils.typecheck.check_type("multivariate_lagrange", "values", values, "table")
    
        if #points ~= #values then
            error("points and values must have the same length")
        end
    
        local n = #points
        if n < 1 then
            error("At least one point is required for interpolation")
        end
    
        -- 计算拉格朗日插值
        local result = 0
    
        for i = 1, n do
            -- 计算拉格朗日基函数 L_i(point)
            local Li = 1
            for j = 1, n do
                if j ~= i then
                    -- 计算分子：||point - pj||^2
                    local num = 0
                    for k = 1, #point do
                        local diff = point[k] - points[j][k]
                        num = num + diff * diff
                    end
    
                    -- 计算分母：||pi - pj||^2
                    local denom = 0
                    for k = 1, #point do
                        local diff = points[i][k] - points[j][k]
                        denom = denom + diff * diff
                    end
    
                    if denom < 1e-20 then
                        -- 两点重合
                        Li = 0
                        break
                    end
    
                    Li = Li * num / denom
                end
            end
            result = result + values[i] * Li
        end
    
        return result
    end
    
    -- =============================================================================
    -- 最近邻插值
    -- =============================================================================
    
    -- 最近邻插值
    -- @param point 要插值的点 {x, y, ...}
    -- @param points 已知点集合
    -- @param values 已知点的值
    -- @return 插值结果
    function multi_interpolation.nearest_neighbor(point, points, values)
        -- 参数验证
        utils.typecheck.check_type("nearest_neighbor", "point", point, "table")
        utils.typecheck.check_type("nearest_neighbor", "points", points, "table")
        utils.typecheck.check_type("nearest_neighbor", "values", values, "table")
    
        if #points ~= #values then
            error("points and values must have the same length")
        end
    
        local min_dist = math.huge
        local nearest_value = values[1]
    
        for i = 1, #points do
            local dist = euclidean_distance(point, points[i])
            if dist < min_dist then
                min_dist = dist
                nearest_value = values[i]
            end
        end
    
        return nearest_value
    end
    
    -- =============================================================================
    -- 反距离加权插值（IDW）
    -- =============================================================================
    
    -- 反距离加权插值
    -- @param point 要插值的点 {x, y, ...}
    -- @param points 已知点集合
    -- @param values 已知点的值
    -- @param options 选项表：
    --   - power: 距离权重幂次（默认2）
    --   - radius: 搜索半径（可选，默认无限制）
    -- @return 插值结果
    function multi_interpolation.idw(point, points, values, options)
        -- 参数验证
        utils.typecheck.check_type("idw", "point", point, "table")
        utils.typecheck.check_type("idw", "points", points, "table")
        utils.typecheck.check_type("idw", "values", values, "table")
    
        if #points ~= #values then
            error("points and values must have the same length")
        end
    
        options = options or {}
        local power = options.power or 2
        local radius = options.radius
    
        local sum_weights = 0
        local sum_values = 0
    
        for i = 1, #points do
            local dist = euclidean_distance(point, points[i])
    
            -- 如果点重合，直接返回该值
            if dist < 1e-10 then
                return values[i]
            end
    
            -- 如果有搜索半径限制
            if radius and dist > radius then
                -- 跳过超出半径的点
            else
                local weight = 1 / (dist ^ power)
                sum_weights = sum_weights + weight
                sum_values = sum_values + weight * values[i]
            end
        end
    
        if sum_weights < 1e-10 then
            -- 没有有效点
            return 0
        end
    
        return sum_values / sum_weights
    end
    
    -- =============================================================================
    -- 统一接口
    -- =============================================================================
    
    -- 多维插值统一接口
    -- @param point 要插值的点（一维数组 {x, y, ...} 或二维点数组）
    -- @param data 插值数据（格式取决于方法）
    -- @param options 选项表
    -- @return 插值结果
    function multi_interpolation.interpolate(point, data, options)
        options = options or {}
        local method = options.method or "bilinear"
    
        if method == "bilinear" or method == "bicubic" then
            -- 规则网格插值
            local x, y = point[1], point[2]
            local x_data, y_data, z_grid = data.x_data, data.y_data, data.z_grid
    
            if method == "bilinear" then
                return multi_interpolation.bilinear(x, y, x_data, y_data, z_grid)
            else
                return multi_interpolation.bicubic(x, y, x_data, y_data, z_grid)
            end
        elseif method == "rbf" then
            -- 径向基函数插值
            return multi_interpolation.rbf(point, data.points, data.values, options)
        elseif method == "lagrange" or method == "multivariate_lagrange" then
            -- 多元拉格朗日插值
            return multi_interpolation.multivariate_lagrange(point, data.points, data.values)
        elseif method == "nearest" or method == "nearest_neighbor" then
            -- 最近邻插值
            return multi_interpolation.nearest_neighbor(point, data.points, data.values)
        elseif method == "idw" then
            -- 反距离加权插值
            return multi_interpolation.idw(point, data.points, data.values, options)
        else
            error("Unknown interpolation method: " .. method)
        end
    end
    
    -- 导出RBF核函数（供高级用户使用）
    multi_interpolation.rbf_kernels = rbf_kernels
    
    return multi_interpolation
end

-- 模块: optimization.basic_optimization
_module_loaders["optimization.basic_optimization"] = function()
    -- 基础优化方法：不需要导数的优化算法
    local utils = require("utils.init")
    
    local basic_optimization = {}
    
    -- 黄金分割法：寻找单峰函数的最小值
    -- @param f 目标函数
    -- @param a 搜索区间左端点
    -- @param b 搜索区间右端点
    -- @param tol 容差（默认 1e-6）
    -- @return 最小值位置，最小值，迭代次数
    function basic_optimization.golden_section(f, a, b, tol)
        -- 参数验证
        utils.typecheck.check_type("golden_section", "f", f, "function")
        utils.typecheck.check_type("golden_section", "a", a, "number")
        utils.typecheck.check_type("golden_section", "b", b, "number")
        utils.typecheck.check_type("golden_section", "tol", tol, "number", "nil")
    
        if a >= b then
            utils.Error.invalid_argument("golden_section", "a must be less than b")
        end
    
        tol = tol or 1e-6
    
        -- 黄金分割比
        local golden_ratio = (math.sqrt(5) - 1) / 2  -- 约 0.618
    
        -- 初始化两点
        local c = b - golden_ratio * (b - a)
        local d = a + golden_ratio * (b - a)
    
        local fc = f(c)
        local fd = f(d)
    
        local iter = 0
        local max_iter = 1000
    
        -- 迭代
        while (b - a) > tol and iter < max_iter do
            iter = iter + 1
    
            if fc < fd then
                b = d
                d = c
                fd = fc
                c = b - golden_ratio * (b - a)
                fc = f(c)
            else
                a = c
                c = d
                fc = fd
                d = a + golden_ratio * (b - a)
                fd = f(d)
            end
        end
    
        -- 返回区间中点作为最优解
        local x_opt = (a + b) / 2
        return x_opt, f(x_opt), iter
    end
    
    -- 抛物线插值法：使用三点抛物线拟合寻找极值点
    -- @param f 目标函数
    -- @param x1, x2, x3 三个点的 x 坐标
    -- @param tol 容差（默认 1e-6）
    -- @return 最小值位置，最小值，迭代次数
    function basic_optimization.parabolic_interpolation(f, x1, x2, x3, tol)
        -- 参数验证
        utils.typecheck.check_type("parabolic_interpolation", "f", f, "function")
        utils.typecheck.check_type("parabolic_interpolation", "x1", x1, "number")
        utils.typecheck.check_type("parabolic_interpolation", "x2", x2, "number")
        utils.typecheck.check_type("parabolic_interpolation", "x3", x3, "number")
        utils.typecheck.check_type("parabolic_interpolation", "tol", tol, "number", "nil")
    
        tol = tol or 1e-6
    
        local f1 = f(x1)
        local f2 = f(x2)
        local f3 = f(x3)
    
        local iter = 0
        local max_iter = 1000
    
        -- 找到当前最优点
        local x_best, f_best = x1, f1
        if f2 < f_best then x_best, f_best = x2, f2 end
        if f3 < f_best then x_best, f_best = x3, f3 end
    
        -- 迭代
        while iter < max_iter do
            iter = iter + 1
    
            -- 计算抛物线极值点
            local denom = 2 * ((x2 - x1) * (f3 - f2) - (x3 - x2) * (f2 - f1))
    
            if math.abs(denom) < utils.tiny then
                -- 分母接近零，返回当前最优点
                break
            end
    
            local x_opt = x2 - ((x3 - x2) * (x3 - x2) * (f2 - f1) -
                                (x1 - x2) * (x1 - x2) * (f3 - f2)) / denom
    
            -- 确保新点在三点确定的区间内
            local x_min = math.min(x1, x2, x3)
            local x_max = math.max(x1, x2, x3)
            if x_opt < x_min or x_opt > x_max then
                break
            end
    
            -- 如果变化太小，停止迭代
            if math.abs(x_opt - x_best) < tol then
                break
            end
    
            local f_opt = f(x_opt)
    
            -- 更新最优点
            if f_opt < f_best then
                x_best, f_best = x_opt, f_opt
            end
    
            -- 用新点替换函数值最大的点
            local x_max_f, f_max = x1, f1
            if f2 > f_max then x_max_f, f_max = x2, f2 end
            if f3 > f_max then x_max_f, f_max = x3, f3 end
    
            if x_max_f == x1 then
                x1, f1 = x_opt, f_opt
            elseif x_max_f == x2 then
                x2, f2 = x_opt, f_opt
            else
                x3, f3 = x_opt, f_opt
            end
        end
    
        return x_best, f_best, iter
    end
    
    -- 斐波那契搜索：使用斐波那契数列进行区间缩小
    -- @param f 目标函数
    -- @param a 搜索区间左端点
    -- @param b 搜索区间右端点
    -- @param n 迭代次数（默认 20）
    -- @return 最小值位置，最小值
    function basic_optimization.fibonacci_search(f, a, b, n)
        -- 参数验证
        utils.typecheck.check_type("fibonacci_search", "f", f, "function")
        utils.typecheck.check_type("fibonacci_search", "a", a, "number")
        utils.typecheck.check_type("fibonacci_search", "b", b, "number")
        utils.typecheck.check_type("fibonacci_search", "n", n, "number", "nil")
    
        if a >= b then
            utils.Error.invalid_argument("fibonacci_search", "a must be less than b")
        end
    
        n = n or 20
    
        -- 生成斐波那契数列: F[1]=1, F[2]=1, F[3]=2, ...
        local F = {}
        F[0] = 1
        F[1] = 1
        for i = 2, n + 2 do
            F[i] = F[i-1] + F[i-2]
        end
    
        -- 初始区间
        local left, right = a, b
        local L = right - left
    
        -- 初始两点位置
        local rho = 1 - F[n] / F[n+1]
        local x1 = left + rho * L
        local x2 = right - rho * L
    
        local f1 = f(x1)
        local f2 = f(x2)
    
        -- 迭代
        for k = 1, n do
            if f1 > f2 then
                -- 最小值在 [x1, right]
                left = x1
                x1 = x2
                f1 = f2
                L = right - left
                rho = 1 - F[n-k] / F[n-k+1]
                x2 = right - rho * L
                f2 = f(x2)
            else
                -- 最小值在 [left, x2]
                right = x2
                x2 = x1
                f2 = f1
                L = right - left
                rho = 1 - F[n-k] / F[n-k+1]
                x1 = left + rho * L
                f1 = f(x1)
            end
        end
    
        -- 返回最终区间中点
        local x_opt = (left + right) / 2
        return x_opt, f(x_opt)
    end
    
    -- 二分搜索法（用于单调函数）
    -- @param f 目标函数（单调函数）
    -- @param a 搜索区间左端点
    -- @param b 搜索区间右端点
    -- @param tol 容差（默认 1e-6）
    -- @return 零点位置，函数值，迭代次数
    function basic_optimization.bisection(f, a, b, tol)
        -- 参数验证
        utils.typecheck.check_type("bisection", "f", f, "function")
        utils.typecheck.check_type("bisection", "a", a, "number")
        utils.typecheck.check_type("bisection", "b", b, "number")
        utils.typecheck.check_type("bisection", "tol", tol, "number", "nil")
    
        if a >= b then
            utils.Error.invalid_argument("bisection", "a must be less than b")
        end
    
        tol = tol or 1e-6
    
        local fa = f(a)
        local fb = f(b)
    
        -- 检查端点是否已满足条件
        if math.abs(fa) < tol then
            return a, fa, 0
        end
        if math.abs(fb) < tol then
            return b, fb, 0
        end
    
        -- 检查是否有根（函数值异号）
        if fa * fb > 0 then
            utils.Error.invalid_argument("bisection", "function values at endpoints must have opposite signs")
        end
    
        local iter = 0
        local max_iter = 1000
    
        -- 迭代
        while (b - a) > tol and iter < max_iter do
            iter = iter + 1
    
            local c = (a + b) / 2
            local fc = f(c)
    
            if math.abs(fc) < tol then
                return c, fc, iter
            end
    
            if fa * fc < 0 then
                b = c
                fb = fc
            else
                a = c
                fa = fc
            end
        end
    
        local x_opt = (a + b) / 2
        return x_opt, f(x_opt), iter
    end
    
    return basic_optimization
    
end

-- 模块: optimization.gradient_methods
_module_loaders["optimization.gradient_methods"] = function()
    -- 梯度相关优化方法：使用导数的优化算法
    local utils = require("utils.init")
    
    local gradient_methods = {}
    
    -- 梯度下降法
    -- @param f 目标函数
    -- @param grad 梯度函数，返回梯度向量
    -- @param x0 初始点（向量）
    -- @param options 选项表：
    --   - learning_rate: 学习率（默认 0.01）
    --   - max_iter: 最大迭代次数（默认 1000）
    --   - tol: 收敛容差（默认 1e-6）
    --   - momentum: 动量系数（默认 0，不使用动量）
    --   - decay: 学习率衰减因子（默认 1，不衰减）
    -- @return 最优解，最优值，迭代次数，收敛信息表
    function gradient_methods.gradient_descent(f, grad, x0, options)
        -- 参数验证
        utils.typecheck.check_type("gradient_descent", "f", f, "function")
        utils.typecheck.check_type("gradient_descent", "grad", grad, "function")
        utils.typecheck.check_type("gradient_descent", "x0", x0, "table")
        utils.typecheck.check_type("gradient_descent", "options", options, "table", "nil")
    
        options = options or {}
        local learning_rate = options.learning_rate or 0.01
        local max_iter = options.max_iter or 1000
        local tol = options.tol or 1e-6
        local momentum = options.momentum or 0
        local decay = options.decay or 1
    
        -- 检查维度
        local n = #x0
    
        -- 初始化
        local x = {}
        for i = 1, n do x[i] = x0[i] end
    
        local v = {}  -- 动量项
        for i = 1, n do v[i] = 0 end
    
        local g = grad(x)
        local prev_g_norm = utils.norm(g)
        local iter = 0
        local converged = false
        local lr = learning_rate
    
        -- 迭代
        while iter < max_iter and not converged do
            iter = iter + 1
    
            -- 计算梯度
            g = grad(x)
            local g_norm = utils.norm(g)
    
            -- 检查收敛
            if g_norm < tol then
                converged = true
                break
            end
    
            -- 更新动量项
            for i = 1, n do
                v[i] = momentum * v[i] - lr * g[i]
            end
    
            -- 更新参数
            for i = 1, n do
                x[i] = x[i] + v[i]
            end
    
            -- 学习率衰减
            lr = lr * decay
    
            prev_g_norm = g_norm
        end
    
        local info = {
            iterations = iter,
            converged = converged,
            final_gradient_norm = utils.norm(g)
        }
    
        return x, f(x), iter, info
    end
    
    -- 牛顿法（使用海森矩阵）
    -- @param f 目标函数
    -- @param grad 梯度函数，返回梯度向量
    -- @param hessian 海森矩阵函数，返回海森矩阵
    -- @param x0 初始点（向量）
    -- @param options 选项表：
    --   - max_iter: 最大迭代次数（默认 100）
    --   - tol: 收敛容差（默认 1e-6）
    --   - alpha: 阻尼因子（默认 1）
    --   - regularize: 是否正则化海森矩阵（默认 false）
    -- @return 最优解，最优值，迭代次数，收敛信息表
    function gradient_methods.newton(f, grad, hessian, x0, options)
        -- 参数验证
        utils.typecheck.check_type("newton", "f", f, "function")
        utils.typecheck.check_type("newton", "grad", grad, "function")
        utils.typecheck.check_type("newton", "hessian", hessian, "function")
        utils.typecheck.check_type("newton", "x0", x0, "table")
        utils.typecheck.check_type("newton", "options", options, "table", "nil")
    
        options = options or {}
        local max_iter = options.max_iter or 100
        local tol = options.tol or 1e-6
        local alpha = options.alpha or 1
        local regularize = options.regularize or false
    
        local matrix = require("matrix.init")
    
        -- 检查维度
        local n = #x0
    
        -- 初始化
        local x = {}
        for i = 1, n do x[i] = x0[i] end
    
        local iter = 0
        local converged = false
    
        -- 迭代
        while iter < max_iter and not converged do
            iter = iter + 1
    
            -- 计算梯度和海森矩阵
            local g = grad(x)
            local g_norm = utils.norm(g)
            local H = hessian(x)
    
            -- 检查收敛
            if g_norm < tol then
                converged = true
                break
            end
    
            -- 正则化海森矩阵（如果需要）
            if regularize then
                for i = 1, n do
                    H[i][i] = H[i][i] + utils.epsilon
                end
            end
    
            -- 将梯度转换为列向量（注意：求解 H * delta = -g）
            local g_vec = {}
            for i = 1, n do g_vec[i] = {-g[i]} end
    
            -- 求解 H * delta_x = -g
            local H_mat = matrix.new(H)
            local delta = H_mat:solve(matrix.new(g_vec))
    
            -- 更新参数
            for i = 1, n do
                x[i] = x[i] + alpha * delta.data[i][1]
            end
        end
    
        local info = {
            iterations = iter,
            converged = converged,
            final_gradient_norm = utils.norm(grad(x))
        }
    
        return x, f(x), iter, info
    end
    
    -- BFGS 拟牛顿法
    -- @param f 目标函数
    -- @param grad 梯度函数，返回梯度向量
    -- @param x0 初始点（向量）
    -- @param options 选项表：
    --   - max_iter: 最大迭代次数（默认 1000）
    --   - tol: 收敛容差（默认 1e-6）
    --   - B0: 初始逆海森矩阵近似（默认单位矩阵）
    -- @return 最优解，最优值，迭代次数，收敛信息表
    function gradient_methods.bfgs(f, grad, x0, options)
        -- 参数验证
        utils.typecheck.check_type("bfgs", "f", f, "function")
        utils.typecheck.check_type("bfgs", "grad", grad, "function")
        utils.typecheck.check_type("bfgs", "x0", x0, "table")
        utils.typecheck.check_type("bfgs", "options", options, "table", "nil")
    
        options = options or {}
        local max_iter = options.max_iter or 1000
        local tol = options.tol or 1e-6
        local B0 = options.B0  -- 初始逆海森矩阵近似
    
        local n = #x0
    
        -- 初始化
        local x = {}
        for i = 1, n do x[i] = x0[i] end
    
        -- 初始化逆海森矩阵近似
        local B = {}
        if B0 then
            for i = 1, n do
                B[i] = {}
                for j = 1, n do
                    B[i][j] = B0[i][j]
                end
            end
        else
            -- 单位矩阵
            for i = 1, n do
                B[i] = {}
                for j = 1, n do
                    B[i][j] = (i == j) and 1 or 0
                end
            end
        end
    
        -- 初始梯度
        local g = grad(x)
    
        local iter = 0
        local converged = false
    
        -- 迭代
        while iter < max_iter and not converged do
            iter = iter + 1
    
            local g_norm = utils.norm(g)
    
            -- 检查收敛
            if g_norm < tol then
                converged = true
                break
            end
    
            -- 计算 B * g（搜索方向）
            local Bg = {}
            for i = 1, n do
                Bg[i] = 0
                for j = 1, n do
                    Bg[i] = Bg[i] + B[i][j] * g[j]
                end
            end
    
            -- 线搜索找步长（简化版：固定步长）
            local alpha = 1.0
            local x_new = {}
            for i = 1, n do
                x_new[i] = x[i] - alpha * Bg[i]
            end
    
            -- 计算新梯度
            local g_new = grad(x_new)
    
            -- BFGS 更新
            local s = {}  -- x_new - x
            local y = {}  -- g_new - g
            for i = 1, n do
                s[i] = x_new[i] - x[i]
                y[i] = g_new[i] - g[i]
            end
    
            -- 计算 s^T * y
            local sTy = 0
            for i = 1, n do
                sTy = sTy + s[i] * y[i]
            end
    
            -- 确保 s^T * y > 0
            if sTy > 0 then
                -- 计算 B * y
                local By = {}
                for i = 1, n do
                    By[i] = 0
                    for j = 1, n do
                        By[i] = By[i] + B[i][j] * y[j]
                    end
                end
    
                -- 计算 y^T * B * y
                local yTBy = 0
                for i = 1, n do
                    yTBy = yTBy + y[i] * By[i]
                end
    
                -- BFGS 更新公式
                -- B = (I - rho * s * y^T) * B * (I - rho * y * s^T) + rho * s * s^T
                local rho = 1 / sTy
    
                for i = 1, n do
                    for j = 1, n do
                        B[i][j] = B[i][j] - rho * s[i] * By[j] - rho * By[i] * s[j] +
                                  rho * rho * yTBy * s[i] * s[j] + rho * s[i] * s[j]
                    end
                end
            end
    
            -- 更新
            x = x_new
            g = g_new
        end
    
        local info = {
            iterations = iter,
            converged = converged,
            final_gradient_norm = utils.norm(g)
        }
    
        return x, f(x), iter, info
    end
    
    -- 共轭梯度法
    -- @param f 目标函数
    -- @param grad 梯度函数，返回梯度向量
    -- @param x0 初始点（向量）
    -- @param options 选项表：
    --   - max_iter: 最大迭代次数（默认 1000）
    --   - tol: 收敛容差（默认 1e-6）
    --   - restart: 重启间隔（默认 n，即维度数）
    --   - method: 共轭梯度方法（" Fletcher-Reeves", "Polak-Ribiere"）
    -- @return 最优解，最优值，迭代次数，收敛信息表
    function gradient_methods.conjugate_gradient(f, grad, x0, options)
        -- 参数验证
        utils.typecheck.check_type("conjugate_gradient", "f", f, "function")
        utils.typecheck.check_type("conjugate_gradient", "grad", grad, "function")
        utils.typecheck.check_type("conjugate_gradient", "x0", x0, "table")
        utils.typecheck.check_type("conjugate_gradient", "options", options, "table", "nil")
    
        options = options or {}
        local max_iter = options.max_iter or 1000
        local tol = options.tol or 1e-6
        local restart = options.restart or #x0
        local method = options.method or "Fletcher-Reeves"
    
        local n = #x0
    
        -- 初始化
        local x = {}
        for i = 1, n do x[i] = x0[i] end
    
        -- 初始梯度
        local g = grad(x)
        local d = {}  -- 搜索方向
        for i = 1, n do d[i] = -g[i] end
    
        local iter = 0
        local converged = false
    
        -- 迭代
        while iter < max_iter and not converged do
            iter = iter + 1
    
            local g_norm = utils.norm(g)
    
            -- 检查收敛
            if g_norm < tol then
                converged = true
                break
            end
    
            -- 线搜索找步长（简化版：固定步长）
            local alpha = 0.01
    
            -- 计算新点
            local x_new = {}
            for i = 1, n do
                x_new[i] = x[i] + alpha * d[i]
            end
    
            -- 计算新梯度
            local g_new = grad(x_new)
    
            -- 计算新搜索方向
            if iter % restart == 0 then
                -- 重启：最速下降方向
                for i = 1, n do
                    d[i] = -g_new[i]
                end
            else
                -- 计算共轭参数 beta
                local beta = 0
                local g_new_norm_sq = 0
                local g_norm_sq = 0
    
                for i = 1, n do
                    g_new_norm_sq = g_new_norm_sq + g_new[i] * g_new[i]
                    g_norm_sq = g_norm_sq + g[i] * g[i]
                end
    
                if method == "Polak-Ribiere" then
                    -- Polak-Ribiere 公式
                    local y_g_new = 0
                    for i = 1, n do
                        y_g_new = y_g_new + (g_new[i] - g[i]) * g_new[i]
                    end
                    beta = y_g_new / g_norm_sq
                    if beta < 0 then beta = 0 end  -- 确保下降方向
                else
                    -- Fletcher-Reeves 公式（默认）
                    beta = g_new_norm_sq / g_norm_sq
                end
    
                -- 更新搜索方向
                for i = 1, n do
                    d[i] = -g_new[i] + beta * d[i]
                end
            end
    
            -- 更新
            x = x_new
            g = g_new
        end
    
        local info = {
            iterations = iter,
            converged = converged,
            final_gradient_norm = utils.norm(g)
        }
    
        return x, f(x), iter, info
    end
    
    -- 随机梯度下降（SGD）
    -- @param f 目标函数（接受数据和参数）
    -- @param grad 梯度函数（接受单个样本和参数）
    -- @param data 数据集
    -- @param x0 初始参数（向量）
    -- @param options 选项表：
    --   - epochs: 训练轮数（默认 100）
    --   - batch_size: 批次大小（默认 1，即纯SGD）
    --   - learning_rate: 学习率（默认 0.01）
    --   - shuffle: 是否打乱数据（默认 true）
    -- @return 最优解，最终损失
    function gradient_methods.stochastic_gradient_descent(f, grad, data, x0, options)
        -- 参数验证
        utils.typecheck.check_type("stochastic_gradient_descent", "f", f, "function")
        utils.typecheck.check_type("stochastic_gradient_descent", "grad", grad, "function")
        utils.typecheck.check_type("stochastic_gradient_descent", "data", data, "table")
        utils.typecheck.check_type("stochastic_gradient_descent", "x0", x0, "table")
        utils.typecheck.check_type("stochastic_gradient_descent", "options", options, "table", "nil")
    
        options = options or {}
        local epochs = options.epochs or 100
        local batch_size = options.batch_size or 1
        local learning_rate = options.learning_rate or 0.01
        local shuffle = options.shuffle ~= false
    
        local n = #x0
        local N = #data  -- 数据集大小
    
        -- 初始化
        local x = {}
        for i = 1, n do x[i] = x0[i] end
    
        -- 辅助函数：打乱数据
        local function shuffle_data()
            local indices = {}
            for i = 1, N do indices[i] = i end
    
            for i = N, 2, -1 do
                local j = math.random(1, i)
                indices[i], indices[j] = indices[j], indices[i]
            end
    
            return indices
        end
    
        -- 训练循环
        for epoch = 1, epochs do
            local indices = shuffle and shuffle_data() or {}
    
            for start = 1, N, batch_size do
                local batch_grad = {}
                for i = 1, n do batch_grad[i] = 0 end
    
                local batch_count = 0
    
                -- 处理当前批次
                for b = start, math.min(start + batch_size - 1, N) do
                    local idx = shuffle and indices[b] or b
                    local sample = data[idx]
                    local g = grad(sample, x)
    
                    for i = 1, n do
                        batch_grad[i] = batch_grad[i] + g[i]
                    end
    
                    batch_count = batch_count + 1
                end
    
                -- 平均梯度
                for i = 1, n do
                    batch_grad[i] = batch_grad[i] / batch_count
                end
    
                -- 更新参数
                for i = 1, n do
                    x[i] = x[i] - learning_rate * batch_grad[i]
                end
            end
        end
    
        return x, f(data, x)
    end
    
    return gradient_methods
    
end

-- 模块: ode.basic_methods
_module_loaders["ode.basic_methods"] = function()
    -- 基础常微分方程求解方法
    local utils = require("utils.init")
    
    local basic_methods = {}
    
    -- 欧拉方法（一阶方法）
    -- @param f 微分函数 dy/dt = f(t, y)
    -- @param t0 初始时间
    -- @param y0 初始值（可以是标量或向量）
    -- @param t_end 终止时间
    -- @param h 步长（可选，默认自动选择）
    -- @param options 选项表：
    --   - n_steps: 步数（如果提供，忽略h）
    -- @return 时间数组，解数组
    function basic_methods.euler(f, t0, y0, t_end, h, options)
        -- 参数验证
        utils.typecheck.check_type("euler", "f", f, "function")
        utils.typecheck.check_type("euler", "t0", t0, "number")
        utils.typecheck.check_type("euler", "t_end", t_end, "number")
        utils.typecheck.check_type("euler", "h", h, "number", "nil")
        utils.typecheck.check_type("euler", "options", options, "table", "nil")
    
        options = options or {}
    
        -- 确定步长和步数
        local n_steps
        if options.n_steps then
            n_steps = options.n_steps
            h = (t_end - t0) / n_steps
        else
            h = h or 0.01
            n_steps = math.floor((t_end - t0) / h)
        end
    
        -- 判断是标量还是向量
        local is_vector = type(y0) == "table"
    
        -- 初始化结果数组
        local t_vals = {t0}
        local y_vals = {is_vector and {} or y0}
        if is_vector then
            for i = 1, #y0 do
                y_vals[1][i] = y0[i]
            end
        end
    
        -- 当前状态
        local t = t0
        local y = is_vector and {} or y0
        if is_vector then
            for i = 1, #y0 do y[i] = y0[i] end
        end
    
        -- 迭代
        for i = 1, n_steps do
            -- 计算导数
            local dy = f(t, y)
    
            -- 欧拉更新：y_{n+1} = y_n + h * f(t_n, y_n)
            if is_vector then
                local y_new = {}
                for j = 1, #y do
                    y_new[j] = y[j] + h * dy[j]
                end
                y = y_new
            else
                y = y + h * dy
            end
    
            t = t + h
    
            -- 存储结果
            t_vals[i + 1] = t
            if is_vector then
                y_vals[i + 1] = {}
                for j = 1, #y do
                    y_vals[i + 1][j] = y[j]
                end
            else
                y_vals[i + 1] = y
            end
        end
    
        return t_vals, y_vals
    end
    
    -- 改进欧拉方法（Heun方法，二阶方法）
    -- @param f 微分函数 dy/dt = f(t, y)
    -- @param t0 初始时间
    -- @param y0 初始值（可以是标量或向量）
    -- @param t_end 终止时间
    -- @param h 步长（可选，默认自动选择）
    -- @param options 选项表
    -- @return 时间数组，解数组
    function basic_methods.heun(f, t0, y0, t_end, h, options)
        -- 参数验证
        utils.typecheck.check_type("heun", "f", f, "function")
        utils.typecheck.check_type("heun", "t0", t0, "number")
        utils.typecheck.check_type("heun", "t_end", t_end, "number")
        utils.typecheck.check_type("heun", "h", h, "number", "nil")
        utils.typecheck.check_type("heun", "options", options, "table", "nil")
    
        options = options or {}
    
        -- 确定步长和步数
        local n_steps
        if options.n_steps then
            n_steps = options.n_steps
            h = (t_end - t0) / n_steps
        else
            h = h or 0.01
            n_steps = math.floor((t_end - t0) / h)
        end
    
        -- 判断是标量还是向量
        local is_vector = type(y0) == "table"
    
        -- 初始化结果数组
        local t_vals = {t0}
        local y_vals = {is_vector and {} or y0}
        if is_vector then
            for i = 1, #y0 do
                y_vals[1][i] = y0[i]
            end
        end
    
        -- 当前状态
        local t = t0
        local y = is_vector and {} or y0
        if is_vector then
            for i = 1, #y0 do y[i] = y0[i] end
        end
    
        -- 迭代
        for i = 1, n_steps do
            -- 预测步（欧拉）
            local k1 = f(t, y)
            local y_pred
            if is_vector then
                y_pred = {}
                for j = 1, #y do
                    y_pred[j] = y[j] + h * k1[j]
                end
            else
                y_pred = y + h * k1
            end
    
            -- 校正步
            local k2 = f(t + h, y_pred)
    
            -- 更新：y_{n+1} = y_n + h/2 * (k1 + k2)
            if is_vector then
                local y_new = {}
                for j = 1, #y do
                    y_new[j] = y[j] + h * 0.5 * (k1[j] + k2[j])
                end
                y = y_new
            else
                y = y + h * 0.5 * (k1 + k2)
            end
    
            t = t + h
    
            -- 存储结果
            t_vals[i + 1] = t
            if is_vector then
                y_vals[i + 1] = {}
                for j = 1, #y do
                    y_vals[i + 1][j] = y[j]
                end
            else
                y_vals[i + 1] = y
            end
        end
    
        return t_vals, y_vals
    end
    
    -- 中点方法（二阶方法）
    -- @param f 微分函数 dy/dt = f(t, y)
    -- @param t0 初始时间
    -- @param y0 初始值（可以是标量或向量）
    -- @param t_end 终止时间
    -- @param h 步长
    -- @param options 选项表
    -- @return 时间数组，解数组
    function basic_methods.midpoint(f, t0, y0, t_end, h, options)
        -- 参数验证
        utils.typecheck.check_type("midpoint", "f", f, "function")
        utils.typecheck.check_type("midpoint", "t0", t0, "number")
        utils.typecheck.check_type("midpoint", "t_end", t_end, "number")
        utils.typecheck.check_type("midpoint", "h", h, "number", "nil")
        utils.typecheck.check_type("midpoint", "options", options, "table", "nil")
    
        options = options or {}
    
        -- 确定步长和步数
        local n_steps
        if options.n_steps then
            n_steps = options.n_steps
            h = (t_end - t0) / n_steps
        else
            h = h or 0.01
            n_steps = math.floor((t_end - t0) / h)
        end
    
        -- 判断是标量还是向量
        local is_vector = type(y0) == "table"
    
        -- 初始化结果数组
        local t_vals = {t0}
        local y_vals = {is_vector and {} or y0}
        if is_vector then
            for i = 1, #y0 do
                y_vals[1][i] = y0[i]
            end
        end
    
        -- 当前状态
        local t = t0
        local y = is_vector and {} or y0
        if is_vector then
            for i = 1, #y0 do y[i] = y0[i] end
        end
    
        -- 迭代
        for i = 1, n_steps do
            -- 计算中点斜率
            local k1 = f(t, y)
            local y_mid
            if is_vector then
                y_mid = {}
                for j = 1, #y do
                    y_mid[j] = y[j] + 0.5 * h * k1[j]
                end
            else
                y_mid = y + 0.5 * h * k1
            end
    
            local k2 = f(t + 0.5 * h, y_mid)
    
            -- 更新
            if is_vector then
                local y_new = {}
                for j = 1, #y do
                    y_new[j] = y[j] + h * k2[j]
                end
                y = y_new
            else
                y = y + h * k2
            end
    
            t = t + h
    
            -- 存储结果
            t_vals[i + 1] = t
            if is_vector then
                y_vals[i + 1] = {}
                for j = 1, #y do
                    y_vals[i + 1][j] = y[j]
                end
            else
                y_vals[i + 1] = y
            end
        end
    
        return t_vals, y_vals
    end
    
    return basic_methods
end

-- 模块: ode.advanced_methods
_module_loaders["ode.advanced_methods"] = function()
    -- 高级常微分方程求解方法
    local utils = require("utils.init")
    
    local advanced_methods = {}
    
    -- 四阶龙格-库塔方法（经典RK4）
    -- @param f 微分函数 dy/dt = f(t, y)
    -- @param t0 初始时间
    -- @param y0 初始值（可以是标量或向量）
    -- @param t_end 终止时间
    -- @param h 步长（可选）
    -- @param options 选项表
    -- @return 时间数组，解数组
    function advanced_methods.runge_kutta4(f, t0, y0, t_end, h, options)
        -- 参数验证
        utils.typecheck.check_type("runge_kutta4", "f", f, "function")
        utils.typecheck.check_type("runge_kutta4", "t0", t0, "number")
        utils.typecheck.check_type("runge_kutta4", "t_end", t_end, "number")
        utils.typecheck.check_type("runge_kutta4", "h", h, "number", "nil")
        utils.typecheck.check_type("runge_kutta4", "options", options, "table", "nil")
    
        options = options or {}
    
        -- 确定步长和步数
        local n_steps
        if options.n_steps then
            n_steps = options.n_steps
            h = (t_end - t0) / n_steps
        else
            h = h or 0.01
            n_steps = math.floor((t_end - t0) / h)
        end
    
        -- 判断是标量还是向量
        local is_vector = type(y0) == "table"
    
        -- 辅助函数：向量加法
        local function vec_add_scaled(a, b, scale)
            if not is_vector then return a + scale * b end
            local result = {}
            for i = 1, #a do
                result[i] = a[i] + scale * b[i]
            end
            return result
        end
    
        -- 初始化结果数组
        local t_vals = {t0}
        local y_vals = {}
        if is_vector then
            y_vals[1] = {}
            for i = 1, #y0 do
                y_vals[1][i] = y0[i]
            end
        else
            y_vals[1] = y0
        end
    
        -- 当前状态
        local t = t0
        local y
        if is_vector then
            y = {}
            for i = 1, #y0 do y[i] = y0[i] end
        else
            y = y0
        end
    
        -- 迭代
        for i = 1, n_steps do
            -- RK4 系数
            local k1 = f(t, y)
            local k2 = f(t + 0.5 * h, vec_add_scaled(y, k1, 0.5 * h))
            local k3 = f(t + 0.5 * h, vec_add_scaled(y, k2, 0.5 * h))
            local k4 = f(t + h, vec_add_scaled(y, k3, h))
    
            -- 更新：y_{n+1} = y_n + h/6 * (k1 + 2*k2 + 2*k3 + k4)
            if is_vector then
                local y_new = {}
                for j = 1, #y do
                    y_new[j] = y[j] + h / 6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j])
                end
                y = y_new
            else
                y = y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
            end
    
            t = t + h
    
            -- 存储结果
            t_vals[i + 1] = t
            if is_vector then
                y_vals[i + 1] = {}
                for j = 1, #y do
                    y_vals[i + 1][j] = y[j]
                end
            else
                y_vals[i + 1] = y
            end
        end
    
        return t_vals, y_vals
    end
    
    -- RK45 自适应步长方法（使用步长加倍法）
    -- @param f 微分函数 dy/dt = f(t, y)
    -- @param t0 初始时间
    -- @param y0 初始值
    -- @param t_end 终止时间
    -- @param options 选项表：
    --   - tol: 容差（默认 1e-6）
    --   - h_init: 初始步长（可选）
    --   - h_min: 最小步长（默认 1e-10）
    --   - h_max: 最大步长（可选）
    --   - max_steps: 最大步数（默认 10000）
    -- @return 时间数组，解数组
    function advanced_methods.rk45(f, t0, y0, t_end, options)
        -- 参数验证
        utils.typecheck.check_type("rk45", "f", f, "function")
        utils.typecheck.check_type("rk45", "t0", t0, "number")
        utils.typecheck.check_type("rk45", "t_end", t_end, "number")
        utils.typecheck.check_type("rk45", "options", options, "table", "nil")
    
        options = options or {}
        local tol = options.tol or 1e-6
        local h_min = options.h_min or 1e-10
        local h_max = options.h_max or (t_end - t0) / 4
        local max_steps = options.max_steps or 10000
    
        -- 初始步长
        local h = options.h_init or math.min(0.1, (t_end - t0) / 10, h_max)
    
        -- 判断是标量还是向量
        local is_vector = type(y0) == "table"
    
        -- 辅助函数：RK4单步
        local function rk4_step(t, y, h)
            local k1 = f(t, y)
            local k2, k3, k4
    
            if is_vector then
                local y2, y3, y4 = {}, {}, {}
                for i = 1, #y do
                    y2[i] = y[i] + 0.5 * h * k1[i]
                end
                k2 = f(t + 0.5 * h, y2)
                for i = 1, #y do
                    y3[i] = y[i] + 0.5 * h * k2[i]
                end
                k3 = f(t + 0.5 * h, y3)
                for i = 1, #y do
                    y4[i] = y[i] + h * k3[i]
                end
                k4 = f(t + h, y4)
    
                local y_new = {}
                for i = 1, #y do
                    y_new[i] = y[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i])
                end
                return y_new
            else
                k2 = f(t + 0.5 * h, y + 0.5 * h * k1)
                k3 = f(t + 0.5 * h, y + 0.5 * h * k2)
                k4 = f(t + h, y + h * k3)
                return y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
            end
        end
    
        -- 计算误差范数
        local function error_norm(y1, y2)
            if is_vector then
                local sum = 0
                for i = 1, #y1 do
                    local diff = y1[i] - y2[i]
                    sum = sum + diff * diff
                end
                return math.sqrt(sum)
            else
                return math.abs(y1 - y2)
            end
        end
    
        -- 初始化结果
        local t_vals = {t0}
        local y_vals = {}
        if is_vector then
            y_vals[1] = {}
            for i = 1, #y0 do
                y_vals[1][i] = y0[i]
            end
        else
            y_vals[1] = y0
        end
    
        -- 当前状态
        local t = t0
        local y
        if is_vector then
            y = {}
            for i = 1, #y0 do y[i] = y0[i] end
        else
            y = y0
        end
    
        local step_count = 0
    
        -- 主循环
        while t < t_end and step_count < max_steps do
            step_count = step_count + 1
    
            -- 确保最后一步正好到达 t_end
            if t + h > t_end then
                h = t_end - t
            end
    
            -- 步长加倍法：比较一步和两步的结果
            local y_one_step = rk4_step(t, y, h)
            local y_half = rk4_step(t, y, 0.5 * h)
            local y_two_steps = rk4_step(t + 0.5 * h, y_half, 0.5 * h)
    
            -- 误差估计
            local err = error_norm(y_one_step, y_two_steps)
    
            -- 步长调整
            if err < tol or h <= h_min then
                -- 接受步（使用更精确的两步结果）
                t = t + h
                y = y_two_steps
    
                t_vals[#t_vals + 1] = t
                if is_vector then
                    y_vals[#y_vals + 1] = {}
                    for j = 1, #y do
                        y_vals[#y_vals][j] = y[j]
                    end
                else
                    y_vals[#y_vals + 1] = y
                end
            end
    
            -- 计算新步长
            if err > 1e-15 then
                local factor = 0.9 * (tol / err) ^ 0.2
                factor = math.max(0.1, math.min(2.0, factor))
                h = math.max(h_min, math.min(h_max, h * factor))
            else
                h = math.min(h_max, h * 2)
            end
        end
    
        return t_vals, y_vals
    end
    
    -- 自适应RK方法别名
    function advanced_methods.adaptive_rk(f, t0, y0, t_end, options)
        return advanced_methods.rk45(f, t0, y0, t_end, options)
    end
    
    return advanced_methods
end

-- 模块: root_finding.multi_root
_module_loaders["root_finding.multi_root"] = function()
    -- 多维根求解模块
    -- 支持求解非线性方程组 F(x) = 0
    
    local math = math
    local utils = require("utils.init")
    
    local multi_root = {}
    
    -- =============================================================================
    -- 辅助函数
    -- =============================================================================
    
    -- 向量范数
    local function vec_norm(v)
        local sum = 0
        for i = 1, #v do
            sum = sum + v[i] * v[i]
        end
        return math.sqrt(sum)
    end
    
    -- 向量减法
    local function vec_sub(a, b)
        local result = {}
        for i = 1, #a do
            result[i] = a[i] - b[i]
        end
        return result
    end
    
    -- 向量加法
    local function vec_add(a, b)
        local result = {}
        for i = 1, #a do
            result[i] = a[i] + b[i]
        end
        return result
    end
    
    -- 标量乘向量
    local function vec_scale(a, s)
        local result = {}
        for i = 1, #a do
            result[i] = a[i] * s
        end
        return result
    end
    
    -- 复制向量
    local function vec_copy(v)
        local result = {}
        for i = 1, #v do
            result[i] = v[i]
        end
        return result
    end
    
    -- =============================================================================
    -- 数值雅可比矩阵计算
    -- =============================================================================
    
    -- 数值计算雅可比矩阵（前向差分）
    -- @param F 函数向量 F(x) 返回 {f1, f2, ...}
    -- @param x 当前点
    -- @param eps 差分步长（可选，默认 1e-8）
    -- @return 雅可比矩阵 J[i][j] = dfi/dxj
    local function numerical_jacobian(F, x, eps)
        eps = eps or 1e-8
        local n = #x
        local fx = F(x)
        local m = #fx
    
        local J = {}
        for i = 1, m do
            J[i] = {}
            for j = 1, n do
                J[i][j] = 0
            end
        end
    
        for j = 1, n do
            -- 构造扰动点
            local x_plus = vec_copy(x)
            local h = eps * math.max(1, math.abs(x[j]))
            x_plus[j] = x_plus[j] + h
    
            local fx_plus = F(x_plus)
    
            -- 计算差分
            for i = 1, m do
                J[i][j] = (fx_plus[i] - fx[i]) / h
            end
        end
    
        return J
    end
    
    -- =============================================================================
    -- 线性求解器（用于求解线性方程组）
    -- =============================================================================
    
    -- 高斯消元法求解 Ax = b
    local function solve_linear(A, b)
        local n = #A
    
        -- 创建增广矩阵
        local aug = {}
        for i = 1, n do
            aug[i] = {}
            for j = 1, n do
                aug[i][j] = A[i][j]
            end
            aug[i][n + 1] = b[i]
        end
    
        -- 前向消元
        for k = 1, n do
            -- 选主元
            local max_val = math.abs(aug[k][k])
            local max_row = k
            for i = k + 1, n do
                if math.abs(aug[i][k]) > max_val then
                    max_val = math.abs(aug[i][k])
                    max_row = i
                end
            end
    
            -- 交换行
            aug[k], aug[max_row] = aug[max_row], aug[k]
    
            if math.abs(aug[k][k]) < 1e-14 then
                error("Matrix is singular or nearly singular")
            end
    
            for i = k + 1, n do
                local factor = aug[i][k] / aug[k][k]
                for j = k, n + 1 do
                    aug[i][j] = aug[i][j] - factor * aug[k][j]
                end
            end
        end
    
        -- 回代
        local x = {}
        for i = n, 1, -1 do
            local sum = aug[i][n + 1]
            for j = i + 1, n do
                sum = sum - aug[i][j] * x[j]
            end
            x[i] = sum / aug[i][i]
        end
    
        return x
    end
    
    -- =============================================================================
    -- 牛顿法
    -- =============================================================================
    
    -- 牛顿法求解非线性方程组
    -- @param F 函数向量 F(x) 返回 {f1, f2, ...}
    -- @param x0 初始猜测
    -- @param options 选项表：
    --   - jacobian: 雅可比矩阵函数（可选，默认数值计算）
    --   - tol: 收敛容差（默认 1e-10）
    --   - max_iter: 最大迭代次数（默认 100）
    --   - verbose: 是否打印迭代信息（默认 false）
    -- @return 解向量，收敛标志，迭代次数
    function multi_root.newton(F, x0, options)
        -- 参数验证
        utils.typecheck.check_type("newton", "F", F, "function")
        utils.typecheck.check_type("newton", "x0", x0, "table")
    
        options = options or {}
        local tol = options.tol or 1e-10
        local max_iter = options.max_iter or 100
        local verbose = options.verbose or false
        local jacobian_func = options.jacobian
    
        local x = vec_copy(x0)
        local n = #x
    
        for iter = 1, max_iter do
            -- 计算函数值
            local fx = F(x)
    
            -- 检查收敛
            local fx_norm = vec_norm(fx)
            if verbose then
                print(string.format("  iter %d: |F(x)| = %.2e", iter, fx_norm))
            end
    
            if fx_norm < tol then
                return x, true, iter
            end
    
            -- 计算雅可比矩阵
            local J
            if jacobian_func then
                J = jacobian_func(x)
            else
                J = numerical_jacobian(F, x)
            end
    
            -- 求解 J * delta = -F(x)
            local neg_fx = vec_scale(fx, -1)
            local delta = solve_linear(J, neg_fx)
    
            -- 更新 x
            x = vec_add(x, delta)
    
            -- 检查 delta 是否足够小
            if vec_norm(delta) < tol * math.max(1, vec_norm(x)) then
                return x, true, iter
            end
        end
    
        -- 未收敛
        return x, false, max_iter
    end
    
    -- =============================================================================
    -- Broyden方法（拟牛顿法）
    -- =============================================================================
    
    -- Broyden方法求解非线性方程组
    -- 不需要显式计算雅可比矩阵，使用秩1更新近似
    -- @param F 函数向量
    -- @param x0 初始猜测
    -- @param options 选项表
    -- @return 解向量，收敛标志，迭代次数
    function multi_root.broyden(F, x0, options)
        -- 参数验证
        utils.typecheck.check_type("broyden", "F", F, "function")
        utils.typecheck.check_type("broyden", "x0", x0, "table")
    
        options = options or {}
        local tol = options.tol or 1e-10
        local max_iter = options.max_iter or 100
        local verbose = options.verbose or false
    
        local x = vec_copy(x0)
        local n = #x
    
        -- 初始雅可比逆的近似（使用单位矩阵的缩放）
        local fx = F(x)
        local fx_norm = vec_norm(fx)
    
        if fx_norm < tol then
            return x, true, 0
        end
    
        -- 初始 B（雅可比逆的近似）
        local B = {}
        for i = 1, n do
            B[i] = {}
            for j = 1, n do
                if i == j then
                    B[i][j] = 1
                else
                    B[i][j] = 0
                end
            end
        end
    
        -- 第一次迭代使用数值雅可比初始化
        local J = numerical_jacobian(F, x)
        -- 计算 J 的逆（使用高斯消元）
        local I = {}
        for i = 1, n do
            I[i] = {}
            for j = 1, n do
                if i == j then
                    I[i][j] = 1
                else
                    I[i][j] = 0
                end
            end
        end
        for i = 1, n do
            B[i] = solve_linear(J, I[i])
        end
        -- 转置
        local B_inv = {}
        for i = 1, n do
            B_inv[i] = {}
            for j = 1, n do
                B_inv[i][j] = B[j][i]
            end
        end
        B = B_inv
    
        for iter = 1, max_iter do
            -- 计算 delta = -B * F(x)
            local delta = {}
            for i = 1, n do
                local sum = 0
                for j = 1, n do
                    sum = sum + B[i][j] * fx[j]
                end
                delta[i] = -sum
            end
    
            -- 更新 x
            local x_new = vec_add(x, delta)
    
            -- 计算新的函数值
            local fx_new = F(x_new)
            local fx_new_norm = vec_norm(fx_new)
    
            if verbose then
                print(string.format("  iter %d: |F(x)| = %.2e", iter, fx_new_norm))
            end
    
            if fx_new_norm < tol then
                return x_new, true, iter
            end
    
            -- Broyden更新
            -- s = x_new - x = delta
            -- y = F(x_new) - F(x)
            local y = vec_sub(fx_new, fx)
    
            -- B_new = B + (s - B*y) * y^T / (y^T * y)
            local By = {}
            for i = 1, n do
                local sum = 0
                for j = 1, n do
                    sum = sum + B[i][j] * y[j]
                end
                By[i] = sum
            end
    
            local s_minus_By = vec_sub(delta, By)
    
            local yty = 0
            for i = 1, n do
                yty = yty + y[i] * y[i]
            end
    
            if yty > 1e-20 then
                for i = 1, n do
                    for j = 1, n do
                        B[i][j] = B[i][j] + s_minus_By[i] * y[j] / yty
                    end
                end
            end
    
            -- 更新
            x = x_new
            fx = fx_new
        end
    
        return x, false, max_iter
    end
    
    -- =============================================================================
    -- 不动点迭代
    -- =============================================================================
    
    -- 不动点迭代求解 x = G(x)
    -- @param G 迭代函数 G(x)
    -- @param x0 初始猜测
    -- @param options 选项表：
    --   - tol: 收敛容差（默认 1e-10）
    --   - max_iter: 最大迭代次数（默认 100）
    --   - relaxation: 松弛因子（默认 1.0，< 1 为低松弛）
    --   - verbose: 是否打印迭代信息
    -- @return 解向量，收敛标志，迭代次数
    function multi_root.fixed_point(G, x0, options)
        -- 参数验证
        utils.typecheck.check_type("fixed_point", "G", G, "function")
        utils.typecheck.check_type("fixed_point", "x0", x0, "table")
    
        options = options or {}
        local tol = options.tol or 1e-10
        local max_iter = options.max_iter or 100
        local relaxation = options.relaxation or 1.0
        local verbose = options.verbose or false
    
        local x = vec_copy(x0)
    
        for iter = 1, max_iter do
            local x_new = G(x)
    
            -- 应用松弛
            if relaxation ~= 1.0 then
                for i = 1, #x_new do
                    x_new[i] = x[i] + relaxation * (x_new[i] - x[i])
                end
            end
    
            -- 计算差值
            local diff = vec_norm(vec_sub(x_new, x))
    
            if verbose then
                print(string.format("  iter %d: |x_new - x| = %.2e", iter, diff))
            end
    
            if diff < tol then
                return x_new, true, iter
            end
    
            x = x_new
        end
    
        return x, false, max_iter
    end
    
    -- =============================================================================
    -- 信赖域方法
    -- =============================================================================
    
    -- 信赖域Dogleg方法
    -- @param F 函数向量
    -- @param x0 初始猜测
    -- @param options 选项表
    -- @return 解向量，收敛标志，迭代次数
    function multi_root.trust_region(F, x0, options)
        -- 参数验证
        utils.typecheck.check_type("trust_region", "F", F, "function")
        utils.typecheck.check_type("trust_region", "x0", x0, "table")
    
        options = options or {}
        local tol = options.tol or 1e-10
        local max_iter = options.max_iter or 100
        local verbose = options.verbose or false
        local delta_max = options.delta_max or 10.0
        local eta = options.eta or 0.15
    
        local x = vec_copy(x0)
        local n = #x
        local delta = options.delta or 1.0
    
        for iter = 1, max_iter do
            local fx = F(x)
            local fx_norm = vec_norm(fx)
    
            if verbose then
                print(string.format("  iter %d: |F(x)| = %.2e, delta = %.4f", iter, fx_norm, delta))
            end
    
            if fx_norm < tol then
                return x, true, iter
            end
    
            -- 计算雅可比矩阵
            local J = numerical_jacobian(F, x)
    
            -- 计算 J^T * F（梯度）
            local JTF = {}
            for j = 1, n do
                local sum = 0
                for i = 1, n do
                    sum = sum + J[i][j] * fx[i]
                end
                JTF[j] = sum
            end
    
            -- 计算柯西点（最速下降方向）
            local JTJ = {}
            for i = 1, n do
                JTJ[i] = {}
                for j = 1, n do
                    local sum = 0
                    for k = 1, n do
                        sum = sum + J[k][i] * J[k][j]
                    end
                    JTJ[i][j] = sum
                end
            end
    
            local JTFJTJ = {}
            for i = 1, n do
                local sum = 0
                for j = 1, n do
                    sum = sum + JTJ[i][j] * JTF[j]
                end
                JTFJTJ[i] = sum
            end
    
            local alpha_c = 0
            local JTF_norm_sq = 0
            local JTFJTJ_norm_sq = 0
            for i = 1, n do
                JTF_norm_sq = JTF_norm_sq + JTF[i] * JTF[i]
                JTFJTJ_norm_sq = JTFJTJ_norm_sq + JTFJTJ[i] * JTFJTJ[i]
            end
    
            if JTFJTJ_norm_sq > 1e-20 then
                alpha_c = JTF_norm_sq / JTFJTJ_norm_sq
            end
    
            -- 柯西点
            local p_c = vec_scale(JTF, -alpha_c)
            local p_c_norm = vec_norm(p_c)
    
            -- 计算高斯-牛顿步
            local neg_fx = vec_scale(fx, -1)
            local p_gn = solve_linear(J, neg_fx)
            local p_gn_norm = vec_norm(p_gn)
    
            -- 选择步长
            local p
            if p_gn_norm <= delta then
                -- 使用高斯-牛顿步
                p = p_gn
            elseif p_c_norm >= delta then
                -- 沿柯西方向截断
                p = vec_scale(p_c, delta / p_c_norm)
            else
                -- Dogleg步
                -- 在 p_c 和 p_gn 之间插值
                local diff = vec_sub(p_gn, p_c)
                local a = 0
                for i = 1, n do
                    a = a + diff[i] * diff[i]
                end
                local b = 0
                for i = 1, n do
                    b = b + p_c[i] * diff[i]
                end
                local c = p_c_norm * p_c_norm - delta * delta
    
                local tau
                if a < 1e-20 then
                    tau = 0
                else
                    local disc = b * b - a * c
                    if disc < 0 then
                        tau = -b / a
                    else
                        tau = (-b + math.sqrt(disc)) / a
                    end
                end
                tau = math.max(0, math.min(1, tau))
    
                p = vec_add(p_c, vec_scale(diff, tau))
            end
    
            -- 计算预测下降
            local predicted = 0
            for i = 1, n do
                predicted = predicted + fx[i] * fx[i]
            end
            local Jp = {}
            for i = 1, n do
                local sum = 0
                for j = 1, n do
                    sum = sum + J[i][j] * p[j]
                end
                Jp[i] = sum
            end
            for i = 1, n do
                predicted = predicted + 2 * fx[i] * Jp[i]
            end
            for i = 1, n do
                predicted = predicted + Jp[i] * Jp[i]
            end
            predicted = -0.5 * predicted
    
            -- 试探新点
            local x_new = vec_add(x, p)
            local fx_new = F(x_new)
            local fx_new_norm = vec_norm(fx_new)
    
            -- 计算实际下降
            local actual = 0.5 * (fx_norm * fx_norm - fx_new_norm * fx_new_norm)
    
            -- 计算比率
            local rho = 0
            if math.abs(predicted) > 1e-20 then
                rho = actual / predicted
            end
    
            -- 更新信赖域半径
            if rho < 0.25 then
                delta = 0.25 * delta
            elseif rho > 0.75 and math.abs(vec_norm(p) - delta) < 1e-10 then
                delta = math.min(2 * delta, delta_max)
            end
    
            -- 接受或拒绝步
            if rho > eta then
                x = x_new
            end
        end
    
        return x, false, max_iter
    end
    
    -- =============================================================================
    -- 统一接口
    -- =============================================================================
    
    -- 多维根求解统一接口
    -- @param F 函数向量 F(x) 或函数表 {f1, f2, ...}
    -- @param x0 初始猜测
    -- @param options 选项表：
    --   - method: 方法名（"newton", "broyden", "fixed_point", "trust_region"）
    --   - 其他方法特定选项
    -- @return 解向量，收敛标志，迭代次数
    function multi_root.find_root(F, x0, options)
        options = options or {}
        local method = options.method or "newton"
    
        -- 如果 F 是函数表，转换为单一函数
        local F_func
        if type(F) == "table" then
            F_func = function(x)
                local result = {}
                for i, f in ipairs(F) do
                    result[i] = f(x)
                end
                return result
            end
        else
            F_func = F
        end
    
        if method == "newton" then
            return multi_root.newton(F_func, x0, options)
        elseif method == "broyden" then
            return multi_root.broyden(F_func, x0, options)
        elseif method == "fixed_point" then
            -- 对于不动点迭代，需要构造 G(x) = x - F(x)
            local G = function(x)
                local fx = F_func(x)
                return vec_sub(x, fx)
            end
            return multi_root.fixed_point(G, x0, options)
        elseif method == "trust_region" then
            return multi_root.trust_region(F_func, x0, options)
        else
            error("Unknown root finding method: " .. method)
        end
    end
    
    -- 别名
    multi_root.solve = multi_root.find_root
    multi_root.nsolve = multi_root.find_root
    
    return multi_root
end

-- 模块: pde.elliptic
_module_loaders["pde.elliptic"] = function()
    -- 椭圆型方程求解器
    -- 包括泊松方程和拉普拉斯方程的有限差分求解方法
    
    local utils = require("utils.init")
    
    local elliptic = {}
    
    -- =============================================================================
    -- 辅助函数
    -- =============================================================================
    
    -- 初始化网格
    local function create_grid(nx, ny, init_value)
        init_value = init_value or 0
        local grid = {}
        for i = 1, nx do
            grid[i] = {}
            for j = 1, ny do
                grid[i][j] = init_value
            end
        end
        return grid
    end
    
    -- 复制网格
    local function copy_grid(u)
        local copy = {}
        for i = 1, #u do
            copy[i] = {}
            for j = 1, #u[1] do
                copy[i][j] = u[i][j]
            end
        end
        return copy
    end
    
    -- 计算最大差异（用于收敛判断）
    local function max_diff(u1, u2)
        local max_d = 0
        for i = 1, #u1 do
            for j = 1, #u1[1] do
                local d = math.abs(u1[i][j] - u2[i][j])
                if d > max_d then
                    max_d = d
                end
            end
        end
        return max_d
    end
    
    -- 计算残差范数
    local function residual_norm(u, f, nx, ny, dx, dy)
        local sum = 0
        local dx2 = dx * dx
        local dy2 = dy * dy
    
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                local laplacian = (u[i+1][j] - 2*u[i][j] + u[i-1][j]) / dx2
                              + (u[i][j+1] - 2*u[i][j] + u[i][j-1]) / dy2
                local f_val = type(f) == "function" and f(i, j) or f
                local r = laplacian - f_val
                sum = sum + r * r
            end
        end
    
        return math.sqrt(sum)
    end
    
    -- =============================================================================
    -- 边界条件处理
    -- =============================================================================
    
    -- 应用边界条件
    local function apply_boundary_conditions(u, bc, nx, ny, dx, dy)
        -- 左边界 (i = 1)
        if bc.left then
            if bc.left.type == "dirichlet" then
                for j = 1, ny do
                    u[1][j] = bc.left.value
                end
            elseif bc.left.type == "neumann" then
                -- 使用一阶差分: (u[2][j] - u[1][j]) / dx = value
                for j = 1, ny do
                    u[1][j] = u[2][j] - dx * bc.left.value
                end
            end
        end
    
        -- 右边界 (i = nx)
        if bc.right then
            if bc.right.type == "dirichlet" then
                for j = 1, ny do
                    u[nx][j] = bc.right.value
                end
            elseif bc.right.type == "neumann" then
                for j = 1, ny do
                    u[nx][j] = u[nx-1][j] + dx * bc.right.value
                end
            end
        end
    
        -- 下边界 (j = 1)
        if bc.bottom then
            if bc.bottom.type == "dirichlet" then
                for i = 1, nx do
                    u[i][1] = bc.bottom.value
                end
            elseif bc.bottom.type == "neumann" then
                for i = 1, nx do
                    u[i][1] = u[i][2] - dy * bc.bottom.value
                end
            end
        end
    
        -- 上边界 (j = ny)
        if bc.top then
            if bc.top.type == "dirichlet" then
                for i = 1, nx do
                    u[i][ny] = bc.top.value
                end
            elseif bc.top.type == "neumann" then
                for i = 1, nx do
                    u[i][ny] = u[i][ny-1] + dy * bc.top.value
                end
            end
        end
    end
    
    -- =============================================================================
    -- 迭代求解方法
    -- =============================================================================
    
    -- Jacobi 迭代法
    local function jacobi_iteration(u, f, bc, nx, ny, dx, dy)
        local u_new = copy_grid(u)
        local dx2 = dx * dx
        local dy2 = dy * dy
        local factor = 2 * (1/dx2 + 1/dy2)
    
        -- 内部点更新
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                local f_val = type(f) == "function" and f(i, j) or f
                u_new[i][j] = ((u[i+1][j] + u[i-1][j]) / dx2
                            + (u[i][j+1] + u[i][j-1]) / dy2
                            - f_val) / factor
            end
        end
    
        -- 应用边界条件
        apply_boundary_conditions(u_new, bc, nx, ny, dx, dy)
    
        return u_new
    end
    
    -- Gauss-Seidel 迭代法
    local function gauss_seidel_iteration(u, f, bc, nx, ny, dx, dy)
        local dx2 = dx * dx
        local dy2 = dy * dy
        local factor = 2 * (1/dx2 + 1/dy2)
    
        -- 原地更新
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                local f_val = type(f) == "function" and f(i, j) or f
                u[i][j] = ((u[i+1][j] + u[i-1][j]) / dx2
                        + (u[i][j+1] + u[i][j-1]) / dy2
                        - f_val) / factor
            end
        end
    
        -- 应用边界条件
        apply_boundary_conditions(u, bc, nx, ny, dx, dy)
    
        return u
    end
    
    -- SOR（逐次超松弛）迭代法
    local function sor_iteration(u, f, bc, nx, ny, dx, dy, omega)
        local dx2 = dx * dx
        local dy2 = dy * dy
        local factor = 2 * (1/dx2 + 1/dy2)
    
        -- 原地更新
        for i = 2, nx - 1 do
            for j = 2, ny - 1 do
                local f_val = type(f) == "function" and f(i, j) or f
                local gs_val = ((u[i+1][j] + u[i-1][j]) / dx2
                            + (u[i][j+1] + u[i][j-1]) / dy2
                            - f_val) / factor
                u[i][j] = (1 - omega) * u[i][j] + omega * gs_val
            end
        end
    
        -- 应用边界条件
        apply_boundary_conditions(u, bc, nx, ny, dx, dy)
    
        return u
    end
    
    -- 计算最优松弛因子（对于矩形区域）
    local function optimal_omega(nx, ny, dx, dy)
        -- 对于正方形区域的最优omega
        local pi = math.pi
        local hx = dx / (nx - 1)
        local hy = dy / (ny - 1)
    
        -- Jacobi迭代矩阵的最大特征值
        local rho_j = math.cos(pi / (nx - 1)) * (hx * hx) / (hx * hx + hy * hy)
                    + math.cos(pi / (ny - 1)) * (hy * hy) / (hx * hx + hy * hy)
    
        -- 最优松弛因子
        return 2 / (1 + math.sqrt(1 - rho_j * rho_j))
    end
    
    -- =============================================================================
    -- 主求解函数
    -- =============================================================================
    
    -- 求解二维泊松方程: ∇²u = f
    -- @param f 源项函数 f(x, y) 或常数值
    -- @param bounds 区域边界 {ax, bx, ay, by}
    -- @param bc 边界条件表 {left, right, top, bottom}
    --   每个边界条件: {type = "dirichlet"|"neumann", value = ...}
    -- @param options 选项表：
    --   - nx, ny: 网格点数（默认 50）
    --   - max_iter: 最大迭代次数（默认 10000）
    --   - tol: 收敛容差（默认 1e-6）
    --   - method: 求解方法 "jacobi"|"gauss_seidel"|"sor"（默认 "sor"）
    --   - omega: SOR松弛因子（可选，默认自动计算）
    --   - verbose: 是否打印迭代信息
    -- @return 解网格 u[i][j]，收敛信息
    function elliptic.poisson(f, bounds, bc, options)
        -- 参数验证
        utils.typecheck.check_type("poisson", "bounds", bounds, "table")
        utils.typecheck.check_type("poisson", "bc", bc, "table")
        utils.typecheck.check_type("poisson", "options", options, "table", "nil")
    
        options = options or {}
        local nx = options.nx or 50
        local ny = options.ny or 50
        local max_iter = options.max_iter or 10000
        local tol = options.tol or 1e-6
        local method = options.method or "sor"
        local verbose = options.verbose or false
    
        -- 解析边界
        local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
        local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1
    
        local dx = (bx - ax) / (nx - 1)
        local dy = (by - ay) / (ny - 1)
    
        -- 初始化解网格
        local u = create_grid(nx, ny, 0)
    
        -- 应用初始边界条件
        apply_boundary_conditions(u, bc, nx, ny, dx, dy)
    
        -- 选择迭代方法
        local iterate
        local omega = options.omega
    
        if method == "jacobi" then
            iterate = function(u_curr)
                return jacobi_iteration(u_curr, f, bc, nx, ny, dx, dy)
            end
        elseif method == "gauss_seidel" then
            iterate = function(u_curr)
                return gauss_seidel_iteration(u_curr, f, bc, nx, ny, dx, dy)
            end
        elseif method == "sor" then
            omega = omega or optimal_omega(nx, ny, bx - ax, by - ay)
            if verbose then
                print(string.format("  SOR omega: %.4f", omega))
            end
            iterate = function(u_curr)
                return sor_iteration(u_curr, f, bc, nx, ny, dx, dy, omega)
            end
        else
            error("Unknown method: " .. method)
        end
    
        -- 迭代求解
        local converged = false
        local iter
    
        for iter = 1, max_iter do
            local u_old = (method == "jacobi") and copy_grid(u) or nil
            u = iterate(u)
    
            -- 检查收敛
            local diff
            if method == "jacobi" then
                diff = max_diff(u, u_old)
            else
                -- 对于Gauss-Seidel和SOR，使用残差估计
                diff = residual_norm(u, f, nx, ny, dx, dy)
            end
    
            if verbose and iter % 100 == 0 then
                print(string.format("  iter %d: diff = %.2e", iter, diff))
            end
    
            if diff < tol then
                converged = true
                break
            end
        end
    
        -- 返回结果
        local info = {
            converged = converged,
            iterations = iter or max_iter,
            method = method,
            omega = omega
        }
    
        return u, info
    end
    
    -- 求解二维拉普拉斯方程: ∇²u = 0
    -- @param bounds 区域边界 {ax, bx, ay, by}
    -- @param bc 边界条件表
    -- @param options 选项表
    -- @return 解网格 u[i][j]，收敛信息
    function elliptic.laplace(bounds, bc, options)
        -- 拉普拉斯方程是泊松方程 f = 0 的特例
        return elliptic.poisson(0, bounds, bc, options)
    end
    
    -- 求解带狄利克雷边界条件的泊松方程（简化接口）
    -- @param f 源项函数
    -- @param bounds 区域边界
    -- @param boundary_values 边界值 {left, right, bottom, top}
    -- @param options 选项
    -- @return 解网格
    function elliptic.poisson_simple(f, bounds, boundary_values, options)
        local bc = {
            left = {type = "dirichlet", value = boundary_values[1] or boundary_values.left or 0},
            right = {type = "dirichlet", value = boundary_values[2] or boundary_values.right or 0},
            bottom = {type = "dirichlet", value = boundary_values[3] or boundary_values.bottom or 0},
            top = {type = "dirichlet", value = boundary_values[4] or boundary_values.top or 0}
        }
        return elliptic.poisson(f, bounds, bc, options)
    end
    
    -- =============================================================================
    -- 辅助输出函数
    -- =============================================================================
    
    -- 获取网格坐标
    function elliptic.grid_coords(bounds, nx, ny)
        local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
        local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1
    
        local x = {}
        local y = {}
    
        for i = 1, nx do
            x[i] = ax + (i - 1) * (bx - ax) / (nx - 1)
        end
    
        for j = 1, ny do
            y[j] = ay + (j - 1) * (by - ay) / (ny - 1)
        end
    
        return x, y
    end
    
    -- 获取解在特定点的值（双线性插值）
    function elliptic.interpolate(u, bounds, x, y)
        local nx, ny = #u, #u[1]
        local ax, bx = bounds[1] or bounds.ax or 0, bounds[2] or bounds.bx or 1
        local ay, by = bounds[3] or bounds.ay or 0, bounds[4] or bounds.by or 1
    
        local dx = (bx - ax) / (nx - 1)
        local dy = (by - ay) / (ny - 1)
    
        -- 找到所在的网格单元
        local i = math.floor((x - ax) / dx) + 1
        local j = math.floor((y - ay) / dy) + 1
    
        -- 边界处理
        i = math.max(1, math.min(nx - 1, i))
        j = math.max(1, math.min(ny - 1, j))
    
        -- 双线性插值
        local tx = (x - (ax + (i - 1) * dx)) / dx
        local ty = (y - (ay + (j - 1) * dy)) / dy
    
        tx = math.max(0, math.min(1, tx))
        ty = math.max(0, math.min(1, ty))
    
        local u00 = u[i][j]
        local u10 = u[i + 1][j]
        local u01 = u[i][j + 1]
        local u11 = u[i + 1][j + 1]
    
        return (1 - tx) * (1 - ty) * u00 + tx * (1 - ty) * u10
             + (1 - tx) * ty * u01 + tx * ty * u11
    end
    
    return elliptic
end

-- 模块: pde.parabolic
_module_loaders["pde.parabolic"] = function()
    -- 抛物型方程求解器
    -- 包括热传导方程的有限差分求解方法
    
    local utils = require("utils.init")
    
    local parabolic = {}
    
    -- =============================================================================
    -- 辅助函数
    -- =============================================================================
    
    -- 创建一维数组
    local function create_array(n, init_value)
        init_value = init_value or 0
        local arr = {}
        for i = 1, n do
            arr[i] = init_value
        end
        return arr
    end
    
    -- 复制数组
    local function copy_array(arr)
        local copy = {}
        for i = 1, #arr do
            copy[i] = arr[i]
        end
        return copy
    end
    
    -- 创建二维解矩阵
    local function create_solution_matrix(nt, nx)
        local sol = {}
        for t = 1, nt do
            sol[t] = create_array(nx, 0)
        end
        return sol
    end
    
    -- 三对角方程组求解器（Thomas算法）
    -- 求解 a[i]*x[i-1] + b[i]*x[i] + c[i]*x[i+1] = d[i]
    local function thomas_solver(a, b, c, d)
        local n = #d
        local x = create_array(n, 0)
    
        -- 前向消元
        local c_prime = create_array(n, 0)
        local d_prime = create_array(n, 0)
    
        c_prime[1] = c[1] / b[1]
        d_prime[1] = d[1] / b[1]
    
        for i = 2, n do
            local m = b[i] - a[i] * c_prime[i-1]
            c_prime[i] = c[i] / m
            d_prime[i] = (d[i] - a[i] * d_prime[i-1]) / m
        end
    
        -- 回代
        x[n] = d_prime[n]
        for i = n - 1, 1, -1 do
            x[i] = d_prime[i] - c_prime[i] * x[i+1]
        end
    
        return x
    end
    
    -- =============================================================================
    -- 一维热传导方程求解器
    -- =============================================================================
    
    -- FTCS 显式方法求解一维热传导方程
    -- ∂u/∂t = α * ∂²u/∂x²
    -- @param alpha 热扩散系数
    -- @param ic 初始条件函数 u0(x)
    -- @param bc 边界条件 {left = {type, value}, right = {type, value}}
    -- @param x_span 空间区间 {x0, x_end}
    -- @param t_span 时间区间 {t0, t_end}
    -- @param options 选项：{nx, nt, r} 或自动计算
    -- @return x网格, t网格, 解矩阵 u[t][x]
    local function heat1d_ftcs(alpha, ic, bc, x_span, t_span, options)
        options = options or {}
        local nx = options.nx or 50
        local r = options.r  -- r = alpha * dt / dx^2
    
        local x0, x_end = x_span[1] or 0, x_span[2] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (x_end - x0) / (nx - 1)
        local dt, nt
    
        -- 根据稳定性条件确定时间步长
        if r then
            dt = r * dx * dx / alpha
        else
            -- 自动选择满足稳定性条件的步长
            r = 0.4  -- 留出余量
            dt = r * dx * dx / alpha
        end
    
        nt = math.floor((t_end - t0) / dt) + 1
        dt = (t_end - t0) / (nt - 1)
        r = alpha * dt / (dx * dx)
    
        -- 稳定性检查
        if r > 0.5 then
            -- 自动调整
            nt = math.ceil(nt * r / 0.4)
            dt = (t_end - t0) / (nt - 1)
            r = alpha * dt / (dx * dx)
        end
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local t = create_array(nt, 0)
        for i = 1, nx do
            x[i] = x0 + (i - 1) * dx
        end
        for n = 1, nt do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解矩阵
        local u = create_solution_matrix(nt, nx)
    
        -- 初始条件
        for i = 1, nx do
            u[1][i] = ic(x[i])
        end
    
        -- 应用初始边界条件
        if bc.left and bc.left.type == "dirichlet" then
            u[1][1] = bc.left.value
        end
        if bc.right and bc.right.type == "dirichlet" then
            u[1][nx] = bc.right.value
        end
    
        -- 时间步进
        for n = 1, nt - 1 do
            -- FTCS 更新内部点
            for i = 2, nx - 1 do
                u[n+1][i] = u[n][i] + r * (u[n][i+1] - 2*u[n][i] + u[n][i-1])
            end
    
            -- 边界条件
            if bc.left then
                if bc.left.type == "dirichlet" then
                    u[n+1][1] = bc.left.value
                elseif bc.left.type == "neumann" then
                    u[n+1][1] = u[n+1][2] - dx * bc.left.value
                end
            end
    
            if bc.right then
                if bc.right.type == "dirichlet" then
                    u[n+1][nx] = bc.right.value
                elseif bc.right.type == "neumann" then
                    u[n+1][nx] = u[n+1][nx-1] + dx * bc.right.value
                end
            end
        end
    
        return x, t, u
    end
    
    -- Crank-Nicolson 隐式方法求解一维热传导方程
    -- 无条件稳定，二阶精度
    local function heat1d_crank_nicolson(alpha, ic, bc, x_span, t_span, options)
        options = options or {}
        local nx = options.nx or 50
        local nt = options.nt or 100
    
        local x0, x_end = x_span[1] or 0, x_span[2] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (x_end - x0) / (nx - 1)
        local dt = (t_end - t0) / (nt - 1)
        local r = alpha * dt / (dx * dx)
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local t = create_array(nt, 0)
        for i = 1, nx do
            x[i] = x0 + (i - 1) * dx
        end
        for n = 1, nt do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解矩阵
        local u = create_solution_matrix(nt, nx)
    
        -- 初始条件
        for i = 1, nx do
            u[1][i] = ic(x[i])
        end
    
        -- 应用初始边界条件
        if bc.left and bc.left.type == "dirichlet" then
            u[1][1] = bc.left.value
        end
        if bc.right and bc.right.type == "dirichlet" then
            u[1][nx] = bc.right.value
        end
    
        -- Crank-Nicolson 系数
        -- (1 + r) * u[i]^{n+1} - 0.5*r * (u[i-1]^{n+1} + u[i+1]^{n+1})
        -- = (1 - r) * u[i]^n + 0.5*r * (u[i-1]^n + u[i+1]^n)
    
        local a = create_array(nx, 0)  -- 下对角线
        local b = create_array(nx, 0)  -- 主对角线
        local c = create_array(nx, 0)  -- 上对角线
        local d = create_array(nx, 0)  -- 右端项
    
        -- 设置三对角矩阵系数
        for i = 2, nx - 1 do
            a[i] = -0.5 * r
            b[i] = 1 + r
            c[i] = -0.5 * r
        end
    
        -- 时间步进
        for n = 1, nt - 1 do
            -- 构造右端项
            for i = 2, nx - 1 do
                d[i] = (1 - r) * u[n][i] + 0.5 * r * (u[n][i-1] + u[n][i+1])
            end
    
            -- 边界条件处理
            if bc.left then
                if bc.left.type == "dirichlet" then
                    b[1] = 1
                    c[1] = 0
                    d[1] = bc.left.value
                    -- 修改第二个方程
                    d[2] = d[2] + 0.5 * r * bc.left.value
                elseif bc.left.type == "neumann" then
                    -- 使用虚拟点处理Neumann边界
                    b[1] = 1 + r
                    c[1] = -r
                    d[1] = u[n][1] + r * dx * bc.left.value
                end
            else
                b[1] = 1
                c[1] = 0
                d[1] = u[n][1]
            end
    
            if bc.right then
                if bc.right.type == "dirichlet" then
                    a[nx] = 0
                    b[nx] = 1
                    d[nx] = bc.right.value
                    d[nx-1] = d[nx-1] + 0.5 * r * bc.right.value
                elseif bc.right.type == "neumann" then
                    a[nx] = -r
                    b[nx] = 1 + r
                    d[nx] = u[n][nx] - r * dx * bc.right.value
                end
            else
                a[nx] = 0
                b[nx] = 1
                d[nx] = u[n][nx]
            end
    
            -- 求解三对角方程组
            local u_new = thomas_solver(a, b, c, d)
    
            -- 存储解
            for i = 1, nx do
                u[n+1][i] = u_new[i]
            end
        end
    
        return x, t, u
    end
    
    -- 统一接口：求解一维热传导方程
    -- @param alpha 热扩散系数
    -- @param ic 初始条件函数 u0(x)
    -- @param bc 边界条件
    -- @param x_span 空间区间
    -- @param t_span 时间区间
    -- @param options: {method = "ftcs"|"cn", nx, nt, r}
    function parabolic.heat1d(alpha, ic, bc, x_span, t_span, options)
        -- 参数验证
        utils.typecheck.check_type("heat1d", "alpha", alpha, "number")
        utils.typecheck.check_type("heat1d", "ic", ic, "function")
        utils.typecheck.check_type("heat1d", "bc", bc, "table")
        utils.typecheck.check_type("heat1d", "x_span", x_span, "table")
        utils.typecheck.check_type("heat1d", "t_span", t_span, "table")
    
        options = options or {}
        local method = options.method or "ftcs"
    
        if method == "ftcs" or method == "explicit" then
            return heat1d_ftcs(alpha, ic, bc, x_span, t_span, options)
        elseif method == "cn" or method == "crank_nicolson" or method == "implicit" then
            return heat1d_crank_nicolson(alpha, ic, bc, x_span, t_span, options)
        else
            error("Unknown method for heat1d: " .. method)
        end
    end
    
    -- =============================================================================
    -- 二维热传导方程求解器
    -- =============================================================================
    
    -- ADI（交替方向隐式）方法求解二维热传导方程
    -- ∂u/∂t = α * (∂²u/∂x² + ∂²u/∂y²)
    -- @param alpha 热扩散系数
    -- @param ic 初始条件函数 u0(x, y)
    -- @param bc 边界条件 {left, right, bottom, top}
    -- @param bounds 区域边界 {ax, bx, ay, by}
    -- @param t_span 时间区间
    -- @param options: {nx, ny, nt}
    function parabolic.heat2d(alpha, ic, bc, bounds, t_span, options)
        -- 参数验证
        utils.typecheck.check_type("heat2d", "alpha", alpha, "number")
        utils.typecheck.check_type("heat2d", "ic", ic, "function")
        utils.typecheck.check_type("heat2d", "bounds", bounds, "table")
        utils.typecheck.check_type("heat2d", "t_span", t_span, "table")
    
        options = options or {}
        local nx = options.nx or 30
        local ny = options.ny or 30
        local nt = options.nt or 50
    
        local ax, bx = bounds[1] or 0, bounds[2] or 1
        local ay, by = bounds[3] or 0, bounds[4] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (bx - ax) / (nx - 1)
        local dy = (by - ay) / (ny - 1)
        local dt = (t_end - t0) / nt
    
        local rx = alpha * dt / (dx * dx)
        local ry = alpha * dt / (dy * dy)
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local y = create_array(ny, 0)
        local t = create_array(nt + 1, 0)
    
        for i = 1, nx do
            x[i] = ax + (i - 1) * dx
        end
        for j = 1, ny do
            y[j] = ay + (j - 1) * dy
        end
        for n = 1, nt + 1 do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解网格（三维：时间 × x × y）
        local u = {}
        for n = 1, nt + 1 do
            u[n] = {}
            for i = 1, nx do
                u[n][i] = create_array(ny, 0)
            end
        end
    
        -- 初始条件
        for i = 1, nx do
            for j = 1, ny do
                u[1][i][j] = ic(x[i], y[j])
            end
        end
    
        -- 应用初始边界条件
        local function apply_bc_2d(u_curr)
            if bc.left and bc.left.type == "dirichlet" then
                for j = 1, ny do
                    u_curr[1][j] = bc.left.value
                end
            end
            if bc.right and bc.right.type == "dirichlet" then
                for j = 1, ny do
                    u_curr[nx][j] = bc.right.value
                end
            end
            if bc.bottom and bc.bottom.type == "dirichlet" then
                for i = 1, nx do
                    u_curr[i][1] = bc.bottom.value
                end
            end
            if bc.top and bc.top.type == "dirichlet" then
                for i = 1, nx do
                    u_curr[i][ny] = bc.top.value
                end
            end
        end
    
        apply_bc_2d(u[1])
    
        -- ADI 方法时间步进
        for n = 1, nt do
            -- 半步：x 方向隐式，y 方向显式
            local u_half = {}
            for i = 1, nx do
                u_half[i] = create_array(ny, 0)
            end
    
            -- 对每一行求解三对角方程组
            for j = 2, ny - 1 do
                local a = create_array(nx, 0)
                local b = create_array(nx, 0)
                local c = create_array(nx, 0)
                local d = create_array(nx, 0)
    
                for i = 2, nx - 1 do
                    a[i] = -0.5 * rx
                    b[i] = 1 + rx
                    c[i] = -0.5 * rx
                    d[i] = u[n][i][j] + 0.5 * ry * (u[n][i][j+1] - 2*u[n][i][j] + u[n][i][j-1])
                end
    
                -- 边界
                b[1] = 1; c[1] = 0; d[1] = bc.left and bc.left.value or u[n][1][j]
                a[nx] = 0; b[nx] = 1; d[nx] = bc.right and bc.right.value or u[n][nx][j]
    
                local row = thomas_solver(a, b, c, d)
                for i = 1, nx do
                    u_half[i][j] = row[i]
                end
            end
    
            -- 边界行的处理
            for j = 1, ny do
                if bc.bottom and bc.bottom.type == "dirichlet" then
                    for i = 1, nx do u_half[i][1] = bc.bottom.value end
                end
                if bc.top and bc.top.type == "dirichlet" then
                    for i = 1, nx do u_half[i][ny] = bc.top.value end
                end
            end
    
            -- 半步：y 方向隐式，x 方向显式
            for i = 2, nx - 1 do
                local a = create_array(ny, 0)
                local b = create_array(ny, 0)
                local c = create_array(ny, 0)
                local d = create_array(ny, 0)
    
                for j = 2, ny - 1 do
                    a[j] = -0.5 * ry
                    b[j] = 1 + ry
                    c[j] = -0.5 * ry
                    d[j] = u_half[i][j] + 0.5 * rx * (u_half[i+1][j] - 2*u_half[i][j] + u_half[i-1][j])
                end
    
                b[1] = 1; c[1] = 0; d[1] = bc.bottom and bc.bottom.value or u_half[i][1]
                a[ny] = 0; b[ny] = 1; d[ny] = bc.top and bc.top.value or u_half[i][ny]
    
                local col = thomas_solver(a, b, c, d)
                for j = 1, ny do
                    u[n+1][i][j] = col[j]
                end
            end
    
            -- 边界列
            for j = 1, ny do
                if bc.left and bc.left.type == "dirichlet" then
                    u[n+1][1][j] = bc.left.value
                end
                if bc.right and bc.right.type == "dirichlet" then
                    u[n+1][nx][j] = bc.right.value
                end
            end
        end
    
        return x, y, t, u
    end
    
    -- =============================================================================
    -- 别名
    -- =============================================================================
    
    parabolic.diffusion1d = parabolic.heat1d
    parabolic.diffusion2d = parabolic.heat2d
    
    return parabolic
end

-- 模块: pde.hyperbolic
_module_loaders["pde.hyperbolic"] = function()
    -- 双曲型方程求解器
    -- 包括波动方程和对流方程的有限差分求解方法
    
    local utils = require("utils.init")
    
    local hyperbolic = {}
    
    -- =============================================================================
    -- 辅助函数
    -- =============================================================================
    
    -- 创建一维数组
    local function create_array(n, init_value)
        init_value = init_value or 0
        local arr = {}
        for i = 1, n do
            arr[i] = init_value
        end
        return arr
    end
    
    -- 创建二维解矩阵
    local function create_solution_matrix(nt, nx)
        local sol = {}
        for t = 1, nt do
            sol[t] = create_array(nx, 0)
        end
        return sol
    end
    
    -- =============================================================================
    -- 一维波动方程求解器
    -- =============================================================================
    
    -- 显式有限差分方法求解一维波动方程
    -- ∂²u/∂t² = c² * ∂²u/∂x²
    -- 使用中心差分格式，二阶精度
    -- @param c 波速
    -- @param ic_u 初始位移 u(x, 0)
    -- @param ic_v 初始速度 ∂u/∂t(x, 0)
    -- @param bc 边界条件
    -- @param x_span 空间区间
    -- @param t_span 时间区间
    -- @param options: {nx, nt, cfl}
    -- @return x网格, t网格, 解矩阵 u[t][x]
    function hyperbolic.wave1d(c, ic_u, ic_v, bc, x_span, t_span, options)
        -- 参数验证
        utils.typecheck.check_type("wave1d", "c", c, "number")
        utils.typecheck.check_type("wave1d", "ic_u", ic_u, "function")
        utils.typecheck.check_type("wave1d", "ic_v", ic_v, "function", "nil")
        utils.typecheck.check_type("wave1d", "bc", bc, "table")
        utils.typecheck.check_type("wave1d", "x_span", x_span, "table")
        utils.typecheck.check_type("wave1d", "t_span", t_span, "table")
    
        options = options or {}
        local nx = options.nx or 100
        local cfl = options.cfl or 0.8  -- CFL数，需 <= 1 保持稳定
    
        local x0, x_end = x_span[1] or 0, x_span[2] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (x_end - x0) / (nx - 1)
        local dt = cfl * dx / c  -- 根据 CFL 条件确定时间步长
        local nt = math.floor((t_end - t0) / dt) + 1
        dt = (t_end - t0) / (nt - 1)
    
        -- 更新实际的 CFL 数
        cfl = c * dt / dx
        if cfl > 1 then
            -- 如果 CFL > 1，增加时间步数
            nt = math.ceil(nt * cfl)
            dt = (t_end - t0) / (nt - 1)
            cfl = c * dt / dx
        end
    
        local r2 = cfl * cfl  -- r = c * dt / dx
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local t = create_array(nt, 0)
        for i = 1, nx do
            x[i] = x0 + (i - 1) * dx
        end
        for n = 1, nt do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解矩阵
        local u = create_solution_matrix(nt, nx)
    
        -- 初始条件：位移
        for i = 1, nx do
            u[1][i] = ic_u(x[i])
        end
    
        -- 初始条件：速度（用于计算第二步）
        -- 使用 Taylor 展开: u(x, dt) ≈ u(x, 0) + dt * v(x, 0) + 0.5 * dt² * c² * u_xx(x, 0)
        if ic_v then
            for i = 2, nx - 1 do
                local u_xx = (u[1][i+1] - 2*u[1][i] + u[1][i-1]) / (dx * dx)
                u[2][i] = u[1][i] + dt * ic_v(x[i]) + 0.5 * dt * dt * c * c * u_xx
            end
        else
            -- 如果没有初始速度，使用简单外推
            for i = 2, nx - 1 do
                u[2][i] = u[1][i]
            end
        end
    
        -- 边界条件（初始时刻）
        if bc.left then
            u[1][1] = bc.left.value or 0
            u[2][1] = bc.left.value or 0
        end
        if bc.right then
            u[1][nx] = bc.right.value or 0
            u[2][nx] = bc.right.value or 0
        end
    
        -- 时间步进（显式格式）
        for n = 2, nt - 1 do
            -- 内部点更新
            for i = 2, nx - 1 do
                u[n+1][i] = 2*(1 - r2)*u[n][i] + r2*(u[n][i+1] + u[n][i-1]) - u[n-1][i]
            end
    
            -- 边界条件
            if bc.left then
                if bc.left.type == "dirichlet" then
                    u[n+1][1] = bc.left.value
                elseif bc.left.type == "neumann" then
                    -- 反射边界
                    u[n+1][1] = u[n+1][2]
                elseif bc.left.type == "absorbing" then
                    -- 吸收边界（一阶）
                    u[n+1][1] = u[n][2] + (cfl - 1) / (cfl + 1) * (u[n+1][2] - u[n][1])
                end
            end
    
            if bc.right then
                if bc.right.type == "dirichlet" then
                    u[n+1][nx] = bc.right.value
                elseif bc.right.type == "neumann" then
                    u[n+1][nx] = u[n+1][nx-1]
                elseif bc.right.type == "absorbing" then
                    u[n+1][nx] = u[n][nx-1] + (cfl - 1) / (cfl + 1) * (u[n+1][nx-1] - u[n][nx])
                end
            end
        end
    
        return x, t, u
    end
    
    -- =============================================================================
    -- 一阶对流方程求解器
    -- =============================================================================
    
    -- 求解一阶对流方程: ∂u/∂t + a * ∂u/∂x = 0
    -- @param a 对流速度（a > 0 波向右传播，a < 0 波向左传播）
    -- @param ic 初始条件函数
    -- @param bc 边界条件
    -- @param x_span 空间区间
    -- @param t_span 时间区间
    -- @param options: {scheme = "upwind"|"lax_friedrichs"|"lax_wendroff", nx, cfl}
    function hyperbolic.advection1d(a, ic, bc, x_span, t_span, options)
        -- 参数验证
        utils.typecheck.check_type("advection1d", "a", a, "number")
        utils.typecheck.check_type("advection1d", "ic", ic, "function")
        utils.typecheck.check_type("advection1d", "x_span", x_span, "table")
        utils.typecheck.check_type("advection1d", "t_span", t_span, "table")
    
        options = options or {}
        local scheme = options.scheme or "upwind"
        local nx = options.nx or 100
        local cfl = options.cfl or 0.8
    
        local x0, x_end = x_span[1] or 0, x_span[2] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (x_end - x0) / (nx - 1)
        local dt = cfl * dx / math.abs(a)
        local nt = math.floor((t_end - t0) / dt) + 1
        dt = (t_end - t0) / (nt - 1)
        cfl = math.abs(a) * dt / dx
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local t = create_array(nt, 0)
        for i = 1, nx do
            x[i] = x0 + (i - 1) * dx
        end
        for n = 1, nt do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解矩阵
        local u = create_solution_matrix(nt, nx)
    
        -- 初始条件
        for i = 1, nx do
            u[1][i] = ic(x[i])
        end
    
        -- 时间步进
        for n = 1, nt - 1 do
            if scheme == "upwind" then
                -- 迎风格式（一阶精度）
                if a > 0 then
                    -- 波向右传播，使用左差分
                    for i = 2, nx do
                        u[n+1][i] = u[n][i] - cfl * (u[n][i] - u[n][i-1])
                    end
                    -- 左边界
                    if bc and bc.left then
                        u[n+1][1] = bc.left.value or ic(x0 - a * t[n+1])
                    end
                else
                    -- 波向左传播，使用右差分
                    for i = 1, nx - 1 do
                        u[n+1][i] = u[n][i] - cfl * (u[n][i+1] - u[n][i])
                    end
                    -- 右边界
                    if bc and bc.right then
                        u[n+1][nx] = bc.right.value or ic(x_end - a * t[n+1])
                    end
                end
    
            elseif scheme == "lax_friedrichs" then
                -- Lax-Friedrichs 格式（一阶精度，但有数值耗散）
                for i = 2, nx - 1 do
                    u[n+1][i] = 0.5 * (u[n][i+1] + u[n][i-1])
                              - 0.5 * cfl * (a / math.abs(a)) * (u[n][i+1] - u[n][i-1])
                end
                -- 边界
                u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
                u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]
    
            elseif scheme == "lax_wendroff" then
                -- Lax-Wendroff 格式（二阶精度）
                local sigma = a * dt / dx
                for i = 2, nx - 1 do
                    u[n+1][i] = u[n][i]
                              - 0.5 * sigma * (u[n][i+1] - u[n][i-1])
                              + 0.5 * sigma * sigma * (u[n][i+1] - 2*u[n][i] + u[n][i-1])
                end
                -- 边界
                u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
                u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]
    
            elseif scheme == "beam_warming" then
                -- Beam-Warming 格式（二阶迎风格式）
                if a > 0 then
                    for i = 3, nx do
                        local sigma = a * dt / dx
                        u[n+1][i] = u[n][i]
                                  - 0.5 * sigma * (3*u[n][i] - 4*u[n][i-1] + u[n][i-2])
                                  + 0.5 * sigma * sigma * (u[n][i] - 2*u[n][i-1] + u[n][i-2])
                    end
                    u[n+1][1] = bc and bc.left and bc.left.value or u[n][1]
                    u[n+1][2] = u[n][2]
                else
                    for i = 1, nx - 2 do
                        local sigma = a * dt / dx
                        u[n+1][i] = u[n][i]
                                  - 0.5 * sigma * (-3*u[n][i] + 4*u[n][i+1] - u[n][i+2])
                                  + 0.5 * sigma * sigma * (u[n][i] - 2*u[n][i+1] + u[n][i+2])
                    end
                    u[n+1][nx] = bc and bc.right and bc.right.value or u[n][nx]
                    u[n+1][nx-1] = u[n][nx-1]
                end
    
            else
                error("Unknown advection scheme: " .. scheme)
            end
        end
    
        return x, t, u
    end
    
    -- =============================================================================
    -- 二维波动方程求解器
    -- =============================================================================
    
    -- 显式有限差分方法求解二维波动方程
    -- ∂²u/∂t² = c² * (∂²u/∂x² + ∂²u/∂y²)
    -- @param c 波速
    -- @param ic_u 初始位移
    -- @param ic_v 初始速度
    -- @param bc 边界条件
    -- @param bounds 区域边界
    -- @param t_span 时间区间
    -- @param options: {nx, ny, cfl}
    function hyperbolic.wave2d(c, ic_u, ic_v, bc, bounds, t_span, options)
        -- 参数验证
        utils.typecheck.check_type("wave2d", "c", c, "number")
        utils.typecheck.check_type("wave2d", "ic_u", ic_u, "function")
        utils.typecheck.check_type("wave2d", "bounds", bounds, "table")
        utils.typecheck.check_type("wave2d", "t_span", t_span, "table")
    
        options = options or {}
        local nx = options.nx or 50
        local ny = options.ny or 50
        local cfl = options.cfl or 0.5  -- 二维情况下 CFL 需更小
    
        local ax, bx = bounds[1] or 0, bounds[2] or 1
        local ay, by = bounds[3] or 0, bounds[4] or 1
        local t0, t_end = t_span[1] or 0, t_span[2] or 1
    
        local dx = (bx - ax) / (nx - 1)
        local dy = (by - ay) / (ny - 1)
        local dt = cfl * math.min(dx, dy) / (c * math.sqrt(2))
        local nt = math.floor((t_end - t0) / dt) + 1
        dt = (t_end - t0) / (nt - 1)
    
        local rx2 = (c * dt / dx) ^ 2
        local ry2 = (c * dt / dy) ^ 2
    
        -- 创建坐标数组
        local x = create_array(nx, 0)
        local y = create_array(ny, 0)
        local t = create_array(nt, 0)
    
        for i = 1, nx do
            x[i] = ax + (i - 1) * dx
        end
        for j = 1, ny do
            y[j] = ay + (j - 1) * dy
        end
        for n = 1, nt do
            t[n] = t0 + (n - 1) * dt
        end
    
        -- 创建解网格
        local u = {}
        for n = 1, nt do
            u[n] = {}
            for i = 1, nx do
                u[n][i] = create_array(ny, 0)
            end
        end
    
        -- 初始条件
        for i = 1, nx do
            for j = 1, ny do
                u[1][i][j] = ic_u(x[i], y[j])
            end
        end
    
        -- 使用初始速度计算第二步
        if ic_v then
            for i = 2, nx - 1 do
                for j = 2, ny - 1 do
                    local u_xx = (u[1][i+1][j] - 2*u[1][i][j] + u[1][i-1][j]) / (dx * dx)
                    local u_yy = (u[1][i][j+1] - 2*u[1][i][j] + u[1][i][j-1]) / (dy * dy)
                    u[2][i][j] = u[1][i][j] + dt * ic_v(x[i], y[j])
                               + 0.5 * dt * dt * c * c * (u_xx + u_yy)
                end
            end
        else
            for i = 2, nx - 1 do
                for j = 2, ny - 1 do
                    u[2][i][j] = u[1][i][j]
                end
            end
        end
    
        -- 应用边界条件
        local function apply_bc(u_curr)
            if bc.left then
                for j = 1, ny do u_curr[1][j] = bc.left.value or 0 end
            end
            if bc.right then
                for j = 1, ny do u_curr[nx][j] = bc.right.value or 0 end
            end
            if bc.bottom then
                for i = 1, nx do u_curr[i][1] = bc.bottom.value or 0 end
            end
            if bc.top then
                for i = 1, nx do u_curr[i][ny] = bc.top.value or 0 end
            end
        end
    
        apply_bc(u[1])
        apply_bc(u[2])
    
        -- 时间步进
        for n = 2, nt - 1 do
            for i = 2, nx - 1 do
                for j = 2, ny - 1 do
                    u[n+1][i][j] = 2*u[n][i][j] - u[n-1][i][j]
                                 + rx2 * (u[n][i+1][j] - 2*u[n][i][j] + u[n][i-1][j])
                                 + ry2 * (u[n][i][j+1] - 2*u[n][i][j] + u[n][i][j-1])
                end
            end
            apply_bc(u[n+1])
        end
    
        return x, y, t, u
    end
    
    -- =============================================================================
    -- 别名
    -- =============================================================================
    
    hyperbolic.transport1d = hyperbolic.advection1d
    
    return hyperbolic
end

-- 模块: statistics.descriptive
_module_loaders["statistics.descriptive"] = function()
    -- 描述性统计函数
    local descriptive = {}
    
    local utils = require("utils.init")
    
    -----------------------------------------------------------------------------
    -- 辅助函数
    -----------------------------------------------------------------------------
    
    -- 检查输入是否为非空数组
    local function validate_array(x, name)
        name = name or "data"
        if type(x) ~= "table" then
            utils.Error.invalid_input(name .. " must be a table")
        end
        if #x == 0 then
            utils.Error.invalid_input(name .. " must not be empty")
        end
    end
    
    -- 复制并排序数组
    local function sorted_copy(x)
        local sorted = {}
        for i = 1, #x do
            sorted[i] = x[i]
        end
        table.sort(sorted)
        return sorted
    end
    
    -----------------------------------------------------------------------------
    -- 集中趋势度量
    -----------------------------------------------------------------------------
    
    -- 算术平均值
    function descriptive.mean(x)
        validate_array(x)
        local sum = 0
        for i = 1, #x do
            sum = sum + x[i]
        end
        return sum / #x
    end
    
    -- 中位数
    function descriptive.median(x)
        validate_array(x)
        local sorted = sorted_copy(x)
        local n = #sorted
        local mid = math.floor(n / 2)
    
        if n % 2 == 1 then
            return sorted[mid + 1]
        else
            return (sorted[mid] + sorted[mid + 1]) / 2
        end
    end
    
    -- 众数（返回出现次数最多的值，可能有多个）
    function descriptive.mode(x)
        validate_array(x)
    
        local counts = {}
        for i = 1, #x do
            local v = x[i]
            counts[v] = (counts[v] or 0) + 1
        end
    
        local max_count = 0
        local modes = {}
        for v, c in pairs(counts) do
            if c > max_count then
                max_count = c
                modes = {v}
            elseif c == max_count then
                modes[#modes + 1] = v
            end
        end
    
        -- 如果所有值出现次数相同，返回空（无众数）
        if max_count == 1 then
            return {}
        end
    
        table.sort(modes)
        return modes
    end
    
    -- 几何平均值
    function descriptive.geomean(x)
        validate_array(x)
    
        local log_sum = 0
        for i = 1, #x do
            if x[i] <= 0 then
                utils.Error.invalid_input("geometric mean requires positive values")
            end
            log_sum = log_sum + math.log(x[i])
        end
        return math.exp(log_sum / #x)
    end
    
    -- 调和平均值
    function descriptive.harmean(x)
        validate_array(x)
    
        local sum = 0
        for i = 1, #x do
            if x[i] == 0 then
                utils.Error.invalid_input("harmonic mean requires non-zero values")
            end
            sum = sum + 1 / x[i]
        end
        return #x / sum
    end
    
    -- 截尾均值（去除两端各 p 比例的数据后求均值）
    function descriptive.trimmean(x, p)
        validate_array(x)
        p = p or 0.1
        if p < 0 or p >= 0.5 then
            utils.Error.invalid_input("p must be in [0, 0.5)")
        end
    
        local sorted = sorted_copy(x)
        local n = #sorted
        local k = math.floor(n * p)
    
        if k * 2 >= n then
            return descriptive.mean(sorted)
        end
    
        local sum = 0
        for i = k + 1, n - k do
            sum = sum + sorted[i]
        end
        return sum / (n - 2 * k)
    end
    
    -----------------------------------------------------------------------------
    -- 离散程度度量
    -----------------------------------------------------------------------------
    
    -- 方差（样本方差，无偏估计，自由度 n-1）
    function descriptive.var(x)
        validate_array(x)
        if #x < 2 then
            return 0
        end
    
        local m = descriptive.mean(x)
        local sum = 0
        for i = 1, #x do
            sum = sum + (x[i] - m) ^ 2
        end
        return sum / (#x - 1)
    end
    
    -- 标准差（样本标准差）
    function descriptive.std(x)
        return math.sqrt(descriptive.var(x))
    end
    
    -- 总体方差（自由度 n）
    function descriptive.var_pop(x)
        validate_array(x)
    
        local m = descriptive.mean(x)
        local sum = 0
        for i = 1, #x do
            sum = sum + (x[i] - m) ^ 2
        end
        return sum / #x
    end
    
    -- 总体标准差
    function descriptive.std_pop(x)
        return math.sqrt(descriptive.var_pop(x))
    end
    
    -- 极差
    function descriptive.range(x)
        validate_array(x)
    
        local min_val, max_val = x[1], x[1]
        for i = 2, #x do
            if x[i] < min_val then min_val = x[i] end
            if x[i] > max_val then max_val = x[i] end
        end
        return max_val - min_val
    end
    
    -- 四分位距 (IQR = Q3 - Q1)
    function descriptive.iqr(x)
        local q1, q3 = descriptive.quartile(x)
        return q3 - q1
    end
    
    -- 平均绝对偏差 (MAD)
    function descriptive.mad(x)
        validate_array(x)
    
        local m = descriptive.mean(x)
        local sum = 0
        for i = 1, #x do
            sum = sum + math.abs(x[i] - m)
        end
        return sum / #x
    end
    
    -- 标准误 (SEM)
    function descriptive.sem(x)
        validate_array(x)
        if #x < 2 then
            return 0
        end
        return descriptive.std(x) / math.sqrt(#x)
    end
    
    -----------------------------------------------------------------------------
    -- 分位数
    -----------------------------------------------------------------------------
    
    -- 百分位数 (p: 0-100)
    function descriptive.percentile(x, p)
        validate_array(x)
        if p < 0 or p > 100 then
            utils.Error.invalid_input("percentile must be in [0, 100]")
        end
    
        local sorted = sorted_copy(x)
        local n = #sorted
    
        -- 使用线性插值方法
        local rank = (p / 100) * (n - 1) + 1
        local lower = math.floor(rank)
        local upper = math.ceil(rank)
    
        if lower == upper then
            return sorted[lower]
        end
    
        local frac = rank - lower
        return sorted[lower] + frac * (sorted[upper] - sorted[lower])
    end
    
    -- 四分位数，返回 Q1, Q3
    function descriptive.quartile(x)
        local q1 = descriptive.percentile(x, 25)
        local q3 = descriptive.percentile(x, 75)
        return q1, q3
    end
    
    -- 分位数（通用版本，p 为 0-1 的比例）
    function descriptive.quantile(x, p)
        return descriptive.percentile(x, p * 100)
    end
    
    -----------------------------------------------------------------------------
    -- 分布形状度量
    -----------------------------------------------------------------------------
    
    -- n 阶中心矩
    function descriptive.moment(x, n, center)
        validate_array(x)
        n = n or 2
        center = center or descriptive.mean(x)
    
        local sum = 0
        for i = 1, #x do
            sum = sum + (x[i] - center) ^ n
        end
        return sum / #x
    end
    
    -- 偏度（skewness）
    -- 正偏：右尾较长；负偏：左尾较长
    function descriptive.skewness(x)
        validate_array(x)
        if #x < 3 then
            return 0
        end
    
        local n = #x
        local m = descriptive.mean(x)
        local s = descriptive.std_pop(x)
    
        if s == 0 then return 0 end
    
        local sum3 = 0
        for i = 1, n do
            sum3 = sum3 + ((x[i] - m) / s) ^ 3
        end
    
        -- 样本偏度校正
        return sum3 * n / ((n - 1) * (n - 2))
    end
    
    -- 峰度（kurtosis）
    -- 正态分布峰度为 0（超额峰度）
    function descriptive.kurtosis(x)
        validate_array(x)
        if #x < 4 then
            return 0
        end
    
        local n = #x
        local m = descriptive.mean(x)
        local s = descriptive.std_pop(x)
    
        if s == 0 then return 0 end
    
        local sum4 = 0
        for i = 1, n do
            sum4 = sum4 + ((x[i] - m) / s) ^ 4
        end
    
        -- 样本超额峰度校正
        local g2 = (sum4 * n * (n + 1) / ((n - 1) * (n - 2) * (n - 3)))
                 - (3 * (n - 1) ^ 2 / ((n - 2) * (n - 3)))
        return g2
    end
    
    -----------------------------------------------------------------------------
    -- 频数统计
    -----------------------------------------------------------------------------
    
    -- 直方图
    -- 返回各区间计数和区间边界
    function descriptive.histogram(x, bins)
        validate_array(x)
        bins = bins or 10
    
        local min_val, max_val = x[1], x[1]
        for i = 2, #x do
            if x[i] < min_val then min_val = x[i] end
            if x[i] > max_val then max_val = x[i] end
        end
    
        -- 处理所有值相同的情况
        if min_val == max_val then
            local counts = {}
            for i = 1, bins do
                counts[i] = 0
            end
            counts[1] = #x
            local edges = {}
            for i = 0, bins do
                edges[i + 1] = min_val + (i / bins)
            end
            return counts, edges
        end
    
        local width = (max_val - min_val) / bins
        local counts = {}
        local edges = {}
    
        for i = 0, bins do
            edges[i + 1] = min_val + i * width
        end
    
        for i = 1, bins do
            counts[i] = 0
        end
    
        for i = 1, #x do
            local idx = math.floor((x[i] - min_val) / width) + 1
            if idx > bins then idx = bins end
            if idx < 1 then idx = 1 end
            counts[idx] = counts[idx] + 1
        end
    
        return counts, edges
    end
    
    -- 频数统计
    function descriptive.frequency(x)
        validate_array(x)
    
        local freq = {}
        for i = 1, #x do
            local v = x[i]
            freq[v] = (freq[v] or 0) + 1
        end
        return freq
    end
    
    -----------------------------------------------------------------------------
    -- 综合描述
    -----------------------------------------------------------------------------
    
    -- 生成描述性统计摘要
    function descriptive.describe(x)
        validate_array(x)
    
        local sorted = sorted_copy(x)
        local q1, q3 = descriptive.quartile(x)
    
        return {
            n = #x,
            min = sorted[1],
            max = sorted[#sorted],
            range = descriptive.range(x),
            mean = descriptive.mean(x),
            std = descriptive.std(x),
            var = descriptive.var(x),
            median = descriptive.median(x),
            q1 = q1,
            q3 = q3,
            iqr = q3 - q1,
            skewness = descriptive.skewness(x),
            kurtosis = descriptive.kurtosis(x),
            sem = descriptive.sem(x)
        }
    end
    
    return descriptive
end

-- 模块: statistics.correlation
_module_loaders["statistics.correlation"] = function()
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
end

-- 模块: statistics.distributions
_module_loaders["statistics.distributions"] = function()
    -- 概率分布模块
    -- 提供离散和连续概率分布的 PDF、CDF、分位数函数和随机采样
    local distributions = {}
    
    local utils = require("utils.init")
    
    -----------------------------------------------------------------------------
    -- 数学辅助函数
    -----------------------------------------------------------------------------
    
    -- 阶乘（使用对数避免溢出）
    local function log_factorial(n)
        if n <= 1 then return 0 end
        local result = 0
        for i = 2, n do
            result = result + math.log(i)
        end
        return result
    end
    
    -- 组合数 C(n, k) 的对数
    local function log_choose(n, k)
        if k < 0 or k > n then return -math.huge end
        if k == 0 or k == n then return 0 end
        return log_factorial(n) - log_factorial(k) - log_factorial(n - k)
    end
    
    -- 组合数 C(n, k)
    local function choose(n, k)
        return math.exp(log_choose(n, k))
    end
    
    -- Gamma 函数（使用 Lanczos 近似）
    local function gamma(z)
        if z <= 0 then
            utils.Error.invalid_input("gamma function requires positive argument")
        end
    
        -- Lanczos 系数
        local g = 7
        local coef = {
            0.99999999999980993,
            676.5203681218851,
            -1259.1392167224028,
            771.32342877765313,
            -176.61502916214059,
            12.507343278686905,
            -0.13857109526572012,
            9.9843695780195716e-6,
            1.5056327351493116e-7
        }
    
        if z < 0.5 then
            -- 反射公式
            return math.pi / (math.sin(math.pi * z) * gamma(1 - z))
        end
    
        z = z - 1
        local x = coef[1]
        for i = 1, g + 1 do
            x = x + coef[i + 1] / (z + i)
        end
    
        local t = z + g + 0.5
        return math.sqrt(2 * math.pi) * t^(z + 0.5) * math.exp(-t) * x
    end
    
    -- 对数 Gamma 函数
    local function log_gamma(z)
        if z <= 0 then
            utils.Error.invalid_input("log_gamma requires positive argument")
        end
        return math.log(gamma(z))
    end
    
    -- Beta 函数
    local function beta(a, b)
        return gamma(a) * gamma(b) / gamma(a + b)
    end
    
    -- 不完全 Gamma 函数（下不完全 Gamma）
    local function gamma_lower(a, x)
        if x < 0 then return 0 end
        if x == 0 then return 0 end
    
        -- 使用级数展开
        local max_iter = 200
        local eps = 1e-12
    
        local sum = 1.0 / a
        local term = sum
        for n = 1, max_iter do
            term = term * x / (a + n)
            sum = sum + term
            if math.abs(term) < math.abs(sum) * eps then
                break
            end
        end
    
        return sum * math.exp(-x + a * math.log(x) - log_gamma(a + 1))
    end
    
    -- 正则化的不完全 Gamma 函数 P(a, x)
    local function gamma_p(a, x)
        if x < 0 then return 0 end
        if x == 0 then return 0 end
        if x > a + 1 then
            -- 使用 gamma_q 的补数
            return 1 - gamma_lower(a, x) / gamma(a) * math.exp(-x + a * math.log(x) - log_gamma(a))
        end
        return gamma_lower(a, x) / gamma(a)
    end
    
    -- 不完全 Beta 函数
    local function beta_incomplete(a, b, x)
        if x <= 0 then return 0 end
        if x >= 1 then return 1 end
    
        -- 使用连分数展开
        local max_iter = 200
        local eps = 1e-12
    
        local qab = a + b
        local qap = a + 1
        local qam = a - 1
        local c = 1.0
        local d = 1.0 - qab * x / qap
    
        if math.abs(d) < 1e-30 then d = 1e-30 end
        d = 1.0 / d
        local h = d
    
        for m = 1, max_iter do
            local m2 = 2 * m
            local aa = m * (b - m) * x / ((qam + m2) * (a + m2))
            d = 1.0 + aa * d
            if math.abs(d) < 1e-30 then d = 1e-30 end
            c = 1.0 + aa / c
            if math.abs(c) < 1e-30 then c = 1e-30 end
            d = 1.0 / d
            h = h * d * c
            aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
            d = 1.0 + aa * d
            if math.abs(d) < 1e-30 then d = 1e-30 end
            c = 1.0 + aa / c
            if math.abs(c) < 1e-30 then c = 1e-30 end
            d = 1.0 / d
            local delta = d * c
            h = h * delta
            if math.abs(delta - 1.0) < eps then
                break
            end
        end
    
        return h * math.exp(a * math.log(x) + b * math.log(1 - x) - log_gamma(a) - log_gamma(b) + log_gamma(a + b)) / a
    end
    
    -- 误差函数 erf (使用更高精度的近似)
    local function erf(x)
        if x == 0 then return 0 end
    
        local sign = 1
        if x < 0 then sign = -1; x = -x end
    
        -- 使用 Winitzki 近似 (更精确)
        -- erf(x) ≈ sign(x) * sqrt(1 - exp(-x² * (4/π + a*x²) / (1 + a*x²)))
        local a = 0.147
        local x2 = x * x
        local term = x2 * (4 / math.pi + a * x2) / (1 + a * x2)
        local result = math.sqrt(1 - math.exp(-term))
    
        -- 对于较大的 x，使用渐近展开修正
        if x > 3 then
            -- 渐近展开
            local t = math.exp(-x2) / (math.sqrt(math.pi) * x)
            result = 1 - t * (1 - 1/(2*x2) + 3/(4*x2*x2))
        end
    
        return sign * result
    end
    
    -- 逆误差函数 erfinv
    local function erfinv(x)
        if x <= -1 or x >= 1 then
            utils.Error.invalid_input("erfinv argument must be in (-1, 1)")
        end
    
        if x == 0 then return 0 end
    
        -- 使用有理近似
        local sign = 1
        if x < 0 then sign = -1; x = -x end
    
        local a = 0.147
        local ln = math.log(1 - x * x)
        local t1 = 2 / (math.pi * a) + ln / 2
        local t2 = ln / a
    
        local result = math.sqrt(math.sqrt(t1 * t1 - t2) - t1)
        return sign * result
    end
    
    -- 随机数生成器状态（简单 LCG）
    local rand_state = os.time()
    local function rand()
        rand_state = (rand_state * 1103515245 + 12345) % 2147483648
        return rand_state / 2147483648
    end
    
    -- 设置随机种子
    function distributions.seed(s)
        rand_state = s or os.time()
    end
    
    -----------------------------------------------------------------------------
    -- 连续分布
    -----------------------------------------------------------------------------
    
    --- 正态分布 (高斯分布)
    -- μ: 均值，σ: 标准差
    distributions.normal = {}
    
    function distributions.normal.pdf(x, mu, sigma)
        mu = mu or 0
        sigma = sigma or 1
        if sigma <= 0 then
            utils.Error.invalid_input("sigma must be positive")
        end
        local z = (x - mu) / sigma
        return math.exp(-0.5 * z * z) / (sigma * math.sqrt(2 * math.pi))
    end
    
    function distributions.normal.cdf(x, mu, sigma)
        mu = mu or 0
        sigma = sigma or 1
        if sigma <= 0 then
            utils.Error.invalid_input("sigma must be positive")
        end
        local z = (x - mu) / sigma
        return 0.5 * (1 + erf(z / math.sqrt(2)))
    end
    
    function distributions.normal.quantile(p, mu, sigma)
        mu = mu or 0
        sigma = sigma or 1
        if sigma <= 0 then
            utils.Error.invalid_input("sigma must be positive")
        end
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
        return mu + sigma * math.sqrt(2) * erfinv(2 * p - 1)
    end
    
    function distributions.normal.sample(n, mu, sigma)
        mu = mu or 0
        sigma = sigma or 1
        n = n or 1
        local result = {}
        for i = 1, n do
            -- Box-Muller 变换
            local u1, u2 = rand(), rand()
            local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
            result[i] = mu + sigma * z
        end
        return result
    end
    
    --- 均匀分布
    distributions.uniform = {}
    
    function distributions.uniform.pdf(x, a, b)
        a = a or 0
        b = b or 1
        if b <= a then
            utils.Error.invalid_input("b must be greater than a")
        end
        if x < a or x > b then return 0 end
        return 1 / (b - a)
    end
    
    function distributions.uniform.cdf(x, a, b)
        a = a or 0
        b = b or 1
        if b <= a then
            utils.Error.invalid_input("b must be greater than a")
        end
        if x <= a then return 0 end
        if x >= b then return 1 end
        return (x - a) / (b - a)
    end
    
    function distributions.uniform.quantile(p, a, b)
        a = a or 0
        b = b or 1
        if b <= a then
            utils.Error.invalid_input("b must be greater than a")
        end
        if p < 0 or p > 1 then
            utils.Error.invalid_input("p must be in [0, 1]")
        end
        return a + p * (b - a)
    end
    
    function distributions.uniform.sample(n, a, b)
        a = a or 0
        b = b or 1
        n = n or 1
        local result = {}
        for i = 1, n do
            result[i] = a + rand() * (b - a)
        end
        return result
    end
    
    --- 指数分布
    distributions.exponential = {}
    
    function distributions.exponential.pdf(x, lambda)
        lambda = lambda or 1
        if lambda <= 0 then
            utils.Error.invalid_input("lambda must be positive")
        end
        if x < 0 then return 0 end
        return lambda * math.exp(-lambda * x)
    end
    
    function distributions.exponential.cdf(x, lambda)
        lambda = lambda or 1
        if lambda <= 0 then
            utils.Error.invalid_input("lambda must be positive")
        end
        if x <= 0 then return 0 end
        return 1 - math.exp(-lambda * x)
    end
    
    function distributions.exponential.quantile(p, lambda)
        lambda = lambda or 1
        if lambda <= 0 then
            utils.Error.invalid_input("lambda must be positive")
        end
        if p < 0 or p >= 1 then
            utils.Error.invalid_input("p must be in [0, 1)")
        end
        if p == 0 then return 0 end
        return -math.log(1 - p) / lambda
    end
    
    function distributions.exponential.sample(n, lambda)
        lambda = lambda or 1
        n = n or 1
        local result = {}
        for i = 1, n do
            result[i] = -math.log(1 - rand()) / lambda
        end
        return result
    end
    
    --- t 分布
    distributions.t = {}
    
    function distributions.t.pdf(x, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        local coef = gamma((df + 1) / 2) / (math.sqrt(df * math.pi) * gamma(df / 2))
        return coef * (1 + x * x / df)^(-(df + 1) / 2)
    end
    
    function distributions.t.cdf(x, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        -- 使用正则化不完全 Beta 函数
        if x == 0 then return 0.5 end
        local sign = 1
        if x < 0 then sign = -1; x = -x end
    
        local a = df / 2
        local b = 0.5
        local t = df / (df + x * x)
        local p = 1 - 0.5 * beta_incomplete(a, b, t)
    
        if sign > 0 then
            return p
        else
            return 1 - p
        end
    end
    
    function distributions.t.quantile(p, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
    
        -- 使用牛顿法求解
        local x = distributions.normal.quantile(p)  -- 初始猜测
    
        for i = 1, 50 do
            local cdf_val = distributions.t.cdf(x, df)
            local pdf_val = distributions.t.pdf(x, df)
            if pdf_val == 0 then break end
    
            local delta = (cdf_val - p) / pdf_val
            x = x - delta
    
            if math.abs(delta) < 1e-12 then break end
        end
    
        return x
    end
    
    function distributions.t.sample(n, df)
        n = n or 1
        -- 使用正态和卡方分布采样
        local z = distributions.normal.sample(n)
        local chi2 = distributions.chi2.sample(n, df)
    
        local result = {}
        for i = 1, n do
            result[i] = z[i] * math.sqrt(df / chi2[i])
        end
        return result
    end
    
    --- 卡方分布
    distributions.chi2 = {}
    
    function distributions.chi2.pdf(x, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if x <= 0 then return 0 end
    
        local k = df / 2
        local coef = 1 / (2^k * gamma(k))
        return coef * x^(k - 1) * math.exp(-x / 2)
    end
    
    function distributions.chi2.cdf(x, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if x <= 0 then return 0 end
        return gamma_p(df / 2, x / 2)
    end
    
    function distributions.chi2.quantile(p, df)
        if df <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
    
        -- 使用牛顿法
        local x = df  -- 初始猜测
    
        for i = 1, 50 do
            local cdf_val = distributions.chi2.cdf(x, df)
            local pdf_val = distributions.chi2.pdf(x, df)
            if pdf_val == 0 then break end
    
            local delta = (cdf_val - p) / pdf_val
            x = x - delta
    
            if math.abs(delta) < 1e-12 then break end
        end
    
        return x
    end
    
    function distributions.chi2.sample(n, df)
        n = n or 1
        -- 使用 Gamma 分布采样
        return distributions.gamma.sample(n, df / 2, 2)
    end
    
    --- F 分布
    distributions.f = {}
    
    function distributions.f.pdf(x, df1, df2)
        if df1 <= 0 or df2 <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if x <= 0 then return 0 end
    
        local coef = gamma((df1 + df2) / 2) / (gamma(df1 / 2) * gamma(df2 / 2))
        coef = coef * (df1 / df2)^(df1 / 2) * x^(df1 / 2 - 1)
        local denom = (1 + (df1 / df2) * x)^((df1 + df2) / 2)
        return coef / denom
    end
    
    function distributions.f.cdf(x, df1, df2)
        if df1 <= 0 or df2 <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if x <= 0 then return 0 end
    
        -- 使用 Beta 分布
        local t = df1 * x / (df1 * x + df2)
        return beta_incomplete(df1 / 2, df2 / 2, t)
    end
    
    function distributions.f.quantile(p, df1, df2)
        if df1 <= 0 or df2 <= 0 then
            utils.Error.invalid_input("degrees of freedom must be positive")
        end
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
    
        -- 使用牛顿法
        local x = 1  -- 初始猜测
    
        for i = 1, 50 do
            local cdf_val = distributions.f.cdf(x, df1, df2)
            local pdf_val = distributions.f.pdf(x, df1, df2)
            if pdf_val == 0 then break end
    
            local delta = (cdf_val - p) / pdf_val
            x = x - delta
    
            if x <= 0 then x = 0.001 end
            if math.abs(delta) < 1e-12 then break end
        end
    
        return x
    end
    
    function distributions.f.sample(n, df1, df2)
        n = n or 1
        local chi2_1 = distributions.chi2.sample(n, df1)
        local chi2_2 = distributions.chi2.sample(n, df2)
    
        local result = {}
        for i = 1, n do
            result[i] = (chi2_1[i] / df1) / (chi2_2[i] / df2)
        end
        return result
    end
    
    --- Gamma 分布
    distributions.gamma = {}
    
    function distributions.gamma.pdf(x, shape, scale)
        shape = shape or 1
        scale = scale or 1
        if shape <= 0 or scale <= 0 then
            utils.Error.invalid_input("shape and scale must be positive")
        end
        if x <= 0 then return 0 end
    
        local coef = 1 / (scale^shape * gamma(shape))
        return coef * x^(shape - 1) * math.exp(-x / scale)
    end
    
    function distributions.gamma.cdf(x, shape, scale)
        shape = shape or 1
        scale = scale or 1
        if shape <= 0 or scale <= 0 then
            utils.Error.invalid_input("shape and scale must be positive")
        end
        if x <= 0 then return 0 end
        return gamma_p(shape, x / scale)
    end
    
    function distributions.gamma.quantile(p, shape, scale)
        shape = shape or 1
        scale = scale or 1
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
    
        -- 使用牛顿法
        local x = shape * scale  -- 初始猜测
    
        for i = 1, 50 do
            local cdf_val = distributions.gamma.cdf(x, shape, scale)
            local pdf_val = distributions.gamma.pdf(x, shape, scale)
            if pdf_val == 0 then break end
    
            local delta = (cdf_val - p) / pdf_val
            x = x - delta
    
            if x <= 0 then x = 0.001 end
            if math.abs(delta) < 1e-12 then break end
        end
    
        return x
    end
    
    function distributions.gamma.sample(n, shape, scale)
        shape = shape or 1
        scale = scale or 1
        n = n or 1
    
        local result = {}
        for i = 1, n do
            if shape >= 1 then
                -- Marsaglia and Tsang 方法
                local d = shape - 1/3
                local c = 1 / math.sqrt(9 * d)
    
                while true do
                    local z = distributions.normal.sample(1)[1]
                    local v = (1 + c * z) ^ 3
    
                    if v > 0 then
                        local u = rand()
                        if u < 1 - 0.0331 * (z * z) * (z * z) then
                            result[i] = d * v * scale
                            break
                        end
                        if math.log(u) < 0.5 * z * z + d * (1 - v + math.log(v)) then
                            result[i] = d * v * scale
                            break
                        end
                    end
                end
            else
                -- Ahrens-Dieter 方法 (shape < 1)
                local b = (math.exp(1) + shape) / math.exp(1)
                while true do
                    local p = b * rand()
                    if p <= 1 then
                        local y = p^(1 / shape)
                        if rand() <= math.exp(-y) then
                            result[i] = y * scale
                            break
                        end
                    else
                        local y = -math.log((b - p) / shape)
                        if rand() <= y^(shape - 1) then
                            result[i] = y * scale
                            break
                        end
                    end
                end
            end
        end
        return result
    end
    
    --- Beta 分布
    distributions.beta = {}
    
    function distributions.beta.pdf(x, alpha, beta_param)
        beta_param = beta_param or 1
        if alpha <= 0 or beta_param <= 0 then
            utils.Error.invalid_input("alpha and beta must be positive")
        end
        if x <= 0 or x >= 1 then return 0 end
    
        local b = gamma(alpha) * gamma(beta_param) / gamma(alpha + beta_param)
        return x^(alpha - 1) * (1 - x)^(beta_param - 1) / b
    end
    
    function distributions.beta.cdf(x, alpha, beta_param)
        beta_param = beta_param or 1
        if alpha <= 0 or beta_param <= 0 then
            utils.Error.invalid_input("alpha and beta must be positive")
        end
        if x <= 0 then return 0 end
        if x >= 1 then return 1 end
        return beta_incomplete(alpha, beta_param, x)
    end
    
    function distributions.beta.quantile(p, alpha, beta_param)
        beta_param = beta_param or 1
        if alpha <= 0 or beta_param <= 0 then
            utils.Error.invalid_input("alpha and beta must be positive")
        end
        if p <= 0 or p >= 1 then
            utils.Error.invalid_input("p must be in (0, 1)")
        end
    
        -- 使用牛顿法
        local x = 0.5  -- 初始猜测
    
        for i = 1, 50 do
            local cdf_val = distributions.beta.cdf(x, alpha, beta_param)
            local pdf_val = distributions.beta.pdf(x, alpha, beta_param)
            if pdf_val == 0 then break end
    
            local delta = (cdf_val - p) / pdf_val
            x = x - delta
    
            if x <= 0 then x = 0.001 end
            if x >= 1 then x = 0.999 end
            if math.abs(delta) < 1e-12 then break end
        end
    
        return x
    end
    
    function distributions.beta.sample(n, alpha, beta_param)
        beta_param = beta_param or 1
        n = n or 1
    
        -- 使用两个 Gamma 分布
        local g1 = distributions.gamma.sample(n, alpha, 1)
        local g2 = distributions.gamma.sample(n, beta_param, 1)
    
        local result = {}
        for i = 1, n do
            result[i] = g1[i] / (g1[i] + g2[i])
        end
        return result
    end
    
    -----------------------------------------------------------------------------
    -- 离散分布
    -----------------------------------------------------------------------------
    
    --- 伯努利分布
    distributions.bernoulli = {}
    
    function distributions.bernoulli.pmf(k, p)
        if p < 0 or p > 1 then
            utils.Error.invalid_input("p must be in [0, 1]")
        end
        if k == 0 then return 1 - p end
        if k == 1 then return p end
        return 0
    end
    
    function distributions.bernoulli.cdf(k, p)
        if p < 0 or p > 1 then
            utils.Error.invalid_input("p must be in [0, 1]")
        end
        if k < 0 then return 0 end
        if k < 1 then return 1 - p end
        return 1
    end
    
    function distributions.bernoulli.sample(n, p)
        n = n or 1
        local result = {}
        for i = 1, n do
            result[i] = rand() < p and 1 or 0
        end
        return result
    end
    
    --- 二项分布
    distributions.binomial = {}
    
    function distributions.binomial.pmf(k, n, p)
        if n < 0 or k < 0 or k > n then
            return 0
        end
        if p < 0 or p > 1 then
            utils.Error.invalid_input("p must be in [0, 1]")
        end
        if n ~= math.floor(n) or k ~= math.floor(k) then
            return 0
        end
        return choose(n, k) * p^k * (1 - p)^(n - k)
    end
    
    function distributions.binomial.cdf(k, n, p)
        if k < 0 then return 0 end
        if k >= n then return 1 end
        if p < 0 or p > 1 then
            utils.Error.invalid_input("p must be in [0, 1]")
        end
    
        local sum = 0
        for i = 0, math.min(math.floor(k), n) do
            sum = sum + distributions.binomial.pmf(i, n, p)
        end
        return sum
    end
    
    function distributions.binomial.sample(num_samples, n, p)
        num_samples = num_samples or 1
        local result = {}
        for i = 1, num_samples do
            local count = 0
            for j = 1, n do
                if rand() < p then
                    count = count + 1
                end
            end
            result[i] = count
        end
        return result
    end
    
    --- 泊松分布
    distributions.poisson = {}
    
    function distributions.poisson.pmf(k, lambda)
        if lambda <= 0 then
            utils.Error.invalid_input("lambda must be positive")
        end
        if k < 0 or k ~= math.floor(k) then
            return 0
        end
        return math.exp(-lambda + k * math.log(lambda) - log_factorial(k))
    end
    
    function distributions.poisson.cdf(k, lambda)
        if lambda <= 0 then
            utils.Error.invalid_input("lambda must be positive")
        end
        if k < 0 then return 0 end
        k = math.floor(k)
    
        local sum = 0
        for i = 0, k do
            sum = sum + distributions.poisson.pmf(i, lambda)
        end
        return sum
    end
    
    function distributions.poisson.sample(n, lambda)
        lambda = lambda or 1
        n = n or 1
    
        local result = {}
        for i = 1, n do
            -- Knuth 算法
            local L = math.exp(-lambda)
            local k = 0
            local p = 1
    
            repeat
                k = k + 1
                p = p * rand()
            until p <= L
    
            result[i] = k - 1
        end
        return result
    end
    
    --- 几何分布
    distributions.geometric = {}
    
    function distributions.geometric.pmf(k, p)
        if p <= 0 or p > 1 then
            utils.Error.invalid_input("p must be in (0, 1]")
        end
        if k < 1 or k ~= math.floor(k) then
            return 0
        end
        return (1 - p)^(k - 1) * p
    end
    
    function distributions.geometric.cdf(k, p)
        if p <= 0 or p > 1 then
            utils.Error.invalid_input("p must be in (0, 1]")
        end
        if k < 1 then return 0 end
        return 1 - (1 - p)^math.floor(k)
    end
    
    function distributions.geometric.sample(n, p)
        n = n or 1
        local result = {}
        for i = 1, n do
            result[i] = math.ceil(math.log(1 - rand()) / math.log(1 - p))
        end
        return result
    end
    
    -----------------------------------------------------------------------------
    -- 导出辅助函数
    -----------------------------------------------------------------------------
    
    distributions.gamma_func = gamma
    distributions.beta_func = beta
    distributions.erf = erf
    distributions.erfinv = erfinv
    
    return distributions
end

-- 模块: statistics.hypothesis
_module_loaders["statistics.hypothesis"] = function()
    -- 假设检验模块
    local hypothesis = {}
    
    local utils = require("utils.init")
    local descriptive = require("statistics.descriptive")
    local distributions = require("statistics.distributions")
    
    -----------------------------------------------------------------------------
    -- 辅助函数
    -----------------------------------------------------------------------------
    
    
    -- 计算合并标准误差
    local function pooled_std(x, y)
        local n1, n2 = #x, #y
        local v1 = descriptive.var(x)
        local v2 = descriptive.var(y)
    
        -- 合并方差
        local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
        return math.sqrt(pooled_var)
    end
    
    -----------------------------------------------------------------------------
    
    
    -- 单样本 t 检验
    -- 检验样本均值是否与假设值有显著差异
    -- @param x 样本数据
    -- @param mu 假设的总体均值
    -- @param alternative 备择假设类型: "two.sided", "less", "greater"
    -- @return t_statistic, p_value, df
    function hypothesis.t_test_one_sample(x, mu, alternative)
        if type(x) ~= "table" or #x < 2 then
            utils.Error.invalid_input("x must be a table with at least 2 elements")
        end
    
        mu = mu or 0
        alternative = alternative or "two.sided"
    
        local n = #x
        local sample_mean = descriptive.mean(x)
        local sample_std = descriptive.std(x)
    
        -- t 统计量
        local se = sample_std / math.sqrt(n)
        local t_stat = (sample_mean - mu) / se
    
        -- 自由度
        local df = n - 1
    
        -- 计算 p 值
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
        elseif alternative == "less" then
            p_value = distributions.t.cdf(t_stat, df)
        elseif alternative == "greater" then
            p_value = 1 - distributions.t.cdf(t_stat, df)
        else
            utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
        end
    
        return t_stat, p_value, df
    end
    
    -- 双样本 t 检验（等方差）
    -- @param x 第一个样本
    -- @param y 第二个样本
    -- @param mu 差值的假设值（默认为0）
    -- @param alternative 备择假设类型
    -- @param paired 是否为配对样本
    -- @return t_statistic, p_value, df
    function hypothesis.t_test_two_sample(x, y, mu, alternative, paired)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("samples must have at least 2 elements")
        end
    
        mu = mu or 0
        alternative = alternative or "two.sided"
        paired = paired or false
    
        local t_stat, df, p_value
    
        if paired then
            -- 配对样本 t 检验
            if #x ~= #y then
                utils.Error.dimension_mismatch(#x, #y, "paired samples must have equal length")
            end
    
            local n = #x
            local diff = {}
            for i = 1, n do
                diff[i] = x[i] - y[i]
            end
    
            return hypothesis.t_test_one_sample(diff, mu, alternative)
        else
            -- 独立样本 t 检验
            local n1, n2 = #x, #y
            local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
            local v1, v2 = descriptive.var(x), descriptive.var(y)
    
            -- 使用合并方差（假设等方差）
            local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
            local se = math.sqrt(pooled_var * (1/n1 + 1/n2))
    
            t_stat = ((mean1 - mean2) - mu) / se
            df = n1 + n2 - 2
    
            -- 计算 p 值
            if alternative == "two.sided" then
                p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
            elseif alternative == "less" then
                p_value = distributions.t.cdf(t_stat, df)
            elseif alternative == "greater" then
                p_value = 1 - distributions.t.cdf(t_stat, df)
            else
                utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
            end
        end
    
        return t_stat, p_value, df
    end
    
    -- Welch's t 检验（异方差）
    -- @param x 第一个样本
    -- @param y 第二个样本
    -- @param mu 差值的假设值
    -- @param alternative 备择假设类型
    -- @return t_statistic, p_value, df
    function hypothesis.welch_test(x, y, mu, alternative)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("samples must have at least 2 elements")
        end
    
        mu = mu or 0
        alternative = alternative or "two.sided"
    
        local n1, n2 = #x, #y
        local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
        local v1, v2 = descriptive.var(x), descriptive.var(y)
    
        -- Welch's t 统计量
        local se = math.sqrt(v1/n1 + v2/n2)
        local t_stat = ((mean1 - mean2) - mu) / se
    
        -- Welch-Satterthwaite 自由度
        local num = (v1/n1 + v2/n2)^2
        local den = (v1/n1)^2 / (n1 - 1) + (v2/n2)^2 / (n2 - 1)
        local df = num / den
    
        -- 计算 p 值
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.t.cdf(math.abs(t_stat), df))
        elseif alternative == "less" then
            p_value = distributions.t.cdf(t_stat, df)
        elseif alternative == "greater" then
            p_value = 1 - distributions.t.cdf(t_stat, df)
        else
            utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
        end
    
        return t_stat, p_value, df
    end
    
    -----------------------------------------------------------------------------
    
    
    -- 单样本 Z 检验（需要已知总体标准差）
    -- @param x 样本数据
    -- @param mu 假设的总体均值
    -- @param sigma 已知的总体标准差
    -- @param alternative 备择假设类型
    -- @return z_statistic, p_value
    function hypothesis.z_test_one_sample(x, mu, sigma, alternative)
        if type(x) ~= "table" or #x < 1 then
            utils.Error.invalid_input("x must be a non-empty table")
        end
        if not sigma or sigma <= 0 then
            utils.Error.invalid_input("sigma must be a positive number")
        end
    
        mu = mu or 0
        alternative = alternative or "two.sided"
    
        local n = #x
        local sample_mean = descriptive.mean(x)
    
        -- Z 统计量
        local se = sigma / math.sqrt(n)
        local z_stat = (sample_mean - mu) / se
    
        -- 计算 p 值（使用标准正态分布）
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.normal.cdf(math.abs(z_stat)))
        elseif alternative == "less" then
            p_value = distributions.normal.cdf(z_stat)
        elseif alternative == "greater" then
            p_value = 1 - distributions.normal.cdf(z_stat)
        else
            utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
        end
    
        return z_stat, p_value
    end
    
    -----------------------------------------------------------------------------
    
    
    -- F 检验（方差齐性检验）
    -- 检验两个总体方差是否相等
    -- @param x 第一个样本
    -- @param y 第二个样本
    -- @param alternative 备择假设类型
    -- @return f_statistic, p_value, df1, df2
    function hypothesis.var_test(x, y, alternative)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("samples must have at least 2 elements")
        end
    
        alternative = alternative or "two.sided"
    
        local n1, n2 = #x, #y
        local v1, v2 = descriptive.var(x), descriptive.var(y)
    
        -- F 统计量（较大的方差作为分子）
        local f_stat, df1, df2
        if alternative == "two.sided" then
            -- 双侧检验：总是把较大的方差放在分子
            if v1 >= v2 then
                f_stat = v1 / v2
                df1, df2 = n1 - 1, n2 - 1
            else
                f_stat = v2 / v1
                df1, df2 = n2 - 1, n1 - 1
            end
        else
            f_stat = v1 / v2
            df1, df2 = n1 - 1, n2 - 1
        end
    
        -- 计算 p 值
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.f.cdf(f_stat, df1, df2))
            if p_value > 1 then p_value = 2 - p_value end  -- 确保不超过1
        elseif alternative == "less" then
            p_value = distributions.f.cdf(f_stat, df1, df2)
        elseif alternative == "greater" then
            p_value = 1 - distributions.f.cdf(f_stat, df1, df2)
        else
            utils.Error.invalid_input("alternative must be 'two.sided', 'less', or 'greater'")
        end
    
        return f_stat, p_value, df1, df2
    end
    
    -----------------------------------------------------------------------------
    
    
    -- 卡方拟合优度检验
    -- 检验观测频数是否符合期望频数
    -- @param observed 观测频数数组
    -- @param expected 期望频数数组（可选，默认为等概率）
    -- @param p 期望概率数组（可选）
    -- @return chi2_statistic, p_value, df
    function hypothesis.chisq_test_goodness(observed, expected, p)
        if type(observed) ~= "table" or #observed < 2 then
            utils.Error.invalid_input("observed must be a table with at least 2 elements")
        end
    
        local n = #observed
        local total = 0
        for i = 1, n do
            if observed[i] < 0 then
                utils.Error.invalid_input("observed frequencies must be non-negative")
            end
            total = total + observed[i]
        end
    
        if total == 0 then
            utils.Error.invalid_input("sum of observed frequencies must be positive")
        end
    
        -- 计算期望频数
        if not expected then
            if p then
                -- 使用给定的概率
                expected = {}
                for i = 1, n do
                    expected[i] = total * p[i]
                end
            else
                -- 默认等概率
                expected = {}
                for i = 1, n do
                    expected[i] = total / n
                end
            end
        end
    
        -- 计算卡方统计量
        local chi2_stat = 0
        for i = 1, n do
            if expected[i] > 0 then
                local diff = observed[i] - expected[i]
                chi2_stat = chi2_stat + (diff * diff) / expected[i]
            end
        end
    
        -- 自由度
        local df = n - 1
        if p then
            df = n - 1  -- 如果概率已知
        end
    
        -- 计算 p 值
        local p_value = 1 - distributions.chi2.cdf(chi2_stat, df)
    
        return chi2_stat, p_value, df
    end
    
    -- 卡方独立性检验（列联表）
    -- @param observed 观测频数矩阵（二维数组）
    -- @return chi2_statistic, p_value, df
    function hypothesis.chisq_test_independence(observed)
        if type(observed) ~= "table" or #observed < 2 then
            utils.Error.invalid_input("observed must be a 2D table with at least 2 rows")
        end
    
        local rows = #observed
        local cols = #observed[1]
    
        if cols < 2 then
            utils.Error.invalid_input("observed must have at least 2 columns")
        end
    
        -- 计算行和、列和、总和
        local row_sums = {}
        local col_sums = {}
        local total = 0
    
        for i = 1, rows do
            row_sums[i] = 0
            for j = 1, cols do
                if observed[i][j] < 0 then
                    utils.Error.invalid_input("observed frequencies must be non-negative")
                end
                row_sums[i] = row_sums[i] + observed[i][j]
                total = total + observed[i][j]
            end
        end
    
        for j = 1, cols do
            col_sums[j] = 0
            for i = 1, rows do
                col_sums[j] = col_sums[j] + observed[i][j]
            end
        end
    
        if total == 0 then
            utils.Error.invalid_input("sum of observed frequencies must be positive")
        end
    
        -- 计算期望频数和卡方统计量
        local chi2_stat = 0
        for i = 1, rows do
            for j = 1, cols do
                local expected = row_sums[i] * col_sums[j] / total
                if expected > 0 then
                    local diff = observed[i][j] - expected
                    chi2_stat = chi2_stat + (diff * diff) / expected
                end
            end
        end
    
        -- 自由度 = (r-1)(c-1)
        local df = (rows - 1) * (cols - 1)
    
        -- 计算 p 值
        local p_value = 1 - distributions.chi2.cdf(chi2_stat, df)
    
        return chi2_stat, p_value, df
    end
    
    -----------------------------------------------------------------------------
    
    
    -- Wilcoxon 符号秩检验（单样本/配对样本）
    -- @param x 样本数据（单样本）或差值（配对样本）
    -- @param mu 假设的中位数/差值
    -- @param alternative 备择假设类型
    -- @return w_statistic, p_value
    function hypothesis.wilcoxon_signed_rank(x, mu, alternative)
        if type(x) ~= "table" or #x < 2 then
            utils.Error.invalid_input("x must be a table with at least 2 elements")
        end
    
        mu = mu or 0
        alternative = alternative or "two.sided"
    
        local n = #x
    
        -- 计算差值
        local diff = {}
        for i = 1, n do
            diff[i] = x[i] - mu
        end
    
        -- 去除零值
        local non_zero = {}
        for i = 1, n do
            if diff[i] ~= 0 then
                table.insert(non_zero, {value = diff[i], abs_val = math.abs(diff[i])})
            end
        end
    
        local n1 = #non_zero
        if n1 == 0 then
            return 0, 1  -- 所有点都等于 mu
        end
    
        -- 按绝对值排序
        table.sort(non_zero, function(a, b) return a.abs_val < b.abs_val end)
    
        -- 分配秩
        local ranks = {}
        local i = 1
        while i <= n1 do
            local j = i
            while j < n1 and non_zero[j + 1].abs_val == non_zero[i].abs_val do
                j = j + 1
            end
    
            local avg_rank = (i + j) / 2
            for k = i, j do
                ranks[k] = avg_rank
            end
            i = j + 1
        end
    
        -- 计算正秩和与负秩和
        local w_plus = 0
        local w_minus = 0
        for k = 1, n1 do
            if non_zero[k].value > 0 then
                w_plus = w_plus + ranks[k]
            else
                w_minus = w_minus + ranks[k]
            end
        end
    
        -- W 统计量（取较小的）
        local w_stat
        if alternative == "two.sided" then
            w_stat = math.min(w_plus, w_minus)
        elseif alternative == "less" then
            w_stat = w_plus
        else
            w_stat = w_minus
        end
    
        -- 正态近似计算 p 值（n > 20 时更准确）
        local mean_w = n1 * (n1 + 1) / 4
        local var_w = n1 * (n1 + 1) * (2 * n1 + 1) / 24
        local se = math.sqrt(var_w)
    
        -- 连续性修正
        local z
        if alternative == "two.sided" then
            z = (w_stat + 0.5 - mean_w) / se
            if z < 0 then z = -z end
            -- 使用较小的 W，所以 p 值需要调整
            z = math.abs(w_plus - w_minus) / (2 * se)
        else
            z = (w_stat - mean_w) / se
        end
    
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * (1 - distributions.normal.cdf(math.abs(z)))
        elseif alternative == "less" then
            p_value = distributions.normal.cdf(z)
        else
            p_value = 1 - distributions.normal.cdf(z)
        end
    
        return w_stat, p_value
    end
    
    -----------------------------------------------------------------------------
    
    
    -- Mann-Whitney U 检验（Wilcoxon 秩和检验）
    -- @param x 第一个样本
    -- @param y 第二个样本
    -- @param alternative 备择假设类型
    -- @return u_statistic, p_value
    function hypothesis.mann_whitney_u(x, y, alternative)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 1 or #y < 1 then
            utils.Error.invalid_input("samples must have at least 1 element")
        end
    
        alternative = alternative or "two.sided"
    
        local n1, n2 = #x, #y
    
        -- 合并并排序
        local combined = {}
        for i = 1, n1 do
            table.insert(combined, {value = x[i], group = 1})
        end
        for i = 1, n2 do
            table.insert(combined, {value = y[i], group = 2})
        end
    
        table.sort(combined, function(a, b) return a.value < b.value end)
    
        -- 分配秩（处理结值）
        local n = n1 + n2
        local i = 1
        while i <= n do
            local j = i
            while j < n and combined[j + 1].value == combined[i].value do
                j = j + 1
            end
    
            local avg_rank = (i + j) / 2
            for k = i, j do
                combined[k].rank = avg_rank
            end
            i = j + 1
        end
    
        -- 计算秩和
        local r1, r2 = 0, 0
        for k = 1, n do
            if combined[k].group == 1 then
                r1 = r1 + combined[k].rank
            else
                r2 = r2 + combined[k].rank
            end
        end
    
        -- 计算 U 统计量
        local u1 = r1 - n1 * (n1 + 1) / 2
        local u2 = r2 - n2 * (n2 + 1) / 2
    
        local u_stat
        if alternative == "two.sided" then
            u_stat = math.min(u1, u2)
        elseif alternative == "less" then
            u_stat = u1
        else
            u_stat = u2
        end
    
        -- 正态近似
        local mean_u = n1 * n2 / 2
        local var_u = n1 * n2 * (n1 + n2 + 1) / 12
        local se = math.sqrt(var_u)
    
        local z
        if alternative == "two.sided" then
            z = (u_stat + 0.5 - mean_u) / se
            if z > 0 then z = -z end
        else
            z = (u_stat - mean_u) / se
        end
    
        local p_value
        if alternative == "two.sided" then
            p_value = 2 * distributions.normal.cdf(z)
        elseif alternative == "less" then
            p_value = distributions.normal.cdf(z)
        else
            p_value = 1 - distributions.normal.cdf(z)
        end
    
        return u_stat, p_value
    end
    
    -----------------------------------------------------------------------------
    
    
    -- 置信区间计算
    -- 单样本均值的置信区间
    function hypothesis.ci_mean(x, level)
        if type(x) ~= "table" or #x < 2 then
            utils.Error.invalid_input("x must be a table with at least 2 elements")
        end
    
        level = level or 0.95
    
        local n = #x
        local mean = descriptive.mean(x)
        local se = descriptive.std(x) / math.sqrt(n)
        local df = n - 1
    
        local alpha = 1 - level
        local t_crit = distributions.t.quantile(1 - alpha/2, df)
    
        local margin = t_crit * se
        return mean - margin, mean + margin
    end
    
    -- 两样本均值差的置信区间
    function hypothesis.ci_mean_diff(x, y, level, pooled)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("samples must have at least 2 elements")
        end
    
        level = level or 0.95
        pooled = pooled or true
    
        local n1, n2 = #x, #y
        local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
        local v1, v2 = descriptive.var(x), descriptive.var(y)
    
        local diff = mean1 - mean2
        local se, df
    
        if pooled then
            local pooled_var = ((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2)
            se = math.sqrt(pooled_var * (1/n1 + 1/n2))
            df = n1 + n2 - 2
        else
            -- Welch's
            se = math.sqrt(v1/n1 + v2/n2)
            local num = (v1/n1 + v2/n2)^2
            local den = (v1/n1)^2 / (n1 - 1) + (v2/n2)^2 / (n2 - 1)
            df = num / den
        end
    
        local alpha = 1 - level
        local t_crit = distributions.t.quantile(1 - alpha/2, df)
    
        local margin = t_crit * se
        return diff - margin, diff + margin
    end
    
    -- 比例的置信区间
    function hypothesis.ci_proportion(count, n, level)
        if count < 0 or n <= 0 or count > n then
            utils.Error.invalid_input("invalid count and n values")
        end
    
        level = level or 0.95
    
        local p = count / n
        local alpha = 1 - level
        local z_crit = distributions.normal.quantile(1 - alpha/2)
    
        -- Wilson score interval
        local denominator = 1 + z_crit^2 / n
        local center = (p + z_crit^2 / (2*n)) / denominator
        local margin = z_crit * math.sqrt(p*(1-p)/n + z_crit^2/(4*n*n)) / denominator
    
        return math.max(0, center - margin), math.min(1, center + margin)
    end
    
    -----------------------------------------------------------------------------
    
    
    -- 效应量计算
    
    -- Cohen's d（单样本）
    function hypothesis.cohens_d_one_sample(x, mu)
        mu = mu or 0
        local mean = descriptive.mean(x)
        local sd = descriptive.std(x)
        return (mean - mu) / sd
    end
    
    -- Cohen's d（双样本）
    function hypothesis.cohens_d_two_sample(x, y, pooled)
        pooled = pooled or true
    
        local mean1, mean2 = descriptive.mean(x), descriptive.mean(y)
        local diff = mean1 - mean2
    
        if pooled then
            local n1, n2 = #x, #y
            local v1, v2 = descriptive.var(x), descriptive.var(y)
            local pooled_sd = math.sqrt(((n1-1)*v1 + (n2-1)*v2) / (n1+n2-2))
            return diff / pooled_sd
        else
            -- 使用对照组标准差
            return diff / descriptive.std(y)
        end
    end
    
    -- 点二列相关（作为效应量）
    function hypothesis.point_biserial(x, y)
        -- x 是二分变量（0/1），y 是连续变量
        local n = #x
        local n1, n2 = 0, 0
        local sum1, sum2 = 0, 0
    
        for i = 1, n do
            if x[i] == 0 then
                n1 = n1 + 1
                sum1 = sum1 + y[i]
            else
                n2 = n2 + 1
                sum2 = sum2 + y[i]
            end
        end
    
        local mean1 = sum1 / n1
        local mean2 = sum2 / n2
        local mean_y = descriptive.mean(y)
        local sd_y = descriptive.std(y)
    
        return (mean2 - mean1) / sd_y * math.sqrt(n1 * n2 / n^2)
    end
    
    return hypothesis
end

-- 模块: statistics.regression
_module_loaders["statistics.regression"] = function()
    -- 回归分析模块
    local regression = {}
    
    local utils = require("utils.init")
    local descriptive = require("statistics.descriptive")
    local distributions = require("statistics.distributions")
    local hypothesis = require("statistics.hypothesis")
    
    -----------------------------------------------------------------------------
    -- 辅助函数
    -----------------------------------------------------------------------------
    
    -- 构建设计矩阵（包含截距项）
    local function build_design_matrix(x, add_intercept)
        if add_intercept == nil then add_intercept = true end
        local n
        local p  -- 预测变量数
    
        if type(x[1]) == "table" then
            -- 多元回归：x 是二维数组
            n = #x
            p = #x[1]
            if add_intercept then
                p = p + 1
            end
        else
            -- 简单回归：x 是一维数组
            n = #x
            p = add_intercept and 2 or 1
        end
    
        local X = {}
        for i = 1, n do
            X[i] = {}
            local col = 1
            if add_intercept then
                X[i][col] = 1
                col = col + 1
            end
            if type(x[1]) == "table" then
                for j = 1, #x[i] do
                    X[i][col] = x[i][j]
                    col = col + 1
                end
            else
                X[i][col] = x[i]
            end
        end
    
        return X, n, p
    end
    
    -- 矩阵转置
    local function transpose(A)
        local m, n = #A, #A[1]
        local B = {}
        for j = 1, n do
            B[j] = {}
            for i = 1, m do
                B[j][i] = A[i][j]
            end
        end
        return B
    end
    
    -- 矩阵乘法
    local function matmul(A, B)
        local m, n, p = #A, #A[1], #B[1]
        local C = {}
        for i = 1, m do
            C[i] = {}
            for j = 1, p do
                local sum = 0
                for k = 1, n do
                    sum = sum + A[i][k] * B[k][j]
                end
                C[i][j] = sum
            end
        end
        return C
    end
    
    -- 矩阵求逆（高斯-约旦消元法）
    local function inverse(A)
        local n = #A
        -- 创建增广矩阵 [A | I]
        local aug = {}
        for i = 1, n do
            aug[i] = {}
            for j = 1, n do
                aug[i][j] = A[i][j]
            end
            for j = 1, n do
                aug[i][n + j] = (i == j) and 1 or 0
            end
        end
    
        -- 高斯-约旦消元
        for col = 1, n do
            -- 找主元
            local max_row = col
            for row = col + 1, n do
                if math.abs(aug[row][col]) > math.abs(aug[max_row][col]) then
                    max_row = row
                end
            end
    
            -- 交换行
            aug[col], aug[max_row] = aug[max_row], aug[col]
    
            -- 检查奇异性
            if math.abs(aug[col][col]) < 1e-12 then
                utils.Error.invalid_input("Matrix is singular or nearly singular")
            end
    
            -- 归一化主元行
            local pivot = aug[col][col]
            for j = 1, 2 * n do
                aug[col][j] = aug[col][j] / pivot
            end
    
            -- 消去其他行
            for row = 1, n do
                if row ~= col then
                    local factor = aug[row][col]
                    for j = 1, 2 * n do
                        aug[row][j] = aug[row][j] - factor * aug[col][j]
                    end
                end
            end
        end
    
        -- 提取逆矩阵
        local inv = {}
        for i = 1, n do
            inv[i] = {}
            for j = 1, n do
                inv[i][j] = aug[i][n + j]
            end
        end
    
        return inv
    end
    
    -----------------------------------------------------------------------------
    -- 线性回归
    -----------------------------------------------------------------------------
    
    -- 简单线性回归
    -- @param x 自变量
    -- @param y 因变量
    -- @return result 表，包含系数、R²、标准误等
    function regression.linear(x, y)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x ~= #y then
            utils.Error.dimension_mismatch(#x, #y)
        end
        if #x < 2 then
            utils.Error.invalid_input("need at least 2 data points")
        end
    
        local n = #x
        local mean_x = descriptive.mean(x)
        local mean_y = descriptive.mean(y)
    
        -- 计算 Sxx, Syy, Sxy
        local Sxx, Syy, Sxy = 0, 0, 0
        for i = 1, n do
            local dx = x[i] - mean_x
            local dy = y[i] - mean_y
            Sxx = Sxx + dx * dx
            Syy = Syy + dy * dy
            Sxy = Sxy + dx * dy
        end
    
        -- 回归系数
        local slope = Sxy / Sxx
        local intercept = mean_y - slope * mean_x
    
        -- 预测值和残差
        local y_pred = {}
        local residuals = {}
        local SSR, SSE = 0, 0  -- 回归平方和，残差平方和
        for i = 1, n do
            y_pred[i] = intercept + slope * x[i]
            residuals[i] = y[i] - y_pred[i]
            SSE = SSE + residuals[i] * residuals[i]
            SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
        end
    
        -- R²
        local SST = SSR + SSE
        local R2 = SSR / SST
        local R2_adj = 1 - (1 - R2) * (n - 1) / (n - 2)
    
        -- 标准误
        local MSE = SSE / (n - 2)
        local se_slope = math.sqrt(MSE / Sxx)
        local se_intercept = math.sqrt(MSE * (1/n + mean_x * mean_x / Sxx))
    
        -- t 检验
        local t_slope = slope / se_slope
        local t_intercept = intercept / se_intercept
        local p_slope = 2 * (1 - distributions.t.cdf(math.abs(t_slope), n - 2))
        local p_intercept = 2 * (1 - distributions.t.cdf(math.abs(t_intercept), n - 2))
    
        -- F 检验
        local F_stat = (SSR / 1) / MSE
        local p_F = 1 - distributions.f.cdf(F_stat, 1, n - 2)
    
        -- 标准误（残差标准误）
        local s = math.sqrt(MSE)
    
        -- 协方差矩阵
        local cov_matrix = {
            {MSE * (1/n + mean_x * mean_x / Sxx), -mean_x * MSE / Sxx},
            {-mean_x * MSE / Sxx, MSE / Sxx}
        }
    
        return {
            intercept = intercept,
            slope = slope,
            coefficients = {intercept, slope},
            R2 = R2,
            R2_adj = R2_adj,
            MSE = MSE,
            RMSE = math.sqrt(MSE),
            SSR = SSR,
            SSE = SSE,
            SST = SST,
            F = F_stat,
            p_F = p_F,
            se = {se_intercept, se_slope},
            t = {t_intercept, t_slope},
            p = {p_intercept, p_slope},
            residuals = residuals,
            fitted = y_pred,
            n = n,
            df = n - 2,
            s = s,
            cov_matrix = cov_matrix
        }
    end
    
    -- 多元线性回归
    -- @param X 设计矩阵（二维数组，每行一个观测，每列一个变量）
    -- @param y 因变量
    -- @param add_intercept 是否添加截距项（默认true）
    -- @return result 表
    function regression.multiple(X, y, add_intercept)
        if type(X) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("X and y must be tables")
        end
        if #X ~= #y then
            utils.Error.dimension_mismatch(#X, #y)
        end
    
        if add_intercept == nil then add_intercept = true end
        local n = #X
        local design, _, p = build_design_matrix(X, add_intercept)
    
        if n < p then
            utils.Error.invalid_input("not enough observations for the number of predictors")
        end
    
        -- 最小二乘法: beta = (X'X)^(-1) X'y
        local Xt = transpose(design)
        local XtX = matmul(Xt, design)
    
        local ok, XtX_inv = pcall(inverse, XtX)
        if not ok then
            utils.Error.invalid_input("cannot invert X'X matrix: " .. tostring(XtX_inv))
        end
    
        -- 将 y 转换为列向量
        local y_col = {}
        for i = 1, n do
            y_col[i] = {y[i]}
        end
    
        local Xty = matmul(Xt, y_col)
        local beta_col = matmul(XtX_inv, Xty)
    
        -- 提取系数
        local coefficients = {}
        for i = 1, p do
            coefficients[i] = beta_col[i][1]
        end
    
        -- 预测值和残差
        local y_pred = {}
        local residuals = {}
        for i = 1, n do
            local pred = 0
            for j = 1, p do
                pred = pred + design[i][j] * coefficients[j]
            end
            y_pred[i] = pred
            residuals[i] = y[i] - pred
        end
    
        -- 统计量
        local mean_y = descriptive.mean(y)
        local SSR, SSE = 0, 0
        for i = 1, n do
            SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
            SSE = SSE + residuals[i] * residuals[i]
        end
    
        local SST = SSR + SSE
        local R2 = SSR / SST
        local R2_adj = 1 - (1 - R2) * (n - 1) / (n - p)
    
        local MSE = SSE / (n - p)
        local RMSE = math.sqrt(MSE)
    
        -- F 检验
        local F_stat = (SSR / (p - 1)) / MSE
        local p_F = 1 - distributions.f.cdf(F_stat, p - 1, n - p)
    
        -- 系数的标准误和 t 检验
        local se = {}
        local t_values = {}
        local p_values = {}
        for j = 1, p do
            se[j] = math.sqrt(MSE * XtX_inv[j][j])
            t_values[j] = coefficients[j] / se[j]
            p_values[j] = 2 * (1 - distributions.t.cdf(math.abs(t_values[j]), n - p))
        end
    
        -- 协方差矩阵
        local cov_matrix = {}
        for i = 1, p do
            cov_matrix[i] = {}
            for j = 1, p do
                cov_matrix[i][j] = MSE * XtX_inv[i][j]
            end
        end
    
        return {
            coefficients = coefficients,
            intercept = add_intercept and coefficients[1] or nil,
            R2 = R2,
            R2_adj = R2_adj,
            MSE = MSE,
            RMSE = RMSE,
            SSR = SSR,
            SSE = SSE,
            SST = SST,
            F = F_stat,
            p_F = p_F,
            se = se,
            t = t_values,
            p = p_values,
            residuals = residuals,
            fitted = y_pred,
            n = n,
            df = n - p,
            p_predictors = p,
            cov_matrix = cov_matrix
        }
    end
    
    -----------------------------------------------------------------------------
    -- 多项式回归
    -----------------------------------------------------------------------------
    
    -- 多项式回归
    -- @param x 自变量
    -- @param y 因变量
    -- @param degree 多项式阶数（默认2）
    -- @return result 表
    function regression.polynomial(x, y, degree)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x ~= #y then
            utils.Error.dimension_mismatch(#x, #y)
        end
    
        degree = degree or 2
        local n = #x
    
        if degree < 1 then
            utils.Error.invalid_input("degree must be at least 1")
        end
        if n <= degree + 1 then
            utils.Error.invalid_input("need more data points than degree + 1")
        end
    
        -- 构建设计矩阵
        local X = {}
        for i = 1, n do
            X[i] = {}
            X[i][1] = 1  -- 截距
            for d = 1, degree do
                X[i][d + 1] = x[i] ^ d
            end
        end
    
        local p = degree + 1
    
        -- 最小二乘法
        local Xt = transpose(X)
        local XtX = matmul(Xt, X)
        local XtX_inv = inverse(XtX)
    
        local y_col = {}
        for i = 1, n do
            y_col[i] = {y[i]}
        end
    
        local Xty = matmul(Xt, y_col)
        local beta_col = matmul(XtX_inv, Xty)
    
        local coefficients = {}
        for i = 1, p do
            coefficients[i] = beta_col[i][1]
        end
    
        -- 预测值和残差
        local y_pred = {}
        local residuals = {}
        for i = 1, n do
            y_pred[i] = 0
            for j = 1, p do
                y_pred[i] = y_pred[i] + X[i][j] * coefficients[j]
            end
            residuals[i] = y[i] - y_pred[i]
        end
    
        -- 统计量
        local mean_y = descriptive.mean(y)
        local SSR, SSE = 0, 0
        for i = 1, n do
            SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
            SSE = SSE + residuals[i] * residuals[i]
        end
    
        local SST = SSR + SSE
        local R2 = SSR / SST
        local R2_adj = 1 - (1 - R2) * (n - 1) / (n - p)
    
        local MSE = SSE / (n - p)
        local RMSE = math.sqrt(MSE)
    
        local F_stat = (SSR / degree) / MSE
        local p_F = 1 - distributions.f.cdf(F_stat, degree, n - p)
    
        -- 系数的标准误和 t 检验
        local se = {}
        local t_values = {}
        local p_values = {}
        for j = 1, p do
            se[j] = math.sqrt(MSE * XtX_inv[j][j])
            t_values[j] = coefficients[j] / se[j]
            p_values[j] = 2 * (1 - distributions.t.cdf(math.abs(t_values[j]), n - p))
        end
    
        return {
            coefficients = coefficients,
            intercept = coefficients[1],
            degree = degree,
            R2 = R2,
            R2_adj = R2_adj,
            MSE = MSE,
            RMSE = RMSE,
            SSR = SSR,
            SSE = SSE,
            SST = SST,
            F = F_stat,
            p_F = p_F,
            se = se,
            t = t_values,
            p = p_values,
            residuals = residuals,
            fitted = y_pred,
            n = n,
            df = n - p
        }
    end
    
    -----------------------------------------------------------------------------
    -- 预测和诊断
    -----------------------------------------------------------------------------
    
    -- 使用回归模型预测
    -- @param model 回归结果
    -- @param x_new 新数据（简单/多项式回归为1D数组，多元回归为2D数组）
    -- @return 预测值数组
    function regression.predict(model, x_new)
        if not model or not model.coefficients then
            utils.Error.invalid_input("invalid model")
        end
    
        local coef = model.coefficients
        local p = #coef
        local predictions = {}
    
        if type(x_new[1]) == "table" then
            -- 多元回归预测
            for i = 1, #x_new do
                local pred = coef[1]  -- 截距
                for j = 1, #x_new[i] do
                    pred = pred + coef[j + 1] * x_new[i][j]
                end
                table.insert(predictions, pred)
            end
        else
            -- 简单回归或多项式回归
            if model.degree then
                -- 多项式回归
                for i = 1, #x_new do
                    local pred = 0
                    for d = 0, model.degree do
                        pred = pred + coef[d + 1] * (x_new[i] ^ d)
                    end
                    table.insert(predictions, pred)
                end
            else
                -- 简单线性回归
                for i = 1, #x_new do
                    table.insert(predictions, coef[1] + coef[2] * x_new[i])
                end
            end
        end
    
        return predictions
    end
    
    -- 计算预测区间
    -- @param model 回归结果
    -- @param x_new 新数据点
    -- @param level 置信水平（默认0.95）
    -- @return lower, upper 置信区间
    function regression.predict_interval(model, x_new, level)
        level = level or 0.95
        local predictions = regression.predict(model, {x_new})
        local pred = predictions[1]
    
        local alpha = 1 - level
        local t_crit = distributions.t.quantile(1 - alpha/2, model.df)
    
        -- 预测标准误
        local rmse = model.RMSE or model.s or math.sqrt(model.MSE)
        local margin = t_crit * rmse
        return pred - margin, pred + margin
    end
    
    -- 计算置信区间（均值的置信区间）
    function regression.confidence_interval(model, x_new, level)
        level = level or 0.95
        local predictions = regression.predict(model, {x_new})
        local pred = predictions[1]
    
        local alpha = 1 - level
        local t_crit = distributions.t.quantile(1 - alpha/2, model.df)
    
        -- 均值的标准误（简化）
        local se_mean = model.RMSE / math.sqrt(model.n)
        local margin = t_crit * se_mean
    
        return pred - margin, pred + margin
    end
    
    -----------------------------------------------------------------------------
    -- 模型诊断
    -----------------------------------------------------------------------------
    
    -- 计算残差诊断指标
    function regression.diagnostics(model, y)
        local residuals = model.residuals
        local n = #residuals
    
        -- 标准化残差
        local std_residuals = {}
        local rmse = model.RMSE or model.s or math.sqrt(model.MSE)
        for i = 1, n do
            std_residuals[i] = residuals[i] / rmse
        end
    
        -- 学生化残差
        local student_residuals = {}
        local p_pred = model.p_predictors or 2  -- 简单回归默认为2个参数
        local h_bar = p_pred / n  -- 平均杠杆值（近似）
        for i = 1, n do
            local h_i = h_bar  -- 简化处理
            student_residuals[i] = residuals[i] / (rmse * math.sqrt(1 - h_i))
        end
    
        -- 残差统计
        local res_mean = descriptive.mean(residuals)
        local res_std = descriptive.std(residuals)
        local res_skew = descriptive.skewness(residuals)
        local res_kurt = descriptive.kurtosis(residuals)
    
        -- Durbin-Watson 统计量（自相关检验）
        local dw_num, dw_den = 0, 0
        for i = 1, n do
            dw_den = dw_den + residuals[i] * residuals[i]
        end
        for i = 2, n do
            dw_num = dw_num + (residuals[i] - residuals[i-1]) * (residuals[i] - residuals[i-1])
        end
        local DW = dw_den > 0 and dw_num / dw_den or 0
    
        return {
            std_residuals = std_residuals,
            student_residuals = student_residuals,
            residual_mean = res_mean,
            residual_std = res_std,
            residual_skewness = res_skew,
            residual_kurtosis = res_kurt,
            durbin_watson = DW
        }
    end
    
    -- 方差分析表
    function regression.anova(model)
        local df_reg = model.p_predictors and (model.p_predictors - 1) or 1
        local df_res = model.df
        local df_total = model.n - 1
    
        local MS_reg = model.SSR / df_reg
        local MS_res = model.SSE / df_res
    
        return {
            {
                source = "Regression",
                SS = model.SSR,
                df = df_reg,
                MS = MS_reg,
                F = model.F,
                p = model.p_F
            },
            {
                source = "Residual",
                SS = model.SSE,
                df = df_res,
                MS = MS_res,
                F = nil,
                p = nil
            },
            {
                source = "Total",
                SS = model.SST,
                df = df_total,
                MS = nil,
                F = nil,
                p = nil
            }
        }
    end
    
    -----------------------------------------------------------------------------
    -- 其他回归方法
    -----------------------------------------------------------------------------
    
    -- 加权最小二乘法
    function regression.wls(x, y, weights)
        if type(x) ~= "table" or type(y) ~= "table" or type(weights) ~= "table" then
            utils.Error.invalid_input("x, y, and weights must be tables")
        end
        if #x ~= #y or #x ~= #weights then
            utils.Error.dimension_mismatch("x, y, and weights must have the same length")
        end
    
        local n = #x
        local sum_w = 0
        local sum_wx = 0
        local sum_wy = 0
        local sum_wxx = 0
        local sum_wxy = 0
    
        for i = 1, n do
            local w = weights[i]
            sum_w = sum_w + w
            sum_wx = sum_wx + w * x[i]
            sum_wy = sum_wy + w * y[i]
            sum_wxx = sum_wxx + w * x[i] * x[i]
            sum_wxy = sum_wxy + w * x[i] * y[i]
        end
    
        local denom = sum_w * sum_wxx - sum_wx * sum_wx
        local slope = (sum_w * sum_wxy - sum_wx * sum_wy) / denom
        local intercept = (sum_wy * sum_wxx - sum_wx * sum_wxy) / denom
    
        -- 计算残差和统计量
        local y_pred = {}
        local residuals = {}
        local SSE = 0
        local mean_y = descriptive.mean(y)
    
        for i = 1, n do
            y_pred[i] = intercept + slope * x[i]
            residuals[i] = y[i] - y_pred[i]
            SSE = SSE + weights[i] * residuals[i] * residuals[i]
        end
    
        local SSR = 0
        for i = 1, n do
            SSR = SSR + weights[i] * (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
        end
    
        local SST = SSR + SSE
        local R2 = SSR / SST
    
        return {
            intercept = intercept,
            slope = slope,
            coefficients = {intercept, slope},
            R2 = R2,
            MSE = SSE / (n - 2),
            residuals = residuals,
            fitted = y_pred,
            n = n,
            weights = weights
        }
    end
    
    -- 岭回归（Ridge Regression）
    -- @param X 设计矩阵（2D数组）
    -- @param y 因变量
    -- @param lambda 正则化参数
    -- @param add_intercept 是否添加截距项
    -- @return result 表
    function regression.ridge(X, y, lambda, add_intercept)
        if type(X) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("X and y must be tables")
        end
    
        lambda = lambda or 1.0
        if add_intercept == nil then add_intercept = true end
    
        local design, n, p = build_design_matrix(X, add_intercept)
    
        -- 岭回归: beta = (X'X + lambda*I)^(-1) X'y
        local Xt = transpose(design)
        local XtX = matmul(Xt, design)
    
        -- 添加正则化项（不对截距惩罚）
        local start_idx = add_intercept and 2 or 1
        for i = start_idx, p do
            XtX[i][i] = XtX[i][i] + lambda
        end
    
        local XtX_inv = inverse(XtX)
    
        local y_col = {}
        for i = 1, n do
            y_col[i] = {y[i]}
        end
    
        local Xty = matmul(Xt, y_col)
        local beta_col = matmul(XtX_inv, Xty)
    
        local coefficients = {}
        for i = 1, p do
            coefficients[i] = beta_col[i][1]
        end
    
        -- 预测值
        local y_pred = {}
        local residuals = {}
        for i = 1, n do
            local pred = 0
            for j = 1, p do
                pred = pred + design[i][j] * coefficients[j]
            end
            y_pred[i] = pred
            residuals[i] = y[i] - pred
        end
    
        -- R²
        local mean_y = descriptive.mean(y)
        local SSR, SSE = 0, 0
        for i = 1, n do
            SSR = SSR + (y_pred[i] - mean_y) * (y_pred[i] - mean_y)
            SSE = SSE + residuals[i] * residuals[i]
        end
        local SST = SSR + SSE
        local R2 = SSR / SST
    
        return {
            coefficients = coefficients,
            intercept = add_intercept and coefficients[1] or nil,
            lambda = lambda,
            R2 = R2,
            MSE = SSE / (n - p),
            residuals = residuals,
            fitted = y_pred,
            n = n,
            p_predictors = p
        }
    end
    
    -- 打印回归摘要
    function regression.summary(model)
        print("=" .. string.rep("=", 50))
        print("Regression Summary")
        print("=" .. string.rep("=", 50))
    
        print(string.format("\nObservations: %d", model.n))
        print(string.format("Predictors: %d", model.p_predictors or 2))
        print(string.format("Degrees of Freedom: %d", model.df))
    
        print("\nCoefficients:")
        print(string.format("%-12s %10s %10s %10s %10s", "", "Estimate", "Std.Err", "t-value", "p-value"))
        print(string.rep("-", 55))
    
        local coef_names = {"Intercept", "X1", "X2", "X3", "X4", "X5"}
        for i = 1, #model.coefficients do
            local name = coef_names[i] or ("X" .. i)
            if model.se then
                print(string.format("%-12s %10.4f %10.4f %10.4f %10.4f",
                    name, model.coefficients[i], model.se[i], model.t[i], model.p[i]))
            else
                print(string.format("%-12s %10.4f", name, model.coefficients[i]))
            end
        end
    
        print("\nModel Fit:")
        print(string.format("  R²:          %.4f", model.R2))
        print(string.format("  Adj. R²:     %.4f", model.R2_adj or model.R2))
        print(string.format("  RMSE:        %.4f", model.RMSE or math.sqrt(model.MSE)))
    
        if model.F then
            print(string.format("\nF-statistic: %.4f (p = %.4f)", model.F, model.p_F))
        end
    
        print("=" .. string.rep("=", 50))
    end
    
    return regression
end

-- 模块: statistics.resampling
_module_loaders["statistics.resampling"] = function()
    -- Bootstrap 和重抽样模块
    local resampling = {}
    
    local utils = require("utils.init")
    local descriptive = require("statistics.descriptive")
    local distributions = require("statistics.distributions")
    
    -----------------------------------------------------------------------------
    -- 辅助函数
    -----------------------------------------------------------------------------
    
    -- Fisher-Yates 洗牌算法
    local function shuffle(t, rng)
        rng = rng or math.random
        local n = #t
        for i = n, 2, -1 do
            local j = math.floor(rng() * i) + 1
            t[i], t[j] = t[j], t[i]
        end
        return t
    end
    
    -- 从数组中有放回地抽样
    local function sample_with_replacement(t, n, rng)
        rng = rng or math.random
        n = n or #t
        local result = {}
        for i = 1, n do
            local idx = math.floor(rng() * #t) + 1
            result[i] = t[idx]
        end
        return result
    end
    
    -- 从数组中无放回地抽样
    local function sample_without_replacement(t, n, rng)
        rng = rng or math.random
        n = n or #t
        if n > #t then
            utils.Error.invalid_input("sample size cannot exceed population size")
        end
    
        -- 复制原数组
        local copy = {}
        for i = 1, #t do
            copy[i] = t[i]
        end
    
        -- Fisher-Yates 部分洗牌
        for i = 1, n do
            local j = math.floor(rng() * (#copy - i + 1)) + i
            copy[i], copy[j] = copy[j], copy[i]
        end
    
        local result = {}
        for i = 1, n do
            result[i] = copy[i]
        end
        return result
    end
    
    -- 计算统计量的辅助函数
    local function compute_statistic(data, stat_func)
        if type(stat_func) == "string" then
            -- 内置统计量
            if stat_func == "mean" then
                return descriptive.mean(data)
            elseif stat_func == "median" then
                return descriptive.median(data)
            elseif stat_func == "sd" or stat_func == "std" then
                return descriptive.std(data)
            elseif stat_func == "var" then
                return descriptive.var(data)
            elseif stat_func == "trimmed_mean" then
                return descriptive.trimmean(data, 0.1)
            else
                utils.Error.invalid_input("unknown statistic: " .. stat_func)
            end
        elseif type(stat_func) == "function" then
            return stat_func(data)
        else
            utils.Error.invalid_input("stat_func must be a string or function")
        end
    end
    
    -- 计算百分位数
    local function percentile(t, p)
        if #t == 0 then return nil end
    
        -- 排序
        local sorted = {}
        for i = 1, #t do
            sorted[i] = t[i]
        end
        table.sort(sorted)
    
        local n = #sorted
        local idx = (n - 1) * p + 1
        local lower = math.floor(idx)
        local upper = math.ceil(idx)
        local frac = idx - lower
    
        if lower == upper then
            return sorted[lower]
        else
            return sorted[lower] * (1 - frac) + sorted[upper] * frac
        end
    end
    
    -----------------------------------------------------------------------------
    -- Bootstrap 方法
    -----------------------------------------------------------------------------
    
    -- 单样本 Bootstrap
    -- @param data 原始数据
    -- @param stat_func 统计量函数或名称（"mean", "median", "std", "var"）
    -- @param n_bootstrap Bootstrap 样本数（默认 1000）
    -- @param seed 随机种子（可选）
    -- @return bootstrap_samples, se, bias, ci_lower, ci_upper
    function resampling.bootstrap(data, stat_func, n_bootstrap, seed)
        if type(data) ~= "table" or #data < 2 then
            utils.Error.invalid_input("data must be a table with at least 2 elements")
        end
    
        n_bootstrap = n_bootstrap or 1000
        if seed then
            math.randomseed(seed)
        end
    
        local n = #data
        local original_stat = compute_statistic(data, stat_func)
        local bootstrap_stats = {}
    
        for b = 1, n_bootstrap do
            -- 有放回抽样
            local sample = sample_with_replacement(data, n)
            local stat = compute_statistic(sample, stat_func)
            bootstrap_stats[b] = stat
        end
    
        -- 计算 Bootstrap 标准误
        local mean_stat = descriptive.mean(bootstrap_stats)
        local se = descriptive.std(bootstrap_stats)
    
        -- 计算 Bootstrap 偏差
        local bias = mean_stat - original_stat
    
        return {
            original = original_stat,
            bootstrap_samples = bootstrap_stats,
            mean = mean_stat,
            se = se,
            bias = bias
        }
    end
    
    -- Bootstrap 置信区间
    -- @param data 原始数据
    -- @param stat_func 统计量函数或名称
    -- @param n_bootstrap Bootstrap 样本数
    -- @param level 置信水平（默认 0.95）
    -- @param method 方法: "percentile", "basic", "bca", "normal"（默认 "percentile"）
    -- @param seed 随机种子
    -- @return lower, upper
    function resampling.bootstrap_ci(data, stat_func, n_bootstrap, level, method, seed)
        if type(data) ~= "table" or #data < 2 then
            utils.Error.invalid_input("data must be a table with at least 2 elements")
        end
    
        n_bootstrap = n_bootstrap or 1000
        level = level or 0.95
        method = method or "percentile"
    
        if seed then
            math.randomseed(seed)
        end
    
        local result = resampling.bootstrap(data, stat_func, n_bootstrap, seed)
        local bootstrap_stats = result.bootstrap_samples
        local original_stat = result.original
    
        local alpha = 1 - level
        local lower_p = alpha / 2
        local upper_p = 1 - alpha / 2
    
        if method == "percentile" then
            -- 百分位数法
            local lower = percentile(bootstrap_stats, lower_p)
            local upper = percentile(bootstrap_stats, upper_p)
            return lower, upper
    
        elseif method == "basic" then
            -- 基本法（反转百分位数）
            local lower_pivot = percentile(bootstrap_stats, upper_p)
            local upper_pivot = percentile(bootstrap_stats, lower_p)
            local lower = 2 * original_stat - upper_pivot
            local upper = 2 * original_stat - lower_pivot
            -- 确保 lower < upper
            if lower > upper then
                lower, upper = upper, lower
            end
            return lower, upper
    
        elseif method == "normal" then
            -- 正态近似法
            local z = distributions.normal.quantile(1 - alpha / 2)
            local lower = original_stat - z * result.se
            local upper = original_stat + z * result.se
            return lower, upper
    
        elseif method == "bca" then
            -- BCa (Bias-Corrected and Accelerated) 方法
            -- 计算偏差校正因子 z0
            local count = 0
            for i = 1, #bootstrap_stats do
                if bootstrap_stats[i] < original_stat then
                    count = count + 1
                end
            end
            local p0 = count / #bootstrap_stats
            if p0 == 0 then p0 = 0.001 end
            if p0 == 1 then p0 = 0.999 end
            local z0 = distributions.normal.quantile(p0)
    
            -- 加速度因子 a（使用 Jackknife 近似）
            local jackknife_stats = {}
            local n = #data
            for i = 1, n do
                local leave_one_out = {}
                for j = 1, n do
                    if j ~= i then
                        table.insert(leave_one_out, data[j])
                    end
                end
                jackknife_stats[i] = compute_statistic(leave_one_out, stat_func)
            end
            local jack_mean = descriptive.mean(jackknife_stats)
            local num, den = 0, 0
            for i = 1, n do
                local diff = jack_mean - jackknife_stats[i]
                num = num + diff ^ 3
                den = den + diff ^ 2
            end
            local a = num / (6 * den ^ 1.5)
            if den == 0 then a = 0 end
    
            -- 调整后的分位点
            local z_alpha_lower = distributions.normal.quantile(lower_p)
            local z_alpha_upper = distributions.normal.quantile(upper_p)
    
            local function adjust(z_alpha)
                local numer = z0 + z_alpha
                local denom = 1 - a * numer
                if denom == 0 then denom = 0.001 end
                return distributions.normal.cdf(z0 + numer / denom)
            end
    
            local adjusted_lower_p = adjust(z_alpha_lower)
            local adjusted_upper_p = adjust(z_alpha_upper)
    
            -- 确保分位点在有效范围内
            adjusted_lower_p = math.max(0.001, math.min(0.999, adjusted_lower_p))
            adjusted_upper_p = math.max(0.001, math.min(0.999, adjusted_upper_p))
    
            local lower = percentile(bootstrap_stats, adjusted_lower_p)
            local upper = percentile(bootstrap_stats, adjusted_upper_p)
            return lower, upper
    
        else
            utils.Error.invalid_input("unknown method: " .. method)
        end
    end
    
    -- 双样本 Bootstrap（比较两组）
    -- @param x 第一组数据
    -- @param y 第二组数据
    -- @param stat_func 统计量函数（接受两个参数）
    -- @param n_bootstrap Bootstrap 样本数
    -- @param level 置信水平
    -- @param method 置信区间方法
    -- @param seed 随机种子
    -- @return lower, upper, bootstrap_stats
    function resampling.bootstrap_two_sample(x, y, stat_func, n_bootstrap, level, method, seed)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("each sample must have at least 2 elements")
        end
    
        n_bootstrap = n_bootstrap or 1000
        level = level or 0.95
        method = method or "percentile"
    
        if seed then
            math.randomseed(seed)
        end
    
        local original_stat = stat_func(x, y)
        local bootstrap_stats = {}
    
        for b = 1, n_bootstrap do
            local sample_x = sample_with_replacement(x, #x)
            local sample_y = sample_with_replacement(y, #y)
            bootstrap_stats[b] = stat_func(sample_x, sample_y)
        end
    
        local alpha = 1 - level
    
        if method == "percentile" then
            local lower = percentile(bootstrap_stats, alpha / 2)
            local upper = percentile(bootstrap_stats, 1 - alpha / 2)
            return lower, upper, bootstrap_stats
        elseif method == "basic" then
            local lower = 2 * original_stat - percentile(bootstrap_stats, 1 - alpha / 2)
            local upper = 2 * original_stat - percentile(bootstrap_stats, alpha / 2)
            return lower, upper, bootstrap_stats
        else
            utils.Error.invalid_input("unknown method: " .. method)
        end
    end
    
    -----------------------------------------------------------------------------
    -- Jackknife 方法
    -----------------------------------------------------------------------------
    
    -- Jackknife 重抽样
    -- @param data 原始数据
    -- @param stat_func 统计量函数或名称
    -- @return jackknife_samples, mean, se, bias
    function resampling.jackknife(data, stat_func)
        if type(data) ~= "table" or #data < 2 then
            utils.Error.invalid_input("data must be a table with at least 2 elements")
        end
    
        local n = #data
        local original_stat = compute_statistic(data, stat_func)
        local jackknife_stats = {}
    
        for i = 1, n do
            -- 留一抽样
            local leave_one_out = {}
            for j = 1, n do
                if j ~= i then
                    table.insert(leave_one_out, data[j])
                end
            end
            jackknife_stats[i] = compute_statistic(leave_one_out, stat_func)
        end
    
        -- Jackknife 估计
        local jack_mean = descriptive.mean(jackknife_stats)
    
        -- Jackknife 标准误
        local sum_sq = 0
        for i = 1, n do
            sum_sq = sum_sq + (jackknife_stats[i] - jack_mean) ^ 2
        end
        local se = math.sqrt((n - 1) / n * sum_sq)
    
        -- Jackknife 偏差
        local bias = (n - 1) * (jack_mean - original_stat)
    
        return {
            original = original_stat,
            jackknife_samples = jackknife_stats,
            mean = jack_mean,
            se = se,
            bias = bias,
            bias_corrected = original_stat - bias
        }
    end
    
    -- Jackknife 置信区间
    -- @param data 原始数据
    -- @param stat_func 统计量函数或名称
    -- @param level 置信水平
    -- @return lower, upper
    function resampling.jackknife_ci(data, stat_func, level)
        level = level or 0.95
    
        local result = resampling.jackknife(data, stat_func)
        local alpha = 1 - level
        local z = distributions.normal.quantile(1 - alpha / 2)
    
        -- 使用偏差校正后的估计值
        local corrected = result.bias_corrected or result.original
        local lower = corrected - z * result.se
        local upper = corrected + z * result.se
    
        return lower, upper
    end
    
    -----------------------------------------------------------------------------
    -- 置换检验
    -----------------------------------------------------------------------------
    
    -- 两独立样本置换检验
    -- @param x 第一组数据
    -- @param y 第二组数据
    -- @param stat_func 检验统计量函数（默认为均值差）
    -- @param n_permutations 置换次数（默认 1000）
    -- @param alternative 备择假设: "two.sided", "less", "greater"
    -- @param seed 随机种子
    -- @return observed_stat, p_value, permutation_stats
    function resampling.permutation_test(x, y, stat_func, n_permutations, alternative, seed)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 1 or #y < 1 then
            utils.Error.invalid_input("each sample must have at least 1 element")
        end
    
        n_permutations = n_permutations or 1000
        alternative = alternative or "two.sided"
    
        if seed then
            math.randomseed(seed)
        end
    
        -- 默认统计量：均值差
        stat_func = stat_func or function(a, b)
            return descriptive.mean(a) - descriptive.mean(b)
        end
    
        local n1, n2 = #x, #y
        local observed_stat = stat_func(x, y)
    
        -- 合并数据
        local combined = {}
        for i = 1, n1 do
            combined[i] = x[i]
        end
        for i = 1, n2 do
            combined[n1 + i] = y[i]
        end
    
        local permutation_stats = {}
        local extreme_count = 0
    
        for p = 1, n_permutations do
            -- 随机重排
            local permuted = {}
            for i = 1, #combined do
                permuted[i] = combined[i]
            end
            shuffle(permuted)
    
            -- 分成两组
            local perm_x = {}
            local perm_y = {}
            for i = 1, n1 do
                perm_x[i] = permuted[i]
            end
            for i = 1, n2 do
                perm_y[i] = permuted[n1 + i]
            end
    
            local perm_stat = stat_func(perm_x, perm_y)
            permutation_stats[p] = perm_stat
    
            -- 计算极端值数量
            if alternative == "two.sided" then
                if math.abs(perm_stat) >= math.abs(observed_stat) then
                    extreme_count = extreme_count + 1
                end
            elseif alternative == "greater" then
                if perm_stat >= observed_stat then
                    extreme_count = extreme_count + 1
                end
            else  -- less
                if perm_stat <= observed_stat then
                    extreme_count = extreme_count + 1
                end
            end
        end
    
        -- p 值（加 1 法以避免 p = 0）
        local p_value = (extreme_count + 1) / (n_permutations + 1)
    
        return observed_stat, p_value, permutation_stats
    end
    
    -- 配对样本置换检验
    -- @param x 第一组数据
    -- @param y 第二组数据
    -- @param n_permutations 置换次数
    -- @param alternative 备择假设
    -- @param seed 随机种子
    -- @return observed_stat, p_value
    function resampling.permutation_test_paired(x, y, n_permutations, alternative, seed)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x ~= #y then
            utils.Error.dimension_mismatch(#x, #y, "paired samples must have equal length")
        end
        if #x < 1 then
            utils.Error.invalid_input("samples must have at least 1 element")
        end
    
        n_permutations = n_permutations or 1000
        alternative = alternative or "two.sided"
    
        if seed then
            math.randomseed(seed)
        end
    
        local n = #x
    
        -- 计算差值
        local diff = {}
        for i = 1, n do
            diff[i] = x[i] - y[i]
        end
    
        -- 观测统计量：差值均值
        local observed_stat = descriptive.mean(diff)
    
        local extreme_count = 0
    
        for p = 1, n_permutations do
            -- 对每个差值随机分配符号
            local perm_diff = {}
            for i = 1, n do
                if math.random() < 0.5 then
                    perm_diff[i] = -diff[i]
                else
                    perm_diff[i] = diff[i]
                end
            end
    
            local perm_stat = descriptive.mean(perm_diff)
    
            if alternative == "two.sided" then
                if math.abs(perm_stat) >= math.abs(observed_stat) then
                    extreme_count = extreme_count + 1
                end
            elseif alternative == "greater" then
                if perm_stat >= observed_stat then
                    extreme_count = extreme_count + 1
                end
            else  -- less
                if perm_stat <= observed_stat then
                    extreme_count = extreme_count + 1
                end
            end
        end
    
        local p_value = (extreme_count + 1) / (n_permutations + 1)
    
        return observed_stat, p_value
    end
    
    -----------------------------------------------------------------------------
    -- 自助法假设检验
    -----------------------------------------------------------------------------
    
    -- Bootstrap t 检验
    -- @param x 样本数据
    -- @param mu 假设的总体均值
    -- @param n_bootstrap Bootstrap 样本数
    -- @param alternative 备择假设
    -- @param seed 随机种子
    -- @return t_stat, p_value
    function resampling.bootstrap_t_test(x, mu, n_bootstrap, alternative, seed)
        if type(x) ~= "table" or #x < 2 then
            utils.Error.invalid_input("x must be a table with at least 2 elements")
        end
    
        mu = mu or 0
        n_bootstrap = n_bootstrap or 1000
        alternative = alternative or "two.sided"
    
        if seed then
            math.randomseed(seed)
        end
    
        local n = #x
        local sample_mean = descriptive.mean(x)
        local sample_std = descriptive.std(x)
        local observed_t = (sample_mean - mu) / (sample_std / math.sqrt(n))
    
        -- Bootstrap 检验：在原假设下生成数据
        local extreme_count = 0
    
        for b = 1, n_bootstrap do
            -- 从样本中 Bootstrap
            local sample = sample_with_replacement(x, n)
            local boot_mean = descriptive.mean(sample)
            local boot_std = descriptive.std(sample)
    
            -- 构建在原假设下的 t 统计量
            local boot_t = (boot_mean - mu) / (boot_std / math.sqrt(n))
    
            if alternative == "two.sided" then
                if math.abs(boot_t) >= math.abs(observed_t) then
                    extreme_count = extreme_count + 1
                end
            elseif alternative == "greater" then
                if boot_t >= observed_t then
                    extreme_count = extreme_count + 1
                end
            else  -- less
                if boot_t <= observed_t then
                    extreme_count = extreme_count + 1
                end
            end
        end
    
        local p_value = (extreme_count + 1) / (n_bootstrap + 1)
    
        return observed_t, p_value
    end
    
    -- Bootstrap 方差检验
    -- @param x 第一组数据
    -- @param y 第二组数据
    -- @param n_bootstrap Bootstrap 样本数
    -- @param seed 随机种子
    -- @return f_stat, p_value
    function resampling.bootstrap_var_test(x, y, n_bootstrap, seed)
        if type(x) ~= "table" or type(y) ~= "table" then
            utils.Error.invalid_input("x and y must be tables")
        end
        if #x < 2 or #y < 2 then
            utils.Error.invalid_input("each sample must have at least 2 elements")
        end
    
        n_bootstrap = n_bootstrap or 1000
    
        if seed then
            math.randomseed(seed)
        end
    
        local v1 = descriptive.var(x)
        local v2 = descriptive.var(y)
        local observed_f = v1 / v2
    
        -- 合并数据
        local combined = {}
        for i = 1, #x do
            combined[i] = x[i]
        end
        for i = 1, #y do
            combined[#x + i] = y[i]
        end
    
        local n1, n2 = #x, #y
        local extreme_count = 0
    
        for b = 1, n_bootstrap do
            local sample1 = sample_with_replacement(combined, n1)
            local sample2 = sample_with_replacement(combined, n2)
    
            local boot_v1 = descriptive.var(sample1)
            local boot_v2 = descriptive.var(sample2)
            local boot_f = boot_v1 / boot_v2
    
            if boot_f >= observed_f then
                extreme_count = extreme_count + 1
            end
        end
    
        -- 双侧 p 值
        local p_value = 2 * math.min(extreme_count, n_bootstrap - extreme_count) / n_bootstrap
    
        return observed_f, p_value
    end
    
    -----------------------------------------------------------------------------
    -- 其他重抽样方法
    -----------------------------------------------------------------------------
    
    -- 交叉验证（K-fold）
    -- @param data 数据（x, y 或只有 y）
    -- @param k 折数（默认 10）
    -- @param model_func 模型训练函数（返回预测函数）
    -- @param loss_func 损失函数（默认为平方误差）
    -- @param seed 随机种子
    -- @return mean_error, std_error, fold_errors
    function resampling.cross_validation(data, k, model_func, loss_func, seed)
        if type(data) ~= "table" then
            utils.Error.invalid_input("data must be a table")
        end
    
        k = k or 10
        loss_func = loss_func or function(y_true, y_pred)
            return (y_true - y_pred) ^ 2
        end
    
        if seed then
            math.randomseed(seed)
        end
    
        local n
        local x, y
    
        -- 判断数据格式
        if type(data.x) == "table" and type(data.y) == "table" then
            x = data.x
            y = data.y
            n = #y
        elseif type(data.y) == "table" then
            -- 只有 y 的情况：data = {y = {...}}
            y = data.y
            n = #y
        elseif type(data) == "table" then
            -- data 直接是数组
            y = data
            n = #data
            if n == 0 then
                utils.Error.invalid_input("data must be a non-empty table")
            end
        else
            utils.Error.invalid_input("data must be a table with values or {y=...} format")
        end
    
        if k > n then
            k = n  -- 如果 k > n，使用 n 折（留一法）
        end
    
        -- 随机排列索引
        local indices = {}
        for i = 1, n do
            indices[i] = i
        end
        shuffle(indices)
    
        local fold_size = math.floor(n / k)
        local fold_errors = {}
    
        for fold = 1, k do
            -- 划分训练集和验证集
            local test_start = (fold - 1) * fold_size + 1
            local test_end = (fold == k) and n or (fold * fold_size)
    
            local train_idx = {}
            local test_idx = {}
            for i = 1, n do
                if i >= test_start and i <= test_end then
                    table.insert(test_idx, indices[i])
                else
                    table.insert(train_idx, indices[i])
                end
            end
    
            -- 训练模型
            local predict = model_func(train_idx, test_idx)
    
            -- 计算测试误差
            local total_error = 0
            for i = 1, #test_idx do
                local idx = test_idx[i]
                local y_true = y[idx]
                local y_pred
                if x then
                    y_pred = predict(x[idx])
                else
                    y_pred = predict(idx)
                end
                total_error = total_error + loss_func(y_true, y_pred)
            end
            fold_errors[fold] = total_error / #test_idx
        end
    
        local mean_error = descriptive.mean(fold_errors)
        local std_error = descriptive.std(fold_errors)
    
        return mean_error, std_error, fold_errors
    end
    
    -- 蒙特卡洛模拟
    -- @param n_simulations 模拟次数
    -- @param sim_func 模拟函数（返回一个值）
    -- @param seed 随机种子
    -- @return mean, se, results
    function resampling.monte_carlo(n_simulations, sim_func, seed)
        if type(n_simulations) ~= "number" or n_simulations < 1 then
            utils.Error.invalid_input("n_simulations must be a positive integer")
        end
        if type(sim_func) ~= "function" then
            utils.Error.invalid_input("sim_func must be a function")
        end
    
        if seed then
            math.randomseed(seed)
        end
    
        local results = {}
        for i = 1, n_simulations do
            results[i] = sim_func()
        end
    
        local mean = descriptive.mean(results)
        local se = descriptive.std(results)
    
        return mean, se, results
    end
    
    return resampling
end

-- ===========================================================================
-- 模块初始化
-- ===========================================================================

-- 预加载所有模块
local function preload_modules()
    _require("utils.constants")
    _require("utils.error")
    _require("utils.validators")
    _require("utils.typecheck")
    _require("matrix.matrix")
    _require("matrix.basic_ops")
    _require("matrix.advanced_ops")
    _require("matrix.decompositions")
    _require("matrix.solvers")
    _require("matrix.special_matrices")
    _require("vector.vector")
    _require("vector.basic_ops")
    _require("vector.advanced_ops")
    _require("vector.special_vectors")
    _require("integration.basic_integration")
    _require("integration.advanced_integration")
    _require("integration.multi_integration")
    _require("interpolation.basic_interpolation")
    _require("interpolation.advanced_interpolation")
    _require("interpolation.multi_interpolation")
    _require("optimization.basic_optimization")
    _require("optimization.gradient_methods")
    _require("ode.basic_methods")
    _require("ode.advanced_methods")
    _require("root_finding.multi_root")
    _require("pde.elliptic")
    _require("pde.parabolic")
    _require("pde.hyperbolic")
    _require("statistics.descriptive")
    _require("statistics.correlation")
    _require("statistics.distributions")
    _require("statistics.hypothesis")
    _require("statistics.regression")
    _require("statistics.resampling")
end

preload_modules()

-- 恢复原始 require
require = _original_require

-- Utils 模块封装
local utils = {}
utils.constants = _loaded["utils.constants"]
utils.Error = _loaded["utils.error"]
utils.validators = _loaded["utils.validators"]
utils.typecheck = _loaded["utils.typecheck"]
utils.pi = utils.constants.pi
utils.e = utils.constants.e
utils.phi = utils.constants.phi
utils.gamma = utils.constants.gamma
utils.epsilon = utils.constants.epsilon
utils.tiny = utils.constants.tiny
utils.huge = utils.constants.huge
utils.deg2rad = utils.constants.deg2rad
utils.rad2deg = utils.constants.rad2deg
utils.assert_matrix = utils.validators.assert_matrix
utils.assert_square_matrix = utils.validators.assert_square_matrix
utils.assert_same_dimensions = utils.validators.assert_same_dimensions
utils.assert_can_multiply = utils.validators.assert_can_multiply
function utils.abs(x) return math.abs(x) end
function utils.sign(x) if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end end
function utils.max(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] > m then m = v[i] end end return m end
function utils.min(...) local v = {...} local m = v[1] for i = 2, #v do if v[i] < m then m = v[i] end end return m end
function utils.dot(v1, v2) if #v1 ~= #v2 then utils.Error.dimension_mismatch(#v1, #v2) end local s = 0 for i = 1, #v1 do s = s + v1[i] * v2[i] end return s end
function utils.norm(v) local s = 0 for i = 1, #v do s = s + v[i] * v[i] end return math.sqrt(s) end
_loaded["utils.init"] = utils

-- Matrix 模块封装
local matrix = {}
local Matrix = _loaded["matrix.matrix"]
local special_matrices = _loaded["matrix.special_matrices"]
matrix.new = Matrix.new
matrix.Matrix = Matrix
matrix.zeros = special_matrices.zeros
matrix.ones = special_matrices.ones
matrix.eye = special_matrices.eye
matrix.diag = special_matrices.diag
matrix.rand = special_matrices.rand
matrix.rand_int = special_matrices.rand_int
matrix.rand_spd = special_matrices.rand_spd
matrix.hilbert = special_matrices.hilbert
matrix.vandermonde = special_matrices.vandermonde
matrix.toeplitz = special_matrices.toeplitz
matrix.circulant = special_matrices.circulant
matrix.block_diagonal = special_matrices.block_diagonal
matrix.identity = matrix.eye
setmetatable(matrix, { __call = function(_, ...) return Matrix.new(...) end })
_loaded["matrix.init"] = matrix

-- Vector 模块封装
local vector = {}
local Vector = _loaded["vector.vector"]
vector.new = Vector.new
vector.Vector = Vector
vector.zeros = Vector.zeros
vector.ones = Vector.ones
vector.unit = Vector.unit
vector.rand = Vector.rand
vector.rand_int = Vector.rand_int
vector.rand_unit = Vector.rand_unit
vector.randn = Vector.randn
vector.linspace = Vector.linspace
vector.logspace = Vector.logspace
vector.geomspace = Vector.geomspace
vector.from_table = Vector.from_table
vector.range = Vector.range
vector.basis = Vector.basis
vector.standard_basis = Vector.standard_basis
vector.constant = Vector.constant
vector.repeat_vec = Vector.repeat_vec
vector.concat_vectors = Vector.concat_vectors
vector.stack = Vector.stack
vector.indices = Vector.indices
vector.bool = Vector.bool
vector.from_string = Vector.from_string
vector.meshgrid = Vector.meshgrid
vector.sphere_grid = Vector.sphere_grid
vector.triple_product = Vector.triple_product
vector.double_cross = Vector.double_cross
vector.zero = vector.zeros
vector.identity = vector.unit
setmetatable(vector, { __call = function(_, ...) return Vector.new(...) end })
_loaded["vector.init"] = vector

-- Integration 模块封装
local integration = {}
local basic_int = _loaded["integration.basic_integration"]
local advanced_int = _loaded["integration.advanced_integration"]
local multi_int = _loaded["integration.multi_integration"]
integration.trapezoidal = basic_int.trapezoidal
integration.simpson = basic_int.simpson
integration.midpoint = basic_int.midpoint
integration.left_endpoint = basic_int.left_endpoint
integration.right_endpoint = basic_int.right_endpoint
integration.adaptive = advanced_int.adaptive
integration.romberg = advanced_int.romberg
integration.gauss = advanced_int.gauss
integration.composite_gauss = advanced_int.composite_gauss
integration.singular = advanced_int.singular
integration.double = multi_int.double
integration.double_integral = multi_int.double_integral
integration.triple = multi_int.triple
integration.triple_integral = multi_int.triple_integral
integration.monte_carlo = multi_int.monte_carlo
integration.monte_carlo_region = multi_int.monte_carlo_region
integration.trap = integration.trapezoidal
integration.adaptive_simpson = integration.adaptive
integration.gauss_legendre = integration.gauss
function integration.integrate(f, a, b, options)
    options = options or {}
    local method = options.method or "simpson"
    local methods = {
        trapezoidal = function() return integration.trapezoidal(f, a, b, options.n) end,
        trap = function() return integration.trapezoidal(f, a, b, options.n) end,
        simpson = function() return integration.simpson(f, a, b, options.n) end,
        midpoint = function() return integration.midpoint(f, a, b, options.n) end,
        adaptive = function() return integration.adaptive(f, a, b, options.tol, options.max_iter) end,
        romberg = function() return integration.romberg(f, a, b, options.n, options.tol) end,
        gauss = function() return integration.gauss(f, a, b, options.n) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["integration.init"] = integration

-- Interpolation 模块封装
local interpolation = {}
local basic_interp = _loaded["interpolation.basic_interpolation"]
local advanced_interp = _loaded["interpolation.advanced_interpolation"]
local multi_interp = _loaded["interpolation.multi_interpolation"]
interpolation.linear = basic_interp.linear
interpolation.lagrange = basic_interp.lagrange
interpolation.newton = basic_interp.newton
interpolation.piecewise_linear = basic_interp.piecewise_linear
interpolation.spline = advanced_interp.spline
interpolation.spline_clamped = advanced_interp.spline_clamped
interpolation.spline_derivative = advanced_interp.spline_derivative
interpolation.spline_derivative2 = advanced_interp.spline_derivative2
interpolation.bilinear = multi_interp.bilinear
interpolation.bicubic = multi_interp.bicubic
interpolation.rbf = multi_interp.rbf
interpolation.idw = multi_interp.idw
interpolation.nearest_neighbor = multi_interp.nearest_neighbor
interpolation.poly = interpolation.lagrange
interpolation.natural_spline = interpolation.spline
function interpolation.interpolate(x, x_data, y_data, options)
    options = options or {}
    local method = options.method or "linear"
    local methods = {
        linear = function() return interpolation.linear(x, x_data, y_data) end,
        lagrange = function() return interpolation.lagrange(x, x_data, y_data) end,
        newton = function() return interpolation.newton(x, x_data, y_data) end,
        spline = function() return interpolation.spline(x, x_data, y_data) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["interpolation.init"] = interpolation

-- Optimization 模块封装
local optimization = {}
local basic_opt = _loaded["optimization.basic_optimization"]
local gradient_opt = _loaded["optimization.gradient_methods"]
optimization.golden_section = basic_opt.golden_section
optimization.parabolic_interpolation = basic_opt.parabolic_interpolation
optimization.fibonacci_search = basic_opt.fibonacci_search
optimization.bisection = basic_opt.bisection
optimization.gradient_descent = gradient_opt.gradient_descent
optimization.newton = gradient_opt.newton
optimization.bfgs = gradient_opt.bfgs
optimization.conjugate_gradient = gradient_opt.conjugate_gradient
optimization.stochastic_gradient_descent = gradient_opt.stochastic_gradient_descent
optimization.gs = optimization.golden_section
optimization.gd = optimization.gradient_descent
optimization.sgd = optimization.stochastic_gradient_descent
optimization.cg = optimization.conjugate_gradient
function optimization.optimize(f, x0, options)
    options = options or {}
    if type(x0) == "number" then
        local a = options.a or x0 - 1
        local b = options.b or x0 + 1
        return optimization.golden_section(f, a, b, options.tol)
    else
        if not options.grad then error("Gradient required") end
        return optimization.bfgs(f, options.grad, x0, options)
    end
end
function optimization.minimize_1d(f, a, b, options) return optimization.golden_section(f, a, b, options and options.tol) end
function optimization.minimize(f, grad, x0, options) return optimization.bfgs(f, grad, x0, options) end
_loaded["optimization.init"] = optimization

-- ODE 模块封装
local ode = {}
local basic_ode = _loaded["ode.basic_methods"]
local advanced_ode = _loaded["ode.advanced_methods"]
ode.euler = basic_ode.euler
ode.heun = basic_ode.heun
ode.midpoint = basic_ode.midpoint
ode.runge_kutta4 = advanced_ode.runge_kutta4
ode.rk4 = advanced_ode.runge_kutta4
ode.rk45 = advanced_ode.rk45
ode.improved_euler = ode.heun
function ode.solve(f, t_span, y0, options)
    options = options or {}
    local method = options.method or "rk4"
    local t0, t_end = t_span[1], t_span[2]
    local h = options.h
    local methods = {
        euler = function() return ode.euler(f, t0, y0, t_end, h, options) end,
        heun = function() return ode.heun(f, t0, y0, t_end, h, options) end,
        rk4 = function() return ode.rk4(f, t0, y0, t_end, h, options) end,
        rk45 = function() return ode.rk45(f, t0, y0, t_end, options) end,
    }
    local fn = methods[method]
    if not fn then error("Unknown method: " .. method) end
    return fn()
end
_loaded["ode.init"] = ode

-- Root finding 模块封装
local root = {}
local multi_root = _loaded["root_finding.multi_root"]
root.newton = multi_root.newton
root.broyden = multi_root.broyden
root.fixed_point = multi_root.fixed_point
root.trust_region = multi_root.trust_region
root.find_root = multi_root.find_root
root.solve = multi_root.solve
root.nsolve = multi_root.nsolve
_loaded["root_finding.init"] = root

-- PDE 模块封装
local pde = {}
local elliptic = _loaded["pde.elliptic"]
local parabolic = _loaded["pde.parabolic"]
local hyperbolic = _loaded["pde.hyperbolic"]
pde.poisson = elliptic.poisson
pde.laplace = elliptic.laplace
pde.interpolate = elliptic.interpolate
pde.heat1d = parabolic.heat1d
pde.heat2d = parabolic.heat2d
pde.wave1d = hyperbolic.wave1d
pde.wave2d = hyperbolic.wave2d
pde.advection1d = hyperbolic.advection1d
function pde.solve(eq_type, prob_type, ...)
    if eq_type == "elliptic" then
        if prob_type == "poisson" then return elliptic.poisson(...)
        elseif prob_type == "laplace" then return elliptic.laplace(...) end
    elseif eq_type == "parabolic" then
        return parabolic.heat1d(...)
    elseif eq_type == "hyperbolic" then
        if prob_type == "wave" then return hyperbolic.wave1d(...)
        else return hyperbolic.advection1d(...) end
    end
    error("Unknown type: " .. eq_type .. "/" .. prob_type)
end
_loaded["pde.init"] = pde

-- Statistics 模块封装
local statistics = {}
local descriptive = _loaded["statistics.descriptive"]
local correlation = _loaded["statistics.correlation"]
local distributions = _loaded["statistics.distributions"]
local hypothesis = _loaded["statistics.hypothesis"]
local regression = _loaded["statistics.regression"]
local resampling = _loaded["statistics.resampling"]

-- 描述性统计
statistics.mean = descriptive.mean
statistics.median = descriptive.median
statistics.mode = descriptive.mode
statistics.var = descriptive.var
statistics.std = descriptive.std
statistics.percentile = descriptive.percentile
statistics.quartile = descriptive.quartile
statistics.quantile = descriptive.quantile
statistics.range = descriptive.range
statistics.iqr = descriptive.iqr
statistics.skewness = descriptive.skewness
statistics.kurtosis = descriptive.kurtosis
statistics.moment = descriptive.moment
statistics.geomean = descriptive.geomean
statistics.harmean = descriptive.harmean
statistics.trimmean = descriptive.trimmean
statistics.mad = descriptive.mad
statistics.sem = descriptive.sem
statistics.var_pop = descriptive.var_pop
statistics.std_pop = descriptive.std_pop
statistics.describe = descriptive.describe
statistics.histogram = descriptive.histogram
statistics.frequency = descriptive.frequency

-- 相关性分析
statistics.cov = correlation.cov
statistics.cov_pop = correlation.cov_pop
statistics.corr = correlation.corr
statistics.corrcoef = correlation.corrcoef
statistics.spearman = correlation.spearman
statistics.kendall = correlation.kendall

-- 概率分布
statistics.dist = distributions
statistics.normal = distributions.normal
statistics.uniform = distributions.uniform
statistics.exponential = distributions.exponential
statistics.t = distributions.t
statistics.chi2 = distributions.chi2
statistics.f = distributions.f
statistics.gamma = distributions.gamma
statistics.beta = distributions.beta
statistics.bernoulli = distributions.bernoulli
statistics.binomial = distributions.binomial
statistics.poisson = distributions.poisson
statistics.geometric = distributions.geometric
statistics.seed = distributions.seed

-- 假设检验
statistics.t_test_one_sample = hypothesis.t_test_one_sample
statistics.t_test_two_sample = hypothesis.t_test_two_sample
statistics.welch_test = hypothesis.welch_test
statistics.z_test_one_sample = hypothesis.z_test_one_sample
statistics.var_test = hypothesis.var_test
statistics.chisq_test_goodness = hypothesis.chisq_test_goodness
statistics.chisq_test_independence = hypothesis.chisq_test_independence
statistics.wilcoxon_signed_rank = hypothesis.wilcoxon_signed_rank
statistics.mann_whitney_u = hypothesis.mann_whitney_u
statistics.ci_mean = hypothesis.ci_mean
statistics.ci_mean_diff = hypothesis.ci_mean_diff
statistics.ci_proportion = hypothesis.ci_proportion
statistics.cohens_d_one_sample = hypothesis.cohens_d_one_sample
statistics.cohens_d_two_sample = hypothesis.cohens_d_two_sample

-- 回归分析
statistics.lm = regression.linear
statistics.linear_regression = regression.linear
statistics.multiple_regression = regression.multiple
statistics.polynomial_regression = regression.polynomial
statistics.wls = regression.wls
statistics.ridge = regression.ridge
statistics.regression = regression

-- Bootstrap 和重抽样
statistics.bootstrap = resampling.bootstrap
statistics.bootstrap_ci = resampling.bootstrap_ci
statistics.bootstrap_two_sample = resampling.bootstrap_two_sample
statistics.jackknife = resampling.jackknife
statistics.jackknife_ci = resampling.jackknife_ci
statistics.permutation_test = resampling.permutation_test
statistics.permutation_test_paired = resampling.permutation_test_paired
statistics.bootstrap_t_test = resampling.bootstrap_t_test
statistics.bootstrap_var_test = resampling.bootstrap_var_test
statistics.cross_validation = resampling.cross_validation
statistics.monte_carlo = resampling.monte_carlo
statistics.resampling = resampling

_loaded["statistics.init"] = statistics

-- 主模块导出
lua_num._VERSION = "1.0.0"
lua_num._DESCRIPTION = "Lua Numerical Computing Library (Single File)"
lua_num._AUTHOR = "lua_num contributors"

lua_num.utils = utils
lua_num.matrix = matrix
lua_num.vector = vector
lua_num.integration = integration
lua_num.interpolation = interpolation
lua_num.optimization = optimization
lua_num.ode = ode
lua_num.root = root
lua_num.pde = pde
lua_num.statistics = statistics

lua_num.mat = matrix
lua_num.vec = vector
lua_num.integ = integration
lua_num.interp = interpolation
lua_num.opt = optimization

lua_num.PI = math.pi
lua_num.E = math.exp(1)
lua_num.EPSILON = 1e-15
lua_num.INF = math.huge
lua_num.PHI = (1 + math.sqrt(5)) / 2

function lua_num.isclose(a, b, rel_tol, abs_tol)
    rel_tol = rel_tol or 1e-9
    abs_tol = abs_tol or 0
    return math.abs(a - b) <= math.max(rel_tol * math.max(math.abs(a), math.abs(b)), abs_tol)
end

function lua_num.sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

function lua_num.linspace(a, b, n)
    n = n or 100
    local result = {}
    if n == 1 then result[1] = a
    else
        local step = (b - a) / (n - 1)
        for i = 0, n - 1 do result[i + 1] = a + i * step end
    end
    return result
end

function lua_num.sum(t) local s = 0 for i = 1, #t do s = s + t[i] end return s end
function lua_num.prod(t) local p = 1 for i = 1, #t do p = p * t[i] end return p end
function lua_num.max(t) if #t == 0 then return nil end local m = t[1] for i = 2, #t do if t[i] > m then m = t[i] end end return m end
function lua_num.min(t) if #t == 0 then return nil end local m = t[1] for i = 2, #t do if t[i] < m then m = t[i] end end return m end
function lua_num.mean(t) if #t == 0 then return nil end return lua_num.sum(t) / #t end
function lua_num.var(t) if #t == 0 then return nil end local m = lua_num.mean(t) local s = 0 for i = 1, #t do s = s + (t[i] - m) ^ 2 end return s / #t end
function lua_num.std(t) return math.sqrt(lua_num.var(t)) end
function lua_num.dot(a, b) local s = 0 for i = 1, math.min(#a, #b) do s = s + a[i] * b[i] end return s end
function lua_num.map(t, f) local r = {} for i = 1, #t do r[i] = f(t[i]) end return r end
function lua_num.filter(t, f) local r = {} for i = 1, #t do if f(t[i]) then r[#r + 1] = t[i] end end return r end

return lua_num
