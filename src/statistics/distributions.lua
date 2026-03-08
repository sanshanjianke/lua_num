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