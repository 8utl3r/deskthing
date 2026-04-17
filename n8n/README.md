# n8n on TrueNAS Scale

n8n workflow automation tool running on TrueNAS Scale NAS.

## Instance Details

- **URL**: `http://192.168.0.158:30109`
- **Location**: TrueNAS Scale 25.04.2.6 on Ugreen DXP2800 NAS
- **Storage**: Host Path mounts on `/mnt/tank/apps/n8n`
- **Database**: PostgreSQL (internal to n8n app)
- **Status**: ✅ Running

## Access

1. Open `http://192.168.0.158:30109` in your browser
2. Log in with your credentials (configured during installation)

## Workflows

Workflow definitions are stored in `workflows/` directory. Import them into the NAS instance:

1. Open n8n at `http://192.168.0.158:30109`
2. Go to Workflows → Click "Add workflow" → "Import from File"
3. Select a workflow JSON file from `workflows/` directory

See `workflows/README.md` for workflow documentation.

## Backup

Workflows and data are stored on the NAS at:
- **n8n data**: `/mnt/tank/apps/n8n`
- **PostgreSQL data**: `/mnt/tank/apps/n8n-postgres`

Backup these directories via TrueNAS snapshots or manual backup.

## Setup Documentation

For installation and configuration details, see:
- `/Users/pete/dotfiles/docs/truenas-n8n-*.md` - Setup and configuration guides

## Notes

- This is the production instance (local MacBook setup has been removed)
- All workflows should be imported to this instance
- Data persists on NAS storage
