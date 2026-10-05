# Extracted from test-kggplot.R:107

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "kggplot", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
for (type in setdiff(kgg_types(), "convexhull")) {
    d <- iris
    p <- switch(
      type,
      boxplot = , violin = kggplot(d, "Species", "Sepal.Length", type = type),
      bar = , col = , bar_dodge = kggplot(
        data.frame(g = c("a", "b"), v = 1:2), "g", "v", type = type
      ),
      text = kggplot(d, "Sepal.Length", "Sepal.Width", label = "Species",
                     type = type),
      count = kggplot(d, "Species", type = type),
      ribbon = , errorbar = , pointrange = {
        d$lo <- d$Sepal.Width - 0.1
        d$hi <- d$Sepal.Width + 0.1
        kggplot(d, "Sepal.Length", "Sepal.Width", ymin = "lo", ymax = "hi",
                type = type)
      },
      hline = kggplot(d, yintercept = "Sepal.Width", type = type),
      vline = kggplot(d, xintercept = "Sepal.Length", type = type),
      kggplot(d, "Sepal.Length", "Sepal.Width", type = type)
    )
    expect_s3_class(render(p)$plot, "ggplot")
  }
