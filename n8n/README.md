# n8n Configuration

n8n is an open-source workflow automation tool that allows you to connect different services and automate tasks.

## Installation

n8n runs in Docker using Docker Compose. Docker Desktop must be installed and running.

**Status**: ✅ Ready to use

## Quick Start

1. **Create environment file**:
   ```bash
   cd ~/dotfiles/n8n
   cp .env.example .env
   # Edit .env and set a secure password
   ```

2. **Start n8n**:
   ```bash
   docker-compose up -d
   ```

3. **Access n8n**:
   Open `http://localhost:5678` in your browser
   - Username: `admin` (or value from `.env`)
   - Password: (value from `.env`)

## Service Management

**Start n8n**:
```bash
cd ~/dotfiles/n8n
docker-compose up -d
```

**Stop n8n**:
```bash
cd ~/dotfiles/n8n
docker-compose down
```

**View logs**:
```bash
docker-compose logs -f
```

**Restart n8n**:
```bash
docker-compose restart
```

**Update n8n**:
```bash
docker-compose pull
docker-compose up -d
```

## Configuration

### Environment Variables

Edit `.env` file to configure n8n:

- `N8N_BASIC_AUTH_ACTIVE`: Enable basic authentication (default: `true`)
- `N8N_BASIC_AUTH_USER`: Username for web interface (default: `admin`)
- `N8N_BASIC_AUTH_PASSWORD`: Password for web interface (**required**)
- `N8N_HOST`: Hostname (default: `localhost`)
- `N8N_PROTOCOL`: `http` or `https` (default: `http`)
- `N8N_METRICS`: Enable metrics collection (default: `false`)
- `N8N_LOG_LEVEL`: Logging level - `debug`, `info`, `warn`, `error` (default: `info`)

### Data Persistence

Workflow data is stored in `~/.n8n/` directory, which is mounted as a Docker volume. This ensures:
- Workflows persist across container restarts
- Credentials are saved
- Execution history is maintained

**Backup**:
```bash
tar czf n8n-backup-$(date +%F).tar.gz ~/.n8n
```

**Restore**:
```bash
tar xzf n8n-backup-YYYY-MM-DD.tar.gz -C ~/
```

## Security

- Basic authentication is enabled by default
- Change the default password in `.env` file
- For production use, consider:
  - Setting up HTTPS with reverse proxy (Nginx, Traefik, Caddy)
  - Restricting port 5678 to localhost only
  - Using VPN/Tailscale for remote access

## Use Cases

Common automation scenarios:
- **API Integrations**: Connect different services
- **Data Synchronization**: Sync data between platforms
- **Notifications**: Send alerts based on triggers
- **File Processing**: Automate file operations
- **Webhooks**: Receive and process webhook events
- **Scheduled Tasks**: Run workflows on schedule

## Resources

- [n8n Official Documentation](https://docs.n8n.io)
- [n8n Community Forum](https://community.n8n.io)
- [n8n GitHub Repository](https://github.com/n8n-io/n8n)
- [Setup Research Document](../docs/n8n-setup-research.md)

## Notes

- Data directory `~/.n8n/` is not symlinked (contains runtime data)
- Configuration files (`docker-compose.yml`, `.env.example`) are version-controlled
- `.env` file is git-ignored (contains secrets)
- Container automatically restarts on system reboot

