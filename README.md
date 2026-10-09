
<!-- README.md is generated from README.Rmd. Please edit that file,
then run devtools::build_readme(). -->

# kggplot

<!-- badges: start -->

[![R-CMD-check](https://github.com/kbosirany/kggplot/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kbosirany/kggplot/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/kbosirany/kggplot/graph/badge.svg)](https://app.codecov.io/gh/kbosirany/kggplot)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: AGPL
v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

<!-- badges: end -->

Site: <https://kbosirany.github.io/kggplot/> (development version:
[/dev](https://kbosirany.github.io/kggplot/dev/))

ggplot2 is powerful, but even a simple figure quickly costs a dozen
lines. **kggplot** draws a complete plot in one short call (data
reshaping, mappings, geometry, titles, theme, palette, legend, facets),
and plots stay composable through the `kggplot` S3 class. It is the
ggplot2 part of [kplot](https://github.com/kbosirany/kplot).

## Installation

``` r
# install.packages("pak")
pak::pak("kbosirany/kggplot")
```

## Example

``` r
library(kggplot)

kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
        title = "Iris", theme = "inrae")
```

<img src="man/figures/README-example-1.png" width="70%" />

``` r

# Several columns in y: long format is handled for you
kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"), type = "line")
```

<img src="man/figures/README-example-2.png" width="70%" />

``` r

# Superpose two datasets: shared palette and legend
obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))

kggplot(obs, "t", "v", color = "Observed", type = "point") +
  kggplot(sim, "t", "v", color = "Simulated", type = "line")
```

<img src="man/figures/README-example-3.png" width="70%" />

``` r

# Several plots in one grid: square layout, a single shared legend
a <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
b <- kggplot(iris, "Petal.Length", "Petal.Width", color = "Species")
kgg_grid(a, b, a, b, title = "Iris", tags = "A")
```

<img src="man/figures/README-example-4.png" width="70%" />

See `vignette("kggplot")` (“Get started”) for the full tour: input data,
plot types, titles, themes and palettes, facets, composing plots, grids,
and extending kggplot with your own input classes, plot types and
themes.

Branch, version and release conventions are those of
[kpkg.r](https://github.com/kbosirany/kpkg.r):
`vignette("workflow", package = "kpkg.r")`.
