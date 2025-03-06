#!/bin/bash
# "Things To Do!" script for a fresh Debian installation

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/debian_things_to_do.log"
INITIAL_DIR=$(pwd)

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        log_message "ERROR: $message"
        exit $exit_code
    fi
}

# Function to prompt for reboot
prompt_reboot() {
    sudo -u $ACTUAL_USER bash -c 'read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        log_message "Rebooting..."
        reboot
    else
        log_message "Reboot canceled."
    fi
}

# Function to backup configuration files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        handle_error "Failed to backup $file"
        log_message "Backed up $file"
    fi
}

echo "";
echo "+======================================================+";
echo "|                                                      |";
echo "|    ░░░░░░░░░░░█▀▄░█▀▀░█▀▄░▀█▀░█▀█░█▀█░░░░░░░░░░░░    |";
echo "|    ░░░░░░░░░░░█░█░█▀▀░█▀▄░░█░░█▀█░█░█░░░░░░░░░░░░    |";
echo "|    ░░░░░░░░░░░▀▀░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░░░░░░░░░░░░    |";
echo "|    ░▀█▀░█░█░▀█▀░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀█░█    |";
echo "|    ░░█░░█▀█░░█░░█░█░█░█░▀▀█░░░░█░░█░█░░░█░█░█░█░▀    |";
echo "|    ░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀    |";
echo "|                                                      |";
echo "+======================================================+";
echo "";
echo "This script automates \"Things To Do!\" steps after a fresh Debian installation"
echo "ver. 0.1.25.03"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# System Upgrade
{{system_upgrade}}

# System Configuration
{{system_config}}

# App Installation
{{app_install}}

# Customization
{{customization}}

# Custom user-defined commands
{{custom_script}}

# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
echo "";
echo "+========================================================================+";
echo "|                                                                        |";
echo "|    ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀▀░█▀▄░▀█▀░█▀█░█▀█    |";
echo "|    ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█░█░█▀▀░█▀▄░░█░░█▀█░█░█    |";
echo "|    ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀    |";
echo "|                                                                        |";
echo "+========================================================================+";
echo "";
log_message "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
