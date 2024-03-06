#!/bin/bash

LOCAL_BACKUP_RETENTION=5 # 5 minutes retention in minutes

# Set the directory you want to store backup files
BACKUP_DIRECTORY="/home/backup"

# Set the directory you want to take backup
BACKUP_SOURCE="/var/www/faveo"

# Set the MySQL server credentials
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="faveo"
MYSQL_PASSWORD="strongpassword"

# Set the database name you want to backup
DATABASE_NAME="faveo"

# Set the current date as a variable
CURRENT_DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# FILE SYSTEM BACKUP:
File_System_Backup() {
  BACKUP_FILE="$BACKUP_DIRECTORY/filesystem-backup-$CURRENT_DATE.tar.gz"
  mkdir -p "$BACKUP_DIRECTORY" || { echo "Error: Unable to create backup directory"; exit 1; }
  tar -czf "$BACKUP_FILE" "$BACKUP_SOURCE" || { echo "Error: Failed to tar directory"; exit 1; }
  echo "Backup of directory $BACKUP_SOURCE completed at $(date +"%Y-%m-%d %H:%M:%S")"
}

# MYSQL BACKUP:
MySQL_Backup() {
  MYSQL_BACKUP_FILE="$BACKUP_DIRECTORY/db-backup-$CURRENT_DATE.sql"
  mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$DATABASE_NAME" > "$MYSQL_BACKUP_FILE" || { echo "Error: Failed to dump MySQL database"; exit 1; }
  tar -czf "$MYSQL_BACKUP_FILE.tar.gz" "$MYSQL_BACKUP_FILE" || { echo "Error: Failed to zip MySQL backup"; exit 1; }
  rm "$MYSQL_BACKUP_FILE" || { echo "Error: Failed to remove temporary MySQL backup"; exit 1; }
  echo "Backup of MySQL Database $DATABASE_NAME completed at $(date +"%Y-%m-%d %H:%M:%S")"
}

# Purge_Old_Backup
Purge_Old_Backup() {
  find "$BACKUP_DIRECTORY" -type f -name '*.gz' -mmin +"$LOCAL_BACKUP_RETENTION" -delete
  num_deleted=$(find "$BACKUP_DIRECTORY" -type f -name '*.gz' | wc -l)
  echo "Deleted $num_deleted TAR files that are older than $LOCAL_BACKUP_RETENTION minutes in $BACKUP_DIRECTORY."
}

if File_System_Backup && MySQL_Backup && Purge_Old_Backup; then
  echo 'All functions executed successfully'
else
  echo 'Error: One or more functions failed'
  exit 1
fi