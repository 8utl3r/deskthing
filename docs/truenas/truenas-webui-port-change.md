# TrueNAS Web UI Port Change

## Issue
TrueNAS Web UI uses ports 80 and 443 by default, which conflicts with Caddy reverse proxy.

## Solution
Move TrueNAS Web UI to ports 81 (HTTP) and 444 (HTTPS).

## New Access URLs
- **HTTP**: `http://192.168.0.158:81`
- **HTTPS**: `https://192.168.0.158:444`

## Revert (if needed)
```bash
midclt call system.general.update '{"ui_port": 80, "ui_httpsport": 443}'
```

## Note
After changing ports, you'll need to:
1. Access TrueNAS at the new port (81/444)
2. Restart the web service (usually automatic)
3. Then install Caddy on ports 80/443
