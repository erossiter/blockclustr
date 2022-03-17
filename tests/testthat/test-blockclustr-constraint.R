#Simulate data for tests
N <- 100
df <- data.frame(id = stringi::stri_rand_strings(N, 10),
                 pid = sample(c("R", "D"),
                              size = N,
                              replace = T),
                 inc = 20000 * rgamma(N, 1.4, 0.65),
                 age = round(runif(N, 18, 85)))

set.seed(123)
out <- blockclustr(data = df,
                   n_units_per_clust = NA,
                   n_tr = 5,
                   id_var = "id",
                   block_vars = c("age", "inc"),
                   constraint_var = "pid",
                   constraint_list = list(c("D", "D", "R", "R"),
                                          c("D", "D", "D", "R")))

test_that("No duplicated ids after blocking", {
  expect_false(any(duplicated(out$design$id)))
  expect_false(any(duplicated(out$unused_units$id)))
})

test_that("All units accounted for", {
  expect_equal(nrow(out$design) + nrow(out$unused_units), nrow(df))
})


test_that("Expected units per cluster", {
  expect_true(all(table(out$design$cluster_id) == 4))
})

test_that("Expected units per block", {
  expect_true(all(table(out$design$block_id) == 20))
})

test_that("Expected units per treatment", {
  expect_true(all(table(out$design$Z) == 12))
})

test_that("Expected constraint per cluster", {
  tab <- table(out$design$pid, out$design$cluster_id)
  expect_true(all(tab["D",] %in% c(2,3)))
  expect_true(all(tab["R",] %in% c(1,2)))
})
