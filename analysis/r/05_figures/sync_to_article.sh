#!/usr/bin/env bash
# Copy the generated figures and LaTeX table fragments into the manuscript
# repository (a private sibling checkout; nothing is computed there). The
# copying itself lives in that repository's scripts/sync_figures.sh.
#
#   bash analysis/r/05_figures/sync_to_article.sh                 # ../IDAlert-T54-Article
#   ARTICLE=/path/to/manuscript bash analysis/r/05_figures/sync_to_article.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ARTICLE=${ARTICLE:-../IDAlert-T54-Article}
[[ -f $ARTICLE/scripts/sync_figures.sh ]] || { echo "manuscript repository not found at $ARTICLE" >&2; exit 1; }
analysis=$PWD
cd "$ARTICLE"
ANALYSIS=$analysis bash scripts/sync_figures.sh
