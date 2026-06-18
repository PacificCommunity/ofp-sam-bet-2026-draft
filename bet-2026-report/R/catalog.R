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

catalog_columns <- function(type = c("figures", "tables")) {
  type <- match.arg(type)
  if (identical(type, "figures")) {
    return(c("key", "section", "title", "file_candidates", "caption", "todo"))
  }
  c("key", "section", "title", "file_candidates", "caption", "todo")
}

complete_catalog <- function(catalog, type = c("figures", "tables")) {
  type <- match.arg(type)
  needed <- catalog_columns(type)
  for (name in setdiff(needed, names(catalog))) {
    catalog[[name]] <- ""
  }
  catalog
}
