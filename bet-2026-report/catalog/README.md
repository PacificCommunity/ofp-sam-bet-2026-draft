# Report Catalogs

The report decides where generated figures and tables appear from two small CSV
files:

- `figures.csv`: one row per figure slot.
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

Generated mfclshiny outputs are expected under `Figures/generated` and
`tables/generated`. Extra generated files that are not listed in the catalog are
still included at the end of the relevant section, so exploratory Kflow runs are
easy to inspect before choosing the final report set.
