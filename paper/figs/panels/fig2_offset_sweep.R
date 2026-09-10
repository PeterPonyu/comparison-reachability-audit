# Figure 2. The part of the comparison that IS reproducible here, including the
# condition the published account omits: where no offsets are present, the
# offset-aware estimator is estimating something that does not exist and loses by
# orders of magnitude. The axis is logarithmic because that is the size of the
# gap, and a linear axis would render every other condition as a flat line.

f2 <- data.frame(
  offset = rep(sr$offset_std_ms, 2L),
  arm = factor(rep(arm_labels, each = nrow(sr)), levels = arm_labels),
  median_err = c(sr$naive_median_err_m, sr$aware_median_err_m)
)

SWEEP_TRIALS <- single_valued(sr$n_trials, "how many paired trials each offset condition ran")

p <- ggplot(f2, aes(offset, median_err, colour = arm, shape = arm)) +
  # Finite bounds: an infinite ymin is undefined once the axis is log-scaled.
  annotate("rect", xmin = -3.2, xmax = 2.5, ymin = 5e-4, ymax = 5,
           fill = "grey90", alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "22", linewidth = 0.4, colour = "grey25") +
  # The note sits to the right of the zero-offset marker, clear of the rising
  # agnostic curve, which passes through the earlier position of this label.
  annotate("label", x = 3.0, y = 0.0022,
           label = sprintf("zero-offset condition\nn = %d paired trials", SWEEP_TRIALS),
           hjust = 0, size = FIGURE_ANNOTATION_SIZE, colour = "grey25", fill = "white",
           border.colour = NA, label.padding = unit(0.08, "lines"),
           lineheight = 0.95) +
  geom_line(linewidth = 0.5) +
  geom_point(size = 2, fill = "white", stroke = 0.6) +
  scale_colour_manual(values = arm_colours, name = NULL) +
  scale_shape_manual(values = c(21, 24), name = NULL) +
  scale_x_continuous(name = "Dispersion of the unknown per-channel offsets (ms)",
                     breaks = sr$offset_std_ms) +
  scale_y_log10(name = "Median localisation error (m)",
                breaks = c(0.001, 0.01, 0.1, 1),
                labels = c("0.001", "0.01", "0.1", "1")) +
  annotation_logticks(sides = "l", linewidth = 0.25,
                      short = unit(0.03, "in"), mid = unit(0.045, "in"),
                      long = unit(0.06, "in")) +
  rtx_theme() +
  theme(legend.position = "inside",
        legend.position.inside = c(0.99, 0.03), legend.justification = c(1, 0),
        legend.background = element_rect(fill = "white", colour = "grey70",
                                         linewidth = 0.25),
        legend.margin = margin(2, 4, 2, 4))

save_fig(p, "fig2_offset_sweep", 0.88 * FIGURE_TEXT_WIDTH_IN, 3.4)
