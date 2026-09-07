# Figure 9. A cell-level view of the refined crossing design.
#
# The overlaid curves in Figure 8 show trajectories well, but make it hard to
# compare rooms at one offset. This heatmap keeps the same bound cells and
# changes only the encoding: each tile is one room x dispersion cell, and its
# value is the recorded median-error difference (agnostic minus aware).

robust <- FINE_GAP
if (!nrow(robust) || any(!is.finite(robust$gap))) {
  stop("the refined crossing grid has no finite cell-level gaps to plot")
}
robust$room <- factor(robust$room, levels = rev(unique(robust$room)))
# Keep the sign of cells that are close to the zero crossing.  One decimal is
# enough for the larger gaps; three decimals for the tiniest gaps avoid a
# misleading signed zero, while two decimals for the remaining near-zero cells
# keep the 72-cell grid readable.
format_gap_label <- function(x) {
  ifelse(abs(x) < 0.01, sprintf("%+.3f", x),
         ifelse(abs(x) < 0.05, sprintf("%+.2f", x), sprintf("%+.1f", x)))
}
robust$label <- format_gap_label(robust$gap)
robust$label_colour <- ifelse(abs(robust$gap) >= 0.75, "white", "grey20")

p <- ggplot(robust, aes(x = offset, y = room, fill = gap)) +
  geom_tile(colour = "white", linewidth = 0.35, width = 0.96, height = 0.88) +
  geom_text(aes(label = label, colour = label_colour), size = 2.15,
            show.legend = FALSE) +
  scale_colour_identity() +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, name = "Agnostic minus aware\nmedian error (m)") +
  scale_x_continuous(name = "Dispersion of unknown offsets (ms)",
                     breaks = seq(0, max(robust$offset), by = 1),
                     labels = sprintf("%.0f", seq(0, max(robust$offset), by = 1)),
                     expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_discrete(name = NULL, expand = expansion(add = c(0.15, 0.15))) +
  labs(subtitle = sprintf("%d rooms × %d levels × %d paired trials per cell; blue = agnostic lower error",
                          length(unique(robust$room)), length(unique(robust$offset)),
                          single_valued(robust$n, "paired trials per refined cell"))) +
  rtx_theme() +
  theme(axis.text.x = element_text(size = 7.2),
        axis.text.y = element_text(size = 7.5),
        legend.position = "right", legend.text = element_text(size = 7),
        legend.title = element_text(size = 7.5, lineheight = 0.9),
        plot.subtitle = element_text(size = 7.1, colour = "grey25"))

save_fig(p, "fig9_robustness", FIGURE_TEXT_WIDTH_IN, 3.55)
