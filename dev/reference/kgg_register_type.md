# Plot types

A *type* maps a short name (`"point"`, `"line"`, `"bar"`, ...) to a
ggplot2 geometry plus default parameters. Types live in a registry, so
you can add your own with `kgg_register_type()`.

## Usage

``` r
kgg_register_type(
  name,
  geom,
  params = list(),
  univariate = FALSE,
  series = c("colour", "fill", "none"),
  extra = NULL,
  free = FALSE,
  intercept = NULL
)

kgg_types()
```

## Arguments

- name:

  Name of the type.

- geom:

  A function building a ggplot2 layer, e.g.
  [ggplot2::geom_point](https://ggplot2.tidyverse.org/reference/geom_point.html).
  It is called with `mapping`, `data` and the layer parameters.

- params:

  Default parameters passed to `geom`.

- univariate:

  If `TRUE`, the type summarises one variable (histogram, density, ...):
  `y` is ignored and used as `x` when `x` is missing.

- series:

  Aesthetic (`"colour"` or `"fill"`) mapped to the series name when
  several `y` variables are plotted, or `"none"` for no default mapping
  (e.g. black error bars).

- extra:

  Optional function without argument returning an extra ggplot2
  component (scale, limits, ...) added with the layer.

- free:

  If `TRUE`, `x` and `y` are optional and the layer gives no axis title
  (e.g. `blank`).

- intercept:

  `"xintercept"` or `"yintercept"` for a reference line type: the layer
  reads that aesthetic instead of `x` and `y`.

## Value

`kgg_register_type()` returns `name` invisibly; `kgg_types()` a
character vector of the registered types.

## Details

Built-in types: `point`, `jitter`, `line`, `path`, `step`, `area`,
`smooth`, `text`, `bar` (alias `col`), `bar_dodge`, `count`,
`histogram`, `density`, `ecdf` (alias `cumFreq`), `boxplot`, `violin`,
`convexhull` (needs the ggConvexHull package), and

- `ribbon`: a band between `ymin` and `ymax`, filled with the series
  colour (`alpha = 0.2`, no outline);

- `pointrange` and `errorbar`: a point (`y`) with its range (`ymin`,
  `ymax`), black and not coloured by series;

- `hline` and `vline`: reference lines at `yintercept` / `xintercept`
  (see
  [`kgg_hline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md)
  and
  [`kgg_vline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md));

- `blank`: draws nothing but trains the scales, to force the limits of
  some panels (see
  [`kgg_limits()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md)).

## Examples

``` r
kgg_types()
#>  [1] "point"      "jitter"     "line"       "path"       "step"      
#>  [6] "area"       "smooth"     "text"       "bar"        "col"       
#> [11] "bar_dodge"  "count"      "histogram"  "density"    "ecdf"      
#> [16] "cumFreq"    "boxplot"    "violin"     "ribbon"     "pointrange"
#> [21] "errorbar"   "hline"      "vline"      "blank"      "convexhull"
kgg_register_type("hollow", ggplot2::geom_point, params = list(shape = 1))
kggplot(iris, "Sepal.Length", "Sepal.Width", type = "hollow")

```
