# Add layers or ggplot2 components to a kggplot

- `kggplot + kggplot`: appends the layers of the right-hand plot; its
  theme, titles, legend, palette and facets override the left ones when
  specified.

- `kggplot + <ggplot2 component>` (theme, scale, coord, labs, geom...):
  stored and applied last, in order.

## Usage

``` r
# S3 method for class 'kggplot'
e1 + e2
```

## Arguments

- e1:

  A `kggplot`.

- e2:

  A `kggplot` or a ggplot2 component.

## Value

A `kggplot`.

## Examples

``` r
p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
p + ggplot2::theme_bw() + ggplot2::geom_hline(yintercept = 3)

```
