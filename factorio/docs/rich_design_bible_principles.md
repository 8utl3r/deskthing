# Rich Design Bible — Part 1: UX/UI Principles

Principles from well-regarded experts, adapted for terminal/CLI and Rich. Use these as the ground truth when designing dashboards, CLIs, and TUIs.

**See also:** [Part 2: Applying principles in Rich](rich_design_bible_rich.md) | [Rich reference](rich_reference.md)

---

## 1. Nielsen’s 10 Usability Heuristics (NN/G)

Jakob Nielsen’s heuristics are broad rules of thumb for interaction design. Source: [nngroup.com/articles/ten-usability-heuristics](https://www.nngroup.com/articles/ten-usability-heuristics).

| # | Heuristic | In short |
|---|-----------|----------|
| 1 | **Visibility of system status** | Keep users informed with timely feedback. No consequential action without informing them. |
| 2 | **Match system and real world** | Use the user’s language and concepts; avoid jargon. Natural order of information. |
| 3 | **User control and freedom** | Clear “emergency exit” (undo, cancel). Users should not feel stuck. |
| 4 | **Consistency and standards** | Same words/actions mean the same thing. Follow platform and industry conventions. |
| 5 | **Error prevention** | Prefer preventing errors (constraints, good defaults) over fixing them after. |
| 6 | **Recognition rather than recall** | Make options and state visible; minimize what users must remember. |
| 7 | **Flexibility and efficiency** | Shortcuts for experts; still usable for novices. Allow tailoring. |
| 8 | **Aesthetic and minimalist design** | No irrelevant information. Every element competes with what matters. |
| 9 | **Help users recognize, diagnose, recover from errors** | Plain language, precise problem, constructive solution. Use familiar error visuals (e.g. bold, red). |
| 10 | **Help and documentation** | Easy to find, task-focused, concrete steps. Prefer in-context help. |

---

## 2. Don Norman’s principles of design

From *The Design of Everyday Things* and related work. Source: [principles.design](https://principles.design/examples/don-norman-s-principles-of-design), [Interaction Design Foundation](https://www.interaction-design.org/literature/topics/don-norman).

| Principle | Meaning |
|-----------|--------|
| **Discoverability** | Users can see what actions are possible and what the current state is. |
| **Feedback** | Clear, continuous information about the result of actions and current state. |
| **Conceptual model** | The design communicates a clear mental model so users understand and feel in control. |
| **Affordances** | Elements suggest how they can be used (e.g. a “button” looks actionable). |
| **Signifiers** | Cues (labels, icons, placement) that communicate meaning and guide action. |
| **Mapping** | Relationship between controls and effects is logical (spatial/temporal). |
| **Constraints** | Physical, logical, semantic, or cultural limits that guide correct use and reduce errors. |

---

## 3. Visual hierarchy (NN/G)

Visual hierarchy controls where attention goes. Source: [nngroup.com/articles/visual-hierarchy-ux-definition](https://www.nngroup.com/articles/visual-hierarchy-ux-definition).

- **Definition:** Organize elements so the eye is guided through content in order of intended importance.
- **Color and contrast:** Contrast in value/saturation (not hue alone) creates hierarchy. Bright/saturated for important; muted for secondary. Don’t rely on color alone (accessibility).
- **Scale:** Bigger = more attention. Use at most 3 sizes (e.g. header, subheader, body). Most important element is largest; limit “big” to 1–2 elements.
- **Grouping:** Proximity and common regions (borders, panels). Related items closer; more space around important groups. Containers (e.g. panels) clarify structure but use sparingly to avoid clutter.
- **Squint test:** Blur or squint at the design; the pattern of emphasis should match your intended hierarchy.

---

## 4. Terminal/CLI UX

From [clig.dev](https://clig.dev/), [better-cli.org](https://better-cli.org/), and CLI handbooks.

- **Consistency:** Internal (predictable patterns in your app) and external (e.g. `--help`, `--version`, exit codes).
- **Discoverability:** Good help text, descriptive names, concrete examples.
- **Feedback:** Show what’s happening, success/failure, and why something failed. Progress for long operations; confirmations for destructive actions.
- **Output:** Avoid meaning by color alone; pair color with text/labels. Use structure (headings, bullets, separators) instead of walls of text.
- **Language:** Direct, specific, user-oriented. Prefer “Could not connect to server” over raw error codes.

---

## 5. Accessibility (color and contrast)

From WCAG and accessibility guidelines (e.g. [WebAIM contrast](https://webaim.org/articles/contrast/), [W3C Understanding WCAG](https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-without-color.html)).

- **Don’t rely on color alone:** Color must not be the only way to convey information, indicate actions, or distinguish elements. Add text, icons, or patterns (e.g. “Error” + red).
- **Contrast:** Sufficient luminance difference between text and background. Aim for readable contrast even in limited-color or monochrome terminals.
- **Who benefits:** People with color blindness, low vision, or using monochrome/limited-color displays.

---

## 6. Summary checklist

Before shipping a Rich UI:

- [ ] **Status visible** — User always knows what’s happening (loading, success, error).
- [ ] **Language** — User’s words; no unexplained jargon.
- [ ] **Exit** — Clear way to stop or cancel (e.g. Ctrl+C mentioned).
- [ ] **Consistent** — Same terms and patterns; aligns with CLI conventions where relevant.
- [ ] **Recognition** — Options and state visible; minimal recall needed.
- [ ] **Minimal** — Only essential information; no decorative clutter.
- [ ] **Errors** — Plain language, cause, and next step; use signifiers (e.g. bold/red + “Error:”).
- [ ] **Hierarchy** — Contrast, scale, and grouping reflect importance (squint test).
- [ ] **Color** — Reinforces hierarchy and meaning but never the only cue.
