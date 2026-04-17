# Hammerspoon Configuration Evaluation Report

**Date:** 2026-02-07  
**Scope:** All modules, lib, config, and documentation  
**Status:** Issues resolved (see changelog below)

---

## Changelog (Resolutions Applied)

- **Hotkey conflict**: Removed lg-monitor Hyper+1–4 (use Hammerflow F18+l+i+1/2/3/4); removed lg-monitor Hyper+T (conflicted with WezTerm)
- **README**: Updated directory structure, added module docs for audio-info, desktop-management, car-thing-bridge, minidsp, status-dashboard, diagnostics
- **CAR_THING_BRIDGE.md**: Created with API reference
- **status-dashboard**: Replaced `print()` with `logger.debug()`; use `utils.resolvePath()` for dock-detector
- **Cleanup**: Centralized in init.lua; removed per-module registration; added diagnostics.cleanup to central loop
- **errorHandler**: Added capture to car-thing-bridge (init failure), minidsp (daemon unreachable)
- **config.get()**: Refactored to use key map

---

## Executive Summary

The Hammerspoon configuration is **well-structured overall** with solid foundations: centralized config, consistent module patterns, structured logging, and debug infrastructure. Documentation is good but could be improved in a few areas. There are some organizational gaps and a few issues to address.

**Overall rating: B+** — Good organization, could be more consistent and complete.

---

## Strengths

### 1. Architecture & Structure

- **Clear separation of concerns**: `init.lua` is a thin orchestrator; logic lives in modules
- **Consistent module pattern**: All modules expose `init()`, `cleanup()`, and use `lib.logger`
- **Centralized configuration**: `config.lua` with `config.get()` keeps settings in one place
- **Explicit load order**: Modules array in `init.lua` documents dependencies
- **Proper cleanup**: `hs.cleanup` handlers registered for all modules

### 2. Infrastructure

- **lib/logger.lua**: Structured logging with file + console, per-module levels
- **lib/utils.lua**: Path resolution, file ops, env detection — well-documented
- **lib/error-handler.lua**: Error capture, categorization, DAP export
- **lib/debug.lua**: Tracing, breakpoints, Cursor IDE integration

### 3. Documentation

- **docs/README.md**: Solid overview, quick start, troubleshooting, development guide
- **docs/DESKTOP_MANAGEMENT.md**: Full feature docs, API, Hammerflow integration
- **docs/MINIDSP.md**: Clear API reference, config, status shape
- **docs/DEBUGGING*.md**: DAP integration, debug workflow
- **hammerflow.toml**: Inline comments for sections

---

## Gaps & Issues

### 1. Documentation Gaps

| Module | Status | Recommendation |
|--------|--------|----------------|
| **car-thing-bridge** | No dedicated doc | Add `docs/CAR_THING_BRIDGE.md` — API endpoints, macro config, feed config |
| **status-dashboard** | Not in README | Document in README under Modules; describe `showDashboard`, `getCompactStatus` |
| **diagnostics** | Not in README | Add to README; document `runDiagnostics`, health check, export |
| **audio-info** | Brief mention only | Add short section: menu bar display, CoreAudio fallback, C binary |
| **shortcut-overlay** | In README | Good — keep as is |
| **caffeine** | In README | Good — keep as is |

### 2. README vs Actual State

The **docs/README.md** directory structure is outdated:

```
# README says:
├── modules/
│   ├── window-management.lua
│   ├── app-launcher.lua
│   ├── caffeine.lua
│   ├── shortcut-overlay.lua
│   ├── lg-monitor.lua
│   └── home-assistant.lua

# Missing from README:
│   ├── audio-info.lua
│   ├── desktop-management.lua
│   ├── car-thing-bridge.lua
│   ├── minidsp.lua
│   ├── status-dashboard.lua
│   └── diagnostics.lua
```

Also missing from lib: `error-handler.lua`, `debug-helper.lua`, `debug-adapter/`.

### 3. Hotkey Conflict

**desktop-management** and **lg-monitor** both bind `Hyper+1`, `Hyper+2`, `Hyper+3`, `Hyper+4`:

- lg-monitor: HDMI 1–4 switch
- desktop-management: Switch to space 1–4

Because desktop-management loads after lg-monitor, **space switching wins** — LG HDMI shortcuts are overridden. Users may not realize this.

**Recommendation:**  
- Either move space switching to a prefix (e.g. `Hyper+Shift+1-9`)  
- Or move LG input switching to Hammerflow only (already available under `[l.i]`)  
- Or document the conflict and let the user choose

### 4. config.get() Design

`config.get()` uses a long if/else chain. Adding new config sections requires editing this function.

**Recommendation:** Use direct table access:

```lua
function config.get(moduleName)
    local key = moduleName:gsub("^%l", string.upper):gsub("([A-Z])", "_%1"):lower()
    -- Or simpler: maintain a map
    local map = {
        hyper = "hyper", apps = "apps", window = "window",
        shortcutOverlay = "shortcutOverlay", lgMonitor = "lgMonitor",
        minidsp = "minidsp", homeAssistant = "homeAssistant",
        logging = "logging", debug = "debug"
    }
    local key = map[moduleName]
    return key and config[key] or nil
end
```

Or just `return config[moduleName]` if keys match — but currently keys are camelCase (`homeAssistant`) while callers use `"homeAssistant"`, so it works. A small refactor could simplify.

### 5. Module-Level Documentation

Most modules have a one-line header comment. Some could use more:

- **car-thing-bridge**: No module header describing endpoints or flow
- **status-dashboard**: No header describing data sources or format
- **diagnostics**: Good header; could add "Integrations covered: HA, LG Monitor"

### 6. Hardcoded Paths

- **car-thing-bridge**: `~/dotfiles/car-thing/config/` — multiple fallbacks, but dotfiles is assumed
- **status-dashboard**: `~/dotfiles/scripts/lg-c5/dock-detector-simple` — should use `utils.resolvePath()`
- **config.lua**: `utils.resolvePath("scripts/archive/lg-server")` — good use of utils

### 7. Debug / Verbose Logging in Production

- **status-dashboard**: Uses `print()` in `getSystemStatus()` for "immediate visibility" — will clutter console
- **audio-info**: Some commented-out log lines (e.g. "Audio info updated successfully")

### 8. Duplicate Cleanup Registration

Some modules do **both**:

1. `table.insert(hs.cleanup, module.cleanup)` in their `init()`
2. Get registered in the main `init.lua` cleanup loop via `loadedModules`

The main cleanup in `init.lua` (lines 134–163) calls `module.cleanup()` for each loaded module. So modules that also do `table.insert(hs.cleanup, module.cleanup)` may run cleanup twice. Not harmful for most cleanup logic, but redundant.

**Recommendation:** Standardize on one approach — either per-module registration or central loop, not both.

### 9. Init Order / Dependencies

- **diagnostics** is loaded before modules but `diagnostics.init()` is called after modules
- **status-dashboard** is require'd after modules and initialized with `haModule`, `lgModule`, `diagnostics`
- **car-thing-bridge** has `init()` but is loaded in the modules loop — so it gets `init()` like others. Good.

### 10. Error Handling Consistency

- **home-assistant**, **lg-monitor**: Use `errorHandler.capture()` for failures
- **minidsp**: Uses `errorHandler` require but doesn't call `capture` on failures
- **car-thing-bridge**: No error handler usage
- **desktop-management**: No error handler

**Recommendation:** Use `errorHandler.capture()` for transient failures (network, config) in all integration modules.

---

## Recommendations (Prioritized)

### High Priority

1. **Document hotkey conflict** between desktop-management and lg-monitor — add to README Troubleshooting
2. **Update README directory structure** to include all current modules and lib files
3. **Add missing module docs** to README: audio-info, desktop-management, car-thing-bridge, minidsp, status-dashboard, diagnostics

### Medium Priority

4. **Create docs/CAR_THING_BRIDGE.md** — endpoints, macros, feed config
5. **Use utils.resolvePath()** in status-dashboard for dock-detector path
6. **Remove or reduce `print()` usage** in status-dashboard for production

### Low Priority

7. **Refactor config.get()** to be more maintainable
8. ** Standardize cleanup** — either per-module or central only
9. **Add errorHandler.capture** to minidsp, car-thing-bridge, desktop-management where appropriate
10. **Resolve hotkey conflict** — pick one binding scheme and document it

---

## Module-by-Module Summary

| Module | Lines | Docs | Init | Cleanup | Notes |
|--------|-------|------|------|---------|-------|
| window-management | 97 | ✓ README | ✓ | ✓ | Clean, focused |
| app-launcher | 62 | ✓ README | ✓ | ✓ | Clean |
| caffeine | 79 | ✓ README | ✓ | ✓ | Clean |
| audio-info | 374 | Partial | ✓ | ✓ | Complex; multiple fallbacks |
| shortcut-overlay | 382 | ✓ README | ✓ | ✓ | Good structure |
| lg-monitor | 456 | ✓ README | ✓ | ✓ | healthCheck, errorHandler |
| home-assistant | 364 | ✓ README | ✓ | ✓ | Good integration |
| desktop-management | 364 | ✓ Doc | ✓ | ✓ | Hotkey conflict with lg-monitor |
| car-thing-bridge | 302 | None | ✓ | ✓ | No errorHandler |
| minidsp | 298 | ✓ Doc | ✓ | ✓ | Good LuaDoc comments |
| status-dashboard | 376 | None | ✓ | n/a | print() in prod path |
| diagnostics | 372 | None | ✓ | ✓ | Comprehensive |

---

## Files Inventory

### lib/

| File | Purpose |
|------|---------|
| logger.lua | Structured logging |
| utils.lua | Path resolution, file ops |
| error-handler.lua | Error capture, DAP export |
| debug.lua | Tracing, breakpoints |
| debug-helper.lua | (Not reviewed in detail) |
| audio-format-query / .c | CoreAudio format query binary |

### docs/

| File | Purpose |
|------|---------|
| README.md | Main docs |
| DESKTOP_MANAGEMENT.md | Space management |
| MINIDSP.md | MiniDSP API |
| DEBUGGING*.md | Debug workflow |
| DAP_ADAPTER.md | Cursor integration |
| HAMMERSPOON_RESOURCES.md | (Not reviewed) |
| hammerflow-*.md | Command tree docs |

---

## Conclusion

The Hammerspoon config is production-ready and maintainable. The main improvements are:

1. **Documentation** — align README with current structure and add docs for newer modules
2. **Hotkey conflict** — document or resolve Hyper+1–4 between desktop-management and lg-monitor
3. **Minor consistency** — paths, error handling, cleanup, and logging

No urgent refactors are needed; incremental improvements will bring it to an A-level setup.
