# Hammerspoon Official Resources & Documentation

## Official Documentation

### Primary Documentation Site
- **Main Documentation**: https://www.hammerspoon.org/docs/
- **API Index**: https://www.hammerspoon.org/docs/index.html
- **Getting Started Guide**: https://www.hammerspoon.org/go/

### In-App Documentation
- Use `hs.doc` module in Hammerspoon console:
  ```lua
  hs.doc.help("hs.application")  -- Get help for any module
  hs.doc.help("hs.webview")     -- Example: webview documentation
  ```

## GitHub Repositories

### Main Repository
- **Hammerspoon Core**: https://github.com/Hammerspoon/hammerspoon
  - Source code, issues, releases
  - Sample configurations: https://github.com/Hammerspoon/hammerspoon/tree/master/SampleConfigs

### Official Spoons (Plugins)
- **Spoons Repository**: https://github.com/Hammerspoon/Spoons
- **Spoons Website**: https://www.hammerspoon.org/Spoons/
  - Pre-built plugins/extensions
  - Examples: AClock, ReloadConfiguration, WindowHalfsAndThirds, etc.

## Community Resources

### Community-Driven Projects
- **Awesome Hammerspoon**: https://github.com/ashfinal/awesome-hammerspoon
  - Curated list of Hammerspoon configurations and resources
  - Examples, tutorials, and community contributions

### Support & Discussion
- **Discord Server**: https://discord.gg/hammerspoon
  - Real-time chat with community
  - Quick help and discussions
  
- **Google Group**: https://groups.google.com/forum/#!forum/hammerspoon
  - Mailing list for questions and discussions
  - Archive of past discussions

## Key Modules Reference

### UI & Windows
- `hs.webview` - HTML/CSS/JS windows (most flexible)
- `hs.canvas` - Advanced drawing API
- `hs.drawing` - Basic drawing primitives (deprecated)
- `hs.alert` - Simple alert messages
- `hs.chooser` - Searchable chooser dialog
- `hs.menubar` - Menu bar items
- `hs.notify` - System notifications

### System Control
- `hs.eventtap` - Low-level keyboard/mouse event capture
- `hs.hotkey` - Hotkey bindings
- `hs.window` - Window management
- `hs.application` - Application control
- `hs.screen` - Screen/monitor management

### Utilities
- `hs.timer` - Timed events
- `hs.http` - HTTP requests
- `hs.json` - JSON encoding/decoding
- `hs.fs` - File system operations

## Quick Links

- **Homepage**: https://www.hammerspoon.org/
- **Releases**: https://github.com/Hammerspoon/hammerspoon/releases
- **Wiki**: Check GitHub wiki for additional resources
- **Issues**: https://github.com/Hammerspoon/hammerspoon/issues

## Installation & Setup

1. Install via Homebrew: `brew install --cask hammerspoon`
2. Configuration location: `~/.hammerspoon/init.lua`
3. Reload config: `Hyper+R` or menu bar → Reload Config
4. Console: Menu bar icon → Console (for debugging)

## Tips

- Use `hs.inspect()` to debug variables: `print(hs.inspect(myTable))`
- Check console for errors after reloading config
- Most modules have examples in the official docs
- Spoons can be installed by downloading `.spoon` files to `~/.hammerspoon/Spoons/`


