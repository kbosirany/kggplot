#' Modify a kggplot
#'
#' Pipe-friendly setters. Each returns a modified `kggplot`; unspecified
#' arguments are left unchanged.
#'
#' `kgg_add()` appends a layer. Aesthetics you do not give (`x`, `y`,
#' `color`...) are inherited from the first layer when they refer to columns
#' that exist in the new data; `type` is guessed again.
#'
#' @param p A `kggplot`.
#' @param data Data of the new layer (default: the data of the first layer,
#'   handy for e.g. adding a smoother).
#' @param ... For `kgg_add()`: arguments of [kggplot()] (aesthetics, `type`,
#'   geometry parameters, ...). For `kgg_labs()`: legend titles such as
#'   `color = "Species"`. For `kgg_facet()`: arguments of the facet function.
#' @param title,subtitle,caption,x,y Titles. `NA` removes a title.
#' @param theme,base_size,palette,legend,facet See [kggplot()].
#'
#' @return A `kggplot`.
#'
#' @examples
#' p <- kggplot(iris, "Sepal.Length", "Sepal.Width", color = "Species")
#' p |>
#'   kgg_add(type = "smooth") |>
#'   kgg_labs(title = "Iris", x = "Sepal length") |>
#'   kgg_theme("bw", base_size = 14) |>
#'   kgg_facet("Species") |>
#'   kgg_legend("none")
#'
#' @name kgg_modify
NULL

#' @export
#' @rdname kgg_modify
kgg_add <- function(p, data = NULL, ...) {
  check_kggplot(p)
  dots <- list(...)
  first <- p$layers[[1L]]
  given <- c(norm_aes_names(names(dots)), names(norm_list(dots$vars)))
  new_src <- if (is.null(data)) first$source else as_kdata(data)
  # bands and intercepts belong to one layer, they are not inherited
  inherited <- setdiff(
    names(first$mapped), c(y_aes, "xintercept", "yintercept")
  )
  for (a in setdiff(inherited, given)) {
    if (all(first$mapped[[a]] %in% c(names(new_src), ".series", "all"))) {
      dots[[a]] <- first$mapped[[a]]
    }
  }
  layer_plot <- rlang::exec(kggplot, new_src, !!!dots)
  merge_kggplot(p, layer_plot)
}

#' @export
#' @rdname kgg_modify
kgg_labs <- function(p, title = NULL, subtitle = NULL, caption = NULL,
                     x = NULL, y = NULL, ...) {
  check_kggplot(p)
  new <- norm_list(c(
    list(title = title, subtitle = subtitle, caption = caption, x = x, y = y),
    list(...)
  ))
  p$labels <- utils::modifyList(p$labels, new)
  p
}

#' @export
#' @rdname kgg_modify
kgg_theme <- function(p, theme, base_size = NULL, palette = NULL) {
  check_kggplot(p)
  p$theme <- theme
  if (!is.null(base_size)) p$base_size <- base_size
  if (!is.null(palette)) p$palette <- palette
  p
}

#' @export
#' @rdname kgg_modify
kgg_palette <- function(p, palette) {
  check_kggplot(p)
  p$palette <- palette
  p
}

#' @export
#' @rdname kgg_modify
kgg_legend <- function(p, legend) {
  check_kggplot(p)
  p$legend <- legend
  p
}

#' @export
#' @rdname kgg_modify
kgg_facet <- function(p, facet, ...) {
  check_kggplot(p)
  p$facet <- facet
  p$facet_args <- list(...)
  p
}

check_kggplot <- function(p) {
  if (!inherits(p, "kggplot")) {
    stop("`p` must be a kggplot object.", call. = FALSE)
  }
}

# Combine two kggplots: layers are appended, settings given on the right
# override those on the left.
merge_kggplot <- function(a, b) {
  a$layers <- c(a$layers, b$layers)
  a$labels <- utils::modifyList(a$labels, b$labels)
  for (nm in c("theme", "base_size", "palette", "legend", "facet",
               "facet_args")) {
    if (!is.null(b[[nm]])) a[[nm]] <- b[[nm]]
  }
  a$extras <- c(a$extras, b$extras)
  a
}
