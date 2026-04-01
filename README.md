# 🛠 Universal Backup Manager

Lightweight Bash-based backup tool for DevOps environments.

### Key Features:
- 🧠 **Auto-Discovery:** Detects PostgreSQL and Docker environments automatically.
- 📬 **Telegram Integration:** Sends status reports and error alerts.
- 🧹 **Smart Retention:** Automatic cleanup of old backups (Rotation).
- 📦 **Compression:** All backups are Gzipped to save space.

### Usage:
1. Clone the repo.
2. Set your `TG_TOKEN` and `TG_CHAT_ID`.
3. Add to crontab: `0 2 * * * /path/to/backup-manager.sh`
