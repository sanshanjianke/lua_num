-- 统计学模块
local statistics = {}

-- 加载子模块
statistics._descriptive = require("statistics.descriptive")
statistics._correlation = require("statistics.correlation")
statistics._distributions = require("statistics.distributions")
statistics._hypothesis = require("statistics.hypothesis")
statistics._regression = require("statistics.regression")
statistics._resampling = require("statistics.resampling")

-- 描述性统计
statistics.mean = statistics._descriptive.mean
statistics.median = statistics._descriptive.median
statistics.mode = statistics._descriptive.mode
statistics.var = statistics._descriptive.var
statistics.std = statistics._descriptive.std
statistics.percentile = statistics._descriptive.percentile
statistics.quartile = statistics._descriptive.quartile
statistics.quantile = statistics._descriptive.quantile
statistics.range = statistics._descriptive.range
statistics.iqr = statistics._descriptive.iqr
statistics.skewness = statistics._descriptive.skewness
statistics.kurtosis = statistics._descriptive.kurtosis
statistics.moment = statistics._descriptive.moment
statistics.geomean = statistics._descriptive.geomean
statistics.harmean = statistics._descriptive.harmean
statistics.trimmean = statistics._descriptive.trimmean
statistics.mad = statistics._descriptive.mad
statistics.sem = statistics._descriptive.sem
statistics.var_pop = statistics._descriptive.var_pop
statistics.std_pop = statistics._descriptive.std_pop
statistics.describe = statistics._descriptive.describe

-- 相关性分析
statistics.cov = statistics._correlation.cov
statistics.cov_pop = statistics._correlation.cov_pop
statistics.corr = statistics._correlation.corr
statistics.corrcoef = statistics._correlation.corrcoef
statistics.spearman = statistics._correlation.spearman
statistics.kendall = statistics._correlation.kendall

-- 直方图和频数
statistics.histogram = statistics._descriptive.histogram
statistics.frequency = statistics._descriptive.frequency

-- 概率分布
statistics.dist = statistics._distributions

-- 分布快捷访问
statistics.normal = statistics._distributions.normal
statistics.uniform = statistics._distributions.uniform
statistics.exponential = statistics._distributions.exponential
statistics.t = statistics._distributions.t
statistics.chi2 = statistics._distributions.chi2
statistics.f = statistics._distributions.f
statistics.gamma = statistics._distributions.gamma
statistics.beta = statistics._distributions.beta
statistics.bernoulli = statistics._distributions.bernoulli
statistics.binomial = statistics._distributions.binomial
statistics.poisson = statistics._distributions.poisson
statistics.geometric = statistics._distributions.geometric

-- 随机种子
statistics.seed = statistics._distributions.seed

-- 假设检验
statistics.t_test_one_sample = statistics._hypothesis.t_test_one_sample
statistics.t_test_two_sample = statistics._hypothesis.t_test_two_sample
statistics.welch_test = statistics._hypothesis.welch_test
statistics.z_test_one_sample = statistics._hypothesis.z_test_one_sample
statistics.var_test = statistics._hypothesis.var_test
statistics.chisq_test_goodness = statistics._hypothesis.chisq_test_goodness
statistics.chisq_test_independence = statistics._hypothesis.chisq_test_independence
statistics.wilcoxon_signed_rank = statistics._hypothesis.wilcoxon_signed_rank
statistics.mann_whitney_u = statistics._hypothesis.mann_whitney_u
statistics.ci_mean = statistics._hypothesis.ci_mean
statistics.ci_mean_diff = statistics._hypothesis.ci_mean_diff
statistics.ci_proportion = statistics._hypothesis.ci_proportion
statistics.cohens_d_one_sample = statistics._hypothesis.cohens_d_one_sample
statistics.cohens_d_two_sample = statistics._hypothesis.cohens_d_two_sample

-- 回归分析
statistics.lm = statistics._regression.linear
statistics.linear_regression = statistics._regression.linear
statistics.multiple_regression = statistics._regression.multiple
statistics.polynomial_regression = statistics._regression.polynomial
statistics.wls = statistics._regression.wls
statistics.ridge = statistics._regression.ridge
statistics.regression = statistics._regression

-- Bootstrap 和重抽样
statistics.bootstrap = statistics._resampling.bootstrap
statistics.bootstrap_ci = statistics._resampling.bootstrap_ci
statistics.bootstrap_two_sample = statistics._resampling.bootstrap_two_sample
statistics.jackknife = statistics._resampling.jackknife
statistics.jackknife_ci = statistics._resampling.jackknife_ci
statistics.permutation_test = statistics._resampling.permutation_test
statistics.permutation_test_paired = statistics._resampling.permutation_test_paired
statistics.bootstrap_t_test = statistics._resampling.bootstrap_t_test
statistics.bootstrap_var_test = statistics._resampling.bootstrap_var_test
statistics.cross_validation = statistics._resampling.cross_validation
statistics.monte_carlo = statistics._resampling.monte_carlo
statistics.resampling = statistics._resampling

return statistics