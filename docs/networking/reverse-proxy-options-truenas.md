# Reverse Proxy Options for TrueNAS Scale

## Summary

**Caddy is NOT available as a native TrueNAS app.** You need to install it as a custom Docker app (which we've prepared).

## Options

### Option 1: Caddy (Custom App) ✅ RECOMMENDED
- **Pros**: Lightest weight (~50MB RAM), simplest config, automatic HTTPS
- **Cons**: Not in catalog, must install as custom app
- **Status**: Already prepared and ready to install

### Option 2: Traefik (TrueCharts)
- **Pros**: Native TrueCharts app, powerful features
- **Cons**: 
  - Requires moving TrueNAS Web UI ports (80/443 → 81/444)
  - Requires installing operators (cert-manager, prometheus-operator, cloudnative-pg)
  - Heavier resource usage
  - More complex configuration

### Option 3: Nginx Proxy Manager (Custom App)
- **Pros**: Web UI for management, popular choice
- **Cons**: Heavier than Caddy, requires database, not in official catalog

## Recommendation

**Stick with Caddy** - it's the simplest and lightest option, perfect for your low-RAM NAS. The custom app installation is straightforward.
