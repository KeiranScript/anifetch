#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-v] [-tags TAGS]"
    echo "  -v         Enable verbose output"
    echo "  -tags      Specify tags for filtering images (separate multiple tags with spaces)"
    exit 1
}

# Parse command line arguments
VERBOSE=false
TAGS=""

while getopts "vtags:" opt; do
    case ${opt} in
        v )
            VERBOSE=true
            ;;
        t )
            TAGS="$OPTARG"
            ;;
        a )
            TAGS="$OPTARG"
            ;;
        \? )
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# API endpoint to get random anime girl image
API_URL="https://api.waifu.pics/sfw/waifu"

# Desired image dimensions (width x height)
MAX_WIDTH=200
MAX_HEIGHT=300
MIN_SIZE=10240  # Minimum file size in bytes (10 KB for example)

# Fetch a random anime girl image URL
IMAGE_URL=$(curl -s "$API_URL" | jq -r '.url')

# Check if IMAGE_URL is empty
if [ -z "$IMAGE_URL" ]; then
    echo "Error: Failed to fetch image URL."
    exit 1
fi

if [ "$VERBOSE" = true ]; then
    echo "Fetching anime girl image from: $IMAGE_URL"
fi

# Download the image
wget -q -O anime_image.jpg "$IMAGE_URL"

# Determine the file extension
FILE_EXTENSION="${IMAGE_URL##*.}"

# Check the file size
FILE_SIZE=$(stat -c%s "anime_image.jpg")

# Filter out images below the minimum size
if [ "$FILE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "Error: The fetched image is too small."
    rm anime_image.jpg
    exit 1
fi

# Handle different file types
case "$FILE_EXTENSION" in
    "png"|"jpg")
        # Resize PNG and JPEG images if necessary
        magick anime_image.jpg -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" anime_image_resized.jpg
        DISPLAY_IMAGE="anime_image_resized.jpg"
        ;;
    "svg")
        # For SVG files, just use the original file
        DISPLAY_IMAGE="anime_image.jpg"
        ;;
    *)
        # Handle other formats or convert to PNG if necessary
        echo "Error: Unsupported image format."
        rm anime_image.jpg
        exit 1
        ;;
esac

# Get system information
OS_NAME=$(uname -o)
KERNEL_VERSION=$(uname -r)
HOSTNAME=$(uname -n)
UPTIME=$(uptime -p | sed 's/up //')
CPU_INFO=$(lscpu | grep "Model name" | sed 's/Model name: *//')
GPU_INFO=$(lspci | grep VGA | sed 's/.*: //')
MEMORY_INFO=$(free -h | grep Mem | awk '{print $3 " / " $2 " (" $3/$2*100 "%)"}')
DISPLAYS=$(xrandr | grep '*' | awk '{print $1}')

# Detect Terminal
if [[ $TERM == *"kitty"* ]]; then
    TERMINAL="kitty"
elif [[ $TERM == *"xterm"* ]]; then
    TERMINAL="xterm"
elif [[ $TERM == *"alacritty"* ]]; then
    TERMINAL="alacritty"
elif [[ $TERM == *"gnome-terminal"* ]]; then
    TERMINAL="gnome-terminal"
elif [[ $TERM == *"konsole"* ]]; then
    TERMINAL="konsole"
elif [[ $TERM == *"urxvt"* ]]; then
    TERMINAL="urxvt"
else
    TERMINAL="unknown"
fi

# Detect Window Manager/Desktop Environment
if command -v wmctrl >/dev/null 2>&1; then
    WM=$(wmctrl -m | grep "Name" | sed 's/Name:\s*//')
else
    WM=${XDG_CURRENT_DESKTOP:-"Unknown or not detected"}
fi

# Pretty print the information
echo -e "\n\033[1;33mAnifetch\033[0m"

# Function to detect if the terminal is Kitty
is_kitty() {
    [[ "$TERM" == *"kitty"* ]]
}

# Display the image
if is_kitty; then
    if command -v kitty >/dev/null 2>&1; then
        kitty icat --align left "$DISPLAY_IMAGE"
    else
        echo "Error displaying image. Please install Kitty."
    fi
elif command -v catimg >/dev/null 2>&1; then
    catimg "$DISPLAY_IMAGE"
else
    echo "Error displaying image. Please install catimg or use Kitty."
fi

# Display system information
cat <<EOF

──────────────────────────────────────────
 OS        : $OS_NAME
 Kernel    : $KERNEL_VERSION
 Hostname  : $HOSTNAME
 Uptime    : $UPTIME
 Packages  : $(pacman -Qq | wc -l) (pacman)
 Display   : $DISPLAYS
 WM        : $WM
 Terminal  : $TERMINAL
 User      : $(whoami)
──────────────────────────────────────────

EOF

# Clean up
rm anime_image.jpg anime_image_resized.jpg
