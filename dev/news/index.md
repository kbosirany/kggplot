# Changelog

## kggplot 0.3.0

This version adds grids: several plots composed in one figure.

- New
  [`kgg_grid()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_grid.md)
  composes kggplot, ggplot and nested lists of plots into a grid (via
  ‘patchwork’). The layout is as square as possible by default
  ([`kgg_grid_dims()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_grid_dims.md)),
  can be forced with `nrow`/`ncol` (checked: too-small grids are an
  error, empty rows or columns a warning), identical legends are merged
  into one (`legend = "collect"`), and titles, tags, widths and heights
  are supported.

## kggplot 0.2.0

This version draws maps (`sf` objects) and adds plot types and helpers
for bands, reference lines and forced axis limits.

- `sf` objects are supported: the geometry is kept
  ([`as_kdata.sf()`](https://kbosirany.github.io/kggplot/dev/reference/as_kdata.md))
  and the new plot type `sf` draws a map
  (`kggplot(sf, fill = "column")`), also with facets and discrete fills.

- New plot types: `ribbon` (band between `ymin` and `ymax`),
  `pointrange` and `errorbar` (black, not coloured by series), `hline`
  and `vline` (reference lines) and `blank` (trains the scales). `ymin`,
  `ymax`, `xintercept` and `yintercept` are new aesthetics; with several
  `y` columns, `ymin` and `ymax` are stacked with them (one column per
  `y`, or one shared column).

- New helpers
  [`kgg_hline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md),
  [`kgg_vline()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md)
  and
  [`kgg_limits()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_reference.md):
  reference lines in every panel or in the panels of a data frame only,
  and forced axis limits for some panels with free scales
  ([\#7](https://github.com/kbosirany/kggplot/issues/7)).

- Layers with their own data now share the panels of a facet variable,
  in the same order, whatever the type (factor or character) of the
  column.

- `switch` in `facet_args` places the strips outside the axes.

- [`kgg_register_type()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_type.md)
  gains `series = "none"`, `free` and `intercept`; the defaults of a
  type (e.g. the black colour of `pointrange`) give way to an aesthetic
  the user maps.

- Fix: positional aesthetics are matched exactly (`x` no longer matches
  `xintercept`).

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
