#' Themes and palettes
#'
#' A kggplot *theme* bundles a ggplot2 theme and (optionally) a colour
#' palette under one name, so `kggplot(..., theme = "inrae")` styles the whole
#' plot. Register your own with `kgg_register_theme()` and
#' `kgg_register_palette()`.
#'
#' A `theme` argument accepted by [kggplot()] can be: a registered name; the
#' name of any `theme_<name>()` function found on the search path (so
#' `theme = "bw"` or a theme from another package works); a ggplot2 theme
#' object; or a function taking `base_size`. Set `options(kggplot.theme = )`
#' and `options(kggplot.palette = )` to change the defaults session-wide.
#'
#' @param name Name of the theme or palette.
#' @param theme A function taking `base_size` and returning a ggplot2 theme,
#'   a ggplot2 theme object, or `NULL` (ggplot2 default).
#' @param palette Colours of the theme: a character vector of colours, the
#'   name of a registered palette, or `NULL`.
#' @param colors Character vector of colours (or a function of `n`).
#'
#' @return `kgg_register_*()` return `name` invisibly; `kgg_themes()` and
#'   `kgg_palettes()` return the registered names.
#'
#' @examples
#' kgg_themes()
#' kgg_register_palette("traffic", c("#2ecc71", "#f1c40f", "#e74c3c"))
#' kgg_register_theme("traffic", ggplot2::theme_bw, palette = "traffic")
#' kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
#'         theme = "traffic")
#'
#' @export
kgg_register_theme <- function(name, theme = NULL, palette = NULL) {
  stopifnot(is.character(name), length(name) == 1L)
  if (!is.null(theme) && !is.function(theme) && !inherits(theme, "theme")) {
    stop("`theme` must be a function, a ggplot2 theme or NULL.", call. = FALSE)
  }
  .kgg$themes[[name]] <- list(theme = theme, palette = palette)
  invisible(name)
}

#' @export
#' @rdname kgg_register_theme
kgg_register_palette <- function(name, colors) {
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.character(colors) || is.function(colors))
  .kgg$palettes[[name]] <- colors
  invisible(name)
}

#' @export
#' @rdname kgg_register_theme
kgg_themes <- function() names(.kgg$themes)

#' @export
#' @rdname kgg_register_theme
kgg_palettes <- function() names(.kgg$palettes)

register_builtin_palettes <- function() {
  kgg_register_palette(
    "inrae",
    c("#00a3a6", "#9dc544", "#423089", "#ed6e6c", "#c4c0b3", "#9ed6e3",
      "#797870")
  )
  kgg_register_palette(
    "okabe_ito",
    c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00",
      "#CC79A7", "#999999")
  )
}

register_builtin_themes <- function() {
  kgg_register_theme("default")
  kgg_register_theme("grey", ggplot2::theme_grey)
  kgg_register_theme("minimal", ggplot2::theme_minimal)
  kgg_register_theme("bw", ggplot2::theme_bw)
  kgg_register_theme("classic", ggplot2::theme_classic)
  kgg_register_theme("light", ggplot2::theme_light)
  kgg_register_theme("dark", ggplot2::theme_dark)
  kgg_register_theme("linedraw", ggplot2::theme_linedraw)
  kgg_register_theme("void", ggplot2::theme_void)
  kgg_register_theme(
    "inrae",
    function(...) {
      if (requireNamespace("InraeThemes", quietly = TRUE)) {
        InraeThemes::theme_inrae(...)
      } else {
        ggplot2::theme_minimal(...)
      }
    },
    palette = "inrae"
  )
}

# Resolve `theme` to list(theme = <ggplot2 theme or NULL>, palette = <colors>)
resolve_theme <- function(theme = NULL, base_size = NULL) {
  theme <- theme %||% getOption("kggplot.theme")
  if (is.null(theme)) return(list(theme = NULL, palette = NULL))

  build <- function(fun) {
    if (is.null(base_size)) fun() else fun(base_size = base_size)
  }

  if (inherits(theme, "theme")) return(list(theme = theme, palette = NULL))
  if (is.function(theme)) return(list(theme = build(theme), palette = NULL))
  if (!is.character(theme) || length(theme) != 1L) {
    stop("`theme` must be a name, a function or a ggplot2 theme.", call. = FALSE)
  }

  entry <- .kgg$themes[[theme]]
  if (is.null(entry)) {
    fun <- get0(paste0("theme_", theme), mode = "function") %||%
      get0(paste0("theme_", theme), envir = asNamespace("ggplot2"),
           mode = "function")
    if (is.null(fun)) {
      stop(
        "Unknown theme '", theme, "'. Registered: ",
        paste(kgg_themes(), collapse = ", "), ".",
        call. = FALSE
      )
    }
    entry <- list(theme = fun, palette = NULL)
  }
  th <- entry$theme
  if (is.function(th)) th <- build(th)
  list(theme = th, palette = entry$palette)
}

# Resolve a palette spec to a character vector, a function, or NULL
resolve_palette <- function(palette) {
  palette <- palette %||% getOption("kggplot.palette")
  if (is.null(palette) || is.function(palette)) return(palette)
  if (!is.character(palette)) {
    stop("`palette` must be colours, a palette name or a function.", call. = FALSE)
  }
  if (length(palette) == 1L && is.null(names(palette)) &&
      !is.null(.kgg$palettes[[palette]])) {
    return(.kgg$palettes[[palette]])
  }
  palette
}

# Colours for `levels` (named by level), from a vector or a function
palette_values <- function(pal, levels) {
  n <- length(levels)
  if (is.function(pal)) return(stats::setNames(pal(n), levels))
  if (!is.null(names(pal))) return(pal)
  cols <- if (n <= length(pal)) pal[seq_len(n)] else {
    if (n > 100L) message("Can't generate palette for more than 100 colors")
    grDevices::colorRampPalette(pal)(n)
  }
  stats::setNames(cols, levels)
}

#' Generate a colour palette for a vector of values
#'
#' Returns a named vector of colours, one per unique value of `x`. If there
#' are at most `length(main_colors)` values the first colours are used,
#' otherwise the colours are interpolated.
#'
#' @param x A vector of values.
#' @param theme Name of a registered theme or palette whose colours are used.
#' @param main_colors Character vector of base colours (overrides `theme`).
#'
#' @return A named character vector of colours.
#'
#' @examples
#' get_color_palette(c("A", "B", "C"), main_colors = c("red", "green", "blue"))
#' get_color_palette(c("A", "B"), theme = "inrae")
#'
#' @export
get_color_palette <- function(x, theme = NULL, main_colors = NULL) {
  if (is.null(main_colors)) {
    if (is.null(theme)) stop("Argument 'theme' is required.", call. = FALSE)
    main_colors <- .kgg$palettes[[theme]] %||% resolve_theme(theme)$palette
    main_colors <- resolve_palette(main_colors)
    if (is.null(main_colors)) {
      stop("Theme '", theme, "' has no palette.", call. = FALSE)
    }
  }
  lv <- if (is.factor(x)) levels(droplevels(x)) else unique(as.character(x))
  palette_values(main_colors, lv)
}
