#' Convert to a ggplot2 object
#'
#' `as_ggplot()` renders a [kggplot()] specification into a regular
#' `ggplot` object, which you can then customise with any ggplot2 function
#' or save with [ggplot2::ggsave()]. Printing a kggplot does this
#' implicitly.
#'
#' @param x A `kggplot` (or a `ggplot`, returned unchanged).
#' @param ... Unused.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
#' g <- as_ggplot(p)
#' class(g)
#'
#' @export
as_ggplot <- function(x, ...) {
  UseMethod("as_ggplot")
}

#' @export
#' @rdname as_ggplot
as_ggplot.ggplot <- function(x, ...) x

#' @export
#' @rdname as_ggplot
as_ggplot.kggplot <- function(x, ...) {
  fvars <- facet_vars(x$facet)
  res <- lapply(x$layers, resolve_layer, keep = fvars)

  p <- ggplot2::ggplot()
  for (r in res) p <- p + make_geom(r)

  theme <- resolve_theme(x$theme, x$base_size)
  p <- add_color_scales(p, res, resolve_palette(x$palette %||% theme$palette))
  p <- p + build_labs(res, x$labels)
  if (!is.null(theme$theme)) p <- p + theme$theme
  p <- add_legend(p, x$legend)
  p <- add_facet(p, x$facet, x$facet_args)

  for (e in x$extras) p <- p + e
  p
}

# Discrete colour/fill scales share one palette across layers, so a level has
# the same colour whatever layer it comes from.
add_color_scales <- function(p, res, pal) {
  if (is.null(pal)) return(p)
  for (a in c("colour", "fill")) {
    vals <- Filter(Negate(is.null), lapply(res, function(r) r$data[[a]]))
    if (length(vals)) p <- p + color_scale(a, vals, pal)
  }
  p
}

color_scale <- function(aesthetic, vals, pal) {
  if (all(vapply(vals, is.numeric, logical(1)))) {
    cols <- if (is.function(pal)) pal(7L) else unname(pal)
    return(switch(
      aesthetic,
      colour = ggplot2::scale_colour_gradientn(colours = cols),
      fill = ggplot2::scale_fill_gradientn(colours = cols)
    ))
  }
  lv <- unique(unlist(lapply(
    vals, function(v) if (is.factor(v)) levels(v) else unique(as.character(v))
  )))
  values <- palette_values(pal, lv)
  switch(
    aesthetic,
    colour = ggplot2::scale_colour_manual(values = values),
    fill = ggplot2::scale_fill_manual(values = values)
  )
}

# Default titles come from the layers (first one wins), then user titles
build_labs <- function(res, explicit) {
  lab <- Reduce(merge_labels, lapply(res, function(r) r$labels), list())
  lab <- utils::modifyList(lab, explicit)
  lab <- lapply(lab, function(v) if (length(v) == 1L && is.na(v)) NULL else v)
  # lapply drops nothing but keeps NULL entries, which ggplot2 reads as
  # "remove this title"
  do.call(ggplot2::labs, lab)
}

# Keep the first non-NA title of each aesthetic
merge_labels <- function(acc, new) {
  for (a in names(new)) {
    if (is.null(acc[[a]]) || is.na(acc[[a]])) acc[[a]] <- new[[a]]
  }
  acc
}

add_legend <- function(p, legend) {
  if (is.null(legend) || isTRUE(legend)) return(p)
  if (isFALSE(legend)) legend <- "none"
  if (is.numeric(legend)) {
    if (utils::packageVersion("ggplot2") >= "3.5.0") {
      return(p + ggplot2::theme(
        legend.position = "inside", legend.position.inside = legend
      ))
    }
    return(p + ggplot2::theme(legend.position = legend))
  }
  p + ggplot2::theme(legend.position = legend)
}

facet_vars <- function(facet) {
  if (is.null(facet)) return(character())
  if (inherits(facet, "formula")) return(setdiff(all.vars(facet), "."))
  as.character(facet)
}

add_facet <- function(p, facet, args) {
  if (is.null(facet)) return(p)
  args <- args %||% list()
  if (inherits(facet, "formula")) {
    fun <- if (length(facet) == 3L) ggplot2::facet_grid else ggplot2::facet_wrap
    return(p + do.call(fun, c(list(facet), args)))
  }
  facet <- as.character(facet)
  if (length(facet) == 1L) {
    return(p + do.call(
      ggplot2::facet_wrap,
      c(list(ggplot2::vars(!!rlang::sym(facet))), args)
    ))
  }
  if (length(facet) == 2L) {
    return(p + do.call(
      ggplot2::facet_grid,
      c(list(rows = ggplot2::vars(!!rlang::sym(facet[1L])),
             cols = ggplot2::vars(!!rlang::sym(facet[2L]))), args)
    ))
  }
  stop("`facet` takes one or two variables, or a formula.", call. = FALSE)
}

#' Save a kggplot to a file
#'
#' Thin wrapper around [ggplot2::ggsave()] that accepts a `kggplot`.
#'
#' @param p A `kggplot` or `ggplot`.
#' @inheritParams ggplot2::ggsave
#' @param ... Passed to [ggplot2::ggsave()].
#'
#' @return The file name, invisibly.
#'
#' @export
kgg_save <- function(p, filename, ...) {
  ggplot2::ggsave(filename = filename, plot = as_ggplot(p), ...)
}
