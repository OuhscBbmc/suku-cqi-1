rm(list = ls(all.names = TRUE)) # Clear the memory of variables from previous run. This is not called by knitr, because it's above the first chunk.

# ---- load-sources ------------------------------------------------------------
#Load any source files that contain/define functions, but that don't load any other types of variables
#   into memory.  Avoid side effects and don't pollute the global environment.
# source("SomethingSomething.R")

# ---- load-packages -----------------------------------------------------------
library(ggplot2) #For graphing
import::from("magrittr", "%>%")
requireNamespace("dplyr")
# requireNamespace("RColorBrewer")
# requireNamespace("scales") #For formating values in graphs
# requireNamespace("mgcv) #For the Generalized Additive Model that smooths the longitudinal graphs.
# requireNamespace("TabularManifest") # remotes::install_github("Melinae/TabularManifest")

# ---- declare-globals ---------------------------------------------------------
options(show.signif.stars=F) #Turn off the annotations on p-values
config                      <- config::get()
levels_metric       <- c(
  "stroke", "antithromb", "anticoag", "statin", "smoking", "cumulative"
)

palette_dark <- list( # http://colrd.com/image-dna/50489/
  # "#141e1f",            # black
  "boundary" = "#3e525c", # dark gray
  "post"  = "#27403a",    # dark green
  "pre"   = "#804d1e"     # dark brown
  # "#77b6c4",            # light blue
  # "post"  = "#185f63",    # lighter green
  # "pre"   = "#c5873e"     # lighter brown
)
palette_light <- list( # http://colrd.com/image-dna/50489/
  # "#141e1f",            # black
  "boundary" = "#3e525c", # dark gray
  # "post"  = "#27403a",    # dark green
  # "pre"   = "#804d1e",    # dark brown
  # "#77b6c4",            # light blue
  "post"  = "#185f63",    # lighter green
  "pre"   = "#c5873e"     # lighter brown
)
# OuhscMunge::readr_spec_aligned(config$path_month_raw)

col_types <- readr::cols_only(
  `month`                     = readr::col_date(format = ""),
  `phase`                     = readr::col_character(),
  `stroke_numerator`          = readr::col_integer(),
  `stroke_denominator`        = readr::col_integer(),
  `antithromb_numerator`      = readr::col_integer(),
  `antithromb_denominator`    = readr::col_integer(),
  `anticoag_numerator`        = readr::col_integer(),
  `anticoag_denominator`      = readr::col_integer(),
  `statin_numerator`          = readr::col_integer(),
  `statin_denominator`        = readr::col_integer(),
  `smoking_numerator`         = readr::col_integer(),
  `smoking_denominator`       = readr::col_integer(),
  `cumulative_numerator`      = readr::col_integer(),
  `cumulative_denominator`    = readr::col_integer()
)

# ---- load-data ---------------------------------------------------------------
ds_wide <- readr::read_csv(config$path_month_raw, col_types = col_types)

# ---- tweak-data --------------------------------------------------------------
pattern <- "^(\\w+)_(numerator|denominator)$"
ds <-
  ds_wide %>%
  dplyr::mutate(
    cumulative_numerator =
      dplyr::coalesce(stroke_numerator        , 0L) +
      dplyr::coalesce(antithromb_numerator    , 0L) +
      dplyr::coalesce(anticoag_numerator      , 0L) +
      dplyr::coalesce(statin_numerator        , 0L) +
      dplyr::coalesce(smoking_numerator       , 0L),
    cumulative_denominator =
      dplyr::coalesce(stroke_denominator      , 0L) +
      dplyr::coalesce(antithromb_denominator  , 0L) +
      dplyr::coalesce(anticoag_denominator    , 0L) +
      dplyr::coalesce(statin_denominator      , 0L) +
      dplyr::coalesce(smoking_denominator     , 0L),
  ) %>%
  tidyr::pivot_longer(
    cols            = tidyselect::matches(pattern),
    names_to        = c("metric", ".value"),
    names_pattern   = pattern
  ) %>%
  # dplyr::filter(metric != "cumulative") %>%
  dplyr::mutate(
    post        = dplyr::recode(phase, "pre" = 0L, "post" = 1L),
    phase       = factor(phase, levels = c("pre", "post")),
    metric      = factor(metric, levels = levels_metric),
    proportion  = numerator     / denominator,
    label       = dplyr::if_else(
      denominator == 0L,
      sprintf("  --%% of %2i"                   , denominator),
      sprintf("%4.0f%% of %2i", proportion * 100, denominator)
      # sprintf("  --%% (%2i of %2i)"                   , numerator, denominator),
      # sprintf("%4.0f%% (%2i of %2i)", proportion * 100, numerator, denominator)
    ),
  )


  # dplyr::mutate(
  #   stroke_proportion     = stroke_numerator     / stroke_denominator     ,
  #   antithromb_proportion = antithromb_numerator / antithromb_denominator ,
  #   anticoag_proportion   = anticoag_numerator   / anticoag_denominator   ,
  #   statin_proportion     = statin_numerator     / statin_denominator     ,
  #   smoking_proportion    = smoking_numerator    / smoking_denominator    ,
  #   cumulative_proportion = cumulative_numerator / cumulative_denominator ,
  # ) %>%
  # dplyr::mutate(
  #   stroke_label     = sprintf("%4.0f%% (%2i of %2i)", stroke_proportion     * 100, stroke_numerator     , stroke_denominator     ),
  #   antithromb_label = sprintf("%4.0f%% (%2i of %2i)", antithromb_proportion * 100, antithromb_numerator , antithromb_denominator ),
  #   anticoag_label   = sprintf("%4.0f%% (%2i of %2i)", anticoag_proportion   * 100, anticoag_numerator   , anticoag_denominator   ),
  #   statin_label     = sprintf("%4.0f%% (%2i of %2i)", statin_proportion     * 100, statin_numerator     , statin_denominator     ),
  #   smoking_label    = sprintf("%4.0f%% (%2i of %2i)", smoking_proportion    * 100, smoking_numerator    , smoking_denominator    ),
  #   cumulative_label = sprintf("%4.0f%% (%2i of %2i)", cumulative_proportion * 100, cumulative_numerator , cumulative_denominator ),
  # )

# ---- marginals ---------------------------------------------------------------
# # Inspect continuous variables
# histogram_continuous(d_observed=ds, variable_name="quarter_mile_sec", bin_width=.5, rounded_digits=1)
# # slightly better function: TabularManifest::histogram_continuous(d_observed=ds, variable_name="quarter_mile_sec", bin_width=.5, rounded_digits=1)
# histogram_continuous(d_observed=ds, variable_name="displacement_inches_cubed", bin_width=50, rounded_digits=1)
#
# # Inspect discrete/categorical variables
# histogram_discrete(d_observed=ds, variable_name="carburetor_count_f")
# histogram_discrete(d_observed=ds, variable_name="forward_gear_count_f")


# ---- scatterplots ------------------------------------------------------------
x_breaks  <- ds$month

g1 <-
  ds %>%
  # dplyr::filter(metric == "statin") %>%
  # dplyr::filter(metric == "smoking") %>%
  ggplot(aes(x=month, y=proportion, size=denominator, group=metric, label=label, color =phase)) +
  geom_text(aes(y = -Inf, size=10), alpha = .6, angle = 90, hjust = 0, family = "mono") +
  geom_vline(xintercept = config$intervention_start, size = 4, color = "gray80", alpha = .4) +
  annotate("text", label = "intervention starts", x = config$intervention_start, y = .5, hjust = .5, angle = 90, alpha = .4) +
  geom_line(data=ds[!is.na(ds$proportion), ], size=.5, color = "gray70", inherit.aes = TRUE) +
  geom_point(aes(fill = phase), shape=21, alpha = .5, na.rm = T) +
  scale_x_date(breaks = x_breaks, date_labels = "%b\n%Y") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_color_manual(values = palette_dark, guide = "none") +
  scale_fill_manual(values = palette_light, guide = "none") +
  scale_size(guide = "none") +
  coord_cartesian(ylim = c(0, 1)) +
  facet_wrap("metric", ncol = 2) +
  theme_light() +
  theme(axis.ticks = element_blank()) +
  labs(x = NULL, y = "Percent Completed")
g1


# ---- models ------------------------------------------------------------------
m1 <- lm(proportion ~ 1 + post, data = ds, subset = (metric != "cumulative"))
summary(m1)

m2 <- glm(
  numerator / denominator ~ 1 + post,
  family  = quasipoisson,
  # subset = (metric == "statin")
  subset = (metric != "cumulative"),
  data    = ds,
)
summary(m2)


# ---- model-results-table  -----------------------------------------------
summary(m2)$coef %>%
  knitr::kable(
    digits      = 2,
    format      = "markdown"
  )

# Uncomment the next line for a dynamic, JavaScript [DataTables](https://datatables.net/) table.
# DT::datatable(round(summary(m2)$coef, digits = 2), options = list(pageLength = 2))
