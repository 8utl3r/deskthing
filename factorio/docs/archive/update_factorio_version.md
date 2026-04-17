# Updating Factorio Server Version

## Current Situation

- **Server running**: Factorio 2.0.72
- **Latest Factorio**: 2.0.73
- **Docker image**: `goofball222/factorio:latest`

## Why the Version Mismatch?

Docker images are maintained by third parties and may lag behind official Factorio releases. The `goofball222/factorio:latest` image currently has 2.0.72, not 2.0.73.

## Options to Update

### Option 1: Wait for Image Update (Easiest)

The image maintainer will eventually update `:latest` to 2.0.73. You can:
1. Check periodically: `docker pull goofball222/factorio:latest`
2. Restart the container when updated

### Option 2: Use Specific Tag (When Available)

Once the maintainer releases 2.0.73, update the YAML:

```yaml
image: goofball222/factorio:2.0.73
```

Then redeploy the app.

### Option 3: Check Available Tags

```bash
# Check what tags are available
curl -s https://hub.docker.com/v2/repositories/goofball222/factorio/tags | jq '.results[].name'
```

Or visit: https://hub.docker.com/r/goofball222/factorio/tags

### Option 4: Build Your Own Image (Advanced)

If you need the absolute latest version immediately, you could build your own Docker image, but this requires more maintenance.

## Is 2.0.72 vs 2.0.73 a Problem?

**For NPCs/RCON**: No, version 2.0.72 works fine. The difference between 2.0.72 and 2.0.73 is likely minor bug fixes.

**For multiplayer**: Players need to match the server version. If they have 2.0.73, they may need to downgrade or wait for the server to update.

## Recommendation

**For now**: Keep using 2.0.72. It's very recent and works fine for NPCs.

**To update later**: 
1. Check Docker Hub tags periodically
2. When 2.0.73 tag appears, update the YAML
3. Redeploy the app

The version mismatch is minor and shouldn't affect NPC functionality.
