#!/bin/bash
# Test script to verify Dynamic DNS is working
# Checks if DNS record updates from wrong IP to correct IP

echo "🧪 Testing Dynamic DNS Update"
echo "=============================="
echo ""

# Get current public IP
echo "1️⃣  Getting current public IP..."
CURRENT_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || curl -s https://ifconfig.me)
echo "   Current public IP: $CURRENT_IP"
echo ""

# Check DNS record
echo "2️⃣  Checking DNS record..."
DNS_IP=$(nslookup factorio.xcvr.link 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)

if [ -z "$DNS_IP" ]; then
    # Try with dig
    DNS_IP=$(dig +short factorio.xcvr.link 2>/dev/null | head -1)
fi

if [ -z "$DNS_IP" ]; then
    echo "   ❌ Could not resolve DNS record"
    echo "   → DNS might not be propagated yet"
else
    echo "   DNS record IP: $DNS_IP"
fi
echo ""

# Compare
echo "3️⃣  Comparison:"
echo "   Public IP:    $CURRENT_IP"
echo "   DNS record:   ${DNS_IP:-'Not resolved'}"
echo ""

if [ "$CURRENT_IP" = "$DNS_IP" ]; then
    echo "   ✅ IPs match! Dynamic DNS is working correctly."
elif [ -n "$DNS_IP" ]; then
    echo "   ⚠️  IPs don't match!"
    echo "   → DNS record needs to be updated"
    echo "   → Check UDM Pro Dynamic DNS status"
    echo "   → Or wait a few minutes for update interval"
else
    echo "   ⚠️  Could not compare (DNS not resolved)"
fi
echo ""

# Check UDM Pro Dynamic DNS (if accessible)
echo "4️⃣  Next Steps:"
echo "   - Check UDM Pro: UniFi Network → Settings → Internet → WAN → Dynamic DNS"
echo "   - Should show: Active/Connected"
echo "   - Wait 5-15 minutes for update interval"
echo "   - Run this script again to check: ./test_dynamic_dns.sh"
echo ""
