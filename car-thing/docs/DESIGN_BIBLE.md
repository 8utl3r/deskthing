# Car Thing Design Bible

Design system for the Dotfiles Car Thing app. Optimized for a 480×800 portrait touchscreen with physical dial and buttons.

---

## Philosophy

**Glanceable, thumb-friendly, low cognitive load.** The Car Thing sits at arm's length. Every element must be readable in under a second, touch targets must work with a thumb, and feedback must be immediate. Prioritize clarity over density.

---

## Screen & Constraints

| Property | Value |
|----------|-------|
| Resolution | 480×800 px (portrait) |
| Display | 4" touchscreen |
| Input | Touch + physical dial (scroll) + 4 preset buttons |
| Viewing distance | ~30–60 cm |

**Implications:**
- Min touch target: **44×44 px** (Apple HIG)
- Safe area: avoid notch/edge; keep critical controls in thumb zone (lower 60%)
- Max ~8–10 list items visible without scroll
- Dial scrolls; buttons map to presets or context actions

---

## Typography

| Token | Size | Weight | Use |
|-------|------|--------|-----|
| `text-display` | 20px | 700 | Page titles |
| `text-title` | 16px | 600 | Section headers |
| `text-body` | 14px | 400 | Primary content |
| `text-caption` | 12px | 400 | Secondary, hints |
| `text-micro` | 11px | 400 | Labels, metadata |

**Font:** System sans (SF Pro on Mac, fallback `ui-sans-serif`). No custom fonts—keeps bundle small and ensures readability.

---

## Color Palette

**Base (dark theme, OLED-friendly):**
- `bg-base`: #0f172a (slate-900)
- `bg-elevated`: #1e293b (slate-800)
- `bg-subtle`: #334155 (slate-700)
- `text-primary`: #f8fafc (slate-50)
- `text-secondary`: #cbd5e1 (slate-300)
- `text-muted`: #64748b (slate-500)

**Semantic:**
- `accent`: #3b82f6 (blue-500) — primary actions, links
- `success`: #22c55e (green-500)
- `warning`: #f59e0b (amber-500)
- `danger`: #ef4444 (red-500) — mute, delete, stop
- `muted-active`: #94a3b8 (slate-400) — toggles on

**Borders:** `border-subtle` #475569 (slate-600)

---

## Spacing Scale

| Token | Value | Use |
|-------|-------|-----|
| `space-1` | 4px | Tight inline |
| `space-2` | 8px | Between related items |
| `space-3` | 12px | Section padding |
| `space-4` | 16px | Card padding, gaps |
| `space-5` | 20px | Section margins |
| `space-6` | 24px | Page padding |

---

## Component Guidelines

### Buttons
- **Primary:** Filled accent; one per screen max.
- **Secondary:** Elevated bg, subtle border; default for actions.
- **Ghost:** Transparent, for low-emphasis (e.g. in lists).
- Min height 44px; padding 12–16px horizontal.

### Cards / Panels
- `bg-elevated`, `rounded-lg` (8px), padding `space-4`.
- Use for grouped controls; separate with `space-4` vertical.

### Toggles (Switch)
- Track: `bg-subtle` default, `danger` when on (e.g. mute).
- Thumb: 20px, white, clear travel.

### Lists
- Row height ≥ 44px; left-aligned label, right-aligned control or chevron.
- Dividers optional; prefer spacing.

### Empty States
- Icon + short message + optional hint. Never leave blank.

---

## Interaction Patterns

1. **Immediate feedback:** Every tap shows a state change within 100ms (optimistic UI when possible).
2. **Loading:** Skeleton or spinner; avoid blocking the whole screen.
3. **Errors:** Inline message near the control; retry if applicable.
4. **Confirmation:** Only for destructive actions; use a simple confirm dialog.
5. **Scroll:** Dial scrolls; ensure scrollable areas have visible scroll affordance.

---

## Accessibility

- **Contrast:** Text on bg ≥ 4.5:1 (WCAG AA). Muted text ≥ 3:1.
- **Touch:** No targets < 44×44 px.
- **Focus:** Visible focus ring for keyboard/dial navigation (if supported).
- **Motion:** Prefer `prefers-reduced-motion`; keep animations subtle.

---

## Do's and Don'ts

| Do | Don't |
|----|-------|
| One primary action per view | Crowd with many CTAs |
| Use semantic color (red = mute) | Use color alone to convey meaning |
| Group related controls | Scatter controls across the screen |
| Show empty states with guidance | Leave blank areas |
| Optimistic updates for fast actions | Wait for server before UI update |
| Keep labels short and scannable | Use long sentences |

---

## File Structure

```
src/design/
  tokens.css      # CSS variables
  components/     # Button, Card, Switch, etc.
  index.ts        # Exports
```

Use `@/design/components` for imports. See [DESIGN_COMPONENTS.md](DESIGN_COMPONENTS.md) for API reference.
