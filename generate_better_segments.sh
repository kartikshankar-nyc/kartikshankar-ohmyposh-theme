#!/bin/bash

# Create output directory
mkdir -p better_segments

# Function to enhance a segment image
enhance_segment() {
  local input_file=$1
  local output_file=$2
  
  # Create a high-quality enlarged image with improved contrast
  magick "$input_file" -resize 500% -background "#282c34" -gravity center -extent 500x200 \
    -brightness-contrast 10x30 "$output_file"
}

echo "Enhancing segment images for better visibility..."

# Enhance each segment image
enhance_segment "segment_images/apple_icon.png" "better_segments/apple_icon.png"
enhance_segment "segment_images/username.png" "better_segments/username.png"
enhance_segment "segment_images/computer_name.png" "better_segments/computer_name.png"
enhance_segment "segment_images/root_indicator.png" "better_segments/root_indicator.png"
enhance_segment "segment_images/directory_path.png" "better_segments/directory_path.png"
enhance_segment "segment_images/git_status.png" "better_segments/git_status.png"
enhance_segment "segment_images/time_display.png" "better_segments/time_display.png"
enhance_segment "segment_images/prompt_character.png" "better_segments/prompt_character.png"

echo "Done. Check better_segments directory for results." 