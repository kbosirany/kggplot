# kggplot 0.0.0.9000

* Première version, extraite de kplot (partie ggplot2) et refactorée.
* `kggplot()` dessine un graphique complet en un appel : mise en forme des
  données (plusieurs `y` empilés en format long), variables, type de
  graphique (deviné si omis), titres, thème, palette, légende et facettes.
  Le résultat est un objet S3 `kggplot`, converti en `ggplot` à l'affichage
  (`as_ggplot()`).
* Composition : `+` entre deux `kggplot` (couleurs et légende partagées),
  `kggplot(p, data)`, `kgg_add()`, et ajout de composants ggplot2 avec `+`.
  Modificateurs : `kgg_labs()`, `kgg_theme()`, `kgg_palette()`,
  `kgg_legend()`, `kgg_facet()`, `kgg_save()`.
* `as_kdata()` (S3) convertit les entrées : `data.frame`, `ts`, matrice,
  vecteur, liste nommée.
* Registres extensibles : `kgg_register_type()`, `kgg_register_theme()`,
  `kgg_register_palette()`.
* Thème et palette `"inrae"` intégrés (palette de la charte INRAE), sans
  dépendance à InraeThemes ; couleurs conformes à la charte graphique INRAE
  v4.2 ; polices réglables avec `options(kggplot.base_family = )` et
  `options(kggplot.title_family = )`.
* `get_color_palette()` n'a plus de paramètre `cfg` : les palettes sont dans
  le registre de kggplot.
