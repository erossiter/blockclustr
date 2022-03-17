#Simulate data for tests
N <- 100
df <- data.frame(id = stringi::stri_rand_strings(N, 10),
                 pid = sample(c("R", "D"),
                              size = N,
                              replace = T),
                 inc = 20000 * rgamma(N, 1.4, 0.65),
                 age = round(runif(N, 18, 85)))


test_that("Throws error: variable names not in data", {
  expect_error(blockclustr(data = df,
                           n_units_per_clust = 5,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc", "height")),
               regexp = "not in data")
})

test_that("Throws error: missing data", {
  df$inc[1] <- NA
  expect_error(blockclustr(data = df,
                           n_units_per_clust = 5,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc")),
               regexp = "Missing data")
})

test_that("Throws error: non-numeric block var", {
  df$inc <- as.character(df$inc)
  expect_error(blockclustr(data = df,
                           n_units_per_clust = 5,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc")),
               regexp = "Non-numeric")
})

test_that("Throws error: non-unique ids", {
  df$id[1:2] <- c("1", "1")
  expect_error(blockclustr(data = df,
                           n_units_per_clust = 5,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc")),
               regexp = "Non-unique")
})

test_that("Throws error: specify both constraint params", {
  expect_error(blockclustr(data = df,
                           n_units_per_clust = NA,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc"),
                           constraint_list = list(c("R", "D"))),
               regexp = "both be specified")

  expect_error(blockclustr(data = df,
                           n_units_per_clust = NA,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc"),
                           constraint_var = "pid"),
               regexp = "both be specified")
})

test_that("Throws error: constraint_list values not in list", {
  expect_error(blockclustr(data = df,
                           n_units_per_clust = NA,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc"),
                           constraint_var = "pid",
                           constraint_list = list(c("R", "D", "I"))),
               regexp = "not in 'constraint_var")
})

test_that("Throws warning: n_units_per_clust not used", {
  expect_warning(blockclustr(data = df,
                           n_units_per_clust = 2,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc"),
                           constraint_var = "pid",
                           constraint_list = list(c("R", "D"))),
               regexp = "will not be used")
})

test_that("Throws error: constraint_list values not in list", {
  expect_error(blockclustr(data = df,
                           n_units_per_clust = NA,
                           n_tr = 3,
                           id_var = "id",
                           block_vars = c("age", "inc"),
                           constraint_var = "pid",
                           constraint_list = c("R", "D")),
               regexp = "not a list")
})
