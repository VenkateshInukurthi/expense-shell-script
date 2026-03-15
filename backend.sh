#!/bin/bash

set -euo pipefail

#########################################
#   VARIABLES
#########################################

LOG_FOLDER="/var/log/expenses"
SCRIPT_NAME=$(basename "$0" .sh)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_FOLDER/${SCRIPT_NAME}_${TIMESTAMP}.log"
APP_DIR="/app"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
C="\e[36m"

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

CHECK_ROOT() {
    if [ "$EUID" -ne 0 ]; then
        log "${R}ERROR: Please run this script with root privileges ${N}" | tee -a $LOG_FILE
        exit 1
    fi
}

###########################################
#   Command Runner Function
###########################################

RUN() {
    COMMAND=$1
    DESCRIPTION=$2

    echo -e "${Y}$DESCRIPTION... $N" | tee -a $LOG_FILE

    eval $COMMAND &>> $LOG_FILE

    if [ $? -ne 0 ]
    then
        echo -e "$DESCRIPTION ... ${R}FAILED${N}" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$DESCRIPTION ...${G}SUCCESS${N}" | tee -a $LOG_FILE
    fi
}

############################################
#   Script start
############################################

echo -e "${C}Script started at $(date) ${N}" | tee -a $LOG_FILE

CHECK_ROOT

#############################################
#   NodeJS installation
#############################################

RUN "dnf module disable nodejs -y" "Disabling NodeJS default version"
RUN "dnf module enable nodejs:20 -y" "Enabling NodeJS 20 version"
RUN "dnf install nodejs -y" "Installing NodeJS"

##############################################
#   Create application user
##############################################

if ! id expense &>> $LOG_FILE
then
    echo -e "expense user doesnot exist... ${G}Creating it now${N}" | tee -a $LOG_FILE
    RUN "useradd expense" "Creating expense user"
else
    echo -e "expense user already exists... ${Y}SKIPPING${N}" | tee -a $LOG_FILE
fi

##############################################
#   Application Setup
##############################################

RUN "mkdir -p /app" "Creating app directory"
RUN "curl -L -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip" "Downloading backend Code"
RUN "rm -rf /app/*" "Removing old application files"

cd /app

RUN "unzip /tmp/backend.zip" "Extracting backend application code"
RUN "npm install" "Installing NodeJS dependencies"

###############################################
#   Systemd service startup
###############################################

RUN "cp /opt/expense-shell-script/backend.service /etc/systemd/system/backend.service" "Copying backend service file"
RUN "systemctl daemon-reload" "Reloading Systemd daemon"

################################################
#   Database setup
################################################
RUN "dnf install mysql -y" "Installing mysql client"
RUN "mysql -h mysql.devsecopslab.cloud -uroot -pExpenseApp@1 < /app/schema/backend.sql" "Loading backend schema"

################################################
#   Start backend Service
################################################
RUN "systemctl enable backend" "Enabling backend service"
RUN "systemctl restart backend" "Restarting backend service"

################################################
#   Script completion
################################################

echo -e "${G}Backend deployment completed successfully...${N}" | tee -a $LOG_FILE