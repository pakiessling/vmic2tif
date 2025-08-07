#!/bin/bash

# Script to convert all .vmic files in a folder to .ome.tif using Bio-Formats
# Usage: ./vmic_to_ome_converter.sh /path/to/input/folder [/path/to/output/folder]

# Configuration - adjust these paths as needed
BIOFORMATS_PATH="artifacts/*"

# Default settings for conversion
TILE_SIZE=1024
COMPRESSION="zlib"
PYRAMID_SCALE=2

# Check if input folder is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input_folder> [output_folder]"
    echo "Example: $0 /Volumes/T7-CK/HEART_TMA_original/ ./converted/"
    exit 1
fi

INPUT_FOLDER="$1"
OUTPUT_FOLDER="${2:-${INPUT_FOLDER}/converted}"

# Check if input folder exists
if [ ! -d "$INPUT_FOLDER" ]; then
    echo "Error: Input folder '$INPUT_FOLDER' does not exist"
    exit 1
fi

# Create output folder if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"

# Find all .vmic files, excluding temporary files starting with ._
VMIC_FILES=($(find "$INPUT_FOLDER" -name "*.vmic" -type f ! -name "._*"))

if [ ${#VMIC_FILES[@]} -eq 0 ]; then
    echo "No .vmic files found in '$INPUT_FOLDER'"
    exit 1
fi

echo "Found ${#VMIC_FILES[@]} .vmic files to convert"
echo "Input folder: $INPUT_FOLDER"
echo "Output folder: $OUTPUT_FOLDER"
echo "Settings: ${TILE_SIZE}x${TILE_SIZE} tiles, $COMPRESSION compression, pyramid scale $PYRAMID_SCALE"
echo ""

# Counter for progress
CURRENT=0
TOTAL=${#VMIC_FILES[@]}
SUCCESSFUL=0
FAILED=0

# Process each file
for vmic_file in "${VMIC_FILES[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    # Get filename without path and extension
    filename=$(basename "$vmic_file" .vmic)
    output_file="$OUTPUT_FOLDER/${filename}.ome.tif"
    
    echo "[$CURRENT/$TOTAL] Converting: $filename"
    echo "  Input: $vmic_file"
    echo "  Output: $output_file"
    
    # Check if output file already exists
    if [ -f "$output_file" ]; then
        echo "  Warning: Output file already exists. Skipping..."
        echo ""
        continue
    fi
    
    # Run the conversion
    if java -cp "$BIOFORMATS_PATH" loci.formats.tools.ImageConverter \
        -tilex $TILE_SIZE -tiley $TILE_SIZE \
        -compression $COMPRESSION \
        -pyramid-scale $PYRAMID_SCALE \
        -bigtiff \
        -overwrite \
        "$vmic_file" "$output_file" 2>/dev/null; then
        
        echo "  ✓ Success"
        SUCCESSFUL=$((SUCCESSFUL + 1))
    else
        echo "  ✗ Failed"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
done

# Summary
echo "Conversion complete!"
echo "Total files: $TOTAL"
echo "Successful: $SUCCESSFUL"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "Some files failed to convert. Check the error messages above."
    exit 1
fi