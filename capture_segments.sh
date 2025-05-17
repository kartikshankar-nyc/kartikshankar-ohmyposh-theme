#!/bin/bash

# Create a directory for the zoomed segments
mkdir -p zoomed_segments

# Function to display a specific segment with enlarged text
display_segment() {
  local segment_name=$1
  local segment_text=$2
  local output_file="zoomed_segments/${segment_name}.png"
  
  # Create an HTML file with the segment content displayed at large size
  cat > /tmp/segment_display.html << EOF
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      background-color: #282c34;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      font-family: 'Hack Nerd Font', monospace;
    }
    .segment {
      font-size: 48px;
      padding: 20px;
      white-space: nowrap;
    }
  </style>
</head>
<body>
  <div class="segment">${segment_text}</div>
</body>
</html>
EOF

  # Open the HTML in browser (for manual screenshot)
  open /tmp/segment_display.html
  
  echo "Please take a screenshot of the ${segment_name} segment and save it to ${output_file}"
  echo "Press Enter when done..."
  read
}

# Display each segment for screenshot
display_segment "apple_icon" " "
display_segment "username" "kartikshankar"
display_segment "computer_name" "Narasimha"
display_segment "root_indicator" "#"
display_segment "directory_path" "~/github/project"
display_segment "git_status" "main ≡ ✓"
display_segment "time_display" "20:45:30"
display_segment "prompt_character" "❯"

echo "All segments displayed. Check zoomed_segments directory for the captured images." 