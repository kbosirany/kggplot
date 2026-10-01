#' Plot types
#'
#' A *type* maps a short name (`"point"`, `"line"`, `"bar"`, ...) to a
#' ggplot2 geometry plus default parameters. Types live in a registry, so you
#' can add your own with `kgg_register_type()`.
#'
#' Built-in types: `point`, `jitter`, `line`, `path`, `step`, `area`,
#' `smooth`, `text`, `bar` (alias `col`), `bar_dodge`, `count`, `histogram`,
#' `density`, `ecdf` (alias `cumFreq`), `boxplot`, `violin`, `convexhull`
#' (needs the ggConvexHull package).
#'
#' @param name Name of the type.
#' @param geom A function building a ggplot2 layer, e.g.
#'   [ggplot2::geom_point]. It is called with `mapping`, `data` and the
#'   layer parameters.
#' @param params Default parameters passed to `geom`.
#' @param univariate If `TRUE`, the type summarises one variable (histogram,
#'   density, ...): `y` is ignored and used as `x` when `x` is missing.
#' @param series Aesthetic (`"colour"` or `"fill"`) mapped to the series name
#'   when several `y` variables are plotted.
#' @param extra Optional function without argument returning an extra ggplot2
#'   component (scale, limits, ...) added with the layer.
#'
#' @return `kgg_register_type()` returns `name` invisibly; `kgg_types()` a
#'   character vector of the registered types.
#'
#' @examples
#' kgg_types()
#' kgg_register_type("hollow", ggplot2::geom_point, params = list(shape = 1))
#' kggplot(iris, "Sepal.Length", "Sepal.Width", type = "hollow")
#'
#' @export
kgg_register_type <- function(
  name, geom, params = list(), univariate = FALSE,
  series = c("colour", "fill"), extra = NULL
) {
  series <- match.arg(series)
  stopifnot(is.character(name), length(name) == 1L, is.function(geom))
  .kgg$types[[name]] <- type_spec(geom, params, univariate, series, extra)
  invisible(name)
}

#' @export
#' @rdname kgg_register_type
kgg_types <- function() names(.kgg$types)

type_spec <- function(geom, params = list(), univariate = FALSE,
                      series = "colour", extra = NULL) {
  list(
    geom = geom, params = params, univariate = univariate, series = series,
    extra = extra
  )
}

get_type <- function(type) {
  if (is.function(type)) return(type_spec(type))
  if (!is.character(type) || length(type) != 1L) {
    stop("`type` must be a single string or a geom function.", call. = FALSE)
  }
  spec <- .kgg$types[[type]]
  if (is.null(spec)) {
    stop(
      "Unknown plot type '", type, "'. Available: ",
      paste(kgg_types(), collapse = ", "), ".",
      call. = FALSE
    )
  }
  spec
}

# Pick a sensible type from the shape of the data
infer_type <- function(src, x, y) {
  hint <- attr(src, "kgg_type")
  if (!is.null(hint)) return(hint)
  xv <- if (length(x) == 1L && x %in% names(src)) src[[x]]
  if (!length(y)) return(if (is.numeric(xv)) "histogram" else "count")
  if (inherits(xv, c("Date", "POSIXt"))) return("line")
  if (is.null(xv) || is.numeric(xv)) "point" else "bar"
}

register_builtin_types <- function() {
  reg <- kgg_register_type
  reg("point", ggplot2::geom_point)
  reg("jitter", ggplot2::geom_jitter)
  reg("line", ggplot2::geom_line)
  reg("path", ggplot2::geom_path)
  reg("step", ggplot2::geom_step)
  reg("area", ggplot2::geom_area, series = "fill")
  reg(
    "smooth", ggplot2::geom_smooth,
    params = list(method = "lm", formula = y ~ x, se = FALSE)
  )
  reg("text", ggplot2::geom_text)
  reg("bar", ggplot2::geom_col, series = "fill")
  reg("col", ggplot2::geom_col, series = "fill")
  reg(
    "bar_dodge", ggplot2::geom_col, series = "fill",
    params = list(width = 0.5, position = ggplot2::position_dodge(0.8))
  )
  reg("count", ggplot2::geom_bar, univariate = TRUE, series = "fill")
  reg("histogram", ggplot2::geom_histogram, univariate = TRUE, series = "fill")
  reg(
    "density", ggplot2::geom_density, univariate = TRUE,
    extra = function() ggplot2::expand_limits(y = 0)
  )
  ecdf_geom <- function(...) ggplot2::geom_step(..., stat = "ecdf")
  reg("ecdf", ecdf_geom, univariate = TRUE)
  reg("cumFreq", ecdf_geom, univariate = TRUE)
  reg("boxplot", ggplot2::geom_boxplot, series = "fill")
  reg("violin", ggplot2::geom_violin, series = "fill")
  reg(
    "convexhull",
    function(...) {
      if (!requireNamespace("ggConvexHull", quietly = TRUE)) {
        stop("Type 'convexhull' needs the 'ggConvexHull' package.", call. = FALSE)
      }
      ggConvexHull::geom_convexhull(...)
    },
    series = "fill"
  )
}
