# Figure 7. The same estimators against the same bound, summarised two ways.
#
# The Cramer-Rao bound is a property of the array geometry and the timing noise,
# so it is the same number under either rule and the whole of the spread here
# comes from the numerator. Read through the mean, both estimators look between
# two and sixteen times worse than the best any unbiased estimator could do.
# Read through the median, both sit within a small factor of it.

f7 <- do.call(rbind, lapply(CX_COMPARISONS, function(x) {
  data.frame(
    sigma = sigma_us(x$sigma_s),
    arm = rep(c(CX_FULL, CX_REDUCED), each = 2),
    rule = rep(c(RULE_MEAN, RULE_MEDIAN), times = 2),
    ratio = unname(x$eff[c("full_mean", "full_median",
                           "reduced_mean", "reduced_median")])
  )
}))
f7$sigma <- factor(paste0(f7$sigma, " \u00b5s"),
                   levels = paste0(sigma_us(cx_sigma), " \u00b5s"))
f7$rule <- factor(f7$rule, levels = c(RULE_MEAN, RULE_MEDIAN))

# The two median-rule values at one condition sit within a few per cent of the
# bound and of each other, so their labels are pushed apart vertically: the
# larger of the pair reads above its marker and the smaller below it.  The
# mean-rule values are far apart and read to the right of their markers.
f7$label_hjust <- -0.35
f7$label_vjust <- 0.4
for (s in levels(f7$sigma)) {
  rows <- which(f7$sigma == s & f7$rule == RULE_MEDIAN)
  upper <- rows[which.max(f7$ratio[rows])]
  lower <- rows[which.min(f7$ratio[rows])]
  f7$label_hjust[c(upper, lower)] <- 0.5
  f7$label_vjust[upper] <- -1.1
  f7$label_vjust[lower] <- 2.1
}

p <- ggplot(f7, aes(sigma, ratio, colour = arm, shape = rule)) +
  geom_hline(yintercept = 1, colour = "grey35", linewidth = 0.4) +
  annotate("text", x = 3.55, y = 1, label = "at the bound", hjust = 1, vjust = -0.6,
           size = FIGURE_ANNOTATION_SIZE, colour = "grey30") +
  geom_line(aes(group = interaction(arm, rule)), linewidth = 0.45, alpha = 0.6) +
  geom_point(size = 2.2, stroke = 0.7) +
  geom_text(aes(label = ratio_label(ratio), hjust = label_hjust, vjust = label_vjust),
            size = FIGURE_ANNOTATION_SIZE, show.legend = FALSE) +
  scale_colour_manual(values = cx_colours, name = NULL) +
  scale_shape_manual(values = c(16, 1), name = NULL) +
  scale_x_discrete(name = "Timing-noise standard deviation",
                   expand = expansion(add = c(0.55, 0.75))) +
  scale_y_log10(name = "Error over the bound", expand = expansion(mult = 0.16)) +
  guides(colour = guide_legend(order = 1), shape = guide_legend(order = 2)) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.box = "vertical",
        legend.spacing.y = unit(0, "pt"), legend.margin = margin(t = -4))

save_fig(p, "fig7_efficiency", 0.88 * FIGURE_TEXT_WIDTH_IN, 3.1)
