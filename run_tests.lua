-- 运行所有测试
-- 用法: lua run_tests.lua

local tests = {
    "tests/test_matrix.lua",
    "tests/test_vector.lua",
    "tests/test_integration.lua",
    "tests/test_multi_integration.lua",
    "tests/test_interpolation.lua",
    "tests/test_multi_interpolation.lua",
    "tests/test_optimization.lua",
    "tests/test_ode.lua",
    "tests/test_multi_root.lua",
    "tests/test_pde.lua",
    "tests/test_statistics.lua",
    "tests/test_distributions.lua",
    "tests/test_hypothesis.lua",
    "tests/test_regression.lua",
    "tests/test_resampling.lua",
}

local passed = 0
local failed = 0
local failed_tests = {}

print("==================================================")
print("       lua_num 测试套件")
print("==================================================\n")

for _, test_file in ipairs(tests) do
    print(string.format("运行: %s", test_file))
    print(string.rep("-", 50))

    local ok, err = pcall(function()
        dofile(test_file)
    end)

    if ok then
        passed = passed + 1
        print("✓ 通过\n")
    else
        failed = failed + 1
        table.insert(failed_tests, test_file)
        print(string.format("✗ 失败: %s\n", err))
    end
end

print("==================================================")
print(string.format("测试结果: %d 通过, %d 失败", passed, failed))
print("==================================================")

if failed > 0 then
    print("\n失败的测试:")
    for _, test in ipairs(failed_tests) do
        print(string.format("  - %s", test))
    end
    os.exit(1)
else
    print("\n所有测试通过!")
    os.exit(0)
end