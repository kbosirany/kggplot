`%||%` <- function(x, y) if (is.null(x)) y else x

# Constant factor of length n (cheap: no character vector is allocated)
const_factor <- function(label, n) {
  structure(rep.int(1L, n), levels = as.character(label), class = "factor")
}

# Aesthetics understood by kggplot (US spelling "color" is normalised)
std_aes <- c(
  "x", "y", "colour", "fill", "group", "size", "shape", "alpha", "linetype",
  "label"
)

# Aesthetics that get a legend title
legend_aes <- c("colour", "fill", "size", "shape", "alpha", "linetype")

norm_aes_names <- function(nm) {
  if (is.null(nm)) return(nm)
  sub("^color$", "colour", nm)
}

# Normalise a named list: US -> UK spelling, drop NULL entries
norm_list <- function(x) {
  if (!length(x)) return(list())
  names(x) <- norm_aes_names(names(x))
  x[!vapply(x, is.null, logical(1))]
}
