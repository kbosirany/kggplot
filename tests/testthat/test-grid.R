p1 <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
p2 <- kggplot(iris, "Petal.Length", "Petal.Width", color = "Species")

n_legends <- function(g) {
  gt <- patchwork::patchworkGrob(g)
  i <- grep("guide-box", gt$layout$name)
  sum(vapply(gt$grobs[i], function(x) {
    !inherits(x, "zeroGrob") && length(x$grobs) > 0
  }, logical(1)))
}

test_that("automatic dimensions are as square as possible", {
  d <- function(n, ...) unlist(kgg_grid_dims(n, ...))
  expect_equal(d(1), c(nrow = 1, ncol = 1))
  expect_equal(d(2), c(nrow = 1, ncol = 2))
  expect_equal(d(4), c(nrow = 2, ncol = 2))
  expect_equal(d(5), c(nrow = 2, ncol = 3))
  expect_equal(d(7), c(nrow = 3, ncol = 3))
  expect_equal(d(12), c(nrow = 3, ncol = 4))
  expect_equal(d(6, ratio = 16 / 9), c(nrow = 2, ncol = 3))
  for (n in 1:40) {
    r <- kgg_grid_dims(n)
    expect_gte(r$nrow * r$ncol, n)
    expect_lt((r$nrow - 1) * r$ncol, n)
    expect_lt(r$nrow * (r$ncol - 1), n)
  }
})

test_that("one dimension deduces the other", {
  expect_equal(kgg_grid_dims(5, ncol = 2), list(nrow = 3L, ncol = 2L))
  expect_equal(kgg_grid_dims(5, nrow = 1), list(nrow = 1L, ncol = 5L))
})

test_that("grids too small are rejected", {
  expect_error(kgg_grid_dims(5, nrow = 2, ncol = 2), "do not fit")
  expect_error(kgg_grid(p1, p2, p1, nrow = 1, ncol = 2), "do not fit")
})

test_that("empty rows or columns are reported", {
  expect_warning(kgg_grid_dims(2, nrow = 3, ncol = 2), "2 rows")
  expect_warning(kgg_grid_dims(2, nrow = 2, ncol = 3), "1 column")
  expect_warning(kgg_grid_dims(2, nrow = 3, ncol = 3), "2 rows and 1 column")
  expect_error(kgg_grid_dims(2, nrow = 3, ncol = 2, strict = TRUE), "empty")
  expect_warning(kgg_grid_dims(3, nrow = 2, ncol = 2), NA)
  expect_warning(kgg_grid_dims(3, nrow = 1, ncol = 3, byrow = FALSE), NA)
  expect_warning(kgg_grid_dims(2, nrow = 2, ncol = 2, byrow = FALSE), "column")
})

test_that("invalid inputs are rejected", {
  expect_error(kgg_grid_dims(0), "positive")
  expect_error(kgg_grid_dims(3, nrow = 1.5), "positive")
  expect_error(kgg_grid_dims(3, ratio = -1), "ratio")
  expect_error(kgg_grid(), "No plot")
  expect_error(kgg_grid(1), "Grid elements")
})

test_that("plots can be given individually, as lists or nested", {
  g1 <- kgg_grid(p1, p2, p1)
  g2 <- kgg_grid(list(p1, p2, p1))
  g3 <- kgg_grid(p1, list(p2, list(p1)))
  expect_length(g1$plots, 3)
  expect_equal(g1$nrow, g2$nrow)
  expect_length(g3$plots, 3)
  expect_equal(c(g1$nrow, g1$ncol), c(2, 2))
  g4 <- kgg_grid(p1, as_ggplot(p2))
  expect_length(g4$plots, 2)
})

test_that("a grid renders to a patchwork", {
  g <- as_ggplot(kgg_grid(p1, p2, p1, title = "T", tags = "A"))
  expect_s3_class(g, "patchwork")
  expect_length(g$patches$plots, 2)
  expect_no_error(ggplot2::ggplot_build(g))
})

test_that("identical legends are merged", {
  expect_equal(n_legends(as_ggplot(kgg_grid(p1, p2))), 1)
  expect_equal(n_legends(as_ggplot(kgg_grid(p1, p2, legend = "each"))), 2)
  expect_equal(n_legends(as_ggplot(kgg_grid(p1, p2, legend = "none"))), 0)
})

test_that("a plot without legend does not hide the shared legend", {
  q <- kgg_legend(p2, "none")
  expect_equal(n_legends(as_ggplot(kgg_grid(p1, q))), 1)
})

test_that("named plots get a title and the grid can grow with +", {
  g <- kgg_grid(a = p1, b = p2)
  expect_equal(as_ggplot(g)$patches$plots[[1]]$labels$title, "a")
  g <- suppressWarnings(kgg_grid(p1, p2, ncol = 3)) + p1
  expect_length(g$plots, 3)
  expect_equal(c(g$nrow, g$ncol), c(1, 3))
  expect_error(kgg_grid(p1, p2, nrow = 1, ncol = 2) + p1, "do not fit")
  expect_s3_class(kgg_grid(p1) + kgg_grid(p2), "kgg_grid")
})

test_that("a kggplot is not confused with ggplot2 on +", {
  expect_s3_class(kgg_grid(p1, p2) + list(p1), "kgg_grid")
})
