#' Draw a complete plot in one call
#'
#' `kggplot()` builds a ggplot2 graphic (reshaping, mappings, geometry,
#' labels, theme, palette, legend, facets) from a data object and a few
#' short arguments, and returns a `kggplot` object. Print it to draw it,
#' compose it with `+`, or convert it with [as_ggplot()].
#'
#' @section Mapping aesthetics:
#' `x`, `y`, `color`, `fill`, `group`, `size`, `shape`, `alpha`, `linetype`
#' and `label` take column names (strings). `ymin` and `ymax` (bands, error
#' bars) and `xintercept` and `yintercept` (reference lines) are columns too.
#' Special values:
#' \itemize{
#'   \item `y = c("a", "b")` or `y = "all"` plots several columns; they are
#'   stacked in long format and coloured by series (the pseudo-column
#'   `".series"` can be mapped to any aesthetic or facet). `ymin` and `ymax`
#'   then take either one column (used for every series) or one column per
#'   `y` column, in the same order.
#'   \item a string that is not a column, passed to `color`, `fill` or
#'   `group`, creates a legend entry: `color = "Observed"` names the layer.
#'   \item `I("red")` (or a number, for `size`, `alpha`...) is a fixed
#'   value, not a mapping.
#'   \item `x` omitted: the first column (or the row index if `y` is given).
#'   \item `y` omitted: all the other columns.
#' }
#'
#' @section Extending a plot:
#' `kggplot(p, new_data, ...)` (with `p` a kggplot), `p + kggplot(...)` and
#' [kgg_add()] add a layer; colours stay consistent across layers. Any
#' ggplot2 component can be added with `+` (`+ theme(...)`, `+ geom_hline()`,
#' `+ scale_x_log10()`), and is applied last.
#'
#' @param data A data frame, or anything [as_kdata()] understands (`ts`,
#'   matrix, vector, named list). If a `kggplot`, a layer is added to it.
#' @param x,y,color,fill,group,size,shape,alpha,linetype,label Aesthetics,
#'   see Details. `colour` is accepted as an alias of `color`.
#' @param ymin,ymax Columns holding the lower and upper bounds of a band or of
#'   error bars, for the types `ribbon`, `pointrange` and `errorbar`.
#' @param xintercept,yintercept Column of the position of a reference line, for
#'   the types `vline` and `hline` (see [kgg_hline()] and [kgg_vline()]).
#' @param vars Optional named list of aesthetics (`list(x = "a", y = "b")`),
#'   an alternative to the arguments above (they take precedence).
#' @param type Plot type, see [kgg_types()]; or a geom function. By default
#'   guessed from the data (line for dates and `ts`, point for numeric
#'   `x`/`y`, bar for a categorical `x`, histogram/count for a lone `x`).
#' @param title,subtitle,caption Plot titles.
#' @param xlab,ylab Axis titles (default: the variable names). Use `NA` to
#'   remove a title.
#' @param labels Named list of titles (`title`, `x`, `y`, `color`, `fill`...)
#'   for anything not covered by the arguments above, e.g. legend titles.
#' @param theme Theme: a name ([kgg_themes()], `"bw"`, ...), a ggplot2 theme
#'   or a function. See [kgg_register_theme()].
#' @param base_size Base font size passed to the theme.
#' @param palette Colours for discrete `color`/`fill`: a vector (named to
#'   fix level colours), a palette name ([kgg_palettes()]) or a function of
#'   `n`. Default: the theme palette.
#' @param legend `"right"`, `"bottom"`, `"top"`, `"left"`, `"none"`/`FALSE`,
#'   or `c(x, y)` to place it inside the panel.
#' @param facet Facet variable(s): one name (wrap), two names (row, column
#'   grid) or a formula (`panel ~ .` for a column of panels). Layers with their
#'   own data share the panels, in the same order.
#' @param facet_args Named list of extra arguments for
#'   [ggplot2::facet_wrap()]/[ggplot2::facet_grid()], e.g.
#'   `list(scales = "free_y")`. With `switch`, the strips are placed outside
#'   the axes.
#' @param new_data For the `kggplot` method: data of the new layer (default:
#'   the data of the first layer).
#' @param ... Extra parameters of the geometry (`size = 3` is an aesthetic
#'   argument, but `width`, `bins`, `linewidth`, `show.legend`... go here).
#'
#' @return An object of class `kggplot`.
#'
#' @examples
#' # scatter plot, coloured, themed: one call
#' kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
#'         title = "Iris", theme = "inrae")
#'
#' # several y columns at once, long-format handled for you
#' kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"),
#'         type = "line")
#'
#' # univariate types
#' kggplot(iris, y = "Sepal.Length", color = "Species", type = "density")
#'
#' # time series input
#' kggplot(AirPassengers, title = "Air passengers", theme = "minimal")
#'
#' # a band around a line, from ymin / ymax columns
#' d <- data.frame(t = 1:20, m = sin(1:20 / 3))
#' d$lo <- d$m - 0.2
#' d$hi <- d$m + 0.2
#' kggplot(d, "t", "m", ymin = "lo", ymax = "hi", type = "ribbon") +
#'   kggplot(d, "t", "m", type = "line")
#'
#' # superpose a second dataset: consistent colours and a shared legend
#' obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
#' sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))
#' kggplot(obs, "t", "v", color = "Observed", type = "point", theme = "bw") +
#'   kggplot(sim, "t", "v", color = "Simulated", type = "line")
#'
#' @export
kggplot <- function(data, ...) {
  UseMethod("kggplot")
}

#' @export
#' @rdname kggplot
kggplot.default <- function(
  data,
  x = NULL, y = NULL, color = NULL, fill = NULL, group = NULL, size = NULL,
  shape = NULL, alpha = NULL, linetype = NULL, label = NULL,
  ymin = NULL, ymax = NULL, xintercept = NULL, yintercept = NULL,
  vars = NULL, type = NULL,
  title = NULL, subtitle = NULL, caption = NULL, xlab = NULL, ylab = NULL,
  labels = NULL,
  theme = NULL, base_size = NULL, palette = NULL, legend = NULL,
  facet = NULL, facet_args = NULL,
  ...
) {
  params <- list(...)
  if (!is.null(params$colour)) {
    color <- color %||% params$colour
    params$colour <- NULL
  }
  source <- as_kdata(data)

  args <- norm_list(list(
    x = x, y = y, colour = color, fill = fill, group = group, size = size,
    shape = shape, alpha = alpha, linetype = linetype, label = label,
    ymin = ymin, ymax = ymax, xintercept = xintercept, yintercept = yintercept
  ))
  vars <- norm_list(vars)
  for (nm in setdiff(names(vars), names(args))) args[[nm]] <- vars[[nm]]
  unknown <- setdiff(names(args), std_aes)
  if (length(unknown)) {
    stop("Unknown aesthetic(s) in `vars`: ", paste(unknown, collapse = ", "),
         call. = FALSE)
  }

  explicit <- norm_list(c(
    list(title = title, subtitle = subtitle, caption = caption,
         x = xlab, y = ylab),
    as.list(labels)
  ))

  obj <- list(
    layers = list(new_layer(source, args, type, params)),
    labels = explicit,
    theme = theme, base_size = base_size, palette = palette, legend = legend,
    facet = facet, facet_args = facet_args,
    extras = list()
  )
  class(obj) <- "kggplot"
  obj
}

#' @export
#' @rdname kggplot
kggplot.kggplot <- function(data, new_data = NULL, ...) {
  kgg_add(data, new_data, ...)
}
