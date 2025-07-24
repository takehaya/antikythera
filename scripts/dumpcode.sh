#!/bin/bash
set -e

TARGET_DIR=${1:-.}

tree . -a -I "\.DS_Store|\.git|target|dump.*|tools" -N

find "$TARGET_DIR" \
    \( -type d -name bin -o -name .git -o -name build -o -name docker -o -name tools -o -name 'dump.*' \) \
    -prune -o -type f -name '*.v' -print \
| while read -r file; do
    echo "Filename: $file"
    echo "---"
    cat "$file"
    echo "---"
done