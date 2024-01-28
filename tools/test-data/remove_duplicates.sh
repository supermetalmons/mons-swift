#!/bin/bash

# A temporary file to hold file hashes
tempfile=$(mktemp /tmp/filehashes.XXXXXX)

# Generate hashes for each file and store them in the temporary file
find . -type f -exec md5 -r {} + | sort > "$tempfile"

# Initialize variables
prev_hash=""
prev_file=""

# Read each line from the temp file
while read -r hash file; do
    if [[ $hash == $prev_hash ]]; then
        echo "Duplicate found. Removing $file"
        rm "$file"
    else
        prev_hash=$hash
        prev_file=$file
    fi
done < "$tempfile"

# Clean up
rm "$tempfile"

