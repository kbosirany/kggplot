#' Convert to a ggplot2 object
#'
#' `as_ggplot()` renders a [kggplot()] specification into a regular
#' `ggplot` object, which you can then customise with any ggplot2 function
#' or save with [ggplot2::ggsave()]. Printing a kggplot does this
#' implicitly.
#'
#' @param x A `kggplot`, a `kgg_grid` or a `ggplot` (returned unchanged).
#' @param ... Unused.
#' @param shared Colour and fill levels or limits imposed on a `kggplot`.
#'   Used by [kgg_grid()] to share scales across plots; leave it `NULL`.
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
as_ggplot.kggplot <- function(x, ..., shared = NULL) {
  res <- resolve_layers(x)

  p <- ggplot2::ggplot()
  for (r in res) p <- p + make_geom(r)

  theme <- resolve_theme(x$theme, x$base_size)
  pal <- resolve_palette(x$palette %||% theme$palette)
  p <- add_color_scales(p, res, pal, shared)
  p <- p + build_labs(res, x$labels)
  if (!is.null(theme$theme)) p <- p + theme$theme
  p <- add_legend(p, x$legend)
  p <- add_facet(p, x$facet, x$facet_args)

  for (e in x$extras) p <- p + e
  p
}

# Standardised long data of every layer, facet variables kept and harmonised
resolve_layers <- function(x) {
  fvars <- facet_vars(x$facet)
  harmonise_facets(lapply(x$layers, resolve_layer, keep = fvars), fvars)
}

# Discrete colour/fill scales share one palette across layers, so a level has
# the same colour whatever layer it comes from. `shared` (see
# `shared_scales()`) imposes the levels or limits of a whole grid instead.
add_color_scales <- function(p, res, pal, shared = NULL) {
  for (a in c("colour", "fill")) {
    vals <- Filter(Negate(is.null), lapply(res, function(r) r$data[[a]]))
    sh <- shared[[a]]
    if (!length(vals) || (is.null(pal) && is.null(sh))) next
    p <- p + color_scale(a, vals, pal, sh)
  }
  p
}

color_scale <- function(aesthetic, vals, pal, shared = NULL) {
  if (all(vapply(vals, is.numeric, logical(1)))) {
    return(continuous_scale(aesthetic, pal, shared$limits))
  }
  lv <- shared$levels %||% level_union(vals)
  values <- palette_values(pal %||% hue_palette, lv)
  args <- list(values = values)
  if (!is.null(shared)) args <- c(args, list(limits = lv, drop = FALSE))
  fun <- switch(
    aesthetic,
    colour = ggplot2::scale_colour_manual,
    fill = ggplot2::scale_fill_manual
  )
  do.call(fun, args)
}

continuous_scale <- function(aesthetic, pal, limits) {
  if (is.null(pal)) {
    fun <- switch(
      aesthetic,
      colour = ggplot2::scale_colour_gradient,
      fill = ggplot2::scale_fill_gradient
    )
    return(fun(limits = limits))
  }
  cols <- if (is.function(pal)) pal(7L) else unname(pal)
  fun <- switch(
    aesthetic,
    colour = ggplot2::scale_colour_gradientn,
    fill = ggplot2::scale_fill_gradientn
  )
  fun(colours = cols, limits = limits)
}

# Default ggplot2 hue colours, used when a grid shares scales without palette
hue_palette <- function(n) scales::hue_pal()(n)

level_union <- function(vals) {
  unique(unlist(lapply(
    vals, function(v) if (is.factor(v)) levels(v) else unique(as.character(v))
  )))
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

# Layers with their own data must share the panels of a facet variable: when
# it is a factor in some layer, every layer gets the same levels (those of the
# factors first, then the other values), so panels and their order are the same.
harmonise_facets <- function(res, fvars) {
  for (f in fvars) {
    vals <- Filter(Negate(is.null), lapply(res, function(r) r$data[[f]]))
    if (!any(vapply(vals, is.factor, logical(1)))) next
    lv <- unique(unlist(lapply(vals, function(v) {
      if (is.factor(v)) levels(v) else unique(as.character(v))
    })))
    for (i in seq_along(res)) {
      col <- res[[i]]$data[[f]]
      if (!is.null(col)) {
        res[[i]]$data[[f]] <- factor(as.character(col), levels = lv)
      }
    }
  }
  res
}

facet_vars <- function(facet) {
  if (is.null(facet)) return(character())
  if (inherits(facet, "formula")) return(setdiff(all.vars(facet), "."))
  as.character(facet)
}

# `switch` moves the strips to the other side: they are placed outside the axes
add_facet <- function(p, facet, args) {
  p <- add_facet_layer(p, facet, args)
  if (!is.null(facet) && "switch" %in% names(args)) {
    p <- p + ggplot2::theme(strip.placement = "outside")
  }
  p
}

add_facet_layer <- function(p, facet, args) {
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
