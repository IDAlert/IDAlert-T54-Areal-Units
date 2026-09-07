#!/usr/bin/env bash
#
# Build the PDF rendering of the pre-registration from its markdown source.
#
#   docs/preregistration/preregistration-osf.md  ->  ...-osf.pdf
#
# The markdown is the document of record; the PDF is a derived artifact and is
# not tracked in version control. Every option below is typographic — nothing
# here alters the text, and the PDF should always be regenerated from the
# markdown rather than edited.
#
# Requires pandoc and XeLaTeX. Run from anywhere; paths are resolved relative
# to this script.
#
# Usage: docs/preregistration/build-pdf.sh [output.pdf]

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/preregistration-osf.md"
out="${1:-$here/preregistration-osf.pdf}"

for tool in pandoc xelatex; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "error: $tool not found on PATH" >&2
    exit 1
  }
done

[ -f "$src" ] || { echo "error: source not found: $src" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Preamble. Tables are set a size down so that all nine fit the text block;
# the widow and club penalties keep headings and single lines off page breaks.
cat > "$work/preamble.tex" <<'TEX'
\usepackage{etoolbox}
\AtBeginEnvironment{longtable}{\small}
\setlength{\LTpre}{0.9\baselineskip}
\setlength{\LTpost}{0.9\baselineskip}
\raggedbottom
\widowpenalty=10000
\clubpenalty=10000
\usepackage{titlesec}
\titleformat*{\section}{\Large\bfseries\sffamily}
\titleformat*{\subsection}{\large\bfseries\sffamily}
\titleformat*{\subsubsection}{\normalsize\bfseries\sffamily}
% STIX Two Text carries the degree, plus-minus, multiplication, superscript-two
% and dash glyphs the document uses, but not these three relations; map them to
% the matching math glyphs so they render rather than dropping out silently.
\usepackage{newunicodechar}
\newunicodechar{≤}{\ensuremath{\leq}}
\newunicodechar{≥}{\ensuremath{\geq}}
\newunicodechar{≈}{\ensuremath{\approx}}
TEX

# Repository paths in code spans are longer than the table columns they sit in
# and contain no character LaTeX will break at. This inserts zero-width break
# opportunities after the path separators. No hyphen is added and no character
# is changed — only the set of places a line may end.
cat > "$work/breakcode.lua" <<'LUA'
function Code(el)
  if FORMAT ~= 'latex' then return nil end
  local s = el.text
  s = s:gsub('\\', '\\textbackslash{}')
  s = s:gsub('([%%%$&#_{}])', '\\%1')
  s = s:gsub('~', '\\textasciitilde{}')
  s = s:gsub('%^', '\\textasciicircum{}')
  s = s:gsub('/', '/\\allowbreak{}')
  s = s:gsub('\\_', '\\_\\allowbreak{}')
  s = s:gsub('%-', '-\\allowbreak{}')
  return pandoc.RawInline('latex', '\\texttt{' .. s .. '}')
end
LUA

# title-meta and author-meta set the PDF document properties only. Passing
# --metadata title instead would print a title block, duplicating the heading
# the markdown already carries.
pandoc "$src" -o "$out" \
  --pdf-engine=xelatex \
  --lua-filter="$work/breakcode.lua" \
  --include-in-header="$work/preamble.tex" \
  -V fontsize=11pt \
  -V geometry:"a4paper,margin=1in" \
  -V mainfont="STIX Two Text" \
  -V sansfont="Helvetica Neue" \
  -V monofont="Menlo" \
  -V monofontoptions="Scale=0.85" \
  -V colorlinks=true \
  -V linkcolor=Maroon \
  -V urlcolor=Maroon \
  -V title-meta="Pre-registration: Regulatory-Focus Framing in Geographically Targeted Advertisements for Citizen Science" \
  -V author-meta="Berj Dekramanjian; John R.B. Palmer"

echo "wrote $out"
