
<!-- README.md is generated from README.Rmd. Please edit that file -->

# blockclustr

The goal of blockclustr is to allow researchers to easily construct
experimental designs where they have to assign units to clusters
themselves. Usually, cluster randomized experiments are used when the
clusters are naturally occurring, like cities or classrooms. But
sometimes, researchers will bring units together that aren’t naturally
clustered, particularly for experiments involving social interaction.

Since the researcher is already burdened with assigning units to
clusters in these settings, `blockclustr` also implements *blocked*
randomization. In sum, `blockclustr` helps a research assign units to
clusters in a way that increases precision of their estimated causal
effects by simultaneously creating blocked clusters.

## Installation

You can install the `blockclustr` package from Github.

``` r
install.packages("devtools")
devtools::install_github("erossiter/blockclustr")
```

After install, you should load the package.

``` r
library(blockclustr)
```

You’ll also need to install the `blockTools` package. It’s not available
on CRAN, so I recommend installing the latest available version (0.6-3)
from the CRAN mirror on GitHub.

``` r
devtools::install_github("cran/blockTools")
```

## Examples

Constructing an experimental design with `blockclustr` requires
pre-treatment covariate(s). To demonstrate the `blockclustr`
functionality, I’ll simulate for variables for 100 participants:

1.  `id` a unique identifier for each unit
2.  `pid` a string indicating partisanship (either “R” for Republican,
    or “D” for Democrat)
3.  `inc` a numeric indicating income
4.  `age` a numeric indicating age

<!-- end list -->

``` r
set.seed(123)
N <- 100
df <- data.frame(id = stringi::stri_rand_strings(N, 10),
                 pid = sample(c("R", "D"),
                              size = N,
                              replace = T),
                 inc = 20000 * rgamma(N, 1.4, 0.65),
                 age = round(runif(N, 18, 85)))
```

### Two arm design with two units per cluster

We’ll first construct a design with two units per cluster, and two
clusters per block. We’ll block on `age` and `income`.

``` r
twoarm <- blockclustr(data = df,
                      n_units_per_clust = 2,
                      n_tr = 2,
                      id_var = "id",
                      block_vars = c("age", "inc"))
#> Warning: `is.tibble()` was deprecated in tibble 2.0.0.
#> Please use `is_tibble()` instead.
```

By looking at the first few rows of the design, we can see each block
has two clusters, each cluster has two units, and each cluster within a
block is assigned to a different experimental condition.

``` r
head(twoarm$design, n = 8)
#>           id block_id cluster_id pid        inc age  Z
#> 1 Y9x2Nxe3PQ        1          1   D   2881.875  78 Z1
#> 2 EgEJAn9pKN        1          1   D  65844.805  31 Z1
#> 3 qI9h62z2Ku        1          2   D 134261.317  49 Z2
#> 4 m0mjdT90SU        1          2   D  67916.095  27 Z2
#> 5 dBrkfcNWsa        2          3   R  62859.767  57 Z2
#> 6 XdaJtcIO9r        2          3   R  11484.625  73 Z2
#> 7 ctfjWeomyR        2          4   R  60805.065  58 Z1
#> 8 l8OD3O4E3f        2          4   R   8293.954  76 Z1
```

### Increasing experimental conditions and cluster size

It is simple to move beyond a two-arm design or two units per cluster by
specifying the `n_tr` and `n_units_per_clust` parameters.

``` r
multiarm <- blockclustr(data = df,
                        n_units_per_clust = 4,
                        n_tr = 3,
                        id_var = "id",
                        block_vars = c("age", "inc"))

head(multiarm$design, n = 16)
#>            id block_id cluster_id pid       inc age  Z
#> 1  z8uZORh5Lg        1          1   R 74054.912  85 Z1
#> 2  kdi0TDNbL6        1          1   D 22233.430  68 Z1
#> 3  s04AljyS4e        1          1   R 52950.177  20 Z1
#> 4  5oQkfRc0Dh        1          1   D 33137.969  84 Z1
#> 5  antN5ck5Ic        1          2   D 76985.168  84 Z3
#> 6  yUOP5APLPI        1          2   R 21827.707  65 Z3
#> 7  wgRo2jLpXH        1          2   R 37606.597  19 Z3
#> 8  KCZtWafWV1        1          2   R 36170.025  85 Z3
#> 9  cQX3GOCp9n        1          3   R 86517.102  82 Z2
#> 10 1W5HQaoCSR        1          3   R 15744.352  65 Z2
#> 11 vXDUnP6HMG        1          3   D 73397.865  19 Z2
#> 12 W3y75sVKt1        1          3   D 29649.449  84 Z2
#> 13 f5NHoRoonR        2          4   R 20218.827  51 Z3
#> 14 l8OD3O4E3f        2          4   R  8293.954  76 Z3
#> 15 QLrSXxmCJy        2          4   R 58038.195  49 Z3
#> 16 TFDf2hLPou        2          4   R 29838.935  74 Z3
```

### Including a cluster constraint

Next we can construct a similar design, but constrain the clusters to
have certain partisan makeups. For example, below I construct a design
where there are four units per cluster, but each cluster must contain a
partisan majority and minority (3 Republicans and 1 Democrat or vice
versa).

Note that when implementing a clustering constraint, the number of units
per cluster will simply be determined by the length of the elements of
the `constraint_list` parameter.

``` r
multiarm_cons <- blockclustr(data = df,
                             n_units_per_clust = NA,
                             n_tr = 3,
                             id_var = "id",
                             block_vars = c("age", "inc"),
                             constraint_var = "pid",
                             constraint_list = list(c("R", "R", "R", "D"),
                                                    c("D", "D", "D", "R")))

head(multiarm_cons$design, n = 24)
#>            id block_id cluster_id pid       inc age  Z
#> 1  n5pHkx5qnN        1          1   D  20281.71  19 Z3
#> 2  ExbVOsMHAA        1          1   R  50831.46  67 Z3
#> 3  s04AljyS4e        1          1   R  52950.18  20 Z3
#> 4  alNlXuBH5D        1          1   R  94676.68  67 Z3
#> 5  xjb7YGt0E8        1          2   D  25257.80  19 Z1
#> 6  qUOF6OZDRD        1          2   R  51185.93  66 Z1
#> 7  2Rn7YC7ktN        1          2   R  61917.92  21 Z1
#> 8  I64skoy66n        1          2   R 108593.34  80 Z1
#> 9  vsfwWZKL1V        1          3   D  31882.77  31 Z2
#> 10 0lSifZheH6        1          3   R  57987.96  65 Z2
#> 11 wgRo2jLpXH        1          3   R  37606.60  19 Z2
#> 12 lqSj6DxkoP        1          3   R 145591.74  81 Z2
#> 13 eJJDMz958g        2          4   D  32659.02  36 Z2
#> 14 FfPm6QztsA        2          4   D  32963.89  69 Z2
#> 15 gJbzk4R3Lj        2          4   R  23154.10  31 Z2
#> 16 OSi3LnpELr        2          4   D  26899.80  50 Z2
#> 17 qn7iE4w9eA        2          5   D  39281.09  33 Z1
#> 18 2vlCeeOoXs        2          5   D  32475.95  69 Z1
#> 19 VLeNMXjDPG        2          5   R  13774.40  26 Z1
#> 20 kuTZjru3VL        2          5   D  26869.65  49 Z1
#> 21 YuaQwhP1ZU        2          6   D  49124.04  39 Z3
#> 22 JP0BqEE4Fj        2          6   D  32897.46  67 Z3
#> 23 uofo7FKPdo        2          6   R  36653.61  46 Z3
#> 24 qG1rKdXNBQ        2          6   D  30297.37  47 Z3
```
