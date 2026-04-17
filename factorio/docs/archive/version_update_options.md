# Factorio Version Update Options

## Current Situation
- **Server running**: 2.0.72 (from `goofball222/factorio:latest`)
- **Latest Factorio**: 2.0.73
- **Goal**: Get 2.0.73 running

## Option 1: Try factoriotools/factorio (Easiest) ⭐ Recommended

**Why**: More maintained (1.3k GitHub stars), actively updated

**Steps**:
1. Check if it has 2.0.73: https://hub.docker.com/r/factoriotools/factorio/tags
2. If yes, update `truenas_custom_app.yaml`:
   ```yaml
   image: factoriotools/factorio:latest
   ```
3. Or use the pre-made YAML: `truenas_custom_app_factoriotools.yaml`
4. Redeploy in TrueNAS

**Pros**:
- ✅ No building required
- ✅ Well-maintained
- ✅ Community support

**Cons**:
- ❌ May still lag behind (but usually faster than goofball222)

---

## Option 2: Build Custom Image (Full Control)

**Why**: Always get the absolute latest version automatically

**Steps**:
1. Build the image:
   ```bash
   cd /Users/pete/dotfiles/factorio
   ./build_docker_image.sh
   ```
2. If build fails (authentication required):
   - Get token from `~/.factorio/player-data.json` (or Windows: `%appdata%\Factorio\player-data.json`)
   - Build with: `docker build --build-arg FACTORIO_USERNAME=... --build-arg FACTORIO_TOKEN=... -t factorio-custom:latest .`
3. Push to registry (or build on NAS):
   ```bash
   docker tag factorio-custom:latest your-username/factorio-custom:latest
   docker push your-username/factorio-custom:latest
   ```
4. Update YAML:
   ```yaml
   image: your-username/factorio-custom:latest
   ```

**Pros**:
- ✅ Always latest version
- ✅ Full control
- ✅ No waiting for maintainers

**Cons**:
- ❌ Requires building
- ❌ May need authentication token
- ❌ You maintain it

---

## Option 3: Wait (Simplest)

**Why**: 2.0.72 → 2.0.73 is likely just bug fixes

**Steps**: Do nothing, wait for `goofball222/factorio:latest` to update

**Pros**:
- ✅ Zero effort
- ✅ 2.0.72 works fine for NPCs

**Cons**:
- ❌ May take days/weeks
- ❌ Version mismatch with clients

---

## Recommendation

**Try Option 1 first** (factoriotools/factorio). It's the best balance of:
- Ease of use
- Maintenance
- Likelihood of having 2.0.73

If that doesn't have 2.0.73, then **Option 2** (build custom) gives you full control.

---

## Files Created

- `Dockerfile` - Custom build (always latest)
- `build_docker_image.sh` - Build script
- `build_and_deploy_guide.md` - Detailed build instructions
- `truenas_custom_app_factoriotools.yaml` - Alternative YAML using factoriotools
