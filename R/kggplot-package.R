#' @keywords internal
"_PACKAGE"

# Internal registries (types, themes, palettes), filled in .onLoad().
.kgg <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .kgg$types <- list()
  .kgg$themes <- list()
  .kgg$palettes <- list()
  register_builtin_palettes()
  register_builtin_themes()
  register_builtin_types()
}
NULL
