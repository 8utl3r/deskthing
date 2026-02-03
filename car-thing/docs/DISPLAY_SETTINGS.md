# Car Thing Display Settings

## Screen brightness

The Car Thing screen brightness is controlled by the **device/LiteClient**, not by our app. To prevent the screen from constantly changing brightness (e.g. auto-adjust):

1. **During device setup:** When connecting the Car Thing to DeskThing, choose **Edit Config** (instead of Skip Setup) and look for brightness or display options. DeskThing docs note "More Description of config options coming soon."
2. **Device settings:** Check DeskThing Desktop → Settings → Device for any display/brightness options.
3. **Community:** Ask on [DeskThing Discord](https://discord.gg/uNS3dhj46D) for the current way to set fixed brightness on Car Thing.

Our app cannot set the device brightness from JavaScript—it runs inside a webview and has no access to device display APIs.
