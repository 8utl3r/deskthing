# Home Assistant Configuration Export Checklist

## Files to Export
- [ ] configuration.yaml
- [ ] automations.yaml
- [ ] scripts.yaml
- [ ] groups.yaml
- [ ] scenes.yaml
- [ ] secrets.yaml (⚠️ Contains sensitive data)
- [ ] customize.yaml
- [ ] ui-lovelace.yaml
- [ ] themes.yaml (if you have custom themes)
- [ ] known_devices.yaml (if you want device history)

## Export Methods

### Method 1: File Editor (Easiest)
1. Install File Editor add-on if not already installed
2. Go to Settings → Add-ons → File editor
3. Open each file and copy contents
4. Save locally with same filename

### Method 2: Backup Download
1. Go to Settings → System → Server Controls
2. Click "Download backup"
3. Extract the backup archive
4. Copy config files from the extracted folder

### Method 3: SSH/Terminal (Advanced)
1. Access server via SSH or terminal
2. Navigate to /config directory
3. Copy files using scp or similar

## After Export
1. Place all files in the backup directory
2. Run `./bin/ha-analyze` to analyze your configuration
3. Compare with dotfiles and merge as needed
4. Update dotfiles with your existing setup

## Security Note
- Never commit secrets.yaml to git
- Be careful with API keys and passwords
- Use secrets.yaml.template for non-sensitive defaults
