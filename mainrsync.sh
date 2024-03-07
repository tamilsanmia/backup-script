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
MYSQL_PASSWORD="root"

# Set the database name you want to backup
DATABASE_NAME="faveo"

# Set the remote server details
REMOTE_HOST="212.2.240.86"
REMOTE_PORT="22" # Default port is 21 if you have different valuse change it accordingly.
REMOTE_USER="root"
REMOTE_PASSWORD="Faveo@123"
REMOTE_DESTINATION="/home/backup"

# Set the current date as a variable
CURRENT_DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Function to install sshpass on Debian-based systems
install_sshpass_debian() {
  sudo apt-get update
  sudo apt-get install -y sshpass
}

# Function to install sshpass on RHEL-based systems
install_sshpass_rhel() {
  sudo yum install -y sshpass
}

# Function to install sshpass based on the Linux distribution
install_sshpass() {
  if [ -x "$(command -v apt-get)" ]; then
    install_sshpass_debian
  elif [ -x "$(command -v yum)" ]; then
    install_sshpass_rhel
  else
    echo "Error: Unsupported Linux distribution, cannot install sshpass"
    exit 1
  fi
}

# Check if sshpass is already installed
if ! command -v sshpass &> /dev/null; then
  echo "sshpass is not installed. Installing..."
  install_sshpass
else
  echo "sshpass is already installed. Skipping installation."
fi

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

# Transfer backup files to remote server using rsync
Transfer_Backup() {
   #sshpass -p "$REMOTE_PASSWORD" rsync -avz --progress --delete "$BACKUP_DIRECTORY/" "$REMOTE_SERVER:$REMOTE_DESTINATION" || { echo "Error: Failed to transfer backup files to remote server"; exit 1; }
   sshpass -p "$REMOTE_PASSWORD" rsync -avz --progress -e "ssh -p $REMOTE_PORT" "$BACKUP_DIRECTORY/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DESTINATION" || { echo "Error: Failed to transfer backup files to remote server"; exit 1; }
   echo "Backup files transferred successfully to remote server"
}

# Purge_Old_Backup
Purge_Old_Backup() {
  find "$BACKUP_DIRECTORY" -type f -name '*.gz' -mmin +"$LOCAL_BACKUP_RETENTION" -delete
  num_deleted=$(find "$BACKUP_DIRECTORY" -type f -name '*.gz' | wc -l)
  echo "Deleted $num_deleted TAR files that are older than $LOCAL_BACKUP_RETENTION minutes in $BACKUP_DIRECTORY."
}

if File_System_Backup && MySQL_Backup && Purge_Old_Backup && Transfer_Backup; then
  echo 'All functions executed successfully'
else
  echo 'Error: One or more functions failed'
  exit 1
fi


#*/5 * * * * /bin/bash /root/rsync.sh >> /home/backup/rsync.log 2>&1


#ssh-keygen -t rsa
#ssh-copy-id remote_user@remote_host