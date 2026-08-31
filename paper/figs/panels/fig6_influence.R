# Figure 6. How much of the printed answer one trial in forty is carrying.
#
# The curve recomputes each arm's mean after setting aside its own largest
# trials, and plots the gap between the two arms. Where the curve is on the
# wrong side of zero the mean names one estimator; where it crosses, it names
# the other. The dashed line is the same gap between medians, drawn at the same
# scale, and it does not move.
#
# Setting trials aside is a measurement of leverage here, not a proposal. No
# quantity this paper reports as a result is computed from a trimmed sample.

f6 <- CX_INFLUENCE
f6$sigma <- factor(paste0(sigma_us(f6$sigma_s), " \u00b5s"),
                   levels = paste0(sigma_us(cx_sigma), " \u00b5s"))

flips <- data.frame(
  sigma = factor(paste0(sigma_us(as.numeric(names(CX_FLIP_DEPTH))), " \u00b5s"),
                 levels = levels(f6$sigma)),
  excluded = as.integer(CX_FLIP_DEPTH)
)
flips <- merge(flips, f6[, c("sigma", "excluded", "mean_gap")],
               by = c("sigma", "excluded"))

p <- ggplot(f6, aes(excluded, mean_gap)) +
  geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.35) +
  geom_line(aes(y = median_gap, linetype = "between medians"), colour = "#1B7837",
            linewidth = 0.5) +
  geom_line(aes(linetype = "between means"), colour = "#762A83", linewidth = 0.6) +
  geom_point(size = 1.2, colour = "#762A83") +
  geom_point(data = flips, shape = 21, size = 3.4, stroke = 0.7, fill = NA,
             colour = "black") +
  facet_wrap(~sigma, nrow = 1, scales = "free_y") +
  scale_linetype_manual(values = c(`between means` = "solid",
                                   `between medians` = "22"), name = NULL) +
  scale_x_continuous(name = "Largest trials of each arm set aside",
                     breaks = 0:CX_TRIM_DEPTH) +
  scale_y_continuous(name = "Gap, both sets minus one set (m)") +
  labs(subtitle = paste("Below zero the summary names the both-set estimator;",
                        "the ring marks where the mean first agrees with the median")) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.margin = margin(t = -4),
        plot.subtitle = element_text(size = 7.4, colour = "grey25"),
        strip.text = element_text(size = 8))

save_fig(p, "fig6_influence", FIGURE_TEXT_WIDTH_IN, 2.9)
