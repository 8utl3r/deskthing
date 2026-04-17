# n8n Setup Research

## Overview

n8n is an open-source workflow automation tool that allows you to connect different services and automate tasks. It's similar to Zapier or Make.com but can be self-hosted for full control over your data and workflows.

## Installation Options

### 1. n8n Cloud (Managed Service)
- **Pros**: No setup, automatic updates, managed infrastructure
- **Cons**: Subscription costs, less control
- **Best for**: Quick start, minimal maintenance needs
- **Cost**: Paid plans available at [n8n.cloud](https://n8n.cloud)

### 2. Self-Hosted Options

#### Option A: Docker (Recommended)
**Status**: ✅ Docker Desktop already installed in dotfiles

**Requirements**:
- Docker Desktop (already installed via `cask "docker-desktop"`)
- Docker Compose (included with Docker Desktop)
- ~500MB disk space for container
- Persistent volume for workflow data

**Basic Setup**:
```bash
# Create data directory
mkdir ~/.n8n

# Run n8n container
docker run -it --rm \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Access**: `http://localhost:5678`

#### Option B: Docker Compose (Production-Ready)
**Recommended for**: Persistent setup with configuration management

**docker-compose.yml example**:
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
    volumes:
      - ~/.n8n:/home/node/.n8n
      - ~/.n8n/.n8n:/home/node/.n8n
```

**Benefits**:
- Easy to start/stop: `docker-compose up -d`
- Configuration via environment variables
- Automatic restart on system reboot
- Can be version-controlled in dotfiles

#### Option C: npm Installation
**Requirements**:
- Node.js 18.17.0 or later
- npm

**Setup**:
```bash
npm install -g n8n
n8n
```

**Pros**: Direct installation, no Docker needed
**Cons**: Requires Node.js management, less isolated

## System Requirements

### Minimum
- **CPU**: 1 core
- **RAM**: 2GB (4GB recommended)
- **Disk**: 500MB for container + space for workflow data
- **Network**: Port 5678 available

### Recommended
- **CPU**: 2+ cores
- **RAM**: 4GB+
- **Disk**: 5GB+ for workflows and data
- **Network**: HTTPS with reverse proxy for production

## Configuration Considerations

### Security Settings

**Basic Authentication** (Required for production):
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=your_username
N8N_BASIC_AUTH_PASSWORD=your_secure_password
```

**Environment Variables**:
- `N8N_HOST`: Hostname (default: localhost)
- `N8N_PORT`: Port (default: 5678)
- `N8N_PROTOCOL`: http or https
- `N8N_METRICS`: Enable metrics collection
- `N8N_LOG_LEVEL`: debug, info, warn, error

### Data Persistence

**Default Location**: `~/.n8n/`
- Contains workflows, credentials, execution data
- Should be backed up regularly
- Can be moved to custom location via volume mount

**Backup Strategy**:
```bash
# Create backup
tar czf n8n-backup-$(date +%F).tar.gz ~/.n8n

# Restore backup
tar xzf n8n-backup-YYYY-MM-DD.tar.gz -C ~/
```

## Integration with Dotfiles

### Recommended Structure

```
dotfiles/
  n8n/
    docker-compose.yml          # Docker Compose configuration
    README.md                   # Setup and usage documentation
    .env.example                # Environment variable template
```

### Symlink Strategy

**Note**: n8n data directory (`~/.n8n`) should NOT be symlinked as it contains runtime data that Docker needs to write to. However, configuration files can be managed:

- `docker-compose.yml` → Can be in dotfiles, run from there
- `.env` file → Can be in dotfiles (add to `.gitignore` if contains secrets)
- Documentation → In `n8n/README.md`

### Docker Compose Location Options

**Option 1**: Run from dotfiles directory
```bash
cd ~/dotfiles/n8n
docker-compose up -d
```

**Option 2**: Run from home directory with symlinked config
- Symlink `docker-compose.yml` to `~/.n8n/docker-compose.yml`
- Run from `~/.n8n/`

**Recommendation**: Option 1 (run from dotfiles) for better version control

## Setup Steps for Your Environment

### 1. Create n8n Directory Structure
```bash
mkdir -p ~/dotfiles/n8n
cd ~/dotfiles/n8n
```

### 2. Create docker-compose.yml
Create file with production-ready configuration including:
- Basic auth
- Volume persistence
- Restart policy
- Environment variables

### 3. Create .env File (Optional)
For sensitive configuration:
```bash
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password_here
```

### 4. Start n8n
```bash
docker-compose up -d
```

### 5. Access Web UI
Open `http://localhost:5678` in browser

### 6. Initial Setup
- Create admin account (if not using basic auth)
- Configure first workflow
- Test with a simple automation

## Production Considerations

### HTTPS Setup
For production use, configure reverse proxy:
- **Nginx**: Most common, well-documented
- **Traefik**: Docker-native, automatic SSL
- **Caddy**: Automatic HTTPS with Let's Encrypt

### Firewall Configuration
- Restrict port 5678 to localhost only
- Use reverse proxy for external access
- Consider VPN/Tailscale for remote access

### Resource Monitoring
- Monitor Docker container resource usage
- Set memory limits if needed
- Monitor disk usage for workflow data

### Updates
```bash
# Pull latest image
docker-compose pull

# Restart with new image
docker-compose up -d
```

## Use Cases

Common automation scenarios:
- **API Integrations**: Connect different services
- **Data Synchronization**: Sync data between platforms
- **Notifications**: Send alerts based on triggers
- **File Processing**: Automate file operations
- **Webhooks**: Receive and process webhook events
- **Scheduled Tasks**: Run workflows on schedule

## Comparison with Alternatives

| Feature | n8n | Zapier | Make.com |
|---------|-----|--------|----------|
| Self-hosted | ✅ | ❌ | ❌ |
| Open source | ✅ | ❌ | ❌ |
| Free tier | ✅ Unlimited | Limited | Limited |
| Data privacy | ✅ Full control | Cloud | Cloud |
| Setup complexity | Medium | Low | Low |

## Next Steps

1. **Decision**: Choose Docker Compose setup (recommended)
2. **Implementation**: Create `n8n/` directory in dotfiles
3. **Configuration**: Set up docker-compose.yml with security
4. **Testing**: Start n8n and create test workflow
5. **Documentation**: Add to wiki/Development-Tools.md

## Resources

- [n8n Official Documentation](https://docs.n8n.io)
- [n8n Community Forum](https://community.n8n.io)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Notes

- Docker Desktop is already installed, so Docker setup is ready
- Consider adding n8n to dotfiles following existing patterns (Ollama, Home Assistant)
- Data directory should remain in `~/.n8n` for Docker volume access
- Configuration files can be version-controlled in dotfiles
- Basic auth is essential for any non-localhost access


