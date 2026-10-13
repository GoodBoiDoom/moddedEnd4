#!/bin/bash

# --- CONFIGURATION ---
STATE_FILE="$HOME/.config/hypr/wallpaper.env"
WORKSPACE_SCRIPT="$HOME/.config/hypr/scripts/monitor_workspace_assign.sh"
TMP_DIR="/tmp/swww_slices"
mkdir -p "$TMP_DIR"

# Optimized Transition Settings
T_TYPE="grow"
T_STEP=120
T_FPS=144

# CLEANUP PREVIOUS INSTANCES(when logging back in or restarting the script)
# Ensures that when loggin back in, the instance from the last session is killed to prevent multiple instances running simultaneously
CUR_PID=$$
for pid in $(pgrep -f "swww_daemon.sh"); do
  if [ "$pid" != "$CUR_PID" ]; then kill -9 "$pid" 2>/dev/null; fi
done

# --- FUNCTIONS ---

function get_monitors {
  hyprctl monitors -j | jq -r 'sort_by(.x) | .[] | "\(.name) \(.width)"'
}

function apply_wallpaper {
  [ -f "$STATE_FILE" ] && source "$STATE_FILE"

  # 1. Ensure swww-daemon is initialized
    swww-daemon --format xrgb &

 sleep 1.5 # lets swww-daemon fully initialize before sending commands to it, preventing race conditions
  fi

  mapfile -t MON_DATA < <(get_monitors)
  NUM_MONS=${#MON_DATA[@]}
  [ "$NUM_MONS" -eq 0 ] && return

  if [ "$NUM_MONS" -eq 1 ]; then
    TARGET="$SINGLE_WALLPAPER"
    [ -z "$TARGET" ] && TARGET="$WIDE_WALLPAPER"
    [ -f "$TARGET" ] && swww img "$TARGET" --transition-type "$T_TYPE" --transition-step "$T_STEP" --transition-fps "$T_FPS"
  else
    if [ "$MODE" == "FILL" ] && [ -f "$SINGLE_WALLPAPER" ]; then
      swww img "$SINGLE_WALLPAPER" --transition-type "$T_TYPE" --transition-step "$T_STEP" --transition-fps "$T_FPS"

    elif [ "$MODE" == "SPLIT" ] && [ -f "$WIDE_WALLPAPER" ]; then
      # Cache Mechanism to avoid reapplying the same wallpaper
      # Creating an unique hash based on the image path and monitor count
      # If the hash matches, skip the 'convert' step
      HASH=$(echo "$WIDE_WALLPAPER-$NUM_MONS" | md5sum | awk '{print $1}')
      CACHE_MARKER="$TMP_DIR/last_hash.txt"
      LAST_HASH=$(cat "$CACHE_MARKER" 2>/dev/null)

      if [ "$HASH" != "$LAST_HASH" ]; then
        read -r IMG_W IMG_H < <(identify -format "%w %h" "$WIDE_WALLPAPER")
        TOTAL_PHYS_W=0
        for line in "${MON_DATA[@]}"; do
          TOTAL_PHYS_W=$((TOTAL_PHYS_W + $(echo "$line" | awk '{print $2}')))
        done

        CURRENT_X=0
        PIDS=()
        for ((i = 0; i < NUM_MONS; i++)); do
          MON_W=$(echo "${MON_DATA[$i]}" | awk '{print $2}')
          SLICE_W=$((MON_W * IMG_W / TOTAL_PHYS_W))
          OFFSET_X=$((CURRENT_X * IMG_W / TOTAL_PHYS_W))
          OUTPUT="$TMP_DIR/slice_$i.png"

          nice -n 19 convert "$WIDE_WALLPAPER" -crop "${SLICE_W}x${IMG_H}+${OFFSET_X}+0" +repage "$OUTPUT" &
          PIDS+=($!)
          CURRENT_X=$((CURRENT_X + MON_W))
        done
        wait "${PIDS[@]}"//waits till wallpaper is split and cached before applying
        echo "$HASH" >"$CACHE_MARKER"
      fi

      # Apply cached slices
      for ((i = 0; i < NUM_MONS; i++)); do
        NAME=$(echo "${MON_DATA[$i]}" | awk '{print $1}')
        swww img "$TMP_DIR/slice_$i.png" --outputs "$NAME" --transition-type "$T_TYPE" --transition-step "$T_STEP" --transition-fps "$T_FPS"
      done

    elif [ "$MODE" == "DISTINCT" ]; then
      for ((i = 0; i < NUM_MONS; i++)); do
        NAME=$(echo "${MON_DATA[$i]}" | awk '{print $1}')
        IMG="${DISTINCT_PATHS[$i]:-${WALL_PATHS[$i]}}"
        [ $i -eq 0 ] && [ -z "$IMG" ] && IMG="$WALL_LEFT"
        [ $i -eq 1 ] && [ -z "$IMG" ] && IMG="$WALL_RIGHT"
        [ -f "$IMG" ] && swww img "$IMG" --outputs "$NAME" --transition-type "$T_TYPE" --transition-step "$T_STEP" --transition-fps "$T_FPS"
      done
    fi
  fi

  [ -f "$WORKSPACE_SCRIPT" ] && bash "$WORKSPACE_SCRIPT" &
}

# Set up signal handler for manual refresh(link with a hyprland keybind)
trap apply_wallpaper SIGUSR1

# main
apply_wallpaper

# Using a loop for socat to make it resilient to Hyprland restarts
while true; do
  SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  if [ -S "$SOCKET" ]; then
    socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
      if [[ $line == monitoradded* ]]; then
        apply_wallpaper
      elif [[ $line == monitorremoved* ]]; then
        CURRENT_COUNT=$(hyprctl monitors -j | jq '. | length')
        if [ "$CURRENT_COUNT" -eq 1 ]; then
          apply_wallpaper
        else
          [ -f "$WORKSPACE_SCRIPT" ] && bash "$WORKSPACE_SCRIPT" &
        fi
      fi
    done
  fi
  sleep 2 # Wait before trying to reconnect if socket fails
done
