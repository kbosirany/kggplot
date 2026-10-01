test_that("one call builds a ggplot", {
  p <- kggplot(
    iris, "Sepal.Length", "Sepal.Width", color = "Species",
    title = "Iris", xlab = "Sepal length", ylab = "Sepal width"
  )
  expect_s3_class(p, "kggplot")
  r <- render(p)
  expect_s3_class(r$plot, "ggplot")
  expect_equal(r$plot$labels$title, "Iris")
  expect_equal(r$plot$labels$x, "Sepal length")
  expect_equal(r$plot$labels$colour, "Species")
  expect_equal(nrow(r$built$data[[1]]), nrow(iris))
})

test_that("default axis titles are the variable names", {
  g <- as_ggplot(kggplot(iris, "Sepal.Length", "Sepal.Width"))
  expect_equal(g$labels$x, "Sepal.Length")
  expect_equal(g$labels$y, "Sepal.Width")
})

test_that("NA removes a title", {
  g <- as_ggplot(kggplot(iris, "Sepal.Length", "Sepal.Width", xlab = NA))
  expect_null(g$labels$x)
})

test_that("`vars` list is equivalent to arguments", {
  a <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species"))
  b <- render(kggplot(
    iris, vars = list(x = "Sepal.Length", y = "Sepal.Width", color = "Species")
  ))
  expect_equal(a$built$data[[1]], b$built$data[[1]])
})

test_that("`colour` is an alias of `color`", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", colour = "Species"))
  expect_equal(r$plot$labels$colour, "Species")
})

test_that("multiple y are stacked and coloured by series", {
  r <- render(kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"),
                      type = "line"))
  expect_equal(nrow(r$plot$layers[[1]]$data), 2 * nrow(iris))
  expect_equal(levels(r$plot$layers[[1]]$data$colour),
               c("Sepal.Width", "Petal.Width"))
  expect_null(r$plot$labels$colour)
})

test_that("y = 'all' uses every other column", {
  d <- iris[, 1:4]
  r <- render(kggplot(d, "Sepal.Length", "all"))
  expect_equal(nlevels(r$plot$layers[[1]]$data$.series), 3)
})

test_that("user colour with several y still groups by series", {
  r <- render(kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"),
                      color = "Species", type = "line"))
  d <- r$plot$layers[[1]]$data
  expect_equal(nlevels(d$group), 6)
  expect_equal(r$plot$labels$colour, "Species")
})

test_that("a missing x defaults to the first column, y to the others", {
  d <- data.frame(t = 1:5, a = 1:5, b = 5:1)
  r <- render(kggplot(d))
  expect_equal(r$plot$labels$x, "t")
  expect_equal(nlevels(r$plot$layers[[1]]$data$.series), 2)
})

test_that("univariate types use y as x and ignore y", {
  r <- render(kggplot(iris, y = "Sepal.Length", type = "density"))
  expect_equal(r$plot$labels$x, "Sepal.Length")
  expect_null(r$plot$layers[[1]]$data$y)
})

test_that("type is inferred", {
  geom <- function(p) class(as_ggplot(p)$layers[[1]]$geom)[1]
  expect_equal(geom(kggplot(iris, "Sepal.Length", "Sepal.Width")), "GeomPoint")
  expect_equal(geom(kggplot(AirPassengers)), "GeomLine")
  expect_equal(geom(kggplot(iris, "Sepal.Length")), "GeomBar")
  expect_equal(geom(kggplot(iris, "Species")), "GeomBar")
  d <- data.frame(d = as.Date("2020-01-01") + 0:4, v = 1:5)
  expect_equal(geom(kggplot(d, "d", "v")), "GeomLine")
})

test_that("every built-in type renders", {
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
      kggplot(d, "Sepal.Length", "Sepal.Width", type = type)
    )
    expect_s3_class(render(p)$plot, "ggplot")
  }
})

test_that("fixed values are parameters, not mappings", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width",
                      color = I("red"), size = 3, alpha = 0.5))
  expect_null(r$plot$layers[[1]]$data$colour)
  expect_equal(r$built$data[[1]]$colour[1], "red")
  expect_equal(r$built$data[[1]]$size[1], 3)
})

test_that("unknown columns and types give clear errors", {
  expect_error(kggplot(iris, "nope", "Sepal.Width"), "not found")
  expect_error(kggplot(iris, "Sepal.Length", "Sepal.Width", type = "zzz"),
               "Unknown plot type")
  expect_error(kggplot(iris, "Sepal.Length", "Sepal.Width", theme = "zzz") |>
                 as_ggplot(), "Unknown theme")
})

test_that("geom parameters go through `...`", {
  r <- render(kggplot(iris, "Sepal.Length", type = "histogram", bins = 5))
  expect_equal(nrow(r$built$data[[1]]), 5)
})

test_that("convexhull needs ggConvexHull", {
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
               type = "convexhull")
  if (requireNamespace("ggConvexHull", quietly = TRUE)) {
    expect_s3_class(render(p)$plot, "ggplot")
  } else {
    expect_error(as_ggplot(p), "ggConvexHull")
  }
})
