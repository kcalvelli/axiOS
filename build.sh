#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Setup display manager
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/cosmic-greeter.service /etc/systemd/system/display-manager.service

# Package preferences
rpm-ostree override remove firefox-langpacks firefox
rpm-ostree install geary 

# No idea if this will work
flatpak remove org.mozilla.Thunderbird

systemctl enable podman.socket
