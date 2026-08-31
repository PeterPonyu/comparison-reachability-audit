# Figure 4. One set of trials, three summaries, and the answers they give.
#
# The three rows are not three experiments. They are three ways of reducing the
# same forty paired trials at each condition to a sentence about which estimator
# was better, and the top row disagrees with the two below it at two of the
# three conditions.

f4 <- do.call(rbind, lapply(CX_COMPARISONS, function(x) {
  data.frame(
    sigma = sigma_us(x$sigma_s),
    rule = factor(DISPLAY_RULES, levels = rev(DISPLAY_RULES)),
    winner = unname(x$by_rule[DISPLAY_RULES]),
    detail = c(
      sprintf("%s vs %s m", fmt(x$a$mean, 3), fmt(x$b$mean, 3)),
      sprintf("%s vs %s m", fmt(x$a$median, 3), fmt(x$b$median, 3)),
      sprintf("%d of %d, p = %s", x$wins_a, x$n_pairs, p_cell(x$p_two_sided))
    )
  )
}))
f4$sigma <- factor(f4$sigma, levels = unique(f4$sigma))

# The row that stands apart is the one worth pointing at, and which row that is
# is read off the data rather than assumed to be the first.
majority <- vapply(split(f4$winner, f4$sigma), function(w) names(sort(table(w),
                   decreasing = TRUE))[1], character(1))
f4$odd <- f4$winner != majority[as.character(f4$sigma)]

p <- ggplot(f4, aes(sigma, rule)) +
  geom_tile(aes(fill = winner), colour = "white", linewidth = 1.1) +
  geom_tile(data = f4[f4$odd, ], fill = NA, colour = "black", linewidth = 0.8) +
  geom_text(aes(label = paste0(winner, "\n", detail)), size = 2.35,
            lineheight = 1.15, colour = "grey15") +
  scale_fill_manual(values = c("#CBE6D0", "#E4D3EC"), guide = "none",
                    limits = c(CX_FULL, CX_REDUCED)) +
  # The micro sign is a literal in the shared family rather than a plotmath
  # `mu`: plotmath resolves symbols through the device's own font handling, and
  # Cairo answers that by embedding a second family for this one glyph.
  scale_x_discrete(name = "Timing-noise standard deviation (\u03bcs)") +
  scale_y_discrete(name = NULL) +
  labs(subtitle = "Which estimator each rule names as the better one") +
  rtx_theme() +
  theme(plot.subtitle = element_text(size = FIGURE_SUBTITLE_SIZE, colour = "grey25"),
        panel.grid.major = element_blank())

save_fig(p, "fig4_display_rule", FIGURE_TEXT_WIDTH_IN, 2.5)
