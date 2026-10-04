# Draw a complete plot in one call

`kggplot()` builds a ggplot2 graphic (reshaping, mappings, geometry,
labels, theme, palette, legend, facets) from a data object and a few
short arguments, and returns a `kggplot` object. Print it to draw it,
compose it with `+`, or convert it with
[`as_ggplot()`](https://kbosirany.github.io/kggplot/dev/reference/as_ggplot.md).

## Usage

``` r
kggplot(data, ...)

# Default S3 method
kggplot(
  data,
  x = NULL,
  y = NULL,
  color = NULL,
  fill = NULL,
  group = NULL,
  size = NULL,
  shape = NULL,
  alpha = NULL,
  linetype = NULL,
  label = NULL,
  ymin = NULL,
  ymax = NULL,
  xintercept = NULL,
  yintercept = NULL,
  vars = NULL,
  type = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  xlab = NULL,
  ylab = NULL,
  labels = NULL,
  theme = NULL,
  base_size = NULL,
  palette = NULL,
  legend = NULL,
  facet = NULL,
  facet_args = NULL,
  ...
)

# S3 method for class 'kggplot'
kggplot(data, new_data = NULL, ...)
```

## Arguments

- data:

  A data frame, or anything
  [`as_kdata()`](https://kbosirany.github.io/kggplot/dev/reference/as_kdata.md)
  understands (`ts`, matrix, vector, named list). If a `kggplot`, a
  layer is added to it.

- ...:

  Extra parameters of the geometry (`size = 3` is an aesthetic argument,
  but `width`, `bins`, `linewidth`, `show.legend`... go here).

- x, y, color, fill, group, size, shape, alpha, linetype, label:

  Aesthetics, see Details. `colour` is accepted as an alias of `color`.

- ymin, ymax:

  Columns holding the lower and upper bounds of a band or of error bars,
  for the types `ribbon`, `pointrange` and `errorbar`.

- xintercept, yintercept:

  Column of the position of a reference line, for the types `vline` and
  `hline` (see
  [`kgg_hline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md)
  and
  [`kgg_vline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md)).

- vars:

  Optional named list of aesthetics (`list(x = "a", y = "b")`), an
  alternative to the arguments above (they take precedence).

- type:

  Plot type, see
  [`kgg_types()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_type.md);
  or a geom function. By default guessed from the data (line for dates
  and `ts`, point for numeric `x`/`y`, bar for a categorical `x`,
  histogram/count for a lone `x`).

- title, subtitle, caption:

  Plot titles.

- xlab, ylab:

  Axis titles (default: the variable names). Use `NA` to remove a title.

- labels:

  Named list of titles (`title`, `x`, `y`, `color`, `fill`...) for
  anything not covered by the arguments above, e.g. legend titles.

- theme:

  Theme: a name
  ([`kgg_themes()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md),
  `"bw"`, ...), a ggplot2 theme or a function. See
  [`kgg_register_theme()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md).

- base_size:

  Base font size passed to the theme.

- palette:

  Colours for discrete `color`/`fill`: a vector (named to fix level
  colours), a palette name
  ([`kgg_palettes()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md))
  or a function of `n`. Default: the theme palette.

- legend:

  `"right"`, `"bottom"`, `"top"`, `"left"`, `"none"`/`FALSE`, or
  `c(x, y)` to place it inside the panel.

- facet:

  Facet variable(s): one name (wrap), two names (row, column grid) or a
  formula (`panel ~ .` for a column of panels). Layers with their own
  data share the panels, in the same order.

- facet_args:

  Named list of extra arguments for
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html)/[`ggplot2::facet_grid()`](https://ggplot2.tidyverse.org/reference/facet_grid.html),
  e.g. `list(scales = "free_y")`. With `switch`, the strips are placed
  outside the axes.

- new_data:

  For the `kggplot` method: data of the new layer (default: the data of
  the first layer).

## Value

An object of class `kggplot`.

## Mapping aesthetics

`x`, `y`, `color`, `fill`, `group`, `size`, `shape`, `alpha`, `linetype`
and `label` take column names (strings). `ymin` and `ymax` (bands, error
bars) and `xintercept` and `yintercept` (reference lines) are columns
too. Special values:

- `y = c("a", "b")` or `y = "all"` plots several columns; they are
  stacked in long format and coloured by series (the pseudo-column
  `".series"` can be mapped to any aesthetic or facet). `ymin` and
  `ymax` then take either one column (used for every series) or one
  column per `y` column, in the same order.

- a string that is not a column, passed to `color`, `fill` or `group`,
  creates a legend entry: `color = "Observed"` names the layer.

- `I("red")` (or a number, for `size`, `alpha`...) is a fixed value, not
  a mapping.

- `x` omitted: the first column (or the row index if `y` is given).

- `y` omitted: all the other columns.

## Extending a plot

`kggplot(p, new_data, ...)` (with `p` a kggplot), `p + kggplot(...)` and
[`kgg_add()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md)
add a layer; colours stay consistent across layers. Any ggplot2
component can be added with `+` (`+ theme(...)`, `+ geom_hline()`,
`+ scale_x_log10()`), and is applied last.

## Examples

``` r
# scatter plot, coloured, themed: one call
kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
        title = "Iris", theme = "inrae")


# several y columns at once, long-format handled for you
kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"),
        type = "line")


# univariate types
kggplot(iris, y = "Sepal.Length", color = "Species", type = "density")


# time series input
kggplot(AirPassengers, title = "Air passengers", theme = "minimal")


# a band around a line, from ymin / ymax columns
d <- data.frame(t = 1:20, m = sin(1:20 / 3))
d$lo <- d$m - 0.2
d$hi <- d$m + 0.2
kggplot(d, "t", "m", ymin = "lo", ymax = "hi", type = "ribbon") +
  kggplot(d, "t", "m", type = "line")


# superpose a second dataset: consistent colours and a shared legend
obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))
kggplot(obs, "t", "v", color = "Observed", type = "point", theme = "bw") +
  kggplot(sim, "t", "v", color = "Simulated", type = "line")

```
