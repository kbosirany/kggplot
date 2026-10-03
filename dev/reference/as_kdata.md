# Convert an input object to a data frame for kggplot

`as_kdata()` is the S3 entry point that turns whatever you hand to
[`kggplot()`](https://kbosirany.github.io/kggplot/dev/reference/kggplot.md)
into a plain data frame. Add a method to teach kggplot a new input
class. A method may set the attributes `kgg_x`, `kgg_y` (default
variables to plot) and `kgg_type` (default plot type) on the result;
they are only used when the call does not specify `x`, `y` or `type`.

## Usage

``` r
as_kdata(x, ...)

# S3 method for class 'data.frame'
as_kdata(x, ...)

# S3 method for class 'ts'
as_kdata(x, ...)

# S3 method for class 'matrix'
as_kdata(x, ...)

# S3 method for class 'numeric'
as_kdata(x, ...)

# S3 method for class 'logical'
as_kdata(x, ...)

# S3 method for class 'character'
as_kdata(x, ...)

# S3 method for class 'factor'
as_kdata(x, ...)

# S3 method for class 'list'
as_kdata(x, ...)

# Default S3 method
as_kdata(x, ...)
```

## Arguments

- x:

  Object to convert.

- ...:

  Unused, for method extensions.

## Value

A data frame.

## Details

Built-in methods: `data.frame` (and tibbles), `ts`/`mts`, `matrix`,
atomic vectors (numeric, character, factor, logical), `list` of
equal-length vectors.

## Examples

``` r
as_kdata(ts(c(1, 3, 2), start = 2000))
#>   time value
#> 1 2000     1
#> 2 2001     3
#> 3 2002     2
as_kdata(matrix(1:6, 3, dimnames = list(NULL, c("a", "b"))))
#>   a b
#> 1 1 4
#> 2 2 5
#> 3 3 6
as_kdata(c(2, 4, 8))
#>   index value
#> 1     1     2
#> 2     2     4
#> 3     3     8
```
