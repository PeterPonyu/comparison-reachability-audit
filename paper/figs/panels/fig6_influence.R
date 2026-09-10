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

RULE_LINE_MEAN <- "gap between means"
RULE_LINE_MEDIAN <- "gap between medians"
rule_line_colours <- c(COLOUR_RULE_MEAN, COLOUR_RULE_MEDIAN)
names(rule_line_colours) <- c(RULE_LINE_MEAN, RULE_LINE_MEDIAN)
rule_line_types <- c("solid", "22")
names(rule_line_types) <- c(RULE_LINE_MEAN, RULE_LINE_MEDIAN)

p <- ggplot(f6, aes(excluded, mean_gap)) +
  geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.4) +
  geom_line(aes(y = median_gap, colour = RULE_LINE_MEDIAN, linetype = RULE_LINE_MEDIAN),
            linewidth = 0.55) +
  geom_line(aes(colour = RULE_LINE_MEAN, linetype = RULE_LINE_MEAN), linewidth = 0.65) +
  geom_point(size = 1.4, colour = COLOUR_RULE_MEAN) +
  geom_point(data = flips, shape = 21, size = 3.6, stroke = 0.7, fill = NA,
             colour = "black") +
  facet_wrap(~sigma, nrow = 1, scales = "free_y") +
  scale_colour_manual(values = rule_line_colours, name = NULL) +
  scale_linetype_manual(values = rule_line_types, name = NULL) +
  scale_x_continuous(name = "Largest trials of each arm set aside",
                     breaks = 0:CX_TRIM_DEPTH) +
  scale_y_continuous(name = "Gap, both sets minus one set (m)") +
  guides(colour = guide_legend(override.aes = list(linewidth = 0.8))) +
  rtx_theme() +
  theme(legend.position = "bottom", legend.margin = margin(t = -4),
        legend.key.width = unit(0.3, "in"))

save_fig(p, "fig6_influence", FIGURE_TEXT_WIDTH_IN, 2.9)
