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
# The grid is not evenly spaced: its levels sit a quarter of a millisecond
# apart at the low end and half a millisecond apart above one.  Tiles of one
# width per level, labelled with the level, keep every cell the same size and
# every label inside its own tile; tiles drawn in data units would overlap
# where the levels are close.
level_label <- function(x) sub("\\.?0+$", "", sprintf("%.2f", x))
level_values <- sort(unique(robust$offset))
robust$level <- factor(level_label(robust$offset), levels = level_label(level_values))
# Keep the sign of cells that are close to the zero crossing.  One decimal is
# enough for the larger gaps; three decimals for the tiniest gaps avoid a
# misleading signed zero, while two decimals for the remaining near-zero cells
# keep the 72-cell grid readable.
format_gap_label <- function(x) {
  ifelse(abs(x) < 0.01, sprintf("%+.3f", x),
         ifelse(abs(x) < 0.05, sprintf("%+.2f", x), sprintf("%+.1f", x)))
}
robust$label <- format_gap_label(robust$gap)
robust$label_colour <- ifelse(abs(robust$gap) >= 1.0, "white", "grey15")

# Negative cells (agnostic lower error) take the agnostic estimator's colour
# and positive cells the aware estimator's, so the heatmap reads with the same
# key as the sweep figures; white is the zero midpoint.  The scale spans the
# measured range and nothing more, so the key does not suggest positive gaps
# the grid never produced.
p <- ggplot(robust, aes(x = level, y = room, fill = gap)) +
  geom_tile(colour = "white", linewidth = 0.5, width = 0.96, height = 0.9) +
  geom_text(aes(label = label, colour = label_colour), size = FIGURE_CELL_SIZE,
            show.legend = FALSE) +
  scale_colour_identity() +
  scale_fill_gradient2(low = COLOUR_AGNOSTIC, mid = "white", high = COLOUR_AWARE,
                       midpoint = 0,
                       name = "Median error,\nagnostic minus\naware (m)") +
  scale_x_discrete(name = "Dispersion of the unknown per-channel offsets (ms)",
                   expand = expansion(add = 0.05)) +
  scale_y_discrete(name = NULL, expand = expansion(add = 0.05)) +
  rtx_theme() +
  theme(panel.grid.major = element_blank(),
        panel.border = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "right",
        legend.key.height = unit(0.32, "in"),
        legend.key.width = unit(0.14, "in"),
        legend.title = element_text(lineheight = 0.95))

save_fig(p, "fig9_robustness", FIGURE_TEXT_WIDTH_IN, 3.55)
