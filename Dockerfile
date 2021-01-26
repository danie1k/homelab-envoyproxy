FROM clearlinux:latest AS builder

ARG swupd_args
ARG swupd_bundles=
ARG multirun_version=1.0.0

RUN swupd update --no-boot-update $swupd_args && swupd bundle-add curl

COPY --from=clearlinux/os-core:latest /usr/lib/os-release /

RUN source /os-release \
 && mkdir /install_root \
 && swupd os-install -V $(cat /usr/lib/os-release | grep VERSION_ID | awk -F= '{print $2}') \
    --path /install_root --statedir /swupd-state \
    --bundles=${swupd_bundles} \
    --no-boot-update \
# Download & install multirun
 && curl -s -o /tmp/multirun.tar.gz \
    -L https://github.com/nicolas-van/multirun/releases/download/${multirun_version}/multirun-glibc-${multirun_version}.tar.gz \
 && mkdir -p /install_root/usr/local/bin/ \
 && tar -zxvf /tmp/multirun.tar.gz -C /install_root/usr/local/bin/ \
 && chmod +x /install_root/usr/local/bin/multirun

RUN mkdir /os_core_install
COPY --from=clearlinux/os-core:latest / /os_core_install/
RUN cd / && find os_core_install | sed -e 's/os_core_install/install_root/' | xargs rm -d &> /dev/null || true

FROM clearlinux/os-core:latest

COPY --from=builder /install_root /


# ???


ENTRYPOINT ["/usr/local/bin/multirun"]
CMD []
