# macOS Digital Audio Output Optimization

## Setup Overview
- **DAC/DSP**: MiniDSP DDRC-24 (room correction)
- **Amplifiers**: Fosi V3 mono blocks
- **Speakers**: KEF Q1 Meta
- **Connection**: USB via dock to MacBook Pro

## macOS Audio Configuration

### 1. Audio MIDI Setup (Critical)

The DDRC-24 should appear as a USB audio device. Configure it for optimal quality:

**Access**: Applications → Utilities → Audio MIDI Setup

**Recommended Settings**:
- **Sample Rate**: 48 kHz (or 96 kHz if your DDRC-24 supports it)
  - DDRC-24 supports up to 96 kHz
  - Higher sample rates reduce aliasing but increase CPU usage
  - 48 kHz is often the sweet spot for USB audio
- **Bit Depth**: 24-bit (or 32-bit if supported)
  - DDRC-24 supports 24-bit
  - Avoid 16-bit if possible
- **Format**: PCM (not compressed)

**To Set**:
1. Open Audio MIDI Setup
2. Select DDRC-24 from USB devices
3. Right-click → Configure Device
4. Set sample rate and bit depth
5. Ensure "Clock Source" is set to "Internal" (if available)

### 2. System Preferences Audio Settings

**System Settings → Sound → Output**:
- Select DDRC-24 as output device
- **Balance**: Center (50/50)
- **Volume**: Set to maximum (100%) - control volume via DDRC-24 or preamp
  - macOS volume control can reduce bit depth if not at 100%

### 3. CoreAudio Optimization (Terminal)

These settings can improve USB audio stability and reduce latency:

```bash
# Disable audio ducking (reduces automatic volume reduction)
defaults write com.apple.soundpref "AudioDucking" -bool false

# Reduce audio processing overhead
defaults write com.apple.audio.AudioMIDIServer "AudioDeviceSettings" -dict-add "AggregateDevice" -bool false

# Disable automatic sample rate switching (prevents clicks/pops)
# Note: This may require third-party tools or may not be directly settable
```

### 4. USB Audio Optimization

**USB Connection Quality**:
- Use a **direct USB connection** when possible (bypass dock if issues occur)
- Ensure USB port is USB 3.0+ for better power delivery
- Use a **powered USB hub** if dock doesn't provide adequate power
- Consider a **USB isolator** (e.g., iFi iDefender) to reduce ground loops and noise

**Dock Considerations**:
- Some docks introduce jitter or power issues
- Test direct USB connection vs. dock to compare
- Ensure dock firmware is up to date

### 5. Software Recommendations

#### Audio Hijack (Rogue Amoeba)
- **Purpose**: Route audio, apply EQ, monitor levels
- **Benefits**: 
  - Can force specific sample rates
  - Provides audio routing flexibility
  - Useful for system-wide EQ if needed
- **Cost**: ~$64

#### SoundSource (Rogue Amoeba)
- **Purpose**: Per-app audio routing and volume control
- **Benefits**:
  - Control audio per application
  - Monitor audio levels
  - Quick access to audio settings
- **Cost**: ~$39

#### Background Music (Free, Open Source)
- **Purpose**: Per-app volume control
- **Benefits**: Free alternative to SoundSource
- **GitHub**: https://github.com/kyleneideck/BackgroundMusic

### 6. macOS System Optimizations

#### Disable Audio Enhancements
Some macOS audio "enhancements" can degrade quality:

```bash
# Disable automatic audio adjustments
defaults write com.apple.soundpref "AudioEnhancement" -bool false
```

#### Reduce System Audio Processing
- **Disable**: System Sounds, UI sound effects
- **System Settings → Sound**: Uncheck "Play user interface sound effects"
- **System Settings → Sound**: Set alert volume to minimum

#### Power Management
USB audio can be affected by power management:

```bash
# Prevent USB power management (may require sudo)
# Check current settings:
pmset -g

# Consider disabling USB power saving (if issues occur):
# sudo pmset -a usb 0
```

**Note**: Only disable USB power management if you experience audio dropouts.

### 7. Application-Specific Settings

#### Music Apps (Spotify, Apple Music, etc.)
- **Spotify**: Settings → Audio Quality → Set to "Very High" (320 kbps)
- **Apple Music**: Settings → Music → Audio Quality → Set to "Lossless" or "Hi-Res Lossless"
- **Tidal/Qobuz**: Enable highest quality settings

#### Video Apps
- **VLC**: Preferences → Audio → Output module → "CoreAudio"
- **QuickTime**: Use highest quality audio tracks when available

### 8. DDRC-24 Specific Optimizations

#### MiniDSP Device Console
- Ensure DDRC-24 firmware is up to date
- Configure room correction filters properly
- Set input gain appropriately (avoid clipping)
- Use USB input mode (not analog)

#### USB Audio Class
- DDRC-24 uses USB Audio Class 2.0
- macOS should recognize it natively
- If not recognized, check USB cable and try different port

### 9. Troubleshooting

#### Audio Dropouts/Clicks/Pops
1. **Check sample rate matching**: Ensure all apps use same rate as DDRC-24
2. **USB power**: Try powered USB hub or direct connection
3. **CPU usage**: Close unnecessary apps
4. **USB cable**: Try different USB cable (quality matters for digital audio)

#### No Audio Output
1. **Audio MIDI Setup**: Verify DDRC-24 is selected and configured
2. **System Preferences**: Check output device selection
3. **DDRC-24**: Verify it's powered and USB connection is active
4. **Dock**: Try bypassing dock with direct USB connection

#### Low Volume
1. **macOS volume**: Set to 100%
2. **DDRC-24**: Check input/output gain settings
3. **Fosi amps**: Verify gain settings on mono blocks

#### Distortion
1. **Clipping**: Check input levels in DDRC-24
2. **Sample rate mismatch**: Ensure consistent sample rates
3. **USB bandwidth**: Close other USB devices if possible

### 10. Testing Audio Quality

#### Test Files
- Use high-resolution test tones (sine waves at various frequencies)
- Test with known high-quality recordings
- Compare direct USB vs. dock connection

#### Measurement Tools
- **Audio MIDI Setup**: Monitor sample rate and bit depth
- **MiniDSP Device Console**: Monitor input/output levels
- **Rogue Amoeba tools**: Monitor system audio levels

### 11. Advanced: Aggregate Devices

If you need to combine multiple audio sources:

1. Open Audio MIDI Setup
2. Click "+" → Create Aggregate Device
3. Select DDRC-24 and other devices
4. Set clock source to DDRC-24
5. Configure sample rates to match

**Note**: Aggregate devices can introduce latency and complexity. Only use if necessary.

## Quick Reference Checklist

- [ ] DDRC-24 configured in Audio MIDI Setup (48 kHz / 24-bit minimum)
- [ ] macOS system volume set to 100%
- [ ] System sound effects disabled
- [ ] USB connection stable (test direct vs. dock)
- [ ] DDRC-24 firmware up to date
- [ ] Room correction filters configured
- [ ] Music apps set to highest quality
- [ ] No audio processing/effects enabled in macOS
- [ ] USB power adequate (use powered hub if needed)

## Additional Resources

- **MiniDSP Support**: https://www.minidsp.com/support
- **Rogue Amoeba**: https://rogueamoeba.com/ (Audio Hijack, SoundSource)
- **Audio Science Review**: https://www.audiosciencereview.com/ (measurements and reviews)

## Notes

- USB audio quality is primarily determined by the DAC (DDRC-24), not macOS
- macOS CoreAudio is generally excellent for USB audio
- The dock may be the weakest link - test direct connection
- Room correction (DDRC-24) is more important than sample rate above 48 kHz
- 24-bit/48 kHz is often indistinguishable from higher rates in real-world listening


