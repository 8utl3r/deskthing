# UniFi Network Monitoring Setup Guide

## Overview
Complete FOSS monitoring solution for UniFi networks with all bells and whistles:
- **LibreNMS**: Primary network monitoring (discovery, SNMP, alerts, topology)
- **Prometheus + Grafana**: Advanced metrics and beautiful dashboards
- **Home Assistant Integration**: Network metrics in your smart home

## Architecture

```
UniFi Devices (SNMP)
    ↓
LibreNMS (Primary Monitoring)
    ↓
Prometheus (Metrics Collection)
    ↓
Grafana (Dashboards)
    ↓
Home Assistant (Integration)
```

## Prerequisites

### UniFi Controller Setup
1. Enable SNMP on UniFi Controller:
   - Settings → CyberSecure → Traffic Logging → Enable SNMP
   - Choose SNMP v2c (community string) or v3 (username/password)
   - **Important**: Use SNMP v3 for security (SHA auth, AES-128 encryption)
   - Set community string (v2c) or credentials (v3)
   - Apply to all devices

2. Verify SNMP on devices:
   ```bash
   # Test SNMP connectivity
   snmpwalk -v2c -c YOUR_COMMUNITY YOUR_UNIFI_IP
   # Or for v3:
   snmpwalk -v3 -u YOUR_USER -l authPriv -a SHA -A YOUR_AUTH_PASS -x AES -X YOUR_PRIV_PASS YOUR_UNIFI_IP
   ```

### System Requirements
- Docker & Docker Compose (recommended)
- Or native installation on Linux/macOS
- Minimum 4GB RAM, 20GB disk space
- Network access to UniFi devices

## Installation Options

### Option 1: Docker Compose (Recommended)

#### LibreNMS Setup
```yaml
# docker-compose.librenms.yml
version: '3.8'
services:
  librenms:
    image: librenms/librenms:latest
    container_name: librenms
    hostname: librenms
    restart: unless-stopped
    volumes:
      - ./librenms-data:/data
      - ./librenms-logs:/logs
    environment:
      - TZ=America/New_York
      - PUID=1000
      - PGID=1000
      - DB_HOST=librenms-db
      - DB_NAME=librenms
      - DB_USER=librenms
      - DB_PASSWORD=changeme
      - BASE_URL=http://localhost:8000
    ports:
      - "8000:80"
    depends_on:
      - librenms-db
      - librenms-redis
    networks:
      - monitoring

  librenms-db:
    image: mariadb:10.11
    container_name: librenms-db
    restart: unless-stopped
    volumes:
      - ./librenms-db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=changeme
      - MYSQL_DATABASE=librenms
      - MYSQL_USER=librenms
      - MYSQL_PASSWORD=changeme
    networks:
      - monitoring

  librenms-redis:
    image: redis:7-alpine
    container_name: librenms-redis
    restart: unless-stopped
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

#### Prometheus + Grafana Setup
```yaml
# docker-compose.prometheus.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus-data:/prometheus
      - ./prometheus-config:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    volumes:
      - ./grafana-data:/var/lib/grafana
      - ./grafana-provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - monitoring

  # UniFi Exporter for Prometheus
  unifi-exporter:
    image: golift/unifi-exporter:latest
    container_name: unifi-exporter
    restart: unless-stopped
    environment:
      - UNIFI_USER=your_unifi_username
      - UNIFI_PASS=your_unifi_password
      - UNIFI_URL=https://your-unifi-controller:8443
      - UNIFI_VERSION=UDMP-unifiOS  # or UDM for older controllers
    ports:
      - "9130:9130"
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
```

### Option 2: Homebrew (macOS)

```bash
# Install LibreNMS dependencies
brew install librenms

# Install Prometheus & Grafana
brew install prometheus grafana

# Start services
brew services start prometheus
brew services start grafana
```

## Configuration

### LibreNMS Configuration

1. **Initial Setup**:
   - Access web UI: `http://localhost:8000`
   - Complete installation wizard
   - Create admin account

2. **Add UniFi Devices**:
   - Devices → Add Device
   - Enter UniFi device IP
   - Select SNMP version (v2c or v3)
   - Enter credentials
   - Enable auto-discovery

3. **Enable Features**:
   - Settings → Global Settings:
     - Enable: Ports, VLANs, FDB, Wireless, BGP, OSPF
     - Set polling intervals (default: 5 minutes)
   - Settings → Alert Settings:
     - Configure email/SMS notifications
     - Set alert rules for:
       - Device down
       - High CPU/Memory
       - Port errors
       - Interface utilization > 80%

4. **UniFi-Specific Settings**:
   - Upload UniFi MIB files for better device recognition
   - Enable wireless client monitoring
   - Configure port utilization alerts

### Prometheus Configuration

```yaml
# prometheus-config/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # UniFi Exporter
  - job_name: 'unifi'
    static_configs:
      - targets: ['unifi-exporter:9130']
    metrics_path: '/metrics'

  # LibreNMS SNMP Exporter (if using)
  - job_name: 'librenms-snmp'
    static_configs:
      - targets: ['librenms:8000']
    metrics_path: '/api/v0/metrics'
```

### Grafana Configuration

1. **Add Data Sources**:
   - Prometheus: `http://prometheus:9090`
   - LibreNMS API (optional): `http://librenms:8000/api/v0`

2. **Import Dashboards**:
   - UniFi Dashboard: Dashboard ID `13639` (community)
   - Network Overview: Dashboard ID `11074`
   - LibreNMS Overview: Create custom or import

3. **Create Custom Dashboards**:
   - UniFi AP Performance
   - Switch Port Utilization
   - Client Connection Stats
   - Network Topology Visualization

### Home Assistant Integration

#### Option 1: Prometheus Integration
```yaml
# homeassistant/configuration.yaml
prometheus:
  namespace: unifi
  filter:
    include_entities:
      - sensor.unifi_*
```

#### Option 2: LibreNMS Integration
```yaml
# homeassistant/configuration.yaml
sensor:
  - platform: rest
    name: "UniFi Device Status"
    resource: "http://librenms:8000/api/v0/devices/YOUR_DEVICE_ID"
    headers:
      X-Auth-Token: YOUR_LIBRENMS_API_TOKEN
    value_template: "{{ value_json.status }}"
    json_attributes:
      - uptime
      - location
      - hardware
```

#### Option 3: REST API Sensors
```yaml
# homeassistant/configuration.yaml
sensor:
  - platform: rest
    name: "UniFi AP Clients"
    resource: "http://librenms:8000/api/v0/devices/YOUR_AP_ID/wireless"
    headers:
      X-Auth-Token: YOUR_LIBRENMS_API_TOKEN
    value_template: "{{ value_json.clients }}"
    scan_interval: 60
```

## Features & Capabilities

### LibreNMS Features
- ✅ Automatic device discovery
- ✅ SNMP monitoring (v1/v2c/v3)
- ✅ Port-level statistics
- ✅ VLAN and FDB monitoring
- ✅ Wireless client tracking
- ✅ Hardware sensors (temp, fans, power)
- ✅ Network topology maps
- ✅ Alerting (email, SMS, webhooks)
- ✅ Mobile apps (iOS/Android)
- ✅ Historical data & trending
- ✅ API for integration

### Prometheus + Grafana Features
- ✅ Time-series metrics
- ✅ Custom dashboards
- ✅ Advanced alerting (Alertmanager)
- ✅ Long-term retention
- ✅ Query language (PromQL)
- ✅ Exporters ecosystem
- ✅ Beautiful visualizations

### Home Assistant Integration
- ✅ Network device status sensors
- ✅ Client count monitoring
- ✅ Port utilization alerts
- ✅ Device availability automation
- ✅ Network health notifications

## Monitoring Checklist

### Essential Metrics
- [ ] Device uptime & availability
- [ ] CPU & memory usage
- [ ] Interface traffic (in/out)
- [ ] Port errors & discards
- [ ] Wireless client counts
- [ ] AP channel utilization
- [ ] Switch port utilization
- [ ] VLAN traffic
- [ ] Hardware sensors (temp, fans)

### Alerts to Configure
- [ ] Device down (immediate)
- [ ] High CPU (>80% for 5 min)
- [ ] High memory (>90%)
- [ ] Port errors (>10/min)
- [ ] Interface utilization (>80%)
- [ ] High temperature (>70°C)
- [ ] AP client count (>threshold)
- [ ] Unusual traffic patterns

## Troubleshooting

### SNMP Not Working
1. Verify SNMP enabled on UniFi Controller
2. Check firewall rules (UDP port 161)
3. Test with `snmpwalk` command
4. Verify SNMP version matches (v2c vs v3)
5. Check community string/credentials

### Devices Not Discovered
1. Check network connectivity
2. Verify SNMP credentials
3. Review LibreNMS discovery logs
4. Manually add device if needed
5. Check device firmware version

### Missing Metrics
1. Verify MIB files uploaded
2. Check device SNMP support
3. Review polling intervals
4. Check LibreNMS device detection
5. Update device firmware

## Next Steps

1. **Installation**: Choose Docker or native installation
2. **SNMP Setup**: Enable SNMP on UniFi Controller
3. **Device Discovery**: Add UniFi devices to LibreNMS
4. **Dashboard Setup**: Configure Grafana dashboards
5. **Alerting**: Set up email/SMS notifications
6. **Home Assistant**: Integrate network metrics
7. **Automation**: Create HA automations based on network events

## Resources

- LibreNMS Docs: https://docs.librenms.org/
- Prometheus Docs: https://prometheus.io/docs/
- Grafana Dashboards: https://grafana.com/grafana/dashboards/
- UniFi SNMP Guide: https://help.ui.com/hc/en-us/articles/33502980942615-SNMP-Monitoring-in-UniFi-Network
- Home Assistant Prometheus: https://www.home-assistant.io/integrations/prometheus/

## Notes

- Use SNMP v3 for production (more secure)
- Set appropriate polling intervals (balance detail vs performance)
- Configure alert thresholds based on your network baseline
- Regular backups of LibreNMS database recommended
- Consider retention policies for Prometheus metrics
