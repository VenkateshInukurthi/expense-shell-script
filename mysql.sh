#!/bin/bash

set -euo pipefail

#########################################
#   VARIABLES
#########################################

LOG_FOLDER="/var/log/expenses"
SCRIPT_NAME=$(basename "$0" .sh)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOGFILE="$LOG_FOLDER/${SCRIPT_NAME}_${TIMESTAMP}.log"

R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"
C="/e[36m"

##########################################
#   Ensure log directory exists
##########################################

mkdir -p "$LOG_FOLDER"

##########################################
#   Logging Function
##########################################

log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

##########################################
#   Root privilege check
##########################################

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log "$R ERROR: Please run this script as root user $N"
        exit 1
    fi
}

###########################################
#   Command Validation
###########################################

validate() {
    if [ "$1" -ne 0 ]; then
        log "$2 ... $R FAILED $N"
        exit 1
    else
        log "$2 ... $G SUCCESS $N"
    fi
}

###########################################
#   MySQL Installation
###########################################

mysql_installation() {
    if ! dnf list installed mysql-server &>> "$LOGFILE"
    then
        log "$Y Installing mysql server $N"
        dnf install mysql-server -y
        validate $? "Installing MySQL"
    else
        log "$Y MySQL server is already installed, Skipping this step $N"
    fi
}

############################################
#   Setting up MySQL service
############################################

setup_mysql_service() {
    systemctl is-enabled  mysqld &>> "$LOGFILE" || systemctl enable mysqld &>> "$LOGFILE"
    validate $? "Enabling MySQL service"

    systemctl is-active mysqld &>> "$LOGFILE" || systemctl start mysqld &>> "$LOGFILE"
    validate $? "Starting MYSQL Service"
}

#############################################
#   Main Function
#############################################
main() {
    log "$C Starting script at : $(date) $N"

    check_root
    install_mysql
    setup_mysql_service

    log "$G Script completed successfully $N"
}

###############################################
#   Execution block
###############################################

main