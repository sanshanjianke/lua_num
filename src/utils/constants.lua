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
