#! /bin/bash

# This script is used to install the required packages and the customizations.
# Check if the user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Check for the existence of lsb_release
if ! command -v lsb_release > /dev/null; then
    echo "lsb_release command not found. This script requires lsb_release to determine the distribution."
    exit 1
fi

# Get distribution information
distro_info=$(lsb_release -si)
if [ "$distro_info" == "Debian" ] || [ "$distro_info" == "Ubuntu" ]; then
    echo "Debian based distribution detected"
    distro="deb"
    package_manager="apt"
elif [ "$distro_info" == "RedHatEnterpriseServer" ] || [ "$distro_info" == "Fedora" ]; then
    echo "Redhat based distribution detected"
    distro="rpm"
    package_manager="dnf"
else
    echo "Unknown distribution"
    exit 1
fi

required_packages=("curl", "file", "git", "make", "python3", "python3-pip", "python3-setuptools", "python3-wheel", "unzip", "wget", "zip")
failed_packages=()
# print the required packages
echo -e "\e[32m"
echo "Required packages: ${required_packages[@]}"
echo -e "\e[39m"

# Check for the existence of required commands
for command in "${required_commands[@]}"; do
    if ! command -v "$command" > /dev/null; then
        echo "$command command not found."
        if [ "$distro" == "deb" ]; then
            # color to violet
            echo -e "\e[35m"
            echo "Installing $command using $package_manager..."
            echo -e "\e[39m"
            if ! sudo $package_manager update || ! sudo $package_manager install "$command"; then
                # color to red
                echo -e "\e[31m"
                echo "Failed to install $command."
                echo -e "\e[39m"
                # add the failed package to the failed_packages array
                failed_packages+=("$command")
                exit 1
            fi
        elif [ "$distro" == "rpm" ]; then
            # color to cyan
            echo -e "\e[36m"
            echo "Installing $command using $package_manager..."
            echo -e "\e[39m"
            if ! sudo $package_manager update || ! sudo $package_manager install "$command"; then
                # color to red
                echo -e "\e[31m"
                echo "Failed to install $command."
                echo -e "\e[39m"
                # add the failed package to the failed_packages array
                failed_packages+=("$command")
                exit 1
            fi
        fi
    fi
done

if [ ${#failed_packages[@]} -gt 0 ]; then
    echo "Failed to install the following packages: ${failed_packages[@]}"
    exit 1
elif [ ${#failed_packages[@]} -eq 0 ]; then
    echo "All required packages are installed."
fi

# Check if Flatpak is already installed
if command -v flatpak > /dev/null; then
    echo "Flatpak is already installed."
else
    echo "Installing Flatpak..."
    if [ "$distro" == "deb" ]; then
        if ! sudo $package_manager update || ! sudo $package_manager install flatpak; then
            echo "Failed to install Flatpak."
            exit 1
        fi
    elif [ "$distro" == "rpm" ]; then
        if ! sudo $package_manager update || ! sudo $package_manager install flatpak; then
            echo "Failed to install Flatpak."
            exit 1
        fi
    fi
fi

# Add the Flathub repository
if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    echo "Failed to add the Flathub repository."
    exit 1
fi

echo "Flatpak setup complete."

# Installing the required Flatpaks

flatpak_packages = ("com.visualstudio.code", "com.unity.UnityHub")
failed_flatpak_packages = ()
# Loop through the list of Flatpak packages
for package in "${flatpak_packages[@]}"; do
    # Install the package
    if ! flatpak install flathub "$package"; then
        echo "Failed to install $package."
        # add failed package to failed_flatpak_packages
        failed_flatpak_packages+=("$package")
    else
        echo "$package installed successfully."
    fi
done

if [ ${#failed_flatpak_packages[@]} -gt 0 ]; then
    echo "Failed to install the following packages: ${failed_flatpak_packages[@]}"
    exit 1
elif [ ${#failed_packages[@]} -eq 0 ]; then
    echo "All required packages are installed."
fi