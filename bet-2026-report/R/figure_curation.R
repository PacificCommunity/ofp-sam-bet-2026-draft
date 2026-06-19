`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x

source("R/report_helpers.R")
source("R/config.R")
source("R/catalog.R")
load_report_context("report-config.yml")

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) tolower(args[[1]]) else "review"
if (!mode %in% c("review", "build")) {
  stop("Unknown figure curation mode: ", mode, call. = FALSE)
}

curation_dir <- file.path("curation")
dir.create(curation_dir, recursive = TRUE, showWarnings = FALSE)

relative_from_report <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root), "/?"), "", path)
}

html_src_from_curation <- function(path) {
  if (!nzchar(path) || !file.exists(path)) return("")
  paste0("../", markdown_path(relative_from_report(path)))
}

figure_files_in_roots <- function(roots) {
  roots <- roots[dir.exists(roots)]
  if (!length(roots)) return(character())
  sort(unique(unlist(lapply(roots, function(root) {
    list.files(root, pattern = "[.](png|jpg|jpeg|pdf|svg)$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  }), use.names = FALSE)))
}

curation_row_for_key <- function(curation, key, candidates) {
  matches <- figure_curation_matches_key(curation, key, candidates)
  if (nrow(matches)) matches[nrow(matches), , drop = FALSE] else matches
}

curation_row_for_file <- function(curation, file) {
  matches <- figure_curation_matches_file(curation, file)
  if (nrow(matches)) matches[nrow(matches), , drop = FALSE] else matches
}

row_value <- function(row, name, default = "") {
  if (!is.data.frame(row) || !nrow(row) || !name %in% names(row)) return(default)
  value <- clean_text(row[[name]][[1]])
  if (nzchar(value)) value else default
}

catalog_figure_rows <- function(catalog, curation, roots, metadata) {
  catalog <- apply_figure_curation(catalog, curation)
  if (!nrow(catalog)) return(data.frame(stringsAsFactors = FALSE))
  rows <- list()
  for (i in seq_len(nrow(catalog))) {
    key <- clean_text(catalog$key[[i]])
    files <- find_report_assets(catalog$file_candidates[[i]], roots = roots)
    placement <- normalize_figure_placement(catalog$placement[[i]], default = "main")
    title <- render_report_text(catalog$title[[i]])
    section <- render_report_text(catalog$section[[i]])
    caption_override <- render_report_text(catalog$caption_override[[i]])
    caption_default <- render_report_text(catalog$caption[[i]])
    if (!length(files)) {
      rows[[length(rows) + 1L]] <- data.frame(
        target_type = "key",
        target = key,
        placement = placement,
        section = section,
        title = title,
        caption_override = caption_override,
        order = "",
        notes = clean_text(catalog$notes[[i]]),
        status = "missing",
        file = "",
        current_caption = polish_report_caption(caption_default),
        source = "catalog",
        stringsAsFactors = FALSE
      )
      next
    }
    for (file in files) {
      rows[[length(rows) + 1L]] <- data.frame(
        target_type = "key",
        target = key,
        placement = placement,
        section = section,
        title = title,
        caption_override = caption_override,
        order = "",
        notes = clean_text(catalog$notes[[i]]),
        status = if (placement == "exclude") "excluded" else "included",
        file = relative_from_report(file),
        current_caption = figure_caption(file, caption_default, metadata, override = caption_override),
        source = "catalog",
        stringsAsFactors = FALSE
      )
    }
  }
  bind_report_rows(rows)
}

extra_figure_rows <- function(files, catalog, curation, metadata) {
  catalog_tokens <- catalog_all_candidate_tokens(catalog)
  rows <- list()
  for (file in files) {
    file_tokens <- file_match_tokens(file)
    if (any(file_tokens %in% catalog_tokens) || is_default_excluded_figure(file)) {
      next
    }
    match <- curation_row_for_file(curation, file)
    placement <- if (nrow(match)) normalize_figure_placement(match$placement[[1]], default = "appendix") else "appendix"
    if (placement == "exclude") {
      status <- "excluded"
    } else if (placement == "main") {
      status <- "included"
    } else {
      status <- "appendix"
    }
    title <- row_value(match, "title")
    if (!nzchar(title)) {
      title <- gsub("[-_]+", " ", tools::file_path_sans_ext(basename(file)))
      title <- paste0(toupper(substr(title, 1, 1)), substr(title, 2, nchar(title)))
    }
    section <- row_value(match, "section", if (placement == "main") "Curated generated figures" else "Supplemental generated figures")
    caption_override <- row_value(match, "caption_override")
    rows[[length(rows) + 1L]] <- data.frame(
      target_type = "file",
      target = basename(file),
      placement = placement,
      section = section,
      title = title,
      caption_override = caption_override,
      order = row_value(match, "order"),
      notes = row_value(match, "notes"),
      status = status,
      file = relative_from_report(file),
      current_caption = figure_caption(file, title, metadata, override = caption_override),
      source = if (nrow(match)) "curation" else "generated",
      stringsAsFactors = FALSE
    )
  }
  bind_report_rows(rows)
}

write_review_html <- function(rows, path) {
  rows <- rows[order(match(rows$placement, c("main", "appendix", "exclude")), rows$section, rows$title, rows$target), , drop = FALSE]
  counts <- table(factor(rows$placement, levels = c("main", "appendix", "exclude")))
  card_html <- vapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    file <- clean_text(row$file[[1]])
    src <- if (nzchar(file)) html_src_from_curation(file) else ""
    preview <- if (nzchar(src) && grepl("[.](png|jpg|jpeg|svg)$", file, ignore.case = TRUE)) {
      sprintf('<img src="%s" alt="">', html_escape(src))
    } else if (nzchar(src)) {
      sprintf('<a class="file-link" href="%s">Open file</a>', html_escape(src))
    } else {
      '<span class="missing">Missing file</span>'
    }
    sprintf(
      '<article class="card" data-placement="%s" data-search="%s"><div class="preview">%s</div><div class="meta"><span class="pill %s">%s</span><span>%s</span></div><h2>%s</h2><p class="target">%s: %s</p><p class="caption">%s</p><p class="notes">%s</p></article>',
      html_escape(row$placement[[1]]),
      html_escape(paste(row$section, row$title, row$target, row$file, row$current_caption, row$notes, collapse = " ")),
      preview,
      html_escape(row$placement[[1]]),
      html_escape(row$placement[[1]]),
      html_escape(row$section[[1]]),
      html_escape(row$title[[1]]),
      html_escape(row$target_type[[1]]),
      html_escape(row$target[[1]]),
      html_escape(row$current_caption[[1]]),
      html_escape(row$notes[[1]])
    )
  }, character(1))
  html <- c(
    "<!doctype html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    "<title>BET 2026 Figure Curation</title>",
    "<style>",
    "body{margin:0;font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f4f8fb;color:#143044}",
    ".shell{max-width:1440px;margin:0 auto;padding:28px}",
    "header{display:flex;gap:18px;align-items:flex-end;justify-content:space-between;margin-bottom:18px}",
    "h1{font-size:34px;line-height:1.05;margin:0}.sub{margin:8px 0 0;color:#5c7182;font-weight:650}",
    ".toolbar{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:18px 0}.toolbar input{min-width:280px;flex:1;padding:12px 14px;border:1px solid #c9d9e4;border-radius:10px;background:white;font:inherit}",
    ".filter{border:1px solid #c9d9e4;background:white;border-radius:999px;padding:10px 13px;font-weight:800;color:#24465d;cursor:pointer}.filter.is-active{background:#143044;color:white;border-color:#143044}",
    ".summary{display:flex;gap:10px;flex-wrap:wrap}.stat{background:white;border:1px solid #d5e2ea;border-radius:10px;padding:10px 13px;font-weight:850}.stat small{display:block;color:#6b7f8d;font-weight:750}",
    ".grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:14px}.card{background:white;border:1px solid #d5e2ea;border-radius:10px;box-shadow:0 8px 22px rgba(33,70,92,.07);overflow:hidden}.card[hidden]{display:none}",
    ".preview{height:210px;background:#e9f1f6;display:flex;align-items:center;justify-content:center;border-bottom:1px solid #d5e2ea}.preview img{max-width:100%;max-height:100%;object-fit:contain}.missing,.file-link{font-weight:850;color:#60788b}",
    ".meta{display:flex;align-items:center;justify-content:space-between;gap:10px;margin:12px 14px 0;color:#60788b;font-size:13px;font-weight:800}.pill{border-radius:999px;padding:5px 9px;text-transform:uppercase;font-size:11px;letter-spacing:.04em}.pill.main{background:#e5f6ee;color:#19754e}.pill.appendix{background:#eef4ff;color:#2a5fa6}.pill.exclude{background:#fff0e9;color:#a04722}",
    "h2{font-size:18px;line-height:1.2;margin:10px 14px 6px}.target{margin:0 14px 10px;color:#597082;font-weight:750}.caption{margin:0 14px 12px;line-height:1.45}.notes{margin:0 14px 16px;color:#7c5b22;font-weight:700}",
    ".guide{background:#eaf5fb;border:1px solid #cbe0ec;border-radius:12px;padding:14px 16px;margin:0 0 18px;color:#24465d}.guide code{background:white;border:1px solid #d4e2eb;border-radius:6px;padding:1px 5px}",
    "</style>",
    "</head>",
    "<body>",
    '<main class="shell">',
    "<header><div><h1>Figure curation</h1><p class=\"sub\">Review generated figures, then edit <code>catalog/figure-curation.csv</code> to set placement or caption overrides.</p></div>",
    sprintf('<div class="summary"><div class="stat">%s<small>Main</small></div><div class="stat">%s<small>Appendix</small></div><div class="stat">%s<small>Excluded</small></div></div>', counts[["main"]] %||% 0, counts[["appendix"]] %||% 0, counts[["exclude"]] %||% 0),
    "</header>",
    '<section class="guide">Use <code>target_type=key</code> with a catalog key to move an existing report slot. Use <code>target_type=file</code> with a generated filename to promote an uncatalogued figure, send it to the appendix, exclude it, or override its caption.</section>',
    '<div class="toolbar"><input id="search" type="search" placeholder="Search title, file, section, caption..."><button class="filter is-active" data-filter="all">All</button><button class="filter" data-filter="main">Main</button><button class="filter" data-filter="appendix">Appendix</button><button class="filter" data-filter="exclude">Excluded</button></div>',
    '<section class="grid" id="grid">',
    card_html,
    "</section>",
    "</main>",
    "<script>",
    "const search=document.querySelector('#search');const buttons=[...document.querySelectorAll('.filter')];const cards=[...document.querySelectorAll('.card')];let active='all';function sync(){const q=(search.value||'').toLowerCase().trim();cards.forEach(card=>{const okFilter=active==='all'||card.dataset.placement===active;const okSearch=!q||(card.dataset.search||'').toLowerCase().includes(q);card.hidden=!(okFilter&&okSearch);});}buttons.forEach(btn=>btn.addEventListener('click',()=>{active=btn.dataset.filter;buttons.forEach(b=>b.classList.toggle('is-active',b===btn));sync();}));search.addEventListener('input',sync);",
    "</script>",
    "</body></html>"
  )
  writeLines(html, path)
}

catalog <- read_catalog("figures")
curation <- read_figure_curation()
roots <- unique(c(
  report_paths("figure_roots", c("Figures/generated", "Figures/static", "Figures")),
  report_paths("extra_figure_roots", c("Figures/generated"))
))
metadata <- read_figure_metadata(roots)
files <- figure_files_in_roots(roots)
rows <- bind_report_rows(list(
  catalog_figure_rows(catalog, curation, roots, metadata),
  extra_figure_rows(files, catalog, curation, metadata)
))

if (!nrow(rows)) {
  rows <- data.frame(
    target_type = character(),
    target = character(),
    placement = character(),
    section = character(),
    title = character(),
    caption_override = character(),
    order = character(),
    notes = character(),
    status = character(),
    file = character(),
    current_caption = character(),
    source = character(),
    stringsAsFactors = FALSE
  )
}

utils::write.csv(rows, file.path(curation_dir, "figure-curation-template.csv"), row.names = FALSE)
write_review_html(rows, file.path(curation_dir, "figure-curation-review.html"))
message("Wrote figure curation review: ", file.path(curation_dir, "figure-curation-review.html"))
