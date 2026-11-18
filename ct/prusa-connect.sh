#!/usr/bin/env bash
_CS_DEFAULT_URL="https://raw.githubusercontent.com/community-scripts/DevScripts/main"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Piotr Karny (pkarny)
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
# Source: https://github.com/prusa3d/prusa-connect

APP="Prusa-Connect"
var_tags="${var_tags:-3d-printing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/prusa-connect ]]; then
    msg_error "No Prusa Connect Installation Found!"
    exit
  fi

  if GH_INCLUDE_PRERELEASE=1 check_for_gh_release "prusa-connect" "prusa3d/prusa-connect"; then
    msg_info "Backing up Prusa Connect"
    cd /opt/prusa-connect_data
    BACKUP_MANIFEST=$(/opt/prusa-connect/prusa-connect backup create -config /opt/prusa-connect_data/config/config.yaml -upgrade-to "${CHECK_UPDATE_RELEASE#v}" -acknowledge-external-postgres -json)
    msg_ok "Backed up Prusa Connect"
    if [[ "$BACKUP_MANIFEST" == *'"postgres":'* ]]; then
      msg_warn "PostgreSQL databases are not in this backup. To roll back, restore them from your own backups."
    fi

    msg_info "Stopping Prusa Connect"
    systemctl stop prusa-connect
    msg_ok "Stopped Prusa Connect"

    GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "prusa-connect" "prusa3d/prusa-connect" "singlefile" "latest" "/opt/prusa-connect" "prusa_connect_$(arch_resolve "amd64" "aarch64")"

    msg_info "Starting Prusa Connect"
    systemctl start prusa-connect
    msg_ok "Started Prusa Connect"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}Prusa Connect setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}The first-run setup code is in /opt/prusa-connect_data/config/config.yaml${CL}"
