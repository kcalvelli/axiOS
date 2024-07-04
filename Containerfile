ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-dx"
ARG SOURCE_TAG="latest"

FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

# Setup Copr repo
RUN wget https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-40/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_ryanabx-cosmic.repo

# Install cosmic desktop environment
RUN rpm-ostree install cosmic-desktop

# Install extras (currently just a power manager and a libsecret manager)
#RUN rpm-ostree install \
#    tuned \
#    gnome-keyring

# Set up display manager
RUN rm -f /etc/systemd/system/display-manager.service && \
    ln -s /usr/lib/systemd/system/cosmic-greeter.service /etc/systemd/system/display-manager.service

RUN ostree container commit && \
    mkdir -p /var/tmp && chmod -R 1777 /var/tmp

