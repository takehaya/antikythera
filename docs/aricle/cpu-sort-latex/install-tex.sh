#!/bin/sh
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  texlive-lang-japanese texlive-latex-recommended texlive-pictures \
  poppler-utils python3 lmodern mupdf-tools qpdf python3-pikepdf python3-pil fonts-ipaexfont
apt-get clean
rm -rf /var/lib/apt/lists/*
mkdir -p /opt/cpu-report
dpkg-query -W -f='${Package}\t${Version}\n' > /opt/cpu-report/package-versions.tsv
kanji-config-updmap-sys ipaex
