#!/bin/bash
# Cloudflare Dynamic DNS Update Script for Factorio
# Updates factorio.xcvr.link DNS record when public IP changes

set -e

# Configuration
ZONE_ID="${CLOUDFLARE_ZONE_ID:-YOUR_ZONE_ID_HERE}"
DNS_NAME="factorio"
DOMAIN="xcvr.link"
API_TOKEN="${CLOUDFLARE_API_TOKEN:-YOUR_API_TOKEN_HERE}"

# Log file
LOG_FILE="/mnt/boot-pool/scripts/dns_update.log"

# Function to log with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Get current public IP
log "Checking current public IP..."
CURRENT_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || curl -s https://ifconfig.me)

if [ -z "$CURRENT_IP" ]; then
    log "ERROR: Could not determine public IP"
    exit 1
fi

log "Current public IP: $CURRENT_IP"

# Get Record ID if not set
if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "YOUR_RECORD_ID_HERE" ]; then
    log "Fetching Record ID..."
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${DNS_NAME}.${DOMAIN}" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
    
    if [ -z "$RECORD_ID" ]; then
        log "ERROR: Could not find DNS record for ${DNS_NAME}.${DOMAIN}"
        exit 1
    fi
    log "Found Record ID: $RECORD_ID"
fi

# Get current DNS record IP
log "Fetching current DNS record..."
DNS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json")

DNS_IP=$(echo "$DNS_RESPONSE" | grep -o '"content":"[^"]*' | cut -d'"' -f4)

if [ -z "$DNS_IP" ]; then
    log "ERROR: Could not get current DNS IP from response"
    log "Response: $DNS_RESPONSE"
    exit 1
fi

log "Current DNS IP: $DNS_IP"

# Compare IPs
if [ "$CURRENT_IP" != "$DNS_IP" ]; then
    log "IP changed from $DNS_IP to $CURRENT_IP. Updating DNS..."
    
    # Update DNS record
    UPDATE_RESPONSE=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${DNS_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":3600,\"proxied\":false}")
    
    if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
        log "✅ DNS updated successfully to $CURRENT_IP"
        exit 0
    else
        log "❌ DNS update failed"
        log "Response: $UPDATE_RESPONSE"
        exit 1
    fi
else
    log "IP unchanged ($CURRENT_IP). No update needed."
    exit 0
fi
