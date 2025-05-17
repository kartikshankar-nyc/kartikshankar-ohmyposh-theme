#!/bin/bash

# Create output directory
mkdir -p high_res_segments

# Function to create a high-resolution image of a segment
create_segment() {
  local segment_name=$1
  local segment_text=$2
  local output_file="high_res_segments/${segment_name}.png"
  
  # Create a high-resolution image with the segment text
  magick -size 800x200 -background "#282c34" -fill "#ffffff" -font "Hack-Nerd-Font-Mono" -pointsize 72 \
    -gravity center label:"$segment_text" "$output_file"
}

echo "Creating high-resolution segment images..."

# Create each segment with proper text/icons
create_segment "apple_icon" " "
create_segment "username" "kartikshankar"
create_segment "computer_name" "Narasimha"
create_segment "root_indicator" "#"
create_segment "directory_path" "~/github/project"
create_segment "git_status" "main ≡ ✓"
create_segment "time_display" "20:45:30"
create_segment "prompt_character" "❯"

echo "Done. Check high_res_segments directory for results." 