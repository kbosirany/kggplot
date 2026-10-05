# secondary y axis
y2_data <- function(n = 50) {
  d <- data.frame(day = seq_len(n))
  d$lai <- 5 * sin(d$day / 16)
  d$yield <- 40 + 3 * d$day
  d$other <- -2 + 0.01 * d$day^2
  d
}

# the map of a plot: the transformed values of the series of the right axis
get_map <- function(p) {
  res <- lapply(p$layers, resolve_layer)
  apply_y2(res)$map
}

sec_axis_of <- function(g) {
  sc <- ggplot2::ggplot_build(g)$plot$scales$get_scales("y")
  sc$secondary.axis
}

test_that("y2 draws a secondary axis", {
  p <- kggplot(y2_data(), "day", "lai", y2 = "yield", type = "line")

  r <- render(p)

  expect_s3_class(r$plot, "ggplot")

  expect_false(is.null(sec_axis_of(r$plot)))

  # the axis titles are the names of the series
  expect_equal(r$plot$labels$y, "lai")
})

test_that("the series of y2 are mapped onto the range of the primary axis", {
  d <- y2_data()

  p <- kggplot(d, "day", "lai", y2 = "yield", type = "line")

  res <- lapply(p$layers, resolve_layer)

  out <- apply_y2(res)

  data <- out$res[[1]]$data

  sec <- data$y[data$.series == "yield"]

  prim <- data$y[data$.series == "lai"]

  # the same minimum and maximum
  expect_equal(range(sec), range(prim))

  # the map is exact: the original values come back
  expect_equal((sec - out$map$a) / out$map$b, d$yield)

  # the primary series is not changed
  expect_equal(prim, d$lai)
})

test_that("the labels of the secondary axis are exact", {
  skip_if_not(utils::packageVersion("ggplot2") >= "3.5.0")

  d <- y2_data()

  p <- kggplot(d, "day", "lai", y2 = "yield", type = "line")

  b <- ggplot2::ggplot_build(as_ggplot(p))

  guide <- ggplot2::get_guide_data(b, "y.sec")

  map <- get_map(p)

  # the position of a break is the map of its label
  expect_equal(map$a + map$b * as.numeric(guide$.label), guide$.value)
})

test_that("several series on both axes", {
  d <- y2_data()

  p <- kggplot(d, "day", c("lai"), y2 = c("yield", "other"), type = "line")

  r <- render(p)

  data <- r$built$data[[1]]

  expect_equal(length(unique(data$group)), 3)

  # both are on the right axis, with the same map
  expect_equal(r$plot$labels$y, "lai")

  p <- kggplot(d, "day", y = c("lai", "other"), y2 = "yield", type = "line")

  expect_s3_class(render(p)$plot, "ggplot")

  # y = "all" is every other column
  p <- kggplot(d, "day", y = "all", y2 = "yield", type = "line")

  res <- lapply(p$layers, resolve_layer)

  expect_equal(res[[1]]$y2, "yield")

  expect_setequal(unique(as.character(res[[1]]$data$.series)),
                  c("lai", "other", "yield"))

  # without x and y: the first column against the others, y2 on the right
  p <- kggplot(d, y2 = "yield", type = "line")

  expect_s3_class(render(p)$plot, "ggplot")
})

test_that("degenerate series do not break the map", {
  d <- y2_data()

  # constant secondary series: centred on the primary range
  d$const <- 7

  map <- get_map(kggplot(d, "day", "lai", y2 = "const", type = "line"))

  expect_equal(map$b, 1)

  expect_equal(map$a + 7, mean(range(d$lai)))

  expect_s3_class(
    render(kggplot(d, "day", "lai", y2 = "const", type = "line"))$plot,
    "ggplot"
  )

  # constant primary series
  d$flat <- 3

  expect_s3_class(
    render(kggplot(d, "day", "flat", y2 = "yield", type = "line"))$plot,
    "ggplot"
  )

  map <- get_map(kggplot(d, "day", "flat", y2 = "yield", type = "line"))

  expect_true(is.finite(map$a) && is.finite(map$b) && map$b > 0)

  # both constant
  expect_s3_class(
    render(kggplot(d, "day", "flat", y2 = "const", type = "line"))$plot,
    "ggplot"
  )

  # missing and infinite values are ignored by the map
  d$na <- d$yield

  d$na[c(3, 10)] <- NA

  d$na[5] <- Inf

  r <- suppressWarnings(
    render(kggplot(d, "day", "lai", y2 = "na", type = "line"))
  )

  expect_s3_class(r$plot, "ggplot")

  map <- get_map(kggplot(d, "day", "lai", y2 = "na", type = "line"))

  expect_true(is.finite(map$b))

  # a series that is all missing
  d$empty <- NA_real_

  expect_no_error(
    suppressWarnings(render(kggplot(d, "day", "lai", y2 = "empty", type = "line")))
  )

  # negative values, and very different magnitudes
  d$tiny <- d$lai * 1e-9

  d$huge <- d$lai * 1e9

  for (col in c("tiny", "huge", "other")) {
    p <- kggplot(d, "day", "yield", y2 = col, type = "line")

    map <- get_map(p)

    expect_true(is.finite(map$a) && is.finite(map$b) && map$b > 0)

    expect_s3_class(render(p)$plot, "ggplot")
  }

  # integers
  d$int <- seq_len(nrow(d))

  expect_s3_class(
    render(kggplot(d, "day", "lai", y2 = "int", type = "point"))$plot,
    "ggplot"
  )
})

test_that("other layers add series to the secondary axis", {
  d <- y2_data()

  other <- data.frame(day = d$day, rain = 10 * (d$day %% 7 == 0))

  p <- kggplot(d, "day", "lai", type = "line") +
    kggplot(other, "day", y2 = "rain", type = "point")

  r <- render(p)

  expect_equal(r$plot$labels$y, "lai")

  # the map covers all the layers together
  res <- lapply(p$layers, resolve_layer)

  out <- apply_y2(res)

  rain <- out$res[[2]]$data$y

  expect_equal(range(rain), range(d$lai))

  # a layer of the right axis with its own y2 and a primary one
  p2 <- kggplot(d, "day", "lai", y2 = "yield", type = "line") +
    kggplot(other, "day", y2 = "rain", type = "point")

  expect_s3_class(render(p2)$plot, "ggplot")

  expect_equal(get_map(p2)$b > 0, TRUE)
})

test_that("facets share the map", {
  d <- rbind(
    transform(y2_data(), g = "a"),
    transform(y2_data(), g = "b", lai = lai * 2)
  )

  for (scales in c("fixed", "free_y")) {
    p <- kggplot(
      d, "day", "lai", y2 = "yield", type = "line", facet = "g",
      facet_args = list(scales = scales)
    )

    r <- render(p)

    expect_s3_class(r$plot, "ggplot")

    expect_false(is.null(sec_axis_of(r$plot)))
  }
})

test_that("the types that cannot take a secondary axis are refused", {
  d <- y2_data()

  expect_error(
    kggplot(d, "day", "lai", y2 = "yield", type = "bar"),
    "plot types"
  )

  expect_error(
    kggplot(d, "day", "lai", y2 = "yield", type = "area"),
    "plot types"
  )

  expect_error(
    kggplot(d, "day", "lai", y2 = "yield", type = ggplot2::geom_line),
    "plot types"
  )

  # the type is guessed: numeric x and y give points, which are accepted
  expect_s3_class(
    render(kggplot(d, "day", "lai", y2 = "yield"))$plot, "ggplot"
  )

  # a guessed bar is refused when the plot is built
  bars <- data.frame(g = c("a", "b", "c"), v = 1:3, w = c(10, 5, 1))

  expect_error(as_ggplot(kggplot(bars, "g", "v", y2 = "w")), "plot types")
})

test_that("wrong y2 are refused with a clear message", {
  d <- y2_data()

  expect_error(kggplot(d, "day", "lai", y2 = "none"), "not found")

  expect_error(kggplot(d, "day", "lai", y2 = 3), "column name")

  expect_error(kggplot(d, "day", "lai", y2 = character()), "column name")

  expect_error(
    kggplot(d, "day", "lai", y2 = "lai", type = "line"), "both axes"
  )

  expect_error(
    kggplot(d, "day", "lai", y2 = "yield", ymin = "other", ymax = "other",
            type = "line"),
    "ymin"
  )

  # only series on the right axis
  expect_error(
    as_ggplot(kggplot(d, "day", y2 = "yield", type = "line")),
    "primary axis"
  )

  # a column that is not numeric
  d$chr <- "a"

  expect_error(
    as_ggplot(kggplot(d, "day", "lai", y2 = "chr", type = "line")),
    "numeric"
  )
})

test_that("the series of the right axis are dashed, unless told otherwise", {
  d <- y2_data()

  lines <- as_ggplot(kggplot(d, "day", "lai", y2 = "yield", type = "line"))

  sc <- ggplot2::ggplot_build(lines)$plot$scales$get_scales("linetype")

  expect_false(is.null(sc))

  built <- ggplot2::ggplot_build(lines)$data[[1]]

  expect_setequal(unique(built$linetype), c("solid", "dashed"))

  # points have no linetype
  points <- as_ggplot(kggplot(d, "day", "lai", y2 = "yield", type = "point"))

  expect_null(ggplot2::ggplot_build(points)$plot$scales$get_scales("linetype"))

  # a mapped linetype is respected
  d$g <- rep(c("u", "v"), length.out = nrow(d))

  mapped <- as_ggplot(
    kggplot(d, "day", "lai", y2 = "yield", linetype = "g", type = "line")
  )

  b <- ggplot2::ggplot_build(mapped)

  # the linetypes are the ones of the user's variable, not solid / dashed
  expect_false(any(c("dashed") %in% unique(b$data[[1]]$linetype)))

  expect_equal(length(unique(b$data[[1]]$linetype)), 2L)

  # a fixed linetype is respected
  fixed <- render(
    kggplot(d, "day", "lai", y2 = "yield", linetype = I("dotted"),
            type = "line")
  )

  expect_equal(unique(fixed$built$data[[1]]$linetype), "dotted")
})

test_that("the titles of the axes", {
  d <- y2_data()

  # default: the names of the series
  p <- kggplot(d, "day", "lai", y2 = c("yield", "other"), type = "line")

  b <- ggplot2::ggplot_build(as_ggplot(p))

  expect_equal(sec_axis_of(as_ggplot(p))$name, "yield, other")

  # a title
  p <- kggplot(d, "day", "lai", y2 = "yield", ylab = "LAI", ylab2 = "Yield",
               type = "line")

  g <- as_ggplot(p)

  expect_equal(g$labels$y, "LAI")

  expect_equal(sec_axis_of(g)$name, "Yield")

  # no title
  p <- kggplot(d, "day", "lai", y2 = "yield", ylab2 = NA, type = "line")

  expect_null(sec_axis_of(as_ggplot(p))$name)

  # kgg_labs, and the title of the plot on the right in `+`
  p <- kggplot(d, "day", "lai", y2 = "yield", type = "line")

  expect_equal(sec_axis_of(as_ggplot(kgg_labs(p, y2 = "Rendement")))$name,
               "Rendement")

  q <- kggplot(d, "day", "lai", ylab2 = "Right", type = "line")

  expect_equal(sec_axis_of(as_ggplot(p + q))$name, "Right")
})

test_that("a plot without y2 is not changed", {
  d <- y2_data()

  p <- kggplot(d, "day", "lai", type = "line")

  expect_null(apply_y2(lapply(p$layers, resolve_layer))$map)

  # ggplot2 has no secondary axis
  expect_s3_class(sec_axis_of(as_ggplot(p)), "waiver")
})

test_that("it works with a theme, a palette, a legend and a user scale", {
  d <- y2_data()

  p <- kggplot(
    d, "day", "lai", y2 = "yield", type = "line", theme = "inrae",
    palette = c(lai = "#00a3a6", yield = "#e07a5f"), legend = "bottom",
    title = "LAI and yield"
  )

  expect_s3_class(render(p)$plot, "ggplot")

  # a ggplot2 component added at the end
  p <- p + ggplot2::theme(legend.position = "top") +
    ggplot2::scale_x_continuous(limits = c(5, 40))

  expect_s3_class(suppressWarnings(render(p))$plot, "ggplot")

  # date on x, as the outputs of the model
  d$date <- as.Date("2005-05-01") + d$day

  expect_s3_class(
    render(kggplot(d, "date", "lai", y2 = "yield", type = "line"))$plot,
    "ggplot"
  )
})
