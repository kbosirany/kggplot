# kggplot (development version)

* Secondary y axis: `y2 = "column"` draws columns on a second axis on the right
  (title with `ylab2`, or `kgg_labs(y2 = )`). The series of `y2` are mapped
  linearly onto the range of the primary series, and the axis on the right is
  the exact inverse of the map, the same in every layer and every panel.
  Constant, missing, negative and very different series are handled; the series
  of the right axis are dashed (lines). Works with the types `point`, `jitter`,
  `line`, `path`, `step` and `smooth`; bars and areas, `ymin`/`ymax` and a
  missing primary series are refused with a clear message.

* `sf` objects are supported: the geometry is kept (`as_kdata.sf()`) and the
  new plot type `sf` draws a map (`kggplot(sf, fill = "column")`), also with
  facets and discrete fills.

* New plot types: `ribbon` (band between `ymin` and `ymax`), `pointrange` and
  `errorbar` (black, not coloured by series), `hline` and `vline` (reference
  lines) and `blank` (trains the scales). `ymin`, `ymax`, `xintercept` and
  `yintercept` are new aesthetics; with several `y` columns, `ymin` and `ymax`
  are stacked with them (one column per `y`, or one shared column).
* New helpers `kgg_hline()`, `kgg_vline()` and `kgg_limits()`: reference lines
  in every panel or in the panels of a data frame only, and forced axis limits
  for some panels with free scales (#7).
* Layers with their own data now share the panels of a facet variable, in the
  same order, whatever the type (factor or character) of the column.
* `switch` in `facet_args` places the strips outside the axes.
* `kgg_register_type()` gains `series = "none"`, `free` and `intercept`; the
  defaults of a type (e.g. the black colour of `pointrange`) give way to an
  aesthetic the user maps.
* Fix: positional aesthetics are matched exactly (`x` no longer matches
  `xintercept`).

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
