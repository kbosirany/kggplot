# kggplot

ggplot2 is powerful, but a basic figure often costs a dozen lines.
**kggplot** draws a complete plot in one call, and plots stay composable
through the `kggplot` S3 class.

```r
library(kggplot)

kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
        title = "Iris", theme = "inrae")
```

## What one call handles

| Concern | Argument | Example |
|---|---|---|
| Input data | `data` (S3 `as_kdata()`) | data frame, tibble, `ts`, matrix, vector, named list |
| Reshaping | `y` | `y = c("a", "b")` or `y = "all"` → long format + colour by series |
| Variables | `x y color fill group size shape alpha linetype label` | column names; `I("red")` for fixed values |
| Plot type | `type` | `"point"`, `"line"`, `"bar"`, `"density"`, `"smooth"`, … (guessed if omitted) |
| Titles | `title subtitle caption xlab ylab labels` | `NA` removes a title |
| Theme / palette | `theme base_size palette` | registered names, any `theme_<name>()`, ggplot2 themes |
| Legend | `legend` | `"bottom"`, `"none"`, `c(x, y)` |
| Facets | `facet facet_args` | `"Species"`, `c("row", "col")`, `~ a`, `".series"` |
| Geometry options | `...` | `bins = 10`, `linewidth = 1`, `width = .5` |

## Composing plots

```r
obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))

kggplot(obs, "t", "v", color = "Observed", type = "point", theme = "inrae") +
  kggplot(sim, "t", "v", color = "Simulated", type = "line")
```

Layers share one legend and one palette (a level keeps its colour whatever the
layer). The same can be written `kggplot(p, sim, ...)` or `kgg_add(p, sim, ...)`.
Anything from ggplot2 can be added with `+` (`theme()`, `scale_*()`,
`geom_hline()`, ...). Pipe-friendly setters change one thing at a time:

```r
p |>
  kgg_labs(title = "New title") |>
  kgg_theme("bw", base_size = 14) |>
  kgg_facet("Species", scales = "free") |>
  kgg_legend("bottom")
```

Convert with `as_ggplot(p)` to continue in plain ggplot2; `kgg_save()` and
`autoplot()` also accept a kggplot.

## Extending

Everything is S3 or a registry:

* `as_kdata()` — teach kggplot a new input class;
* `kgg_register_type()` — a new plot type;
* `kgg_register_theme()` / `kgg_register_palette()` — your house style.
  `options(kggplot.theme = "inrae")` makes it the default.

## Install

```r
remotes::install_github("kbosirany/kggplot")
```
