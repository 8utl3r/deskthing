# Session Records 2026: Services

## Version History
- 2026-01-20: Moved 2026 service records from `project_context.md`.

## 2026-01-20 - Seafile Loop Root Cause Research
- **Date/Time**: 2026-01-20 21:01:55 CST
- **Objective**: Determine why Seafile init loop repeats and identify root cause from docs and community reports.
- **Decision**: Treat auth plugin mismatch for the `seafile` DB user as the primary root cause.
- **Rationale**: Logs show consistent "Access denied for user 'seafile'" despite correct root auth; community reports point to mysql_native_password issues.
- **Alternatives**: Env var mismatch (v11 vs v12), stale DB state, host access (`'seafile'@'%'` vs IPv6 host).
- **Impact**: Validate user host/plugin and, if needed, alter user to mysql_native_password before rerun.
- **Date**: 2026-01-20
- **Actions Taken**: Reviewed Seafile logs; ran targeted web research; created compliance rule files; logged rule violation.
- **Next 3 Specific Steps**:
  1. Summarize loop count and root cause findings to user
  2. Validate DB user/plugin state (`mysql_native_password`, host `%`)
  3. Apply clean reset plan with verified user creation flow
- **Blockers/Concerns**: Resolved - session records moved to `docs/session_records_index.md` to keep `project_context.md` under 200 lines.

## 2026-01-20 - n8n Setup on TrueNAS Scale NAS
- **Date/Time**: 2026-01-20
- **Key Decisions**: Installed n8n on TrueNAS Scale 25.04.2.6 NAS (Ugreen DXP2800) as production instance; removed local MacBook setup
- **Actions Taken**:
  - Installed n8n app via TrueNAS Apps (community train)
  - Configured storage mounts: Host Path `/mnt/tank/apps/n8n` for n8n data, `/mnt/tank/apps/n8n-postgres` for PostgreSQL
  - Fixed permissions: set `/mnt/tank/apps/n8n` ownership to `apps:apps` (UID/GID 568) via `midclt call filesystem.chown`
  - Started n8n app successfully; verified running at `http://192.168.0.158:30109`
  - Removed local MacBook setup: deleted `~/.n8n` directory and `docker-compose.yml`
  - Updated dotfiles documentation to reflect NAS instance only
- **Next 3 Specific Steps**:
  1. Access n8n web interface at `http://192.168.0.158:30109` and complete setup wizard
  2. Import workflows from `n8n/workflows/` directory to NAS instance
  3. Configure n8n settings and create first workflows
- **Blockers/Concerns**: None - n8n is running on NAS and ready to use
