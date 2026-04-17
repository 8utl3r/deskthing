#!/bin/bash
# Troubleshoot external Factorio connection

echo "🔍 Troubleshooting Factorio External Connection"
echo "================================================"
echo ""

# Check DNS resolution
echo "1️⃣  Checking DNS resolution..."
DNS_IP=$(nslookup factorio.xcvr.link 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)

if [ -z "$DNS_IP" ]; then
    DNS_IP=$(dig +short factorio.xcvr.link 2>/dev/null | head -1)
fi

if [ -z "$DNS_IP" ]; then
    echo "   ❌ DNS not resolving - record might not exist or not propagated"
    echo "   → Check Cloudflare Dashboard → DNS → Records"
else
    echo "   ✅ DNS resolves to: $DNS_IP"
fi
echo ""

# Check actual public IP
echo "2️⃣  Checking actual public IP..."
ACTUAL_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com)
echo "   Your public IP: $ACTUAL_IP"

if [ -n "$DNS_IP" ] && [ "$DNS_IP" != "$ACTUAL_IP" ]; then
    echo "   ⚠️  DNS IP ($DNS_IP) doesn't match public IP ($ACTUAL_IP)"
    echo "   → Dynamic DNS might not have updated yet"
    echo "   → Try connecting with IP directly: $ACTUAL_IP:34197"
fi
echo ""

# Check if port is accessible (TCP test - RCON)
echo "3️⃣  Testing TCP port 27015 (RCON)..."
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$DNS_IP/27015" 2>/dev/null; then
    echo "   ✅ TCP port 27015 is accessible"
else
    echo "   ❌ TCP port 27015 is NOT accessible"
    echo "   → Router port forwarding might not be set up"
    echo "   → Or firewall is blocking"
fi
echo ""

# Check router port forwarding
echo "4️⃣  Router Port Forwarding Checklist:"
echo "   [ ] UDP port 34197 forwarded to 192.168.0.158:34197"
echo "   [ ] TCP port 27015 forwarded to 192.168.0.158:27015 (optional)"
echo "   [ ] Router firewall allows these ports"
echo ""

# Test with IP directly
echo "5️⃣  Try connecting with IP directly:"
if [ -n "$ACTUAL_IP" ]; then
    echo "   In Factorio: $ACTUAL_IP:34197"
    echo "   (This bypasses DNS - tests if port forwarding works)"
else
    echo "   Could not determine public IP"
fi
echo ""

# Check server status
echo "6️⃣  Server Status:"
echo "   Check if server is running on NAS:"
echo "   ssh truenas_admin@192.168.0.158 'sudo docker ps | grep factorio'"
echo ""

# Common issues
echo "📋 Common Issues:"
echo "   ❌ DNS not resolving → Check Cloudflare DNS record exists"
echo "   ❌ DNS wrong IP → Wait for dynamic DNS update or fix manually"
echo "   ❌ Port not accessible → Check router port forwarding"
echo "   ❌ Connection timeout → Check firewall rules"
echo "   ❌ Server not running → Check Docker container status"
echo ""
