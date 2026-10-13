#!/bin/bash

# 1. Get current profile and power status
current=$(powerprofilesctl get)

# Check if plugged in (grep returns 0 if found, so we check for "1" in online file)
if grep -q 1 /sys/class/power_supply/*/online 2>/dev/null; then
    ON_AC=true
else
    ON_AC=false
fi

# 2. The Logic
# If currently on an "Extreme" mode (Saver or Perf), return to Balanced.
if [ "$current" == "power-saver" ] || [ "$current" == "performance" ]; then
    powerprofilesctl set balanced
    new_mode="balanced"
    icon=""

# If currently on "Balanced", decide based on charger.
else 
    if [ "$ON_AC" = true ]; then
        # === PLUGGED IN ===
        # Try to set Performance
        if powerprofilesctl list | grep -q "performance"; then
            powerprofilesctl set performance
            new_mode="performance"
            icon=""
        else
            # Fallback if laptop has no performance mode
            powerprofilesctl set balanced
            new_mode="balanced"
            icon=""
        fi
    else
        # === ON BATTERY ===
        # Set Power Saver
        powerprofilesctl set power-saver
        new_mode="power-saver"
        icon=""
    fi
fi

