# Car Thing Display Settings

## Screen brightness (keeps changing / auto-adjusting)

The Car Thing screen brightness is controlled by the **device/LiteClient**, not by our app. If brightness keeps changing (e.g. auto-adjust based on content or ambient light):

1. **Edit Config during setup:** When connecting the Car Thing to DeskThing, choose **Edit Config** (instead of Skip Setup). Look for brightness, display, or auto-brightness options. You may need to disconnect and re-run setup to access Edit Config.
2. **DeskThing Desktop:** Settings → Device — check for display/brightness toggles.
3. **LiteClient config:** The device runs LiteClient; its config may have brightness keys. Ask on [DeskThing Discord](https://discord.gg/uNS3dhj46D) for the exact config option to disable auto-brightness or set a fixed level.

Our app cannot set device brightness from JavaScript—it runs in a webview with no display API access.
