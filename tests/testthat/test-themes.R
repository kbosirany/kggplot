test_that("registered theme applies its palette", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                      theme = "inrae"))
  expect_equal(
    unique(r$built$data[[1]]$colour), c("#00a3a6", "#9dc544", "#423089")
  )
})

test_that("palette argument overrides the theme palette", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                      theme = "inrae", palette = c("red", "green", "blue")))
  expect_equal(unique(r$built$data[[1]]$colour), c("red", "green", "blue"))
  r2 <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                       palette = "okabe_ito"))
  expect_equal(unique(r2$built$data[[1]]$colour)[1], "#E69F00")
})

test_that("a named palette fixes the colour of each level", {
  pal <- c(virginica = "red", setosa = "blue", versicolor = "green")
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                      palette = pal))
  d <- r$built$data[[1]]
  expect_equal(d$colour[iris$Species == "setosa"][1], "blue")
})

test_that("palettes are interpolated beyond their length", {
  d <- data.frame(x = 1:12, y = 1:12, g = letters[1:12])
  r <- render(kggplot(d, "x", "y", color = "g", palette = c("red", "blue")))
  expect_length(unique(r$built$data[[1]]$colour), 12)
})

test_that("a palette can be a function", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                      palette = function(n) rep("black", n)))
  expect_equal(unique(r$built$data[[1]]$colour), "black")
})

test_that("continuous colours use a gradient", {
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width",
                      color = "Petal.Length", theme = "inrae"))
  expect_s3_class(r$plot$scales$get_scales("colour"), "ScaleContinuous")
})

test_that("themes can be names, theme_*() lookups, objects or functions", {
  expect_s3_class(resolve_theme("bw")$theme, "theme")
  expect_error(resolve_theme("no_such_theme"), "Unknown theme")
  expect_s3_class(resolve_theme(ggplot2::theme_bw())$theme, "theme")
  expect_s3_class(resolve_theme(ggplot2::theme_bw, 20)$theme, "theme")
  expect_equal(resolve_theme("bw", 20)$theme$text$size, 20)
  # theme_<name> picked up from the search path
  theme_kggplot_test <- function(...) ggplot2::theme_void(...)
  assign("theme_kggplot_test", theme_kggplot_test, envir = globalenv())
  on.exit(rm("theme_kggplot_test", envir = globalenv()))
  expect_s3_class(resolve_theme("kggplot_test")$theme, "theme")
})

test_that("options set the defaults", {
  old_opts <- options(kggplot.theme = "bw", kggplot.palette = "okabe_ito")
  on.exit(options(old_opts))
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species"))
  expect_equal(unique(r$built$data[[1]]$colour)[1], "#E69F00")
})

test_that("custom themes, palettes and types can be registered", {
  kgg_register_palette("tp", c("#111111", "#222222", "#333333"))
  kgg_register_theme("tt", ggplot2::theme_bw, palette = "tp")
  kgg_register_type("hollow", ggplot2::geom_point, params = list(shape = 1))
  expect_true("tp" %in% kgg_palettes())
  expect_true("tt" %in% kgg_themes())
  expect_true("hollow" %in% kgg_types())
  r <- render(kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
                      theme = "tt", type = "hollow"))
  expect_equal(
    unique(r$built$data[[1]]$colour), c("#111111", "#222222", "#333333")
  )
  expect_equal(r$built$data[[1]]$shape[1], 1)
})

test_that("get_color_palette works as before", {
  expect_equal(
    get_color_palette(
      c("A", "B", "C"), main_colors = c("red", "green", "blue")
    ),
    c(A = "red", B = "green", C = "blue")
  )
  expect_equal(
    names(get_color_palette(c("a", "b"), theme = "inrae")), c("a", "b")
  )
  expect_error(get_color_palette("a"), "theme")
  expect_length(get_color_palette(1:10, main_colors = c("red", "blue")), 10)
})
