#' @export
print.kggplot <- function(x, ...) {
  print(as_ggplot(x), ...)
  invisible(x)
}

#' @export
plot.kggplot <- function(x, ...) {
  print(as_ggplot(x), ...)
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.kggplot <- function(object, ...) as_ggplot(object)

#' Add layers or ggplot2 components to a kggplot
#'
#' * `kggplot + kggplot`: appends the layers of the right-hand plot; its
#'   theme, titles, legend, palette and facets override the left ones when
#'   specified.
#' * `kggplot + <ggplot2 component>` (theme, scale, coord, labs, geom...):
#'   stored and applied last, in order.
#'
#' @param e1 A `kggplot`.
#' @param e2 A `kggplot` or a ggplot2 component.
#'
#' @return A `kggplot`.
#'
#' @examples
#' p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
#' p + ggplot2::theme_bw() + ggplot2::geom_hline(yintercept = 3)
#'
#' @export
`+.kggplot` <- function(e1, e2) {
  if (missing(e2)) stop("Cannot use `+` with a single argument.", call. = FALSE)
  if (!inherits(e1, "kggplot")) {
    stop("The left-hand side of `+` must be a kggplot.", call. = FALSE)
  }
  if (inherits(e2, "kggplot")) return(merge_kggplot(e1, e2))
  e1$extras <- c(e1$extras, list(e2))
  e1
}

# Without this, `kggplot + theme_bw()` is ambiguous with ggplot2's `+.gg`
#' @exportS3Method base::chooseOpsMethod
chooseOpsMethod.kggplot <- function(x, y, mx, my, cl, reverse) TRUE

#' @exportS3Method base::chooseOpsMethod
chooseOpsMethod.kgg_grid <- function(x, y, mx, my, cl, reverse) TRUE
