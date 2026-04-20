#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# 1. Flatten Matugen v4.0 Nested JSON for Quickshell
# ------------------------------------------------------------------------------
# Updated to match your config.toml output path
QS_JSON="$HOME/.config/hypr/scripts/quickshell/qs_colors.json"

python3 -c '
import json
import sys
import os

def flatten_colors(obj):
    if isinstance(obj, dict):
        if "color" in obj and isinstance(obj["color"], str):
            return obj["color"]
        return {k: flatten_colors(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [flatten_colors(x) for x in obj]
    return obj

def _hex_to_rgb(h):
    h = h.strip()
    if h.startswith("#"):
        h = h[1:]
    if len(h) != 6:
        return None
    try:
        return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    except Exception:
        return None

def _rgb_to_hex(rgb):
    r, g, b = rgb
    r = max(0, min(255, int(r)))
    g = max(0, min(255, int(g)))
    b = max(0, min(255, int(b)))
    return f"#{r:02x}{g:02x}{b:02x}"

def _to_gray(hex_color):
    rgb = _hex_to_rgb(hex_color)
    if rgb is None:
        return hex_color
    r, g, b = rgb
    # sRGB luminance, keeps perceived brightness but removes hue
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return _rgb_to_hex((y, y, y))

def _rgb_to_hsl(r, g, b):
    r, g, b = r / 255.0, g / 255.0, b / 255.0
    mx = max(r, g, b)
    mn = min(r, g, b)
    l = (mx + mn) / 2.0
    if mx == mn:
        return 0.0, 0.0, l
    d = mx - mn
    s = d / (2.0 - mx - mn) if l > 0.5 else d / (mx + mn)
    if mx == r:
        h = (g - b) / d + (6.0 if g < b else 0.0)
    elif mx == g:
        h = (b - r) / d + 2.0
    else:
        h = (r - g) / d + 4.0
    h /= 6.0
    return h, s, l

def _hue2rgb(p, q, t):
    if t < 0.0:
        t += 1.0
    if t > 1.0:
        t -= 1.0
    if t < 1.0 / 6.0:
        return p + (q - p) * 6.0 * t
    if t < 1.0 / 2.0:
        return q
    if t < 2.0 / 3.0:
        return p + (q - p) * (2.0 / 3.0 - t) * 6.0
    return p

def _hsl_to_rgb(h, s, l):
    if s <= 0.000001:
        v = int(round(l * 255.0))
        return v, v, v
    q = l * (1.0 + s) if l < 0.5 else l + s - l * s
    p = 2.0 * l - q
    r = _hue2rgb(p, q, h + 1.0 / 3.0)
    g = _hue2rgb(p, q, h)
    b = _hue2rgb(p, q, h - 1.0 / 3.0)
    return int(round(r * 255.0)), int(round(g * 255.0)), int(round(b * 255.0))

def _mix(hex_a, hex_b, t):
    ra = _hex_to_rgb(hex_a)
    rb = _hex_to_rgb(hex_b)
    if ra is None or rb is None:
        return hex_a
    t = max(0.0, min(1.0, float(t)))
    r = ra[0] * (1.0 - t) + rb[0] * t
    g = ra[1] * (1.0 - t) + rb[1] * t
    b = ra[2] * (1.0 - t) + rb[2] * t
    return _rgb_to_hex((r, g, b))

def _tame_accent(hex_color, *, sat_mul, mix_with, mix_t):
    rgb = _hex_to_rgb(hex_color)
    if rgb is None:
        return hex_color
    h, s, l = _rgb_to_hsl(*rgb)
    s = max(0.0, min(1.0, s * sat_mul))
    rr, gg, bb = _hsl_to_rgb(h, s, l)
    out = _rgb_to_hex((rr, gg, bb))
    return _mix(out, mix_with, mix_t) if isinstance(mix_with, str) else out

def _sat(hex_color):
    rgb = _hex_to_rgb(hex_color)
    if rgb is None:
        return None
    _, s, _ = _rgb_to_hsl(*rgb)
    return s

def maybe_apply_monochrome(flat_data):
    # Toggle lives in ~/.config/hypr/scripts/settings.json
    settings_path = os.path.join(os.path.expanduser("~"), ".config/hypr/scripts/settings.json")
    try:
        with open(settings_path, "r") as sf:
            settings = json.load(sf)
    except Exception:
        settings = {}

    mode = (settings.get("matugenAccentMode") or "").strip().lower()
    mono_scope = (settings.get("matugenMonoScope") or "all").strip().lower()
    if settings.get("matugenMonochrome", False):
        mode = "monochrome"
    if mode == "":
        mode = "balanced"

    # Only desaturate accent tokens; keep surfaces/text as-is.
    accent_keys = [
        "blue", "sapphire", "peach", "green", "red",
        "mauve", "pink", "yellow", "maroon", "teal",
    ]
    if mode == "monochrome":
        # Monochrome scopes:
        # - all: desaturate everything (surfaces + accents)
        # - accents: only accent tokens become grayscale
        # - surfaces: only surfaces/text become grayscale (accents stay colorful)
        if mono_scope == "accents":
            for k in accent_keys:
                v = flat_data.get(k)
                if isinstance(v, str) and v.startswith("#") and len(v) == 7:
                    flat_data[k] = _to_gray(v)
            return flat_data

        if mono_scope == "surfaces":
            surface_keys = [
                "base", "mantle", "crust",
                "text", "subtext0", "subtext1",
                "surface0", "surface1", "surface2",
                "overlay0", "overlay1", "overlay2",
            ]
            for k in surface_keys:
                v = flat_data.get(k)
                if isinstance(v, str) and v.startswith("#") and len(v) == 7:
                    flat_data[k] = _to_gray(v)
            return flat_data

        # default: mono_scope == "all"
        for k, v in list(flat_data.items()):
            if isinstance(v, str) and v.startswith("#") and len(v) == 7:
                flat_data[k] = _to_gray(v)
        return flat_data

    if mode == "balanced":
        base = flat_data.get("base", "#000000")
        # Keep a few "main" accents faithful to Matugen; tame the rest.
        # Also keep peach/teal/green so Volume/System/Battery stay colorful.
        keep = {"blue", "mauve", "red", "peach", "teal", "green"}  # primary-ish + system highlights + error
        for k in accent_keys:
            if not isinstance(flat_data.get(k), str):
                continue
            if k in keep:
                continue
            # Reduce saturation and blend slightly towards base for harmony.
            flat_data[k] = _tame_accent(flat_data[k], sat_mul=0.35, mix_with=base, mix_t=0.22)

        # If Matugen emits very low-chroma secondary/tertiary (common on B/W wallpapers),
        # derive them as harmonious variants of primary so modules do not look "stuck gray".
        primary = flat_data.get("blue") or flat_data.get("mauve")
        if isinstance(primary, str):
            for k, (sat_mul, mix_t) in {
                "green": (0.75, 0.08),
                "teal": (0.60, 0.14),
                "peach": (0.50, 0.20),
            }.items():
                v = flat_data.get(k)
                if not isinstance(v, str):
                    continue
                s = _sat(v)
                if s is not None and s < 0.10:
                    flat_data[k] = _tame_accent(primary, sat_mul=sat_mul, mix_with=base, mix_t=mix_t)
        return flat_data

    # fallback: do nothing
    return flat_data

target_file = sys.argv[1]
try:
    with open(target_file, "r") as f:
        data = json.load(f)
    
    flat_data = flatten_colors(data)
    flat_data = maybe_apply_monochrome(flat_data)
    
    # Atomic write so QML never reads partial JSON mid-write.
    tmp_file = target_file + ".tmp"
    with open(tmp_file, "w") as f:
        json.dump(flat_data, f, indent=4)
    os.replace(tmp_file, target_file)
        
except FileNotFoundError:
    pass
except Exception as e:
    print(f"Error flattening JSON: {e}")
' "$QS_JSON"

# ------------------------------------------------------------------------------
# 2. Flatten Matugen v4.0 Output in Standard Text Configs
# ------------------------------------------------------------------------------
# If Tera dumped {"color": "#hex"} into your text files, this strips it to #hex.
TEXT_FILES=(
    "$HOME/.config/hypr/scripts/quickshell/qs_colors.json"
    "$HOME/.config/kitty/kitty-matugen-colors.conf"
    "$HOME/.config/nvim/matugen_colors.lua"
    "$HOME/.config/cava/colors"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/rofi/theme.rasi"
    "$HOME/.config/rofi/matugen-palette.rasi"
    "$HOME/.cache/matugen/colors-gtk.css"
    "$HOME/.config/qt5ct/colors/matugen.conf"
    "$HOME/.config/qt6ct/colors/matugen.conf"
    "$HOME/.config/qt5ct/qss/matugen-style.qss"
    "$HOME/.config/qt6ct/qss/matugen-style.qss"
    "$HOME/.config/hypr/colors.conf"
)

for file in "${TEXT_FILES[@]}"; do
    # Check if file exists and we have write permissions (avoids sudo password hangs on SDDM)
    if [ -f "$file" ] && [ -w "$file" ]; then
        # Looks for {"color": "#abcdef"} and replaces it with #abcdef
        sed -i -E 's/\{[[:space:]]*"color":[[:space:]]*"([^"]+)"[[:space:]]*\}/\1/g' "$file"
    elif [ -f "$file" ]; then
        echo "Warning: No write permission for $file (Skipping text clean-up)"
    fi
done

# ------------------------------------------------------------------------------
# 3. Reload System Components
# ------------------------------------------------------------------------------

# Keep Rofi launcher background in sync with current wallpaper.
# Quickshell wallpaper picker already writes /tmp/lock_bg.png; we mirror to a stable path.
if [ -f /tmp/lock_bg.png ]; then
    mkdir -p "$HOME/.config/rofi/images"
    cp -f /tmp/lock_bg.png "$HOME/.config/rofi/images/wallpaper.png" 2>/dev/null || true

    # Also generate a small, fixed-size image for fast rofi startup.
    # Doing this here avoids any delay when opening rofi.
    if command -v magick >/dev/null 2>&1; then
        # Make it taller than the rofi window so resizing lines won't rescale/tear the wallpaper.
        magick /tmp/lock_bg.png -resize 1200x900^ -gravity center -extent 1200x900 \
            "$HOME/.config/rofi/images/wallpaper_rofi.png" 2>/dev/null || true
    else
        cp -f /tmp/lock_bg.png "$HOME/.config/rofi/images/wallpaper_rofi.png" 2>/dev/null || true
    fi
fi

# Reload Kitty instances
killall -USR1 kitty

# Reload CAVA
# ALWAYS rebuild the final config file from the base and newly generated colors
cat ~/.config/cava/config_base ~/.config/cava/colors > ~/.config/cava/config 2>/dev/null

# Tell CAVA to reload the config ONLY if it is currently running
if pgrep -x "cava" > /dev/null; then
    killall -USR1 cava
fi

# Restart swayosd-server in the background and disown it so the script doesn't hang
killall swayosd-server 2>/dev/null
swayosd-server --top-margin 0.9 --style "$HOME/.config/swayosd/style.css" > /dev/null 2>&1 &
disown

# GTK Live-Reload Hack
# Rapidly toggles the global theme to force GTK3 and GTK4 apps to flush 
# their caches and read the newly generated Matugen CSS.
if command -v gsettings &> /dev/null; then
    # GTK3 apps
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.05
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    
    # GTK4 / Libadwaita apps
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

