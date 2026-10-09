# Number of rows and columns of a grid

Without constraint, picks the layout whose width/height ratio is closest
to `ratio` (the most square by default), with no empty row or column
and, a mild penalty for empty cells; ties go to the widest shape. With
`nrow` and/or `ncol`, the missing dimension is deduced and the layout is
checked: the `n` plots must fit in the grid (error otherwise), and empty
rows or columns are reported (warning, or error when `strict = TRUE`).

## Usage

``` r
kgg_grid_dims(
  n,
  nrow = NULL,
  ncol = NULL,
  ratio = 1,
  byrow = TRUE,
  strict = FALSE
)
```

## Arguments

- n:

  Number of plots.

- nrow, ncol:

  Optional imposed dimensions.

- ratio:

  Target width/height ratio.

- byrow:

  Is the grid filled by row?

- strict:

  Turn the empty rows/columns warning into an error.

## Value

A list with `nrow` and `ncol`.

## Examples

``` r
kgg_grid_dims(5)
#> $nrow
#> [1] 2
#> 
#> $ncol
#> [1] 3
#> 
kgg_grid_dims(5, ncol = 2)
#> $nrow
#> [1] 3
#> 
#> $ncol
#> [1] 2
#> 
kgg_grid_dims(6, ratio = 16 / 9)
#> $nrow
#> [1] 2
#> 
#> $ncol
#> [1] 3
#> 
```
