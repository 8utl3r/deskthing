# Krita AI Diffusion – Setup and Use

Krita has **no built-in AI**. All AI features come from the **Krita AI Diffusion** plugin (Stable Diffusion inside Krita). Krita is installed via Homebrew (`scripts/Brewfile`).

## AI features (via plugin)

| Feature | What it does |
|--------|----------------|
| **Generate** | New image from text prompt (or from existing image). SD 1.5 and SDXL. |
| **Inpaint (Fill)** | Select an area → replace/remove content with AI; prompt steers the result. |
| **Outpaint** | Extend canvas; select empty area → fill with content that matches the image. |
| **Refine** | Strength slider: change existing content instead of full replace (e.g. style transfer, add detail). |
| **Live Painting** | AI interprets the canvas in real time as you paint. |
| **Control** | Guide generation with sketches, line art, depth maps, pose, segmentation. |
| **Upscale** | Super-resolution to 4K/8K+; optional “refine upscaled” with diffusion. |
| **Job queue** | Queue/cancel multiple generations. |
| **History** | Browse previous generations and prompts; re-apply or mix results. |

## Add the plugin

**Automated (dotfiles):** Plugin ZIP is kept in `downloads/krita-ai-diffusion/`. To (re)download latest and get a reminder to open Krita, run:

```bash
./scripts/krita/install-ai-diffusion-plugin.sh   # use existing zip
./scripts/krita/install-ai-diffusion-plugin.sh --update   # fetch latest then open Krita
```

Then in Krita:

1. **Install in Krita**  
   - Open Krita.  
   - **Tools → Scripts → Import Python Plugin from File…**  
   - Select the downloaded ZIP.  
   - When asked to enable the plugin, choose **Yes**.  
   - **Restart Krita.**  
   - When choosing the file, use the ZIP in `dotfiles/downloads/krita-ai-diffusion/` (or the path the script printed).

2. **Show the docker**  
   - **Create or open a document first** – dockers (including AI Image Generation) stay greyed out with no image open.  
   - **Settings → Dockers → ☑ AI Image Generation.**

3. **Configure backend**  
   In the AI Image Generation docker, click **Configure**. Choose one:

   - **Online Service (Interstice.cloud)** – Paid cloud GPU. No local install; sign in in browser. Token-based: e.g. €10 for 5,000 tokens; ~1 token per small live image, ~5–10 per 1024×1024, more for upscale/4K. [Pricing](https://www.interstice.cloud/service). Tokens don’t expire.  
   - **Local Managed Server** – Free. Plugin installs and runs the server on your Mac (GPU recommended; Apple Silicon uses MPS). Needs disk space (e.g. 10–50GB+ for models). Run `xcode-select --install` if you see `xcrun` errors.  
   - **Custom Server** – Free if you run [ComfyUI](https://github.com/comfyanonymous/ComfyUI) yourself (local or remote). See [ComfyUI setup for the plugin](https://docs.interstice.cloud/comfyui-setup).

## Use it

- **New image from text:** Create a document, type a prompt in the docker, click **Generate** (or **Shift+Enter**).  
- **Apply a result:** In the history, click **Apply** on a thumbnail (or double‑click) to put it on a new layer.  
- **Refine existing art:** Set **Strength** below 100% so the action becomes **Refine**; the canvas is used as input.  
- **Inpaint:** Make a selection, keep strength at 100% for **Fill**, or lower strength for variations of the selected content.  
- **Outpaint:** Expand canvas, select the new empty area, then Generate/Fill.  
- **Control (sketch/pose/depth):** Use **Add control layer** in the docker, then generate as usual.  
- **Upscale:** Switch docker workspace to **Upscale**, pick model and scale, click **Upscale**.  
- **Live:** Switch to **Live** workspace, press **Play**, paint; image updates as you work.

Full docs: [Krita AI Handbook (docs.interstice.cloud)](https://docs.interstice.cloud/).

---

## Product concept sketches and technical drawings

You’re logged into Interstice; the AI docker is your control panel. Below: how it works in plain terms, which settings to use, and two workflows (sketch-led and prompt-led).

### How it works in plain terms

1. **Prompt** = text you type. The AI uses it (and optionally your canvas/sketch) to generate an image.
2. **Generate** = “make an image from my prompt (and current canvas if any).” Uses tokens.
3. **Strength** = how much the current canvas affects the result. **100%** = ignore canvas, make something new from the prompt. **&lt;100%** = **Refine**: keep the canvas as base and change it (e.g. add detail, make it look like a technical drawing).
4. **Control layers** = “use this image to guide shape/layout.” You draw a sketch (or use an existing image), add a **Line Art** or **Scribble** control from it, then generate. The AI tries to match your lines and fill in the rest from the prompt.
5. **Apply** = take a result from the history and put it on a new layer so you can edit or use it as base for the next step.

So: you can work **prompt-only** (describe the product → Generate), or **sketch-first** (draw rough lines → add control layer → describe in prompt → Generate). For technical drawings, prompt style matters a lot (“technical drawing”, “blueprint”, “isometric”, etc.).

### Settings that matter (in the docker)

| Setting | What to pick for product/technical |
|--------|-------------------------------------|
| **Style** | A default or neutral style. Avoid heavy “art” styles if you want clean concept/technical look. |
| **Model** | **SDXL** or **Flux** (if available on Interstice) for cleaner, more consistent results. **SD 1.5** is fine and uses fewer tokens. |
| **Strength** | **100%** for a brand‑new image from prompt (or from your sketch via control). **50–70%** to **Refine** an existing sketch/image (e.g. “make this look like a technical drawing”). |
| **Resolution** | Match your canvas or use 1024×1024 to save tokens; go higher when you need detail. |

You can leave the rest at defaults until you want to experiment (negative prompt, steps, etc.).

### Workflow 1: Sketch-led (best for concept sketches)

1. Create or open a document. Draw a **rough sketch** of your product (outline, main shapes) on a layer. Black/dark lines on white/light background work best for control.
2. In the AI docker: **Add control layer** → choose **Line Art** or **Scribble** → create/select the layer with your sketch.
3. Optional: click **From image** (under the control layer) so the plugin derives a clean line version from your sketch.
4. In the **prompt** field, describe what it is and how it should look, e.g.  
   `product concept sketch, wireless speaker, matte plastic, studio lighting, clean lines, white background`
5. Keep **Strength** at **100%**. Click **Generate**. The AI will follow your lines and fill in the description.
6. Pick a result you like from the history and click **Apply**. Tweak the layer in Krita or run **Refine** (lower strength) to add more detail or change style.

### Workflow 2: Prompt-led (no sketch, or technical style)

1. Create a document at the size you want (e.g. 1024×1024).
2. Leave the canvas empty (or put a rough idea). No control layer needed.
3. In the **prompt** field, describe the product and the **drawing style**:
   - **Concept sketch:**  
     `product concept sketch, [product name], [material], [angle], clean lines, white background`
   - **Technical drawing:**  
     `technical drawing, blueprint style, [object], orthographic view, dimension lines, white background, engineering schematic`  
   Or: `isometric technical drawing of [product], line art, white background`
4. **Strength 100%** → **Generate**. Try a few generations; use **Apply** on the best, then **Refine** at 50–70% if you want to push it more “technical” or “sketchy” without redrawing.

### Example prompts (copy and change [brackets])

- **Concept:**  
  `product concept sketch, [desk lamp], metal and fabric, front view, clean lines, minimal, white background`
- **Technical:**  
  `technical drawing, [mechanical part], orthographic projection, dimension lines, blueprint, white background`
- **Isometric:**  
  `isometric view, [product], line drawing, technical illustration, white background`

### If the result is wrong style or messy

- Add style words to the prompt: `line drawing`, `clean lines`, `minimal`, `white background`, `no shading` (or `subtle shading` for concepts).
- For technical: `blueprint`, `engineering drawing`, `orthographic`, `isometric`, `schematic`.
- Use **Refine** with **Strength** around 50–70% and a prompt like `technical drawing style, clean lines` to nudge the current image toward that look.
- For sketch-led: make sure your control layer is **Line Art** or **Scribble** and the sketch layer is clearly visible; increase the control layer’s strength slider if the AI is ignoring your lines.
