# TrueNAS Scale UDP Issue - Root Cause & Solution

## The Problem: Why UDP Doesn't Work in TrueNAS Custom Apps

### Root Cause

**TrueNAS Scale Custom Apps use Kubernetes (k3s)** which has **known UDP forwarding limitations**:

1. **Kubernetes NodePort Services**: When you configure port forwarding in TrueNAS UI, it creates a Kubernetes NodePort service
2. **UDP Support is Limited**: Kubernetes NodePort services have **poor UDP support**, especially for game servers
3. **Network Translation Layer**: The Kubernetes networking layer (CNI) doesn't properly forward UDP packets, even though TCP works fine
4. **No Host Network Option**: TrueNAS Custom Apps UI **doesn't expose host network mode**, which is the standard workaround

### Why TCP Works But UDP Doesn't

- **TCP**: Kubernetes handles TCP connections well - it can track connections and properly forward them
- **UDP**: UDP is connectionless - Kubernetes networking layer struggles with stateless UDP packet forwarding
- **Game Servers**: Many game servers (Factorio, Minecraft, etc.) use UDP and hit this limitation

### Evidence from TrueNAS Community

From TrueNAS community forums, **others have encountered this exact issue**:

> "Having trouble with ports on my game server docker container" - User with UDP port 28015
> **Solution found**: Switch to "host network" mode
> 
> The issue: TCP ports worked fine, but UDP port failed despite proper router configuration
> Root cause: Kubernetes networking doesn't properly forward UDP

## Why TrueNAS Custom Apps Can't Fix This

1. **No Host Network UI Option**: TrueNAS Custom Apps interface doesn't provide a way to enable host network mode
2. **YAML Ignored**: Even if you add `network_mode: host` to Docker Compose YAML, TrueNAS may ignore it when converting to Kubernetes
3. **Kubernetes Limitation**: This is a fundamental Kubernetes networking limitation, not a TrueNAS bug

## The Proper Solution: Run Container Directly with Docker

Since TrueNAS Custom Apps can't properly handle UDP game servers, the **recommended approach** is to:

1. **Run the container directly with Docker** (bypassing TrueNAS Custom Apps)
2. **Use host network mode** (fixes UDP forwarding)
3. **Manage via shell** (use `docker` commands)

This is **not a hack** - it's the proper way to run game servers on TrueNAS Scale.

### Why This Works

- **Host Network Mode**: Bypasses Kubernetes networking entirely
- **Direct Port Access**: Container uses host ports directly (no translation layer)
- **UDP Works**: UDP packets flow directly from client → host → container

### This is a Known Pattern

Many TrueNAS Scale users run game servers this way:
- Factorio servers
- Minecraft servers  
- Other UDP-based game servers

They all use Docker directly with host network mode, not TrueNAS Custom Apps.

## Alternative Solutions (If You Must Use Custom Apps)

### Option 1: Use TrueCharts Apps (If Available)

TrueCharts provides better networking options for some apps, but Factorio isn't available there.

### Option 2: Use Ingress (Doesn't Help)

TrueNAS recommends using Traefik Ingress for apps, but:
- Ingress only works for HTTP/HTTPS (TCP)
- Doesn't help with UDP game servers
- Factorio needs raw UDP, not HTTP

### Option 3: Wait for TrueNAS Update

TrueNAS may add host network support to Custom Apps in the future, but:
- No timeline available
- May never come (Kubernetes limitation)
- Not worth waiting for

## Recommended Architecture

```
┌─────────────────────────────────────────┐
│ TrueNAS Scale                           │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ TrueNAS Custom Apps (Kubernetes) │  │
│  │ - HTTP/HTTPS apps (work fine)    │  │
│  │ - Use for web services           │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ Docker Direct (Host Network)     │  │
│  │ - Game servers (UDP)             │  │
│  │ - Factorio, Minecraft, etc.      │  │
│  │ - Managed via shell               │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Best Practice:**
- **Custom Apps**: Use for HTTP/HTTPS services (web apps, APIs)
- **Docker Direct**: Use for game servers, UDP services, or anything needing host network

## Implementation: Docker Direct Setup

### Step 1: Create Docker Compose File

Create `/mnt/boot-pool/apps/factorio/docker-compose.yml`:

```yaml
version: '3.8'

services:
  factorio:
    image: goofball222/factorio:latest
    container_name: factorio
    restart: unless-stopped
    network_mode: host
    environment:
      - FACTORIO_RCON_PASSWORD=your_password_here
      - FACTORIO_SAVE=my-save
    volumes:
      - /mnt/boot-pool/apps/factorio:/factorio
    mem_limit: 2g
    mem_reservation: 512m
    cpus: '2'
```

### Step 2: Use Docker Compose

```bash
cd /mnt/boot-pool/apps/factorio
docker-compose up -d
```

### Step 3: Auto-start on Boot

Create systemd service or use Docker's `--restart unless-stopped` (already in compose file).

## Why This is the Right Solution

1. **Works Reliably**: Host network mode properly forwards UDP
2. **Standard Practice**: Many TrueNAS users do this for game servers
3. **Not a Workaround**: This is the proper way to run UDP services
4. **Future-Proof**: Won't break with TrueNAS updates
5. **More Control**: Direct Docker management gives you full control

## Summary

**The Issue:**
- TrueNAS Custom Apps use Kubernetes
- Kubernetes has poor UDP forwarding support
- TrueNAS UI doesn't expose host network mode

**The Solution:**
- Run container directly with Docker
- Use host network mode
- Manage via shell/scripts

**This is not a bug or limitation of your setup** - it's a fundamental Kubernetes networking limitation that affects all TrueNAS Scale users running UDP game servers.

The Docker direct approach is the **recommended solution** used by the TrueNAS community for game servers.
