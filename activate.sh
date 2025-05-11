#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# Function to prompt user to continue or exit
prompt_continue() {
    read -p "Do you want to continue anyway? (y/n): " choice
    case "$choice" in
        y|Y ) echo "Continuing...";;
        * ) echo "Exiting."; exit 1;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "WARN: You did not source this file in the terminal."
  exit 1
fi

# Check if the system is Ubuntu
if grep -qi "ubuntu" /etc/os-release; then

    # Check for Ubuntu 24.x
    if grep -q 'VERSION_ID="24' /etc/os-release; then
        echo "Ubuntu 24.x detected."
    else
        echo "This is Ubuntu, but not version 24.x. only 24 has been tested"
        prompt_continue
    fi

else
    echo "This system is not running Ubuntu only Ubuntu has been tested."
    prompt_continue
fi


# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Exiting."
    exit 1
fi

# Check for Docker version 28.x
docker_version=$(docker --version | awk -F'[ ,.]' '{print $3}')

if [ "$docker_version" = "28" ]; then
    echo "Docker 28.x detected."
else
    echo "Docker is installed, but not version 28.x., which has not been tested."
    prompt_continue
fi

echo "Adding $SCRIPT_DIR/bin to \$PATH"
export PATH="$PATH:$SCRIPT_DIR/bin"

echo "This terminal should now have access to jenkins-run."
echo "Try with jenkins-run --help" 


