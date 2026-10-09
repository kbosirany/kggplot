# Compose plots into a grid

`kgg_grid()` arranges several plots in a grid. Plots can be given one by
one, as lists (possibly nested), or both.
[`kggplot()`](https://kbosirany.github.io/kggplot/reference/kggplot.md)
objects, regular `ggplot` objects and other `kgg_grid` objects are
accepted. By default the grid is as square as possible (see
[`kgg_grid_dims()`](https://kbosirany.github.io/kggplot/reference/kgg_grid_dims.md))
and identical legends are merged into a single one, as in a facet.

## Usage

``` r
kgg_grid(
  ...,
  nrow = NULL,
  ncol = NULL,
  ratio = 1,
  byrow = TRUE,
  scales = c("shared", "free"),
  legend = c("collect", "each", "none"),
  legend_position = c("right", "bottom", "left", "top"),
  titles = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  tags = NULL,
  widths = NULL,
  heights = NULL,
  strict = FALSE
)
```

## Arguments

- ...:

  Plots (`kggplot`, `ggplot`, `kgg_grid`) or lists of plots. Names
  become the title of each cell (see `titles`).

- nrow, ncol:

  Number of rows and columns. Leave both `NULL` for the most square
  grid; give one and the other is deduced; give both to force the grid.
  The number of plots must fit in the grid (error otherwise) and a grid
  with entirely empty rows or columns triggers a warning (an error when
  `strict = TRUE`).

- ratio:

  Target width/height ratio of the grid when `nrow` and `ncol` are not
  given (1 = square, 16/9 = wide).

- byrow:

  Fill the grid by row (`TRUE`, default) or by column.

- scales:

  `"shared"` (default) gives the same colour to the same level in every
  plot and the same colour limits to continuous colour/fill scales, so a
  legend merged across plots is truthful (as in a facet). `"free"` keeps
  the scales of each plot. Only `kggplot` objects are unified: plain
  `ggplot` objects and nested grids are left untouched.

- legend:

  `"collect"` (default) merges the legends of all plots into one shared
  legend, `"each"` keeps one legend per plot, `"none"` removes every
  legend.

- legend_position:

  Position of the shared legend (`"right"`, `"bottom"`, `"left"`,
  `"top"`).

- titles:

  Use the names of the plots as cell titles? `NULL` (default) does so
  when at least one plot is named.

- title, subtitle, caption:

  Overall annotations of the grid.

- tags:

  Panel tags: `NULL` for none, or `"A"`, `"a"`, `"1"`, `"I"`, `"i"` to
  number the cells.

- widths, heights:

  Relative widths of the columns and heights of the rows.

- strict:

  Turn the warning about empty rows or columns into an error.

## Value

A `kgg_grid`, printed as a patchwork; convert it with
[`as_ggplot()`](https://kbosirany.github.io/kggplot/reference/as_ggplot.md).
Add plots with `+`.

## Examples

``` r
a <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
b <- kggplot(iris, "Petal.Length", "Petal.Width", color = "Species")
kgg_grid(a, b, a, title = "Iris")

kgg_grid(list(a = a, b = b), ncol = 1, tags = "A")

kgg_grid_dims(7)
#> $nrow
#> [1] 3
#> 
#> $ncol
#> [1] 3
#> 
```
