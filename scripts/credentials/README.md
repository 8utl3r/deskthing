# Credential Helper

Fetches credentials for scripts so the agent can log in without manual input.

## Options (pick one)

### 1. macOS Keychain (recommended — built-in)

Store credentials in Keychain; scripts read them via `security find-generic-password`.

```bash
# Add NPM password (run once)
security add-generic-password -a "petersag3@gmail.com" -s "NPM" -w "YOUR_NPM_PASSWORD"

# Or add TrueNAS sudo password
security add-generic-password -a "truenas_admin" -s "truenas-sudo" -w "YOUR_SUDO_PASSWORD"
```

The helper reads with: `security find-generic-password -s "NPM" -a "petersag3@gmail.com" -w`

### 2. Bitwarden CLI

```bash
brew install bitwarden-cli
bw login
bw unlock  # export BW_SESSION for session

# Create a "Secure Note" or "Login" item named "NPM" with:
#   username: petersag3@gmail.com
#   password: <your NPM password>
```

For headless: set `BW_PASSWORD` in a gitignored file, or run `bw unlock` once per session.

### 3. `.env` files (current)

Keep credentials in gitignored `.env` files (e.g. `scripts/npm/.env`, `factorio/.env.nas`). Scripts source these. No extra setup.

## Usage

```bash
# From scripts (sources the helper)
source ~/dotfiles/scripts/credentials/creds.sh
NPM_PASSWORD=$(creds_get "NPM")
```

## Supported credentials

| Key | Source | Used by |
|-----|--------|---------|
| NPM | keychain | npm-api.sh |
| NPM_EMAIL | keychain | npm-api.sh |
| truenas-sudo | keychain | truenas SSH scripts |
| unifi-ssh | keychain | unifi scripts |

## One-time setup (Keychain)

```bash
# NPM (email + password)
security add-generic-password -a "petersag3@gmail.com" -s "NPM" -w "YOUR_NPM_PASSWORD"
security add-generic-password -a "npm" -s "NPM_EMAIL" -w "petersag3@gmail.com"

# TrueNAS sudo
security add-generic-password -a "truenas_admin" -s "truenas-sudo" -w "YOUR_SUDO_PASSWORD"

# UniFi SSH
security add-generic-password -a "unifi" -s "unifi-ssh" -w "YOUR_UNIFI_SSH_PASSWORD"
```
