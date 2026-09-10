# Figure 10. Geometry-level sensitivity of the offset-aware advantage.
#
# Unlike the six-room refined-grid heatmap, this panel treats each of the 20
# independently drawn room/source/microphone geometries as one observation.
# Intervals are the stored geometry bootstrap, not a trial-level interval.

if (!exists("GEOM20_LEVELS")) stop("geometry-level audit was not loaded")

p <- ggplot(GEOM20_LEVELS, aes(x = offset, y = mean_gap)) +
  geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.4) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = COLOUR_AWARE, alpha = 0.16,
              colour = NA) +
  geom_line(colour = COLOUR_AWARE, linewidth = 0.7) +
  geom_point(colour = COLOUR_AWARE, fill = "white", shape = 21, size = 2.4,
             stroke = 0.7) +
  geom_text(aes(label = sprintf("%d/%d", aware_wins, n_geometry)),
            vjust = -0.9, size = FIGURE_ANNOTATION_SIZE, family = FIGURE_FONT_FAMILY) +
  annotate("text", x = max(GEOM20_LEVELS$offset), y = 0, hjust = 1, vjust = -0.6,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey30",
           label = "above zero the offset-aware estimator has the lower mean error") +
  scale_x_continuous(name = "Dispersion of the unknown per-channel offsets (ms)",
                     breaks = GEOM20_LEVELS$offset,
                     expand = expansion(mult = c(0.04, 0.05))) +
  scale_y_continuous(name = "Mean error, agnostic minus aware (m)",
                     expand = expansion(mult = c(0.08, 0.12))) +
  rtx_theme()

save_fig(p, "fig10_geometry_sensitivity", FIGURE_TEXT_WIDTH_IN, 3.15)
