# Home Assistant Configuration

## Overview
This directory contains Home Assistant configuration files for macOS dotfiles integration.

## Files
- `configuration.yaml` - Main Home Assistant configuration
- `automations.yaml` - Home automation rules
- `scripts.yaml` - Reusable automation scripts
- `groups.yaml` - Device grouping and organization
- `secrets.yaml` - Sensitive configuration data (not tracked in git)

## Integration with LG C5 Monitor
This configuration includes integration with the LG C5 monitor (192.168.0.39) using the webOS API.

## Usage
1. Install Home Assistant Companion app: `brew install --cask home-assistant`
2. Run the dotfiles link script to create symlinks
3. Configure Home Assistant Companion to connect to server at 192.168.0.105
4. Configure integrations on the Home Assistant server

## Network Requirements
- LG Connect Apps must be enabled on the TV
- TV and Mac must be on the same network
- Wake on LAN configured for power control
