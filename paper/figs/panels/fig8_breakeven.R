# Figure 8. The interval the coarse grid skipped, and what is inside it.
#
# Panel A: the gap between the two arms across the refined grid, one line per
# room. Below the zero line is the offset-agnostic estimator named. The two
# rows of ticks above the curves are the two designs: the coarse sweep has two
# conditions in this range, at the ends, and this sweep has twelve.
#
# Panel B: where the sign change actually sits, per room and per summary rule,
# with the rooms that never crossed drawn as arrows leaving the grid rather
# than as a point at its edge, because a sweep that stops short of a crossing
# has not measured one.

# One array order for every view of these cells: the crossing table, both
# panels here, the heatmap and the 400-trial sensitivity all list the arrays as
# the crossing record does.  Panel B's discrete axis is pinned to that order
# explicitly; left to itself the scale would be trained on the censored layer
# first and put the censored arrays before the crossed ones.
room_order <- CROSSINGS$room
FINE_GAP$room <- factor(FINE_GAP$room, levels = room_order)
gap_room_colours <- COLOUR_ROOMS[seq_along(room_order)]
names(gap_room_colours) <- room_order
gap_room_shapes <- SHAPE_ROOMS[seq_along(room_order)]
names(gap_room_shapes) <- room_order

anchor <- CROSS_ANCHOR$offset_std_ms
coarse_here <- sort(cross$coarse_grid_ms[cross$coarse_grid_ms <= anchor])
refined_here <- sort(unique(FINE_GAP$offset))
FINE_TRIALS <- single_valued(FINE_GAP$n, "how many paired trials each refined cell ran")

gap_span <- range(FINE_GAP$gap)
row_refined <- gap_span[2] + 0.24
row_coarse <- row_refined + 0.36
tick <- 0.05

left <- ggplot(FINE_GAP, aes(offset, gap, colour = room, shape = room)) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey20") +
  geom_line(linewidth = 0.5) +
  geom_point(size = 1.5) +
  annotate("segment", x = coarse_here, xend = coarse_here,
           y = row_coarse - tick, yend = row_coarse + tick,
           colour = "grey15", linewidth = 0.5) +
  annotate("segment", x = min(coarse_here), xend = max(coarse_here),
           y = row_coarse, yend = row_coarse, colour = "grey55", linewidth = 0.3,
           linetype = "dotted") +
  annotate("segment", x = refined_here, xend = refined_here,
           y = row_refined - tick, yend = row_refined + tick,
           colour = "grey15", linewidth = 0.5) +
  annotate("text", x = anchor, y = row_coarse + 0.09, hjust = 1, vjust = 0,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey25",
           label = "conditions the coarse sweep has here") +
  annotate("text", x = anchor, y = row_refined + 0.09, hjust = 1, vjust = 0,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey25",
           label = "conditions this sweep has here") +
  annotate("text", x = 0.5, y = gap_span[1] + 0.02, hjust = 0,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey25",
           label = "offset-agnostic estimator named") +
  scale_colour_manual(values = gap_room_colours, name = NULL) +
  scale_shape_manual(values = gap_room_shapes, name = NULL) +
  scale_x_continuous(name = "Dispersion of the unknown per-channel offsets (ms)",
                     breaks = seq(0, anchor, by = 1),
                     limits = c(-0.05, anchor + 0.05)) +
  scale_y_continuous(name = "Median error, agnostic minus aware (m)",
                     limits = c(gap_span[1] - 0.04, row_coarse + 0.24)) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE),
         shape = guide_legend(nrow = 2, byrow = TRUE)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.2, "in"),
        legend.margin = margin(0, 0, 0, 0))

RULE_LABEL_MEDIAN <- "median of the trials"
RULE_LABEL_PAIRED <- "paired per-trial count"

crossing_long <- rbind(
  data.frame(room = CROSSINGS$room, rule = RULE_LABEL_MEDIAN,
             at = CROSSINGS$median_ms, stringsAsFactors = FALSE),
  data.frame(room = CROSSINGS$room, rule = RULE_LABEL_PAIRED,
             at = CROSSINGS$paired_ms, stringsAsFactors = FALSE)
)
crossing_long$room <- factor(crossing_long$room, levels = rev(room_order))
crossing_long$rule <- factor(crossing_long$rule, levels = c(RULE_LABEL_MEDIAN, RULE_LABEL_PAIRED))
censored <- CROSSINGS[is.na(CROSSINGS$median_ms), ]
censored$room <- factor(censored$room, levels = rev(room_order))
crossing_long$value_label <- sprintf("%.2f", crossing_long$at)
# The two rules' positions in one array can sit a third of a millisecond apart,
# so the median rule's value reads above its marker, ending at it, and the
# paired rule's below it, centred; neither label then shares a line with the
# other or with a marker, and only one touches the dashed prediction line.
crossing_long$label_hjust <- ifelse(crossing_long$rule == RULE_LABEL_MEDIAN, 1.0, 0.5)
crossing_long$label_vjust <- ifelse(crossing_long$rule == RULE_LABEL_MEDIAN, -1.0, 2.0)

rule_colours <- c(COLOUR_RULE_MEDIAN, COLOUR_RULE_PAIRED)
names(rule_colours) <- c(RULE_LABEL_MEDIAN, RULE_LABEL_PAIRED)

# The notes go where the panel is empty: the dashed line is named at the top,
# right-aligned to it, and the censoring convention is explained in the lower
# left, beside the rows whose arrows it describes.
n_rooms <- length(room_order)
predicted <- CROSS_PREDICTION$predicted_crossing_ms
censored_rows <- as.numeric(censored$room)

right <- ggplot(crossing_long, aes(at, room, colour = rule, shape = rule)) +
  geom_vline(xintercept = predicted, linetype = "dashed", linewidth = 0.4,
             colour = "grey30") +
  geom_segment(data = censored,
               aes(x = censored_above - 0.7, xend = censored_above - 0.05,
                   y = room, yend = room),
               inherit.aes = FALSE, colour = "grey45", linewidth = 0.45,
               arrow = arrow(length = unit(0.05, "in"), type = "closed")) +
  geom_point(size = 2.2, na.rm = TRUE) +
  # White-backed so a value that straddles the dashed prediction line stays
  # legible; the box has no border and reads as plain text.
  geom_label(aes(label = value_label, hjust = label_hjust, vjust = label_vjust),
             size = FIGURE_ANNOTATION_SIZE, show.legend = FALSE, na.rm = TRUE,
             fill = "white", border.colour = NA,
             label.padding = unit(0.04, "lines"), label.r = unit(0, "lines")) +
  geom_text(data = censored,
            aes(x = censored_above, y = room, label = paste0(">", fmt(censored_above, 1))),
            inherit.aes = FALSE, hjust = 1.05, vjust = -0.8,
            size = FIGURE_ANNOTATION_SIZE, colour = "grey35") +
  annotate("text", x = predicted - 0.1, y = n_rooms + 1.2,
           hjust = 1, vjust = 0.5, size = FIGURE_ANNOTATION_SIZE,
           colour = "grey30", lineheight = 0.95,
           label = "predicted from the\ncoarse record") +
  annotate("text", x = 0.1, y = min(censored_rows) + 0.5,
           hjust = 0, vjust = 0.5, size = FIGURE_ANNOTATION_SIZE, colour = "grey35",
           lineheight = 0.95,
           label = "arrows: no crossing\nbelow the coarse sweep's\nlowest condition") +
  scale_colour_manual(values = rule_colours, name = NULL) +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  scale_x_continuous(name = "Where the ordering changes sign (ms)",
                     limits = c(0, anchor + 0.1),
                     breaks = seq(0, anchor, by = 1)) +
  scale_y_discrete(name = NULL, limits = rev(room_order),
                   expand = expansion(add = c(0.7, 1.9))) +
  guides(colour = guide_legend(nrow = 2), shape = guide_legend(nrow = 2)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.2, "in"),
        legend.margin = margin(0, 0, 0, 0),
        panel.grid.major.y = element_line(linewidth = 0.2, colour = "grey92"))

p <- patchwork::wrap_plots(panel_label(left, "A"), panel_label(right, "B"),
                           widths = c(1.3, 1))

save_fig(p, "fig8_breakeven", FIGURE_TEXT_WIDTH_IN, 3.8)
