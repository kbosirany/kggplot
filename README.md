# kggplot

<!-- badges: start -->
[![R-CMD-check][check-badge]][check]

[check-badge]:
https://github.com/kbosirany/kggplot/actions/workflows/R-CMD-check.yaml/badge.svg
[check]:
https://github.com/kbosirany/kggplot/actions/workflows/R-CMD-check.yaml
<!-- badges: end -->

Site : <https://kbosirany.github.io/kggplot/> (version en développement :
[/dev](https://kbosirany.github.io/kggplot/dev/))

ggplot2 est puissant, mais une figure simple demande vite une dizaine de
lignes. **kggplot** dessine un graphique complet en un seul appel, et les
graphiques restent composables grâce à la classe S3 `kggplot`. C'est la partie
ggplot2 de [kplot](https://github.com/kbosirany/kplot).

## Installation

```r
# install.packages("pak")
pak::pak("kbosirany/kggplot")
```

## Utilisation

```r
library(kggplot)

kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species",
        title = "Iris", theme = "inrae")

# Plusieurs colonnes en y : le format long est géré pour vous
kggplot(iris, "Sepal.Length", c("Sepal.Width", "Petal.Width"), type = "line")
```

Ce qu'un seul appel gère :

| Besoin | Argument | Exemple |
|---|---|---|
| Données en entrée | `data` (S3 `as_kdata()`) | data frame, tibble, `ts`, matrice, vecteur, liste nommée |
| Mise en forme | `y` | `y = c("a", "b")` ou `y = "all"` : format long, couleur par série |
| Variables | `x y color fill group size shape alpha linetype label` | noms de colonnes ; `I("red")` pour une valeur fixe |
| Type de graphique | `type` | `"point"`, `"line"`, `"bar"`, `"density"`, `"smooth"`... (deviné si omis) |
| Titres | `title subtitle caption xlab ylab labels` | `NA` supprime un titre |
| Thème et palette | `theme base_size palette` | noms enregistrés, tout `theme_<nom>()`, thèmes ggplot2 |
| Légende | `legend` | `"bottom"`, `"none"`, `c(x, y)` |
| Facettes | `facet facet_args` | `"Species"`, `c("ligne", "colonne")`, `~ a`, `".series"` |
| Options de la géométrie | `...` | `bins = 10`, `linewidth = 1`, `width = .5` |

## Composer des graphiques

```r
obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))

kggplot(obs, "t", "v", color = "Observed", type = "point", theme = "inrae") +
  kggplot(sim, "t", "v", color = "Simulated", type = "line")
```

Les couches partagent une légende et une palette : un niveau garde sa
couleur quelle que soit la couche. On peut aussi écrire
`kggplot(p, sim, ...)` ou `kgg_add(p, sim, ...)`. Tout composant ggplot2 s'ajoute
avec `+` (`theme()`, `scale_*()`, `geom_hline()`...). Des modificateurs
compatibles avec le pipe changent un élément à la fois :

```r
p |>
  kgg_labs(title = "Nouveau titre") |>
  kgg_theme("bw", base_size = 14) |>
  kgg_facet("Species", scales = "free") |>
  kgg_legend("bottom")
```

`as_ggplot(p)` renvoie un `ggplot` pour continuer avec ggplot2 seul ;
`kgg_save()` et `autoplot()` acceptent aussi un `kggplot`.

## Étendre kggplot

Tout est S3 ou registre :

* `as_kdata()` : apprendre à kggplot une nouvelle classe d'entrée ;
* `kgg_register_type()` : un nouveau type de graphique ;
* `kgg_register_theme()` et `kgg_register_palette()` : votre charte
  graphique. `options(kggplot.theme = "inrae")` en fait le thème par défaut.

Le thème `"inrae"` est intégré à kggplot (palette de la charte INRAE et thème
minimal, sans dépendance). Il n'impose pas de police :
`options(kggplot.base_family = "Raleway")` pour utiliser Raleway. Pour le thème
du paquet [InraeThemes](https://github.com/davidcarayon/InraeThemes), passez-le
tel quel : `theme = InraeThemes::theme_inrae`.

Les conventions de branches, de versions et de publication sont celles de
[kpkg.r](https://github.com/kbosirany/kpkg.r) :
`vignette("workflow", package = "kpkg.r")`.
