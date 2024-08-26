#!/bin/bash

find ./folder -name "*.md" | while read -r file; do
    echo "Processing file: $file"
    if ! grep -q "^---" "$file"; then
        sed -i '1i---\nlayout: post\n---\n' "$file"
        echo "Added header to $file"
    else
        echo "Header already exists in $file"
    fi
done

echo "Script completed"