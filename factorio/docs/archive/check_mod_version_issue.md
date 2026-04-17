# FV Embodied Agent Mod - Remote Interface Issue

## Current Status
- ✅ Mod file installed: `fv_embodied_agent_0.1.3.zip`
- ✅ Mod enabled in `mod-list.json`
- ✅ Mod loading in server logs
- ❌ Remote interface not available: "Unknown interface: fv_embodied_agent"

## Possible Causes

1. **Version 0.1.3 may not have remote interface support**
   - This is an early version (0.1.3)
   - Remote interface might have been added in a later version
   - Check mod portal for latest version

2. **Remote interface requires specific initialization**
   - May need to be in an active game session
   - May need specific game state
   - May require mod settings to be configured

3. **Interface name might be different**
   - Could be registered with a different name
   - Check mod source code for actual interface name

## Next Steps

1. **Check mod portal for latest version:**
   - https://mods.factorio.com/mod/fv_embodied_agent
   - See if there's a newer version with remote interface support

2. **Check mod source code:**
   - Look for `remote.add_interface` calls
   - Verify the interface name

3. **Try extracting and examining the mod:**
   ```bash
   # On TrueNAS
   cd /mnt/boot-pool/apps/factorio/mods
   unzip -l fv_embodied_agent_0.1.3.zip | grep -i "control\|remote"
   ```

4. **Check if mod needs configuration:**
   - Some mods require settings to be enabled
   - Check mod settings in game or config files

## Alternative Approach

If remote interface isn't available in this version, we could:
- Update to a newer mod version
- Use a different mod that has remote interface support
- Work directly with Factorio's Lua API if the mod provides other access methods
