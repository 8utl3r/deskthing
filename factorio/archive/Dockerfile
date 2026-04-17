# Custom Factorio Docker Image - Always Latest Version
# Based on factoriotools/factorio-docker but simplified for our needs

FROM debian:stable-slim

ARG USER=factorio
ARG GROUP=factorio
ARG PUID=845
ARG PGID=845

# Version to download (empty = latest stable)
ARG VERSION=""

ENV PORT=34197 \
    RCON_PORT=27015 \
    SAVES=/factorio/saves \
    CONFIG=/factorio/config \
    MODS=/factorio/mods \
    SCENARIOS=/factorio/scenarios \
    SCRIPTOUTPUT=/factorio/script-output \
    PUID="$PUID" \
    PGID="$PGID"

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Install dependencies
RUN apt-get -q update \
 && DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    ca-certificates \
    curl \
    jq \
    xz-utils \
    procps \
    gettext-base \
    netcat-openbsd \
    --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

# Create factorio user
RUN groupadd --system --gid "$PGID" "$GROUP" \
 && useradd --system --uid "$PUID" --gid "$PGID" --no-create-home --shell /bin/sh "$USER"

# Download and install Factorio
# Note: Factorio downloads may require authentication token
# For now, we'll try without auth (works for some versions)
# If build fails, you may need to add: --build-arg FACTORIO_USERNAME=... --build-arg FACTORIO_TOKEN=...
ARG FACTORIO_USERNAME=""
ARG FACTORIO_TOKEN=""

RUN set -ox pipefail \
 && mkdir -p /opt /factorio \
 && if [[ -z "$VERSION" ]]; then \
      echo "Fetching latest stable version..." \
      && VERSION=$(curl -sSL "https://factorio.com/api/latest-releases" | jq -r '.stable.headless') \
      && echo "Latest stable version: $VERSION"; \
    fi \
 && echo "Downloading Factorio $VERSION..." \
 && archive="/tmp/factorio_headless_x64_${VERSION}.tar.xz" \
 && if [[ -n "$FACTORIO_USERNAME" && -n "$FACTORIO_TOKEN" ]]; then \
      echo "Using authenticated download..." \
      && curl -sSL "https://www.factorio.com/get-download/${VERSION}/headless/linux64?username=${FACTORIO_USERNAME}&token=${FACTORIO_TOKEN}" \
         -o "$archive" --retry 8; \
    else \
      echo "Attempting unauthenticated download (may fail for newer versions)..." \
      && curl -sSL "https://www.factorio.com/get-download/${VERSION}/headless/linux64" \
         -o "$archive" --retry 8 || (echo "Download failed. You may need to provide FACTORIO_USERNAME and FACTORIO_TOKEN build args." && exit 1); \
    fi \
 && tar xf "$archive" --directory /opt \
 && chmod ugo=rwx /opt/factorio \
 && rm "$archive" \
 && ln -s "$SCENARIOS" /opt/factorio/scenarios \
 && ln -s "$SAVES" /opt/factorio/saves \
 && mkdir -p /opt/factorio/config/ \
 && chown -R "$USER":"$GROUP" /opt/factorio /factorio

# Create entrypoint script (matches goofball222 behavior)
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Create config directory if needed\n\
mkdir -p /opt/factorio/config\n\
\n\
# Set RCON password if provided\n\
if [ -n "$FACTORIO_RCON_PASSWORD" ]; then\n\
  echo "$FACTORIO_RCON_PASSWORD" > /opt/factorio/config/rconpw\n\
  chmod 600 /opt/factorio/config/rconpw\n\
fi\n\
\n\
# Handle save file\n\
SAVE_ARG=""\n\
if [ -n "$FACTORIO_SAVE" ]; then\n\
  SAVE_ARG="--start-server-load-latest"\n\
  if [ "$FACTORIO_SAVE" != "latest" ]; then\n\
    SAVE_ARG="--start-server /factorio/saves/${FACTORIO_SAVE}.zip"\n\
  fi\n\
else\n\
  SAVE_ARG="--start-server-load-latest"\n\
fi\n\
\n\
# Start Factorio\n\
exec /opt/factorio/bin/x64/factorio \\\n\
  $SAVE_ARG \\\n\
  --rcon-port ${RCON_PORT} \\\n\
  --rcon-password "${FACTORIO_RCON_PASSWORD:-}" \\\n\
  --port ${PORT} \\\n\
  "$@"\n\
' > /docker-entrypoint.sh \
 && chmod +x /docker-entrypoint.sh

VOLUME /factorio
EXPOSE $PORT/udp $RCON_PORT/tcp

ENTRYPOINT ["/docker-entrypoint.sh"]
