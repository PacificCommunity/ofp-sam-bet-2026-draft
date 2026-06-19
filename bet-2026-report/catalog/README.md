# Report Catalogs

The report decides where generated figures and tables appear from two small CSV
files:

- `figures.csv`: one row per figure slot.
- `figure-curation.csv`: optional overlay for moving generated figures between
  the main report, appendix, and excluded set.
- `tables.csv`: one row per table slot.

Edit these files when you want to manually control report layout. The most
useful columns are:

- `section`: the report section heading.
- `title`: the subsection title printed above the asset.
- `file_candidates`: possible file names, separated by semicolons. The first
  matching file wins.
- `caption`: the report caption. Placeholders such as `{species_label}` and
  `{assessment_year}` are filled from `report-config.yml`.
- `todo`: the message shown when the file is missing.

For figure curation, edit `figure-curation.csv`:

- `target_type`: use `key` for a row in `figures.csv`, or `file` for a
  generated filename.
- `target`: the catalog key or generated filename/stem to match.
- `placement`: `main`, `appendix`, or `exclude`.
- `section` and `title`: optional report headings for promoted generated files.
- `caption_override`: optional caption that wins over generated metadata and
  the base catalog caption.
- `order`: optional number for ordering curated rows.

Generated mfclshiny outputs are expected under `Figures/generated` and
`tables/generated`. Extra generated files that are not listed in the catalog are
still included at the end of the relevant section, so exploratory Kflow runs are
easy to inspect before choosing the final report set.

Every report render writes `curation/figure-curation-review.html` and
`curation/figure-curation-template.csv`. Use the HTML page to inspect thumbnails,
current placement, and captions; use the CSV template as a complete list of
available targets when updating `figure-curation.csv`.
