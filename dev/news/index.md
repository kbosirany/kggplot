# Changelog

## kggplot 0.0.0.9000

- Première version, extraite de kplot (partie ggplot2) et refactorée.
- [`kggplot()`](https://kbosirany.github.io/kggplot/dev/reference/kggplot.md)
  dessine un graphique complet en un appel : mise en forme des données
  (plusieurs `y` empilés en format long), variables, type de graphique
  (deviné si omis), titres, thème, palette, légende et facettes. Le
  résultat est un objet S3 `kggplot`, converti en `ggplot` à l’affichage
  ([`as_ggplot()`](https://kbosirany.github.io/kggplot/dev/reference/as_ggplot.md)).
- Composition : `+` entre deux `kggplot` (couleurs et légende
  partagées), `kggplot(p, data)`,
  [`kgg_add()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  et ajout de composants ggplot2 avec `+`. Modificateurs :
  [`kgg_labs()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_theme()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_palette()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_legend()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_facet()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_modify.md),
  [`kgg_save()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_save.md).
- [`as_kdata()`](https://kbosirany.github.io/kggplot/dev/reference/as_kdata.md)
  (S3) convertit les entrées : `data.frame`, `ts`, matrice, vecteur,
  liste nommée.
- Registres extensibles :
  [`kgg_register_type()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_type.md),
  [`kgg_register_theme()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md),
  [`kgg_register_palette()`](https://kbosirany.github.io/kggplot/dev/reference/kgg_register_theme.md).
- Thème et palette `"inrae"` intégrés (palette de la charte INRAE), sans
  dépendance à InraeThemes ; couleurs conformes à la charte graphique
  INRAE v4.2 ; polices réglables avec `options(kggplot.base_family = )`
  et `options(kggplot.title_family = )`.
- [`get_color_palette()`](https://kbosirany.github.io/kggplot/dev/reference/get_color_palette.md)
  n’a plus de paramètre `cfg` : les palettes sont dans le registre de
  kggplot.
