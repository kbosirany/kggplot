# Save a kggplot to a file

Thin wrapper around
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
that accepts a `kggplot`.

## Usage

``` r
kgg_save(p, filename, ...)
```

## Arguments

- p:

  A `kggplot` or `ggplot`.

- filename:

  File name to create on disk.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The file name, invisibly.
