# Generate a colour palette for a vector of values

Returns a named vector of colours, one per unique value of `x`. If there
are at most `length(main_colors)` values the first colours are used,
otherwise the colours are interpolated.

## Usage

``` r
get_color_palette(x, theme = NULL, main_colors = NULL)
```

## Arguments

- x:

  A vector of values.

- theme:

  Name of a registered theme or palette whose colours are used.

- main_colors:

  Character vector of base colours (overrides `theme`).

## Value

A named character vector of colours.

## Examples

``` r
get_color_palette(c("A", "B", "C"), main_colors = c("red", "green", "blue"))
#>       A       B       C 
#>   "red" "green"  "blue" 
get_color_palette(c("A", "B"), theme = "inrae")
#>         A         B 
#> "#00a3a6" "#9dc544" 
```
