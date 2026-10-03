# Build the plot for real: catches errors that only appear at render time
render <- function(p) {
  g <- as_ggplot(p)
  b <- ggplot2::ggplot_build(g)
  list(plot = g, built = b)
}

obs <- data.frame(t = 1:10, v = cumsum(rep(1, 10)))
sim <- data.frame(t = 1:10, v = cumsum(rep(1.2, 10)))

# Data of the figure of issue #7: a column of panels with two series, an
# uncertainty band, observations, a threshold in one panel, decision dates in
# every panel and forced limits for one panel.
issue_data <- function() {
  dates <- seq(as.Date("2024-05-01"), by = "day", length.out = 60)
  panels <- c("LAI", "Available water ratio", "Irrigation")
  make <- function(simulation, shift) {
    lai <- pmax(0, 3 * sin(seq(0, pi, length.out = 60)) + shift)
    awr <- pmin(1, pmax(0, 0.8 - seq(0, 0.5, length.out = 60) + shift / 10))
    irr <- ifelse(seq_along(dates) %% 10 == 0, 20 + 5 * shift, 0)
    data.frame(
      date = rep(dates, 3), simulation = simulation,
      panel = factor(rep(panels, each = 60), levels = panels),
      mean = c(lai, awr, irr), sd = c(rep(0.3, 60), rep(0.08, 60), rep(0, 60))
    )
  }
  data <- rbind(make("Simulation", 0), make("Reference", 0.4))
  data$ymin <- data$mean - data$sd
  data$ymax <- data$mean + data$sd
  obs <- data.frame(
    date = dates[c(10, 25, 40, 55)], lai_obs = c(0.8, 2.4, 2.6, 1.1),
    lai_obs_sd = 0.25, panel = factor("LAI", levels = panels)
  )
  obs$lo <- obs$lai_obs - obs$lai_obs_sd
  obs$hi <- obs$lai_obs + obs$lai_obs_sd
  list(
    continuous = data[data$panel != "Irrigation", ],
    irrigation = data[data$panel == "Irrigation" & data$mean > 0, ],
    obs = obs,
    threshold = data.frame(
      panel = factor("Available water ratio", levels = panels), y = 0.4
    ),
    decisions = dates[c(15, 30, 45)],
    colors = c(Simulation = "#00a3a6", Reference = "#e07a5f"),
    panels = panels
  )
}

# The figure of the issue, with kggplot() calls and `+` only
issue_figure <- function(limits = TRUE) {
  d <- issue_data()
  p <- kggplot(
    d$continuous, "date", "mean", ymin = "ymin", ymax = "ymax",
    fill = "simulation", type = "ribbon",
    facet = panel ~ ., facet_args = list(scales = "free_y", switch = "y"),
    theme = "inrae", palette = d$colors, legend = "bottom",
    xlab = NA, ylab = NA, labels = list(color = NA, fill = NA)
  ) +
    kggplot(d$continuous, "date", "mean", color = "simulation", type = "line",
            linewidth = 0.8) +
    kggplot(d$irrigation, "date", "mean", fill = "simulation",
            type = "bar_dodge", width = 0.9, position = "dodge") +
    kggplot(d$obs, "date", "lai_obs", ymin = "lo", ymax = "hi",
            type = "pointrange") +
    kgg_hline(data = d$threshold, yintercept = "y", linetype = "dashed",
              color = I("grey40")) +
    kgg_vline(d$decisions, linetype = "dotted", color = I("grey60"))
  if (limits) p <- p + kgg_limits(panel = "Available water ratio", y = c(0, 1))
  p
}
