catalog_file <- function(name) {
  if (identical(name, "figures")) {
    return(get0("figure_catalog", ifnotfound = file.path("catalog", "figures.csv")))
  }
  if (identical(name, "tables")) {
    return(get0("table_catalog", ifnotfound = file.path("catalog", "tables.csv")))
  }
  file.path("catalog", paste0(name, ".csv"))
}

read_catalog <- function(name) {
  read_report_csv(catalog_file(name))
}

figure_curation_file <- function() {
  get0("figure_curation", ifnotfound = file.path("catalog", "figure-curation.csv"))
}

figure_curation_columns <- function() {
  c("target_type", "target", "placement", "section", "title", "caption_override", "order", "notes")
}

read_figure_curation <- function(path = figure_curation_file()) {
  curation <- read_report_csv(path)
  needed <- figure_curation_columns()
  for (name in setdiff(needed, names(curation))) {
    curation[[name]] <- ""
  }
  curation[, needed, drop = FALSE]
}

catalog_columns <- function(type = c("figures", "tables")) {
  type <- match.arg(type)
  if (identical(type, "figures")) {
    return(c("key", "placement", "section", "title", "file_candidates", "caption", "caption_override", "todo", "notes"))
  }
  c("key", "placement", "section", "title", "file_candidates", "caption", "todo", "notes")
}

complete_catalog <- function(catalog, type = c("figures", "tables")) {
  type <- match.arg(type)
  needed <- catalog_columns(type)
  for (name in setdiff(needed, names(catalog))) {
    catalog[[name]] <- ""
  }
  catalog
}
