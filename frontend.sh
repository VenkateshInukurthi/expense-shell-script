#!/bin/bash

set -euo pipefail

#########################################
# VARIABLES
#########################################

LOG_FOLDER="/var/log/expenses"
SCRIPT_NAME=$(basename "$0" .sh)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOGFILE="$LOG_FOLDER/${SCRIPT_NAME}_${TIMESTAMP}.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
C="\e[36m"

#########################################
# Ensure log directory exists
#########################################

mkdir -p "$LOG_FOLDER"

#########################################
# Logging Function
#########################################

log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

#########################################
# Root privilege check
#########################################

CHECK_ROOT() {
    if [ "$EUID" -ne 0 ]; then
        log "${R}ERROR: Please run this script with root privileges ${N}"
        exit 1
    fi
}

#########################################
# Command Runner Function
#########################################

RUN() {
    COMMAND=$1
    DESCRIPTION=$2

    log "${Y}$DESCRIPTION... ${N}"

    eval $COMMAND &>> "$LOGFILE"

    if [ $? -ne 0 ]
    then
        log "$DESCRIPTION ... ${R}FAILED${N}"
        exit 1
    else
        log "$DESCRIPTION ... ${G}SUCCESS${N}"
    fi
}

#########################################
# Script Start
#########################################

log "${C}Frontend deployment started at $(date) ${N}"

CHECK_ROOT

#########################################
# Install Nginx
#########################################

RUN "dnf install nginx -y" "Installing Nginx"

#########################################
# Enable and start Nginx
#########################################

RUN "systemctl enable nginx" "Enabling Nginx"
RUN "systemctl start nginx" "Starting Nginx"

#########################################
# Remove default website
#########################################

RUN "rm -rf /usr/share/nginx/html/*" "Removing default nginx website"

#########################################
# Download frontend code
#########################################

RUN "curl -L -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip" "Downloading frontend code"

#########################################
# Extract frontend code
#########################################

RUN "cd /usr/share/nginx/html && unzip /tmp/frontend.zip" "Extracting frontend code"

#########################################
# Copy nginx configuration
#########################################

RUN "cp /opt/expense-shell-script/expense.conf /etc/nginx/default.d/expense.conf" "Copying nginx configuration"

#########################################
# Restart nginx
#########################################

RUN "systemctl restart nginx" "Restarting Nginx"

#########################################
# Script completion
#########################################

log "${G}Frontend deployment completed successfully ${N}"