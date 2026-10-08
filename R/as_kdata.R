#' Convert an input object to a data frame for kggplot
#'
#' `as_kdata()` is the S3 entry point that turns whatever you hand to
#' [kggplot()] into a plain data frame. Add a method to teach kggplot a new
#' input class. A method may set the attributes `kgg_x`, `kgg_y` (default
#' variables to plot) and `kgg_type` (default plot type) on the result; they
#' are only used when the call does not specify `x`, `y` or `type`.
#'
#' Built-in methods: `data.frame` (and tibbles), `sf` (a map: the geometry is
#' kept and `fill` colours the polygons), `ts`/`mts`, `matrix`, atomic
#' vectors (numeric, character, factor, logical), `list` of equal-length
#' vectors.
#'
#' @param x Object to convert.
#' @param ... Unused, for method extensions.
#'
#' @return A data frame.
#'
#' @examples
#' as_kdata(ts(c(1, 3, 2), start = 2000))
#' as_kdata(matrix(1:6, 3, dimnames = list(NULL, c("a", "b"))))
#' as_kdata(c(2, 4, 8))
#'
#' @export
as_kdata <- function(x, ...) {
  UseMethod("as_kdata")
}

#' @export
#' @rdname as_kdata
as_kdata.data.frame <- function(x, ...) {
  if (ncol(x) == 0L) stop("`data` has no column.", call. = FALSE)
  as.data.frame(x)
}

#' @export
#' @rdname as_kdata
as_kdata.sf <- function(x, ...) {
  # keeps the class `sf` (and the geometry): drawn as a map by default
  if (ncol(x) == 0L) stop("`data` has no column.", call. = FALSE)
  attr(x, "kgg_type") <- "sf"
  x
}

#' @export
#' @rdname as_kdata
as_kdata.ts <- function(x, ...) {
  tm <- as.numeric(stats::time(x))
  if (is.matrix(x)) {
    out <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
    if (is.null(colnames(x))) names(out) <- paste0("V", seq_len(ncol(x)))
    out <- cbind(time = tm, out)
  } else {
    out <- data.frame(time = tm, value = as.numeric(x))
  }
  attr(out, "kgg_x") <- "time"
  attr(out, "kgg_type") <- "line"
  out
}

#' @export
#' @rdname as_kdata
as_kdata.matrix <- function(x, ...) {
  out <- as.data.frame(x, stringsAsFactors = FALSE)
  if (is.null(colnames(x))) names(out) <- paste0("V", seq_len(ncol(x)))
  out
}

#' @export
#' @rdname as_kdata
as_kdata.numeric <- function(x, ...) {
  out <- data.frame(index = seq_along(x), value = as.numeric(x))
  attr(out, "kgg_x") <- "index"
  attr(out, "kgg_y") <- "value"
  out
}

#' @export
#' @rdname as_kdata
as_kdata.logical <- function(x, ...) as_kdata.character(x)

#' @export
#' @rdname as_kdata
as_kdata.character <- function(x, ...) {
  out <- data.frame(value = x, stringsAsFactors = FALSE)
  attr(out, "kgg_x") <- "value"
  out
}

#' @export
#' @rdname as_kdata
as_kdata.factor <- function(x, ...) as_kdata.character(x)

#' @export
#' @rdname as_kdata
as_kdata.list <- function(x, ...) {
  if (is.null(names(x)) || !all(nzchar(names(x)))) {
    stop("A list given to kggplot() must be fully named.", call. = FALSE)
  }
  as_kdata.data.frame(as.data.frame(x, stringsAsFactors = FALSE))
}

#' @export
#' @rdname as_kdata
as_kdata.default <- function(x, ...) {
  out <- tryCatch(
    as.data.frame(x),
    error = function(e) {
      stop(
        "Don't know how to plot an object of class '", class(x)[1L], "'. ",
        "Define a method as_kdata.", class(x)[1L], "().",
        call. = FALSE
      )
    }
  )
  as_kdata.data.frame(out)
}
