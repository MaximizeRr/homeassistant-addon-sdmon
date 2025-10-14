# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build arguments
ARG SDMON_VERSION

# Install build dependencies and build sdmon
RUN \
    apk add --no-cache --virtual .build-dependencies \
    git \
    gcc \
    g++ \
    make \
    linux-headers \
    && git clone --depth 1 --branch ${SDMON_VERSION} \
    https://github.com/Ognian/sdmon.git /tmp/sdmon \
    && cd /tmp/sdmon \
    && gcc -static -o sdmon src/*.c \
    && mv sdmon /usr/local/bin/ \
    && chmod +x /usr/local/bin/sdmon \
    && cd / \
    && rm -rf /tmp/sdmon \
    && apk del .build-dependencies

# Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="maximizerr" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="maximizerr" \
    org.opencontainers.image.licenses="GPL-2.0" \
    org.opencontainers.image.url="https://github.com/maximizerr/homeassistant-addon-sdmon" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

