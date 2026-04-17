#!/bin/bash
# Add test user to Jellyfin (run after admin exists)
# Usage: JF_PASS=your_admin_password ./servarr-pi5-jellyfin-add-test-user.sh
# Or from Mac: JF_BASE=http://pi5.xcvr.link:8096 JF_PASS=xxx ./servarr-pi5-jellyfin-add-test-user.sh

set -e
BASE="${JF_BASE:-http://localhost:8096}"
JF_USER="${JF_USER:-admin}"
JF_PASS="${JF_PASS:-}"
TEST_USER="${TEST_USER:-test}"
TEST_PASS="${TEST_PASS:-test1234}"

if [ -z "$JF_PASS" ]; then
  echo "Usage: JF_PASS=your_admin_password $0"
  exit 1
fi

echo "Authenticating as $JF_USER..."
AUTH=$(curl -s -X POST "$BASE/Users/AuthenticateByName" \
  -H "Authorization: MediaBrowser Client=\"script\", Device=\"add-user\", DeviceId=\"1\", Version=\"1.0\"" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$JF_USER\",\"Pw\":\"$JF_PASS\"}")

TOKEN=$(echo "$AUTH" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('AccessToken',''))" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "Auth failed. Check admin username/password."
  echo "Response: $AUTH"
  exit 1
fi

echo "Creating test user: $TEST_USER / $TEST_PASS"
curl -s -X POST "$BASE/Users/New" \
  -H "Authorization: MediaBrowser Token=\"$TOKEN\"" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"$TEST_USER\",\"Password\":\"$TEST_PASS\",\"EnableAutoLogin\":false}" \
  -w " HTTP %{http_code}\n" -o /dev/null

echo "Done. Test account: $TEST_USER / $TEST_PASS"
