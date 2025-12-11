# Home Assistant API Export Summary

## Export Details
- **Server**: 192.168.0.105:8123
- **Export Date**: Thu Sep 11 21:41:15 CDT 2025
- **Export Method**: Home Assistant API

## Files Exported
- **automations_api.json**:       14 bytes
- **config_info.json**:     3648 bytes
- **entities.json**:   180851 bytes
- **events.json**:     1112 bytes
- **groups_api.json**:        0 bytes
- **history.json**:       14 bytes
- **logbook.json**:       14 bytes
- **scenes_api.json**:    31334 bytes
- **scripts_api.json**:       14 bytes
- **services.json**:    90130 bytes
- **automations_from_api.yaml**:        4 bytes
- **scripts_from_api.yaml**:        4 bytes

## Configuration Analysis
Run the following to analyze your exported configuration:

```bash
# Analyze the exported data
./bin/ha-analyze --backup-dir ./homeassistant/backup

# Compare with dotfiles
./bin/ha-analyze
```

## Next Steps
1. Review the exported JSON files
2. Convert relevant data to YAML format
3. Merge with your dotfiles configuration
4. Test and deploy updated configuration

## Notes
- JSON files contain raw API data
- YAML files are converted versions (if yq is available)
- Some configuration may need manual conversion
- Secrets are not included in API exports
