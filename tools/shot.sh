#!/usr/bin/env bash
# tools/shot.sh <name> <route> [extra user args...]  -> /workspace/grok_fortune3k_shots/<name>.png
# Renders one screen under a private Xvfb with the GL compatibility renderer.
set -e
cd "$(dirname "$0")/.."
name="$1"; route="$2"; shift 2
out="/workspace/grok_fortune3k_shots/${name}.png"
save="/tmp/f3k_shot_save.json"
rm -f "$save"
if [ -f /tmp/f3k_shot_seed.json ]; then cp /tmp/f3k_shot_seed.json "$save"; fi
xvfb-run -a -s "-screen 0 1200x2000x24" "$HOME/bin/godot" --path . --rendering-driver opengl3 --resolution 1024x1792 --audio-driver Dummy -- \
  --route="$route" --shot="$out" --save="$save" --no-save "$@" 2>&1 | grep -E "ERROR|SCRIPT|shot saved|shot window" | grep -v "^\s*at:" | head -30
