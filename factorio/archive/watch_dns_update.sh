#!/bin/bash
# Watch DNS record until it updates to correct IP
# This script MONITORS only - it doesn't update DNS
# The update comes from UDM Pro Dynamic DNS

CORRECT_IP="24.155.117.71"
DNS_NAME="factorio.xcvr.link"
CHECK_INTERVAL=30

echo "🔍 Watching DNS Record Update (Monitoring Only)"
echo "================================================"
echo ""
echo "Waiting for UDM Pro Dynamic DNS to update:"
echo "  $DNS_NAME → $CORRECT_IP"
echo ""
echo "Checking every $CHECK_INTERVAL seconds..."
echo "Press Ctrl+C to stop"
echo ""

# Get current public IP for comparison
CURRENT_PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || curl -s https://ifconfig.me)
echo "Current public IP: $CURRENT_PUBLIC_IP"
echo ""

if [ "$CURRENT_PUBLIC_IP" != "$CORRECT_IP" ]; then
    echo "⚠️  Note: Your public IP ($CURRENT_PUBLIC_IP) doesn't match expected ($CORRECT_IP)"
    echo "   This might be normal if your IP changed"
    echo ""
fi

ATTEMPT=1

while true; do
    # Get DNS record IP
    DNS_IP=$(nslookup "$DNS_NAME" 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
    
    # Fallback to dig if nslookup fails
    if [ -z "$DNS_IP" ]; then
        DNS_IP=$(dig +short "$DNS_NAME" 2>/dev/null | head -1)
    fi
    
    TIMESTAMP=$(date '+%H:%M:%S')
    
    if [ -z "$DNS_IP" ]; then
        echo "[$TIMESTAMP] Attempt $ATTEMPT: ❌ DNS record not found or not resolving"
    elif [ "$DNS_IP" = "$CORRECT_IP" ]; then
        echo "[$TIMESTAMP] Attempt $ATTEMPT: ✅ SUCCESS! DNS updated to $CORRECT_IP"
        echo ""
        echo "🎉 Dynamic DNS is working correctly!"
        echo "   DNS record: $DNS_NAME → $CORRECT_IP"
        exit 0
    else
        echo "[$TIMESTAMP] Attempt $ATTEMPT: ⏳ DNS shows $DNS_IP (waiting for $CORRECT_IP)..."
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep $CHECK_INTERVAL
done
