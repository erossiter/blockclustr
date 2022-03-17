
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
set.seed(7127)
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
head(twoarm$design)
#>           id block_id cluster_id pid       inc age  Z
#> 1 OnJXFchqc8        1          1   R 44948.549  67 Z1
#> 2 Vd6mM9J8xQ        1          1   R 20273.623  61 Z1
#> 3 rEUc89OylA        1          2   D 44260.593  66 Z2
#> 4 43lmpOAKY0        1          2   R 20807.236  61 Z2
#> 5 Oxlp9wq7Fz        2          3   R  4337.587  82 Z2
#> 6 37KVqxdSeb        2          3   D 28427.700  69 Z2
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

head(multiarm$design)
#>           id block_id cluster_id pid       inc age  Z
#> 1 ANb3EXJCI6        1          1   R  5642.655  44 Z1
#> 2 Rl5eW1F3f5        1          1   R 18054.641  32 Z1
#> 3 cQhAZh2UO2        1          1   R 74939.915  40 Z1
#> 4 shScMMgB2H        1          1   D 53864.411  36 Z1
#> 5 doInMAkWys        1          2   D  1883.210  44 Z2
#> 6 JICg8wcglx        1          2   D  5992.299  25 Z2
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

head(multiarm_cons$design)
#>           id block_id cluster_id pid       inc age  Z
#> 1 8Xyrr1KyhJ        1          1   D  88697.23  56 Z1
#> 2 Vd6mM9J8xQ        1          1   R  20273.62  61 Z1
#> 3 xjmn1Xo6iu        1          1   R  54017.56  48 Z1
#> 4 NunxvKsCti        1          1   R  39896.66  57 Z1
#> 5 fYYxr2VBgn        1          2   D 141820.79  36 Z3
#> 6 rlGrRl5MKD        1          2   R  29056.71  62 Z3
```
