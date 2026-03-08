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
