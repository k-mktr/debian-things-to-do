#!/bin/bash
# NVIDIA Driver Installation Script for Debian

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/nvidia_driver_installation.log"

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
echo "╔══════════════════════════════════════════════════════════╗";
echo "║                                                          ║";
echo "║   ███╗   ██╗██╗   ██╗██╗██████╗ ██╗ █████╗               ║";
echo "║   ████╗  ██║██║   ██║██║██╔══██╗██║██╔══██╗              ║";
echo "║   ██╔██╗ ██║██║   ██║██║██║  ██║██║███████║              ║";
echo "║   ██║╚██╗██║╚██╗ ██╔╝██║██║  ██║██║██╔══██║              ║";
echo "║   ██║ ╚████║ ╚████╔╝ ██║██████╔╝██║██║  ██║              ║";
echo "║   ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝              ║";
echo "║                                                          ║";
echo "║   ██████╗ ██████╗ ██╗██╗   ██╗███████╗██████╗ ███████╗   ║";
echo "║   ██╔══██╗██╔══██╗██║██║   ██║██╔════╝██╔══██╗██╔════╝   ║";
echo "║   ██║  ██║██████╔╝██║██║   ██║█████╗  ██████╔╝███████╗   ║";
echo "║   ██║  ██║██╔══██╗██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║   ║";
echo "║   ██████╔╝██║  ██║██║ ╚████╔╝ ███████╗██║  ██║███████║   ║";
echo "║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝   ║";
echo "║                                                          ║";
echo "╚══════════════════════════════════════════════════════════╝";
echo "";
echo "This script installs NVIDIA drivers on Debian"
echo ""
echo "IMPORTANT: This script should be run outside of the graphical user interface (GUI)."
echo "To access a bare terminal window:"
echo "1. Press Ctrl+Alt+F3 to switch to a virtual console."
echo "2. Log in with your username and password."
echo "3. Run this script with sudo."
echo "4. After installation, reboot your system"
echo ""
echo "If you're not comfortable with this process, please seek assistance from an experienced user."
echo ""
echo "Please choose the installation method:"
echo "1) Debian repository method (recommended)"
echo "2) NVIDIA official .run file method"
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        log_message "Debian repository method selected"
        
        # Add non-free repository if not already enabled
        if ! grep -q "non-free" /etc/apt/sources.list; then
            log_message "Adding non-free repository..."
            echo "deb http://deb.debian.org/debian/ $(lsb_release -cs) non-free" >> /etc/apt/sources.list
            handle_error "Failed to add non-free repository"
        fi

        # Update the system
        log_message "Updating the system..."
        apt-get update
        handle_error "Failed to update package lists"
        apt-get upgrade -y
        handle_error "Failed to upgrade packages"

        # Install NVIDIA drivers
        log_message "Installing NVIDIA drivers..."
        apt-get install -y nvidia-driver firmware-misc-nonfree
        handle_error "Failed to install NVIDIA drivers"

        # Install CUDA (optional)
        read -p "Do you want to install CUDA? (y/n): " install_cuda
        if [[ $install_cuda =~ ^[Yy]$ ]]; then
            log_message "Installing CUDA..."
            apt-get install -y nvidia-cuda-toolkit
            handle_error "Failed to install CUDA"
        fi
        ;;
    2)
        log_message "NVIDIA official .run file method selected"
        
        # Install necessary packages
        log_message "Installing necessary packages..."
        apt-get install -y build-essential dkms linux-headers-$(uname -r)
        handle_error "Failed to install necessary packages"

        # Download the latest NVIDIA driver
        log_message "Downloading the latest NVIDIA driver..."
        driver_url=$(curl -s https://www.nvidia.com/Download/processFind.aspx?psid=101&pfid=816&osid=12&lid=1&whql=1&lang=en-us&ctk=0 | grep -o 'https://[^"]*' | grep '.run' | head -n 1)
        wget $driver_url -O /tmp/nvidia_driver.run
        handle_error "Failed to download NVIDIA driver"

        # Stop the display manager
        log_message "Stopping the display manager..."
        systemctl isolate multi-user.target
        handle_error "Failed to stop the display manager"

        # Install the NVIDIA driver
        log_message "Installing the NVIDIA driver..."
        bash /tmp/nvidia_driver.run --silent
        handle_error "Failed to install NVIDIA driver"

        # Start the display manager
        log_message "Starting the display manager..."
        systemctl isolate graphical.target
        handle_error "Failed to start the display manager"
        ;;
    *)
        log_message "Invalid choice. Exiting."
        exit 1
        ;;
esac

log_message "NVIDIA driver installation completed."
echo "Installation complete. Please reboot your system to apply changes."
read -p "Do you want to reboot now? (y/n): " reboot_choice
if [[ $reboot_choice =~ ^[Yy]$ ]]; then
    log_message "Rebooting the system..."
    reboot
else
    log_message "Reboot postponed. Please remember to reboot your system to complete the installation."
fi