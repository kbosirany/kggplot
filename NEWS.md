# kggplot (development version)

# kggplot 0.1.0

* First version, extracted from kplot (its ggplot2 part) and refactored.
* `kggplot()` draws a complete plot in one call: data reshaping (several `y`
  columns are stacked in long format), variables, plot type (guessed when
  omitted), titles, theme, palette, legend and facets. The result is a
  `kggplot` S3 object, turned into a `ggplot` when printed (`as_ggplot()`).
* Composition: `+` between two `kggplot` objects (shared colours and legend),
  `kggplot(p, data)`, `kgg_add()`, and ggplot2 components added with `+`.
  Modifiers: `kgg_labs()`, `kgg_theme()`, `kgg_palette()`, `kgg_legend()`,
  `kgg_facet()`, `kgg_save()`.
* `as_kdata()` (S3) converts the input: `data.frame`, `ts`, matrix, vector,
  named list.
* Extensible registries: `kgg_register_type()`, `kgg_register_theme()`,
  `kgg_register_palette()`.
* Built-in `"inrae"` theme and palette following the INRAE graphic charter
  v4.2, with no dependency on InraeThemes; fonts can be set with
  `options(kggplot.base_family = )` and `options(kggplot.title_family = )`.
* `get_color_palette()` no longer has a `cfg` argument: palettes live in the
  kggplot registry.
* "Get started" vignette.
