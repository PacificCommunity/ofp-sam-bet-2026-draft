# Report Catalogs

This folder controls which generated figures and tables appear in the report.
It is part of the report repo; it is not a separate Kflow curation task.

## Files

- `figures.csv`: standard figure slots.
- `tables.csv`: standard table slots.
- `curation.yml`: small human-edited overrides for placement, order, headings,
  captions, and exclusions.

Most edits should go in `curation.yml`. Keep the CSV files for stable default
report structure.

## Useful Fields

In `figures.csv` and `tables.csv`:

- `section`: report section heading.
- `title`: title printed above the asset.
- `file_candidates`: possible generated files; the first match is used.
- `caption`: default caption, with placeholders filled from
  `report-config.yml`.
- `todo`: message shown when an expected file is missing.

In `curation.yml`:

- `target_type`: `key` for a catalog row or `file` for a generated filename.
- `target`: catalog key, filename, or filename stem.
- `placement`: `main`, `appendix`, or `exclude`.
- `section`, `title`, `caption_override`, `order`: optional overrides.

Open `generated/outputs/report-ready/report-map.html` before editing. It shows
the generated assets and makes it easier to choose the right target names.
