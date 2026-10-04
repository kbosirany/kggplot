#' Reference lines and panel limits
#'
#' Helpers that return a layer to add to a plot with `+`:
#'
#' * `kgg_hline()` and `kgg_vline()` draw horizontal and vertical reference
#'   lines. Give the positions as a vector (the lines appear in every panel),
#'   or a data frame and the name of the column holding the positions: if the
#'   data frame also has the facet column, the lines appear only in the
#'   matching panels (a threshold shown in one panel only).
#' * `kgg_limits()` forces the range of the axes of some panels, which is
#'   useful with free scales (`facet_args = list(scales = "free_y")`): it draws
#'   nothing but trains the scales, like `ggplot2::geom_blank()`.
#'
#' Fixed appearance goes in the arguments: `linetype = "dashed"`,
#' `color = I("grey40")`, `linewidth = 0.5`... (wrap a colour in `I()`, as for
#' every kggplot layer: a bare string would be a legend entry).
#'
#' @param yintercept,xintercept Positions of the lines: a vector (numbers,
#'   dates...), or the name of a column of `data`.
#' @param data Optional data frame with the positions and the facet column(s).
#' @param ... For `kgg_hline()` and `kgg_vline()`: appearance and other
#'   arguments of [kggplot()] (`linetype`, `color`, `linewidth`, ...). For
#'   `kgg_limits()`: the facet values of the panels concerned, named after the
#'   facet variable (`panel = "Available water ratio"`).
#' @param x,y Limits to force: the axis range will contain them. Several
#'   values are allowed, e.g. `y = c(0, 1)`.
#'
#' @return A `kggplot` with a single layer, to add to another with `+`.
#'
#' @examples
#' d <- data.frame(
#'   date = rep(as.Date("2024-05-01") + 0:29, 2),
#'   panel = rep(c("Ratio", "Biomass"), each = 30),
#'   value = c(seq(0.2, 0.6, length.out = 30), seq(0, 8, length.out = 30))
#' )
#' kggplot(d, "date", "value", type = "line", facet = "panel",
#'         facet_args = list(scales = "free_y")) +
#'   # a threshold in the "Ratio" panel only
#'   kgg_hline(data = data.frame(panel = "Ratio", y = 0.4), yintercept = "y",
#'             linetype = "dashed", color = I("grey40")) +
#'   # decision dates in every panel
#'   kgg_vline(as.Date("2024-05-10") + c(0, 10), linetype = "dotted") +
#'   # the "Ratio" panel spans 0 to 1
#'   kgg_limits(panel = "Ratio", y = c(0, 1))
#'
#' @name kgg_reference
NULL

#' @export
#' @rdname kgg_reference
kgg_hline <- function(yintercept, data = NULL, ...) {
  reference_line("hline", "yintercept", yintercept, data, ...)
}

#' @export
#' @rdname kgg_reference
kgg_vline <- function(xintercept, data = NULL, ...) {
  reference_line("vline", "xintercept", xintercept, data, ...)
}

reference_line <- function(type, aes, value, data, ...) {
  if (is.null(data)) {
    data <- data.frame(value)
    names(data) <- aes
    value <- aes
  } else if (!is.character(value) || !all(value %in% names(data))) {
    stop("With `data`, `", aes, "` must be the name of one of its columns.",
         call. = FALSE)
  }
  rlang::exec(
    kggplot, data, type = type, !!!stats::setNames(list(value), aes), ...
  )
}

#' @export
#' @rdname kgg_reference
kgg_limits <- function(..., x = NULL, y = NULL) {
  facets <- list(...)
  unnamed <- is.null(names(facets)) || !all(nzchar(names(facets)))
  if (length(facets) && unnamed) {
    stop("The panels must be given by name, e.g. `panel = \"A\"`.",
         call. = FALSE)
  }
  if (is.null(x) && is.null(y)) {
    stop("Give the limits to force in `x` and/or `y`.", call. = FALSE)
  }
  n <- max(length(x), length(y))
  recycle <- function(v) v[rep_len(seq_along(v), n)]
  data <- data.frame(row.names = seq_len(n))
  for (f in names(facets)) data[[f]] <- recycle(facets[[f]])
  if (!is.null(x)) data$x <- recycle(x)
  if (!is.null(y)) data$y <- recycle(y)
  kggplot(
    data, x = if (!is.null(x)) "x", y = if (!is.null(y)) "y", type = "blank"
  )
}
