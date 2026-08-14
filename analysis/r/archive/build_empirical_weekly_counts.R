suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(sf)
  library(geodata)
  library(giscoR)
  library(terra)
})

.data <- rlang::.data

android_start_date <- as.Date("2014-06-14")
ios_start_date <- as.Date("2014-06-24")

prepare_report_points <- function(raw_path) {
  reports <- readRDS(raw_path) %>%
    mutate(
      lon = dplyr::case_when(
        .data$location_choice == "selected" ~ .data$selected_location_lon,
        TRUE ~ .data$current_location_lon
      ),
      lat = dplyr::case_when(
        .data$location_choice == "selected" ~ .data$selected_location_lat,
        TRUE ~ .data$current_location_lat
      ),
      date = as.Date(.data$creation_time),
      report_type = .data$type,
      os = dplyr::case_when(
        .data$os == "Android" ~ "Android",
        .data$os %in% c("iOS", "iPhone OS", "iPadOS") ~ "iOS",
        TRUE ~ as.character(.data$os)
      )
    ) %>%
    filter(
      !is.na(.data$lon),
      !is.na(.data$lat),
      .data$report_type != "mission",
      !is.na(.data$date),
      .data$date <= Sys.Date(),
      ((.data$date >= android_start_date & .data$os == "Android") |
         (.data$date >= ios_start_date & .data$os == "iOS"))
    )

  st_as_sf(reports, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
}

make_date_suffix <- function(min_date = NULL, max_date = NULL) {
  if (is.null(min_date) && is.null(max_date)) {
    return("")
  }

  parts <- c()

  if (!is.null(min_date)) {
    parts <- c(parts, format(as.Date(min_date), "%Y%m%d"))
  }

  if (!is.null(max_date)) {
    parts <- c(parts, format(as.Date(max_date), "%Y%m%d"))
  }

  paste0("_", paste(parts, collapse = "_to_"))
}

download_admin_units <- function(country_code, level, path) {
  geodata::gadm(country = country_code, level = level, path = path)
}

get_spain_provinces <- function(path) {
  spain_admin <- download_admin_units("ESP", level = 2, path = path)
  sf::st_as_sf(spain_admin) %>%
    filter(.data$TYPE_2 == "Provincia") %>%
    transmute(unit_name = .data$NAME_2)
}

get_germany_states <- function(path) {
  germany_admin <- download_admin_units("DEU", level = 1, path = path)
  sf::st_as_sf(germany_admin) %>%
    transmute(unit_name = .data$NAME_1)
}

get_netherlands_provinces <- function(path) {
  netherlands_admin <- download_admin_units("NLD", level = 1, path = path)
  sf::st_as_sf(netherlands_admin) %>%
    filter(.data$TYPE_1 == "Provincie") %>%
    transmute(unit_name = .data$NAME_1)
}

get_spain_municipalities <- function(path) {
  spain_admin <- download_admin_units("ESP", level = 4, path = path)
  sf::st_as_sf(spain_admin) %>%
    filter(.data$TYPE_4 == "Municipality") %>%
    transmute(
      unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", "),
      admin_name = .data$NAME_4
    )
}

get_greece_proxy_units <- function() {
  giscoR::gisco_get_nuts(nuts_level = 3, year = "2021", epsg = "4326") %>%
    filter(.data$CNTR_CODE == "EL") %>%
    transmute(unit_name = .data$NAME_LATN)
}

get_greece_municipalities <- function(path) {
  greece_admin <- download_admin_units("GRC", level = 3, path = path)
  sf::st_as_sf(greece_admin) %>%
    filter(.data$TYPE_3 == "Dímos") %>%
    transmute(
      unit_name = paste(.data$NAME_3, .data$NAME_2, sep = ", "),
      admin_name = .data$NAME_3
    )
}

extract_country_unit_counts <- function(points_sf, admin_sf, country_label, unit_label) {
  admin_sf <- sf::st_as_sf(admin_sf) %>%
    mutate(unit_name = .data[[unit_label]]) %>%
    select("unit_name")

  joined <- sf::st_join(points_sf, admin_sf, join = sf::st_within, left = FALSE)

  joined %>%
    st_drop_geometry() %>%
    mutate(
      country = country_label,
      week_start = floor_date(.data$date, unit = "week", week_start = 1)
    ) %>%
    count(.data$country, .data$unit_name, .data$week_start, name = "weekly_count")
}

extract_country_unit_counts_pre_named <- function(points_sf, admin_sf, country_label) {
  admin_sf <- sf::st_as_sf(admin_sf) %>%
    select("unit_name")

  joined <- sf::st_join(points_sf, admin_sf, join = sf::st_within, left = FALSE)

  joined %>%
    st_drop_geometry() %>%
    mutate(
      country = country_label,
      week_start = floor_date(.data$date, unit = "week", week_start = 1)
    ) %>%
    count(.data$country, .data$unit_name, .data$week_start, name = "weekly_count")
}

complete_unit_weeks <- function(weekly_counts, all_units) {
  full_weeks <- seq(min(weekly_counts$week_start), max(weekly_counts$week_start), by = "7 days")

  merge(
    all_units,
    data.frame(week_start = full_weeks),
    by = NULL
  ) %>%
    dplyr::left_join(weekly_counts, by = c("country", "unit_name", "week_start")) %>%
    mutate(weekly_count = ifelse(is.na(.data$weekly_count), 0L, .data$weekly_count))
}

build_empirical_counts <- function(
  raw_path = file.path("data", "raw", "mosquito_alert_raw_reports.Rds"),
  boundary_path = file.path("data", "raw"),
  output_dir = file.path("analysis", "r", "power_analysis", "output"),
  unit_level = c("province", "municipality"),
  countries = c("Spain", "Greece"),
  min_report_date = NULL,
  max_report_date = NULL
) {
  unit_level <- match.arg(unit_level)
  countries <- unique(countries)
  date_suffix <- make_date_suffix(min_report_date, max_report_date)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  message("Reading raw reports")
  points_sf <- prepare_report_points(raw_path)

  if (!is.null(min_report_date)) {
    points_sf <- points_sf[points_sf$date >= as.Date(min_report_date), ]
  }

  if (!is.null(max_report_date)) {
    points_sf <- points_sf[points_sf$date <= as.Date(max_report_date), ]
  }

  if (nrow(points_sf) == 0) {
    stop("No reports remain after applying the requested date filter")
  }

  if (identical(unit_level, "municipality")) {
    message("Downloading or loading Spain municipalities")
    spain_admin <- get_spain_municipalities(boundary_path)

    message("Downloading or loading Greece municipalities")
    greece_admin <- get_greece_municipalities(boundary_path)

    message("Extracting Spain municipality counts")
    spain_points <- points_sf[points_sf$lon >= -25 & points_sf$lon <= 10 & points_sf$lat >= 27 & points_sf$lat <= 45, ]
    spain_counts <- extract_country_unit_counts_pre_named(spain_points, spain_admin, "Spain")

    message("Extracting Greece municipality counts")
    greece_points <- points_sf[points_sf$lon >= 19 & points_sf$lon <= 30 & points_sf$lat >= 34 & points_sf$lat <= 42, ]
    greece_counts <- extract_country_unit_counts_pre_named(greece_points, greece_admin, "Greece")

    weekly_counts_filename <- paste0("empirical_weekly_counts_municipality", date_suffix, ".csv")
    unit_baselines_filename <- paste0("empirical_unit_baselines_municipality", date_suffix, ".csv")
    spain_source <- "GADM municipality"
    greece_source <- "GADM municipality"
  } else {
    country_configs <- list(
      Spain = list(
        admin_loader = get_spain_provinces,
        source = "GADM province",
        xmin = -25,
        xmax = 10,
        ymin = 27,
        ymax = 45
      ),
      Greece = list(
        admin_loader = function(path) get_greece_proxy_units(),
        source = "GISCO NUTS3 proxy for Greek regional units",
        xmin = 19,
        xmax = 30,
        ymin = 34,
        ymax = 42
      ),
      Germany = list(
        admin_loader = get_germany_states,
        source = "GADM state",
        xmin = 5,
        xmax = 16,
        ymin = 47,
        ymax = 56
      ),
      Netherlands = list(
        admin_loader = get_netherlands_provinces,
        source = "GADM province",
        xmin = 3,
        xmax = 8,
        ymin = 50,
        ymax = 54
      )
    )

    unsupported_countries <- setdiff(countries, names(country_configs))
    if (length(unsupported_countries) > 0) {
      stop("Unsupported countries for province level: ", paste(unsupported_countries, collapse = ", "))
    }

    country_results <- lapply(countries, function(country_name) {
      cfg <- country_configs[[country_name]]
      message("Loading ", country_name, " province-level units")
      admin_sf <- cfg$admin_loader(boundary_path)
      points_subset <- points_sf[
        points_sf$lon >= cfg$xmin & points_sf$lon <= cfg$xmax &
          points_sf$lat >= cfg$ymin & points_sf$lat <= cfg$ymax,
      ]
      message("Extracting ", country_name, " province-level counts")
      counts <- extract_country_unit_counts_pre_named(points_subset, admin_sf, country_name)

      list(
        country = country_name,
        admin = admin_sf,
        counts = counts,
        source = cfg$source
      )
    })

    names(country_results) <- countries

    weekly_counts_filename <- if (identical(sort(countries), sort(c("Spain", "Greece")))) {
      paste0("empirical_weekly_counts", date_suffix, ".csv")
    } else {
      paste0(
        "empirical_weekly_counts_",
        paste(tolower(gsub("[^A-Za-z0-9]+", "_", countries)), collapse = "_"),
        date_suffix,
        ".csv"
      )
    }

    unit_baselines_filename <- if (identical(sort(countries), sort(c("Spain", "Greece")))) {
      paste0("empirical_unit_baselines", date_suffix, ".csv")
    } else {
      paste0(
        "empirical_unit_baselines_",
        paste(tolower(gsub("[^A-Za-z0-9]+", "_", countries)), collapse = "_"),
        date_suffix,
        ".csv"
      )
    }
  }

  if (identical(unit_level, "municipality")) {
    weekly_counts <- bind_rows(spain_counts, greece_counts)

    all_units <- bind_rows(
      data.frame(country = "Spain", unit_name = unique(spain_admin$unit_name)),
      data.frame(country = "Greece", unit_name = unique(greece_admin$unit_name))
    )

    unit_source_lookup <- data.frame(
      country = c("Spain", "Greece"),
      unit_source = c(spain_source, greece_source)
    )
  } else {
    weekly_counts <- bind_rows(lapply(country_results, function(entry) entry$counts))
    all_units <- bind_rows(lapply(country_results, function(entry) {
      data.frame(country = entry$country, unit_name = unique(entry$admin$unit_name))
    }))
    unit_source_lookup <- bind_rows(lapply(country_results, function(entry) {
      data.frame(country = entry$country, unit_source = entry$source)
    }))
  }

  weekly_counts_complete <- complete_unit_weeks(weekly_counts, all_units)

  unit_baselines <- weekly_counts_complete %>%
    group_by(.data$country, .data$unit_name) %>%
    summarize(
      baseline_mean = mean(.data$weekly_count, na.rm = TRUE),
      baseline_sd = sd(.data$weekly_count, na.rm = TRUE),
      nonzero_share = mean(.data$weekly_count > 0, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(.data$country) %>%
    mutate(
      unit_id = paste0(
        dplyr::recode(
          .data$country,
          Spain = "ES",
          Greece = "GR",
          Germany = "DE",
          Netherlands = "NL"
        ),
        "_",
        row_number()
      )
    ) %>%
    ungroup() %>%
    left_join(unit_source_lookup, by = "country") %>%
    select("country", "unit_id", "unit_name", "unit_source", "baseline_mean", "baseline_sd", "nonzero_share")

  write.csv(weekly_counts_complete, file.path(output_dir, weekly_counts_filename), row.names = FALSE)
  write.csv(unit_baselines, file.path(output_dir, unit_baselines_filename), row.names = FALSE)

  list(
    weekly_counts = weekly_counts_complete,
    unit_baselines = unit_baselines,
    unit_level = unit_level,
    weekly_counts_path = file.path(output_dir, weekly_counts_filename),
    unit_baselines_path = file.path(output_dir, unit_baselines_filename)
  )
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  unit_level <- if (length(args) >= 1) args[[1]] else "province"

  results <- build_empirical_counts(unit_level = unit_level)
  cat("Empirical unit counts built for", results$unit_level, "level.\n")
  print(table(results$unit_baselines$country))
  cat("Weekly counts file:", results$weekly_counts_path, "\n")
  cat("Unit baseline file:", results$unit_baselines_path, "\n")
  print(head(results$unit_baselines))
}