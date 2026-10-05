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
  if (name %in% position_aes) {
    stop("`", name, "` must be column name(s) of the data.", call. = FALSE)
  }
  list(kind = "fixed", value = value)
}

classify_chr <- function(name, value, cols) {
  if (all(value %in% cols) || (name == "y" && identical(value, "all"))) {
    return(list(kind = "col", value = value))
  }
  if (name %in% c(position_aes, "xintercept", "yintercept")) {
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

new_layer <- function(source, args, type = NULL, params = list(), y2 = NULL) {
  cols <- c(names(source), ".series")
  kinds <- lapply(names(args), function(a) classify_aes(a, args[[a]], cols))
  names(kinds) <- names(args)
  pick <- function(kind) {
    sel <- Filter(function(cl) cl$kind == kind, kinds)
    lapply(sel, function(cl) cl$value)
  }
  if (!is.null(type)) get_type(type) # validate early
  y2 <- check_y2(y2, source, args, type)
  list(
    source = source, mapped = pick("col"), const = pick("const"),
    fixed = utils::modifyList(pick("fixed"), params), type = type, y2 = y2
  )
}

others_of <- function(mapped) mapped[setdiff(names(mapped), position_aes)]

# x and y columns: explicit, else the hints of as_kdata(), else the first
# column against all the others (a band given by ymin/ymax needs no y)
default_xy <- function(src, mapped, y2 = NULL) {
  cols <- names(src)
  others <- unlist(others_of(mapped))
  band <- unlist(mapped[y_aes])
  # exact access: `$` would match `xintercept` for `x`
  x <- mapped[["x"]]
  y <- mapped[["y"]]
  if (is.null(x) && is.null(y)) {
    x <- attr(src, "kgg_x") %||% cols[1L]
    y <- attr(src, "kgg_y") %||% setdiff(cols, c(x, others, y2))
    if (length(band)) y <- NULL
  }
  if (identical(y, "all")) y <- setdiff(cols, c(x, others, band, y2))
  list(x = x, y = if (length(y)) y)
}

# What a layer plots: type, x, y and how they are used. Checks that the type
# gets what it needs.
plan_layer <- function(layer) {
  m <- layer$mapped
  y2 <- layer$y2
  xy <- default_xy(layer$source, m, y2)
  type <- layer$type %||% infer_type(layer$source, xy$x, xy$y, m)
  spec <- get_type(type)
  mode <- spec$mode
  if (mode %in% c("free", "intercept")) {
    xy <- list(x = m[["x"]], y = if (!identical(m[["y"]], "all")) m[["y"]])
  }
  x <- xy$x
  y <- xy$y
  uni <- mode == "univariate"
  pivot_to_x <- uni && is.null(x)
  if (uni && !is.null(x)) y <- NULL
  y_primary <- y
  if (length(y2)) {
    check_y2_type(type)
    if (length(intersect(y_primary, y2))) {
      stop("A column cannot be on both axes (`y` and `y2`).", call. = FALSE)
    }
    # all the series are stacked together; y2 tells which are on the right
    y <- c(y_primary, y2)
  }
  check_required(layer, spec, type, y)
  if (mode == "xy" && is.null(x)) x <- ".index"
  list(spec = spec, x = x, y = y, uni = uni, pivot_to_x = pivot_to_x,
       mode = mode, y2 = y2, y_primary = y_primary, type = type)
}

check_required <- function(layer, spec, type, y) {
  m <- layer$mapped
  name <- if (is.character(type)) type else "custom"
  has_band <- length(m[["ymin"]]) > 0L && length(m[["ymax"]]) > 0L
  if (spec$mode == "xy" && is.null(y) && !has_band) {
    stop("Plot type '", name, "' needs a `y` variable (or `ymin` and `ymax`).",
         call. = FALSE)
  }
  aes <- spec$intercept
  if (spec$mode == "intercept" &&
        is.null(m[[aes]]) && is.null(layer$fixed[[aes]])) {
    stop("Plot type '", name, "' needs `", aes, "`.", call. = FALSE)
  }
}

# Values of the ymin/ymax columns, aligned with the stacked y values: one
# column is repeated for every y, or one column per y.
stack_extra <- function(d, extra, k) {
  vals <- list()
  for (a in names(extra)) {
    cols <- extra[[a]]
    if (length(cols) == 1L) {
      vals[[a]] <- if (k > 1L) rep(d[[cols]], k) else d[[cols]]
    } else if (length(cols) == k && k > 1L) {
      vals[[a]] <- unlist(lapply(cols, function(cn) d[[cn]]), use.names = FALSE)
    } else {
      stop("`", a, "` must be one column, or one column per `y` column.",
           call. = FALSE)
    }
  }
  vals
}

# Stack the y columns of `d` in long format. Returns the data (rows repeated
# once per y column), the stacked values (y, and ymin/ymax in `extra`), the
# series factor and the number of rows.
stack_y <- function(d, x, y, extra, keep_cols) {
  n0 <- nrow(d)
  k <- length(y)
  vals <- stack_extra(d, extra, k)
  if (k == 0L) {
    series <- const_factor(
      if (identical(x, ".index")) "index" else x[1L] %||% "layer", n0
    )
    return(list(d = d, val = NULL, series = series, n = n0, extra = vals))
  }
  if (k == 1L) {
    return(list(
      d = d, val = d[[y]], series = const_factor(y, n0), n = n0, extra = vals
    ))
  }
  val <- unlist(lapply(y, function(cn) d[[cn]]), use.names = FALSE)
  d <- d[setdiff(names(d), setdiff(c(y, unlist(extra)), keep_cols))]
  d <- d[rep.int(seq_len(n0), k), , drop = FALSE]
  series <- structure(rep(seq_len(k), each = n0), levels = y, class = "factor")
  list(d = d, val = val, series = series, n = n0 * k, extra = vals)
}

x_values <- function(layer, d, st, pl) {
  if (pl$pivot_to_x) return(st$val)
  if (is.null(pl$x)) return(NULL)
  if (identical(pl$x, ".index")) {
    return(rep.int(seq_len(nrow(layer$source)), max(nlevels(st$series), 1L)))
  }
  d[[pl$x]]
}

# Standardised columns (x, y, colour...) of a layer
std_columns <- function(layer, d, st, pl) {
  out <- list()
  out$x <- x_values(layer, d, st, pl)
  if (!pl$uni) out$y <- st$val
  for (a in names(st$extra)) out[[a]] <- st$extra[[a]]
  others <- others_of(layer$mapped)
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
  used <- k > 1L && is.null(out$colour) && is.null(out$fill) &&
    spec$series != "none"
  if (used) out[[spec$series]] <- series
  key <- out$group
  if (is.null(key) && !used) key <- out$colour %||% out$fill
  if (k > 1L && !is.null(key)) {
    out$group <- interaction(series, key, drop = TRUE)
  }
  list(out = out, used = used)
}

# Default axis titles; NA means "no title". Reference lines and blank layers
# give none, so they never decide the titles of the plot.
axis_labels <- function(pl) {
  k <- length(pl$y)
  lab <- list()
  lab$x <- if (pl$pivot_to_x) {
    if (k == 1L) pl$y else "value"
  } else if (identical(pl$x, ".index")) {
    "Index"
  } else {
    pl$x[1L]
  }
  if (!pl$uni) {
    lab$y <- if (length(pl$y2)) {
      # the left axis: the series of the primary axis
      if (length(pl$y_primary)) paste(pl$y_primary, collapse = ", ") else NA_character_
    } else if (k == 1L) {
      pl$y
    } else if (k == 0L) {
      NA_character_
    } else {
      "value"
    }
  }
  lab
}

# Default axis / legend titles; NA means "no title"
layer_labels <- function(layer, pl, series_aes) {
  lab <- if (pl$mode %in% c("xy", "univariate")) axis_labels(pl) else list()
  others <- others_of(layer$mapped)
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
  cols <- names(layer$source)
  m <- layer$mapped
  pl <- plan_layer(layer)
  others <- unlist(others_of(m))
  extra <- m[intersect(names(m), y_aes)]
  ref <- unique(c(pl$x, pl$y, unlist(extra), others, intersect(keep, cols)))
  d <- as.data.frame(layer$source)[ref[ref %in% cols]]
  st <- stack_y(d, pl$x, pl$y, extra, c(pl$x, others))

  ser <- add_series_aes(std_columns(layer, st$d, st, pl), st$series, pl$spec)
  out <- ser$out

  # the series of the secondary axis are dashed (lines), to tell them apart
  auto_linetype <- length(pl$y2) > 0L && is.null(out$linetype) &&
    is.null(layer$fixed$linetype) && pl$type %in% c("line", "path", "step")
  if (auto_linetype) out$linetype <- st$series
  out$.series <- st$series
  for (f in setdiff(intersect(keep, cols), names(out))) out[[f]] <- st$d[[f]]
  attr(out, "row.names") <- .set_row_names(st$n)
  class(out) <- "data.frame"

  # a map: the geometry is carried along, the layer data stay an `sf`
  if (inherits(layer$source, "sf") && st$n == nrow(layer$source)) {
    geometry <- sf::st_geometry(layer$source)
    out$geometry <- geometry
    out <- sf::st_as_sf(out, sf_column_name = "geometry")
  }

  labels <- layer_labels(layer, pl, if (ser$used) pl$spec$series)
  if (auto_linetype) labels$linetype <- NA_character_

  list(
    data = out, aes = intersect(names(out), std_aes), labels = labels,
    params = layer$fixed, spec = pl$spec, y2 = pl$y2,
    auto_linetype = auto_linetype
  )
}

# Build the ggplot2 layer(s) of a resolved layer. The default parameters of
# the type (e.g. a black colour) are dropped for the aesthetics the user mapped.
make_geom <- function(res) {
  aes_names <- stats::setNames(res$aes, res$aes)
  mapping <- ggplot2::aes(!!!rlang::syms(aes_names))
  defaults <- res$spec$params[setdiff(names(res$spec$params), res$aes)]
  args <- c(
    list(mapping = mapping, data = res$data),
    utils::modifyList(defaults, res$params)
  )
  geom <- do.call(res$spec$geom, args)
  if (is.null(res$spec$extra)) geom else list(geom, res$spec$extra())
}
