#!/bin/bash

# ==============================================================================
# Реквизиты для уведомлений (заполни свои данные)
# ==============================================================================
TG_TOKEN="YOUR_BOT_TOKEN"
TG_CHAT_ID="YOUR_CHAT_ID"
HOSTNAME=$(hostname)

# Настройки путей
BACKUP_DIR="/mnt/backups/$(date +%Y-%m-%d)"
LOG_FILE="/var/log/backup-manager.log"
KEEP_DAYS=7

# Создаем директорию бэкапа, если её нет
mkdir -p "$BACKUP_DIR"

# ==============================================================================
# Функция логирования и отправки в Telegram
# ==============================================================================
log_and_notify() {
    local status=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Запись в лог
    echo "[$timestamp] [$status] $message" >> "$LOG_FILE"
    
    # Отправка в TG если статус ERROR или по завершении
    if [[ "$status" == "ERROR" ]] || [[ "$message" == *"completed"* ]]; then
        curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
            -d chat_id="$TG_CHAT_ID" \
            -d text="🚀 [$HOSTNAME] Backup Report:
Status: $status
Message: $message" > /dev/null
    fi
}

# ==============================================================================
# 1. Определение окружения и выбор стратегии
# ==============================================================================
echo "--- Starting Backup Process ---"

# Проверка на наличие PostgreSQL
if command -v pg_dump &> /dev/null; then
    log_and_notify "INFO" "PostgreSQL detected. Starting database dump..."
    sudo -u postgres pg_dumpall | gzip > "$BACKUP_DIR/pg_globals_$(date +%H%M).sql.gz"
    if [ $? -eq 0 ]; then
        log_and_notify "SUCCESS" "PostgreSQL dump created."
    else
        log_and_notify "ERROR" "PostgreSQL dump failed!"
    fi
fi

# Проверка на наличие Docker
if command -v docker &> /dev/null && [ "$(docker ps -q)" ]; then
    log_and_notify "INFO" "Docker containers detected. Backing up volumes..."
    # Бэкапим папку с конфигами докера (укажи свой путь)
    tar -czf "$BACKUP_DIR/docker_configs_$(date +%H%M).tar.gz" /opt/docker-data 2>/dev/null
    log_and_notify "SUCCESS" "Docker volumes archived."
fi

# Универсальный бэкап важных директорий (например, nginx configs, scripts)
log_and_notify "INFO" "Archiving system configs..."
tar -czf "$BACKUP_DIR/sys_configs_$(date +%H%M).tar.gz" /etc/nginx /usr/local/bin 2>/dev/null

# ==============================================================================
# 2. Ротация (Удаление старых бэкапов)
# ==============================================================================
log_and_notify "INFO" "Cleaning up backups older than $KEEP_DAYS days..."
find /mnt/backups/ -type d -mtime +$KEEP_DAYS -exec rm -rf {} \;

# ==============================================================================
# 3. Финальный отчет
# ==============================================================================
DISK_USAGE=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $5}')
log_and_notify "INFO" "Backup cycle completed. Disk usage on backup partition: $DISK_USAGE"
