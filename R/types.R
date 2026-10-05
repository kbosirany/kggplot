#' Plot types
#'
#' A *type* maps a short name (`"point"`, `"line"`, `"bar"`, ...) to a
#' ggplot2 geometry plus default parameters. Types live in a registry, so you
#' can add your own with `kgg_register_type()`.
#'
#' Built-in types: `point`, `jitter`, `line`, `path`, `step`, `area`,
#' `smooth`, `text`, `bar` (alias `col`), `bar_dodge`, `count`, `histogram`,
#' `density`, `ecdf` (alias `cumFreq`), `boxplot`, `violin`, `convexhull`
#' (needs the ggConvexHull package), and
#' \itemize{
#'   \item `ribbon`: a band between `ymin` and `ymax`, filled with the series
#'   colour (`alpha = 0.2`, no outline);
#'   \item `pointrange` and `errorbar`: a point (`y`) with its range
#'   (`ymin`, `ymax`), black and not coloured by series;
#'   \item `hline` and `vline`: reference lines at `yintercept` /
#'   `xintercept` (see [kgg_hline()] and [kgg_vline()]);
#'   \item `blank`: draws nothing but trains the scales, to force the limits
#'   of some panels (see [kgg_limits()]).
#' }
#'
#' @param name Name of the type.
#' @param geom A function building a ggplot2 layer, e.g.
#'   [ggplot2::geom_point]. It is called with `mapping`, `data` and the
#'   layer parameters.
#' @param params Default parameters passed to `geom`.
#' @param univariate If `TRUE`, the type summarises one variable (histogram,
#'   density, ...): `y` is ignored and used as `x` when `x` is missing.
#' @param series Aesthetic (`"colour"` or `"fill"`) mapped to the series name
#'   when several `y` variables are plotted, or `"none"` for no default
#'   mapping (e.g. black error bars).
#' @param extra Optional function without argument returning an extra ggplot2
#'   component (scale, limits, ...) added with the layer.
#' @param free If `TRUE`, `x` and `y` are optional and the layer gives no axis
#'   title (e.g. `blank`).
#' @param intercept `"xintercept"` or `"yintercept"` for a reference line
#'   type: the layer reads that aesthetic instead of `x` and `y`.
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
  series = c("colour", "fill", "none"), extra = NULL,
  free = FALSE, intercept = NULL
) {
  series <- match.arg(series)
  if (!is.null(intercept)) {
    intercept <- match.arg(intercept, c("xintercept", "yintercept"))
  }
  stopifnot(is.character(name), length(name) == 1L, is.function(geom))
  .kgg$types[[name]] <- type_spec(
    geom, params, univariate, series, extra, free, intercept
  )
  invisible(name)
}

#' @export
#' @rdname kgg_register_type
kgg_types <- function() names(.kgg$types)

# mode: "xy" (x and y), "univariate" (one variable), "free" (x and y optional)
# or "intercept" (xintercept / yintercept)
type_spec <- function(geom, params = list(), univariate = FALSE,
                      series = "colour", extra = NULL, free = FALSE,
                      intercept = NULL) {
  mode <- if (!is.null(intercept)) {
    "intercept"
  } else if (free) {
    "free"
  } else if (univariate) {
    "univariate"
  } else {
    "xy"
  }
  list(
    geom = geom, params = params, univariate = univariate, series = series,
    extra = extra, mode = mode, intercept = intercept
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
infer_type <- function(src, x, y, mapped = list()) {
  hint <- attr(src, "kgg_type")
  if (!is.null(hint)) return(hint)
  band <- length(mapped[["ymin"]]) > 0L && length(mapped[["ymax"]]) > 0L
  if (band) return(if (length(y)) "pointrange" else "ribbon")
  xv <- if (length(x) == 1L && x %in% names(src)) src[[x]]
  infer_xy_type(xv, y)
}

# Type from the class of x and the presence of y
infer_xy_type <- function(xv, y) {
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
    "ribbon", ggplot2::geom_ribbon, series = "fill",
    params = list(alpha = 0.2, colour = NA)
  )
  reg(
    "pointrange", ggplot2::geom_pointrange, series = "none",
    params = list(colour = "black")
  )
  reg(
    "errorbar", ggplot2::geom_errorbar, series = "none",
    params = list(colour = "black")
  )
  reg("hline", ggplot2::geom_hline, series = "none", intercept = "yintercept")
  reg("vline", ggplot2::geom_vline, series = "none", intercept = "xintercept")
  reg("blank", ggplot2::geom_blank, series = "none", free = TRUE)
  reg(
    "sf", ggplot2::geom_sf,
    params = list(linewidth = 0.05), series = "fill", free = TRUE
  )
  reg(
    "convexhull",
    function(...) {
      if (!requireNamespace("ggConvexHull", quietly = TRUE)) {
        stop(
          "Type 'convexhull' needs the 'ggConvexHull' package.",
          call. = FALSE
        )
      }
      ggConvexHull::geom_convexhull(...)
    },
    series = "fill"
  )
}
