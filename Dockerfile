FROM clearlinux:latest AS builder

ARG swupd_args
ARG envoy_version=1.17.0

RUN swupd update --no-boot-update $swupd_args && swupd bundle-add curl

COPY --from=clearlinux/os-core:latest /usr/lib/os-release /

RUN source /os-release \
 && mkdir /install_root \
 && swupd os-install -V $(cat /usr/lib/os-release | grep VERSION_ID | awk -F= '{print $2}') \
    --path /install_root --statedir /swupd-state \
    --no-boot-update \
# Install Getenvoy & Envoy
 && curl -L https://getenvoy.io/cli | bash -s -- -b /install_root/usr/local/bin \
 && /install_root/usr/local/bin/getenvoy --home-dir /install_root/root/.getenvoy run "standard:${envoy_version}" -- --version \
# Create Envoy shortcut command
 && { \
      echo '#!/bin/sh'; \
      echo "getenvoy --home-dir /root/.getenvoy run standard:${envoy_version} -- \"$@\""; \
    } > /install_root/usr/local/bin/envoy \
 && chmod +x /install_root/usr/local/bin/envoy

RUN mkdir /os_core_install
COPY --from=clearlinux/os-core:latest / /os_core_install/
RUN cd / && find os_core_install | sed -e 's/os_core_install/install_root/' | xargs rm -d &> /dev/null || true

FROM clearlinux/os-core:latest

COPY --from=builder /install_root /

WORKDIR /config
VOLUME /config

ENTRYPOINT ["envoy"]
CMD ["-c", "/config/envoy.yml"]
