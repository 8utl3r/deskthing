# Applications

This page covers all applications managed by the dotfiles, including installation, configuration, and usage.

## Application Launcher

### Alfred 5

**Installation**: `brew install --cask alfred`  
**Configuration**: `alfred/Alfred.alfredpreferences` → `~/Library/Application Support/Alfred/Alfred.alfredpreferences`

#### Features
- **Application Launcher**: Quick app launching
- **File Search**: Find files and folders
- **Web Search**: Search engines integration
- **Workflows**: Custom automation
- **Clipboard History**: Access recent clipboard items
- **Calculator**: Quick calculations

#### Usage
- **Hotkey**: `Cmd + Space` (same as Spotlight)
- **Launch Apps**: Type app name and press Enter
- **File Search**: Type file name or path
- **Web Search**: Type search query
- **Calculator**: Type mathematical expressions

#### Configuration
```bash
# Alfred syncs with dotfiles automatically
# Preferences folder: ~/dotfiles/alfred/Alfred.alfredpreferences
# License and caches are gitignored
```

## Development & Productivity

### Cursor IDE

**Installation**: Manual download from cursor.sh  
**Configuration**: Multiple files in `cursor/` directory

#### Configuration Files
- `settings.json`: Editor preferences
- `keybindings.json`: Custom shortcuts
- `snippets/`: User code snippets
- `tasks.json`: Task configurations
- `argv.json`: Command-line arguments
- `locale.json`: Language settings

#### Key Features
- **AI-Powered**: Built-in AI assistance
- **VS Code Compatible**: Extensions and themes
- **Custom Font**: JetBrains Mono with ligatures
- **Terminal Integration**: WezTerm font consistency

#### Usage
```bash
# Launch Cursor
cursor .                   # open current directory
cursor file.js            # open specific file

# Extensions management
bin/cursor-extensions snapshot    # save current extensions
bin/cursor-extensions install     # install from saved list

# Key shortcuts
Ctrl+Cmd+T                # toggle terminal
Ctrl+Cmd+B                # toggle sidebar
Ctrl+Cmd+E                # focus explorer
```

### Docker Desktop

**Installation**: `brew install --cask docker-desktop`  
**Configuration**: Multiple files in `docker/` directory

#### Configuration Files
- `config.json`: CLI configuration
- `daemon.json`: Daemon settings
- `persisted-state.json`: UI preferences
- `window-management.json`: Window positions

#### Usage
```bash
# Launch Docker Desktop
open -a Docker

# CLI operations
docker ps                   # list containers
docker images              # list images
docker build -t myapp .    # build image
docker run -p 3000:3000 myapp  # run container

# Docker Compose
docker-compose up          # start services
docker-compose down        # stop services
```

### CrossOver

**Installation**: `brew install --cask crossover`  
**Purpose**: Windows compatibility for running Windows games and applications

#### Features
- **Windows Apps**: Run Windows applications on macOS
- **Gaming**: Play Windows games
- **User-Friendly**: GUI-based management
- **Wine-Based**: Uses Wine technology

#### Usage
- **Launch**: From Applications
- **Install Apps**: Use built-in installer
- **Manage Bottles**: Windows environments
- **Run Games**: Launch Windows games

## Gaming & Media

### Steam

**Installation**: `brew install --cask steam`  
**Purpose**: Gaming platform and library management

#### Features
- **Game Library**: Manage game collection
- **Cloud Sync**: Save game progress
- **Social Features**: Friends, chat, achievements
- **Steam Workshop**: Mods and community content

#### Usage
- **Launch**: From Applications
- **Install Games**: Download from Steam store
- **Play Games**: Launch from library
- **Note**: Requires Rosetta 2 (Intel compatibility)

### Sony PS Remote Play

**Installation**: `brew install --cask sony-ps-remote-play`  
**Purpose**: Play PlayStation games remotely

#### Features
- **Remote Gaming**: Play PS4/PS5 games on Mac
- **DualSense Support**: Use PlayStation controller
- **High Quality**: Stream games at high resolution

#### Usage
- **Launch**: From Applications
- **Connect**: Link to PlayStation console
- **Play**: Stream games remotely

### Stremio

**Installation**: `brew install --cask stremio`  
**Purpose**: Open-source media center

#### Features
- **Media Streaming**: Stream movies and TV shows
- **Add-ons**: Extensible with community add-ons
- **Cross-Platform**: Works on multiple devices

#### Usage
- **Launch**: From Applications
- **Install Add-ons**: Add streaming sources
- **Stream Content**: Watch movies and TV shows
- **Note**: Requires Rosetta 2 (Intel compatibility)

### Spotify

**Installation**: `brew install --cask spotify`  
**Purpose**: Music streaming service

#### Features
- **Music Streaming**: Access to millions of songs
- **Playlists**: Create and share playlists
- **Offline Mode**: Download for offline listening
- **Cross-Platform**: Sync across devices

#### Usage
- **Launch**: From Applications
- **Sign In**: Use Spotify account
- **Play Music**: Browse and play songs
- **Create Playlists**: Organize music

## Communication & Security

### Telegram

**Installation**: `brew install --cask telegram`  
**Purpose**: Secure messaging app

#### Features
- **Secure Messaging**: End-to-end encryption
- **File Sharing**: Send files and media
- **Group Chats**: Create and join groups
- **Cross-Platform**: Sync across devices

#### Usage
- **Launch**: From Applications
- **Sign In**: Use phone number
- **Send Messages**: Chat with contacts
- **Share Files**: Send documents and media

### Bitwarden

**Installation**: `brew install --cask bitwarden`  
**Purpose**: Password manager and vault

#### Features
- **Password Management**: Store and generate passwords
- **Secure Vault**: Encrypted password storage
- **Auto-Fill**: Automatic password filling
- **Cross-Platform**: Sync across devices

#### Usage
- **Launch**: From Applications
- **Sign In**: Use Bitwarden account
- **Store Passwords**: Save login credentials
- **Auto-Fill**: Use browser extension

### Discord

**Installation**: `brew install --cask discord`  
**Purpose**: Voice and text chat for communities

#### Features
- **Voice Chat**: High-quality voice communication
- **Text Chat**: Message channels and DMs
- **Screen Sharing**: Share screen during calls
- **Community Servers**: Join gaming communities

#### Usage
- **Launch**: From Applications
- **Sign In**: Use Discord account
- **Join Servers**: Connect to communities
- **Voice Chat**: Join voice channels

## System Utilities

### Hidden Bar

**Installation**: `brew install --cask hiddenbar`  
**Purpose**: Hide menu bar items to reduce clutter

#### Features
- **Menu Bar Management**: Hide/show menu bar items
- **Auto-Hide**: Automatically hide unused items
- **Customization**: Control which items to hide

#### Usage
- **Launch**: From Applications
- **Configure**: Choose items to hide
- **Auto-Hide**: Enable automatic hiding

### SlimHUD

**Installation**: `brew install --cask slimhud`  
**Purpose**: Replacement for volume, brightness, and keyboard backlight HUDs

#### Features
- **Volume Control**: Custom volume HUD
- **Brightness Control**: Custom brightness HUD
- **Keyboard Backlight**: Custom backlight HUD
- **Minimal Design**: Clean, unobtrusive interface

#### Usage
- **Launch**: From Applications
- **Configure**: Set preferences
- **Note**: Deprecated, will be disabled on 2026-09-01

### IINA

**Installation**: `brew install --cask iina`  
**Purpose**: Modern media player for macOS

#### Features
- **Video Playback**: Play various video formats
- **Audio Support**: Play audio files
- **Modern UI**: Clean, intuitive interface
- **Performance**: Hardware-accelerated playback

#### Usage
- **Launch**: From Applications
- **Open Files**: Drag and drop media files
- **Playback Controls**: Standard media controls

### Itsycal

**Installation**: `brew install --cask itsycal`  
**Purpose**: Menu bar calendar widget

#### Features
- **Calendar View**: Month view in menu bar
- **Event Integration**: Show calendar events
- **Quick Access**: Click to open full calendar
- **Customization**: Adjust appearance and behavior

#### Usage
- **Launch**: From Applications
- **Click Menu Bar**: Access calendar
- **Configure**: Set preferences

## Development & Tools

### Termius

**Installation**: `brew install --cask termius`  
**Purpose**: SSH client for remote server management

#### Features
- **SSH Connections**: Connect to remote servers
- **SFTP Support**: File transfer capabilities
- **Multiple Sessions**: Manage multiple connections
- **Cross-Platform**: Sync across devices

#### Usage
- **Launch**: From Applications
- **Add Servers**: Configure SSH connections
- **Connect**: Establish remote sessions
- **File Transfer**: Use SFTP for file management

### UTM

**Installation**: `brew install --cask utm`  
**Purpose**: Virtual machine platform for macOS

#### Features
- **Virtual Machines**: Run various operating systems
- **QEMU-Based**: Uses QEMU virtualization
- **ARM Support**: Native Apple Silicon support
- **Easy Setup**: User-friendly VM creation

#### Usage
- **Launch**: From Applications
- **Create VM**: Set up virtual machines
- **Install OS**: Install operating systems
- **Run VMs**: Launch virtual machines

### Raspberry Pi Imager

**Installation**: `brew install --cask raspberry-pi-imager`  
**Purpose**: SD card imaging tool for Raspberry Pi

#### Features
- **SD Card Imaging**: Write OS images to SD cards
- **Multiple OSes**: Support for various Raspberry Pi OSes
- **Easy Setup**: Simple imaging process
- **Validation**: Verify written images

#### Usage
- **Launch**: From Applications
- **Select OS**: Choose Raspberry Pi OS
- **Select SD Card**: Choose target storage
- **Write Image**: Create bootable SD card

## Network & IoT

### Tailscale

**Installation**: `brew install --cask tailscale-app`  
**Purpose**: Mesh VPN based on WireGuard

#### Features
- **Mesh VPN**: Connect devices securely
- **Zero-Config**: Easy setup and management
- **Cross-Platform**: Works on all devices
- **Access Control**: Fine-grained permissions

#### Usage
- **Launch**: From Applications
- **Sign In**: Use Tailscale account
- **Connect Devices**: Add devices to network
- **Access Resources**: Connect to remote resources

### Home Assistant

**Installation**: `brew install --cask home-assistant`  
**Purpose**: Smart home automation platform

#### Features
- **Home Automation**: Control smart devices
- **Local Control**: Run automation locally
- **Integrations**: Support for many devices
- **Customization**: Highly customizable

#### Usage
- **Launch**: From Applications
- **Setup**: Configure home automation
- **Add Devices**: Connect smart devices
- **Create Automations**: Set up automated routines

### NetSpot

**Installation**: `brew install --cask netspot`  
**Purpose**: Wi-Fi site survey and analysis

#### Features
- **Wi-Fi Analysis**: Analyze wireless networks
- **Site Survey**: Map Wi-Fi coverage
- **Troubleshooting**: Diagnose network issues
- **Performance Testing**: Test network performance

#### Usage
- **Launch**: From Applications
- **Scan Networks**: Analyze Wi-Fi networks
- **Create Maps**: Map network coverage
- **Troubleshoot**: Diagnose issues

## AI & Machine Learning

### LM Studio

**Installation**: `brew install --cask lm-studio`  
**Purpose**: Local LLM management and development

#### Features
- **Local LLMs**: Run large language models locally
- **Model Management**: Download and manage models
- **API Server**: Serve models via API
- **Chat Interface**: Interactive chat with models

#### Usage
- **Launch**: From Applications
- **Download Models**: Get LLM models
- **Start Server**: Run API server
- **Chat**: Interact with models

## Hardware Management

### Logi Options+

**Installation**: `brew install --cask logi-options+`  
**Purpose**: Logitech device management

#### Features
- **Device Configuration**: Customize Logitech devices
- **Macro Support**: Create custom macros
- **Button Mapping**: Remap device buttons
- **Battery Monitoring**: Monitor device battery

#### Usage
- **Launch**: From Applications
- **Connect Devices**: Pair Logitech devices
- **Configure**: Set up device preferences
- **Create Macros**: Set up custom macros

## Troubleshooting

### Common Issues

1. **App not launching**: Check if app is installed and permissions granted
2. **Configuration not loading**: Verify symlinks are correct
3. **Performance issues**: Check system resources and app requirements
4. **Permission errors**: Grant necessary permissions in System Preferences

### Debug Commands

```bash
# Check if app is installed
brew list --cask | grep app-name

# Check app permissions
# System Preferences → Security & Privacy → Privacy

# Reload configurations
./bin/link --apply

# Check symlinks
ls -la ~/.config/
ls -la ~/Library/Application\ Support/
```

### Manual Installations

Some applications require manual installation:
- **Xcode**: Download from App Store
- **WiiM Home**: Download from App Store
- **XCloud**: Download from Microsoft website
- **TestFlight**: Download from App Store
- **Pokit**: Download from App Store (iOS version)
- **iStatistica Pro**: Download from App Store
