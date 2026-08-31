# Figure 8. The interval the coarse grid skipped, and what is inside it.
#
# Left: the gap between the two arms across the refined grid, one line per
# room. Below the zero line is the offset-agnostic estimator named. The two
# rows of ticks above the curves are the two designs: the coarse sweep has two
# conditions in this range, at the ends, and this sweep has twelve.
#
# Right: where the sign change actually sits, per room and per summary rule,
# with the rooms that never crossed drawn as arrows leaving the grid rather
# than as a point at its edge, because a sweep that stops short of a crossing
# has not measured one.

room_order <- CROSSINGS$room
FINE_GAP$room <- factor(FINE_GAP$room, levels = room_order)
gap_room_colours <- grDevices::hcl.colors(length(room_order), "Dark 3")
names(gap_room_colours) <- room_order

anchor <- CROSS_ANCHOR$offset_std_ms
coarse_here <- sort(cross$coarse_grid_ms[cross$coarse_grid_ms <= anchor])
refined_here <- sort(unique(FINE_GAP$offset))

gap_span <- range(FINE_GAP$gap)
row_refined <- gap_span[2] + 0.22
row_coarse <- row_refined + 0.34
tick <- 0.05

left <- ggplot(FINE_GAP, aes(offset, gap, colour = room)) +
  geom_hline(yintercept = 0, linewidth = 0.35, colour = "grey20") +
  geom_line(linewidth = 0.45) +
  geom_point(size = 1.1) +
  annotate("segment", x = coarse_here, xend = coarse_here,
           y = row_coarse - tick, yend = row_coarse + tick,
           colour = "grey15", linewidth = 0.5) +
  annotate("segment", x = min(coarse_here), xend = max(coarse_here),
           y = row_coarse, yend = row_coarse, colour = "grey55", linewidth = 0.25,
           linetype = "dotted") +
  annotate("segment", x = refined_here, xend = refined_here,
           y = row_refined - tick, yend = row_refined + tick,
           colour = "grey15", linewidth = 0.5) +
  annotate("text", x = anchor, y = row_coarse + 0.09, hjust = 1, vjust = 0,
           size = 2.3, colour = "grey25",
           label = "conditions the coarse sweep has here") +
  annotate("text", x = anchor, y = row_refined + 0.09, hjust = 1, vjust = 0,
           size = 2.3, colour = "grey25",
           label = "conditions this sweep has here") +
  annotate("text", x = 0.1, y = gap_span[1] + 0.05, hjust = 0, size = 2.4,
           colour = "grey25", label = "offset-agnostic estimator named") +
  scale_colour_manual(values = gap_room_colours, name = NULL) +
  scale_x_continuous(name = "Dispersion of the unknown per-channel offsets (ms)",
                     breaks = seq(0, anchor, by = 1),
                     limits = c(-0.05, anchor + 0.05)) +
  scale_y_continuous(name = "Median error, agnostic minus aware (m)",
                     limits = c(gap_span[1] - 0.02, row_coarse + 0.22)) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.16, "in"),
        legend.margin = margin(0, 0, 0, 0))

crossing_long <- rbind(
  data.frame(room = CROSSINGS$room, rule = "median of the trials",
             at = CROSSINGS$median_ms, stringsAsFactors = FALSE),
  data.frame(room = CROSSINGS$room, rule = "paired per-trial count",
             at = CROSSINGS$paired_ms, stringsAsFactors = FALSE)
)
crossing_long$room <- factor(crossing_long$room, levels = rev(room_order))
censored <- CROSSINGS[is.na(CROSSINGS$median_ms), ]
censored$room <- factor(censored$room, levels = rev(room_order))

rule_colours <- c("#1B7837", "#762A83")
names(rule_colours) <- c("median of the trials", "paired per-trial count")

right <- ggplot(crossing_long, aes(at, room, colour = rule, shape = rule)) +
  geom_vline(xintercept = CROSS_PREDICTION$predicted_crossing_ms,
             linetype = "dashed", linewidth = 0.35, colour = "grey30") +
  geom_segment(data = censored,
               aes(x = censored_above - 0.7, xend = censored_above - 0.05,
                   y = room, yend = room),
               inherit.aes = FALSE, colour = "grey45", linewidth = 0.4,
               arrow = arrow(length = unit(0.05, "in"), type = "closed")) +
  annotate("text", x = anchor - 1.35, y = length(censored$room) + 0.55,
           hjust = 1, vjust = 0.5, size = 2.2, colour = "grey35", lineheight = 0.95,
           label = "no crossing below the\ncoarse sweep's lowest condition") +
  geom_point(size = 2, na.rm = TRUE) +
  annotate("text", x = CROSS_PREDICTION$predicted_crossing_ms - 0.15,
           y = length(room_order) + 0.95, hjust = 1, vjust = 1, size = 2.3,
           colour = "grey30", lineheight = 0.95,
           label = "where the coarse\nrecord says to look") +
  scale_colour_manual(values = rule_colours, name = NULL) +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  scale_x_continuous(name = "Where the ordering changes sign (ms)",
                     limits = c(0, anchor + 0.1),
                     breaks = seq(0, anchor, by = 1)) +
  scale_y_discrete(name = NULL, expand = expansion(add = c(0.6, 1.5))) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.16, "in"),
        legend.margin = margin(0, 0, 0, 0),
        panel.grid.major.y = element_line(linewidth = 0.2, colour = "grey92"))

p <- patchwork::wrap_plots(left, right, widths = c(1.3, 1))

save_fig(p, "fig8_breakeven", FIGURE_TEXT_WIDTH_IN, 3.8)
