# Figure 13. The registered crossing beside its 400-trial re-evaluation.
#
# One row per array. The filled marker is the registered crossing, located on
# 40 paired trials per cell; the hollow marker is the same rule applied to the
# same cells read on 400 trials, which is a labelled sensitivity and not a
# replacement. The shaded band is the registered interval, the span of the
# registered crossings across the arrays that crossed. Arrays whose ordering had
# not changed sign by the top of the grid are drawn as arrows leaving it, under
# either trial count, because a sweep that stops below a crossing has not
# measured one.
#
# The registered series is drawn exactly as the median-rule crossing is drawn
# in Figure 8, Panel B -- same marker, same colour, same axis, same array
# order -- so the two figures read as one object.  The sensitivity series is a
# hollow marker in grey, drawn underneath: it is there to be compared with the
# registered position, not to compete with it.

room_order <- CROSSINGS$room
REGISTERED_LABEL <- sprintf("%d trials per cell (registered)", fine$n_trials_per_cell)
FOURHUNDRED_LABEL <- sprintf("%d trials per cell (sensitivity)", fine400$n_trials_per_cell)

f13 <- rbind(
  data.frame(room = CROSSINGS$room, series = REGISTERED_LABEL,
             at = CROSSINGS$median_ms,
             censored_above = CROSSINGS$censored_above,
             stringsAsFactors = FALSE),
  data.frame(room = FINE400_CROSSINGS$room, series = FOURHUNDRED_LABEL,
             at = ifelse(FINE400_CROSSINGS$crossed, FINE400_CROSSINGS$settled_ms, NA_real_),
             censored_above = ifelse(FINE400_CROSSINGS$crossed, NA_real_,
                                     FINE400_CROSSINGS$censored_above),
             stringsAsFactors = FALSE)
)
f13$room <- factor(f13$room, levels = rev(room_order))
f13$series <- factor(f13$series, levels = c(REGISTERED_LABEL, FOURHUNDRED_LABEL))
# The two series share a row, so their markers and censoring arrows are offset
# vertically to stay legible; the offset is a drawing decision and carries no
# value.  The registered series takes the upper position.
f13$nudge <- ifelse(f13$series == REGISTERED_LABEL, 0.2, -0.2)
f13_censored <- f13[is.na(f13$at), ]
f13_points <- f13[!is.na(f13$at), ]
f13_points$label <- sprintf("%.2f", f13_points$at)
# Registered values read above their marker, ending at it, as the median-rule
# values do in Figure 8; sensitivity values read to the right of theirs.  Neither
# then lands on the other series, on a censoring arrow of the next row, or on
# the dashed prediction line.
f13_points$label_hjust <- ifelse(f13_points$series == REGISTERED_LABEL, 1.0, -0.3)
f13_points$label_vjust <- ifelse(f13_points$series == REGISTERED_LABEL, -1.0, 0.4)

anchor <- CROSS_ANCHOR$offset_std_ms
n_rooms <- length(room_order)
predicted <- CROSS_PREDICTION$predicted_crossing_ms
series_colours <- c(COLOUR_RULE_MEDIAN, "grey45")
names(series_colours) <- c(REGISTERED_LABEL, FOURHUNDRED_LABEL)

# Draw the sensitivity first and the registered series on top of it.
f13_points <- f13_points[order(f13_points$series, decreasing = TRUE), ]

p13 <- ggplot(f13_points, aes(at, room, colour = series, shape = series)) +
  annotate("rect", xmin = REGISTERED_INTERVAL[1], xmax = REGISTERED_INTERVAL[2],
           ymin = -Inf, ymax = Inf, fill = "grey88", alpha = 0.55) +
  geom_vline(xintercept = predicted, linetype = "dashed", linewidth = 0.4,
             colour = "grey30") +
  geom_segment(data = f13_censored,
               aes(x = censored_above - 0.7, xend = censored_above - 0.05,
                   y = as.numeric(room) + nudge, yend = as.numeric(room) + nudge,
                   colour = series),
               inherit.aes = FALSE, linewidth = 0.45, show.legend = FALSE,
               arrow = arrow(length = unit(0.05, "in"), type = "closed")) +
  geom_point(aes(y = as.numeric(room) + nudge), size = 2.2, stroke = 0.7) +
  geom_label(aes(y = as.numeric(room) + nudge, label = label,
                 hjust = label_hjust, vjust = label_vjust),
             size = FIGURE_ANNOTATION_SIZE, show.legend = FALSE,
             fill = "white", border.colour = NA,
             label.padding = unit(0.04, "lines"), label.r = unit(0, "lines")) +
  annotate("text", x = 0.05, y = n_rooms + 0.95, hjust = 0, vjust = 0.5,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey30", lineheight = 0.95,
           label = "shaded band: registered interval\ndashed line: predicted from the coarse record") +
  annotate("text", x = 0.05, y = 1.5, hjust = 0, vjust = 0.5,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey35", lineheight = 0.95,
           label = "arrows: no crossing below the coarse sweep's lowest condition") +
  scale_colour_manual(values = series_colours, name = NULL) +
  scale_shape_manual(values = c(16, 1), name = NULL) +
  scale_x_continuous(name = "Where the ordering changes sign (ms)",
                     limits = c(0, anchor + 0.1),
                     breaks = seq(0, anchor, by = 1)) +
  scale_y_continuous(name = NULL, breaks = seq_along(levels(f13$room)),
                     labels = levels(f13$room),
                     limits = c(0.3, n_rooms + 1.35)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.2, "in"),
        legend.margin = margin(0, 0, 0, 0),
        panel.grid.major.y = element_line(linewidth = 0.2, colour = "grey92"))

save_fig(p13, "fig13_fine400", FIGURE_TEXT_WIDTH_IN * 0.88, 3.1)
