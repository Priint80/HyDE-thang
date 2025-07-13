#!/usr/bin/env bash

# Update package databases (optional, may require user prompt)
/usr/bin/pacman -Sy --noconfirm

echo "Installing applications..."
# Prefer yay (AUR helper). Install with --needed to skip if already installed.
for pkg in discord steam librewolf wofi kitty; do
    if command -v yay &>/dev/null; then
        # Try to install via yay (covers official repos and AUR)
        yay -S --needed --noconfirm "$pkg" || {
            echo "Package '$pkg' not found or failed to install via yay."
            echo "Consider installing it via Flatpak or another method."
        }
    else
        echo "yay not found. Attempting pacman for '$pkg'..."
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "$pkg already in official repos, installing with pacman."
            pacman -S --noconfirm "$pkg"
        else
            echo "Package '$pkg' not in official repos. Skipping or use Flatpak."
        fi
    fi
done

# Ensure Hyprland config directories exist
mkdir -p ~/.config/hypr

# Configure Hyprland keybindings
keybind_conf=~/.config/hypr/keybindings.conf
touch "$keybind_conf"

echo "Appending keybindings to $keybind_conf..."
# Only append each keybinding if it doesn't already exist in the file
grep -qxF "bind = SUPER, D, exec, discord" "$keybind_conf" || echo "bind = SUPER, D, exec, discord" >> "$keybind_conf"
grep -qxF "bind = SUPER, S, exec, steam" "$keybind_conf"   || echo "bind = SUPER, S, exec, steam" >> "$keybind_conf"
grep -qxF "bind = SUPER, Q, closewindow, activewindow" "$keybind_conf" || echo "bind = SUPER, Q, closewindow, activewindow" >> "$keybind_conf"
grep -qxF "bind = SUPER, Delete, killwindow, activewindow" "$keybind_conf" || echo "bind = SUPER, Delete, killwindow, activewindow" >> "$keybind_conf"
grep -qxF "bind = SUPER, B, exec, librewolf" "$keybind_conf" || echo "bind = SUPER, B, exec, librewolf" >> "$keybind_conf"
grep -qxF "bind = SUPER, A, exec, wofi" "$keybind_conf"    || echo "bind = SUPER, A, exec, wofi" >> "$keybind_conf"
grep -qxF "bind = SUPER, T, exec, kitty" "$keybind_conf"  || echo "bind = SUPER, T, exec, kitty" >> "$keybind_conf"

echo "Keybindings updated."

# Configure hypridle (idle timings and actions)
idle_conf=~/.config/hypr/hypridle.conf
touch "$idle_conf"

# Add or update the general block for locking (if not present)
if ! grep -qxF "general {" "$idle_conf"; then
    cat >> "$idle_conf" << 'EOF'
general {
    lock_cmd = loginctl lock-session    # Lock the session (keep display manager running)
}
EOF
    echo "Added general block to hypridle.conf"
fi

echo "Appending idle listeners to $idle_conf..."
# Dim screen after 120 seconds (2 min)
if ! grep -q "timeout = 120" "$idle_conf"; then
    cat >> "$idle_conf" << 'EOF'
listener {
    timeout = 120
    on-timeout = brightnessctl -s set 10   # Dim screen to 10%
    on-resume = brightnessctl -r          # Restore brightness on user input
}
EOF
    echo "Added listener: dim to 10% at 2 minutes"
fi

# Lock screen after 900 seconds (15 min)
if ! grep -q "timeout = 900" "$idle_conf"; then
    cat >> "$idle_conf" << 'EOF'
listener {
    timeout = 900
    on-timeout = loginctl lock-session    # Lock screen at 15 minutes
}
EOF
    echo "Added listener: lock screen at 15 minutes"
fi

# Turn off display (DPMS off) after 1200 seconds (20 min)
if ! grep -q "timeout = 1200" "$idle_conf"; then
    cat >> "$idle_conf" << 'EOF'
listener {
    timeout = 1200
    on-timeout = hyprctl dispatch dpms off  # Turn off display at 20 minutes
}
EOF
    echo "Added listener: turn off display at 20 minutes"
fi

# Suspend system after 1800 seconds (30 min)
if ! grep -q "timeout = 1800" "$idle_conf"; then
    cat >> "$idle_conf" << 'EOF'
listener {
    timeout = 1800
    on-timeout = loginctl suspend   # Suspend system at 30 minutes
}
EOF
    echo "Added listener: suspend at 30 minutes"
fi

echo "hypridle configuration updated."

echo "Setup complete. Please restart Hyprland or reload config for changes to take effect."
