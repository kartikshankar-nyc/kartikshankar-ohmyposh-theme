#!/bin/bash

# Create output directory
mkdir -p zoomed_segments

# Function to extract and resize a segment
extract_segment() {
  local input=$1
  local output=$2
  local width=$3
  local height=$4
  local x=$5
  local y=$6
  
  # Convert command: crop the segment and resize it
  convert "$input" -crop "${width}x${height}+${x}+${y}" -resize 300% -background "#282c34" -extent "300%x300%" "$output"
}

echo "Extracting and zooming segments..."

# Manually define crop regions for each segment
# Format: extract_segment input_file output_file width height x y

# Apple icon segment
extract_segment "segment_images/apple_icon.png" "zoomed_segments/apple_icon.png" 80 50 20 20

# Username segment
extract_segment "segment_images/username.png" "zoomed_segments/username.png" 120 50 20 20

# Computer name segment
extract_segment "segment_images/computer_name.png" "zoomed_segments/computer_name.png" 160 50 20 20

# Root indicator segment
extract_segment "segment_images/root_indicator.png" "zoomed_segments/root_indicator.png" 50 50 20 20

# Directory path segment
extract_segment "segment_images/directory_path.png" "zoomed_segments/directory_path.png" 180 50 20 20

# Git status segment
extract_segment "segment_images/git_status.png" "zoomed_segments/git_status.png" 160 50 20 20

# Time display segment
extract_segment "segment_images/time_display.png" "zoomed_segments/time_display.png" 120 50 20 20

# Prompt character segment
extract_segment "segment_images/prompt_character.png" "zoomed_segments/prompt_character.png" 50 50 20 20

echo "Done. Check zoomed_segments directory for results." 