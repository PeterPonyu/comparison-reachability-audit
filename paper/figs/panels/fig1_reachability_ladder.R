# Figure 1. The reachability ladder, as observed rather than as recorded. The
# arrow is the whole point of drawing it as a ladder: the rungs are ordered, so
# the first one that breaks takes every rung above it with it, and the top rung
# is unreachable without anyone having formed an opinion about the method there.

# A second axis that is not a rung. The corpus is openly downloadable and still
# absent from this machine, which is a different kind of obstacle from a broken
# rung and is drawn apart from the ladder so it cannot be counted as one.
corpus_note <- wrap_to(paste(
  "Separate axis: the evaluation corpus is publicly archived and openly downloadable,",
  "but is not present on this machine. A resolvable link is not a local asset."
))

p <- ggplot(ladder) +
  geom_rect(aes(xmin = 0, xmax = 1, ymin = y - 0.40, ymax = y + 0.40, fill = status),
            colour = "grey25", linewidth = 0.3) +
  geom_text(aes(x = 0.018, y = y + 0.19, label = label),
            hjust = 0, vjust = 0.5, size = 2.9, fontface = "bold", colour = "grey10") +
  geom_text(aes(x = 0.018, y = y - 0.17, label = observation),
            hjust = 0, vjust = 0.5, size = 2.3, colour = "grey25", lineheight = 0.98) +
  annotate("segment", x = 1.035, xend = 1.035,
           y = FIRST_BREAK - 0.42, yend = nrow(ladder) + 0.42, colour = "#B2182B",
           linewidth = 0.5,
           arrow = grid::arrow(length = unit(0.06, "in"), type = "closed")) +
  annotate("text", x = 1.055, y = (FIRST_BREAK + nrow(ladder)) / 2,
           label = "everything above\nthe first break is\nunreachable too",
           hjust = 0, size = 2.3, colour = "#B2182B", lineheight = 0.98) +
  annotate("rect", xmin = 0, xmax = 1, ymin = 0.14, ymax = 0.62,
           fill = "grey93", colour = "grey60", linewidth = 0.25) +
  annotate("text", x = 0.018, y = 0.38, label = corpus_note,
           hjust = 0, vjust = 0.5, size = 2.3, colour = "grey25", lineheight = 0.98) +
  scale_fill_manual(values = status_colours, name = NULL,
                    breaks = c(REACHABLE, BROKEN)) +
  scale_x_continuous(limits = c(0, 1.30), expand = expansion(add = 0.01)) +
  scale_y_continuous(expand = expansion(add = 0.22)) +
  # theme_void rather than the shared theme because the ladder carries no axes,
  # but the family and the legend size still come from the shared scale: a bare
  # theme_void would leave the legend at the device default face.
  theme_void(base_size = FIGURE_BASE_SIZE, base_family = FIGURE_FONT_FAMILY) +
  theme(legend.position = "top",
        legend.text = element_text(family = FIGURE_FONT_FAMILY,
                                   size = FIGURE_LEGEND_TEXT_SIZE),
        legend.margin = margin(0, 0, -2, 0),
        legend.key.size = unit(0.16, "in"),
        plot.margin = margin(2, 2, 2, 2))

save_fig(p, "fig1_reachability_ladder", FIGURE_TEXT_WIDTH_IN, 3.9)
