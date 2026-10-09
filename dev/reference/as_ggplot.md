# Convert to a ggplot2 object

`as_ggplot()` renders a
[`kggplot()`](https://kbosirany.github.io/kggplot/dev/reference/kggplot.md)
specification into a regular `ggplot` object, which you can then
customise with any ggplot2 function or save with
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
Printing a kggplot does this implicitly.

## Usage

``` r
as_ggplot(x, ...)

# S3 method for class 'ggplot'
as_ggplot(x, ...)

# S3 method for class 'kggplot'
as_ggplot(x, ..., shared = NULL)

# S3 method for class 'kgg_grid'
as_ggplot(x, ...)
```

## Arguments

- x:

  A `kggplot`, a `kgg_grid` or a `ggplot` (returned unchanged).

- ...:

  Unused.

- shared:

  Colour and fill levels or limits imposed on a `kggplot`. Used by
  [`kgg_grid()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_grid.md)
  to share scales across plots; leave it `NULL`.

## Value

A `ggplot` object.

## Examples

``` r
p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
g <- as_ggplot(p)
class(g)
#> [1] "ggplot2::ggplot" "ggplot"          "ggplot2::gg"     "S7_object"      
#> [5] "gg"             
```
