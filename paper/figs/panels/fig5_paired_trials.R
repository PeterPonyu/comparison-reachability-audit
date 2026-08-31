# Figure 5. The pairs the summaries were computed from.
#
# This is the disclosure the paper argues for, drawn once so a reader can see
# what it buys. Every trial is one point, both arms ran on it, and the diagonal
# is the tie. The cloud sits on one side of the diagonal while a handful of
# points sit two orders of magnitude away from it, which is the whole of the
# disagreement between the mean and the median in one picture.

f5 <- do.call(rbind, lapply(seq_along(cx_sigma), function(i) {
  tr <- cx_trials[[i]]
  data.frame(sigma = sigma_us(cx_sigma[i]),
             full = tr$hybrid$mic_rmse_m,
             reduced = tr$su$mic_rmse_m)
}))
f5$sigma <- factor(paste0(f5$sigma, " \u00b5s"),
                   levels = paste0(sigma_us(cx_sigma), " \u00b5s"))

# A run that produced no error cannot be placed against the other arm's error,
# and putting it at the edge of the panel would invent a value for it. It is
# drawn as a rug on the axis of the arm that did report, which is the only true
# thing that can be drawn about it.
lost <- f5[!is.finite(f5$full) | !is.finite(f5$reduced), ]
lost$at <- ifelse(is.finite(lost$full), lost$full, lost$reduced)
f5 <- f5[is.finite(f5$full) & is.finite(f5$reduced), ]

span <- range(c(f5$full, f5$reduced))

p <- ggplot(f5, aes(reduced, full)) +
  geom_abline(slope = 1, intercept = 0, colour = "grey45", linewidth = 0.35) +
  geom_point(aes(colour = full < reduced), size = 1.1, alpha = 0.85) +
  geom_rug(data = lost, aes(x = NULL, y = at), sides = "l", colour = "#B2182B",
           linewidth = 0.9, length = unit(0.075, "npc"), inherit.aes = FALSE) +
  facet_wrap(~sigma, nrow = 1) +
  scale_colour_manual(values = c(`TRUE` = "#1B7837", `FALSE` = "#762A83"),
                      labels = c(`TRUE` = "both sets better on this trial",
                                 `FALSE` = "one set better on this trial"),
                      name = NULL) +
  scale_x_log10(name = "Error with one measurement set (m, log scale)",
                limits = span) +
  scale_y_log10(name = "Error with both\nmeasurement sets (m)", limits = span) +
  coord_fixed() +
  rtx_theme() +
  theme(legend.position = "bottom", legend.margin = margin(t = -4),
        strip.text = element_text(size = 8))

save_fig(p, "fig5_paired_trials", FIGURE_TEXT_WIDTH_IN, 2.9)
