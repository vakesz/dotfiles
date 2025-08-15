# shellcheck shell=bash
install_azure_cli() {
  if need_cmd az; then return; fi
  local az_key="/etc/apt/keyrings/microsoft.gpg"
  local az_list
  az_list="deb [arch=$(dpkg --print-architecture) signed-by=${az_key}] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"
  add_apt_source "azure-cli" "$az_list" "$az_key" "https://packages.microsoft.com/keys/microsoft.asc"
  apt_update_if_needed
  apt_install azure-cli
}

register_installer install_azure_cli 120