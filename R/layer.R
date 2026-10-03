# A layer = source data + how to read it. The heavy work (reshaping to long
# format, standardising column names) is done lazily by resolve_layer() when the
# plot is built, so facets/themes added later still see every column.

# Decide what a user-supplied aesthetic value means:
#  * column name(s)                -> "col"   (mapped to data)
#  * other string for colour/fill/group -> "const" (a legend entry, e.g. a
#    layer name such as "Observed")
#  * I("red"), numbers, other strings   -> "fixed" (plain geom parameter)
classify_aes <- function(name, value, cols) {
  if (inherits(value, "AsIs")) {
    class(value) <- setdiff(class(value), "AsIs")
    return(list(kind = "fixed", value = value))
  }
  if (is.character(value) || is.factor(value)) {
    return(classify_chr(name, as.character(value), cols))
  }
  if (name %in% c("x", "y")) {
    stop("`", name, "` must be column name(s) of the data.", call. = FALSE)
  }
  list(kind = "fixed", value = value)
}

classify_chr <- function(name, value, cols) {
  if (all(value %in% cols) || (name == "y" && identical(value, "all"))) {
    return(list(kind = "col", value = value))
  }
  if (name %in% c("x", "y")) {
    stop(
      "Column(s) not found in data for `", name, "`: ",
      paste(setdiff(value, cols), collapse = ", "),
      ". Available: ", paste(setdiff(cols, ".series"), collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (!name %in% c("colour", "fill", "group")) {
    return(list(kind = "fixed", value = value))
  }
  if (length(value) != 1L) {
    stop("`", name, "` must be a single column or label.", call. = FALSE)
  }
  list(kind = "const", value = value)
}

new_layer <- function(source, args, type = NULL, params = list()) {
  cols <- c(names(source), ".series")
  kinds <- lapply(names(args), function(a) classify_aes(a, args[[a]], cols))
  names(kinds) <- names(args)
  pick <- function(kind) {
    sel <- Filter(function(cl) cl$kind == kind, kinds)
    lapply(sel, function(cl) cl$value)
  }
  if (!is.null(type)) get_type(type) # validate early
  list(
    source = source, mapped = pick("col"), const = pick("const"),
    fixed = utils::modifyList(pick("fixed"), params), type = type
  )
}

# x and y columns: explicit, else the hints of as_kdata(), else the first
# column against all the others
default_xy <- function(src, mapped) {
  cols <- names(src)
  others <- unlist(mapped[setdiff(names(mapped), c("x", "y"))])
  x <- mapped$x
  y <- mapped$y
  if (is.null(x) && is.null(y)) {
    x <- attr(src, "kgg_x") %||% cols[1L]
    y <- attr(src, "kgg_y") %||% setdiff(cols, c(x, others))
  }
  if (identical(y, "all")) y <- setdiff(cols, c(x, others))
  list(x = x, y = if (length(y)) y)
}

# Stack the y columns of `d` in long format. Returns the data (rows repeated
# once per y column), the stacked values, the series factor and the number of
# rows.
stack_y <- function(d, x, y, keep_cols) {
  n0 <- nrow(d)
  k <- length(y)
  if (k == 0L) {
    series <- const_factor(if (identical(x, ".index")) "index" else x[1L], n0)
    return(list(d = d, val = NULL, series = series, n = n0))
  }
  if (k == 1L) {
    return(list(d = d, val = d[[y]], series = const_factor(y, n0), n = n0))
  }
  val <- unlist(lapply(y, function(cn) d[[cn]]), use.names = FALSE)
  d <- d[setdiff(names(d), setdiff(y, keep_cols))]
  d <- d[rep.int(seq_len(n0), k), , drop = FALSE]
  series <- structure(rep(seq_len(k), each = n0), levels = y, class = "factor")
  list(d = d, val = val, series = series, n = n0 * k)
}

# Standardised columns (x, y, colour...) of a layer
std_columns <- function(layer, d, st, x, uni, pivot_to_x, spec) {
  others <- layer$mapped[setdiff(names(layer$mapped), c("x", "y"))]
  k <- nlevels(st$series)
  out <- list()
  out$x <- if (pivot_to_x) {
    st$val
  } else if (identical(x, ".index")) {
    rep.int(seq_len(nrow(layer$source)), max(k, 1L))
  } else {
    d[[x]]
  }
  if (!uni) out$y <- st$val
  for (a in names(others)) {
    cn <- others[[a]]
    if (length(cn) != 1L) {
      stop("`", a, "` must be a single column.", call. = FALSE)
    }
    out[[a]] <- if (cn == ".series") st$series else d[[cn]]
  }
  for (a in names(layer$const)) out[[a]] <- const_factor(layer$const[[a]], st$n)
  out
}

# Colour (or fill) by series when several y are stacked and nothing is
# mapped to colour/fill; group by series x colour otherwise.
add_series_aes <- function(out, series, spec) {
  k <- nlevels(series)
  used <- k > 1L && is.null(out$colour) && is.null(out$fill)
  if (used) out[[spec$series]] <- series
  key <- out$group
  if (is.null(key) && !used) key <- out$colour %||% out$fill
  if (k > 1L && !is.null(key)) {
    out$group <- interaction(series, key, drop = TRUE)
  }
  list(out = out, used = used)
}

# Default axis / legend titles; NA means "no title"
layer_labels <- function(layer, x, y, uni, pivot_to_x, series_aes) {
  k <- length(y)
  others <- layer$mapped[setdiff(names(layer$mapped), c("x", "y"))]
  lab <- list()
  lab$x <- if (pivot_to_x) {
    if (k == 1L) y else "value"
  } else if (identical(x, ".index")) {
    "Index"
  } else {
    x[1L]
  }
  if (!uni) lab$y <- if (k == 1L) y else "value"
  for (a in intersect(names(others), legend_aes)) {
    lab[[a]] <- if (others[[a]] == ".series") NA_character_ else others[[a]]
  }
  for (a in intersect(names(layer$const), legend_aes)) {
    lab[[a]] <- NA_character_
  }
  if (!is.null(series_aes)) lab[[series_aes]] <- NA_character_
  lab
}

# Turn a layer into standardised long data + labels. `keep` lists extra
# columns (facet variables) to carry along.
resolve_layer <- function(layer, keep = character()) {
  src <- layer$source
  cols <- names(src)
  xy <- default_xy(src, layer$mapped)
  x <- xy$x
  y <- xy$y

  type <- layer$type %||% infer_type(src, x, y)
  spec <- get_type(type)
  uni <- spec$univariate
  pivot_to_x <- uni && is.null(x)
  if (uni && !is.null(x)) y <- NULL
  if (!uni && is.null(y)) {
    stop("Plot type '", if (is.character(type)) type else "custom",
         "' needs a `y` variable.", call. = FALSE)
  }
  if (!uni && is.null(x)) x <- ".index"

  others <- unlist(layer$mapped[setdiff(names(layer$mapped), c("x", "y"))])
  ref <- unique(c(x, y, others, intersect(keep, cols)))
  d <- as.data.frame(src)[ref[ref %in% cols]]
  st <- stack_y(d, x, y, c(x, others))

  out <- std_columns(layer, st$d, st, x, uni, pivot_to_x, spec)
  ser <- add_series_aes(out, st$series, spec)
  out <- ser$out
  out$.series <- st$series
  for (f in setdiff(intersect(keep, cols), names(out))) out[[f]] <- st$d[[f]]
  attr(out, "row.names") <- .set_row_names(st$n)
  class(out) <- "data.frame"

  list(
    data = out, aes = intersect(names(out), std_aes),
    labels = layer_labels(
      layer, x, y, uni, pivot_to_x, if (ser$used) spec$series
    ),
    params = layer$fixed, spec = spec
  )
}

# Build the ggplot2 layer(s) of a resolved layer
make_geom <- function(res) {
  aes_names <- stats::setNames(res$aes, res$aes)
  mapping <- ggplot2::aes(!!!rlang::syms(aes_names))
  args <- c(
    list(mapping = mapping, data = res$data),
    utils::modifyList(res$spec$params, res$params)
  )
  geom <- do.call(res$spec$geom, args)
  if (is.null(res$spec$extra)) geom else list(geom, res$spec$extra())
}
