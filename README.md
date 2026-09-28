# Health Check Script

A bash script that checks system health (CPU, RAM, Disk, Services) and reports warnings.

## Features

- Checks CPU load average
- Checks RAM usage
- Checks disk usage per mount point
- Checks systemd service status
- Colored output (green/yellow/red)
- Returns non-zero exit code if any warning

## Usage

```
./health-check.sh
```

No arguments needed.

## Checks performed

- **CPU**: Load average vs CPU cores. Warns if above threshold.
- **RAM**: Used memory percentage. Warns if above threshold.
- **Disk**: Usage percentage per mount point. Warns if above threshold.
- **Services**: Checks if `ssh` and `cron` are active.

## Configuration

Thresholds can be edited at the top of the script:

```bash
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=80
```

Services to check are defined here:

```bash
SERVICES=("ssh" "cron")
```

## Exit codes

- `0` — All checks passed
- `1` — At least one warning found

This makes the script suitable for cron jobs and CI pipelines.

## Example output

```
===================================
  System Health Check
===================================
Hostname: ubuntu
Date: 2026-09-28 11:18:45
Uptime: up 9 hours, 40 minutes
-----------------------------------
[CPU] Load: 0.14 (cores: 4, 4%) [OK]
[RAM] Used: 1475MB / 5279MB (28%) [OK]
[DISK] / (/dev/sda2): 8% [OK]
[SERVICE] ssh: inactive [WARNING]
[SERVICE] cron: active [OK]
-----------------------------------
Result: 1 warning(s) found
```

## License

MIT
