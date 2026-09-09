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
# The two series share a row, so their censoring arrows are offset vertically
# to stay legible; the offset is a drawing decision and carries no value.
f13$nudge <- ifelse(f13$series == REGISTERED_LABEL, 0.16, -0.16)
f13_censored <- f13[is.na(f13$at), ]
f13_points <- f13[!is.na(f13$at), ]
f13_points$label <- sprintf("%.2f", f13_points$at)
# Registered labels sit above their marker and sensitivity labels to the right,
# so a label never lands on the dashed prediction line or on the other series.
f13_points$label_hjust <- ifelse(f13_points$series == REGISTERED_LABEL, 0.5, -0.3)
f13_points$label_vjust <- ifelse(f13_points$series == REGISTERED_LABEL, -0.9, 0.45)

anchor <- CROSS_ANCHOR$offset_std_ms
series_colours <- c("#1B7837", "#B35806")
names(series_colours) <- c(REGISTERED_LABEL, FOURHUNDRED_LABEL)

p13 <- ggplot(f13_points, aes(at, room, colour = series, shape = series)) +
  annotate("rect", xmin = REGISTERED_INTERVAL[1], xmax = REGISTERED_INTERVAL[2],
           ymin = -Inf, ymax = Inf, fill = "grey88", alpha = 0.55) +
  geom_vline(xintercept = CROSS_PREDICTION$predicted_crossing_ms,
             linetype = "dashed", linewidth = 0.35, colour = "grey30") +
  geom_segment(data = f13_censored,
               aes(x = censored_above - 0.7, xend = censored_above - 0.05,
                   y = as.numeric(room) + nudge, yend = as.numeric(room) + nudge,
                   colour = series),
               inherit.aes = FALSE, linewidth = 0.4, show.legend = FALSE,
               arrow = arrow(length = unit(0.05, "in"), type = "closed")) +
  geom_point(aes(y = as.numeric(room) + nudge), size = 2.1, stroke = 0.7) +
  geom_text(aes(y = as.numeric(room) + nudge, label = label,
                hjust = label_hjust, vjust = label_vjust),
            size = 2.05, show.legend = FALSE) +
  annotate("text", x = REGISTERED_INTERVAL[1] - 0.08, y = length(room_order) + 0.85,
           hjust = 1, vjust = 0.5, size = 2.3, colour = "grey30", lineheight = 0.95,
           label = "shaded: registered interval\ndashed: predicted from the coarse record") +
  annotate("text", x = anchor - 1.35, y = 0.35,
           hjust = 1, vjust = 0.5, size = 2.2, colour = "grey35",
           label = "no crossing below the coarse sweep's lowest condition") +
  scale_colour_manual(values = series_colours, name = NULL) +
  scale_shape_manual(values = c(16, 1), name = NULL) +
  scale_x_continuous(name = "Where the ordering changes sign (ms)",
                     limits = c(0, anchor + 0.1),
                     breaks = seq(0, anchor, by = 1)) +
  scale_y_continuous(name = NULL, breaks = seq_along(levels(f13$room)),
                     labels = levels(f13$room),
                     limits = c(0.1, length(room_order) + 1.2)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.key.width = unit(0.16, "in"),
        legend.margin = margin(0, 0, 0, 0),
        panel.grid.major.y = element_line(linewidth = 0.2, colour = "grey92"))

save_fig(p13, "fig13_fine400", FIGURE_TEXT_WIDTH_IN * 0.88, 2.9)
