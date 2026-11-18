#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Piotr Karny (pkarny)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/prusa3d/prusa-connect

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "prusa-connect" "prusa3d/prusa-connect" "singlefile" "latest" "/opt/prusa-connect" "prusa_connect_$(arch_resolve "amd64" "aarch64")"

msg_info "Configuring Prusa Connect"
mkdir -p /opt/prusa-connect_data/config
cat <<EOF >/opt/prusa-connect_data/config/config.yaml
core:
  auth:
    setup_code: "$(random_password 16)"
  upgrade:
    enabled: false
EOF
msg_ok "Configured Prusa Connect"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prusa-connect.service
[Unit]
Description=Prusa Connect
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/prusa-connect_data
ExecStart=/opt/prusa-connect/prusa-connect -config /opt/prusa-connect_data/config/config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now prusa-connect
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
