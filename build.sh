#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Setup display manager
rm -f /etc/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/cosmic-greeter.service /etc/systemd/system/display-manager.service

# Blindly copied this
mkdir -p /var/tmp && chmod -R 1777 /var/tmp

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#rpm-ostree install screen

# this would install a package from rpmfusion
# rpm-ostree install vlc

#### Example for enabling a System Unit File

systemctl enable podman.socket
