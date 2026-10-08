# Recall vs QPS plots from the ann-benchmarks sweep CSVs.
#
# Usage: Rscript inst/benchmarks/plot_results.R
#
# One PNG per dataset x threads run, written next to the benchmarks article.
# Colour encodes role (annsearchR / CRAN package / BiocNeighbors), not the
# library, so every panel stays within three validated hues; each line is also
# labelled directly. The dashed line is annsearchR's exhaustive search, which
# any approximate index has to beat to be worth building.

results_dir <- file.path("inst", "benchmarks", "results")
out_dir <- file.path("vignettes", "articles", "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

role_colours <- c(
  "annsearchR" = "#2a78d6",
  "CRAN package" = "#eb6834",
  "BiocNeighbors" = "#1baf7a"
)
method_labels <- c(
  hnsw = "HNSW",
  annoy = "Annoy",
  nndescent = "NN-Descent",
  ivf = "IVF"
)
min_recall <- 0.8

plot_run <- function(sweep_file) {
  sweep <- data.table::fread(sweep_file)
  stem <- sub("_sweep\\.csv$", "", basename(sweep_file))

  exact <- sweep[library == "annsearchR" & method == "exhaustive"]
  approx <- sweep[method %in% names(method_labels) & recall >= min_recall]
  approx[,
    role := data.table::fcase(
      library == "annsearchR",
      "annsearchR",
      library == "BiocNeighbors",
      "BiocNeighbors",
      default = "CRAN package"
    )
  ]
  approx[, panel := factor(method_labels[method], levels = method_labels)]
  approx[, role := factor(role, levels = names(role_colours))]
  data.table::setorder(approx, library, method, recall)

  # direct label at the fastest point that clears the recall floor
  # BiocNeighbors is a single point per panel and the only library in its role:
  # the legend plus its own shape names it, a label would only collide
  labels <- approx[
    role != "BiocNeighbors",
    .SD[which.max(qps)],
    by = .(library, panel)
  ]
  # anchor towards the panel interior so labels never clip at the edges
  labels[, hjust := data.table::fifelse(recall > 0.93, 1, 0)]
  # annsearchR sits on top in every panel; comparators label below their point
  labels[, vjust := data.table::fifelse(role == "annsearchR", -0.9, 1.9)]

  p <- ggplot2::ggplot(
    approx,
    ggplot2::aes(recall, qps, colour = role, shape = role, group = library)
  ) +
    ggplot2::geom_hline(
      yintercept = exact$qps,
      linetype = "dashed",
      linewidth = 0.4,
      colour = "#52514e"
    ) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_point(ggplot2::aes(size = role)) +
    ggplot2::scale_size_manual(
      values = c("annsearchR" = 2.4, "CRAN package" = 2.4, "BiocNeighbors" = 4),
      guide = "none"
    ) +
    ggplot2::geom_text(
      data = labels,
      ggplot2::aes(label = library, hjust = hjust, vjust = vjust),
      size = 3,
      colour = "#0b0b0b",
      show.legend = FALSE
    ) +
    ggplot2::facet_wrap(~panel, nrow = 1, drop = TRUE) +
    ggplot2::scale_y_log10(
      labels = scales::label_comma(),
      expand = ggplot2::expansion(mult = c(0.05, 0.2))
    ) +
    ggplot2::scale_x_continuous(limits = c(min_recall, 1)) +
    ggplot2::scale_colour_manual(values = role_colours, drop = FALSE) +
    ggplot2::scale_shape_manual(
      values = c("annsearchR" = 16, "CRAN package" = 16, "BiocNeighbors" = 18),
      drop = FALSE
    ) +
    ggplot2::labs(
      x = sprintf("Recall@10 (from %.1f)", min_recall),
      y = "Queries per second (log scale)",
      colour = NULL,
      shape = NULL,
      caption = sprintf(
        "Dashed: annsearchR exhaustive search, %s QPS",
        format(round(exact$qps), big.mark = ",")
      )
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "top",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#e6e5e0"),
      plot.background = ggplot2::element_rect(fill = "#fcfcfb", colour = NA),
      text = ggplot2::element_text(colour = "#0b0b0b"),
      axis.text = ggplot2::element_text(colour = "#52514e"),
      plot.caption = ggplot2::element_text(colour = "#52514e")
    )

  n_panels <- data.table::uniqueN(approx$panel)
  ggplot2::ggsave(
    file.path(out_dir, paste0(stem, ".png")),
    p,
    width = 2.6 * n_panels + 0.6,
    height = 3.8,
    dpi = 150
  )
}

sweeps <- list.files(results_dir, pattern = "_sweep\\.csv$", full.names = TRUE)
invisible(lapply(sweeps, plot_run))
