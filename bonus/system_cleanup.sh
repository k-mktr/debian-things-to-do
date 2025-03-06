#!/bin/bash
# System Cleanup Script for Debian

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/system_cleanup.log"

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

echo "";
echo "╔═══════════════════════════════════════════════════════════════╗";
echo "║                                                               ║";
echo "║   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗       ║";
echo "║   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║       ║";
echo "║   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║       ║";
echo "║   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║       ║";
echo "║   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║       ║";
echo "║   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝       ║";
echo "║                                                               ║";
echo "║   ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗   ║";
echo "║  ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗  ║";
echo "║  ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝  ║";
echo "║  ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝   ║";
echo "║  ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║       ║";
echo "║   ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝       ║";
echo "║                                                               ║";
echo "╚═══════════════════════════════════════════════════════════════╝";
echo "";
echo "This script performs various system cleanup tasks on Debian"
echo ""

# Function to remove old kernels
remove_old_kernels() {
    log_message "Removing old kernels..."
    # Get the current kernel version
    current_kernel=$(uname -r)
    # List all installed kernels
    installed_kernels=$(dpkg -l | grep '^ii.*linux-image' | awk '{print $2}' | grep -v "$current_kernel")
    
    if [ -z "$installed_kernels" ]; then
        log_message "No old kernels found to remove."
        return 0
    fi
    
    for kernel in $installed_kernels; do
        log_message "Removing kernel $kernel"
        apt-get remove -y $kernel
        handle_error "Failed to remove kernel $kernel"
    done
    
    # Clean up any remaining kernel files
    apt-get autoremove -y
    handle_error "Failed to autoremove old kernel files"
    
    log_message "Old kernel removal completed."
}

# Function to clear APT cache
clear_apt_cache() {
    log_message "Clearing APT cache..."
    apt-get clean
    handle_error "Failed to clear APT cache"
}

# Function to remove orphaned packages
remove_orphaned_packages() {
    log_message "Removing orphaned packages..."
    apt-get autoremove -y
    handle_error "Failed to remove orphaned packages"
}

# Function to clear user cache
clear_user_cache() {
    log_message "Clearing user cache..."
    if [ -d "$ACTUAL_HOME/.cache" ]; then
        find "$ACTUAL_HOME/.cache" -type f -delete
        find "$ACTUAL_HOME/.cache" -type d -empty -delete
    fi
    handle_error "Failed to clear user cache"
}

# Function to clear systemd journal logs
clear_journal_logs() {
    log_message "Clearing systemd journal logs..."
    journalctl --vacuum-time=7d
    handle_error "Failed to clear systemd journal logs"
}

# Function to clear temporary files
clear_temp_files() {
    log_message "Clearing temporary files..."
    rm -rf /tmp/*
    handle_error "Failed to clear temporary files"
}

# Function to update the system
update_system() {
    log_message "Updating the system..."
    apt-get update
    handle_error "Failed to update package lists"
    apt-get upgrade -y
    handle_error "Failed to upgrade packages"
}

# Main menu
while true; do
    echo ""
    echo "Please choose a cleanup option:"
    echo "1) Remove old kernels"
    echo "2) Clear APT cache"
    echo "3) Remove orphaned packages"
    echo "4) Clear user cache"
    echo "5) Clear systemd journal logs"
    echo "6) Clear temporary files"
    echo "7) Update system"
    echo "8) Perform all cleanup tasks"
    echo "9) Exit"
    read -p "Enter your choice (1-9): " choice

    case $choice in
        1) remove_old_kernels ;;
        2) clear_apt_cache ;;
        3) remove_orphaned_packages ;;
        4) clear_user_cache ;;
        5) clear_journal_logs ;;
        6) clear_temp_files ;;
        7) update_system ;;
        8)
            remove_old_kernels
            clear_apt_cache
            remove_orphaned_packages
            clear_user_cache
            clear_journal_logs
            clear_temp_files
            update_system
            ;;
        9) 
            log_message "Exiting system cleanup script."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done