-- 根求解模块入口
local root = {}

-- 加载多维根求解模块
local multi = require("root_finding.multi_root")

-- 导出多维根求解方法
root.newton = multi.newton
root.broyden = multi.broyden
root.fixed_point = multi.fixed_point
root.trust_region = multi.trust_region
root.find_root = multi.find_root
root.solve = multi.solve
root.nsolve = multi.nsolve

-- 别名
root.nsolve_newton = root.newton
root.nsolve_broyden = root.broyden
root.nsolve_trust_region = root.trust_region

return root