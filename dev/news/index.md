# Changelog

## kggplot (development version)

## kggplot 0.1.0

- First version, extracted from kplot (its ggplot2 part) and refactored.
- [`kggplot()`](https://kbosirany.github.io/kggplot/dev/reference/kggplot.md)
  draws a complete plot in one call: data reshaping (several `y` columns
  are stacked in long format), variables, plot type (guessed when
  omitted), titles, theme, palette, legend and facets. The result is a
  `kggplot` S3 object, turned into a `ggplot` when printed
  ([`as_ggplot()`](https://kbosirany.github.io/kggplot/dev/reference/as_ggplot.md)).
- Composition: `+` between two `kggplot` objects (shared colours and
  legend), `kggplot(p, data)`,
  [`kgg_add()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  and ggplot2 components added with `+`. Modifiers:
  [`kgg_labs()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_theme()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_palette()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_legend()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_facet()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_save()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_save.md).
- [`as_kdata()`](https://kbosirany.github.io/kggplot/dev/reference/as_kdata.md)
  (S3) converts the input: `data.frame`, `ts`, matrix, vector, named
  list.
- Extensible registries:
  [`kgg_register_type()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_type.md),
  [`kgg_register_theme()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md),
  [`kgg_register_palette()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md).
- Built-in `"inrae"` theme and palette following the INRAE graphic
  charter v4.2, with no dependency on InraeThemes; fonts can be set with
  `options(kggplot.base_family = )` and
  `options(kggplot.title_family = )`.
- [`get_color_palette()`](https://kbosirany.github.io/kggplot/dev/reference/get_color_palette.md)
  no longer has a `cfg` argument: palettes live in the kggplot registry.
- “Get started” vignette.
