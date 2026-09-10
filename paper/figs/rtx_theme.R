# Shared figure theme. R-first by workspace convention; do not add a
# matplotlib path to this tree.
#
# Keep one explicitly installed family for every glyph in the exported PDF.
# Arial is the manuscript's approved visual family.  The regular and bold
# files are resolved and checked before any panel is built; Cairo is then
# allowed to embed that family rather than asking fontconfig to substitute a
# second family for plot annotations.
FIGURE_FONT_FAMILY <- "Arial"

# Keep the visual hierarchy in one place.  The values are deliberately shared
# by every panel so a composed figure does not mix tiny inherited labels with
# larger ad-hoc annotations.  ggplot2 sizes are in points for theme elements
# and millimetres for geom text.
#
# These are printed sizes, not nominal ones.  Each canvas is emitted at its own
# printed width -- the text width times the \linewidth fraction the manuscript
# includes it at -- so TeX scales every figure by 1.0 and a value here reaches
# the page unchanged.  A panel that emits a different canvas width would
# silently rescale its own type and reintroduce the size drift these constants
# exist to prevent; figs/lib/emit.R refuses to write such a canvas.
FIGURE_TEXT_WIDTH_IN <- 6.5
FIGURE_BASE_SIZE <- 9.8
FIGURE_AXIS_TITLE_SIZE <- 8.9
FIGURE_AXIS_TEXT_SIZE <- 8.0
FIGURE_LEGEND_TITLE_SIZE <- 8.2
FIGURE_LEGEND_TEXT_SIZE <- 7.8
FIGURE_STRIP_TEXT_SIZE <- 8.4
FIGURE_TITLE_SIZE <- 10.7
FIGURE_SUBTITLE_SIZE <- 8.2
# geom text is sized in millimetres; 2.5 mm is 7.1 pt, the smallest type the
# print standard allows at final size, and no in-panel annotation goes below
# it.  The larger step is for text that has to be read as a heading inside a
# panel (the ladder rungs).
FIGURE_ANNOTATION_SIZE <- 2.50
FIGURE_CELL_SIZE <- 2.50
FIGURE_HEADING_SIZE <- 2.95
FIGURE_PANEL_LABEL_SIZE <- 10

# One colour-blind-safe palette for every figure (Okabe & Ito 2008).  Each
# semantic pair in the paper is fixed here once so the same estimator is the
# same colour on every page: the arms of the offset sweep, the two locally
# written estimators of the third comparison, and the summary rules.  Tints
# for filled cells are the same hues mixed towards white so text set on them
# stays legible.
OKABE_ITO <- c(black = "#000000", orange = "#E69F00", skyblue = "#56B4E9",
               green = "#009E73", yellow = "#F0E442", blue = "#0072B2",
               vermillion = "#D55E00", purple = "#CC79A7")
oi_tint <- function(colour, amount = 0.35) {
  rgb <- grDevices::col2rgb(colour)
  grDevices::rgb(t(255 - amount * (255 - rgb)), maxColorValue = 255)
}
COLOUR_AGNOSTIC <- OKABE_ITO[["vermillion"]]
COLOUR_AWARE <- OKABE_ITO[["blue"]]
COLOUR_FULL <- OKABE_ITO[["green"]]
COLOUR_REDUCED <- OKABE_ITO[["purple"]]
COLOUR_RULE_MEAN <- OKABE_ITO[["orange"]]
COLOUR_RULE_MEDIAN <- OKABE_ITO[["black"]]
COLOUR_RULE_PAIRED <- OKABE_ITO[["skyblue"]]
COLOUR_ROOMS <- unname(OKABE_ITO[c("orange", "skyblue", "green", "blue",
                                   "vermillion", "purple")])
SHAPE_ROOMS <- c(16, 17, 15, 18, 8, 7)

# Resolve the family before any panel is built.  A `family` string alone is not
# enough: on a different host Cairo can silently substitute a fallback when a
# regular or bold face is absent, and it does so per glyph rather than per
# figure, so a single character can arrive in a different typeface than the
# label around it.  The generator therefore fails closed if the two Arial faces
# or the Unicode glyphs used by the annotations cannot be resolved.  The minus
# sign is on the list because ggplot2 sets negative axis breaks with U+2212
# rather than a hyphen, and the mu because a plotmath unit resolves to it.
FIGURE_REQUIRED_GLYPHS <- c("\u03c3", "\u00d7", "\u00b1", "\u00b0", "\u2192",
                            "\u03bc", "\u2212", "\u2013")

validate_figure_font <- function() {
  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    stop("systemfonts is required to resolve the embedded figure font")
  }
  matches <- suppressWarnings(systemfonts::match_fonts(
    family = FIGURE_FONT_FAMILY,
    weight = c("normal", "bold")
  ))
  if (nrow(matches) != 2L || any(!file.exists(matches$path))) {
    stop("figure font family must provide installed regular and bold faces: ",
         FIGURE_FONT_FAMILY)
  }
  font_info <- systemfonts::font_info(path = matches$path)
  if (nrow(font_info) != 2L || any(font_info$family != FIGURE_FONT_FAMILY) ||
      !identical(as.logical(font_info$bold), c(FALSE, TRUE)) ||
      !identical(as.character(font_info$name), c("ArialMT", "Arial-BoldMT"))) {
    stop("figure font resolver returned a fallback or unexpected Arial face")
  }
  for (weight in c("normal", "bold")) {
    glyphs <- systemfonts::glyph_info(FIGURE_REQUIRED_GLYPHS,
                                      family = FIGURE_FONT_FAMILY,
                                      weight = weight)
    if (nrow(glyphs) != length(FIGURE_REQUIRED_GLYPHS) ||
        any(is.na(glyphs$index)) || any(glyphs$width <= 0)) {
      stop("figure font lacks one or more required Unicode glyphs at weight ",
           weight, ": ", FIGURE_FONT_FAMILY)
    }
  }
  invisible(matches$path)
}

validate_figure_font()

# ggplot2's newer defaults inherit `family` from the theme, but older releases
# leave text geoms at the host default.  Set both common text geoms explicitly so
# annotations that do not repeat `family =` cannot reintroduce a fallback.
ggplot2::update_geom_defaults("text", list(family = FIGURE_FONT_FAMILY))
ggplot2::update_geom_defaults("label", list(family = FIGURE_FONT_FAMILY))

rtx_theme <- function(base_size = FIGURE_BASE_SIZE) {
  ggplot2::theme_bw(base_size = base_size, base_family = FIGURE_FONT_FAMILY) +
    ggplot2::theme(
      text = ggplot2::element_text(family = FIGURE_FONT_FAMILY, colour = "black"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(colour = "black", linewidth = 0.3),
      axis.ticks = ggplot2::element_line(linewidth = 0.3),
      axis.title = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                         size = FIGURE_AXIS_TITLE_SIZE),
      axis.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                        size = FIGURE_AXIS_TEXT_SIZE),
      legend.title = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                           size = FIGURE_LEGEND_TITLE_SIZE),
      legend.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                          size = FIGURE_LEGEND_TEXT_SIZE),
      strip.text = ggplot2::element_text(family = FIGURE_FONT_FAMILY,
                                         size = FIGURE_STRIP_TEXT_SIZE),
      legend.key = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank()
    )
}

# Apply a panel label to one member of a composed figure.  A ggplot plot tag
# with `plot.tag.location = "panel"` is anchored to the panel viewport itself;
# hjust=1 and vjust=0 put the right/bottom edges on the upper-left spine and
# extend the glyph into the outer top/left margin.  This is deliberately not a
# data-space annotation: it stays outside the plotting region for linear, log,
# discrete and faceted scales alike, and patchwork keeps one tag per composed
# panel.
#
# A caption that says "left" describes where a panel happened to land in one
# composition; a caption that says "Panel A" describes the panel.  The label is
# what lets the caption stay self-contained, so every composed figure in this
# tree carries one.
#
# The title and subtitle are optional: a composed panel that already reads from
# its axes gets a label without acquiring a heading it did not have.
panel_label <- function(plot, label, title = NULL, subtitle = NULL) {
  if (!is.null(subtitle)) {
    subtitle <- paste(strwrap(subtitle, width = 48), collapse = "\n")
  }
  plot +
    ggplot2::labs(title = title, subtitle = subtitle, tag = label) +
    ggplot2::theme(
      plot.title.position = "panel",
      plot.title = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 0.5,
        size = FIGURE_TITLE_SIZE, face = "plain",
        margin = ggplot2::margin(b = 2.5)
      ),
      plot.subtitle = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 0.5,
        size = FIGURE_SUBTITLE_SIZE, colour = "grey25",
        lineheight = 0.95, margin = ggplot2::margin(b = 3.5)
      ),
      plot.tag.location = "panel",
      plot.tag.position = c(0, 1),
      plot.tag = ggplot2::element_text(
        family = FIGURE_FONT_FAMILY, hjust = 1, vjust = 0,
        size = FIGURE_PANEL_LABEL_SIZE, face = "bold",
        margin = ggplot2::margin(0, 0, 0, 0)
      ),
      # Keep enough outer room for the label's ascender and leftward extent.
      plot.margin = ggplot2::margin(t = 16, r = 8, b = 8, l = 16)
    )
}
