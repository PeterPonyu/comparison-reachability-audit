# Figure 3. The same comparison counted per trial rather than summarised. A
# median ratio says the offset-aware estimator loses at the zero-offset
# condition; the win count says it loses on every single paired trial, which is
# a stronger and simpler statement and does not depend on the summary statistic.

f3 <- data.frame(
  offset = factor(pr$offset_std_ms, levels = pr$offset_std_ms),
  wins = pr$n_trials_aware_better,
  n = pr$n_pairs
)

TRIALS <- single_valued(f3$n, "how many paired trials each condition ran")

p <- ggplot(f3, aes(offset, wins)) +
  geom_hline(yintercept = TRIALS / 2, linetype = "22", colour = "grey35",
             linewidth = 0.35) +
  geom_col(aes(fill = wins == 0), width = 0.66, colour = "grey20", linewidth = 0.25) +
  geom_text(aes(label = sprintf("%d/%d", wins, n)), vjust = -0.5, size = 2.5) +
  annotate("text", x = 0.55, y = TRIALS / 2, label = "50% reference",
           hjust = 0, vjust = -0.5, size = 2.4, colour = "grey30") +
  scale_fill_manual(values = c(`FALSE` = "#2166AC", `TRUE` = "#B2182B"), guide = "none") +
  scale_x_discrete(name = "Dispersion of the unknown per-channel offsets (ms)") +
  scale_y_continuous(name = "Trials where the offset-aware method won",
                     limits = c(0, TRIALS * 1.12),
                     breaks = seq(0, TRIALS, 10)) +
  labs(subtitle = sprintf("Labels are aware wins / %d paired trials; red marks zero aware wins",
                          TRIALS)) +
  rtx_theme()

save_fig(p, "fig3_paired_wins", 0.88 * FIGURE_TEXT_WIDTH_IN, 2.9)
