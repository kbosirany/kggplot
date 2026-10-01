test_that("+ superposes two kggplots with a shared legend and palette", {
  p <- kggplot(obs, "t", "v", color = "Observed", type = "point",
               theme = "inrae") +
    kggplot(sim, "t", "v", color = "Simulated", type = "line")
  expect_length(p$layers, 2)
  r <- render(p)
  expect_length(r$plot$layers, 2)
  cols <- unique(c(r$built$data[[1]]$colour, r$built$data[[2]]$colour))
  expect_equal(sort(cols), sort(c("#00a3a6", "#9dc544")))
  expect_equal(r$built$data[[1]]$colour[1], "#00a3a6")
  expect_equal(r$built$data[[2]]$colour[1], "#9dc544")
})

test_that("right-hand settings override, left ones are kept otherwise", {
  p <- kggplot(obs, "t", "v", title = "A", theme = "bw") +
    kggplot(sim, "t", "v", title = "B")
  expect_equal(p$labels$title, "B")
  expect_equal(p$theme, "bw")
})

test_that("kggplot(p, data) and kgg_add() add a layer", {
  p <- kggplot(obs, "t", "v", color = "Observed")
  expect_length(kggplot(p, sim, color = "Simulated")$layers, 2)
  expect_length(kgg_add(p, sim, color = "Simulated")$layers, 2)
  q <- kgg_add(p, sim, color = "Simulated", type = "line")
  expect_s3_class(render(q)$plot, "ggplot")
})

test_that("kgg_add() inherits mappings and reuses the data", {
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species") |>
    kgg_add(type = "smooth")
  r <- render(p)
  expect_equal(r$plot$labels$colour, "Species")
  expect_equal(
    as.character(unique(r$plot$layers[[2]]$data$colour)), levels(iris$Species)
  )
})

test_that("ggplot2 components are stored and applied last", {
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width", theme = "minimal") +
    ggplot2::theme_bw() +
    ggplot2::geom_hline(yintercept = 3) +
    ggplot2::labs(title = "From ggplot2")
  expect_s3_class(p, "kggplot")
  expect_length(p$extras, 3)
  r <- render(p)
  expect_equal(r$plot$labels$title, "From ggplot2")
  expect_length(r$plot$layers, 2)
})

test_that("modifiers are chainable and leave the original untouched", {
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
  q <- p |>
    kgg_labs(title = "T", color = "Sp") |>
    kgg_theme("bw", base_size = 14) |>
    kgg_facet("Species", scales = "free") |>
    kgg_legend("bottom")
  expect_null(p$theme)
  g <- as_ggplot(q)
  expect_equal(g$labels$title, "T")
  expect_equal(g$labels$colour, "Sp")
  expect_equal(g$theme$legend.position, "bottom")
  expect_s3_class(g$facet, "FacetWrap")
  expect_s3_class(ggplot2::ggplot_build(g), "ggplot_built")
})

test_that("print, plot, autoplot and save work", {
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width")
  pdf(NULL)
  on.exit(dev.off())
  expect_invisible(print(p))
  expect_invisible(plot(p))
  expect_s3_class(ggplot2::autoplot(p), "ggplot")
  f <- tempfile(fileext = ".png")
  kgg_save(p, f, width = 3, height = 3)
  expect_true(file.exists(f))
})

test_that("facets accept one variable, two variables or a formula", {
  f <- function(...) as_ggplot(kggplot(mtcars, "mpg", "wt", ...))$facet
  expect_s3_class(f(facet = "cyl"), "FacetWrap")
  expect_s3_class(f(facet = c("cyl", "am")), "FacetGrid")
  expect_s3_class(f(facet = ~cyl), "FacetWrap")
  expect_s3_class(f(facet = am ~ cyl), "FacetGrid")
  expect_error(as_ggplot(kggplot(mtcars, "mpg", "wt", facet = letters[1:3])))
  p <- kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"),
               facet = ".series")
  expect_s3_class(render(p)$plot$facet, "FacetWrap")
})

test_that("legend can be hidden or moved", {
  g <- function(l) {
    as_ggplot(kggplot(
      iris, "Sepal.Length", "Sepal.Width", color = "Species", legend = l
    ))
  }
  expect_equal(g(FALSE)$theme$legend.position, "none")
  expect_equal(g("top")$theme$legend.position, "top")
  expect_s3_class(render(kggplot(iris, "Sepal.Length", "Sepal.Width",
                                 color = "Species", legend = c(0.9, 0.9)))$plot,
                  "ggplot")
})
