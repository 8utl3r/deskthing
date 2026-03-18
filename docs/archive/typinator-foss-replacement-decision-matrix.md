# Verified Decision Matrix: Typinator Replacement (FOSS, No Subscription)

## 1. Decision Context & Consequences

Replacing Typinator avoids subscription costs (and vendor lock-in) while preserving text expansion, abbreviations, snippets, and optional auto-correction. The decision affects daily typing efficiency, snippet portability (config as code), and long-term cost. Irreversible only in the sense of time spent migrating snippets; all options keep data local and editable.

---

## 2. Feature Matrix Comparison

| Dimension | Typinator (reference) | Espanso | MuttonText |
|-----------|------------------------|---------|------------|
| **License** | Proprietary | GPL-3.0 | MIT |
| **Cost** | One-time Mac Basic; subscription for iOS/Advanced | Free | Free |
| **macOS support** | 13+ (v10) | 10.13+ (Intel + Apple Silicon) | 12+ |
| **Config format** | GUI / proprietary | YAML (file-based) | GUI + Beeftext-compatible export |
| **Trigger → replace** | Yes | Yes | Yes |
| **Word-boundary / expand at break** | Yes | Yes (`word: true`, `left_word`/`right_word`) | Yes (strict or loose matching) |
| **Date/time in snippets** | Yes | Yes (date extension, offset, locale, timezone) | Yes (rich variables) |
| **Forms / multi-field input** | Yes | Yes (first-class forms, choice/list, pass to scripts) | Yes (input dialogs, nested combos) |
| **Shell/script in expansions** | Yes | Yes (shell + script extensions; macOS PATH caveat) | Yes (dynamic variables) |
| **Image expansion** | Yes | Yes (`image_path`; `$CONFIG` only for portability) | Not documented in README |
| **Cursor position after expand** | Yes | Yes (`$|$` cursor hint) | Not documented |
| **Rich text (e.g. markdown/HTML)** | Yes | Yes (markdown, HTML) | Not documented |
| **Auto-correction (typos)** | Yes | Via word-trigger matches (manual setup) | Not documented |
| **App exclusions** | Yes | No (per MuttonText comparison) | Yes |
| **Search / picker** | Yes | Yes (Search bar, e.g. ALT+Space) | Yes (Combo Picker) |
| **Packages / community snippets** | Shared libraries | Yes (Espanso Hub, `espanso install`) | No (Beeftext import) |
| **Sync / backup** | Local; team sharing via subscription | Config in `~/Library/Preferences/espanso` (git-friendly) | Automatic backups; config in Application Support |
| **Maturity / ecosystem** | Mature, commercial | Mature (13k+ GitHub stars), active | New (Beeftext-compatible, fewer users) |

*Sources: Ergonis Typinator pricing & learn; espanso.org docs (install, matches basics, extensions, forms); GitHub espanso/espanso, Muminur/MuttonText README.*

---

## 3. Pros and Cons

### Espanso

**Pros**

- Strongest FOSS feature parity with Typinator: date, shell, script, forms, image expansion, cursor hints, rich text, package ecosystem.
- YAML config is version-control and dotfile-friendly (fits your existing `~/dotfiles` workflow).
- Install via Homebrew (`brew install espanso`); no new install pattern.
- Cross-platform (macOS, Windows, Linux) if you ever switch or use multiple OSes.
- Documented, active project; large user base and Hub packages.

**Cons**

- No built-in app exclusions; you cannot disable expansion in specific apps (e.g. password managers) without workarounds.
- Shell/script on macOS had historical `$PATH` issues (GitHub #966, closed 2022); worth verifying on your macOS version.
- Snippets are manual or scripted migration from Typinator (no official Typinator importer).

### MuttonText

**Pros**

- App exclusions (pause in selected apps), matching Typinator behavior.
- Beeftext-compatible: can import/export Beeftext libraries and align with that ecosystem.
- Sub-50ms latency claim; Rust/Tauri stack.
- Automatic backups and system tray; GUI may feel closer to Typinator.
- MIT license (minimal reuse constraints).

**Cons**

- Newer project; smaller community and fewer examples/docs than Espanso.
- Image expansion, cursor hints, and rich text not clearly documented in README.
- No package hub; extension is via Beeftext compatibility and integrations (e.g. Claude).
- macOS + Linux only (no Windows yet).

### Typinator (stay, Mac-only)

**Pros**

- No change; full feature set including auto-correction and app exclusions.
- Mac Basic remains one-time purchase; no subscription required for Mac-only use.

**Cons**

- Subscription required for iOS and multi-device; perpetual Mac-only locks you to a single machine.
- Proprietary format and vendor dependency; not FOSS.

---

## 4. Strategic Alignment

- **Choose Espanso** if your primary constraint is **maximum FOSS feature parity** (dates, scripts, forms, images, packages) and you can accept **no native app exclusions** (or will use workarounds) and **config in YAML** (and migration effort).
- **Choose MuttonText** if your primary constraint is **app exclusions and a GUI similar to Typinator** and you can accept **less documented advanced features** and a **newer, smaller project**.
- **Stay on Typinator (Mac Basic one-time)** if your primary constraint is **zero migration** and Mac-only use is sufficient, and you can accept **proprietary, non-FOSS** and no iOS/cross-device without paying subscription.

---

## 5. Final Recommendation

**Recommendation: Espanso.**

- **Best fit for FOSS and no subscription:** Fully free, GPL-3.0, no paywall. Covers the bulk of Typinator-style use: abbreviations, dates, forms, shell/script, images, cursor position, rich text, and a package ecosystem.
- **Best fit for your setup:** You already use Homebrew and dotfiles; Espanso’s YAML config under `~/Library/Preferences/espanso` (or symlinked from `~/dotfiles`) fits version-controlled, reproducible config. You have Hammerspoon but no existing text-expander config in this repo; Espanso doesn’t conflict and is the path of least friction for a dedicated expander.
- **Decisive factors:** (1) Maturity and documentation (Espanso >> MuttonText for advanced features and community). (2) Script/shell and form capabilities are first-class and documented, matching Typinator’s “dynamic content” use cases. (3) The main gap—app exclusions—can be mitigated (e.g. avoid triggers that would fire in password fields, or use a narrow trigger prefix like `:abbr` in sensitive apps) unless you rely heavily on per-app on/off.
- **If app exclusions are critical:** Try MuttonText in parallel (install is a DMG); if its variable and form support meets your needs and exclusions matter more than packages/scripts, it’s a valid alternative. Prefer Espanso if you want scripts, Hub packages, and maximum doc/community support.

---

## 6. Verified Source Ledger

| Source | Type | What was used |
|--------|------|----------------|
| [Typinator – Pricing](https://ergonis.com/typinator/pricing) | Primary | Subscription vs one-time (Basic Mac), plan comparison, FAQ. |
| [Typinator – Main](https://ergonis.com/en/typinator/) | Primary | Core features: expansion, auto-correction, triggers, local storage, apps supported. |
| [Typinator – Triggers](https://ergonis.com/typinator/learn/triggers-for-expansions) | Primary | Expand at word break, trigger behavior. |
| [Espanso – GitHub](https://github.com/espanso/espanso) | Primary | License (GPL-3.0), description, platform. |
| [Espanso – Install macOS](https://espanso.org/docs/install/mac/) | Primary | macOS 10.13+, Intel/Apple Silicon, Homebrew, app bundle. |
| [Espanso – Matches basics](https://espanso.org/docs/matches/basics) | Primary | Static/dynamic matches, word triggers, cursor hints, images, forms link, rich text. |
| [Espanso – Extensions](https://espanso.org/docs/matches/extensions) | Primary | Date, shell, script, form, choice, random, clipboard, echo; image_path. |
| [Espanso – Forms](https://espanso.org/docs/matches/forms) | Primary | Form fields, controls, script/shell integration. |
| [MuttonText – README](https://raw.githubusercontent.com/Muminur/MuttonText/main/README.md) | Primary | Features, Beeftext compatibility, app exclusions, platform, install, comparison table. |
| [MuttonText – GitHub](https://github.com/Muminur/MuttonText) | Primary | License (MIT), description, platform. |
| [Espanso – PATH on macOS](https://github.com/espanso/espanso/issues/966) | Primary | Shell/script `$PATH` behavior on macOS (issue closed 2022). |

*Confidence: High for Espanso and Typinator (official docs and repo). High for MuttonText feature list (README); maturity/ecosystem is newer so noted in matrix and recommendation.*
