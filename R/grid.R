#' Compose plots into a grid
#'
#' `kgg_grid()` arranges several plots in a grid. Plots can be given one by
#' one, as lists (possibly nested), or both. [kggplot()] objects, regular
#' `ggplot` objects and other `kgg_grid` objects are accepted. By default the
#' grid is as square as possible (see [kgg_grid_dims()]) and identical legends
#' are merged into a single one, as in a facet.
#'
#' @param ... Plots (`kggplot`, `ggplot`, `kgg_grid`) or lists of plots.
#'   Names become the title of each cell (see `titles`).
#' @param nrow,ncol Number of rows and columns. Leave both `NULL` for the
#'   most square grid; give one and the other is deduced; give both to force
#'   the grid. The number of plots must fit in the grid (error otherwise) and
#'   a grid with entirely empty rows or columns triggers a warning (an error
#'   when `strict = TRUE`).
#' @param ratio Target width/height ratio of the grid when `nrow` and `ncol`
#'   are not given (1 = square, 16/9 = wide).
#' @param byrow Fill the grid by row (`TRUE`, default) or by column.
#' @param scales `"shared"` (default) gives the same colour to the same level
#'   in every plot and the same colour limits to continuous colour/fill
#'   scales, so a legend merged across plots is truthful (as in a facet).
#'   `"free"` keeps the scales of each plot. Only `kggplot` objects are
#'   unified: plain `ggplot` objects and nested grids are left untouched.
#' @param legend `"collect"` (default) merges the legends of all plots into
#'   one shared legend, `"each"` keeps one legend per plot, `"none"` removes
#'   every legend.
#' @param legend_position Position of the shared legend (`"right"`,
#'   `"bottom"`, `"left"`, `"top"`).
#' @param titles Use the names of the plots as cell titles? `NULL` (default)
#'   does so when at least one plot is named.
#' @param title,subtitle,caption Overall annotations of the grid.
#' @param tags Panel tags: `NULL` for none, or `"A"`, `"a"`, `"1"`, `"I"`,
#'   `"i"` to number the cells.
#' @param widths,heights Relative widths of the columns and heights of the
#'   rows.
#' @param strict Turn the warning about empty rows or columns into an error.
#'
#' @return A `kgg_grid`, printed as a patchwork; convert it with
#'   [as_ggplot()]. Add plots with `+`.
#'
#' @examples
#' a <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
#' b <- kggplot(iris, "Petal.Length", "Petal.Width", color = "Species")
#' kgg_grid(a, b, a, title = "Iris")
#' kgg_grid(list(a = a, b = b), ncol = 1, tags = "A")
#' kgg_grid_dims(7)
#'
#' @export
kgg_grid <- function(..., nrow = NULL, ncol = NULL, ratio = 1, byrow = TRUE,
                     scales = c("shared", "free"),
                     legend = c("collect", "each", "none"),
                     legend_position = c("right", "bottom", "left", "top"),
                     titles = NULL, title = NULL, subtitle = NULL,
                     caption = NULL, tags = NULL, widths = NULL,
                     heights = NULL, strict = FALSE) {
  scales <- match.arg(scales)
  legend <- match.arg(legend)
  legend_position <- match.arg(legend_position)
  plots <- flatten_plots(list(...))
  if (!length(plots)) stop("No plot to put in the grid.", call. = FALSE)
  dims_args <- list(nrow = nrow, ncol = ncol, ratio = ratio, byrow = byrow,
                    strict = strict)
  dims <- do.call(kgg_grid_dims, c(list(length(plots)), dims_args))
  structure(
    list(
      plots = plots, nrow = dims$nrow, ncol = dims$ncol, byrow = byrow,
      dims_args = dims_args,
      scales = scales, legend = legend, legend_position = legend_position,
      titles = titles,
      annotation = list(title = title, subtitle = subtitle, caption = caption),
      tags = tags, widths = widths, heights = heights
    ),
    class = "kgg_grid"
  )
}

#' Number of rows and columns of a grid
#'
#' Without constraint, picks the layout whose width/height ratio is closest
#' to `ratio` (the most square by default), with no empty row or column and,
#' a mild penalty for empty cells; ties go to the widest shape. With `nrow`
#' and/or `ncol`, the missing dimension is deduced and the layout is checked:
#' the `n` plots must fit in the grid (error otherwise), and empty rows or
#' columns are reported (warning, or error when `strict = TRUE`).
#'
#' @param n Number of plots.
#' @param nrow,ncol Optional imposed dimensions.
#' @param ratio Target width/height ratio.
#' @param byrow Is the grid filled by row?
#' @param strict Turn the empty rows/columns warning into an error.
#'
#' @return A list with `nrow` and `ncol`.
#'
#' @examples
#' kgg_grid_dims(5)
#' kgg_grid_dims(5, ncol = 2)
#' kgg_grid_dims(6, ratio = 16 / 9)
#'
#' @export
kgg_grid_dims <- function(n, nrow = NULL, ncol = NULL, ratio = 1,
                          byrow = TRUE, strict = FALSE) {
  check_dims_args(n, nrow, ncol, ratio)
  if (is.null(nrow) && is.null(ncol)) return(best_dims(n, ratio))
  nrow <- nrow %||% ceiling(n / ncol)
  ncol <- ncol %||% ceiling(n / nrow)
  if (n > nrow * ncol) {
    stop(sprintf(
      "%d plot(s) do not fit in a %d x %d grid (%d cell(s)): add %d more.",
      n, nrow, ncol, nrow * ncol, n - nrow * ncol
    ), call. = FALSE)
  }
  msg <- empty_message(n, nrow, ncol, byrow)
  if (!is.null(msg)) {
    if (strict) stop(msg, call. = FALSE)
    warning(msg, call. = FALSE)
  }
  list(nrow = as.integer(nrow), ncol = as.integer(ncol))
}

# Describe the rows/columns left entirely empty by n plots, or NULL
empty_message <- function(n, nrow, ncol, byrow) {
  used_rows <- if (byrow) ceiling(n / ncol) else min(n, nrow)
  used_cols <- if (byrow) min(n, ncol) else ceiling(n / nrow)
  unused <- c(row = nrow - used_rows, column = ncol - used_cols)
  unused <- unused[unused > 0]
  if (!length(unused)) return(NULL)
  what <- sprintf(
    "%d %s%s", unused, names(unused), ifelse(unused > 1L, "s", "")
  )
  sprintf(
    "The %d x %d grid has %s empty for %d plot(s).", nrow, ncol,
    paste(what, collapse = " and "), n
  )
}

check_dims_args <- function(n, nrow, ncol, ratio) {
  check_count(n, "n")
  if (!is.null(nrow)) check_count(nrow, "nrow")
  if (!is.null(ncol)) check_count(ncol, "ncol")
  if (!is.numeric(ratio) || length(ratio) != 1L || !is.finite(ratio) ||
        ratio <= 0) {
    stop("`ratio` must be a positive number.", call. = FALSE)
  }
}

check_count <- function(x, what) {
  ok <- is.numeric(x) && length(x) == 1L && !is.na(x) && x >= 1 &&
    x == round(x)
  if (!ok) {
    stop(sprintf("`%s` must be a positive integer.", what), call. = FALSE)
  }
}

best_dims <- function(n, ratio) {
  ncol <- seq_len(n)
  nrow <- ceiling(n / ncol)
  # squareness first, with a mild penalty for empty cells; ties go wide
  score <- abs(log(ncol / nrow / ratio)) + 0.5 * (nrow * ncol - n) / n
  ord <- order(round(score, 8), -ncol)[1L]
  list(nrow = as.integer(nrow[ord]), ncol = as.integer(ncol[ord]))
}

# Accept plots, lists of plots (nested) and keep names
flatten_plots <- function(x) {
  out <- list()
  nms <- names(x) %||% rep("", length(x))
  for (i in seq_along(x)) {
    el <- x[[i]]
    if (is.null(el)) next
    if (inherits(el, c("kggplot", "ggplot", "kgg_grid", "patchwork"))) {
      out[[length(out) + 1L]] <- el
      names(out)[length(out)] <- nms[i]
    } else if (is.list(el)) {
      out <- c(out, flatten_plots(el))
    } else {
      stop(
        "Grid elements must be kggplot, ggplot or kgg_grid objects, ",
        "or lists of them.", call. = FALSE
      )
    }
  }
  out
}

#' @rdname as_ggplot
#' @export
as_ggplot.kgg_grid <- function(x, ...) {
  rlang::check_installed("patchwork", reason = "to draw grids.")
  nms <- names(x$plots) %||% rep("", length(x$plots))
  use_titles <- x$titles %||% any(nzchar(nms))
  shared <- if (x$scales == "shared") shared_scales(x$plots)
  plots <- lapply(seq_along(x$plots), function(i) {
    el <- x$plots[[i]]
    p <- if (inherits(el, "kggplot")) {
      as_ggplot(el, shared = shared)
    } else {
      as_ggplot(el)
    }
    if (use_titles && nzchar(nms[i])) p <- p + ggplot2::ggtitle(nms[i])
    if (x$legend == "none") p <- p + ggplot2::theme(legend.position = "none")
    p
  })
  ann <- Filter(Negate(is.null), x$annotation)
  g <- patchwork::wrap_plots(
    plots, nrow = x$nrow, ncol = x$ncol, byrow = x$byrow,
    widths = x$widths, heights = x$heights,
    guides = if (x$legend == "collect") "collect" else "keep"
  )
  args <- c(ann, list(
    tag_levels = x$tags,
    theme = ggplot2::theme(legend.position = x$legend_position)
  ))
  g + do.call(patchwork::plot_annotation, args)
}

#' @export
print.kgg_grid <- function(x, ...) {
  print(as_ggplot(x), ...)
  invisible(x)
}

#' @export
plot.kgg_grid <- function(x, ...) {
  print(as_ggplot(x), ...)
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.kgg_grid <- function(object, ...) as_ggplot(object)

#' @export
`+.kgg_grid` <- function(e1, e2) {
  if (!inherits(e1, "kgg_grid")) {
    stop("The left-hand side of `+` must be a kgg_grid.", call. = FALSE)
  }
  new <- flatten_plots(list(e2))
  if (!length(new)) return(e1)
  e1$plots <- c(e1$plots, new)
  d <- do.call(kgg_grid_dims, c(list(length(e1$plots)), e1$dims_args))
  e1$nrow <- d$nrow
  e1$ncol <- d$ncol
  e1
}

# Levels (discrete) or range (continuous) of the colour and fill aesthetics
# over all the kggplot objects of a grid. An aesthetic that is discrete in
# some plots and continuous in others is not shared.
shared_scales <- function(plots) {
  res <- unlist(
    lapply(Filter(function(p) inherits(p, "kggplot"), plots), resolve_layers),
    recursive = FALSE
  )
  out <- lapply(c(colour = "colour", fill = "fill"), function(a) {
    vals <- Filter(Negate(is.null), lapply(res, function(r) r$data[[a]]))
    if (!length(vals)) return(NULL)
    num <- vapply(vals, is.numeric, logical(1))
    if (all(num)) return(list(limits = range(unlist(vals), na.rm = TRUE)))
    if (!any(num)) return(list(levels = level_union(vals)))
    NULL
  })
  Filter(Negate(is.null), out)
}
