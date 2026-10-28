#!/usr/bin/env bash
# ==============================================================================
#  BUILD-RESUME — Automated Single-Command Resume Compiler
#  Compiles an HTML resume into a crisp 1-page PDF and a Word (.docx) document.
# ==============================================================================

set -e

HTML_FILE="${1:-}"

if [ -z "$HTML_FILE" ] || [ ! -f "$HTML_FILE" ]; then
  echo -e "\033[1;31mUsage:\033[0m build-resume <path-to-resume.html>"
  exit 1
fi

DIR=$(dirname "$HTML_FILE")
BASENAME=$(basename "$HTML_FILE" .html)
PDF_OUT="$DIR/${BASENAME}.pdf"
DOCX_OUT="$DIR/${BASENAME}.docx"

echo -e "\033[1;36m[*] Building PDF:\033[0m $PDF_OUT..."
chromium --headless --disable-gpu --print-to-pdf="$PDF_OUT" --no-pdf-header-footer "$HTML_FILE" >/dev/null 2>&1

PAGES=$(pdfinfo "$PDF_OUT" 2>/dev/null | grep -i "Pages:" | awk '{print $2}')
if [ "$PAGES" = "1" ]; then
  echo -e "\033[1;32m[✓] PDF compiled successfully (Exact 1 Page)!\033[0m"
else
  echo -e "\033[1;33m[!] Warning: PDF is $PAGES pages. Consider adjusting CSS font/margin.\033[0m"
fi

echo -e "\033[1;36m[*] Building Word (.docx):\033[0m $DOCX_OUT..."
libreoffice --headless --convert-to "docx:MS Word 2007 XML" "$HTML_FILE" --outdir "$DIR" >/dev/null 2>&1

if [ -f "$DOCX_OUT" ]; then
  echo -e "\033[1;32m[✓] Word (.docx) generated successfully!\033[0m"
fi

echo -e "\033[1;32m[✓] All formats up to date in:\033[0m $DIR\n"
