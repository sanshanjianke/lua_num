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
