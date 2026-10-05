# Secondary y axis.
#
# ggplot2 only draws a secondary axis as a transformation of the primary one:
# the series of the secondary axis must be mapped onto the range of the primary
# axis, and the axis on the right is the inverse of this mapping. kggplot does
# both from one global linear map `a + b * y2` (the same in every panel and
# every layer), so that the labels of the right axis are always exact:
# `sec_axis(function(x) (x - a) / b)`.

# Plot types whose position is a value that a linear map keeps exact (not
# bars or areas, which start from zero)
y2_types <- c("point", "jitter", "line", "path", "step", "smooth")

# Checks the columns `y2` of a layer
check_y2 <- function(y2, source, args, type) {
  if (is.null(y2)) return(NULL)
  if (!is.character(y2) || !length(y2) || anyNA(y2)) {
    stop("`y2` must be column name(s) of the data.", call. = FALSE)
  }
  missing <- setdiff(y2, names(source))
  if (length(missing)) {
    stop(
      "Column(s) not found in data for `y2`: ", paste(missing, collapse = ", "),
      ". Available: ", paste(names(source), collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (is.character(args$y) && length(intersect(args$y, y2))) {
    stop("A column cannot be on both axes (`y` and `y2`).", call. = FALSE)
  }
  if (any(c("ymin", "ymax") %in% names(args))) {
    stop("`y2` cannot be used with `ymin` or `ymax`.", call. = FALSE)
  }
  check_y2_type(type)
  unique(y2)
}

check_y2_type <- function(type) {
  if (is.null(type)) return(invisible(NULL))
  if (!is.character(type) || !type %in% y2_types) {
    stop(
      "`y2` works with the plot types ", paste(y2_types, collapse = ", "),
      ".", call. = FALSE
    )
  }
  invisible(NULL)
}

# The linear map a + b * y that puts the values `sec` on the range of the
# values `prim`: both ends match. A constant series, or no finite value, gives
# the same slope (1) and centres it: the map is never degenerate.
y2_map <- function(prim, sec) {
  range_of <- function(x) {
    x <- x[is.finite(x)]
    if (length(x)) range(x) else c(0, 1)
  }
  r1 <- range_of(prim)
  r2 <- range_of(sec)
  w1 <- diff(r1)
  w2 <- diff(r2)
  b <- if (w1 > 0 && w2 > 0) w1 / w2 else 1
  if (!is.finite(b) || b <= 0) b <- 1
  a <- if (w1 > 0 && w2 > 0) r1[1L] - b * r2[1L] else mean(r1) - mean(r2)
  list(a = a, b = b)
}

# Maps the series of the secondary axis onto the primary one, for all the
# layers together. Returns the layers and the map (NULL without secondary axis).
apply_y2 <- function(res) {
  has <- vapply(res, function(r) length(r$y2) > 0L, logical(1))
  if (!any(has)) return(list(res = res, map = NULL))

  is_sec <- lapply(res, function(r) {
    if (length(r$y2) && !is.null(r$data$y)) {
      as.character(r$data$.series) %in% r$y2
    } else {
      rep(FALSE, nrow(r$data))
    }
  })
  values <- function(sec) {
    unlist(lapply(seq_along(res), function(i) {
      y <- res[[i]]$data$y
      if (is.null(y)) return(NULL)
      y[is_sec[[i]] == sec]
    }))
  }
  prim <- values(FALSE)
  sec <- values(TRUE)

  if (!length(prim)) {
    stop(
      "`y2` needs at least one series on the primary axis (`y`).",
      call. = FALSE
    )
  }
  if (!is.numeric(sec)) {
    stop("The columns of `y2` must be numeric.", call. = FALSE)
  }

  map <- y2_map(prim, sec)
  for (i in seq_along(res)) {
    if (any(is_sec[[i]])) {
      res[[i]]$data$y[is_sec[[i]]] <- map$a + map$b * res[[i]]$data$y[is_sec[[i]]]
    }
  }
  list(res = res, map = map)
}

# The secondary axis (inverse of the map), its title, and a dashed line for
# the series of the secondary axis when kggplot chose the line type itself
add_y2_scales <- function(p, y2, res, ylab2) {
  map <- y2$map
  if (is.null(map)) return(p)

  name <- if (is.null(ylab2)) {
    paste(unique(unlist(lapply(res, function(r) r$y2))), collapse = ", ")
  } else if (length(ylab2) == 1L && is.na(ylab2)) {
    NULL
  } else {
    ylab2
  }
  a <- map$a
  b <- map$b
  p <- p + ggplot2::scale_y_continuous(
    sec.axis = ggplot2::sec_axis(function(x) (x - a) / b, name = name)
  )

  # no linetype scale if the user mapped a linetype in a layer
  auto <- vapply(res, function(r) isTRUE(r$auto_linetype), logical(1))
  other <- vapply(
    res[!auto], function(r) !is.null(r$data$linetype), logical(1)
  )
  if (any(auto) && !any(other)) {
    lt <- list()
    for (r in res[auto]) {
      series <- levels(r$data$.series)
      lt[series] <- ifelse(series %in% r$y2, "dashed", "solid")
    }
    p <- p + ggplot2::scale_linetype_manual(values = unlist(lt))
  }
  p
}
