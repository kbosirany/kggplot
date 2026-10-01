# Build the plot for real: catches errors that only appear at render time
render <- function(p) {
  g <- as_ggplot(p)
  b <- ggplot2::ggplot_build(g)
  list(plot = g, built = b)
}

obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))
