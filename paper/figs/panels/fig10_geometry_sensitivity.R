# Figure 10. Geometry-level sensitivity of the offset-aware advantage.
#
# Unlike the six-room refined-grid heatmap, this panel treats each of the 20
# independently drawn room/source/microphone geometries as one observation.
# Intervals are the stored geometry bootstrap, not a trial-level interval.

if (!exists("GEOM20_LEVELS")) stop("geometry-level audit was not loaded")

p <- ggplot(GEOM20_LEVELS, aes(x = offset, y = mean_gap)) +
  geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.35) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#2166AC", alpha = 0.16,
              colour = NA) +
  geom_line(colour = "#2166AC", linewidth = 0.7) +
  geom_point(colour = "#2166AC", fill = "white", shape = 21, size = 2.4,
             stroke = 0.7) +
  geom_text(aes(label = sprintf("%d/%d", aware_wins, n_geometry)),
            vjust = -0.9, size = 2.35, family = FIGURE_FONT_FAMILY) +
  scale_x_continuous(name = "True offset dispersion (ms)",
                     breaks = GEOM20_LEVELS$offset,
                     expand = expansion(mult = c(0.04, 0.05))) +
  scale_y_continuous(name = "Naive error minus offset-aware error (m)",
                     expand = expansion(mult = c(0.06, 0.12))) +
  labs(subtitle = "Point = mean across independent geometries; band = 95% geometry bootstrap; labels = aware wins / 20") +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        axis.text.x = element_text(size = FIGURE_AXIS_TEXT_SIZE))

save_fig(p, "fig10_geometry_sensitivity", FIGURE_TEXT_WIDTH_IN, 3.15)
