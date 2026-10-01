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
    value <- as.character(value)
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
    if (name %in% c("colour", "fill", "group")) {
      if (length(value) != 1L) {
        stop("`", name, "` must be a single column or label.", call. = FALSE)
      }
      return(list(kind = "const", value = value))
    }
    return(list(kind = "fixed", value = value))
  }
  if (name %in% c("x", "y")) {
    stop("`", name, "` must be column name(s) of the data.", call. = FALSE)
  }
  list(kind = "fixed", value = value)
}

new_layer <- function(source, args, type = NULL, params = list()) {
  cols <- c(names(source), ".series")
  mapped <- list()
  const <- list()
  fixed <- list()
  for (a in names(args)) {
    cl <- classify_aes(a, args[[a]], cols)
    if (cl$kind == "col") mapped[[a]] <- cl$value
    if (cl$kind == "const") const[[a]] <- cl$value
    if (cl$kind == "fixed") fixed[[a]] <- cl$value
  }
  if (!is.null(type)) get_type(type) # validate early
  list(
    source = source, mapped = mapped, const = const,
    fixed = utils::modifyList(fixed, params), type = type
  )
}

# Turn a layer into standardised long data + labels. `keep` lists extra
# columns (facet variables) to carry along.
resolve_layer <- function(layer, keep = character()) {
  src <- layer$source
  cols <- names(src)
  m <- layer$mapped
  const <- layer$const
  others <- m[setdiff(names(m), c("x", "y"))]
  x <- m$x
  y <- m$y

  if (is.null(x) && is.null(y)) {
    x <- attr(src, "kgg_x") %||% cols[1L]
    y <- attr(src, "kgg_y") %||% setdiff(cols, c(x, unlist(others)))
  }
  if (identical(y, "all")) y <- setdiff(cols, c(x, unlist(others)))
  if (!length(y)) y <- NULL

  type <- layer$type %||% infer_type(src, x, y)
  spec <- get_type(type)
  uni <- spec$univariate

  pivot_to_x <- FALSE
  if (uni) {
    if (is.null(x)) pivot_to_x <- TRUE else y <- NULL
  } else {
    if (is.null(y)) {
      stop("Plot type '", if (is.character(type)) type else "custom",
           "' needs a `y` variable.", call. = FALSE)
    }
    if (is.null(x)) x <- ".index"
  }

  ref <- unique(c(x, y, unlist(others), intersect(keep, cols)))
  ref <- ref[ref %in% cols]
  d <- as.data.frame(src)[ref]
  n0 <- nrow(d)
  k <- length(y)

  # long format: stack the y columns
  if (k == 0L) {
    series <- const_factor(if (identical(x, ".index")) "index" else x[1L], n0)
    val <- NULL
    n <- n0
  } else if (k == 1L) {
    series <- const_factor(y, n0)
    val <- d[[y]]
    n <- n0
  } else {
    val <- unlist(lapply(y, function(cn) d[[cn]]), use.names = FALSE)
    drop <- setdiff(y, c(x, unlist(others)))
    d <- d[setdiff(names(d), drop)]
    d <- d[rep.int(seq_len(n0), k), , drop = FALSE]
    series <- structure(rep(seq_len(k), each = n0), levels = y, class = "factor")
    n <- n0 * k
  }

  out <- list()
  out$x <- if (pivot_to_x) {
    val
  } else if (identical(x, ".index")) {
    rep.int(seq_len(n0), max(k, 1L))
  } else {
    d[[x]]
  }
  if (!uni) out$y <- val
  for (a in names(others)) {
    cn <- others[[a]]
    if (length(cn) != 1L) {
      stop("`", a, "` must be a single column.", call. = FALSE)
    }
    out[[a]] <- if (cn == ".series") series else d[[cn]]
  }
  for (a in names(const)) out[[a]] <- const_factor(const[[a]], n)

  # several y variables: colour (or fill) by series unless already mapped
  series_used <- FALSE
  if (k > 1L && is.null(out$colour) && is.null(out$fill)) {
    out[[spec$series]] <- series
    series_used <- TRUE
  }
  key <- out$group
  if (is.null(key) && !series_used) key <- out$colour %||% out$fill
  if (k > 1L && !is.null(key)) out$group <- interaction(series, key, drop = TRUE)

  out$.series <- series
  for (f in setdiff(intersect(keep, cols), names(out))) out[[f]] <- d[[f]]

  # default axis / legend titles; NA means "no title"
  lab <- list()
  lab$x <- if (pivot_to_x) {
    if (k == 1L) y else "value"
  } else if (identical(x, ".index")) "Index" else x[1L]
  if (!uni) lab$y <- if (k == 1L) y else "value"
  for (a in intersect(names(others), legend_aes)) {
    lab[[a]] <- if (others[[a]] == ".series") NA_character_ else others[[a]]
  }
  for (a in intersect(names(const), legend_aes)) lab[[a]] <- NA_character_
  if (series_used) lab[[spec$series]] <- NA_character_

  attr(out, "row.names") <- .set_row_names(n)
  class(out) <- "data.frame"
  list(
    data = out, aes = intersect(names(out), std_aes), labels = lab,
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
