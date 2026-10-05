test_that("an sf object is drawn as a map", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

  expect_s3_class(as_kdata(nc), "sf")

  p <- as_ggplot(kggplot(nc, fill = "AREA"))

  expect_s3_class(p$coordinates, "CoordSf")

  expect_s3_class(p$layers[[1]]$geom, "GeomSf")

  expect_s3_class(ggplot2::ggplot_build(p)$data[[1]], "data.frame")
})

test_that("a map can be faceted and coloured by a category", {
  skip_if_not_installed("sf")

  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

  nc$g <- rep(c("a", "b"), length.out = nrow(nc))

  p <- as_ggplot(kggplot(nc, fill = "g", facet = "g"))

  expect_no_error(ggplot2::ggplot_build(p))
})
