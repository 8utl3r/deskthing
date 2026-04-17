#!/bin/bash
# Quick Factorio server connection test

NAS_IP="192.168.0.158"
RCON_PORT=27015
GAME_PORT=34197

echo "🔍 Testing Factorio Server Connection"
echo "======================================"
echo ""

# Test 1: RCON Port (TCP)
echo "1️⃣  Testing RCON port (TCP $RCON_PORT)..."
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$NAS_IP/$RCON_PORT" 2>/dev/null; then
    echo "   ✅ RCON port is OPEN"
else
    echo "   ❌ RCON port is CLOSED or unreachable"
    echo "      → Check if server is running"
    echo "      → Check firewall rules"
fi
echo ""

# Test 2: Game Port (UDP - harder to test)
echo "2️⃣  Testing Game port (UDP $GAME_PORT)..."
if command -v nc >/dev/null 2>&1; then
    if nc -u -z -v -w 3 $NAS_IP $GAME_PORT 2>&1 | grep -q "succeeded"; then
        echo "   ✅ UDP port might be open"
    else
        echo "   ⚠️  UDP test inconclusive (UDP is connectionless)"
        echo "      → Try connecting in Factorio client anyway"
    fi
else
    echo "   ⚠️  netcat not available, skipping UDP test"
fi
echo ""

# Test 3: Check if container is running
echo "3️⃣  Checking if container is running on NAS..."
if ssh -o ConnectTimeout=5 truenas_admin@$NAS_IP "sudo docker ps | grep -q factorio" 2>/dev/null; then
    echo "   ✅ Factorio container is RUNNING"
    
    # Get container status
    echo ""
    echo "   Container details:"
    ssh truenas_admin@$NAS_IP "sudo docker ps | grep factorio" 2>/dev/null | head -1
else
    echo "   ❌ Factorio container is NOT running"
    echo "      → Start it in TrueNAS Web UI: Apps → Installed Apps → factorio → Start"
fi
echo ""

# Test 4: Check container logs for binding
echo "4️⃣  Checking server binding in logs..."
LOG_OUTPUT=$(ssh truenas_admin@$NAS_IP "sudo docker logs factorio 2>&1 | tail -20" 2>/dev/null)
if echo "$LOG_OUTPUT" | grep -q "0.0.0.0:34197"; then
    echo "   ✅ Server is binding to 0.0.0.0:34197 (correct)"
elif echo "$LOG_OUTPUT" | grep -q "127.0.0.1:34197"; then
    echo "   ❌ Server is binding to 127.0.0.1:34197 (wrong - only localhost)"
    echo "      → Server won't accept external connections"
elif echo "$LOG_OUTPUT" | grep -q "Hosting game"; then
    echo "   ⚠️  Server is running but binding unclear"
    echo "$LOG_OUTPUT" | grep "Hosting game"
else
    echo "   ⚠️  Could not find binding info in logs"
    echo "      → Check logs manually in TrueNAS Web UI"
fi
echo ""

# Test 5: RCON connection test (if password is set)
if [ -f "config.py" ]; then
    RCON_PASSWORD=$(grep "RCON_PASSWORD" config.py | cut -d'"' -f2)
    if [ -n "$RCON_PASSWORD" ] && [ "$RCON_PASSWORD" != '""' ]; then
        echo "5️⃣  Testing RCON connection..."
        cd "$(dirname "$0")"
        python3 -c "
from factorio_rcon import FactorioRcon
try:
    rcon = FactorioRcon('$NAS_IP', $RCON_PORT, '$RCON_PASSWORD')
    response = rcon.send_command('/sc game.print(\"Connection test\")')
    print('   ✅ RCON connection successful!')
    print(f'   Response: {response[:50]}...')
except Exception as e:
    print(f'   ❌ RCON connection failed: {e}')
" 2>/dev/null || echo "   ⚠️  Could not test RCON (check config.py)"
    else
        echo "5️⃣  Skipping RCON test (password not set in config.py)"
    fi
else
    echo "5️⃣  Skipping RCON test (config.py not found)"
fi
echo ""

echo "======================================"
echo "📋 Summary & Next Steps"
echo "======================================"
echo ""
echo "If RCON works but game connection doesn't:"
echo "  → It's likely a UDP/firewall issue"
echo "  → Check TrueNAS firewall settings"
echo "  → Try connecting from Factorio client: $NAS_IP:$GAME_PORT"
echo ""
echo "If nothing works:"
echo "  → Check server logs in TrueNAS: Apps → factorio → Logs"
echo "  → Verify ports are exposed: Apps → factorio → Edit → Ports"
echo "  → See: network_connection_troubleshooting.md"
echo ""
