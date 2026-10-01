test_that("as_kdata handles the supported inputs", {
  expect_s3_class(as_kdata(iris), "data.frame")
  expect_s3_class(as_kdata(tibble_like <- structure(
    list(a = 1:2), class = c("tbl_df", "tbl", "data.frame"), row.names = 1:2
  )), "data.frame")

  ts1 <- as_kdata(ts(c(1, 3, 2), start = 2000))
  expect_equal(names(ts1), c("time", "value"))
  expect_equal(attr(ts1, "kgg_type"), "line")

  mts <- as_kdata(ts(cbind(a = 1:3, b = 3:1), start = 2000))
  expect_equal(names(mts), c("time", "a", "b"))

  m <- as_kdata(matrix(1:6, 3))
  expect_equal(names(m), c("V1", "V2"))

  expect_equal(names(as_kdata(c(1, 2))), c("index", "value"))
  expect_equal(names(as_kdata(c("a", "b"))), "value")
  expect_equal(names(as_kdata(factor(c("a", "b")))), "value")
  expect_equal(names(as_kdata(list(a = 1:2, b = 3:4))), c("a", "b"))
  expect_error(as_kdata(list(1:2)), "named")
  expect_error(as_kdata(quote(x)), "Don't know")
})

test_that("each input type can be plotted directly", {
  for (obj in list(
    AirPassengers, EuStockMarkets[1:20, ], matrix(rnorm(20), 10),
    cumsum(rnorm(10)), c("a", "b", "a"), list(x = 1:3, y = 3:1)
  )) {
    expect_s3_class(render(kggplot(obj))$plot, "ggplot")
  }
})

test_that("S3 extension: a new class only needs an as_kdata method", {
  as_kdata.myclass <- function(x, ...) data.frame(a = x$a, b = x$b)
  registerS3method("as_kdata", "myclass", as_kdata.myclass)
  obj <- structure(list(a = 1:3, b = 3:1), class = "myclass")
  expect_s3_class(render(kggplot(obj, "a", "b"))$plot, "ggplot")
})
