ARG SOURCE_IMAGE="bluefin"
ARG SOURCE_SUFFIX="-dx"
ARG SOURCE_TAG="latest"

FROM ghcr.io/ublue-os/${SOURCE_IMAGE}${SOURCE_SUFFIX}:${SOURCE_TAG}

RUN mkdir -p /var/lib/alternatives && \
    /tmp/build.sh && \
    ostree container commit

RUN wget https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-$(rpm -E %fedora)/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_ryanabx-cosmic.repo && \
    rpm-ostree install cosmic-desktop && \
    ostree container commit

COPY build.sh /tmp/build.sh

RUN /tmp/build.sh && \
    ostree container commit

