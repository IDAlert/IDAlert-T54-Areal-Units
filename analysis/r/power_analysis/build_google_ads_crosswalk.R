# Crosswalk between Spanish municipalities (GADM level 4) and Google Ads
# geo targets, to establish how many municipalities can actually be targeted.
#
# Input: the Google Ads geo target CSV, published at
#   https://developers.google.com/google-ads/api/data/geotargets
# (a dated file, e.g. geotargets-2026-07-16.csv). Pass its path as argument 1.
#
# Output:
#   output/google_ads_spain_municipality_crosswalk.csv  matched + unmatched
#   output/google_ads_spain_targetable.csv              ready-to-use target list
#
# Usage: Rscript build_google_ads_crosswalk.R <geotargets.csv>

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(geodata)
})

.data <- rlang::.data
output_dir <- file.path("analysis", "r", "power_analysis", "output")

# Accents are stripped with chartr rather than iconv: on macOS
# iconv(..., "ASCII//TRANSLIT") renders "Cataluña" as "Catalu~na" and "Málaga"
# as "M'alaga", which silently breaks matching (it cost Barcelona, Valencia and
# every Catalan municipality a match on the first pass).
accented <- "áàâäãåéèêëíìîïóòôöõúùûüñçÁÀÂÄÃÅÉÈÊËÍÌÎÏÓÒÔÖÕÚÙÛÜÑÇ"
unaccented <- "aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC"

normalize_name <- function(x) {
  x <- as.character(x)
  x <- sub("^Municipality of ", "", x)
  x <- chartr(accented, unaccented, x)
  x <- tolower(x)
  x <- gsub("['`’]", "", x)
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

# Google uses an English exonym for Seville and the co-official Catalan or
# Valencian form for several places where GADM carries the Castilian one. This
# list is not exhaustive -- check the highest-volume unmatched municipalities in
# the crosswalk output and extend it as needed.
name_alias <- c(
  "sevilla" = "seville",
  "elche" = "elx",
  "sagunto" = "sagunt",
  "palma de mallorca" = "palma",
  "castellon de la plana" = "castello de la plana"
)

build_crosswalk <- function(geotargets_csv) {
  geo <- read.csv(geotargets_csv, colClasses = "character")
  names(geo) <- gsub("[^A-Za-z]", "_", names(geo))

  spain <- geo[geo$Country_Code == "ES" &
                 geo$Target_Type %in% c("Municipality", "City") &
                 geo$Status == "Active", ]

  # Canonical Name is "Name,Autonomous Community,Spain"
  spain$autonomous_community <- vapply(strsplit(spain$Canonical_Name, ","),
                                       function(parts) {
                                         if (length(parts) >= 3) parts[length(parts) - 1] else NA_character_
                                       }, character(1))
  spain$name_key <- normalize_name(spain$Name)
  spain$community_key <- normalize_name(spain$autonomous_community)

  message("Loading GADM municipalities")
  admin <- geodata::gadm(country = "ESP", level = 4, path = file.path("data", "raw"))
  municipalities <- sf::st_as_sf(admin) %>%
    sf::st_drop_geometry() %>%
    filter(.data$TYPE_4 == "Municipality") %>%
    transmute(
      unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", "),
      municipality = .data$NAME_4,
      province = .data$NAME_2,
      autonomous_community = .data$NAME_1
    )

  # Google uses English exonyms for several autonomous communities.
  community_alias <- c(
    "comunidad de madrid" = "community of madrid",
    "comunidad valenciana" = "valencian community",
    "cataluna" = "catalonia",
    "pais vasco" = "basque country",
    "andalucia" = "andalusia",
    "aragon" = "aragon",
    "castilla la mancha" = "castile la mancha",
    "castilla y leon" = "castile and leon",
    "islas baleares" = "balearic islands",
    "islas canarias" = "canary islands",
    "navarra" = "navarre",
    "region de murcia" = "region of murcia",
    "principado de asturias" = "asturias",
    "ceuta y melilla" = "ceuta"
  )

  # GADM stores some municipalities as several rows; collapse first so the
  # match cannot fan out.
  municipalities <- municipalities[!duplicated(municipalities$unit_name), ]

  raw_name <- normalize_name(municipalities$municipality)
  municipalities$name_key <- ifelse(raw_name %in% names(name_alias),
                                    name_alias[raw_name], raw_name)
  raw_community <- normalize_name(municipalities$autonomous_community)
  municipalities$community_key <- ifelse(
    raw_community %in% names(community_alias),
    community_alias[raw_community], raw_community)

  # One municipality can legitimately match several Google targets -- typically
  # a "City" entry and a "Municipality of X" entry for the same place. That is
  # a choice to be made, not an ambiguity to discard. Prefer the Municipality
  # type, whose footprint follows the administrative boundary, over City, whose
  # footprint is the urban area.
  choose_target <- function(candidates) {
    if (nrow(candidates) == 1) return(candidates)
    preference <- order(match(candidates$Target_Type, c("Municipality", "City")),
                        nchar(candidates$Canonical_Name))
    candidates[preference[1], , drop = FALSE]
  }

  # `which()` rather than logical subsetting: a few Google canonical names have
  # too few components to yield an autonomous community, so community_key can be
  # NA, and logical subsetting would return a phantom all-NA row that looks like
  # a successful match.
  match_one <- function(name_key, community_key) {
    candidates <- spain[which(spain$name_key == name_key &
                                spain$community_key == community_key), ,
                        drop = FALSE]
    quality <- "name+community"
    if (nrow(candidates) == 0) {
      candidates <- spain[which(spain$name_key == name_key), , drop = FALSE]
      quality <- "name only"
    }
    if (nrow(candidates) == 0) {
      return(data.frame(Criteria_ID = NA_character_, Name = NA_character_,
                        Canonical_Name = NA_character_,
                        Target_Type = NA_character_,
                        match_type = "unmatched"))
    }
    chosen <- choose_target(candidates)
    data.frame(Criteria_ID = chosen$Criteria_ID, Name = chosen$Name,
               Canonical_Name = chosen$Canonical_Name,
               Target_Type = chosen$Target_Type, match_type = quality)
  }

  matches <- do.call(rbind, Map(match_one, municipalities$name_key,
                                municipalities$community_key))
  with_community <- cbind(municipalities, matches)

  # A "name only" match is only trustworthy when the name is nationally unique;
  # otherwise we would be assigning some other province's town.
  name_counts <- table(spain$name_key)
  unsafe <- with_community$match_type == "name only" &
    name_counts[with_community$name_key] > 1
  unsafe[is.na(unsafe)] <- FALSE
  with_community$match_type[unsafe] <- "ambiguous"
  with_community$Criteria_ID[unsafe] <- NA_character_

  result <- with_community %>%
    transmute(
      unit_name = .data$unit_name,
      municipality = .data$municipality,
      province = .data$province,
      autonomous_community = .data$autonomous_community,
      google_criteria_id = .data$Criteria_ID,
      google_name = .data$Name,
      google_canonical_name = .data$Canonical_Name,
      google_target_type = .data$Target_Type,
      match_type = .data$match_type
    ) %>%
    arrange(.data$unit_name)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  write.csv(result, file.path(output_dir,
                              "google_ads_spain_municipality_crosswalk.csv"),
            row.names = FALSE)

  targetable <- result[result$match_type %in% c("name+community", "name only"), ]
  write.csv(targetable[, c("unit_name", "province", "google_criteria_id",
                           "google_name", "google_canonical_name",
                           "google_target_type")],
            file.path(output_dir, "google_ads_spain_targetable.csv"),
            row.names = FALSE)

  list(
    crosswalk = result,
    targetable = targetable,
    n_gadm = nrow(municipalities),
    n_google_spain = nrow(spain)
  )
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) stop("Usage: Rscript build_google_ads_crosswalk.R <geotargets.csv>")

  results <- build_crosswalk(args[[1]])
  cat("GADM municipalities:", results$n_gadm, "\n")
  cat("Google Ads Spain City+Municipality targets:", results$n_google_spain, "\n\n")
  print(table(results$crosswalk$match_type))
  cat("\nTargetable municipalities:", nrow(results$targetable), "\n")
  print(table(results$targetable$google_target_type))
}
