#!/bin/bash

# Check if an NVIDIA GPU is present
if lspci | grep -i nvidia &>/dev/null; then
    echo "NVIDIA GPU found."
    echo "Installing NVIDIA CUDA drivers"
    export distro="$(lsb_release -is | tr '[:upper:]' '[:lower:]')$(lsb_release -rs | tr -d '.')"
    export arch=$(uname -m)
    cd /tmp
    wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt-get -qq update
    sudo apt-get -qq install -y cuda-drivers

    echo "Installing NVIDIA container toolkit"
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get -qq update
    sudo apt-get -qq install -y nvidia-container-toolkit nvidia-docker2

    echo "NVIDIA drivers installed"
else
    echo "No NVIDIA GPU found"
fi

echo "Configuring Docker daemon..."
if [ ! -s "/etc/docker/daemon.json" ]; then \
    sudo sh -c "echo \"{}\" > /etc/docker/daemon.json"; \
fi
sudo sh -c "jq '.[\"log-driver\"] =\"json-file\" | (.[\"log-opts\"] | .[\"labels-regex\"] ) = \"^.+\" | .[\"max-concurrent-downloads\"] = 20 ' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp"
sudo sh -c "mv -f /etc/docker/daemon.json.tmp /etc/docker/daemon.json ; chmod 0644 /etc/docker/daemon.json"
sudo systemctl daemon-reload
sudo systemctl restart docker