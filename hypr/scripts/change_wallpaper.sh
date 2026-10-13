#!/bin/bash

# --- CONFIGURATION ---
STATE_FILE="$HOME/.config/hypr/wallpaper.env"
TRANSITION_TYPE="grow" 
TRANSITION_FPS=60

# 1. Ensure swww-daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
    sleep 0.5
fi

# 2. Get Monitor Data (Sorted Left-to-Right)
mapfile -t MON_NAMES < <(hyprctl monitors -j | jq -r 'sort_by(.x) | .[].name')
NUM_MONS=${#MON_NAMES[@]}

# 3. Load existing state if it exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
fi

# --- FUNCTIONS ---

function save_state {
    # Writes the variables back to wallpaper.env
    cat <<EOT > "$STATE_FILE"
MODE="$MODE"
WIDE_WALLPAPER="$WIDE_WALLPAPER"
SINGLE_WALLPAPER="$SINGLE_WALLPAPER"
WALL_LEFT="$WALL_LEFT"
WALL_RIGHT="$WALL_RIGHT"
EOT
}

function get_image {
    zenity --file-selection --title="$1" --file-filter="Images | *.jpg *.jpeg *.png *.webp *.gif"
}

function apply_wall {
    # $1 = Monitor Name (empty for all), $2 = Image Path
    swww img "$2" \
        ${1:+--outputs "$1"} \
        --transition-type "$TRANSITION_TYPE" \
        --transition-fps "$TRANSITION_FPS" \
        --transition-step 90
}

function run_restore {
    case "$MODE" in
        "FILL")
            [ -n "$SINGLE_WALLPAPER" ] && apply_wall "" "$SINGLE_WALLPAPER"
            ;;
        "SPLIT")
            if [ -n "$WIDE_WALLPAPER" ]; then
                IMG_W=$(identify -format "%w" "$WIDE_WALLPAPER")
                IMG_H=$(identify -format "%h" "$WIDE_WALLPAPER")
                SLICE_W=$((IMG_W / NUM_MONS))
                for ((i=0; i<NUM_MONS; i++)); do
                    OFFSET=$((i * SLICE_W))
                    TMP_SLICE="/tmp/swww_split_$i.png"
                    convert "$WIDE_WALLPAPER" -crop "${SLICE_W}x${IMG_H}+${OFFSET}+0" +repage "$TMP_SLICE"
                    apply_wall "${MON_NAMES[$i]}" "$TMP_SLICE"
                done
            fi
            ;;
        "DISTINCT")
            # Apply to first two monitors based on your variables
            [ -n "$WALL_LEFT" ] && apply_wall "${MON_NAMES[0]}" "$WALL_LEFT"
            [ -n "$WALL_RIGHT" ] && [ $NUM_MONS -gt 1 ] && apply_wall "${MON_NAMES[1]}" "$WALL_RIGHT"
            ;;
    esac
}

# --- LOGIC ---

# Check if we are just restoring the previous session
if [ "$1" == "--restore" ]; then
    run_restore
    exit 0
fi

# Generate Menu Options
OPT_FILL="$ Fill All (Single Image)"
OPT_SPLIT="$ Split Wide Image (Across $NUM_MONS Screens)"
OPT_DISTINCT="$ Distinct (Select for each)"

MON_OPTIONS=""
for ((i=0; i<NUM_MONS; i++)); do
    MON_OPTIONS+="$ Monitor $((i+1)): ${MON_NAMES[$i]}\n"
done

CHOICE=$(echo -e "$OPT_FILL\n$OPT_SPLIT\n$OPT_DISTINCT\n$MON_OPTIONS" | rofi -dmenu -p "SWWW Wallpaper" -i -l 6)

case "$CHOICE" in
    "$OPT_FILL")
        IMG=$(get_image "Select Wallpaper")
        if [ -n "$IMG" ]; then
            SINGLE_WALLPAPER="$IMG"; MODE="FILL"
            apply_wall "" "$IMG"
            save_state
        fi
        ;;

    "$OPT_SPLIT")
        IMG=$(get_image "Select Wide Image to Split")
        if [ -n "$IMG" ]; then
            WIDE_WALLPAPER="$IMG"; MODE="SPLIT"
            save_state
            run_restore # This handles the cropping and applying logic
        fi
        ;;

    "$OPT_DISTINCT")
        MODE="DISTINCT"
        for ((i=0; i<NUM_MONS; i++)); do
            IMG=$(get_image "Monitor $((i+1)) (${MON_NAMES[$i]})")
            if [ -n "$IMG" ]; then
                apply_wall "${MON_NAMES[$i]}" "$IMG"
                [ $i -eq 0 ] && WALL_LEFT="$IMG"
                [ $i -eq 1 ] && WALL_RIGHT="$IMG"
            fi
        done
        save_state
        ;;

    *"Monitor"*)
        SELECTED_MON=$(echo "$CHOICE" | awk -F': ' '{print $2}')
        IMG=$(get_image "Select Image for $SELECTED_MON")
        if [ -n "$IMG" ]; then
            apply_wall "$SELECTED_MON" "$IMG"
            # Update specific variable if it's one of the first two
            [ "$SELECTED_MON" == "${MON_NAMES[0]}" ] && WALL_LEFT="$IMG"
            [ "$SELECTED_MON" == "${MON_NAMES[1]}" ] && WALL_RIGHT="$IMG"
            save_state
        fi
        ;;
esac