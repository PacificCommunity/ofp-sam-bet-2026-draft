#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT_DIR="${OUTPUT_DIR:-outputs}"
INPUT_DIR="${INPUT_DIR:-inputs}"
REPORT_DIR="${REPORT_DIR:-bet-2026-report}"
REPORT_QMD="${REPORT_QMD:-assessment-report.qmd}"

mkdir -p "${OUT_DIR}"

echo "BET 2026 report task"
echo "Input artifacts: ${INPUT_DIR}"
echo "Report directory: ${REPORT_DIR}"
echo "Report entrypoint: ${REPORT_QMD}"

Rscript R/prepare_report_inputs.R

cd "${REPORT_DIR}"
quarto render "${REPORT_QMD}" --to html --output bet-2026-report.html
cd "${ROOT}"

cp "${REPORT_DIR}/bet-2026-report.html" "${OUT_DIR}/bet-2026-report.html"
mkdir -p "${OUT_DIR}/report" "${OUT_DIR}/figures" "${OUT_DIR}/tables"
cp "${REPORT_DIR}/bet-2026-report.html" "${OUT_DIR}/report/bet-2026-report.html"

if [[ -d "${REPORT_DIR}/Figures/generated" ]]; then
  find "${REPORT_DIR}/Figures/generated" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.pdf' -o -name '*.csv' \) -exec cp {} "${OUT_DIR}/figures/" \;
fi
if [[ -d "${REPORT_DIR}/tables/generated" ]]; then
  find "${REPORT_DIR}/tables/generated" -maxdepth 1 -type f -name '*.csv' -exec cp {} "${OUT_DIR}/tables/" \;
fi
if [[ -d "${REPORT_DIR}/pipeline-inputs" ]]; then
  find "${REPORT_DIR}/pipeline-inputs" -maxdepth 1 -type f -name '*.csv' -exec cp {} "${OUT_DIR}/tables/" \;
fi

Rscript - <<'RS'
out <- Sys.getenv("OUTPUT_DIR", "outputs")
files <- list.files(out, recursive = TRUE, full.names = FALSE)
summary <- data.frame(
  output = files,
  type = ifelse(grepl("[.]html$", files), "html", ifelse(grepl("[.](png|jpg|jpeg|pdf)$", files, ignore.case = TRUE), "figure", "table")),
  stringsAsFactors = FALSE
)
utils::write.csv(summary, file.path(out, "report-output-index.csv"), row.names = FALSE)
RS
