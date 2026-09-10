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

# A zero-height bar draws nothing, so the unanimous loss is carried by its
# count label, set in the agnostic estimator's colour because that is the arm
# that won every trial there.
f3$label_colour <- ifelse(f3$wins == 0, COLOUR_AGNOSTIC, "grey10")

p <- ggplot(f3, aes(offset, wins)) +
  geom_hline(yintercept = TRIALS / 2, linetype = "22", colour = "grey35",
             linewidth = 0.4) +
  geom_col(fill = COLOUR_AWARE, width = 0.66, colour = "grey20", linewidth = 0.25) +
  geom_text(aes(label = sprintf("%d/%d", wins, n), colour = label_colour),
            vjust = -0.5, size = FIGURE_ANNOTATION_SIZE, show.legend = FALSE) +
  scale_colour_identity() +
  annotate("text", x = 0.55, y = TRIALS / 2, label = "50% reference",
           hjust = 0, vjust = -0.5, size = FIGURE_ANNOTATION_SIZE, colour = "grey30") +
  scale_x_discrete(name = "Dispersion of the unknown per-channel offsets (ms)") +
  scale_y_continuous(name = sprintf("Trials won by the offset-aware\nestimator, of %d", TRIALS),
                     limits = c(0, TRIALS * 1.12),
                     breaks = seq(0, TRIALS, 10)) +
  rtx_theme()

save_fig(p, "fig3_paired_wins", 0.88 * FIGURE_TEXT_WIDTH_IN, 2.9)
