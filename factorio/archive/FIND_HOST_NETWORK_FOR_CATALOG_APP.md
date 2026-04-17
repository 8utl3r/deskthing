# Finding Host Network Setting for Catalog Apps (n8n)

## The Issue

You're looking at the n8n app's **Edit** screen, which shows a "Network Configuration" section with only:
- WebUI Port
- Broker Port

These are **port binding** settings (inbound access), not the **network mode** setting (outbound access) that we need.

## The Solution

According to the [TrueNAS Custom App Screens documentation](https://www.truenas.com/docs/scale/scaleuireference/apps/installcustomappscreens/), the **Host Network** setting is available in the **Network Configuration** section, but **it is only available for**:

1. **Custom Apps** (apps installed via "Custom App" or "Install via YAML")
2. **Converted Apps** (catalog apps that have been converted to custom apps)

**⚠️ Important**: The documentation does not mention any other way to enable Host Network for catalog apps. There is no API method or hidden setting documented. Converting to a custom app appears to be the **only documented method**.

## Steps to Enable Host Network for n8n

### Option 1: Convert n8n to Custom App (Recommended)

1. Go to **Apps** → **Installed**
2. Select **n8n** from the applications table
3. In the **Application Info** widget, click the **⋮** (three dots) menu
4. Click **Convert to custom app**
5. Confirm the conversion (⚠️ **Warning**: This is a one-time, permanent operation)
6. After conversion, click **Edit** on the n8n app
7. Navigate to the **Network Configuration** section
8. You should now see a **Host Network** checkbox
9. **Enable** the **Host Network** checkbox
10. Click **Save**
11. Restart the n8n app

### Option 2: Check All Tabs/Sections in Edit Screen (Unlikely to Work)

Before converting, you can try (though the documentation suggests this won't work for catalog apps):

1. In the n8n **Edit** screen, scroll through **all sections** in the right-side navigation panel
2. Look for:
   - **Network Configuration** (you're already here - only shows port settings)
   - **Advanced Settings** (if available)
   - **Container Configuration**
   - **Security Context Configuration**
3. Check if **Host Network** appears in any of these sections
4. **Note**: Based on documentation, catalog apps don't expose this option. If not found, you'll need to proceed with Option 1 (convert to custom app)

### Option 3: Use YAML Editor (Advanced)

If the UI doesn't show the option, you can:

1. Convert to custom app (as in Option 1)
2. In the Edit screen, look for a **YAML** tab or **Advanced** section
3. Edit the Docker Compose YAML directly to add:
   ```yaml
   network_mode: host
   ```

## What Host Network Does

According to the documentation:

> **Host Network**: Select to bind the container to the TrueNAS host network. When bound to the host network, the container does not have a unique IP-address, so port-mapping is disabled.

This means:
- ✅ The container can directly access the local network (192.168.0.x)
- ✅ The container can reach your Mac at `192.168.0.30:8080`
- ❌ Port mapping settings become disabled (but that's fine - the container uses host ports directly)

## After Enabling Host Network

1. **Restart** the n8n app
2. Test the connection from n8n to your Mac:
   - The n8n workflow should now be able to reach `http://192.168.0.30:8080/execute-action`
3. Verify the patrol workflow works end-to-end

## References

- [TrueNAS Custom App Screens Documentation](https://www.truenas.com/docs/scale/scaleuireference/apps/installcustomappscreens/)
- [Docker Host Network Documentation](https://docs.docker.com/engine/network/drivers/host/)
