# Building Custom Factorio Docker Image

## Why Build Our Own?

- **Always Latest**: Automatically downloads the latest stable Factorio version
- **No Waiting**: No need to wait for third-party maintainers to update
- **Full Control**: We control the build process and can customize as needed

## Alternative: Use factoriotools/factorio (Easier)

Before building your own, try the more-maintained `factoriotools/factorio` image:

1. Update `truenas_custom_app.yaml` to use:
   ```yaml
   image: factoriotools/factorio:latest
   ```

2. Check if it has 2.0.73: https://hub.docker.com/r/factoriotools/factorio/tags

This is the most popular Factorio Docker image (1.3k stars) and may be more up-to-date than `goofball222/factorio`.

## Quick Start (Building Your Own)

### Option 1: Build Locally (Mac)

```bash
cd /Users/pete/dotfiles/factorio
chmod +x build_docker_image.sh
./build_docker_image.sh
```

This builds `factorio-custom:latest` with the latest Factorio version.

### Option 2: Build on TrueNAS (Recommended)

Since TrueNAS runs the container, building on the NAS avoids image transfer:

```bash
# SSH to TrueNAS
ssh truenas_admin@192.168.0.158

# Copy files to NAS
# (You'll need to copy Dockerfile and build script to the NAS)

# Build on NAS
cd /path/to/factorio
docker build -t factorio-custom:latest -f Dockerfile .
```

### Option 3: Use Docker Buildx for Multi-Arch (Advanced)

If you want to build for different architectures or push to a registry.

## Updating truenas_custom_app.yaml

After building, update the YAML:

```yaml
services:
  factorio:
    image: factorio-custom:latest
    # Or use a specific tag: factorio-custom:2.0.73
```

**For TrueNAS Custom Apps**, you have two options:

### Option A: Use Local Image (if built on NAS)

If you built the image on the NAS, TrueNAS can use it directly.

### Option B: Push to Registry (Recommended)

1. Tag and push to Docker Hub (or your registry):
   ```bash
   docker tag factorio-custom:latest your-username/factorio-custom:latest
   docker push your-username/factorio-custom:latest
   ```

2. Update YAML:
   ```yaml
   image: your-username/factorio-custom:latest
   ```

## How It Works

The Dockerfile:
1. Fetches the latest stable version from `factorio.com/api/latest-releases`
2. Downloads the headless Linux64 tarball (may require authentication for newer versions)
3. Extracts and sets up Factorio
4. Creates an entrypoint that handles RCON password and save files

**Note**: Factorio downloads may require authentication. If the build fails, you'll need to:
1. Get your Factorio username and token from `%appdata%\Factorio\player-data.json` (Windows) or `~/.factorio/player-data.json` (Linux/Mac)
2. Build with: `docker build --build-arg FACTORIO_USERNAME=your-username --build-arg FACTORIO_TOKEN=your-token ...`

## Version Pinning

To pin a specific version, edit `Dockerfile`:

```dockerfile
ARG VERSION="2.0.73"  # Instead of empty string
```

Or build with:

```bash
docker build --build-arg VERSION=2.0.73 -t factorio-custom:2.0.73 .
```

## Comparison with factoriotools/factorio

| Feature | factoriotools/factorio | Our Custom Image |
|---------|------------------------|------------------|
| Latest Version | May lag behind | Always latest |
| Maintenance | Community maintained | We maintain |
| Complexity | More features | Simpler |
| RCON Support | Built-in | Basic support |
| SHA256 Checks | Yes | No (simpler) |

## Troubleshooting

### Build Fails: "Cannot fetch latest version"

The Factorio API might be down. Try:
1. Check https://factorio.com/api/latest-releases manually
2. Build with specific version: `--build-arg VERSION=2.0.73`

### Image Too Large

The image includes the full Factorio binary (~200MB). This is normal.

### RCON Not Working

Check that `FACTORIO_RCON_PASSWORD` is set in the environment variables.

## Next Steps

1. Build the image (locally or on NAS)
2. Update `truenas_custom_app.yaml` to use the new image
3. Redeploy the app in TrueNAS
4. Verify version: Check server logs for "Factorio 2.0.73"
