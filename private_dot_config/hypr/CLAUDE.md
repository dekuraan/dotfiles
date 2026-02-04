# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Hyprland wayland compositor configuration for a dual-monitor desktop setup using the Catppuccin Mocha theme.

## Key Commands

- **Reload config**: `hyprctl reload`
- **Check for errors**: `hyprctl rollinglog` (look for ERR/WARN lines after reload)
- **Inspect active rules**: `hyprctl binds`, `hyprctl keyword`

## Config Structure

```
hyprland.conf          ← Main config (sources mocha.conf)
mocha.conf             ← Catppuccin Mocha color palette (shared)
hyprlock.conf          ← Lock screen config (sources mocha.conf)
hyprpaper.conf         ← Wallpaper config
scripts/
  start_record.sh      ← Screen recording (wf-recorder)
  stop_record.sh       ← Stop recording
  weather.sh           ← OpenWeatherMap widget for status bar
```

`mocha.conf` is sourced by both `hyprland.conf` and `hyprlock.conf` to share color definitions.

## Windowrule Syntax (v0.53+)

The config uses the **new windowrule syntax** introduced in Hyprland v0.53. Key rules:

- Use `windowrule =` (not `windowrulev2`)
- Boolean fields require explicit values: `center on`, not `center`
- Matchers are space-separated: `match:class ^(Unity)$`, not `match:class:^(Unity)$`
- Floating matcher: `match:float yes` (NOT `match:floating`, NOT colon-separated like `match:float:1`)
- `center` is a static effect evaluated once at window open

## Hardware Context

- Monitors: DP-3 (2560x1440@240Hz), HDMI-A-1 (1920x1080@60Hz)
- Keyboard: Keychron Q2 (Caps Lock remapped to Ctrl)
- Terminal: ghostty
- Layout: dwindle
