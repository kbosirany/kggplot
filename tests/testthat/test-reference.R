# unnamed: ggplot2 4 names its layers
geoms <- function(g) {
  unname(vapply(g$layers, function(l) class(l$geom)[1L], ""))
}

test_that("the new types are registered", {
  expect_true(all(
    c("ribbon", "pointrange", "errorbar", "hline", "vline", "blank") %in%
      kgg_types()
  ))
})

test_that("the figure of issue #7 is built with kggplot() and + only", {
  g <- as_ggplot(issue_figure())
  expect_equal(
    geoms(g),
    c("GeomRibbon", "GeomLine", "GeomCol", "GeomPointrange", "GeomHline",
      "GeomVline", "GeomBlank")
  )
  b <- ggplot2::ggplot_build(g)
  expect_s3_class(g$facet, "FacetGrid")
  expect_equal(g$theme$strip.placement, "outside")
  expect_equal(g$theme$legend.position, "bottom")
  # no axis nor legend title
  expect_null(g$labels$x)
  expect_null(g$labels$y)
  expect_null(g$labels$colour)
  expect_null(g$labels$fill)
})

test_that("the panels and their order are shared by all the layers", {
  d <- issue_data()
  b <- ggplot2::ggplot_build(as_ggplot(issue_figure()))
  lay <- b$layout$layout
  expect_equal(as.character(lay$panel), d$panels)
  expect_equal(as.integer(lay$PANEL), 1:3)
  # every layer drawn in panels that exist
  for (ld in b$data) expect_true(all(ld$PANEL %in% lay$PANEL))
  # irrigation bars only in the third panel, observations in the first
  expect_equal(unique(as.integer(b$data[[3]]$PANEL)), 3L)
  expect_equal(unique(as.integer(b$data[[4]]$PANEL)), 1L)
})

test_that("series keep their colours across layers", {
  d <- issue_data()
  b <- ggplot2::ggplot_build(as_ggplot(issue_figure()))
  ribbon <- unique(b$data[[1]][, c("fill", "group")])
  line <- unique(b$data[[2]][, c("colour", "group")])
  bars <- unique(b$data[[3]][, c("fill", "group")])
  expect_setequal(ribbon$fill, unname(d$colors))
  expect_setequal(line$colour, unname(d$colors))
  expect_setequal(bars$fill, unname(d$colors))
  # the same group (series) has the same colour in the ribbon and the line
  expect_equal(
    ribbon$fill[order(ribbon$group)], line$colour[order(line$group)]
  )
  # ribbon: alpha 0.2 and no outline; observations are black
  expect_equal(unique(b$data[[1]]$alpha), 0.2)
  expect_true(all(is.na(b$data[[1]]$colour)))
  expect_equal(unique(b$data[[4]]$colour), "black")
})

test_that("the limits layer forces the range of one panel only", {
  free <- ggplot2::ggplot_build(as_ggplot(issue_figure(limits = FALSE)))
  forced <- ggplot2::ggplot_build(as_ggplot(issue_figure()))
  range <- function(b, i) b$layout$panel_params[[i]]$y.range
  # without the limits the ratio panel is narrower than [0, 1]
  expect_gt(range(free, 2)[1], 0)
  expect_lt(range(free, 2)[2], 1)
  # with them, it contains [0, 1]
  expect_lte(range(forced, 2)[1], 0)
  expect_gte(range(forced, 2)[2], 1)
  # the other panels are untouched
  expect_equal(range(forced, 1), range(free, 1))
  expect_equal(range(forced, 3), range(free, 3))
})

test_that("reference lines target one facet or all of them", {
  b <- ggplot2::ggplot_build(as_ggplot(issue_figure()))
  # threshold: the second panel only
  expect_equal(as.integer(b$data[[5]]$PANEL), 2L)
  expect_equal(b$data[[5]]$yintercept, 0.4)
  expect_equal(b$data[[5]]$linetype, "dashed")
  expect_equal(b$data[[5]]$colour, "grey40")
  # decision dates: every panel
  v <- b$data[[6]]
  expect_equal(sort(unique(as.integer(v$PANEL))), 1:3)
  expect_equal(nrow(v), 9L)
  expect_equal(v$linetype[1], "dotted")
})

test_that("reference lines add no axis aesthetic or title", {
  h <- resolve_layer(kgg_hline(0.4)$layers[[1]])
  expect_setequal(h$aes, "yintercept")
  v <- resolve_layer(kgg_vline(as.Date("2024-05-10"))$layers[[1]])
  expect_setequal(v$aes, "xintercept")
  expect_length(h$labels, 0)
  p <- kggplot(iris, "Sepal.Length", "Sepal.Width") + kgg_hline(3)
  g <- as_ggplot(p)
  expect_equal(g$labels$x, "Sepal.Length")
  expect_equal(g$labels$y, "Sepal.Width")
  # a reference line first does not decide the titles either
  g2 <- as_ggplot(kgg_hline(3) + kggplot(iris, "Sepal.Length", "Sepal.Width"))
  expect_equal(g2$labels$y, "Sepal.Width")
})

test_that("kgg_hline() and kgg_vline() check their arguments", {
  df <- data.frame(panel = "a", y = 1)
  expect_error(kgg_hline(0.4, data = df), "name of one of its columns")
  expect_error(kgg_hline("nope", data = df), "name of one of its columns")
  expect_error(as_ggplot(kggplot(df, type = "hline")), "needs `yintercept`")
})

test_that("kgg_limits() builds a blank layer", {
  l <- kgg_limits(panel = "A", y = c(0, 1), x = c(5, 6))
  r <- resolve_layer(l$layers[[1]], keep = "panel")
  expect_equal(r$data$y, c(0, 1))
  expect_equal(r$data$x, c(5, 6))
  expect_equal(as.character(r$data$panel), c("A", "A"))
  expect_error(kgg_limits(y = 1:2, "A"), "by name")
  expect_error(kgg_limits(panel = "A"), "limits to force")
})

test_that("ymin and ymax follow y, also with several y columns", {
  d <- data.frame(
    t = 1:5, a = 1:5, b = 5:1, a_lo = 0:4, a_hi = 2:6, b_lo = 4:0, b_hi = 6:2
  )
  p <- kggplot(d, "t", c("a", "b"), ymin = c("a_lo", "b_lo"),
               ymax = c("a_hi", "b_hi"), type = "ribbon")
  r <- resolve_layer(p$layers[[1]])
  expect_equal(r$data$ymin, c(d$a_lo, d$b_lo))
  expect_equal(r$data$ymax, c(d$a_hi, d$b_hi))
  expect_equal(r$data$y, c(d$a, d$b))
  expect_equal(levels(r$data$fill), c("a", "b"))
  expect_length(r$params, 0)
  expect_s3_class(ggplot2::ggplot_build(as_ggplot(p)), "ggplot_built")

  # one band column for every series
  d$w <- 0.5
  p1 <- kggplot(d, "t", c("a", "b"), ymin = "a_lo", ymax = "a_hi",
                type = "ribbon")
  expect_equal(resolve_layer(p1$layers[[1]])$data$ymin, rep(d$a_lo, 2))
  expect_error(
    kggplot(d, "t", c("a", "b"), ymin = c("a_lo", "b_lo", "w"), ymax = "a_hi",
            type = "ribbon") |> as_ggplot(),
    "one column per"
  )
})

test_that("a band needs no y and the type is guessed", {
  d <- data.frame(t = 1:5, lo = 0:4, hi = 2:6, y = 1:5)
  g <- function(...) as_ggplot(kggplot(d, "t", ymin = "lo", ymax = "hi", ...))
  expect_equal(geoms(g()), "GeomRibbon")
  expect_equal(geoms(g(y = "y")), "GeomPointrange")
  expect_error(kggplot(d, "t", "y", type = "ribbon") |> as_ggplot(), NA)
  expect_error(kggplot(d, "t", type = "point") |> as_ggplot(), "needs a `y`")
})

test_that("the defaults of a type give way to a mapped aesthetic", {
  d <- data.frame(t = 1:4, y = 1:4, lo = 0:3, hi = 2:5,
                  g = c("a", "a", "b", "b"))
  black <- ggplot2::ggplot_build(as_ggplot(
    kggplot(d, "t", "y", ymin = "lo", ymax = "hi", type = "pointrange")
  ))
  expect_equal(unique(black$data[[1]]$colour), "black")
  mapped <- ggplot2::ggplot_build(as_ggplot(
    kggplot(d, "t", "y", ymin = "lo", ymax = "hi", color = "g",
            type = "pointrange")
  ))
  expect_length(unique(mapped$data[[1]]$colour), 2)
})

test_that("layers with their own data keep the same panels", {
  lv <- c("C", "A", "B")
  a <- data.frame(
    t = 1:3, v = 1:3, panel = factor(c("A", "B", "C"), levels = lv)
  )
  b <- data.frame(t = 1:2, v = c(3, 4), panel = c("B", "A")) # character
  b2 <- data.frame(t = 1:2, v = c(3, 4),
                   panel = factor(c("B", "A"), levels = c("B", "A")))
  for (second in list(b, b2)) {
    p <- kggplot(a, "t", "v", facet = "panel") +
      kggplot(second, "t", "v", type = "line")
    lay <- ggplot2::ggplot_build(as_ggplot(p))$layout$layout
    expect_equal(as.character(lay$panel), lv)
  }
  # a value only present in a later layer gets its own, last, panel
  extra <- data.frame(t = 1, v = 1, panel = "D")
  p <- kggplot(a, "t", "v", facet = "panel") + kggplot(extra, "t", "v")
  lay <- ggplot2::ggplot_build(as_ggplot(p))$layout$layout
  expect_equal(as.character(lay$panel), c(lv, "D"))
})

test_that("series colours are shared even when levels differ between layers", {
  a <- data.frame(
    t = 1:3, v = 1:3, s = factor(c("x", "y", "x"), levels = c("x", "y"))
  )
  b <- data.frame(
    t = 1:3, v = 3:1, s = factor(c("y", "z", "y"), levels = c("z", "y"))
  )
  p <- kggplot(a, "t", "v", color = "s", palette = c("red", "green", "blue")) +
    kggplot(b, "t", "v", color = "s", type = "line")
  built <- ggplot2::ggplot_build(as_ggplot(p))
  col <- function(i, lab) {
    d <- built$data[[i]]
    unique(d$colour)
  }
  # x, y from the first layer, z appended: x red, y green, z blue
  expect_setequal(col(1), c("red", "green"))
  expect_setequal(col(2), c("green", "blue"))
})

test_that("`switch` puts the strips outside", {
  g <- as_ggplot(kggplot(mtcars, "mpg", "wt", facet = cyl ~ .,
                         facet_args = list(switch = "y")))
  expect_equal(g$theme$strip.placement, "outside")
  g2 <- as_ggplot(kggplot(mtcars, "mpg", "wt", facet = "cyl"))
  expect_null(g2$theme$strip.placement)
})

test_that("positional aesthetics are matched exactly", {
  # `$` would match `xintercept` for `x` and `yintercept` for `y`
  r <- resolve_layer(kgg_hline(0.4)$layers[[1]])
  expect_false("y" %in% names(r$data))
  expect_false("x" %in% names(r$data))
})
