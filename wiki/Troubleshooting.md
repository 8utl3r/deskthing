# Troubleshooting

This page provides solutions for common issues and problems with the dotfiles setup.

## Common Issues

### Installation Problems

#### Homebrew Installation Failed
```bash
# Error: Need sudo access on macOS
# Solution: Run Homebrew install script manually
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Permission Denied Errors
```bash
# Error: Permission denied for scripts
# Solution: Run with bash interpreter
bash -lc "./bin/link --dry-run"

# Or make executable
chmod +x bin/link
```

#### Xcode License Not Accepted
```bash
# Error: You have not agreed to the Xcode license
# Solution: Accept license
sudo xcodebuild -license accept
```

### Configuration Issues

#### Symlinks Not Working
```bash
# Check if files exist
ls -la ~/.zshrc
ls -la ~/.config/starship.toml

# Relink configurations
./bin/link --apply

# Check for broken symlinks
find ~ -type l -exec test ! -e {} \; -print
```

#### Configuration Not Loading
```bash
# Check shell configuration
zsh -c "echo $PATH"

# Test individual components
starship prompt
mise doctor
direnv status
```

#### Alfred Not Syncing
```bash
# Check Alfred preferences
cat ~/Library/Application\ Support/Alfred/prefs.json

# Should point to dotfiles
# "current": "/Users/pete/dotfiles/alfred/Alfred.alfredpreferences"

# Relink if needed
./bin/link --apply
```

### Application Issues

#### AeroSpace Not Responding
```bash
# Check if running
ps aux | grep aerospace

# Restart AeroSpace
osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || true
open -a AeroSpace

# Or use reload keybinding: Alt + R
```

#### Karabiner Not Working
```bash
# Check if running
ps aux | grep karabiner

# Check permissions
# System Preferences → Security & Privacy → Privacy → Accessibility
# Ensure Karabiner-Elements is enabled

# Restart Karabiner
open -a "Karabiner-Elements"
```

#### Hammerspoon Not Working
```bash
# Check if running
ps aux | grep hammerspoon

# Check permissions
# System Preferences → Security & Privacy → Privacy → Accessibility
# Ensure Hammerspoon is enabled

# Reload configuration
# Use Hyper + R keybinding or:
osascript -e 'tell application "Hammerspoon" to reload'
```

#### Docker Not Starting
```bash
# Check Docker Desktop status
open -a Docker

# Check if running
ps aux | grep docker

# Reset Docker if needed
# Docker Desktop → Troubleshoot → Reset to factory defaults
```

### Runtime Issues

#### mise Runtime Problems
```bash
# Check mise status
mise doctor

# Reinstall runtimes
mise install

# Check specific runtime
mise list node
mise list python
```

#### direnv Not Loading
```bash
# Check direnv status
direnv status

# Allow .envrc file
direnv allow

# Check file permissions
ls -la .envrc
```

#### fzf Not Working
```bash
# Check fzf installation
which fzf

# Reinstall fzf
brew reinstall fzf

# Set up shell integration
$(brew --prefix)/opt/fzf/install
```

## Debug Commands

### System Information
```bash
# Check macOS version
sw_vers

# Check system architecture
uname -m

# Check Homebrew status
brew doctor

# Check system resources
top -l 1 | head -10
```

### Configuration Status
```bash
# Check all symlinks
find ~ -maxdepth 1 -type l -ls

# Check configuration files
ls -la ~/.zshrc ~/.gitconfig ~/.config/

# Check application support directories
ls -la ~/Library/Application\ Support/ | grep -E "(Alfred|Docker|Cursor)"
```

### Git Status
```bash
# Check Git configuration
git config --list

# Check GitHub CLI status
gh auth status

# Check repository status
git status
git log --oneline -5
```

### Application Status
```bash
# Check running applications
ps aux | grep -E "(aerospace|karabiner|hammerspoon|docker)"

# Check installed applications
brew list --cask | sort

# Check application permissions
# System Preferences → Security & Privacy → Privacy
```

## Recovery Procedures

### Complete Reset
```bash
# Backup current state
cp -r ~/Library/Preferences ~/Desktop/Preferences-backup
cp -r ~/Library/Application\ Support ~/Desktop/ApplicationSupport-backup

# Remove all symlinks
find ~ -maxdepth 1 -type l -delete
find ~/.config -type l -delete

# Reinstall dotfiles
git clone https://github.com/8utl3r/petes-m3-setup.git ~/dotfiles
cd ~/dotfiles
./bin/link --apply
./macos/defaults.sh --apply
```

### Partial Reset
```bash
# Reset specific component
rm ~/.zshrc
./bin/link --apply

# Reset macOS defaults
./macos/defaults.sh --apply

# Reset specific application
rm -rf ~/Library/Application\ Support/Alfred
./bin/link --apply
```

### Configuration Repair
```bash
# Repair broken symlinks
find ~ -type l -exec test ! -e {} \; -exec rm {} \;

# Relink all configurations
./bin/link --apply

# Restart affected services
killall Dock
killall Finder
killall SystemUIServer
```

## Performance Issues

### Slow Shell Startup
```bash
# Check shell startup time
time zsh -i -c exit

# Profile shell startup
zsh -x -c exit 2>&1 | head -20

# Check for slow commands in .zshrc
grep -n "command" ~/.zshrc
```

### Slow Prompt
```bash
# Test Starship performance
time starship prompt

# Check Starship configuration
cat ~/.config/starship.toml

# Reduce timeout if needed
# command_timeout = 500
```

### High CPU Usage
```bash
# Check running processes
top -o cpu

# Check specific applications
ps aux | grep -E "(docker|cursor|alfred)"

# Restart problematic applications
killall Docker
open -a Docker
```

## Network Issues

### GitHub CLI Authentication
```bash
# Check authentication status
gh auth status

# Re-authenticate
gh auth login

# Check token permissions
gh auth token
```

### Homebrew Network Issues
```bash
# Check Homebrew status
brew doctor

# Update Homebrew
brew update

# Check network connectivity
ping -c 3 github.com
```

### Docker Network Issues
```bash
# Check Docker network
docker network ls

# Reset Docker network
docker network prune

# Check Docker daemon
docker info
```

## File Permission Issues

### Permission Denied
```bash
# Check file permissions
ls -la ~/.zshrc
ls -la ~/.config/

# Fix permissions
chmod 644 ~/.zshrc
chmod -R 755 ~/.config/
```

### Ownership Issues
```bash
# Check file ownership
ls -la ~/.zshrc

# Fix ownership
sudo chown -R $(whoami) ~/.zshrc
sudo chown -R $(whoami) ~/.config/
```

### Library Permissions
```bash
# Check Library permissions
ls -la ~/Library/Preferences/
ls -la ~/Library/Application\ Support/

# Fix Library permissions
sudo chown -R $(whoami) ~/Library/Preferences/
sudo chown -R $(whoami) ~/Library/Application\ Support/
```

## Getting Help

### Log Files
```bash
# Check system logs
log show --predicate 'process == "zsh"' --last 1h
log show --predicate 'process == "Docker"' --last 1h

# Check application logs
tail -f ~/Library/Logs/Alfred.log
tail -f ~/Library/Logs/Docker\ Desktop.log
```

### Diagnostic Information
```bash
# Generate diagnostic report
system_profiler SPSoftwareDataType
system_profiler SPHardwareDataType

# Check Homebrew diagnostics
brew doctor --verbose

# Check Git diagnostics
git config --list --show-origin
```

### Support Resources
- **GitHub Issues**: Create issue in dotfiles repository
- **Application Support**: Check individual application documentation
- **macOS Support**: Apple Support for system-level issues
- **Community**: macOS power-user communities

## Prevention

### Regular Maintenance
```bash
# Weekly maintenance
brew update && brew upgrade
./bin/snapshot

# Monthly maintenance
./macos/defaults.sh --apply
./bin/link --apply
```

### Backup Strategy
```bash
# Backup configurations
tar -czf ~/Desktop/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/dotfiles

# Backup system preferences
tar -czf ~/Desktop/preferences-backup-$(date +%Y%m%d).tar.gz ~/Library/Preferences/
```

### Monitoring
```bash
# Check system health
brew doctor
git status
./bin/link --dry-run
```
