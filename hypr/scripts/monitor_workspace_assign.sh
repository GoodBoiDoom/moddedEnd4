#!/bin/bash

# --- CONFIG ---
NUM_WORKSPACES=10

# 1. Get monitor names sorted by physical X position
mapfile -t MONITORS < <(hyprctl monitors -j | jq -r 'sort_by(.x) | .[].name')
NUM_MONS=${#MONITORS[@]}

if [ "$NUM_MONS" -eq 0 ]; then
    exit 1
fi

# 2. Separate monitors into "Left Side" and "Right Side" pools
LEFT_SIDE_MONS=()
RIGHT_SIDE_MONS=()

for ((i=0; i<NUM_MONS; i++)); do
    if (( (i + 1) % 2 != 0 )); then
        LEFT_SIDE_MONS+=("${MONITORS[$i]}")
    else
        RIGHT_SIDE_MONS+=("${MONITORS[$i]}")
    fi
done

# Fallback for single monitor
if [ ${#RIGHT_SIDE_MONS[@]} -eq 0 ]; then
    RIGHT_SIDE_MONS=("${LEFT_SIDE_MONS[0]}")
fi

# 3. Apply Binding Rules
for ((ws=1; ws<=NUM_WORKSPACES; ws++)); do
    if (( ws % 2 != 0 )); then
        # ODD Workspaces -> Left Monitors
        idx=$(( ((ws + 1) / 2 - 1) % ${#LEFT_SIDE_MONS[@]} ))
        target=${LEFT_SIDE_MONS[$idx]}
    else
        # EVEN Workspaces -> Right Monitors
        idx=$(( (ws / 2 - 1) % ${#RIGHT_SIDE_MONS[@]} ))
        target=${RIGHT_SIDE_MONS[$idx]}
    fi

    # SET THE RULE (Binding)
    # We remove 'persistent' so they only exist when tabs are in them.
    hyprctl keyword workspace "$ws,monitor:$target" > /dev/null
done